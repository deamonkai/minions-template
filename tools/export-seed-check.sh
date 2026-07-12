#!/usr/bin/env bash
set -uo pipefail
# Export-tree seed-state guard — public-export runbook Step 3, gate 4.
#
# Two guarantees:
#
# 1. HEADER-ONLY (seed reset): the neutralization sweep (public-export.md Step 2,
#    item 5) resets the content BELOW the split-merge delimiter in the Local Registry
#    / Local Matrix files to header-only seed state — the canonical repo's own SME
#    bench and routing rows are maintainer content and must never publish. That reset
#    is manual prose; nothing else in the pre-push gate stack (test suite, gitleaks,
#    forbidden-files) notices a skipped reset, so a miss silently ships private rows
#    to the PUBLIC mirror (irreversible). This guard FAILS unless everything below the
#    delimiter in SEED_FILES is header-only.
#
# 2. CLASSIFICATION COMPLETENESS: guarantee 1 is only as good as SEED_FILES. A NEW
#    exportable file that grows a filled local section below a delimiter would ship
#    with a green gate if nobody remembered to enroll it. This check finds every file
#    carrying the STRUCTURAL delimiter marker (the real `<!-- ... -->` line, not a
#    prose mention of it), scopes to export=yes via docs/export-manifest.md, and FAILS
#    any that is neither a SEED_FILE nor explicitly WAIVED — the same drift the
#    manifest-completeness guard closes for manifest rows.
#
# Run against the EXPORT TREE (post-reset). Run against canonical the header-only leg
# will — correctly — FAIL (canonical is intentionally filled); the completeness leg
# passes there and is what CI asserts (via --completeness) as a live-repo invariant.
#
# Usage: export-seed-check.sh [--completeness] [<export-tree-root>]
#   (default root: this repo's root; default mode: both legs)

MODE=both
ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --completeness) MODE=completeness; shift;;
    --*) echo "usage: export-seed-check.sh [--completeness] [<export-tree-root>]" >&2; exit 2;;
    *) ROOT_ARG="$1"; shift;;
  esac
done
ROOT="${ROOT_ARG:-$(cd "$(dirname "$0")/.." && pwd)}"
ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || { echo "FAIL - export-seed-check: not a directory: ${ROOT_ARG:-}" >&2; exit 2; }

# Files whose below-delimiter section must be header-only in a public export.
SEED_FILES=(minions/smes/README.md minions/review-matrix.md)

# Delimited, exportable files whose below-delimiter section is downstream-reserved
# scaffolding — EMPTY in canonical, not maintainer content — so they need no manual
# Step-2 reset (unlike SEED_FILES). Listing them is a positive "considered, needs no
# reset" assertion; the completeness leg forces every new delimited exportable file
# into SEED_FILES or here, so the reasoning is never skipped. They are STILL verified
# header-only below (same as SEED_FILES): the waiver is from the reset ACTION, not from
# the check — so if private content is ever added below one of these delimiters it is
# caught, not silently published (closes the Export/Privacy SME's emptiness-snapshot gap).
# docs/instruction-size-budgets.md is the same class: its below-delimiter "Local
# Overrides" section is downstream-reserved scaffolding, empty in canonical.
WAIVER=(MEMORY.md \
        minions/roles/AM.md minions/roles/CM.md minions/roles/DM.md \
        minions/roles/OM.md minions/roles/PM.md minions/roles/RM.md minions/roles/SM.md \
        docs/instruction-size-budgets.md)

# Emit each offending line below the delimiter as "<lineno>: <line>". POSITIVE
# header-only assertion (not a data-row blocklist): below the delimiter the ONLY
# permitted lines are blank lines, markdown headings, and a table header row
# IMMEDIATELY followed by its `| --- |` separator (plus the separator itself).
# Everything else is a leak — prose, bullets, a data row after the separator, or a
# table row with no separator (a malformed/hand-botched reset). The per-line separator
# lookahead (not a global flag) lets several header-only tables sit under one heading
# without false-flagging, while any filled/prose content fails.
seed_violations() { # $1=file
  awk '
    index($0, "DOWNSTREAM CONTENT BELOW") { below=1; next }
    below { n++; L[n]=$0; LN[n]=FNR }
    END {
      for (i=1; i<=n; i++) {
        line=L[i]; sub(/\r$/, "", line)
        if (line ~ /^[[:space:]]*$/)                            continue   # blank
        if (line ~ /^[[:space:]]*#/)                            continue   # heading
        if (line ~ /^[[:space:]]*\|[[:space:]:|-]+\|[[:space:]]*$/) continue   # separator row
        if (line ~ /^[[:space:]]*\|/) {                                    # any other table row
          nxt = ""; if (i < n) { nxt = L[i+1]; sub(/\r$/, "", nxt) }
          if (nxt ~ /^[[:space:]]*\|[[:space:]:|-]+\|[[:space:]]*$/) continue  # header + separator next = OK
          printf "%d: %s\n", LN[i], line; continue             # data / separator-less / trailing row = leak
        }
        printf "%d: %s\n", LN[i], line                         # prose / bullet / anything else = leak
      }
    }
  ' "$1"
}

# export=yes backticked paths from the manifest (cell 2 = path, cell 3 = Initial export).
manifest_yes_paths() { # $1=manifest
  awk -F'|' '
    /^\| `/ {
      e=$3; gsub(/[[:space:]]/, "", e)
      if (e=="yes" && match($2, /`[^`]*`/)) print substr($2, RSTART+1, RLENGTH-2)
    }' "$1"
}

# covered <relpath>: 0 when the path matches a row in yes_paths[] (exact, directory,
# glob, or directory-glob). Same matcher shape as manifest-completeness.test.sh.
covered() { # $1=relpath (matches global yes_paths[])
  local f="$1" p
  [ "${#yes_paths[@]}" -eq 0 ] && return 1
  for p in "${yes_paths[@]}"; do
    [ "$p" = "$f" ] && return 0
    case "$p" in
      *[*?[]*/) case "$f" in $p*)   return 0;; esac;;   # directory-glob row
      *[*?[]*)  case "$f" in $p)     return 0;; esac;;   # glob row
      */)       case "$f" in "$p"*)  return 0;; esac;;   # directory row
    esac
  done
  return 1
}

is_classified() { # $1=relpath -> 0 if in SEED_FILES or WAIVER
  local f="$1" c
  for c in "${SEED_FILES[@]}" "${WAIVER[@]}"; do [ "$c" = "$f" ] && return 0; done
  return 1
}

# Repo-relative paths of files carrying the STRUCTURAL delimiter marker — a LINE that
# starts with the `<!-- ... -->` comment (leading whitespace allowed). The `^[[:space:]]*`
# anchor is load-bearing: it excludes files that merely mention the marker INLINE in
# prose or code (the upgrade playbook, this script, the test files all quote it
# mid-line). git grep when ROOT is a work tree; grep -r fallback for a plain export dir.
find_delimited() {
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$ROOT" grep -lE '^[[:space:]]*<!--.*DOWNSTREAM CONTENT BELOW.*-->' -- . 2>/dev/null
  else
    ( cd "$ROOT" && grep -rlE '^[[:space:]]*<!--.*DOWNSTREAM CONTENT BELOW.*-->' . --exclude-dir=.git 2>/dev/null | sed 's|^\./||' )
  fi
}

check_completeness() { # -> 0 clean, 1 an unclassified delimited exportable file exists
  local manifest="$ROOT/docs/export-manifest.md" viol=0 rel
  yes_paths=()
  if [ -f "$manifest" ]; then
    while IFS= read -r p; do [ -n "$p" ] && yes_paths+=("$p"); done < <(manifest_yes_paths "$manifest")
  fi
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    # Scope to exportable when a manifest is present; with none (bare fixture tree),
    # treat every delimited file as in-scope (conservative — nothing slips).
    if [ "${#yes_paths[@]}" -gt 0 ] && ! covered "$rel"; then continue; fi
    is_classified "$rel" && continue
    echo "FAIL - export-seed-check: unclassified delimited exportable file (add to SEED_FILES or WAIVER): $rel"; viol=1
  done < <(find_delimited)
  return "$viol"
}

fail=0
if [ "$MODE" = both ]; then
  # Header-only check covers SEED_FILES (reset targets) AND WAIVER (must stay empty) —
  # every delimited exportable file must be header-only below the delimiter in a public
  # export; the two lists differ only in whether a manual Step-2 reset was needed.
  for f in "${SEED_FILES[@]}" "${WAIVER[@]}"; do
    path="$ROOT/$f"
    [ -f "$path" ] || { echo "WARN - export-seed-check: seed file absent (skipped): $f" >&2; continue; }
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      echo "FAIL - export-seed-check: non-seed content below delimiter in $f -> $hit"; fail=1
    done < <(seed_violations "$path")
  done
fi

check_completeness || fail=1

if [ "$fail" -eq 0 ]; then
  if [ "$MODE" = completeness ]; then
    echo "ok - export seed classification complete (every delimited exportable file is SEED or WAIVER)"
  else
    echo "ok - export seed state clean + classification complete"
  fi
fi
exit "$fail"
