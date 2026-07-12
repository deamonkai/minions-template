#!/usr/bin/env bash
# Dependency-free test harness for tools/layer-adopted.sh (F1).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUT="$ROOT/tools/layer-adopted.sh"
pass=0; fail=0
check() { local desc="$1"; shift; if "$@"; then echo "ok   - $desc"; pass=$((pass+1)); else echo "FAIL - $desc"; fail=$((fail+1)); fi; }

TMP="$(mktemp -d)"

# adopted-on -> exit 0, stdout on
CL="$TMP/on.md"; printf 'Issue mirror (MINION_ISSUES) — adopted: on — date: 2026-07-10\n' > "$CL"
OUT="$(MINION_ADOPTION_CHECKLIST="$CL" "$SUT" MINION_ISSUES)"; RC=$?
check "adopted-on -> exit 0" test "$RC" -eq 0
check "adopted-on -> stdout on" test "$OUT" = "on"

# adopted-off -> exit 1, stdout off
CL="$TMP/off.md"; printf 'Issue mirror (MINION_ISSUES) — adopted: off — date: 2026-07-10\n' > "$CL"
OUT="$(MINION_ADOPTION_CHECKLIST="$CL" "$SUT" MINION_ISSUES)"; RC=$?
check "adopted-off -> exit 1" test "$RC" -eq 1
check "adopted-off -> stdout off" test "$OUT" = "off"

# adopted-unset -> exit 2
CL="$TMP/unset.md"; printf 'Issue mirror (MINION_ISSUES) — adopted: unset — date: 2026-07-10\n' > "$CL"
OUT="$(MINION_ADOPTION_CHECKLIST="$CL" "$SUT" MINION_ISSUES)"; RC=$?
check "adopted-unset -> exit 2" test "$RC" -eq 2
check "adopted-unset -> stdout unrecorded" test "$OUT" = "unrecorded"

# token absent on key line -> exit 2
CL="$TMP/notoken.md"; printf 'Issue mirror (MINION_ISSUES) — date: 2026-07-10\n' > "$CL"
OUT="$(MINION_ADOPTION_CHECKLIST="$CL" "$SUT" MINION_ISSUES)"; RC=$?
check "token absent -> exit 2" test "$RC" -eq 2
check "token absent -> stdout unrecorded" test "$OUT" = "unrecorded"

# key line absent -> exit 2
CL="$TMP/nokey.md"; printf 'Second brain (MINION_SECONDBRAIN) — adopted: on — date: 2026-07-10\n' > "$CL"
OUT="$(MINION_ADOPTION_CHECKLIST="$CL" "$SUT" MINION_ISSUES)"; RC=$?
check "key line absent -> exit 2" test "$RC" -eq 2
check "key line absent -> stdout unrecorded" test "$OUT" = "unrecorded"

# checklist file absent -> exit 2
OUT="$(MINION_ADOPTION_CHECKLIST="$TMP/does-not-exist.md" "$SUT" MINION_ISSUES)"; RC=$?
check "checklist absent -> exit 2" test "$RC" -eq 2
check "checklist absent -> stdout unrecorded" test "$OUT" = "unrecorded"

# malformed value (adopted: banana) -> exit 2
CL="$TMP/malformed.md"; printf 'Issue mirror (MINION_ISSUES) — adopted: banana — date: 2026-07-10\n' > "$CL"
OUT="$(MINION_ADOPTION_CHECKLIST="$CL" "$SUT" MINION_ISSUES)"; RC=$?
check "malformed value -> exit 2" test "$RC" -eq 2
check "malformed value -> stdout unrecorded" test "$OUT" = "unrecorded"

# usage error (no arg) -> exit 2 + stderr usage
"$SUT" >/dev/null 2>"$TMP/usage.err"; RC=$?
check "no arg -> exit 2" test "$RC" -eq 2
check "no arg -> stderr usage" bash -c "grep -q usage '$TMP/usage.err'"

# right-key-among-many (all five layer lines) -> query MINION_SECONDBRAIN off -> exit 1
CL="$TMP/many.md"
cat > "$CL" <<'EOF'
Issue mirror (MINION_ISSUES) — adopted: on — date: 2026-07-10
Second brain (MINION_SECONDBRAIN) — adopted: off — date: 2026-07-10
Memory recall (MINION_MEMORY) — adopted: unset — date: 2026-07-10
Skill adoption (MINION_SKILLS) — adopted: on — date: 2026-07-10
Coordinator mode — adopted: unset — date: 2026-07-10
EOF
OUT="$(MINION_ADOPTION_CHECKLIST="$CL" "$SUT" MINION_SECONDBRAIN)"; RC=$?
check "right-key-among-many -> exit 1" test "$RC" -eq 1
check "right-key-among-many -> stdout off" test "$OUT" = "off"

# prose-mention masking (F1): a checklist line that mentions the key but
# carries no adopted: token must not defeat the two-stage
# `grep -F "$KEY" | grep -F 'adopted:'` extraction. If someone collapses the
# pipeline to a single-stage grep, `head -1` can grab the prose line instead
# of the real record, changing the result. Cover prose-before and
# prose-after ordering.

# prose line BEFORE the real adopted: off line
CL="$TMP/prose-before.md"
cat > "$CL" <<'EOF'
Note: MINION_ISSUES is referenced in this doc for context only.
Issue mirror (MINION_ISSUES) — adopted: off — date: 2026-07-10
EOF
OUT="$(MINION_ADOPTION_CHECKLIST="$CL" "$SUT" MINION_ISSUES)"; RC=$?
check "prose-before-key-line -> exit 1" test "$RC" -eq 1
check "prose-before-key-line -> stdout off" test "$OUT" = "off"

# prose line AFTER the real adopted: off line
CL="$TMP/prose-after.md"
cat > "$CL" <<'EOF'
Issue mirror (MINION_ISSUES) — adopted: off — date: 2026-07-10
Note: MINION_ISSUES is referenced in this doc for context only.
EOF
OUT="$(MINION_ADOPTION_CHECKLIST="$CL" "$SUT" MINION_ISSUES)"; RC=$?
check "prose-after-key-line -> exit 1" test "$RC" -eq 1
check "prose-after-key-line -> stdout off" test "$OUT" = "off"

rm -rf "$TMP"

echo "layer-adopted: $pass passed, $fail failed"; [ "$fail" -eq 0 ]
