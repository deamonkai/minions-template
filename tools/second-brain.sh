#!/usr/bin/env bash
# second-brain.sh — thin repo-native layer over a local Obsidian-backed
# Markdown vault (the "local second brain" fast-onboard corpus, distinct
# from the cloud Memory Recall layer). Files-first: this tool never assumes
# Obsidian is installed or running — it reads and writes plain Markdown.
# Obsidian is never probed.
#
# Optional + graceful: MINION_SECONDBRAIN=on gates capture/search/scan;
# `filter` and `path` short-circuit BEFORE the gate (same split as
# tools/issue-sync.sh's render/sync — filter must stay testable with the
# gate off). Vault absence is a silent no-op exit 0 on every gated
# subcommand — no minion workflow is ever blocked by this layer's absence.
#
# See docs/second-brain-model.md for the model (invariants, routing,
# security boundary) and docs/runbooks/second-brain-setup.md for Operator
# setup (vault location, gate, smoke test, rollback).
#
# Exit codes: 0 success/graceful-no-op · 2 usage · 3 AC-2 filter reject
# (nothing written) · 4 I/O · 5 scan leak found.
set -uo pipefail

usage() {
  cat <<'EOF' >&2
usage: second-brain.sh <capture|search|filter|scan|path> [options]
  capture [--title <t>] [--tag <t>]... [--source <path>] [--file <path>]
      body from --file, else stdin; AC-2 filter runs first; clean -> append
      to inbox/, trip -> reject (nothing written)
  search <query> [--limit <n>] [--scope inbox|all]
      read-only recall; rg preferred, grep -r fallback
  filter [--file <path>]
      AC-2 primitive only; pure/offline, no gate; 0 clean, 3 trip
  scan
      gitleaks detect --no-git over the vault; gitleaks absent -> warn/no-op
  path [--check]
      echo resolved vault path; --check runs the AC-1 preflight (warn-only)
EOF
}

VAULT="${MINION_SECONDBRAIN_VAULT:-$HOME/second-brain}"

gate_on() { [ "${MINION_SECONDBRAIN:-off}" = "on" ]; }

# ---- AC-2 filter: the always-on, dependency-free, reject-not-redact
# primitive. Checked in order (first match wins for the reported label): a
# SOLE-HOLDER: fact line (git/packet-only per MEMORY.md — never mirrored
# here), then a set of high-signal secret patterns. Personal data carries NO
# built-in pattern in Phase 1 — it ships only via an optional Operator-owned
# $VAULT/.secondbrain-exclude file (absent by default; never shipped with
# built-in PII regexes).
FILTER_LABELS=(
  "SOLE-HOLDER fact"
  "private key header"
  "AWS access key"
  "GitHub token"
  "Slack token"
  "Google API key"
  "generic secret assignment"
  "HTTP bearer token"
)
FILTER_REGEXES=(
  'SOLE-HOLDER:'
  '\-\-\-\-\-BEGIN[A-Z ]*PRIVATE KEY\-\-\-\-\-'
  'AKIA[0-9A-Z]{16}'
  'gh[pousr]_[A-Za-z0-9]{20,}'
  'xox[baprs]-[A-Za-z0-9-]+'
  'AIza[0-9A-Za-z_-]{35}'
  '(^|[^A-Za-z])(key|secret|token|password|bearer)[[:space:]]*[:=][[:space:]]*[^[:space:]]{8,}'
  '[Bb]earer[[:space:]]+[A-Za-z0-9._-]{8,}'
)

# NOTE (security): never echo the matched line CONTENT to stderr — only the
# class label and the line NUMBER. The offending text (secret value,
# SOLE-HOLDER fact) must not be re-emitted into logs/transcripts by the tool
# whose entire job is to keep it from crossing into the vault.
run_filter() { # $1=file to scan (the full assembled note — frontmatter+body)
  local f="$1" i n=${#FILTER_LABELS[@]} label regex hit lineno
  for ((i = 0; i < n; i++)); do
    label="${FILTER_LABELS[$i]}"
    regex="${FILTER_REGEXES[$i]}"
    hit="$(grep -inE -- "$regex" "$f" 2>/dev/null | head -1)"
    if [ -n "$hit" ]; then
      lineno="${hit%%:*}"
      echo "second-brain: filter reject — $label" >&2
      echo "second-brain: offending line number: $lineno" >&2
      return 3
    fi
  done
  # Optional Operator-owned exclude file — one regex per line, '#' comments,
  # absent by default. Never shipped by this tool; Operator-authored only.
  local exclude="$VAULT/.secondbrain-exclude" pat
  if [ -f "$exclude" ]; then
    while IFS= read -r pat; do
      pat="${pat%%#*}"
      pat="$(printf '%s' "$pat" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      [ -n "$pat" ] || continue
      hit="$(grep -inE -- "$pat" "$f" 2>/dev/null | head -1)"
      if [ -n "$hit" ]; then
        lineno="${hit%%:*}"
        echo "second-brain: filter reject — operator exclude pattern ($pat)" >&2
        echo "second-brain: offending line number: $lineno" >&2
        return 3
      fi
    done < "$exclude"
  fi
  return 0
}

slugify() { # $1=title -> lowercase, non-alnum runs collapsed to '-', trimmed
  local s
  s="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
  printf '%s' "${s:-note}"
}

cmd_filter() {
  local file=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --file)
        [ $# -ge 2 ] || { echo "second-brain: --file needs a value" >&2; usage; exit 2; }
        file="$2"; shift 2;;
      *) echo "second-brain: unknown filter option: $1" >&2; usage; exit 2;;
    esac
  done
  local target
  if [ -n "$file" ]; then
    [ -f "$file" ] || { echo "second-brain: --file not found: $file" >&2; exit 4; }
    target="$file"
  else
    target="$(mktemp)" || { echo "second-brain: mktemp failed" >&2; exit 4; }
    cat > "$target"
  fi
  run_filter "$target"
  local rc=$?
  [ "$target" = "$file" ] || rm -f "$target"
  exit "$rc"
}

cmd_path() {
  local check=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --check) check=1; shift;;
      *) echo "second-brain: unknown path option: $1" >&2; usage; exit 2;;
    esac
  done
  echo "$VAULT"
  [ "$check" -eq 1 ] || exit 0

  # AC-1 preflight — warn-only, never fails the command (the resolved path
  # still echoes above regardless of these warnings).
  # Top containment rule per docs/second-brain-model.md: no Obsidian-Git (or
  # any) remote on this vault — the single rule most likely to betray "never
  # leaves the Mac", checked first.
  if [ -d "$VAULT/.git" ]; then
    local remotes
    remotes="$(git -C "$VAULT" remote 2>/dev/null)"
    [ -n "$remotes" ] && echo "second-brain: WARN vault is a git repo with a remote (AC-1: no remote on this vault)" >&2
  fi
  case "$VAULT" in
    "$HOME"/Documents|"$HOME"/Documents/*)
      echo "second-brain: WARN vault is under ~/Documents (a synced/backed-up tree; AC-1 wants it outside)" >&2;;
  esac
  case "$VAULT" in
    "$HOME"/Library/Mobile\ Documents*)
      echo "second-brain: WARN vault is under iCloud Drive (~/Library/Mobile Documents)" >&2;;
  esac
  case "$VAULT" in
    *Dropbox*|*"Google Drive"*|*GoogleDrive*|*OneDrive*)
      echo "second-brain: WARN vault path name suggests a cloud-sync tree (Dropbox/Drive/OneDrive)" >&2;;
  esac
  if [ -d "$VAULT" ] && command -v tmutil >/dev/null 2>&1; then
    tmutil isexcluded "$VAULT" 2>/dev/null | grep -qi 'excluded' \
      || echo "second-brain: WARN vault is not confirmed Time-Machine-excluded (tmutil isexcluded)" >&2
  fi
  exit 0
}

cmd_capture() {
  local title="" tags=() source="" file=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --title)
        [ $# -ge 2 ] || { echo "second-brain: --title needs a value" >&2; usage; exit 2; }
        title="$2"; shift 2;;
      --tag)
        [ $# -ge 2 ] || { echo "second-brain: --tag needs a value" >&2; usage; exit 2; }
        tags+=("$2"); shift 2;;
      --source)
        [ $# -ge 2 ] || { echo "second-brain: --source needs a value" >&2; usage; exit 2; }
        source="$2"; shift 2;;
      --file)
        [ $# -ge 2 ] || { echo "second-brain: --file needs a value" >&2; usage; exit 2; }
        file="$2"; shift 2;;
      *) echo "second-brain: unknown capture option: $1" >&2; usage; exit 2;;
    esac
  done

  gate_on || { echo "second-brain: disabled (MINION_SECONDBRAIN != on); no-op" >&2; exit 0; }
  [ -d "$VAULT" ] || { echo "second-brain: vault absent ($VAULT); no-op" >&2; exit 0; }

  local body
  if [ -n "$file" ]; then
    [ -f "$file" ] || { echo "second-brain: --file not found: $file" >&2; exit 4; }
    body="$(cat "$file")"
  else
    body="$(cat)"
  fi
  [ -n "$(printf '%s' "$body" | tr -d '[:space:]')" ] \
    || { echo "second-brain: empty body" >&2; usage; exit 2; }

  local tmp
  tmp="$(mktemp)" || { echo "second-brain: mktemp failed" >&2; exit 4; }
  {
    echo "---"
    [ -n "$title" ] && echo "title: $title"
    if [ "${#tags[@]}" -gt 0 ]; then
      printf 'tags: ['
      local first=1 t
      for t in "${tags[@]}"; do
        [ "$first" -eq 1 ] || printf ', '
        printf '%s' "$t"
        first=0
      done
      printf ']\n'
    fi
    [ -n "$source" ] && echo "source: $source"
    echo "date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "---"
    echo
    printf '%s\n' "$body"
  } > "$tmp"

  run_filter "$tmp"
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    rm -f "$tmp"
    exit "$rc"
  fi

  local inbox="$VAULT/inbox"
  mkdir -p "$inbox" || { rm -f "$tmp"; echo "second-brain: mkdir failed: $inbox" >&2; exit 4; }

  local slug ts dest n=1
  slug="$(slugify "${title:-note}")"
  ts="$(date '+%Y%m%d-%H%M%S')"
  dest="$inbox/$ts-$slug.md"
  while [ -e "$dest" ]; do
    dest="$inbox/$ts-$slug-$n.md"
    n=$((n + 1))
  done

  if ! mv "$tmp" "$dest"; then
    rm -f "$tmp"
    echo "second-brain: write failed: $dest" >&2
    exit 4
  fi
  echo "$dest"
  exit 0
}

cmd_search() {
  [ $# -ge 1 ] || { usage; exit 2; }
  local query="$1"; shift
  local limit=20 scope="all"
  while [ $# -gt 0 ]; do
    case "$1" in
      --limit)
        [ $# -ge 2 ] || { echo "second-brain: --limit needs a value" >&2; usage; exit 2; }
        limit="$2"; shift 2;;
      --scope)
        [ $# -ge 2 ] || { echo "second-brain: --scope needs a value" >&2; usage; exit 2; }
        scope="$2"; shift 2;;
      *) echo "second-brain: unknown search option: $1" >&2; usage; exit 2;;
    esac
  done
  case "$scope" in inbox|all) ;; *) echo "second-brain: --scope must be inbox|all" >&2; usage; exit 2;; esac
  case "$limit" in ''|*[!0-9]*) echo "second-brain: --limit must be numeric" >&2; usage; exit 2;; esac

  gate_on || { echo "second-brain: disabled (MINION_SECONDBRAIN != on); no-op" >&2; exit 0; }
  [ -d "$VAULT" ] || { echo "second-brain: vault absent ($VAULT); no-op" >&2; exit 0; }

  local dir="$VAULT"
  [ "$scope" = inbox ] && dir="$VAULT/inbox"
  [ -d "$dir" ] || { echo "second-brain: no notes yet ($dir)" >&2; exit 0; }

  if command -v rg >/dev/null 2>&1; then
    rg -n --no-heading -- "$query" "$dir" 2>/dev/null | head -n "$limit"
  else
    grep -rn -- "$query" "$dir" 2>/dev/null | head -n "$limit"
  fi
  exit 0
}

cmd_scan() {
  gate_on || { echo "second-brain: disabled (MINION_SECONDBRAIN != on); no-op" >&2; exit 0; }
  [ -d "$VAULT" ] || { echo "second-brain: vault absent ($VAULT); no-op" >&2; exit 0; }
  if ! command -v gitleaks >/dev/null 2>&1; then
    echo "second-brain: gitleaks not installed; scan skipped (no-op)" >&2
    exit 0
  fi
  if gitleaks detect --source "$VAULT" --no-git; then
    exit 0
  else
    echo "second-brain: gitleaks detected a finding in $VAULT" >&2
    exit 5
  fi
}

[ $# -ge 1 ] || { usage; exit 2; }
SUB="$1"; shift
case "$SUB" in
  filter)  cmd_filter "$@";;
  path)    cmd_path "$@";;
  capture) cmd_capture "$@";;
  search)  cmd_search "$@";;
  scan)    cmd_scan "$@";;
  *) usage; exit 2;;
esac
