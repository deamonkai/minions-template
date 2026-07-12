#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUT="$ROOT/tools/issue-board-bootstrap.sh"
MKFAKE="$ROOT/tools/tests/fixtures/make-fake-provider.sh"
pass=0; fail=0
check() { local desc="$1"; shift; if "$@"; then echo "ok   - $desc"; pass=$((pass+1)); else echo "FAIL - $desc"; fail=$((fail+1)); fi; }

# disabled -> no-op exit 0
( unset MINION_ISSUES; "$SUT" >/dev/null 2>&1 ); check "disabled -> exit 0" test $? -eq 0

# --help / -h / bare help -> exit 0, usage on stderr, no side effects (gate ON)
TMP="$(mktemp -d)"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" tea 0 "ok"
( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" --help > "$TMP/help.out" 2>&1 )
check "--help -> exit 0" test $? -eq 0
check "--help -> output greps usage" bash -c "grep -qi usage '$TMP/help.out'"
check "--help -> no tea.args" bash -c "! test -e '$BIN/tea.args'"
check "--help -> no tea.labels.created" bash -c "! test -e '$BIN/tea.labels.created'"
( cd "$TMP" && PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" -h >/dev/null 2>&1 ); check "-h -> exit 0" test $? -eq 0
( cd "$TMP" && PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" help >/dev/null 2>&1 ); check "bare help -> exit 0" test $? -eq 0
check "-h/help -> still no tea.args" bash -c "! test -e '$BIN/tea.args'"
rm -rf "$TMP"

# unknown flag -> exit 2, no side effects
TMP="$(mktemp -d)"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" tea 0 "ok"
( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" --bogus >/dev/null 2>&1 )
check "--bogus -> exit 2" test $? -eq 2
check "--bogus -> no tea.args" bash -c "! test -e '$BIN/tea.args'"
rm -rf "$TMP"

# env on + checklist adopted:off -> exit 0 no-op, no tea.args
TMP="$(mktemp -d)"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" tea 0 "ok"
( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  mkdir -p docs && printf 'Issue mirror (MINION_ISSUES) — adopted: off — date: 2026-07-10\n' > docs/operator-onboarding-checklist.md
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" >/dev/null 2>&1 )
check "adopted:off -> exit 0" test $? -eq 0
check "adopted:off -> no tea.args" bash -c "! test -e '$BIN/tea.args'"
rm -rf "$TMP"

# env on + checklist adopted:unset -> proceeds (tea.args exists)
TMP="$(mktemp -d)"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" tea 0 "ok"
( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  mkdir -p docs && printf 'Issue mirror (MINION_ISSUES) — adopted: unset — date: 2026-07-10\n' > docs/operator-onboarding-checklist.md
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" >/dev/null 2>&1 )
check "adopted:unset -> exit 0" test $? -eq 0
check "adopted:unset -> tea.args exists (proceeds)" bash -c "test -e '$BIN/tea.args'"
rm -rf "$TMP"

# enabled gitea -> creates labels, reports board as manual-or-created
# (no checklist present: fail-open-on-absent covers the same path as adopted:unset)
TMP="$(mktemp -d)"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" tea 0 "ok"
( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" > "$TMP/report" 2>&1 )
check "bootstrap -> exit 0" test $? -eq 0
check "bootstrap -> tea label create invoked" bash -c "grep -q label '$BIN/tea.args'"
for lbl in type:mail type:gate type:blocker type:pipeline type:chat \
            role:pm role:am role:cm role:sm role:dm role:om role:om-test role:rm; do
  check "bootstrap -> creates $lbl" bash -c "grep -q '$lbl' '$BIN/tea.args'"
done
check "bootstrap -> report mentions board" bash -c "grep -qi board '$TMP/report'"
rm -rf "$TMP"

# --- Idempotency on tea v0.14.1 (RED-first) ---
# On 0.14.1 `tea labels create` EXITS 0 on a duplicate name and creates a
# SECOND same-named label (it does NOT fail on collision). A genuinely
# idempotent bootstrap must query existing labels and SKIP, so a re-run
# leaves exactly ONE of each label, not two. The fake tea records every
# create in tea.labels.created; we assert the count stays at one set.
TMP="$(mktemp -d)"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" tea 0 "ok"
run_bootstrap() { ( cd "$TMP" && git init -q 2>/dev/null; git remote add origin https://git.example.net/o/r.git 2>/dev/null
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" >/dev/null 2>&1 ); }
run_bootstrap
run_bootstrap   # re-run: must NOT double the labels
# 13 labels total (5 type: + 8 role:); a non-idempotent run would record 26.
created_count="$(wc -l < "$BIN/tea.labels.created" | tr -d ' ')"
check "re-run -> exactly 13 label creates (no doubling)" test "$created_count" -eq 13
check "re-run -> each label created at most once" \
  bash -c "test \$(sort '$BIN/tea.labels.created' | uniq -d | wc -l | tr -d ' ') -eq 0"
check "re-run -> bootstrap still exit 0" run_bootstrap
rm -rf "$TMP"

# --- F2: helper-absent fail-open at the caller integration point ---
# Copy the tool (+ its deps) into a temp dir, then delete layer-adopted.sh so
# the SUT's `$(dirname "$0")/layer-adopted.sh` resolves to nothing (exit 127).
# Even with a checklist recording adopted:off, a MISSING helper must mean
# proceed: the fail-open cross-check can only ADD a no-op, never enable one
# on its own absence.
TMP="$(mktemp -d)"; BIN="$TMP/bin"; TOOLCOPY="$TMP/toolcopy"
mkdir -p "$TOOLCOPY"
cp -r "$ROOT/tools/"*.sh "$TOOLCOPY/" 2>/dev/null
rm -f "$TOOLCOPY/layer-adopted.sh"
check "helper-absent fixture -> layer-adopted.sh really gone" bash -c "! test -e '$TOOLCOPY/layer-adopted.sh'"
bash "$MKFAKE" "$BIN" tea 0 "ok"
( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  mkdir -p docs && printf 'Issue mirror (MINION_ISSUES) — adopted: off — date: 2026-07-10\n' > docs/operator-onboarding-checklist.md
  PATH="$BIN:$PATH" MINION_ISSUES=on "$TOOLCOPY/issue-board-bootstrap.sh" >/dev/null 2>&1 )
check "helper-absent -> exit 0" test $? -eq 0
check "helper-absent -> proceeds despite adopted:off (tea.args exists)" bash -c "test -e '$BIN/tea.args'"
rm -rf "$TMP"

echo "issue-board-bootstrap: $pass passed, $fail failed"; [ "$fail" -eq 0 ]
