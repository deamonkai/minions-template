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
#       [--live <live-repo-dir>] [--manifest <export-manifest.md>] \
#       [--hide-excluded] [--repo <git-repo> --from <rev> --to <rev>]
#
# --repo/--from/--to (all three together): git-diff completeness cross-check.
#   ALSO computes `git -C <repo> diff --name-only <from>..<to>`; every changed
#   file whose manifest row says "Initial export: yes" must appear in the
#   old-union-new snapshot union. Any that does not is reported LOUDLY at the
#   top of the output as UNMANIFESTED-CHANGE and the script exits 4 — so a
#   changed-and-exported file can never again silently vanish from an upgrade
#   because the snapshot/export pipeline missed it. Without these flags the
#   output is byte-identical to previous versions.
# --hide-excluded: suppress rows classified `do-not-export`; the summary line
#   notes "(N excluded hidden)". Default off (back-compat).
#
# Output: one row per CHANGED file (unchanged files are omitted):
#   <CLASS>  <CHANGE>  <LIVE>  <PATH>
#     CLASS  = upgrade strategy from docs/export-manifest.md (or 'unknown');
#              matched against exact rows, directory rows (`tools/tests/`),
#              glob rows (`minions/chat/*.md`) and directory-glob rows
#              (`minions/mail/*/`) — exact beats all, deepest row wins otherwise
#     CHANGE = added | removed | modified   (old snapshot vs new snapshot)
#     LIVE   = identical | diverged | missing | error  (live vs old; '-' without --live)
#
# Decision shortcut: CLASS=template-replace + LIVE=identical -> safe clean overwrite;
# LIVE=diverged -> hand-merge; CLASS=unknown -> classify by hand; LIVE=error -> a
# comparison failed (e.g. file-vs-dir), and the tool exits non-zero so it isn't missed.
#
# Exit codes: 0 clean · 2 usage/setup error · 3 LIVE=error rows present ·
# 4 UNMANIFESTED-CHANGE rows present (cross-check found exported changes the
# snapshots missed). When BOTH 3 and 4 conditions occur in one run, both WARN
# lines print but the exit code is 4 — the silently-dropped exported file is the
# higher-stakes signal and must not be masked by an inconclusive live comparison.
#
# Limitation: file paths containing embedded newlines are not supported (the change
# set is newline-delimited). Spaces, leading hyphens, and glob characters are fine.
set -uo pipefail

# _need <optname> <remaining-argc>: fail clearly instead of looping forever when an
# option that takes a value is given without one (a bare `shift 2` would not advance).
_need() { [ "$2" -ge 2 ] || { echo "usage: $1 needs a value" >&2; exit 2; }; }

OLD=""; NEW=""; LIVE=""; MANIFEST=""; REPO=""; FROM=""; TO=""; HIDE_EXCLUDED=0
while [ $# -gt 0 ]; do
  case "$1" in
    --old)      _need --old "$#";      OLD="$2"; shift 2;;
    --new)      _need --new "$#";      NEW="$2"; shift 2;;
    --live)     _need --live "$#";     LIVE="$2"; shift 2;;
    --manifest) _need --manifest "$#"; MANIFEST="$2"; shift 2;;
    --repo)     _need --repo "$#";     REPO="$2"; shift 2;;
    --from)     _need --from "$#";     FROM="$2"; shift 2;;
    --to)       _need --to "$#";       TO="$2"; shift 2;;
    --hide-excluded) HIDE_EXCLUDED=1; shift;;
    *) echo "usage: upgrade-classify.sh --old <dir> --new <dir> [--live <dir>] [--manifest <file>] [--hide-excluded] [--repo <git-repo> --from <rev> --to <rev>]" >&2; exit 2;;
  esac
done
{ [ -n "$OLD" ] && [ -d "$OLD" ] && [ -n "$NEW" ] && [ -d "$NEW" ]; } || {
  echo "usage: --old and --new must both be existing directories" >&2; exit 2; }
if [ -n "$LIVE" ] && [ ! -d "$LIVE" ]; then echo "error: --live is not a directory: $LIVE" >&2; exit 2; fi
if [ -n "$REPO$FROM$TO" ]; then
  { [ -n "$REPO" ] && [ -n "$FROM" ] && [ -n "$TO" ]; } || {
    echo "usage: --repo, --from and --to must be given together" >&2; exit 2; }
  [ -d "$REPO" ] || { echo "error: --repo is not a directory: $REPO" >&2; exit 2; }
fi
MANIFEST="${MANIFEST:-$NEW/docs/export-manifest.md}"

# Parse the manifest table ONCE into parallel arrays (path -> export flag +
# strategy). Avoids the O(files x rows) re-read + per-row subprocess storm. A
# single awk pass extracts, per data row, the first backticked path from cell 2,
# the "Initial export" flag from cell 3, and the strategy from cell 4 (so a PATH
# that merely contains a strategy keyword is never mistaken for the strategy).
man_paths=(); man_exports=(); man_strats=()
if [ -f "$MANIFEST" ]; then
  while IFS=$'\t' read -r _p _e _s; do
    [ -n "$_p" ] || continue
    man_paths+=("$_p"); man_exports+=("${_e:-}"); man_strats+=("${_s:-unspecified}")
  done < <(awk -F'|' '
    /^\| `/ {
      if (match($2, /`[^`]*`/)) { p = substr($2, RSTART+1, RLENGTH-2) } else next
      e = $3; gsub(/[ `]/, "", e)
      s = $4; gsub(/[ `]/, "", s)
      if (p != "") print p "\t" e "\t" s
    }' "$MANIFEST")
fi

# lookup <relpath>: set LK_CLASS / LK_EXPORT from the best-matching manifest
# row. An exact-path row wins outright; otherwise the longest (deepest) matching
# directory row (`sub/`), glob row (`minions/chat/*.md`) or directory-glob row
# (`minions/mail/*/`) wins; no match -> LK_CLASS=unknown, LK_EXPORT="". Unquoted
# $p in the glob branches is deliberate: manifest glob rows must glob-match
# (same matcher family as tools/tests/manifest-completeness.test.sh).
lookup() {
  local f="$1" i p best_i=-1 best_len=-1
  LK_CLASS="unknown"; LK_EXPORT=""
  [ "${#man_paths[@]}" -eq 0 ] && return 0
  for i in "${!man_paths[@]}"; do
    p="${man_paths[$i]}"
    if [ "$p" = "$f" ]; then best_i="$i"; break; fi
    case "$p" in
      *[*?[]*/) case "$f" in $p*)    if [ "${#p}" -gt "$best_len" ]; then best_i="$i"; best_len="${#p}"; fi;; esac;;
      *[*?[]*)  case "$f" in $p)     if [ "${#p}" -gt "$best_len" ]; then best_i="$i"; best_len="${#p}"; fi;; esac;;
      */)       case "$f" in "$p"*)  if [ "${#p}" -gt "$best_len" ]; then best_i="$i"; best_len="${#p}"; fi;; esac;;
    esac
  done
  if [ "$best_i" -ge 0 ]; then LK_CLASS="${man_strats[$best_i]}"; LK_EXPORT="${man_exports[$best_i]}"; fi
  return 0
}

list_files() { ( cd "$1" && find . -type f -not -path './.git/*' | sed 's|^\./||' | sort ); }
old_list="$(list_files "$OLD")"
new_list="$(list_files "$NEW")"
union="$(printf '%s\n%s\n' "$old_list" "$new_list" | sort -u)"

# Git-diff completeness cross-check: every file changed <from>..<to> whose
# manifest row says Initial export: yes must be in the snapshot union; report
# the gaps FIRST (top of output) so they cannot be scrolled past.
unmanifested=0
if [ -n "$REPO" ]; then
  git_changed="$(git -C "$REPO" diff --name-only "$FROM..$TO")" || {
    echo "error: git diff --name-only $FROM..$TO failed in $REPO" >&2; exit 2; }
  while IFS= read -r gf; do
    [ -n "$gf" ] || continue
    lookup "$gf"
    [ "$LK_EXPORT" = "yes" ] || continue
    printf '%s\n' "$union" | grep -qxF -- "$gf" && continue
    printf 'UNMANIFESTED-CHANGE  %s  (class=%s; changed %s..%s but absent from BOTH snapshots)\n' \
      "$gf" "$LK_CLASS" "$FROM" "$TO"
    unmanifested=$((unmanifested+1))
  done <<< "$git_changed"
fi

printf '%-16s  %-9s  %-10s  %s\n' "CLASS" "CHANGE" "LIVE" "PATH"
changed=0; hidden=0; had_error=0
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
  lookup "$f"
  if [ "$HIDE_EXCLUDED" -eq 1 ] && [ "$LK_CLASS" = "do-not-export" ]; then
    hidden=$((hidden+1)); continue
  fi
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
  printf '%-16s  %-9s  %-10s  %s\n' "$LK_CLASS" "$change" "$live" "$f"
done <<< "$union"

echo "---"
if [ "$HIDE_EXCLUDED" -eq 1 ]; then
  echo "changed files: $changed ($hidden excluded hidden)"
else
  echo "changed files: $changed"
fi
[ -n "$REPO" ] && echo "unmanifested exported changes ($FROM..$TO): $unmanifested"
[ -n "$LIVE" ] && echo "LIVE: identical=safe clean replace · diverged=hand-merge · missing=new file · error=could not compare"
# Emit EVERY applicable warning first — neither signal suppresses the other — then
# exit with the higher-stakes code. UNMANIFESTED-CHANGE (4, a silently-dropped
# exported file) outranks LIVE=error (3, a comparison that could not run): a missed
# export is irreversible on the public mirror, an error is merely inconclusive.
# (Earlier the exit-3 return came first and hid a co-occurring exit-4 signal.)
if [ "$had_error" -ne 0 ]; then
  echo "WARN: one or more live comparisons errored (LIVE=error rows) — resolve before trusting the classification" >&2
fi
if [ "$unmanifested" -ne 0 ]; then
  echo "WARN: $unmanifested exported file(s) changed $FROM..$TO but are in NEITHER snapshot (UNMANIFESTED-CHANGE rows) — the export/snapshot pipeline missed them" >&2
  exit 4
fi
[ "$had_error" -ne 0 ] && exit 3
exit 0
