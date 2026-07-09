#!/usr/bin/env bash
# Dependency-free test harness for tools/issue-sync.sh.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUT="$ROOT/tools/issue-sync.sh"
MKFAKE="$ROOT/tools/tests/fixtures/make-fake-provider.sh"
pass=0; fail=0
check() { local desc="$1"; shift; if "$@"; then echo "ok   - $desc"; pass=$((pass+1)); else echo "FAIL - $desc"; fail=$((fail+1)); fi; }

# usage: missing required flags -> exit 2
"$SUT" >/dev/null 2>&1; check "no args -> exit 2" test $? -eq 2
"$SUT" sync --type mail >/dev/null 2>&1; check "missing --packet -> exit 2" test $? -eq 2
"$SUT" sync --type bogus --packet x >/dev/null 2>&1; check "bad --type -> exit 2" test $? -eq 2

# disabled (MINION_ISSUES unset) -> no-op exit 0
TMP="$(mktemp -d)"; mkdir -p "$TMP/p"
( cd "$TMP" && unset MINION_ISSUES; "$SUT" sync --type mail --packet p >/dev/null 2>&1 ); check "disabled -> exit 0 noop" test $? -eq 0

# enabled but host CLI absent -> graceful no-op exit 0
( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  PATH="/usr/bin:/bin" MINION_ISSUES=on "$SUT" sync --type mail --packet p >/dev/null 2>&1 ); check "cli absent -> exit 0 noop" test $? -eq 0
rm -rf "$TMP"

# host detection
TMP="$(mktemp -d)"
( cd "$TMP" && git init -q && git remote add origin https://github.com/o/r.git
  test "$("$SUT" host)" = github ); check "github.com -> github" test $? -eq 0
( cd "$TMP" && git remote set-url origin https://git.example.net/o/r.git
  test "$("$SUT" host)" = gitea ); check "self-hosted -> gitea" test $? -eq 0
( cd "$TMP" && export MINION_ISSUE_HOST=github; test "$("$SUT" host)" = github ); check "env override wins" test $? -eq 0
( cd "$TMP" && git remote remove origin; test "$("$SUT" host)" = none ); check "no remote -> none" test $? -eq 0
rm -rf "$TMP"

# render: mail packet derivation
TMP="$(mktemp -d)"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-authcheck"; mkdir -p "$PKT"
printf 'request body here\n' > "$PKT/request.md"
OUT="$("$SUT" render --type mail --packet "$PKT")"
echo "$OUT" | grep -q '^LABELS:.*type:mail'        ; check "mail -> type:mail label" test $? -eq 0
echo "$OUT" | grep -q '^LABELS:.*role:cm'          ; check "mail -> role:cm from dir" test $? -eq 0
echo "$OUT" | grep -q '^LABELS:.*role:sm'          ; check "mail -> role:sm from dir" test $? -eq 0
echo "$OUT" | grep -q '^ASSIGNEE: *$'              ; check "mail -> no assignee" test $? -eq 0
echo "$OUT" | grep -qF 'edit the packet, not this issue' ; check "body has banner" test $? -eq 0
echo "$OUT" | grep -qF 'request body here'         ; check "body has packet content" test $? -eq 0
# gate -> operator assignee
OUT="$(MINION_OPERATOR=operator1 "$SUT" render --type gate --packet "$PKT")"
echo "$OUT" | grep -q '^ASSIGNEE: operator1'       ; check "gate -> operator assignee" test $? -eq 0
echo "$OUT" | grep -q '^LABELS:.*type:gate'        ; check "gate -> type:gate label" test $? -eq 0
rm -rf "$TMP"

# Gitea create -> sidecar written; second sync -> edit (idempotent)
TMP="$(mktemp -d)"; BIN="$TMP/bin"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-x"; mkdir -p "$PKT"
printf 'hi\n' > "$PKT/request.md"
bash "$MKFAKE" "$BIN" tea 0 "https://git.example.net/o/r/issues/42"
( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" sync --type mail --packet "$PKT" >/dev/null 2>&1 )
check "gitea create -> exit 0" test $? -eq 0
check "create -> sidecar has issue number" bash -c "grep -q 42 '$PKT/.issue'"
check "create -> tea create invoked" bash -c "grep -q create '$BIN/tea.args'"
( cd "$TMP" && PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" sync --type mail --packet "$PKT" >/dev/null 2>&1 )
check "second sync -> tea edit invoked" bash -c "grep -q edit '$BIN/tea.args'"
rm -rf "$TMP"

# soft-fail: backend non-zero -> exit 4, sidecar still absent on first failed create
TMP="$(mktemp -d)"; BIN="$TMP/bin"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-y"; mkdir -p "$PKT"; printf 'hi\n' > "$PKT/request.md"
bash "$MKFAKE" "$BIN" tea 1 "boom"
( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" sync --type mail --packet "$PKT" >/dev/null 2>&1 )
check "backend fail -> exit 4" test $? -eq 4
check "backend fail -> no sidecar written" bash -c "! test -e '$PKT/.issue'"
rm -rf "$TMP"

# GitHub backend: create -> sidecar; uses gh
TMP="$(mktemp -d)"; BIN="$TMP/bin"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-z"; mkdir -p "$PKT"; printf 'hi\n' > "$PKT/request.md"
bash "$MKFAKE" "$BIN" gh 0 "https://github.com/o/r/issues/7"
( cd "$TMP" && git init -q && git remote add origin https://github.com/o/r.git
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" sync --type mail --packet "$PKT" >/dev/null 2>&1 )
check "github create -> exit 0" test $? -eq 0
check "github create -> sidecar=7" bash -c "grep -q 7 '$PKT/.issue'"
check "github -> gh issue create invoked" bash -c "grep -q 'issue' '$BIN/gh.args' && grep -q create '$BIN/gh.args'"
rm -rf "$TMP"

# --- Item 1: GitHub edit + soft-fail tests ---

# 1a: second sync on existing sidecar invokes gh issue edit
TMP="$(mktemp -d)"; BIN="$TMP/bin"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-ghedit"; mkdir -p "$PKT"; printf 'hi\n' > "$PKT/request.md"
bash "$MKFAKE" "$BIN" gh 0 "https://github.com/o/r/issues/9"
( cd "$TMP" && git init -q && git remote add origin https://github.com/o/r.git
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" sync --type mail --packet "$PKT" >/dev/null 2>&1 )
check "gh create first sync -> exit 0" test $? -eq 0
check "gh create -> sidecar written" bash -c "test -f '$PKT/.issue'"
: > "$BIN/gh.args"   # isolate the edit invocation's argv (create already ran above)
( cd "$TMP" && PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" sync --type mail --packet "$PKT" >/dev/null 2>&1 )
check "gh second sync -> exit 0 (idempotent edit)" test $? -eq 0
check "gh second sync -> gh issue edit invoked" bash -c "grep -q 'edit' '$BIN/gh.args'"
# Regression (bug-scrub Item 1): edit must re-apply labels via --add-label, else a
# re-sync updates title/body but leaves GitHub labels stale while the Gitea path
# corrects them (--add-labels). gh's edit flag is --add-label (NOT create's --label).
check "gh edit -> --add-label passed" bash -c "grep -qxF -- '--add-label' '$BIN/gh.args'"
check "gh edit -> labels value present (type:mail,role:...)" bash -c "grep -q 'type:mail,role:' '$BIN/gh.args'"
check "gh edit -> bare --label NOT used on edit (anchored)" bash -c "! grep -qxF -- '--label' '$BIN/gh.args'"
rm -rf "$TMP"

# 1b: gh non-zero exit -> exit 4, NO sidecar written on failed create
TMP="$(mktemp -d)"; BIN="$TMP/bin"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-ghfail"; mkdir -p "$PKT"; printf 'hi\n' > "$PKT/request.md"
bash "$MKFAKE" "$BIN" gh 1 "boom"
( cd "$TMP" && git init -q && git remote add origin https://github.com/o/r.git
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" sync --type mail --packet "$PKT" >/dev/null 2>&1 )
check "gh backend fail -> exit 4" test $? -eq 4
check "gh backend fail -> no sidecar written" bash -c "! test -e '$PKT/.issue'"
rm -rf "$TMP"

# --- Item 1c: gh fake flag-faithfulness (fixture rigor) ---
# The gh fake now REJECTS the wrong label flag on the wrong subcommand (mirrors
# the tea fake's 0.14.1 faithfulness), so a stale-flag regression in the github
# path fails at the fake instead of passing a dumb argv recorder. Assert the
# fake's validation directly — an untested fixture guard is theater.
TMP="$(mktemp -d)"; BIN="$TMP/bin"; bash "$MKFAKE" "$BIN" gh 0 "https://github.com/o/r/issues/1"
"$BIN/gh" issue create --title t --body b --label x >/dev/null 2>&1;     check "gh fake: --label OK on create" test $? -eq 0
"$BIN/gh" issue create --title t --body b --add-label x >/dev/null 2>&1; check "gh fake: --add-label REJECTED on create" test $? -ne 0
"$BIN/gh" issue create --title t --label x >/dev/null 2>&1;              check "gh fake: create requires --body" test $? -ne 0
"$BIN/gh" issue edit 1 --title t --add-label x >/dev/null 2>&1;          check "gh fake: --add-label OK on edit" test $? -eq 0
"$BIN/gh" issue edit 1 --title t --label x >/dev/null 2>&1;              check "gh fake: bare --label REJECTED on edit" test $? -ne 0
"$BIN/gh" issue edit --title t --add-label x >/dev/null 2>&1;            check "gh fake: edit requires issue number" test $? -ne 0
rm -rf "$TMP"

# --- Item 2: Hyphenated-topic parse test ---
# mail packet dir named 2026-06-29-cm-to-sm-auth-check-v2 must render role:cm AND role:sm
TMP="$(mktemp -d)"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-auth-check-v2"; mkdir -p "$PKT"
printf 'auth check body\n' > "$PKT/request.md"
OUT="$("$SUT" render --type mail --packet "$PKT")"
echo "$OUT" | grep -q '^LABELS:.*role:cm'; check "hyphenated-topic -> role:cm present" test $? -eq 0
echo "$OUT" | grep -qE '^LABELS:.*role:sm$'; check "hyphenated-topic -> role:sm exact (anchored, rejects role:sm-*)" test $? -eq 0
! echo "$OUT" | grep -q 'role:sm-'; check "hyphenated-topic -> no role:sm- corruption present" test $? -eq 0
rm -rf "$TMP"

# --- Item 3: Exact banner assertion ---
TMP="$(mktemp -d)"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-banner"; mkdir -p "$PKT"
printf 'banner test\n' > "$PKT/request.md"
OUT="$("$SUT" render --type mail --packet "$PKT")"
echo "$OUT" | grep -qF "Generated from $PKT — edit the packet, not this issue."
check "exact banner line with em dash and full path" test $? -eq 0
rm -rf "$TMP"

# --- Item 4: Blocker assignee test ---
TMP="$(mktemp -d)"; PKT="$TMP/minions/plans/blocker-item"; mkdir -p "$PKT"
printf 'blocker content\n' > "$PKT/request.md"
OUT="$(MINION_OPERATOR=operator1 "$SUT" render --type blocker --packet "$PKT")"
echo "$OUT" | grep -q '^ASSIGNEE: operator1'
check "blocker render -> ASSIGNEE: operator1" test $? -eq 0
rm -rf "$TMP"

# --- Item 5: Label comma-separation ---
TMP="$(mktemp -d)"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-labels"; mkdir -p "$PKT"
printf 'labels test\n' > "$PKT/request.md"
OUT="$("$SUT" render --type mail --packet "$PKT")"
echo "$OUT" | grep -q '^LABELS:.*type:mail,role:'
check "labels joined with commas (type:mail,role:...)" test $? -eq 0
rm -rf "$TMP"

# --- Item 6: Backend stderr surfaced on soft-fail ---
# Create a fake tea that writes to stderr (not just stdout) on failure
TMP="$(mktemp -d)"; BIN="$TMP/bin"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-stderr"; mkdir -p "$PKT"; printf 'hi\n' > "$PKT/request.md"
mkdir -p "$BIN"
cat > "$BIN/tea" <<'FAKE'
#!/usr/bin/env bash
printf '%s\n' "$@" >> "$(dirname "$0")/tea.args"
printf 'backend diagnostic: connection refused\n' >&2
exit 1
FAKE
chmod +x "$BIN/tea"
STDERR_OUT="$( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" sync --type mail --packet "$PKT" 2>&1 >/dev/null )"
check "stderr-surfaced soft-fail -> exit 4 contract held" test $? -eq 4
echo "$STDERR_OUT" | grep -q 'backend diagnostic'
check "backend stderr reaches wrapper stderr on soft-fail" test $? -eq 0
check "no sidecar written when backend fails with stderr" bash -c "! test -e '$PKT/.issue'"
rm -rf "$TMP"

# --- tea v0.14.1 compatibility (RED-first; the fake tea is 0.14.1-faithful) ---
# 0.14.1 renamed the issue-body flag to --description (-d) and the edit
# label flag to --add-labels. These cases FAIL on the legacy --body/--labels
# scripts and PASS only once the backend funcs use the 0.14.1 flag names.

# 7a: create uses --description (NOT --body), succeeds end-to-end on 0.14.1
TMP="$(mktemp -d)"; BIN="$TMP/bin"; PKT="$TMP/minions/mail/2026-06-29-cm-to-sm-teacreate"; mkdir -p "$PKT"
printf 'hi\n' > "$PKT/request.md"
bash "$MKFAKE" "$BIN" tea 0 "https://git.example.net/o/r/issues/55"
( cd "$TMP" && git init -q && git remote add origin https://git.example.net/o/r.git
  PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" sync --type mail --packet "$PKT" >/dev/null 2>&1 )
check "0.14.1 create -> exit 0" test $? -eq 0
check "0.14.1 create -> sidecar=55" bash -c "grep -q 55 '$PKT/.issue'"
check "0.14.1 create -> --description passed" bash -c "grep -q -- '--description' '$BIN/tea.args'"
check "0.14.1 create -> --body NOT passed" bash -c "! grep -q -- '--body' '$BIN/tea.args'"

# 7b: second sync edits an existing issue using --add-labels (NOT --labels).
# Reset tea.args first so the file holds ONLY the edit invocation's argv
# (create legitimately uses --labels on 0.14.1; we are asserting on edit).
: > "$BIN/tea.args"
( cd "$TMP" && PATH="$BIN:$PATH" MINION_ISSUES=on "$SUT" sync --type mail --packet "$PKT" >/dev/null 2>&1 )
check "0.14.1 edit -> exit 0" test $? -eq 0
check "0.14.1 edit -> 'issues edit' invoked" bash -c "grep -q edit '$BIN/tea.args'"
check "0.14.1 edit -> --add-labels passed" bash -c "grep -q -- '--add-labels' '$BIN/tea.args'"
check "0.14.1 edit -> --labels NOT passed (anchored, edit argv only)" bash -c "! grep -qxF -- '--labels' '$BIN/tea.args'"
check "0.14.1 edit -> --body NOT passed" bash -c "! grep -qxF -- '--body' '$BIN/tea.args'"
rm -rf "$TMP"

echo "issue-sync: $pass passed, $fail failed"; [ "$fail" -eq 0 ]
