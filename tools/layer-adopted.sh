#!/usr/bin/env bash
# layer-adopted.sh — shared fail-open adoption-record cross-check for
# remote-mutating layer tools. Parses the `adopted:` token for a given
# MINION_* key out of the operating repo's onboarding checklist. The env
# gate (MINION_* variable) stays primary; this is a secondary, fail-open
# cross-check consulted only after the gate has already passed. See
# docs/issue-mirror-model.md and the Optional Layers convention in
# MEMORY.md.
#
# Usage: layer-adopted.sh <MINION_* key>
#
# Checklist resolution order:
#   1. MINION_ADOPTION_CHECKLIST env override -> that path (tests use this).
#   2. Else "$(git -C "$PWD" rev-parse --show-toplevel)"/docs/operator-onboarding-checklist.md
#      (operating repo at cwd, NOT where this script is vendored).
#   3. Not found / not a git repo -> indeterminate (exit 2).
#
# Exit codes:
#   0 = adopted: on   (stdout: on)   -> caller proceeds
#   1 = adopted: off  (stdout: off)  -> caller no-ops (the new protection)
#   2 = indeterminate (stdout: unrecorded for data cases; usage error also
#       prints usage to stderr) -> caller proceeds. Only exit 1 gates.
#       Helper absent (127) must also mean proceed in callers.
set -uo pipefail

usage() { echo "usage: layer-adopted.sh <MINION_* key>" >&2; }

[ $# -eq 1 ] || { usage; exit 2; }
KEY="$1"

CHECKLIST=""
if [ -n "${MINION_ADOPTION_CHECKLIST:-}" ]; then
  CHECKLIST="$MINION_ADOPTION_CHECKLIST"
else
  TOPLEVEL="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$TOPLEVEL" ] && CHECKLIST="$TOPLEVEL/docs/operator-onboarding-checklist.md"
fi

if [ -z "$CHECKLIST" ] || [ ! -f "$CHECKLIST" ]; then
  echo unrecorded; exit 2
fi

LINE="$(grep -F "$KEY" "$CHECKLIST" 2>/dev/null | grep -F 'adopted:' | head -1 || true)"
[ -n "$LINE" ] || { echo unrecorded; exit 2; }

TOKEN="$(printf '%s\n' "$LINE" | grep -oE 'adopted:[[:space:]]*(on|off)' | head -1 || true)"
[ -n "$TOKEN" ] || { echo unrecorded; exit 2; }

VALUE="$(printf '%s' "$TOKEN" | sed -E 's/adopted:[[:space:]]*//')"
case "$VALUE" in
  on) echo on; exit 0;;
  off) echo off; exit 1;;
  *) echo unrecorded; exit 2;;
esac
