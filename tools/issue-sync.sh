#!/usr/bin/env bash
# issue-sync.sh — one-way projection of git-native packets into host Issues
# (Gitea/GitHub). Files are the source of truth; this is an optional view.
# Default-off (MINION_ISSUES=on to enable). Never authors files. See
# docs/issue-mirror-model.md.
#
# Supported `tea` versions: v0.14.1 (verified against a live Gitea host).
# v0.14.1 renamed the issue-body flag from --body to --description (-d) and the
# edit-time label flag from --labels to --add-labels. The Gitea backend funcs
# detect the installed tea's flag names from `tea issues create --help` and
# pick --description/--add-labels when available, falling back to --body/--labels
# for older tea builds, so a single script stays correct across versions.
set -uo pipefail

resolve_host() {
  if [ -n "${MINION_ISSUE_HOST:-}" ]; then echo "$MINION_ISSUE_HOST"; return; fi
  local url; url="$(git remote get-url origin 2>/dev/null || true)"
  case "$url" in *github.com*) echo github;; "" ) echo none;; *) echo gitea;; esac
}

derive_labels() { # <type> <packet>
  local t="$1" pkt="$2" labels="type:$1"
  if [ "$t" = mail ]; then
    local base; base="$(basename "$pkt")"
    # YYYY-MM-DD-<sender>-to-<recipient>-<topic>
    local rest="${base#????-??-??-}"
    local sender="${rest%%-to-*}"
    local after="${rest#*-to-}"; local recipient="${after%%-*}"
    [ -n "$sender" ] && labels="$labels,role:$sender"
    [ -n "$recipient" ] && labels="$labels,role:$recipient"
  fi
  printf '%s' "$labels"
}

derive_assignee() { case "$1" in gate|blocker) printf '%s' "${MINION_OPERATOR:-}";; *) printf '';; esac; }

derive_title() { # <type> <packet> <override>
  [ -n "$3" ] && { printf '%s' "$3"; return; }
  printf '[%s] %s' "$1" "$(basename "$2")"
}

render_body() { # <packet>
  echo "Generated from $1 — edit the packet, not this issue."
  echo
  if [ -d "$1" ]; then
    local f
    for f in request.md response.md verdict.md; do
      [ -f "$1/$f" ] && { echo "## $f"; cat "$1/$f"; echo; }
    done
  elif [ -f "$1" ]; then cat "$1"; fi
}

render() { # <type> <packet> <title>
  echo "TITLE: $(derive_title "$1" "$2" "$3")"
  echo "LABELS: $(derive_labels "$1" "$2")"
  echo "ASSIGNEE: $(derive_assignee "$1")"
  echo "---"
  render_body "$2"
}

SUB=""; TYPE=""; PACKET=""; TITLE=""
usage() { echo "usage: issue-sync.sh <render|sync|host> --type <mail|gate|blocker|pipeline|chat> --packet <path> [--title <s>]" >&2; }

[ $# -ge 1 ] || { usage; exit 2; }
SUB="$1"; shift
case "$SUB" in
  host) resolve_host; exit 0;;
  render|sync) ;;
  *) usage; exit 2;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --type|--packet|--title)
      [ $# -ge 2 ] || { echo "issue-sync: $1 needs a value" >&2; usage; exit 2; }
      case "$1" in --type) TYPE="$2";; --packet) PACKET="$2";; --title) TITLE="$2";; esac
      shift 2;;
    *) usage; exit 2;;
  esac
done
case "$TYPE" in mail|gate|blocker|pipeline|chat) ;; *) usage; exit 2;; esac
[ -n "$PACKET" ] || { usage; exit 2; }

# render is pure/offline — exit before any gating or host resolution
if [ "$SUB" = render ]; then render "$TYPE" "$PACKET" "$TITLE"; exit 0; fi

# Optional + graceful: disabled or CLI absent -> no-op exit 0.
[ "${MINION_ISSUES:-off}" = "on" ] || { echo "issue-sync: disabled (MINION_ISSUES != on); no-op" >&2; exit 0; }

HOST="$(resolve_host)"
CLI=""; case "$HOST" in gitea) CLI=tea;; github) CLI=gh;; *) CLI="";; esac
if [ -z "$CLI" ] || ! command -v "$CLI" >/dev/null 2>&1; then
  echo "issue-sync: host=$HOST cli=${CLI:-none} unavailable; no-op" >&2; exit 0
fi

sidecar_path() { if [ -d "$1" ]; then echo "$1/.issue"; else echo "$1.issue"; fi; }

LABELS_V="$(derive_labels "$TYPE" "$PACKET")"
ASSIGNEE_V="$(derive_assignee "$TYPE")"
TITLE_V="$(derive_title "$TYPE" "$PACKET" "$TITLE")"
BODY_V="$(render_body "$PACKET")"
SC="$(sidecar_path "$PACKET")"

# Detect whether the installed `tea` supports a given flag on a subcommand,
# so we can prefer the v0.14.1 names (--description / --add-labels) and fall
# back to the legacy names (--body / --labels) on older builds. The help text
# is cheap and offline; a help failure defaults to "supported" for the modern
# flag (0.14.1 is the documented supported version).
tea_supports_flag() { # <flag> <help-args...>
  local flag="$1"; shift
  local help; help="$(tea "$@" --help 2>/dev/null)" || return 0
  printf '%s' "$help" | grep -q -- "$flag"
}

# Resolve the body flag (create + edit) once: --description on 0.14.1, else --body.
gitea_body_flag() {
  if tea_supports_flag '--description' issues create; then printf -- '--description'
  else printf -- '--body'; fi
}
# Resolve the edit-time label flag: --add-labels on 0.14.1, else --labels.
gitea_edit_label_flag() {
  if tea_supports_flag '--add-labels' issues edit; then printf -- '--add-labels'
  else printf -- '--labels'; fi
}

gitea_create() { # echoes issue number on success
  local out err_file body_flag
  body_flag="$(gitea_body_flag)"
  local create_args=(--title "$TITLE_V" "$body_flag" "$BODY_V" --labels "$LABELS_V")
  [ -n "$ASSIGNEE_V" ] && create_args+=(--assignees "$ASSIGNEE_V")
  err_file="$(mktemp)"
  out="$(tea issues create "${create_args[@]}" 2>"$err_file")" || { cat "$err_file" >&2; rm -f "$err_file"; return 4; }
  rm -f "$err_file"
  # parse trailing /issues/<n> or #<n>
  echo "$out" | grep -oE '(issues/|#)[0-9]+' | grep -oE '[0-9]+' | tail -1
}
gitea_edit() {
  local err_file body_flag label_flag
  body_flag="$(gitea_body_flag)"
  label_flag="$(gitea_edit_label_flag)"
  local edit_args=("$1" --title "$TITLE_V" "$body_flag" "$BODY_V" "$label_flag" "$LABELS_V")
  [ -n "$ASSIGNEE_V" ] && edit_args+=(--assignees "$ASSIGNEE_V")
  err_file="$(mktemp)"
  tea issues edit "${edit_args[@]}" >/dev/null 2>"$err_file" || { cat "$err_file" >&2; rm -f "$err_file"; return 4; }
  rm -f "$err_file"
}

if [ "$HOST" = gitea ]; then
  if [ -f "$SC" ]; then
    n="$(cat "$SC")"; gitea_edit "$n" || { echo "issue-sync: tea edit failed" >&2; exit 4; }
  else
    n="$(gitea_create)" || { echo "issue-sync: tea create failed" >&2; exit 4; }
    [ -n "$n" ] || { echo "issue-sync: could not parse issue number" >&2; exit 4; }
    printf '%s\n' "$n" > "$SC"
  fi
  exit 0
fi

# GitHub Projects-v2 board wiring is deferred to the documented follow-up (spec §9).
github_create() {
  local out err_file create_args=(issue create --title "$TITLE_V" --body "$BODY_V" --label "$LABELS_V")
  [ -n "$ASSIGNEE_V" ] && create_args+=(--assignee "$ASSIGNEE_V")
  err_file="$(mktemp)"
  out="$(gh "${create_args[@]}" 2>"$err_file")" || { cat "$err_file" >&2; rm -f "$err_file"; return 4; }
  rm -f "$err_file"
  echo "$out" | grep -oE 'issues/[0-9]+' | grep -oE '[0-9]+' | tail -1
}
github_edit() {
  # gh's edit-time label flag is --add-label (additive), distinct from create's
  # --label. Without it a re-sync would update title/body but leave labels stale
  # — the Gitea edit path re-applies labels (--add-labels), so match that parity.
  local err_file edit_args=(issue edit "$1" --title "$TITLE_V" --body "$BODY_V" --add-label "$LABELS_V")
  [ -n "$ASSIGNEE_V" ] && edit_args+=(--assignee "$ASSIGNEE_V")
  err_file="$(mktemp)"
  gh "${edit_args[@]}" >/dev/null 2>"$err_file" || { cat "$err_file" >&2; rm -f "$err_file"; return 4; }
  rm -f "$err_file"
}

if [ "$HOST" = github ]; then
  if [ -f "$SC" ]; then
    n="$(cat "$SC")"; github_edit "$n" || { echo "issue-sync: gh edit failed" >&2; exit 4; }
  else
    n="$(github_create)" || { echo "issue-sync: gh create failed" >&2; exit 4; }
    [ -n "$n" ] || { echo "issue-sync: could not parse gh issue number" >&2; exit 4; }
    printf '%s\n' "$n" > "$SC"
  fi
  exit 0
fi

exit 0
