#!/usr/bin/env bash
# skill-scout.test.sh — self-tested harness for tools/skill-scout.sh (the
# skill-adoption Scout convenience wrapper: findings-only `survey`).
# House style (second-brain.test.sh): dependency-free, check()-driven, prints
# "----- N passed, M failed -----" and exits nonzero on any failure.
#
# TEST-ONLY: exercises tools/skill-scout.sh as built; never patches it.
#
# The npx-present vs npx-absent branch is exercised deterministically by
# manipulating PATH for the child so `command -v npx` resolves or not,
# independent of the host having npx installed. Env is scoped per child via
# `env`, never leaked into this shell.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SC="$ROOT/tools/skill-scout.sh"

pass=0; fail=0
check() { local desc="$1"; shift; if "$@"; then echo "ok   - $desc"; pass=$((pass+1)); else echo "FAIL - $desc"; fail=$((fail+1)); fi; }

[ -f "$SC" ] || { echo "FAIL - skill-scout.sh not found at $SC"; echo "----- 0 passed, 1 failed -----"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ERRFILE="$WORK/stderr"

# run_sc ENV=val... -- ARGS...  -> sets OUT, ERRTXT, RC
run_sc() {
  local envs=() args=() seen_dd=0 a
  for a in "$@"; do
    if [ "$seen_dd" -eq 0 ] && [ "$a" = "--" ]; then seen_dd=1; continue; fi
    if [ "$seen_dd" -eq 0 ]; then envs+=("$a"); else args+=("$a"); fi
  done
  OUT="$(env ${envs[@]+"${envs[@]}"} "$SC" ${args[@]+"${args[@]}"} 2>"$ERRFILE")"
  RC=$?
  ERRTXT="$(cat "$ERRFILE")"
}

expect_rc()         { local want="$1"; shift; run_sc "$@"; [ "$RC" -eq "$want" ]; }
expect_rc_out_has() { local want="$1" needle="$2"; shift 2; run_sc "$@"; [ "$RC" -eq "$want" ] && printf '%s' "$OUT" | grep -qF -- "$needle"; }
expect_rc_err_has() { local want="$1" needle="$2"; shift 2; run_sc "$@"; [ "$RC" -eq "$want" ] && printf '%s' "$ERRTXT" | grep -qF -- "$needle"; }

echo "=== skill-scout.test.sh ROOT: $ROOT ==="

# Two PATHs to exercise both branches deterministically, independent of whether
# the host has npx:
#   FAKEBIN  — a fake npx on PATH (present branch). It must never actually run
#              (the wrapper only PRINTS the npx command, never executes it).
#   NPXLESS  — bash + cat symlinked in, but NO npx (absent branch). The
#              interpreter must stay reachable: `#!/usr/bin/env bash` makes env
#              search PATH for bash, so a truly empty PATH would fail to launch.
FAKEBIN="$WORK/fakebin"; mkdir -p "$FAKEBIN"
printf '#!/usr/bin/env bash\necho "should never run"\n' > "$FAKEBIN/npx"; chmod +x "$FAKEBIN/npx"
NPXLESS="$WORK/npxless"; mkdir -p "$NPXLESS"
ln -s "$(command -v bash)" "$NPXLESS/bash"
ln -s "$(command -v cat)"  "$NPXLESS/cat"

# ============================================================================
# 1. Usage / dispatch
# ============================================================================
check "no args -> usage exit 2"                    expect_rc 2 --
check "unknown subcommand -> exit 2"               expect_rc 2 -- bogus
check "survey missing query -> exit 2"             expect_rc 2 MINION_SKILLS=on -- survey
check "survey extra args -> exit 2"                expect_rc 2 MINION_SKILLS=on -- survey foo bar

# ============================================================================
# 2. Gating — never fails on a valid call; no-op exit 0 when gate off
# ============================================================================
check "gate off -> no-op exit 0"                   expect_rc 0 MINION_SKILLS=off -- survey "code review"
check "gate off -> stderr says disabled"           expect_rc_err_has 0 "disabled" MINION_SKILLS=off -- survey "code review"

# ============================================================================
# 3. survey — always exit 0; findings-only scaffold; npx branch selection
# ============================================================================
check "survey (npx present) -> exit 0"             expect_rc 0 MINION_SKILLS=on "PATH=$FAKEBIN:/usr/bin:/bin" -- survey "code review"
check "survey (npx present) -> npx guidance"       expect_rc_out_has 0 "npx skills search" MINION_SKILLS=on "PATH=$FAKEBIN:/usr/bin:/bin" -- survey "code review"
check "survey (npx present) -> never auto-installs" expect_rc_out_has 0 "do not 'npx skills add'" MINION_SKILLS=on "PATH=$FAKEBIN:/usr/bin:/bin" -- survey "code review"
check "survey (npx absent) -> exit 0 fallback"     expect_rc 0 MINION_SKILLS=on "PATH=$NPXLESS" -- survey "code review"
check "survey (npx absent) -> WebFetch/web-UI"     expect_rc_out_has 0 "WebFetch" MINION_SKILLS=on "PATH=$NPXLESS" -- survey "code review"
check "survey (npx absent) -> points at skills.sh" expect_rc_out_has 0 "skills.sh" MINION_SKILLS=on "PATH=$NPXLESS" -- survey "code review"
check "survey -> findings-only scaffold present"   expect_rc_out_has 0 "findings-only survey scaffold" MINION_SKILLS=on "PATH=$FAKEBIN:/usr/bin:/bin" -- survey "code review"
check "survey -> reminds fetched content is inert data" expect_rc_out_has 0 "inert" MINION_SKILLS=on "PATH=$FAKEBIN:/usr/bin:/bin" -- survey "code review"
check "survey -> reminds RM never installs"        expect_rc_out_has 0 "never installs" MINION_SKILLS=on "PATH=$FAKEBIN:/usr/bin:/bin" -- survey "code review"

echo "----- $pass passed, $fail failed -----"
test "$fail" -eq 0
