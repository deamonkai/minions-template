#!/usr/bin/env bash
# archive-reporter.sh — read-only reporter for stale coordination units
# (minions/mail/<dir>/, minions/plans/<file>.md, minions/chat/<file>.md).
#
# It identifies units that are CLOSED (Status: marker) and AGED (git
# last-commit age), screens out anything unsafe to suggest moving, and
# PRINTS — never runs — the `git rm` + ARCHIVED.md-append commands a human
# or orchestrator can review and execute. There is intentionally no `run`
# subcommand: emitting one would recreate the deferred full automation this
# tool exists to avoid. See docs/archive-reporter-model.md for the full
# model (the design spec it distills is maintainer-local and does not ship).
#
# Exit codes: 0 normal (candidates or none), 2 usage error, 4 a git/IO
# failure that prevented a correct report.
#
# bash-3.2 (macOS) safe: no ${x,,}, no declare -A, no mapfile/readarray;
# NUL-safe enumeration via find -print0; LC_ALL=C on sorts; grep -rF for
# fixed-string reference-integrity search.
set -uo pipefail

usage() {
  cat <<'EOF'
usage: archive-reporter.sh [report] [--age-days N] [--force-age]
       archive-reporter.sh --help|-h|help

Read-only. Prints candidate archive commands for closed+aged coordination
units under minions/mail/, minions/plans/, minions/chat/. Never mutates
the repository. There is no `run` subcommand.

  report            default action if no subcommand given
  --age-days N       override the aged threshold (default 30, floor 7;
                      below 7 requires --force-age; MINION_ARCHIVE_AGE_DAYS
                      overrides the default)
  --force-age        allow --age-days below the 7-day floor
EOF
}

AGE_DAYS="${MINION_ARCHIVE_AGE_DAYS:-30}"
FORCE_AGE=0
CMD="report"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h|help)
      usage
      exit 0
      ;;
    report)
      CMD="report"
      shift
      ;;
    --age-days)
      shift
      AGE_DAYS="${1:-}"
      shift
      ;;
    --force-age)
      FORCE_AGE=1
      shift
      ;;
    *)
      echo "archive-reporter: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$AGE_DAYS" in
  ''|*[!0-9]*)
    echo "archive-reporter: --age-days must be a non-negative integer" >&2
    exit 2
    ;;
esac
if [ "$AGE_DAYS" -lt 7 ] && [ "$FORCE_AGE" -ne 1 ]; then
  echo "archive-reporter: --age-days $AGE_DAYS is below the 7-day floor; pass --force-age to override" >&2
  exit 2
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "archive-reporter: not inside a git repository" >&2
  exit 4
}
cd "$ROOT" || { echo "archive-reporter: cannot cd to repo root" >&2; exit 4; }

NOW_EPOCH="$(date +%s)"
TODAY="$(date +%Y-%m-%d)"

# ---------------------------------------------------------------------------
# Unicode dash bytes for the sole-holder screen (SM Finding 1): U+2011
# non-breaking hyphen, U+2013 en dash, U+2014 em dash. Built via printf byte
# escapes (bash-3.2 safe; no literal multibyte chars needed in this source).
# Embedding these bytes in an LC_ALL=C bracket expression matches each byte
# of the 3-byte UTF-8 sequence as a separate class member, so the sequence
# is consumed byte-by-byte by the surrounding `*` — verified in the test
# suite against the real bytes, not an ASCII stand-in.
# ---------------------------------------------------------------------------
NB_HYPHEN="$(printf '\xe2\x80\x91')"
EN_DASH="$(printf '\xe2\x80\x93')"
EM_DASH="$(printf '\xe2\x80\x94')"
SOLE_HOLDER_RE="SOLE[[:space:]_${NB_HYPHEN}${EN_DASH}${EM_DASH}-]*HOLDER[[:space:]]*:"

# Fence tracking is backtick-only. Verified: the repo never uses tilde
# fences (checked below at load time); if that ever finds a tilde fence,
# tilde handling becomes required (Shell/Test delta).
if LC_ALL=C grep -rn '~~~' minions/ >/dev/null 2>&1; then
  echo "archive-reporter: warning: a tilde fence (~~~) was found under minions/; backtick-only fence tracking may misparse it" >&2
fi

EXEMPT_LEDGER_RE='^(CHANGELOG\.md|CHANGELOG\.d/.*|minion-version\.md|minions/ARCHIVED\.md)$'

# ---------------------------------------------------------------------------
# is_closed FILE -- exit 0 if a Status: CLOSED... marker is found in the
# first 10 lines, at column 0, outside a fenced block. Exit 1 otherwise.
# ---------------------------------------------------------------------------
is_closed() {
  local f="$1" in_fence=0 n=0 line rest lc
  while IFS= read -r line; do
    n=$((n + 1))
    if [ "$n" -gt 10 ]; then
      break
    fi
    case "$line" in
      '```'*)
        in_fence=$((1 - in_fence))
        continue
        ;;
    esac
    if [ "$in_fence" -eq 1 ]; then
      continue
    fi
    case "$line" in
      Status:*)
        rest="${line#Status:}"
        while [ "${rest# }" != "$rest" ]; do rest="${rest# }"; done
        lc="$(printf '%s' "$rest" | tr '[:upper:]' '[:lower:]')"
        case "$lc" in
          closed*)
            return 0
            ;;
        esac
        ;;
    esac
  done < "$f"
  return 1
}

# designated_file UNIT_DIR -- echoes the first of verdict.md, response.md,
# request.md that exists; empty output if none exist (never an error).
designated_file() {
  local dir="$1"
  for cand in verdict.md response.md request.md; do
    if [ -f "$dir/$cand" ]; then
      echo "$dir/$cand"
      return 0
    fi
  done
  return 0
}

# body_file UNIT -- the file whose first 10 lines are checked for closure.
body_file() {
  local unit="$1"
  if [ -d "$unit" ]; then
    designated_file "$unit"
  else
    echo "$unit"
  fi
}

# unit_last_commit_epoch UNIT -- git log epoch of the last commit touching
# UNIT, or empty if git log returns nothing (shallow clone / never
# committed) -- treated as not-aged -> omit, never epoch-0.
unit_last_commit_epoch() {
  git log -1 --format=%ct -- "$1" 2>/dev/null
}

is_aged() {
  local unit="$1" epoch
  epoch="$(unit_last_commit_epoch "$unit")"
  [ -n "$epoch" ] || return 1
  local age_secs=$((NOW_EPOCH - epoch))
  local age_days=$((age_secs / 86400))
  [ "$age_days" -ge "$AGE_DAYS" ]
}

# sole_holder_hit UNIT -- 0 if any top-level file in UNIT (or UNIT itself
# if a file unit) matches the sole-holder marker.
sole_holder_hit() {
  local unit="$1" f
  if [ -d "$unit" ]; then
    while IFS= read -r -d '' f; do
      if LC_ALL=C grep -Eqi "$SOLE_HOLDER_RE" -- "$f" 2>/dev/null; then
        return 0
      fi
    done < <(find "$unit" -maxdepth 1 -type f -print0 2>/dev/null)
    return 1
  else
    LC_ALL=C grep -Eqi "$SOLE_HOLDER_RE" -- "$unit" 2>/dev/null
  fi
}

# referenced_hit UNIT -- 0 if a live surface (outside the exempt ledgers
# and outside the unit's own files) references the unit's path.
referenced_hit() {
  local unit="$1" hits
  hits="$(git grep -F -l -- "$unit" 2>/dev/null \
    | grep -vF -- "$unit" \
    | grep -Ev "$EXEMPT_LEDGER_RE")"
  [ -n "$hits" ]
}

# not_removable_hit UNIT -- 0 if the unit is unsafe to suggest a `git rm -r`
# for: uncommitted mods, untracked files, a subdirectory, a symlink, a
# non-text file, or an .issue sidecar (issue-sync.sh:107 convention).
not_removable_hit() {
  local unit="$1" f

  if [ -n "$(git status --porcelain -- "$unit" 2>/dev/null)" ]; then
    return 0
  fi

  local sidecar
  if [ -d "$unit" ]; then
    sidecar="$unit/.issue"
  else
    sidecar="${unit}.issue"
  fi
  if [ -e "$sidecar" ]; then
    return 0
  fi

  if [ -d "$unit" ]; then
    if [ -n "$(find "$unit" -mindepth 1 -type d 2>/dev/null)" ]; then
      return 0
    fi
    if [ -n "$(find "$unit" -type l 2>/dev/null)" ]; then
      return 0
    fi
    while IFS= read -r -d '' f; do
      if ! grep -qI '' "$f" 2>/dev/null; then
        return 0
      fi
    done < <(find "$unit" -maxdepth 1 -type f -print0 2>/dev/null)
  else
    if [ -L "$unit" ]; then
      return 0
    fi
    if ! grep -qI '' "$unit" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Enumerate scope units, NUL-safe. LC_ALL=C sort for deterministic order.
# ---------------------------------------------------------------------------
UNITS_FILE="$(mktemp)"
CANDIDATE_LINES="$(mktemp)"
trap 'rm -f "$UNITS_FILE" "$CANDIDATE_LINES"' EXIT

collect() { # $1=root  $2..=find-args
  local root="$1"; shift
  [ -d "$root" ] || return 0
  find "$root" "$@" -print0 2>/dev/null | tr '\0' '\n'
}

{
  collect minions/mail -mindepth 1 -maxdepth 1 -type d
  collect minions/plans -maxdepth 1 -type f -name '*.md'
  collect minions/chat -maxdepth 1 -type f -name '*.md'
} | while IFS= read -r p; do
    base="$(basename -- "$p")"
    case "$base" in
      README.md|*-template.md) continue ;;
    esac
    printf '%s\n' "$p"
  done | LC_ALL=C sort > "$UNITS_FILE"

candidates=0
withheld_sole=0
withheld_referenced=0
withheld_not_removable=0
unmarked_aged=0
oldest_unmarked_epoch=""
oldest_unmarked_unit=""

while IFS= read -r unit; do
  [ -n "$unit" ] || continue
  bf="$(body_file "$unit")"

  closed=1
  if [ -n "$bf" ] && [ -f "$bf" ]; then
    is_closed "$bf" && closed=0
  fi

  aged=1
  is_aged "$unit" && aged=0

  if [ "$closed" -eq 0 ] && [ "$aged" -eq 0 ]; then
    if sole_holder_hit "$unit"; then
      withheld_sole=$((withheld_sole + 1))
      continue
    fi
    if referenced_hit "$unit"; then
      withheld_referenced=$((withheld_referenced + 1))
      continue
    fi
    if not_removable_hit "$unit"; then
      withheld_not_removable=$((withheld_not_removable + 1))
      continue
    fi

    class="mail"
    case "$unit" in
      minions/plans/*) class="plans" ;;
      minions/chat/*) class="chat" ;;
    esac
    slug="$(basename -- "$unit")"
    slug="${slug%.md}"
    closed_date="$(git log -1 --format=%cd --date=short -- "$bf" 2>/dev/null)"
    src_sha="$(git log -1 --format=%h -- "$unit" 2>/dev/null)"
    epoch="$(unit_last_commit_epoch "$unit")"
    last_age_days=$(( (NOW_EPOCH - epoch) / 86400 ))
    {
      printf '# %s  (closed %s, last commit %sd ago)\n' "$unit" "${closed_date:-unknown}" "$last_age_days"
      printf 'git rm -r "%s"\n' "$unit"
      printf '#   then append to minions/ARCHIVED.md:\n'
      printf '#   | %s | %s | %s | %s | %s | (no vault) |\n' "$class" "$slug" "${closed_date:-unknown}" "$TODAY" "${src_sha:-unknown}"
      printf '\n'
    } >> "$CANDIDATE_LINES"
    candidates=$((candidates + 1))
  elif [ "$aged" -eq 0 ] && [ "$closed" -ne 0 ]; then
    unmarked_aged=$((unmarked_aged + 1))
    epoch="$(unit_last_commit_epoch "$unit")"
    if [ -z "$oldest_unmarked_epoch" ] || [ "$epoch" -lt "$oldest_unmarked_epoch" ]; then
      oldest_unmarked_epoch="$epoch"
      oldest_unmarked_unit="$unit"
    fi
  fi
done < "$UNITS_FILE"

echo "## Candidates"
echo
if [ "$candidates" -gt 0 ]; then
  cat "$CANDIDATE_LINES"
else
  echo "(none)"
  echo
fi

echo "## Withheld + drift summary"
echo
echo "withheld: sole-holder $withheld_sole"
echo "withheld: referenced-by-live-surface $withheld_referenced"
echo "withheld: not-removable $withheld_not_removable"
echo "unmarked-but-aged: $unmarked_aged"
if [ "$unmarked_aged" -gt 0 ]; then
  echo "  oldest: $oldest_unmarked_unit"
fi

exit 0
