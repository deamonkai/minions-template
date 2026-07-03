#!/usr/bin/env bash
# manifest-completeness.test.sh — every git-tracked file must be classified by
# docs/export-manifest.md.
#
# Why: the export/snapshot/classify pipeline is manifest-row-driven, and a file
# with NO row is invisible to it (downstream field evidence: a six-release
# upgrade silently missed 5 changed files that had never been manifested). This
# guard makes "unmanifested tracked file" a loud test failure at authoring time
# instead of a silent downstream gap at upgrade time.
#
# Coverage rule — a tracked file passes when it matches a manifest row:
#   - exact path row            (`tools/xtool-call.sh`)
#   - directory row (trailing /) covering everything under it (`AI/feedback/`)
#   - documented glob row        (`minions/chat/*.md`, `minions/mail/*/`)
# or when it is on the tiny in-test allowlist below, reserved for git plumbing
# that can never be export-classified. Everything else must come from the
# manifest — extend the manifest, not the allowlist.
#
# Row extraction is the same awk pass as tools/upgrade-classify.sh (first
# backticked path in table cell 2). Matching mirrors that script's lookup():
# exact rows, trailing-slash directory rows, and the manifest's documented
# glob / directory-glob rows (classify matches them too since v1.25.0; keep
# the two matchers in sync).
set -uo pipefail

# Resolve the repo ROOT to scan: --root <dir>  >  $MANIFEST_ROOT  >  the repo
# this script lives in. Printed so "what did I just test" is never ambiguous.
ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "usage: --root needs a value" >&2; exit 2; }; ROOT="$2"; shift 2;;
    *) echo "usage: manifest-completeness.test.sh [--root <repo-dir>]   (or set MANIFEST_ROOT)" >&2; exit 2;;
  esac
done
ROOT="${ROOT:-${MANIFEST_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}}"
ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || { echo "FAIL - --root/MANIFEST_ROOT is not a directory" >&2; exit 2; }
MANIFEST="$ROOT/docs/export-manifest.md"
echo "manifest-completeness ROOT: $ROOT"

pass=0; fail=0
check() { local desc="$1"; shift; if "$@"; then echo "ok   - $desc"; pass=$((pass+1)); else echo "FAIL - $desc"; fail=$((fail+1)); fi; }

# Allowlist — ONLY genuinely unexportable git infrastructure. .gitignore is NOT
# here on purpose: it is export-relevant and carries its own manifest row.
ALLOW=(".gitattributes" ".gitmodules")
allowed() { local f="$1" a; for a in "${ALLOW[@]}"; do [ "$a" = "$f" ] && return 0; done; return 1; }

# parse_manifest <file>: fill man_paths with the first backticked path of each
# data row — the identical awk extraction used by tools/upgrade-classify.sh.
man_paths=()
parse_manifest() {
  man_paths=()
  [ -f "$1" ] || return 0
  while IFS= read -r _p; do
    [ -n "$_p" ] && man_paths+=("$_p")
  done < <(awk -F'|' '
    /^\| `/ {
      if (match($2, /`[^`]*`/)) { p = substr($2, RSTART+1, RLENGTH-2) } else next
      if (p != "") print p
    }' "$1")
}

# covered <relpath>: 0 when the path matches a manifest row (exact, directory
# prefix, glob, or directory glob). Unquoted $p in case is deliberate: glob rows
# must glob-match. Note case-pattern * crosses '/' — a glob row therefore covers
# subdirectories too, which is the conservative (row exists = classified) read.
covered() {
  local f="$1" p
  [ "${#man_paths[@]}" -eq 0 ] && return 1
  for p in "${man_paths[@]}"; do
    [ "$p" = "$f" ] && return 0
    case "$p" in
      *[*?[]*/) case "$f" in $p*)    return 0;; esac;;   # dir glob row, e.g. minions/mail/*/
      *[*?[]*)  case "$f" in $p)     return 0;; esac;;   # glob row,     e.g. minions/chat/*.md
      */)       case "$f" in "$p"*)  return 0;; esac;;   # directory row, e.g. AI/feedback/
    esac
  done
  return 1
}
not_covered() { ! covered "$1"; }

# --- self-test the matcher (an untested guard is theater; house rule) --------
TMPM="$(mktemp)"
cat > "$TMPM" <<'EOF'
| Path | Initial export | Upgrade strategy | Criticality | Default owner | Notes |
| --- | --- | --- | --- | --- | --- |
| `a.md` | yes | `template-replace` | `feature` | PM | exact row |
| `sub/` | yes | `template-replace` | `reference` | PM | directory row |
| `chat/*.md` | no | `downstream-owned` | `n/a` | PM | glob row |
| `mail/*/` | no | `downstream-owned` | `n/a` | PM | directory-glob row |
EOF
parse_manifest "$TMPM"
check "self: parser extracts 4 rows"                      test "${#man_paths[@]}" -eq 4
check "self: exact row covers a.md"                       covered "a.md"
check "self: directory row covers sub/deep/x.md"          covered "sub/deep/x.md"
check "self: directory row does NOT bleed to subx/x.md"   not_covered "subx/x.md"
check "self: glob row covers chat/2026-01-01.md"          covered "chat/2026-01-01.md"
check "self: glob row does NOT cover chat/readme.txt"     not_covered "chat/readme.txt"
check "self: dir-glob row covers mail/2026-01/packet.md"  covered "mail/2026-01/packet.md"
check "self: unlisted file is uncovered"                  not_covered "zzz.md"
rm -f "$TMPM"

# --- the real sweep -----------------------------------------------------------
parse_manifest "$MANIFEST"
check "manifest exists and has rows ($MANIFEST)" test "${#man_paths[@]}" -gt 0

# File set: git-tracked when ROOT is a work tree; find fallback keeps the guard
# usable against an exported snapshot directory (no .git).
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  files="$(git -C "$ROOT" ls-files)"
else
  files="$(cd "$ROOT" && find . -type f -not -path './.git/*' | sed 's|^\./||' | sort)"
fi
total=0; uncovered=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  total=$((total+1))
  allowed "$f" && continue
  if not_covered "$f"; then
    echo "UNCOVERED (no manifest row): $f"
    uncovered=$((uncovered+1))
  fi
done <<< "$files"
echo "tracked files scanned: $total; manifest rows: ${#man_paths[@]}"
check "every tracked file classified by the export manifest (uncovered: $uncovered)" test "$uncovered" -eq 0

echo "----- $pass passed, $fail failed -----"
test "$fail" -eq 0
