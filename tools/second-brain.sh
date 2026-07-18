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
usage: second-brain.sh <capture|capture-batch|search|filter|scan|path|migrate-tags|migrate-frontmatter> [options]
  capture [--title <t>] [--tag <t>]... [--source <path>] [--file <path>]
      body from --file, else stdin; AC-2 filter runs first; clean -> append
      to inbox/, trip -> reject (nothing written)
  capture-batch [--file <path>]
      many notes in one call from a directive-prefixed stream (--file or stdin):
      records separated by a line of '%%%' (trailing whitespace tolerated); each record's leading
      '@title <t>' / '@tags <a, b>' / '@source <s>' lines set metadata, the rest
      is body. AC-2 filter runs per record; clean records are written (paths ->
      stdout), tripped/empty ones skipped (-> stderr). Exit 0 all written,
      3 if any skipped, 2 no records
  migrate-tags
      convert existing vault notes' frontmatter tags from inline array
      (tags: [a, b]) to the Obsidian-canonical block list; strips a leading
      '#'; backs up every changed note first; idempotent
  migrate-frontmatter
      fix existing notes' frontmatter YAML safety: re-quote a title:/source:
      value that would break YAML (colon-space, trailing colon, leading
      indicator) and map ':' -> '/' in block-list tags; backs up every changed
      note first; idempotent (run migrate-tags first if tags are inline arrays)
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
# Normalize away trailing slashes so path prefix-strips are exact (e.g. the
# migrate-tags relative-path backup). Never reduce a bare "/" to empty.
while [ "$VAULT" != "/" ] && [ "${VAULT%/}" != "$VAULT" ]; do VAULT="${VAULT%/}"; done

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

# yaml_dq <str> -> a valid YAML double-quoted scalar. Escapes backslash then
# double-quote and wraps in quotes, so a free-text value containing a colon or a
# leading YAML indicator char (# [ { & * ! | > % @ " ...) stays parseable — an
# unquoted `title: Foo: bar` is invalid YAML and makes Obsidian drop the WHOLE
# frontmatter block (every tag silently lost).
yaml_dq() { local s="${1//\\/\\\\}"; s="${s//\"/\\\"}"; printf '"%s"' "$s"; }

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

# write_note <title> <source> <body> [tag...]
# Shared assemble -> AC-2 filter -> write core for `capture` and `capture-batch`.
# Assembles frontmatter (Obsidian-canonical block-list tags, a single leading
# '#' stripped) + body, runs run_filter. Clean -> writes to inbox/ with the
# slug+timestamp+collision filename logic, echoes the written path to stdout,
# returns 0. Filter trip -> nothing written, returns run_filter's code (3;
# class+line already reported to stderr). I/O failure -> returns 4. Never exits;
# the caller decides. Assumes gate_on and vault presence were already checked.
write_note() {
  local title="$1" source="$2" body="$3"; shift 3
  local tags=("$@")
  local tmp
  tmp="$(mktemp)" || { echo "second-brain: mktemp failed" >&2; return 4; }
  {
    echo "---"
    [ -n "$title" ] && printf 'title: %s\n' "$(yaml_dq "$title")"
    if [ "${#tags[@]}" -gt 0 ]; then
      # Obsidian-canonical: frontmatter tags are ALWAYS a block list, never a
      # leading '#' (the '#' is for inline body tags only). Per tag: strip a
      # single leading '#', and map ':' -> '/' — Obsidian tag names allow only
      # [A-Za-z0-9_/-], so a colon (e.g. a `branch:dev` namespace) is not a
      # usable tag; '/' is Obsidian's nested-tag form and preserves the intent.
      echo 'tags:'
      local t tn
      for t in "${tags[@]}"; do
        tn="${t#\#}"; tn="${tn//:/\/}"
        printf '  - %s\n' "$tn"
      done
    fi
    [ -n "$source" ] && printf 'source: %s\n' "$(yaml_dq "$source")"
    echo "date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "---"
    echo
    printf '%s\n' "$body"
  } > "$tmp"

  run_filter "$tmp"
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    rm -f "$tmp"
    return "$rc"
  fi

  local inbox="$VAULT/inbox"
  mkdir -p "$inbox" || { rm -f "$tmp"; echo "second-brain: mkdir failed: $inbox" >&2; return 4; }

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
    return 4
  fi
  echo "$dest"
  return 0
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

  write_note "$title" "$source" "$body" ${tags[@]+"${tags[@]}"}
  exit $?
}

# Batch-capture counters (globals: the record loop + process_batch_record run in
# the current shell via here-strings, never a pipe, so these persist).
_SB_WRITTEN=0
_SB_SKIPPED=0
_SB_IOERR=0

# process_batch_record <record-text> <index>
# Parse leading @title/@tags/@source directives, then body; skip empty-body and
# filter-tripped records (report each to stderr), write clean ones via
# write_note (path -> stdout). Whitespace-only records are ignored silently
# (separator artifacts). Updates _SB_WRITTEN / _SB_SKIPPED.
process_batch_record() {
  local rec="$1" idx="$2"
  [ -n "$(printf '%s' "$rec" | tr -d '[:space:]')" ] || return 0

  local title="" source="" tagline="" body="" in_body=0 have_body=0 line
  local tags=()
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_body" -eq 0 ]; then
      case "$line" in
        '@title '*)  title="${line#@title }";   continue;;
        '@title')    title="";                  continue;;
        '@source '*) source="${line#@source }"; continue;;
        '@source')   source="";                 continue;;
        '@tags '*)   tagline="${line#@tags }";   continue;;
        '@tags')     tagline="";                continue;;
        *) in_body=1;;
      esac
    fi
    if [ "$have_body" -eq 0 ]; then body="$line"; have_body=1
    else body="$body
$line"; fi
  done <<< "$rec"

  [ -n "$(printf '%s' "$body" | tr -d '[:space:]')" ] || {
    echo "second-brain: skipped record $idx (\"${title:-note}\") — empty body" >&2
    _SB_SKIPPED=$((_SB_SKIPPED + 1)); return 0
  }

  # split @tags on commas and/or whitespace into single-token tags (set -f
  # so a tag glob char is never expanded during word-splitting)
  if [ -n "$tagline" ]; then
    local _t
    set -f
    for _t in $(printf '%s' "$tagline" | tr ',' ' '); do tags+=("$_t"); done
    set +f
  fi

  local out rc
  out="$(write_note "$title" "$source" "$body" ${tags[@]+"${tags[@]}"})"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '%s\n' "$out"
    _SB_WRITTEN=$((_SB_WRITTEN + 1))
  else
    # rc 3 = AC-2 filter trip (class+line already reported by run_filter); 4 = I/O
    echo "second-brain: skipped record $idx (\"${title:-note}\") — filter/io (rc $rc)" >&2
    _SB_SKIPPED=$((_SB_SKIPPED + 1))
    [ "$rc" -eq 4 ] && _SB_IOERR=$((_SB_IOERR + 1))
  fi
}

cmd_capture_batch() {
  local file=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --file)
        [ $# -ge 2 ] || { echo "second-brain: --file needs a value" >&2; usage; exit 2; }
        file="$2"; shift 2;;
      *) echo "second-brain: unknown capture-batch option: $1" >&2; usage; exit 2;;
    esac
  done

  gate_on || { echo "second-brain: disabled (MINION_SECONDBRAIN != on); no-op" >&2; exit 0; }
  [ -d "$VAULT" ] || { echo "second-brain: vault absent ($VAULT); no-op" >&2; exit 0; }

  local input
  if [ -n "$file" ]; then
    [ -f "$file" ] || { echo "second-brain: --file not found: $file" >&2; exit 4; }
    input="$(cat "$file")"
  else
    input="$(cat)"
  fi

  _SB_WRITTEN=0; _SB_SKIPPED=0; _SB_IOERR=0
  # rec_has (not [ -z "$rec" ]) tracks whether the current record has started, so
  # a leading BLANK line is preserved as the body's first line instead of being
  # dropped — dropping it would shift a following '@'-line from body to directive.
  local rec="" idx=0 line rec_has=0 is_fence rest
  while IFS= read -r line || [ -n "$line" ]; do
    # record separator: a line of '%%%' optionally followed by trailing whitespace
    case "$line" in
      %%%) is_fence=1;;
      %%%*) rest="${line#%%%}"
            [ -z "$(printf '%s' "$rest" | tr -d '[:space:]')" ] && is_fence=1 || is_fence=0;;
      *) is_fence=0;;
    esac
    if [ "$is_fence" -eq 1 ]; then
      idx=$((idx + 1)); process_batch_record "$rec" "$idx"; rec=""; rec_has=0
    elif [ "$rec_has" -eq 0 ]; then rec="$line"; rec_has=1
    else rec="$rec
$line"; fi
  done <<< "$input"
  idx=$((idx + 1)); process_batch_record "$rec" "$idx"

  if [ "$_SB_WRITTEN" -eq 0 ] && [ "$_SB_SKIPPED" -eq 0 ]; then
    echo "second-brain: no records found" >&2; exit 2
  fi
  echo "second-brain: batch — $_SB_WRITTEN written, $_SB_SKIPPED skipped" >&2
  # I/O failure on any record trumps a content skip: exit 4 (environment) over 3.
  [ "$_SB_IOERR" -gt 0 ] && exit 4
  [ "$_SB_SKIPPED" -eq 0 ] && exit 0 || exit 3
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

# One-off migration: rewrite existing notes' FRONTMATTER tags from the inline
# flow array (tags: [a, b]) to the Obsidian-canonical block list. Frontmatter
# only — body text is never touched, even a body line that looks like a tags
# array. Backs up every changed note (relative path preserved) under a
# timestamped dir before writing, and is idempotent: a note already in block
# form has no inline-array frontmatter line, so it is skipped.
cmd_migrate_tags() {
  while [ $# -gt 0 ]; do
    case "$1" in
      *) echo "second-brain: unknown migrate-tags option: $1" >&2; usage; exit 2;;
    esac
  done

  gate_on || { echo "second-brain: disabled (MINION_SECONDBRAIN != on); no-op" >&2; exit 0; }
  [ -d "$VAULT" ] || { echo "second-brain: vault absent ($VAULT); no-op" >&2; exit 0; }

  local ts backup migrated=0 stray=0
  ts="$(date '+%Y%m%d-%H%M%S')"
  backup="$VAULT/.sb-tag-backup-$ts"

  local f rel tags_line tmp
  while IFS= read -r -d '' f; do
    # The inline-array tags line inside the FIRST frontmatter block only.
    tags_line="$(awk '
      NR==1 && $0=="---" {infm=1; next}
      infm==1 && $0=="---" {exit}
      infm==1 && /^tags:[[:space:]]*\[.*\][[:space:]]*$/ {print; exit}
    ' "$f")"
    [ -n "$tags_line" ] || continue   # no inline-array frontmatter tags -> skip (idempotent)

    tmp="$(mktemp)" || { echo "second-brain: mktemp failed" >&2; exit 4; }
    if ! awk '
      BEGIN{infm=0}
      NR==1 && $0=="---" {infm=1; print; next}
      infm==1 && $0=="---" {infm=0; print; next}
      infm==1 && /^tags:[[:space:]]*\[.*\][[:space:]]*$/ {
        s=$0
        sub(/^tags:[[:space:]]*\[/, "", s)
        sub(/\][[:space:]]*$/, "", s)
        t=s; gsub(/[[:space:]]/, "", t)
        if (t=="") { print; next }          # empty [] -> leave unchanged
        # Assumes simple tag tokens (Obsidian tags are alnum/_/-// only — no
        # embedded commas, spaces, or quotes), so a plain comma split is safe.
        n=split(s, a, /,/)
        print "tags:"
        for (i=1;i<=n;i++){
          x=a[i]
          gsub(/^[[:space:]]+/, "", x); gsub(/[[:space:]]+$/, "", x)
          sub(/^#/, "", x)                  # strip a single leading '#'
          print "  - " x
        }
        next
      }
      {print}
    ' "$f" > "$tmp"; then
      rm -f "$tmp"; echo "second-brain: awk failed on $f" >&2; exit 4
    fi

    if cmp -s "$f" "$tmp"; then rm -f "$tmp"; continue; fi   # no net change (e.g. empty [])

    rel="${f#"$VAULT"/}"
    mkdir -p "$backup/$(dirname "$rel")" \
      || { rm -f "$tmp"; echo "second-brain: backup mkdir failed for $rel" >&2; exit 4; }
    cp "$f" "$backup/$rel" \
      || { rm -f "$tmp"; echo "second-brain: backup copy failed: $f" >&2; exit 4; }
    if ! mv "$tmp" "$f"; then
      rm -f "$tmp"; echo "second-brain: write failed: $f" >&2; exit 4
    fi
    migrated=$((migrated + 1))
    # Count a stray '#' only when a tag actually STARTS with one (right after
    # the '[' or a ',', modulo spaces) — the exact case sub(/^#/) strips. A
    # mid-token '#' (e.g. c#pu) is left alone and must not be counted.
    printf '%s' "$tags_line" | grep -qE '(\[|,)[[:space:]]*#' && stray=$((stray + 1))
  done < <(find "$VAULT" \
      \( -name '.git' -o -name '.obsidian' -o -name '.trash' \
         -o -name '.sb-tag-backup-*' -o -name '.sb-frontmatter-backup-*' \) -prune -o \
      -type f -name '*.md' -print0)

  if [ "$migrated" -eq 0 ]; then
    echo "second-brain: no inline-array frontmatter tags found; nothing to migrate" >&2
    exit 0
  fi
  echo "second-brain: migrated $migrated note(s) to block-list tags; backup at $backup"
  [ "$stray" -gt 0 ] && echo "second-brain: stripped a leading '#' in $stray note(s)"
  exit 0
}

# One-off migration for the frontmatter-YAML-safety gaps that older captures
# left in existing notes (fixed forward in write_note): re-quote a `title:` /
# `source:` scalar whose unquoted value would break YAML (a colon-space, a
# trailing colon, or a leading indicator char) — an invalid block makes Obsidian
# drop ALL tags — and map ':' -> '/' inside block-list tag items (a colon is not
# a valid Obsidian tag char). Frontmatter only; body untouched. Backs up every
# changed note first; idempotent (an already-quoted title / colon-free tag is
# left as-is). Run `migrate-tags` first if a vault still has inline-array tags.
cmd_migrate_frontmatter() {
  while [ $# -gt 0 ]; do
    case "$1" in
      *) echo "second-brain: unknown migrate-frontmatter option: $1" >&2; usage; exit 2;;
    esac
  done

  gate_on || { echo "second-brain: disabled (MINION_SECONDBRAIN != on); no-op" >&2; exit 0; }
  [ -d "$VAULT" ] || { echo "second-brain: vault absent ($VAULT); no-op" >&2; exit 0; }

  local ts backup migrated=0
  ts="$(date '+%Y%m%d-%H%M%S')"
  backup="$VAULT/.sb-frontmatter-backup-$ts"

  local f rel tmp
  while IFS= read -r -d '' f; do
    tmp="$(mktemp)" || { echo "second-brain: mktemp failed" >&2; exit 4; }
    if ! awk '
      BEGIN{infm=0; intags=0}
      NR==1 && $0=="---" {infm=1; print; next}
      infm==1 && $0=="---" {infm=0; intags=0; print; next}
      infm==1 {
        if ($0 ~ /^[^ ]/) intags=0            # any top-level key ends a tags block
        if ($0 ~ /^(title|source): /) {
          key=$0; sub(/:.*/, "", key)
          val=$0; sub(/^[^:]*: /, "", val)
          if (val !~ /^".*"$/ && (val ~ /: / || val ~ /:[ \t]*$/ || val ~ /^[#!&*|>@%]/)) {
            gsub(/\\/, "\\\\", val); gsub(/"/, "\\\"", val)
            printf "%s: \"%s\"\n", key, val; next
          }
          print; next
        }
        if ($0 ~ /^tags:/) { intags=1; print; next }
        if (intags==1 && $0 ~ /^[ ]+- /) { line=$0; gsub(/:/, "/", line); print line; next }
        print; next
      }
      {print}
    ' "$f" > "$tmp"; then
      rm -f "$tmp"; echo "second-brain: awk failed on $f" >&2; exit 4
    fi

    if cmp -s "$f" "$tmp"; then rm -f "$tmp"; continue; fi   # nothing to fix in this note

    rel="${f#"$VAULT"/}"
    mkdir -p "$backup/$(dirname "$rel")" \
      || { rm -f "$tmp"; echo "second-brain: backup mkdir failed for $rel" >&2; exit 4; }
    cp "$f" "$backup/$rel" \
      || { rm -f "$tmp"; echo "second-brain: backup copy failed: $f" >&2; exit 4; }
    if ! mv "$tmp" "$f"; then
      rm -f "$tmp"; echo "second-brain: write failed: $f" >&2; exit 4
    fi
    migrated=$((migrated + 1))
  done < <(find "$VAULT" \
      \( -name '.git' -o -name '.obsidian' -o -name '.trash' \
         -o -name '.sb-tag-backup-*' -o -name '.sb-frontmatter-backup-*' \) -prune -o \
      -type f -name '*.md' -print0)

  if [ "$migrated" -eq 0 ]; then
    echo "second-brain: no frontmatter-safety issues found; nothing to migrate" >&2
    exit 0
  fi
  echo "second-brain: fixed frontmatter in $migrated note(s) (title/source quoting, ':' -> '/' tags); backup at $backup"
  exit 0
}

[ $# -ge 1 ] || { usage; exit 2; }
SUB="$1"; shift
case "$SUB" in
  filter)  cmd_filter "$@";;
  path)    cmd_path "$@";;
  capture) cmd_capture "$@";;
  capture-batch) cmd_capture_batch "$@";;
  search)  cmd_search "$@";;
  scan)    cmd_scan "$@";;
  migrate-tags) cmd_migrate_tags "$@";;
  migrate-frontmatter) cmd_migrate_frontmatter "$@";;
  *) usage; exit 2;;
esac
