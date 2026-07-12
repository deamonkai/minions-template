#!/usr/bin/env bash
# instruction-size.test.sh — whole-file word-budget guard for the
# instruction/bootstrap surface (CLAUDE.md, AGENTS.md, MEMORY.md, role
# charters, SME files, etc). Why: the instruction surface is the token cost
# every session pays at bootstrap; without a budget it bloats unnoticed as
# the template is adopted and extended (see MEMORY.md, Instruction-Surface
# Size Budgets). Bash 3.2 safe. Style precedents:
# tools/layer-adopted.sh (fail-open override parse),
# tools/tests/manifest-completeness.test.sh (--root + self-test idiom),
# tools/tests/layer-adopted.test.sh (env fixture isolation).
#
# Modes:
#   (no args)        = self-test (mktemp fixtures) + real-repo sweep;
#                       exit 1 on any breach in either half.
#   --root <dir>     = sweep only that tree; NO self-test (prevents
#                       recursion — self-test child invocations use this).
#   --report [--root <dir>] = percent-of-budget table for every present
#                       surface, sorted desc by usage; exit 0 always; no
#                       self-test.
#
# Env overrides (isolation for the self-test children and for downstreams):
#   MINION_INSTRUCTION_ROOT     - root to sweep (default: repo this script
#                                 lives in, or --root if given)
#   MINION_INSTRUCTION_BUDGETS  - override-file path (default:
#                                 <root>/docs/instruction-size-budgets.md)
set -uo pipefail

# default_budget <key> -> echoes the template default word budget, or empty
# if the key is not budgeted at all (unbudgeted surfaces are skipped).
# NOTE: case pattern order gives named-beats-class automatically — bash's
# `case` takes the first matching pattern, and the named/exact patterns are
# listed before the class globs.
default_budget() {
  case "$1" in
    CLAUDE.md|AGENTS.md|.github/copilot-instructions.md) echo 600;;
    INIT.md|AI.md) echo 1800;;
    MEMORY.md) echo 9000;;
    minions/capabilities.md) echo 1500;;
    minions/review-matrix.md) echo 1200;;
    feedback.md) echo 3000;;
    minions/smes/README.md) echo 2000;;
    minions/roles/PM.md) echo 3000;;
    minions/roles/*.md) echo 2400;;
    minions/smes/*.md) echo 1100;;
    *) echo "";;
  esac
}

# NAMED surfaces checked by exact path (skip silently if absent — downstreams
# may not export every surface).
NAMED_FILES="CLAUDE.md AGENTS.md .github/copilot-instructions.md INIT.md AI.md MEMORY.md minions/capabilities.md minions/review-matrix.md feedback.md minions/smes/README.md"

# CLASS globs, iterated with [ -e "$f" ] || continue (bash 3.2, no nullglob).
CLASS_GLOBS="minions/roles/*.md minions/smes/*.md"

# class_key_for <path relative to root> -> the class-glob string that path
# belongs to (used to look up class defaults/overrides), or empty.
class_key_for() {
  case "$1" in
    minions/roles/*.md) echo "minions/roles/*.md";;
    minions/smes/*.md) echo "minions/smes/*.md";;
    *) echo "";;
  esac
}

# parse_override <override-file> <key> -> echoes the fail-open override
# budget for KEY (exact path or class-glob string), or empty if none.
# A line is an override iff it matches
#   ^[[:space:]]*KEY[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*$
# with a positive integer. Malformed lines are skipped silently
# (fail-open); absent/empty file = defaults.
parse_override() {
  local file="$1" key="$2" line lhs rhs
  [ -f "$file" ] || { echo ""; return 0; }
  while IFS= read -r line; do
    case "$line" in
      *=*) : ;;
      *) continue;;
    esac
    lhs="${line%%=*}"
    rhs="${line#*=}"
    # trim surrounding whitespace from lhs/rhs
    lhs="$(printf '%s' "$lhs" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    rhs="$(printf '%s' "$rhs" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ "$lhs" = "$key" ] || continue
    case "$rhs" in
      ''|*[!0-9]*) continue;;   # not a positive integer -> malformed, skip
    esac
    [ "$rhs" -gt 0 ] 2>/dev/null || continue
    echo "$rhs"
    return 0
  done < "$file"
  echo ""
}

# effective_budget <root> <override-file> <relpath> -> the winning budget per
# precedence: override-exact > override-class > default-exact >
# default-class > not-budgeted (empty = skip).
effective_budget() {
  local override_file="$1" relpath="$2" ckey ov def
  # Test-only injection seam (MINION_TEST_INJECT_BUDGET="<relpath>=<value>"):
  # lets the self-test force an arbitrary (possibly non-numeric) budget value
  # through to _sweep_one's arithmetic guard without needing a real code path
  # that produces a corrupted budget. Not used in production sweeps.
  if [ -n "${MINION_TEST_INJECT_BUDGET:-}" ]; then
    case "$MINION_TEST_INJECT_BUDGET" in
      "$relpath="*) echo "${MINION_TEST_INJECT_BUDGET#*=}"; return 0;;
    esac
  fi
  ckey="$(class_key_for "$relpath")"

  ov="$(parse_override "$override_file" "$relpath")"
  [ -n "$ov" ] && { echo "$ov"; return 0; }

  if [ -n "$ckey" ]; then
    ov="$(parse_override "$override_file" "$ckey")"
    [ -n "$ov" ] && { echo "$ov"; return 0; }
  fi

  def="$(default_budget "$relpath")"
  [ -n "$def" ] && { echo "$def"; return 0; }

  if [ -n "$ckey" ]; then
    def="$(default_budget "$ckey")"
    [ -n "$def" ] && { echo "$def"; return 0; }
  fi

  echo ""
}

# ---------------------------------------------------------------------------
# sweep <root> [--report]
#   non-report mode: prints ok/FAIL per checked file, increments pass/fail
#     counters (globals), returns nothing meaningful (counters drive exit).
#   --report mode: collects rows and prints a percent-of-budget table sorted
#     desc; always exits 0 for this half (no pass/fail counting).
# ---------------------------------------------------------------------------
sweep() {
  local root="$1" mode="${2:-}" override_file relpath fullpath words budget pct f g
  override_file="${MINION_INSTRUCTION_BUDGETS:-$root/docs/instruction-size-budgets.md}"

  report_rows=()

  for relpath in $NAMED_FILES; do
    fullpath="$root/$relpath"
    [ -f "$fullpath" ] || continue
    budget="$(effective_budget "$override_file" "$relpath")"
    [ -n "$budget" ] || continue
    words="$(wc -w < "$fullpath" | tr -d '[:space:]')"
    _sweep_one "$mode" "$relpath" "$words" "$budget"
  done

  for g in $CLASS_GLOBS; do
    for fullpath in "$root"/$g; do
      [ -e "$fullpath" ] || continue
      relpath="${fullpath#"$root"/}"
      # a path already covered by an exact NAMED_FILES entry (e.g.
      # minions/smes/README.md also matching minions/smes/*.md) is swept
      # once, under its exact/named identity — skip the class-glob pass.
      case " $NAMED_FILES " in *" $relpath "*) continue;; esac
      budget="$(effective_budget "$override_file" "$relpath")"
      [ -n "$budget" ] || continue
      words="$(wc -w < "$fullpath" | tr -d '[:space:]')"
      _sweep_one "$mode" "$relpath" "$words" "$budget"
    done
  done

  if [ "$mode" = "--report" ]; then
    if [ "${#report_rows[@]}" -gt 0 ]; then
      printf '%s\n' "${report_rows[@]}" | sort -t'|' -k1,1nr -k2,2 | \
        awk -F'|' '{printf "%3d%%  %-38s (%d / %d words)\n", $1, $2, $3, $4}'
    fi
  fi
}

# _sweep_one <mode> <relpath> <words> <budget> -> either checks pass/fail
# (default mode) or appends a report row (report mode). Globals: pass, fail,
# report_rows.
_sweep_one() {
  local mode="$1" relpath="$2" words="$3" budget="$4" pct
  # Defensive numeric guard: bash 3.2's $(( )) arithmetic silently no-ops
  # (and this script's `set -uo pipefail` does not catch it) on non-numeric
  # operands on this machine, which would otherwise let a corrupted words or
  # budget value slip through the gate without any signal. Fail loudly
  # instead of ever reaching arithmetic with non-numeric input.
  case "$words" in
    ''|*[!0-9]*) echo "FAIL - $relpath: invalid word count '$words' (not a positive integer)"; fail=$((fail+1)); return 0;;
  esac
  case "$budget" in
    ''|*[!0-9]*) echo "FAIL - $relpath: invalid budget '$budget' (not a positive integer)"; fail=$((fail+1)); return 0;;
  esac
  [ "$budget" -gt 0 ] 2>/dev/null || { echo "FAIL - $relpath: invalid budget '$budget' (not a positive integer)"; fail=$((fail+1)); return 0; }
  pct=$(( words * 100 / budget ))
  if [ "$mode" = "--report" ]; then
    report_rows+=("$pct|$relpath|$words|$budget")
    return 0
  fi
  if [ "$words" -gt "$budget" ]; then
    echo "FAIL - $relpath: $words words exceeds budget of $budget"
    fail=$((fail+1))
  else
    echo "ok   - $relpath: $words / $budget words (${pct}%)"
    pass=$((pass+1))
  fi
}

# ---------------------------------------------------------------------------
# arg parsing
# ---------------------------------------------------------------------------
ROOT=""
REPORT=0
SELF_TEST=1
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "usage: --root needs a value" >&2; exit 2; }; ROOT="$2"; SELF_TEST=0; shift 2;;
    --report) REPORT=1; SELF_TEST=0; shift;;
    *) echo "usage: instruction-size.test.sh [--root <dir>] [--report]" >&2; exit 2;;
  esac
done
ROOT="${MINION_INSTRUCTION_ROOT:-${ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}}"
ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || { echo "FAIL - --root/MINION_INSTRUCTION_ROOT is not a directory" >&2; exit 2; }

pass=0; fail=0

if [ "$REPORT" -eq 1 ]; then
  echo "instruction-size --report ROOT: $ROOT"
  sweep "$ROOT" "--report"
  exit 0
fi

if [ "$SELF_TEST" -eq 1 ]; then
  # --- self-test the guard (mktemp fixtures; children run with --root) -----
  SUT="$(cd "$(dirname "$0")" && pwd)/instruction-size.test.sh"
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  check() { local desc="$1"; shift; if "$@"; then echo "ok   - $desc"; pass=$((pass+1)); else echo "FAIL - $desc"; fail=$((fail+1)); fi; }

  mk_words() { # mk_words <n> -> prints n space-separated "w" tokens
    local n="$1" i out=""
    for i in $(seq 1 "$n"); do out="$out w"; done
    printf '%s' "$out"
  }

  # 1. under-budget pass
  F1="$TMP/f1"; mkdir -p "$F1"; printf '%s\n' "$(mk_words 5)" > "$F1/CLAUDE.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F1" bash "$SUT" --root "$F1" 2>&1)"; RC=$?
  check "1 under-budget pass -> exit 0" test "$RC" -eq 0
  check "1 under-budget pass -> ok line" bash -c "printf '%s' \"$OUT\" | grep -q 'ok   - CLAUDE.md'"

  # 2. over-budget child exits 1 + offender named
  F2="$TMP/f2"; mkdir -p "$F2"; printf '%s\n' "$(mk_words 601)" > "$F2/CLAUDE.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F2" bash "$SUT" --root "$F2" 2>&1)"; RC=$?
  check "2 over-budget -> exit 1" test "$RC" -eq 1
  check "2 over-budget -> offender named" bash -c "printf '%s' \"$OUT\" | grep -q 'FAIL - CLAUDE.md'"

  # 3. missing surface skipped (empty root, no files at all)
  F3="$TMP/f3"; mkdir -p "$F3"
  OUT="$(MINION_INSTRUCTION_ROOT="$F3" bash "$SUT" --root "$F3" 2>&1)"; RC=$?
  check "3 missing surface skipped -> exit 0" test "$RC" -eq 0

  # 4. --report with over-budget fixture exits 0 + renders table
  OUT="$(MINION_INSTRUCTION_ROOT="$F2" bash "$SUT" --root "$F2" --report 2>&1)"; RC=$?
  check "4 --report over-budget -> exit 0" test "$RC" -eq 0
  check "4 --report over-budget -> table row rendered" bash -c "printf '%s' \"$OUT\" | grep -q 'CLAUDE.md'"

  # 5. malformed override lines for the ACTUALLY-CHECKED key (CLAUDE.md)
  # fail open: they must not raise the budget, so the default (600) stays
  # in force. 700 words over the 600 default must FAIL; a subsequent valid
  # override (800) must then PASS.
  F5="$TMP/f5"; mkdir -p "$F5/docs"; printf '%s\n' "$(mk_words 700)" > "$F5/CLAUDE.md"
  cat > "$F5/docs/instruction-size-budgets.md" <<'EOF'
CLAUDE.md = banana
CLAUDE.md = -5
EOF
  OUT="$(MINION_INSTRUCTION_ROOT="$F5" bash "$SUT" --root "$F5" 2>&1)"; RC=$?
  check "5a malformed overrides fail-open to default(600), 700 > 600 -> exit 1" test "$RC" -eq 1
  check "5a malformed overrides -> FAIL line for CLAUDE.md" bash -c "printf '%s' \"$OUT\" | grep -q 'FAIL - CLAUDE.md'"

  printf 'CLAUDE.md = 800\n' > "$F5/docs/instruction-size-budgets.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F5" bash "$SUT" --root "$F5" 2>&1)"; RC=$?
  check "5b valid override 800 -> exit 0" test "$RC" -eq 0
  check "5b valid override -> ok line for CLAUDE.md" bash -c "printf '%s' \"$OUT\" | grep -q 'ok   - CLAUDE.md'"

  # 6. override raises budget -> over file passes
  F6="$TMP/f6"; mkdir -p "$F6/docs"; printf '%s\n' "$(mk_words 601)" > "$F6/CLAUDE.md"
  printf 'CLAUDE.md = 700\n' > "$F6/docs/instruction-size-budgets.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F6" bash "$SUT" --root "$F6" 2>&1)"; RC=$?
  check "6 override raises budget -> exit 0" test "$RC" -eq 0

  # 7. override lowers -> passing file fails (legit tightening)
  F7="$TMP/f7"; mkdir -p "$F7/docs"; printf '%s\n' "$(mk_words 5)" > "$F7/CLAUDE.md"
  printf 'CLAUDE.md = 3\n' > "$F7/docs/instruction-size-budgets.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F7" bash "$SUT" --root "$F7" 2>&1)"; RC=$?
  check "7 override lowers -> exit 1" test "$RC" -eq 1

  # 8. class override hits all members, exact override beats class
  F8="$TMP/f8"; mkdir -p "$F8/minions/roles" "$F8/docs"
  printf '%s\n' "$(mk_words 2500)" > "$F8/minions/roles/PM.md"
  printf '%s\n' "$(mk_words 2500)" > "$F8/minions/roles/CM.md"
  cat > "$F8/docs/instruction-size-budgets.md" <<'EOF'
minions/roles/*.md = 3000
minions/roles/CM.md = 2000
EOF
  OUT="$(MINION_INSTRUCTION_ROOT="$F8" bash "$SUT" --root "$F8" 2>&1)"; RC=$?
  check "8 class override raises PM -> passes" bash -c "printf '%s' \"$OUT\" | grep -q 'ok   - minions/roles/PM.md'"
  check "8 exact override beats class for CM -> fails" bash -c "printf '%s' \"$OUT\" | grep -q 'FAIL - minions/roles/CM.md'"
  check "8 overall exit 1 (CM breach)" test "$RC" -eq 1

  # 9. comments-only override = defaults
  F9="$TMP/f9"; mkdir -p "$F9/docs"; printf '%s\n' "$(mk_words 5)" > "$F9/CLAUDE.md"
  printf '# just a comment, no assignments\n' > "$F9/docs/instruction-size-budgets.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F9" bash "$SUT" --root "$F9" 2>&1)"; RC=$?
  check "9 comments-only override = defaults -> exit 0" test "$RC" -eq 0

  # 10. absent override file = defaults
  F10="$TMP/f10"; mkdir -p "$F10"; printf '%s\n' "$(mk_words 5)" > "$F10/CLAUDE.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F10" bash "$SUT" --root "$F10" 2>&1)"; RC=$?
  check "10 absent override file = defaults -> exit 0" test "$RC" -eq 0

  # 11. empty surface file passes
  F11="$TMP/f11"; mkdir -p "$F11"; : > "$F11/CLAUDE.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F11" bash "$SUT" --root "$F11" 2>&1)"; RC=$?
  check "11 empty surface file passes -> exit 0" test "$RC" -eq 0

  # 12. unmatched glob skips without crash (no minions/roles dir at all)
  F12="$TMP/f12"; mkdir -p "$F12"
  OUT="$(MINION_INSTRUCTION_ROOT="$F12" bash "$SUT" --root "$F12" 2>&1)"; RC=$?
  check "12 unmatched glob skips without crash -> exit 0" test "$RC" -eq 0

  # 13. named-vs-class de-dupe: minions/smes/README.md matches both its exact
  # NAMED_FILES entry and the minions/smes/*.md class glob; it must be swept
  # exactly once (no double-count, no double-fail).
  F13="$TMP/f13"; mkdir -p "$F13/minions/smes"
  printf '%s\n' "$(mk_words 5)" > "$F13/minions/smes/README.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F13" bash "$SUT" --root "$F13" 2>&1)"; RC=$?
  README_HITS="$(printf '%s' "$OUT" | grep -c 'minions/smes/README.md')"
  check "13 named-vs-class de-dupe -> swept exactly once" test "$README_HITS" -eq 1
  check "13 named-vs-class de-dupe -> exit 0" test "$RC" -eq 0

  # 14. YAML-frontmatter-only file (no body words beyond the frontmatter
  # keys) parses via wc -w without crashing and passes under budget.
  F14="$TMP/f14"; mkdir -p "$F14"
  printf -- '---\ntitle: x\ntags: [a,b]\n---\n' > "$F14/CLAUDE.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F14" bash "$SUT" --root "$F14" 2>&1)"; RC=$?
  check "14 frontmatter-only file passes -> exit 0" test "$RC" -eq 0

  # 15. tabs / unicode / CRLF content does not crash wc -w or the guard.
  F15="$TMP/f15"; mkdir -p "$F15"
  printf 'w\tw\r\nunicode: cafe word\r\n' > "$F15/CLAUDE.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F15" bash "$SUT" --root "$F15" 2>&1)"; RC=$?
  check "15 tabs/unicode/CRLF file passes -> exit 0" test "$RC" -eq 0

  # 16. adversarial override content: a line that looks like an override but
  # carries trailing shell-injection-shaped text must NOT parse as an
  # override (fail-open to default) and must never be executed/evaluated;
  # a zero-value override is rejected (spec: positive integers only);
  # duplicate override lines for the same key -> first line wins;
  # an override for a non-budgeted path is inert (no crash, no effect).
  F16="$TMP/f16"; mkdir -p "$F16/docs"
  printf '%s\n' "$(mk_words 601)" > "$F16/CLAUDE.md"
  MARKER="$TMP/f16-injection-marker"
  cat > "$F16/docs/instruction-size-budgets.md" <<EOF
MEMORY.md = 9000 ; touch $MARKER
MEMORY.md = 0
CLAUDE.md = 700
CLAUDE.md = 10
NOT/BUDGETED.md = 50
EOF
  OUT="$(MINION_INSTRUCTION_ROOT="$F16" bash "$SUT" --root "$F16" 2>&1)"; RC=$?
  check "16 injection-shaped override does not execute" test ! -e "$MARKER"
  check "16 duplicate override lines -> first wins (700, not 10)" test "$RC" -eq 0
  check "16 no crash from zero-value/non-budgeted override lines" bash -c "printf '%s' \"$OUT\" | grep -q 'ok   - CLAUDE.md'"

  # 17. defensive numeric guard: a non-numeric budget forced in via the
  # test-only injection seam must be a loud FAIL (never a silent skip, never
  # an arithmetic crash/abort).
  F17="$TMP/f17"; mkdir -p "$F17"; printf '%s\n' "$(mk_words 5)" > "$F17/CLAUDE.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F17" MINION_TEST_INJECT_BUDGET="CLAUDE.md=abc" bash "$SUT" --root "$F17" 2>&1)"; RC=$?
  check "17 non-numeric injected budget -> loud FAIL" bash -c "printf '%s' \"$OUT\" | grep -q \"FAIL - CLAUDE.md: invalid budget 'abc'\""
  check "17 non-numeric injected budget -> exit 1 (not silently skipped)" test "$RC" -eq 1

  # 18. default-exact-beats-default-class, pinned NUMERICALLY: a word count
  # (1300) strictly between the class default (minions/smes/*.md = 1100) and
  # the exact default (minions/smes/README.md = 2000). Passing here is only
  # possible if the exact default (2000) wins over the class default (1100).
  F18="$TMP/f18"; mkdir -p "$F18/minions/smes"
  printf '%s\n' "$(mk_words 1300)" > "$F18/minions/smes/README.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F18" bash "$SUT" --root "$F18" 2>&1)"; RC=$?
  check "18 default-exact(2000) beats default-class(1100) numerically -> exit 0" test "$RC" -eq 0
  check "18 default-exact(2000) beats default-class(1100) -> ok line" bash -c "printf '%s' \"$OUT\" | grep -q 'ok   - minions/smes/README.md'"

  # 19. same precedence pin for the new minions/roles/PM.md exact default
  # (3000) vs. the minions/roles/*.md class default (2400): 2600 words is
  # strictly between them, so passing requires the exact PM.md arm to be
  # matched before the class glob arm in default_budget's case statement.
  F19="$TMP/f19"; mkdir -p "$F19/minions/roles"
  printf '%s\n' "$(mk_words 2600)" > "$F19/minions/roles/PM.md"
  OUT="$(MINION_INSTRUCTION_ROOT="$F19" bash "$SUT" --root "$F19" 2>&1)"; RC=$?
  check "19 default-exact(3000, PM.md) beats default-class(2400) numerically -> exit 0" test "$RC" -eq 0
  check "19 default-exact(3000, PM.md) beats default-class(2400) -> ok line" bash -c "printf '%s' \"$OUT\" | grep -q 'ok   - minions/roles/PM.md'"

  trap - EXIT
  rm -rf "$TMP"

  echo "----- self-test: $pass passed, $fail failed -----"
fi

# --- the real sweep: no-arg mode sweeps the repo after self-test; --root
# mode sweeps only the given tree (no self-test, already skipped above) -----
echo "instruction-size sweep ROOT: $ROOT"
sweep "$ROOT"

echo "----- $pass passed, $fail failed -----"
test "$fail" -eq 0
