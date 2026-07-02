#!/usr/bin/env bash
# Dependency-free test harness for tools/xtool-call.sh.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUT="$ROOT/tools/xtool-call.sh"
MKFAKE="$ROOT/tools/tests/fixtures/make-fake-provider.sh"
pass=0; fail=0
check() { # check <desc> <cond-cmd...>
  local desc="$1"; shift
  if "$@"; then echo "ok   - $desc"; pass=$((pass+1));
  else echo "FAIL - $desc"; fail=$((fail+1)); fi
}

# --- usage error when required flags missing ---
"$SUT" >/dev/null 2>&1; check "no args -> exit 2" test $? -eq 2

# --- graceful degrade when provider binary absent ---
TMP="$(mktemp -d)"; OUT="$TMP/out"
PATH="/usr/bin:/bin" "$SUT" --provider codex --mode review --prompt "x" --out "$OUT" >/dev/null 2>&1
check "absent provider -> exit 3" test $? -eq 3
check "absent provider -> envelope written" bash -c "ls '$OUT'/xtool-codex-review-*.json >/dev/null 2>&1"
check "absent provider -> status provider-unavailable" bash -c "grep -q provider-unavailable '$OUT'/xtool-codex-review-*.json"
rm -rf "$TMP"

# --- review mode: codex invoked read-only, no worktree, output captured ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex
( cd "$TMP" && git init -q && git commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode review --target . --prompt "review please" --out "$OUT" >/dev/null 2>&1 )
check "codex review -> exit 0" test $? -eq 0
check "codex review -> read-only flag present" bash -c "grep -q 'read-only' '$BIN/codex.args'"
check "codex review -> raw output captured" bash -c "grep -rq FAKE_codex_OUTPUT '$OUT'"
check "codex review -> no worktree created" bash -c "! git -C '$TMP' worktree list 2>/dev/null | grep -q xtool/"
rm -rf "$TMP"

# --- review mode: copilot constrained, never granted write paths ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" copilot
( cd "$TMP" && git init -q && git commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider copilot --mode review --target . --prompt "review please" --out "$OUT" >/dev/null 2>&1 )
check "copilot review -> exit 0" test $? -eq 0
check "copilot review -> deny-tool read-only enforced" bash -c "grep -q 'deny-tool' '$BIN/copilot.args' && grep -q 'write' '$BIN/copilot.args'"
check "copilot review -> deny-tool shell enforced" bash -c "grep -q 'deny-tool' '$BIN/copilot.args' && grep -q 'shell' '$BIN/copilot.args'"
check "copilot review -> no write-path grant" bash -c "! grep -q 'allow-all-paths\|add-dir' '$BIN/copilot.args'"
rm -rf "$TMP"

# --- json_escape: special chars in --target do not break envelope ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex
( cd "$TMP" && git init -q && git commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode review --target 'a"b' --prompt "review please" --out "$OUT" >/dev/null 2>&1 )
check "json_escape -> target with quote produces escaped form" bash -c "grep -q 'a\\\\\"b' '$OUT'/xtool-codex-review-*.json"
check "json_escape -> envelope file not broken by bare quote" bash -c "! grep -q 'a\"b' '$OUT'/xtool-codex-review-*.json"
rm -rf "$TMP"

# --- delegate mode: isolated worktree+branch, no merge to caller branch ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex
( cd "$TMP" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )
HEAD_BEFORE="$( git -C "$TMP" rev-parse HEAD )"
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode delegate --role cm --topic demo --prompt "do work" --out "$OUT" >/dev/null 2>&1 )
check "codex delegate -> exit 0" test $? -eq 0
check "codex delegate -> branch created" bash -c "git -C '$TMP' branch --list 'xtool/codex-cm-demo' | grep -q xtool"
check "codex delegate -> worktree registered" bash -c "git -C '$TMP' worktree list | grep -q xtool"
check "codex delegate -> caller HEAD unchanged" test "$( git -C "$TMP" rev-parse HEAD )" = "$HEAD_BEFORE"
check "codex delegate -> envelope records branch" bash -c "grep -q 'xtool/codex-cm-demo' '$OUT'/xtool-codex-delegate-*.json"
check "codex delegate -> workspace-write sandbox" bash -c "grep -q 'workspace-write' '$BIN/codex.args'"
rm -rf "$TMP"

# --- delegate mode: copilot uses add-dir write scope, never allow-all-paths ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" copilot
( cd "$TMP" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )
HEAD_BEFORE="$( git -C "$TMP" rev-parse HEAD )"
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider copilot --mode delegate --role cm --topic demo --prompt "do work" --out "$OUT" >/dev/null 2>&1 )
check "copilot delegate -> exit 0" test $? -eq 0
check "copilot delegate -> add-dir present" bash -c "grep -q 'add-dir' '$BIN/copilot.args'"
check "copilot delegate -> allow-all-paths absent" bash -c "! grep -q 'allow-all-paths' '$BIN/copilot.args'"
check "copilot delegate -> caller HEAD unchanged" test "$( git -C "$TMP" rev-parse HEAD )" = "$HEAD_BEFORE"
rm -rf "$TMP"

# --- F2: delegate rejects path-unsafe --role/--topic (no worktree escapes containment) ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex
( cd "$TMP" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode delegate --role cm --topic '../../etc/x' --prompt p --out "$OUT" >/dev/null 2>&1 )
check "F2 delegate -> traversal topic exits 2" test $? -eq 2
check "F2 delegate -> traversal topic creates no worktree" bash -c "! git -C '$TMP' worktree list 2>/dev/null | grep -q xtool"
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode delegate --role cm --topic 'a b/c' --prompt p --out "$OUT" >/dev/null 2>&1 )
check "F2 delegate -> whitespace+slash topic exits 2" test $? -eq 2
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode delegate --role cm --topic ok.v1_2 --prompt p --out "$OUT" >/dev/null 2>&1 )
check "F2 delegate -> safe topic still allowed" bash -c "git -C '$TMP' branch --list 'xtool/codex-cm-ok.v1_2' | grep -q xtool"
rm -rf "$TMP"

# --- F4: failed delegate self-cleans (no diff) so a repeat same-topic run is not blocked ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex 1   # fake codex exits 1 (provider failure), writes nothing
( cd "$TMP" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode delegate --role cm --topic flaky --prompt p --out "$OUT" >/dev/null 2>&1 )
check "F4 delegate failure -> exit propagated (1)" test $? -eq 1
check "F4 delegate failure (no diff) -> worktree cleaned" bash -c "! git -C '$TMP' worktree list 2>/dev/null | grep -q codex-cm-flaky"
check "F4 delegate failure (no diff) -> branch cleaned" bash -c "! git -C '$TMP' branch --list 'xtool/codex-cm-flaky' | grep -q xtool"
bash "$MKFAKE" "$BIN" codex 0   # now a passing provider
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode delegate --role cm --topic flaky --prompt p --out "$OUT" >/dev/null 2>&1 )
check "F4 delegate retry after failure -> succeeds (no stale-branch dead-end)" test $? -eq 0
rm -rf "$TMP"

# --- F4 (committed work): a failed delegate that COMMITTED must NOT lose the commit ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"; mkdir -p "$BIN"
# fake codex that commits work inside the worktree, then exits non-zero
cat > "$BIN/codex" <<'FAKE'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$(dirname "$0")/codex.args"
echo "delegated content" > delegated.txt
git -c user.email=t@t -c user.name=t add -A
git -c user.email=t@t -c user.name=t commit -q -m "delegate work"
exit 1
FAKE
chmod +x "$BIN/codex"
( cd "$TMP" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode delegate --role cm --topic committed --prompt p --out "$OUT" >/dev/null 2>&1 )
check "F4 commit-then-fail -> exit 1 propagated" test $? -eq 1
check "F4 commit-then-fail -> branch KEPT (committed work not deleted)" bash -c "git -C '$TMP' branch --list 'xtool/codex-cm-committed' | grep -q xtool"
check "F4 commit-then-fail -> worktree KEPT" bash -c "git -C '$TMP' worktree list | grep -q codex-cm-committed"
check "F4 commit-then-fail -> the commit is recoverable" bash -c "git -C '$TMP' log --oneline 'xtool/codex-cm-committed' | grep -q 'delegate work'"
rm -rf "$TMP"

# --- F2 edge: charset-safe but git-ref-invalid topic is rejected (exit 2) ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex
( cd "$TMP" && git init -q && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode delegate --role cm --topic 'x.lock' --prompt p --out "$OUT" >/dev/null 2>&1 )
check "F2 edge -> invalid git ref (.lock) exits 2" test $? -eq 2
rm -rf "$TMP"

# --- A: `--prompt -` reads the prompt from STDIN (not the literal "-") ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex
( cd "$TMP" && git init -q && git commit -q --allow-empty -m init )
( cd "$TMP" && printf 'PROMPT_VIA_STDIN_DASH' | PATH="$BIN:$PATH" "$SUT" --provider codex --mode review --prompt - --target . --out "$OUT" >/dev/null 2>&1 )
check "A --prompt - -> exit 0" test $? -eq 0
check "A --prompt - -> stdin used as prompt" bash -c "grep -q PROMPT_VIA_STDIN_DASH '$BIN/codex.args'"
check "A --prompt - -> literal dash not sent as prompt" bash -c "! grep -qx -- - '$BIN/codex.args'"
rm -rf "$TMP"

# --- A regression: a standalone '-' token still reads stdin ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex
( cd "$TMP" && git init -q && git commit -q --allow-empty -m init )
( cd "$TMP" && printf 'PROMPT_VIA_STDIN_BARE' | PATH="$BIN:$PATH" "$SUT" --provider codex --mode review --target . --out "$OUT" - >/dev/null 2>&1 )
check "A bare - -> stdin used as prompt" bash -c "grep -q PROMPT_VIA_STDIN_BARE '$BIN/codex.args'"
rm -rf "$TMP"

# --- B: review-mode envelope status reflects provider failure (not a blanket "ok") ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex 1   # provider exits non-zero
( cd "$TMP" && git init -q && git commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode review --target . --prompt p --out "$OUT" >/dev/null 2>&1 )
check "B review provider-fail -> exit 1 propagated" test $? -eq 1
check "B review provider-fail -> envelope NOT status ok" bash -c "! grep -q '\"status\": \"ok\"' '$OUT'/xtool-codex-review-*.json"
check "B review provider-fail -> envelope status review-failed" bash -c "grep -q '\"status\": \"review-failed\"' '$OUT'/xtool-codex-review-*.json"
rm -rf "$TMP"

# --- B: review success still reports status ok (lock the happy path) ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex
( cd "$TMP" && git init -q && git commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode review --target . --prompt p --out "$OUT" >/dev/null 2>&1 )
check "B review success -> envelope status ok" bash -c "grep -q '\"status\": \"ok\"' '$OUT'/xtool-codex-review-*.json"
rm -rf "$TMP"

# --- C: empty prompt is rejected (exit 2) before any provider call ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"
bash "$MKFAKE" "$BIN" codex
( cd "$TMP" && git init -q && git commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode review --target . --prompt "" --out "$OUT" >/dev/null 2>&1 )
check "C empty --prompt -> exit 2" test $? -eq 2
check "C empty --prompt -> provider never invoked" bash -c "! test -f '$BIN/codex.args'"
( cd "$TMP" && printf '' | PATH="$BIN:$PATH" "$SUT" --provider codex --mode review --target . --prompt - --out "$OUT" >/dev/null 2>&1 )
check "C --prompt - with empty stdin -> exit 2" test $? -eq 2
rm -rf "$TMP"

# --- C: provider exits 0 but produced empty output -> flagged, not a false "ok" ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"; mkdir -p "$BIN"
cat > "$BIN/codex" <<'FAKE'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$(dirname "$0")/codex.args"
exit 0
FAKE
chmod +x "$BIN/codex"
( cd "$TMP" && git init -q && git commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider codex --mode review --target . --prompt p --out "$OUT" >/dev/null 2>&1 )
check "C empty provider output -> exit 4" test $? -eq 4
check "C empty provider output -> envelope status review-empty-output" bash -c "grep -q 'review-empty-output' '$OUT'/xtool-codex-review-*.json"
check "C empty provider output -> not a false ok" bash -c "! grep -q '\"status\": \"ok\"' '$OUT'/xtool-codex-review-*.json"
rm -rf "$TMP"

# --- C (copilot path): the empty-output flag also covers the original copilot
#     regression (copilot exited 0 on a bad prompt but produced a garbage/empty review) ---
TMP="$(mktemp -d)"; OUT="$TMP/out"; BIN="$TMP/bin"; mkdir -p "$BIN"
cat > "$BIN/copilot" <<'FAKE'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$(dirname "$0")/copilot.args"
exit 0
FAKE
chmod +x "$BIN/copilot"
( cd "$TMP" && git init -q && git commit -q --allow-empty -m init )
( cd "$TMP" && PATH="$BIN:$PATH" "$SUT" --provider copilot --mode review --target . --prompt p --out "$OUT" >/dev/null 2>&1 )
check "C (copilot) empty output -> exit 4" test $? -eq 4
check "C (copilot) empty output -> status review-empty-output" bash -c "grep -q 'review-empty-output' '$OUT'/xtool-copilot-review-*.json"
rm -rf "$TMP"

echo "----- $pass passed, $fail failed -----"
test "$fail" -eq 0
