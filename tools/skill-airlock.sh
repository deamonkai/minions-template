#!/usr/bin/env bash
# skill-airlock.sh — mechanical checks for the optional skill-adoption layer
# (Scout + Airlock; see docs/skill-adoption-model.md). This tool inspects an
# adoption candidate ONCE, at crossing time. Its `check` output is ADVISORY
# SIGNAL ONLY: a clean run (exit 0) is NEVER a safety gate — it means the checks
# ran, not that the skill is safe. The human vetting panel (PM-convened,
# Skill-Provenance-SME-synthesized) and the Operator make the trust decision;
# this script only surfaces what a mechanical pass can and cannot see.
#
# Optional + graceful: MINION_SKILLS=on gates `check` (same posture as
# tools/second-brain.sh). `verify-quarantine` short-circuits BEFORE the gate —
# it is pure/offline so the post-transform quarantine assertion stays testable
# and usable with the layer off (the same render/sync split second-brain and
# issue-sync use).
#
# What a static scan CANNOT see (told to the panel, not hidden): obfuscation,
# /dev/tcp shells, interpreter shell-out, postinstall/dependency fetches, and
# data-dependent behaviour realized only at run time. Fetched/scanned content
# is treated as inert data — never eval'd.
#
# Exit codes:
#   0  success / clean-signal / graceful no-op   (NEVER a safety guarantee)
#   2  usage error
#   4  I/O error (missing path, unreadable input)
#   5  verify-quarantine: an auto-loadable SKILL.md remained (hard fail)
set -uo pipefail

usage() {
  cat <<'EOF' >&2
usage: skill-airlock.sh <check|verify-quarantine> [options]
  check --path <dir> --sha <commit-sha>
      ADVISORY signals only (SHA-pin, payload static-scan, license/SPDX,
      gitleaks if present, export-path preview). Exit 0 = checks ran, NOT
      "safe". Gated on MINION_SKILLS=on (no-op exit 0 when off).
  verify-quarantine --path <dir>
      Assert no auto-loadable SKILL.md remains under <dir> after transform.
      Pure/offline, no gate. Exit 0 clean; exit 5 if a SKILL.md is found.
EOF
}

gate_on() { [ "${MINION_SKILLS:-off}" = "on" ]; }

# ---- verify-quarantine: pure/offline, gate-independent. The transform step
# strips the original third-party SKILL.md into a non-loadable SOURCE.txt form.
# This asserts the transform actually happened: any file NAMED SKILL.md (any
# case) under <dir> is auto-loadable by the harness and is a hard failure.
cmd_verify_quarantine() {
  local path=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --path)
        [ $# -ge 2 ] || { echo "skill-airlock: --path needs a value" >&2; usage; exit 2; }
        path="$2"; shift 2;;
      *) echo "skill-airlock: unknown verify-quarantine option: $1" >&2; usage; exit 2;;
    esac
  done
  [ -n "$path" ] || { echo "skill-airlock: verify-quarantine requires --path" >&2; usage; exit 2; }
  [ -d "$path" ] || { echo "skill-airlock: --path not a directory: $path" >&2; exit 4; }

  # Case-insensitive match on the basename SKILL.md — a harness may load
  # SKILL.md/skill.md alike, so both are treated as loadable.
  local found rc=0
  found="$(find "$path" \( -type f -o -type l \) -iname 'SKILL.md' 2>/dev/null)"
  if [ -n "$found" ]; then
    echo "skill-airlock: FAIL — auto-loadable SKILL.md present after transform:" >&2
    printf '%s\n' "$found" >&2
    echo "skill-airlock: quarantine the original as a non-.md SOURCE.txt (see docs/skill-adoption-model.md)" >&2
    rc=5
  else
    echo "skill-airlock: verify-quarantine clean — no auto-loadable SKILL.md under $path"
  fi
  exit "$rc"
}

# ---- check: ADVISORY signals only. Accumulates SIGNAL lines to stdout and
# always exits 0 on a successful run (2 usage, 4 I/O). The exit code reports
# whether the checks RAN, never whether the skill is safe.
#
# SECURITY NOTE: the strings below (including "eval", "curl|bash", "/dev/tcp")
# are grep DETECTION PATTERNS this tool searches FOR inside candidate payloads.
# This script never eval's, sources, or executes candidate content — fetched
# and scanned material is inert data only (see the header). The eval regex flags
# dynamic-eval in a THIRD-PARTY payload; it is not an eval in this tool.
STATIC_LABELS=(
  "network fetch (curl/wget)"
  "pipe-to-shell (curl|bash)"
  "raw TCP socket (/dev/tcp)"
  "netcat"
  "dependency fetch (npm/pip/gem install, postinstall)"
  "dynamic eval"
  "base64 decode (possible obfuscation)"
)
STATIC_REGEXES=(
  '(^|[^A-Za-z])(curl|wget)([^A-Za-z]|$)'
  '(curl|wget)[^|]*\|[[:space:]]*(ba)?sh'
  '/dev/tcp/'
  '(^|[^A-Za-z])(nc|netcat)([^A-Za-z]|$)'
  '(npm|pip|pip3|gem)[[:space:]]+install|postinstall'
  '(^|[^A-Za-z])eval([^A-Za-z]|$)'
  'base64[[:space:]]+(-d|--decode)'
)

cmd_check() {
  local path="" sha=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --path)
        [ $# -ge 2 ] || { echo "skill-airlock: --path needs a value" >&2; usage; exit 2; }
        path="$2"; shift 2;;
      --sha)
        [ $# -ge 2 ] || { echo "skill-airlock: --sha needs a value" >&2; usage; exit 2; }
        sha="$2"; shift 2;;
      *) echo "skill-airlock: unknown check option: $1" >&2; usage; exit 2;;
    esac
  done
  [ -n "$path" ] || { echo "skill-airlock: check requires --path" >&2; usage; exit 2; }
  [ -n "$sha" ]  || { echo "skill-airlock: check requires --sha" >&2; usage; exit 2; }

  gate_on || { echo "skill-airlock: disabled (MINION_SKILLS != on); no-op" >&2; exit 0; }
  [ -d "$path" ] || { echo "skill-airlock: --path not a directory: $path" >&2; exit 4; }

  echo "skill-airlock check (ADVISORY SIGNALS ONLY — a clean run is NOT a safety gate)"
  echo "path: $path"
  echo "sha:  $sha"

  # 1. SHA-pin — a full 40-hex (sha1) or 64-hex (sha256) is a pin; anything
  #    else (branch, tag, short ref) is a floating ref and a signal.
  if printf '%s' "$sha" | grep -qE '^[0-9a-fA-F]{40}$|^[0-9a-fA-F]{64}$'; then
    echo "ok     - SHA-pin: full commit SHA"
  else
    echo "SIGNAL - SHA-pin: '$sha' is not a full commit SHA (floating ref? pin to an immutable SHA)"
  fi

  # 2. Payload static-scan — advisory pattern signals across text files.
  local i n=${#STATIC_LABELS[@]} label regex hits any=0
  for ((i = 0; i < n; i++)); do
    label="${STATIC_LABELS[$i]}"
    regex="${STATIC_REGEXES[$i]}"
    hits="$(grep -rInE -- "$regex" "$path" 2>/dev/null | head -5)"
    if [ -n "$hits" ]; then
      echo "SIGNAL - static-scan: $label"
      printf '%s\n' "$hits" | sed 's/^/           /'
      any=1
    fi
  done
  [ "$any" -eq 0 ] && echo "ok     - static-scan: no known network/exfil/obfuscation patterns (scan is a signal, not proof)"

  # 3. License / SPDX capture.
  local lic spdx
  lic="$(find "$path" -maxdepth 2 -type f \( -iname 'LICENSE*' -o -iname 'COPYING*' \) 2>/dev/null | head -3)"
  spdx="$(grep -rIl 'SPDX-License-Identifier' "$path" 2>/dev/null | head -3)"
  if [ -n "$lic" ] || [ -n "$spdx" ]; then
    echo "ok     - license: present — capture SPDX/attribution into the capabilities.md row"
    [ -n "$lic" ]  && printf '%s\n' "$lic"  | sed 's/^/           license file: /'
    [ -n "$spdx" ] && printf '%s\n' "$spdx" | sed 's/^/           SPDX in: /'
  else
    echo "SIGNAL - license: no LICENSE/COPYING file or SPDX identifier found (attribution/compat unresolved)"
  fi

  # 4. gitleaks — accidental credential vendoring (their leaks, not our run-time
  #    exposure). Absent gitleaks is a documented no-op signal, never a failure.
  if command -v gitleaks >/dev/null 2>&1; then
    if gitleaks detect --source "$path" --no-git >/dev/null 2>&1; then
      echo "ok     - gitleaks: no accidentally-vendored secrets in the payload"
    else
      echo "SIGNAL - gitleaks: a finding in the candidate payload (their leak — review before vendoring)"
    fi
  else
    echo "note   - gitleaks not installed; secret-scan skipped (no-op signal)"
  fi

  # 5. Export-path preview — the payload must land under skills/vendored/
  #    (do-not-export by construction). A path outside it is a loud signal.
  case "$path" in
    *skills/vendored/*|skills/vendored/*) echo "ok     - export-path: under skills/vendored/ (do-not-export by construction)";;
    *) echo "SIGNAL - export-path: '$path' is NOT under skills/vendored/ — vendored payloads must live there (default-deny export)";;
  esac

  echo "---"
  echo "reminder: exit 0 means the checks ran, NOT that the skill is safe. What a"
  echo "static scan cannot see (obfuscation, /dev/tcp, interpreter shell-out,"
  echo "postinstall/dependency fetches, data-dependent run-time behaviour) is the"
  echo "panel's and Operator's call. See docs/skill-adoption-model.md."
  exit 0
}

[ $# -ge 1 ] || { usage; exit 2; }
SUB="$1"; shift
case "$SUB" in
  check)             cmd_check "$@";;
  verify-quarantine) cmd_verify_quarantine "$@";;
  *) usage; exit 2;;
esac
