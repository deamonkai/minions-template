#!/usr/bin/env bash
# issue-board-bootstrap.sh — idempotently create the minion type:/role: labels
# and report what was created vs what already existed. Board creation is manual
# (see docs/runbooks/issue-board-setup.md for host-specific steps). Optional +
# graceful (MINION_ISSUES=on). See docs/runbooks/issue-board-setup.md.
#
# Supported `tea` versions: v0.14.1 (verified against a live Gitea host).
# IMPORTANT: `tea labels create` on v0.14.1 EXITS 0 on a duplicate name and
# creates a SECOND same-named label — it does NOT fail on collision. So this
# script must NOT rely on create failing to detect "already exists". Instead it
# queries the existing labels once (`tea labels list`) and SKIPS any that are
# already present, which makes a re-run genuinely idempotent. (`gh label create`
# does fail on a duplicate, but the query-then-skip path is used uniformly so
# the behavior is identical and host-independent.)
set -uo pipefail
usage() { echo "usage: issue-board-bootstrap.sh [-h|--help]   (creates type:/role: labels; gated on MINION_ISSUES=on)" >&2; }
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help|help) usage; exit 0;;
    *) usage; exit 2;;
  esac
done
[ "${MINION_ISSUES:-off}" = "on" ] || { echo "bootstrap: disabled (MINION_ISSUES != on); no-op" >&2; exit 0; }

# Adoption cross-check (fail-open): env gate is primary and already passed. If THIS
# repo's onboarding checklist explicitly records the layer adopted:off, no-op — guards
# machine-global MINION_* bleed. Absent/unfilled/unparseable record, missing checklist,
# or missing helper -> env gate alone decides (current behavior). See docs/issue-mirror-model.md.
adopt_rc=0; "$(dirname "$0")/layer-adopted.sh" MINION_ISSUES >/dev/null 2>&1 || adopt_rc=$?
if [ "$adopt_rc" -eq 1 ]; then
  echo "bootstrap: MINION_ISSUES=on but this repo's onboarding checklist records adopted:off; no-op" >&2
  exit 0
fi

resolve_host() {
  if [ -n "${MINION_ISSUE_HOST:-}" ]; then echo "$MINION_ISSUE_HOST"; return; fi
  local url; url="$(git remote get-url origin 2>/dev/null || true)"
  case "$url" in *github.com*) echo github;; "" ) echo none;; *) echo gitea;; esac
}
HOST="$(resolve_host)"; CLI=""; case "$HOST" in gitea) CLI=tea;; github) CLI=gh;; esac
{ [ -n "$CLI" ] && command -v "$CLI" >/dev/null 2>&1; } || { echo "bootstrap: host=$HOST cli unavailable; no-op" >&2; exit 0; }

TYPES="mail gate blocker pipeline chat"
ROLES="pm am cm sm dm om om-test rm"

# Snapshot existing label names ONCE so the per-label loop is a cheap lookup.
# Tolerant parse: take the first whitespace/pipe-delimited token of each line
# that looks like one of our namespaced labels (type:* / role:*), so it works
# whether `tea`/`gh` print a bare name or a table row. A list failure leaves
# the snapshot empty -> we fall back to create-and-report (never a hard error).
existing_labels() {
  if [ "$HOST" = gitea ]; then tea labels list 2>/dev/null
  else gh label list 2>/dev/null; fi
}
EXISTING="$(existing_labels | grep -oE '(type|role):[a-z-]+' | sort -u)"

label_exists() { printf '%s\n' "$EXISTING" | grep -qxF "$1"; }

mklabel() { # <label> <color> — query-then-skip; never blind-create on a dup
  if label_exists "$1"; then echo "exists: $1"; return 0; fi
  if [ "$HOST" = gitea ]; then tea labels create --name "$1" --color "$2" >/dev/null 2>&1 && echo "created: $1" || echo "error: $1";
  else gh label create "$1" --color "$2" >/dev/null 2>&1 && echo "created: $1" || echo "error: $1"; fi
}
for t in $TYPES; do mklabel "type:$t" "0366d6"; done
for r in $ROLES; do mklabel "role:$r" "5319e7"; done

echo "board: no automated board creation on this host; create it manually per docs/runbooks/issue-board-setup.md (manual)"
exit 0
