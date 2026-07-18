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
# Two downstream-context exclusions keep the guard green in a real downstream repo
# with zero template drift (it enumerates TEMPLATE paths only):
#   - the vendored template snapshot (`.minions-template/`, `.minions-template.next/`)
#     is excluded built-in — every file in it is an export-ready copy already
#     covered by its root-level manifest row, not separately manifested;
#   - a downstream's OWN files (project code, local tooling) are excluded via the
#     fail-open `tools/tests/manifest-completeness.allow` list (the manifest
#     analogue of `governance-scan.allow`). The template ships it with no active
#     entries, so its own sweep is unchanged.
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

# Vendored template snapshot: a downstream commits an export-ready copy of the
# template under .minions-template/ (and stages upgrades under
# .minions-template.next/) per docs/downstream-onboarding-playbook.md. Every file
# in it is an export-ready copy of a file already covered by its root-level
# manifest row, not separately manifested — so the snapshot is excluded from the
# completeness sweep by construction. Template convention, always excluded.
is_vendored_snapshot() {
  case "$1" in .minions-template/*|.minions-template.next/*) return 0;; esac
  return 1
}

# Downstream-context allowlist (fail-open): a downstream's OWN tracked files —
# project code (app/, src/, ...), local tooling, assets — are not template-managed
# and carry no manifest row. tools/tests/manifest-completeness.allow lists
# repo-relative paths or globs (* ? []) to exclude from the sweep, one per line,
# '#' comments. Absent or comment-only -> no downstream exclusions (the template
# ships it with no active entries). The manifest analogue of governance-scan.allow.
ds_allow=()
DS_ALLOW_FILE="$ROOT/tools/tests/manifest-completeness.allow"

# is_overbroad_allow <entry>: 0 when the entry has NO literal path anchor (it is
# built only from glob metacharacters `* ? / [ ]`), so it would match ~every path
# and silently neuter this completeness guard. Such an entry (`*`, `**`, `*/`, …)
# is rejected at load time — a downstream allowlist must never turn "catch every
# unmanifested file" into "catch nothing" while the suite still prints green.
# A real glob keeps its literal anchor (`*.png` -> `.png`, `app/` -> `app`).
is_overbroad_allow() {
  local s="$1"
  s="${s//\*/}"; s="${s//\?/}"; s="${s//\//}"; s="${s//\[/}"; s="${s//\]/}"
  [ -z "$s" ]
}

# load_ds_allow <file>: populate ds_allow from the fail-open allow file (one
# path/glob per line, '#' comments), skipping blank lines and rejecting
# over-broad entries with a loud stderr warning.
load_ds_allow() {
  ds_allow=()
  [ -f "$1" ] || return 0
  local _line
  while IFS= read -r _line; do
    _line="${_line%%#*}"; _line="$(printf '%s' "$_line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$_line" ] || continue
    if is_overbroad_allow "$_line"; then
      echo "manifest-completeness: WARN ignoring over-broad allow entry '$_line' (built only from glob metacharacters — it would exclude ~every file and neuter this guard)" >&2
      continue
    fi
    ds_allow+=("$_line")
  done < "$1"
}
load_ds_allow "$DS_ALLOW_FILE"
# ds_allowed <relpath>: 0 when the path matches a downstream-allow entry. Same
# matcher shape as covered() — exact, directory prefix, glob, directory glob.
ds_allowed() {
  local f="$1" p
  [ "${#ds_allow[@]}" -eq 0 ] && return 1
  for p in ${ds_allow[@]+"${ds_allow[@]}"}; do
    [ "$p" = "$f" ] && return 0
    case "$p" in
      *[*?[]*/) case "$f" in $p*)    return 0;; esac;;
      *[*?[]*)  case "$f" in $p)     return 0;; esac;;
      */)       case "$f" in "$p"*)  return 0;; esac;;
    esac
  done
  return 1
}

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

# --- self-test the downstream-context excludes (an untested guard is theater) --
not_vendored() { ! is_vendored_snapshot "$1"; }
check "self: vendored snapshot .minions-template/ excluded"      is_vendored_snapshot ".minions-template/AI.md"
check "self: staged snapshot .minions-template.next/ excluded"   is_vendored_snapshot ".minions-template.next/MEMORY.md"
check "self: a normal path is NOT a vendored snapshot"           not_vendored "minions/smes/README.md"
check "self: a look-alike prefix is NOT excluded"                not_vendored ".minions-template-notes/x.md"
_saved_ds=("${ds_allow[@]+${ds_allow[@]}}")
ds_allow=("app/" "src/*.ts" "svelte.config.js")
not_ds() { ! ds_allowed "$1"; }
check "self: ds-allow directory prefix covers app/lib/x.svelte"  ds_allowed "app/lib/x.svelte"
check "self: ds-allow glob covers src/main.ts"                   ds_allowed "src/main.ts"
check "self: ds-allow exact covers svelte.config.js"             ds_allowed "svelte.config.js"
check "self: ds-allow does NOT cover an unlisted file"           not_ds "docs/other.md"
check "self: ds-allow prefix does NOT bleed to appx/x"           not_ds "appx/x"
ds_allow=("${_saved_ds[@]+${_saved_ds[@]}}")
# empty ds-allow (template default) excludes nothing
ds_allow=()
check "self: empty ds-allow matches nothing"                     not_ds "anything.md"
ds_allow=("${_saved_ds[@]+${_saved_ds[@]}}")

# over-broad allow entries must be rejected (they would neuter the guard)
not_overbroad() { ! is_overbroad_allow "$1"; }
check "self: '*' is over-broad (rejected)"                       is_overbroad_allow "*"
check "self: '**' is over-broad (rejected)"                      is_overbroad_allow "**"
check "self: '*/' is over-broad (rejected)"                      is_overbroad_allow "*/"
check "self: '[]' is over-broad (rejected)"                      is_overbroad_allow "[]"
check "self: 'app/' is NOT over-broad"                           not_overbroad "app/"
check "self: '*.png' is NOT over-broad"                          not_overbroad "*.png"
check "self: 'src/*.ts' is NOT over-broad"                       not_overbroad "src/*.ts"
# loader end-to-end: a '*' line is dropped, safe entries kept — the guard is not neutered
TMPA="$(mktemp)"; printf '# comment\napp/\n*\nsrc/*.ts\n' > "$TMPA"
load_ds_allow "$TMPA" 2>/dev/null
check "self: loader keeps the 2 safe entries, drops the over-broad '*'" test "${#ds_allow[@]}" -eq 2
check "self: after loader, a real unlisted file is still caught"        not_ds "docs/some-orphan.md"
rm -f "$TMPA"
load_ds_allow "$DS_ALLOW_FILE"   # restore the real (empty) allow set

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
  is_vendored_snapshot "$f" && continue
  ds_allowed "$f" && continue
  if not_covered "$f"; then
    echo "UNCOVERED (no manifest row): $f"
    uncovered=$((uncovered+1))
  fi
done <<< "$files"
echo "tracked files scanned: $total; manifest rows: ${#man_paths[@]}"
check "every tracked file classified by the export manifest (uncovered: $uncovered)" test "$uncovered" -eq 0

echo "----- $pass passed, $fail failed -----"
test "$fail" -eq 0
