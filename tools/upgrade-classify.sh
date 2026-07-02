#!/usr/bin/env bash
# upgrade-classify.sh — classify a template change-set for a downstream upgrade.
#
# Given the OLD and NEW export-ready snapshots (and optionally the LIVE repo), print
# each changed file with (a) its export-manifest upgrade class and (b) its
# live-vs-old-snapshot divergence — turning the "discover + classify +
# verify-divergence" front half of an upgrade into one reproducible command instead
# of manual cross-referencing against the manifest table.
#
# Usage:
#   tools/upgrade-classify.sh --old <old-snapshot-dir> --new <new-snapshot-dir> \
#       [--live <live-repo-dir>] [--manifest <export-manifest.md>]
#
# Output: one row per CHANGED file (unchanged files are omitted):
#   <CLASS>  <CHANGE>  <LIVE>  <PATH>
#     CLASS  = upgrade strategy from docs/export-manifest.md (or 'unknown')
#     CHANGE = added | removed | modified   (old snapshot vs new snapshot)
#     LIVE   = identical | diverged | missing | error  (live vs old; '-' without --live)
#
# Decision shortcut: CLASS=template-replace + LIVE=identical -> safe clean overwrite;
# LIVE=diverged -> hand-merge; CLASS=unknown -> classify by hand; LIVE=error -> a
# comparison failed (e.g. file-vs-dir), and the tool exits non-zero so it isn't missed.
#
# Limitation: file paths containing embedded newlines are not supported (the change
# set is newline-delimited). Spaces, leading hyphens, and glob characters are fine.
set -uo pipefail

# _need <optname> <remaining-argc>: fail clearly instead of looping forever when an
# option that takes a value is given without one (a bare `shift 2` would not advance).
_need() { [ "$2" -ge 2 ] || { echo "usage: $1 needs a value" >&2; exit 2; }; }

OLD=""; NEW=""; LIVE=""; MANIFEST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --old)      _need --old "$#";      OLD="$2"; shift 2;;
    --new)      _need --new "$#";      NEW="$2"; shift 2;;
    --live)     _need --live "$#";     LIVE="$2"; shift 2;;
    --manifest) _need --manifest "$#"; MANIFEST="$2"; shift 2;;
    *) echo "usage: upgrade-classify.sh --old <dir> --new <dir> [--live <dir>] [--manifest <file>]" >&2; exit 2;;
  esac
done
{ [ -n "$OLD" ] && [ -d "$OLD" ] && [ -n "$NEW" ] && [ -d "$NEW" ]; } || {
  echo "usage: --old and --new must both be existing directories" >&2; exit 2; }
if [ -n "$LIVE" ] && [ ! -d "$LIVE" ]; then echo "error: --live is not a directory: $LIVE" >&2; exit 2; fi
MANIFEST="${MANIFEST:-$NEW/docs/export-manifest.md}"

# Parse the manifest table ONCE into parallel arrays (path -> strategy). Avoids the
# O(files x rows) re-read + per-row subprocess storm. A single awk pass extracts, per
# data row, the first backticked path from cell 2 and the strategy from cell 4 (so a
# PATH that merely contains a strategy keyword is never mistaken for the strategy).
man_paths=(); man_strats=()
if [ -f "$MANIFEST" ]; then
  while IFS=$'\t' read -r _p _s; do
    [ -n "$_p" ] || continue
    man_paths+=("$_p"); man_strats+=("${_s:-unspecified}")
  done < <(awk -F'|' '
    /^\| `/ {
      if (match($2, /`[^`]*`/)) { p = substr($2, RSTART+1, RLENGTH-2) } else next
      s = $4; gsub(/[ `]/, "", s)
      if (p != "") print p "\t" s
    }' "$MANIFEST")
fi

# class_of <relpath>: exact match first, then the longest directory-prefix entry.
class_of() {
  local f="$1" i p s best="unknown" best_len=-1
  [ "${#man_paths[@]}" -eq 0 ] && { echo unknown; return; }
  for i in "${!man_paths[@]}"; do
    p="${man_paths[$i]}"; s="${man_strats[$i]}"
    if [ "$p" = "$f" ]; then echo "$s"; return; fi
    case "$p" in
      */) case "$f" in "$p"*) if [ "${#p}" -gt "$best_len" ]; then best="$s"; best_len="${#p}"; fi;; esac;;
    esac
  done
  echo "$best"
}

list_files() { ( cd "$1" && find . -type f -not -path './.git/*' | sed 's|^\./||' | sort ); }
old_list="$(list_files "$OLD")"
new_list="$(list_files "$NEW")"
union="$(printf '%s\n%s\n' "$old_list" "$new_list" | sort -u)"

printf '%-16s  %-9s  %-10s  %s\n' "CLASS" "CHANGE" "LIVE" "PATH"
changed=0; had_error=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  in_old=0; in_new=0
  [ -f "$OLD/$f" ] && in_old=1
  [ -f "$NEW/$f" ] && in_new=1
  if [ "$in_old" -eq 1 ] && [ "$in_new" -eq 1 ]; then
    cmp -s "$OLD/$f" "$NEW/$f" && continue   # unchanged between snapshots -> omit
    change="modified"
  elif [ "$in_new" -eq 1 ]; then change="added"
  else change="removed"; fi
  changed=$((changed+1))
  live="-"
  if [ -n "$LIVE" ]; then
    if [ ! -e "$LIVE/$f" ]; then live="missing"
    elif [ "$in_old" -eq 1 ]; then
      rc=0; cmp -s "$LIVE/$f" "$OLD/$f" || rc=$?
      case "$rc" in
        0) live="identical";;
        1) live="diverged";;
        *) live="error"; had_error=1;;
      esac
    else
      live="diverged"   # present in live but not in old snapshot (upstream-added + local)
    fi
  fi
  printf '%-16s  %-9s  %-10s  %s\n' "$(class_of "$f")" "$change" "$live" "$f"
done <<< "$union"

echo "---"
echo "changed files: $changed"
[ -n "$LIVE" ] && echo "LIVE: identical=safe clean replace · diverged=hand-merge · missing=new file · error=could not compare"
if [ "$had_error" -ne 0 ]; then
  echo "WARN: one or more live comparisons errored (LIVE=error rows) — resolve before trusting the classification" >&2
  exit 3
fi
exit 0
