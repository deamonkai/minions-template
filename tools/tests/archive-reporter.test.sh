#!/usr/bin/env bash
# Dependency-free test harness for tools/archive-reporter.sh (the read-only
# stale-coordination-unit reporter; see
# docs/superpowers/specs/2026-07-21-archive-reporter-design.md).
# Fixtures are built as throwaway git repos under mktemp — the reporter is
# never run against the live canonical tree here.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUT="$ROOT/tools/archive-reporter.sh"
[ -f "$SUT" ] || { echo "FAIL - archive-reporter.sh not found at $SUT"; exit 1; }

pass=0; fail=0
check() { local desc="$1"; shift; if "$@"; then echo "ok   - $desc"; pass=$((pass+1)); else echo "FAIL - $desc"; fail=$((fail+1)); fi; }
check_out() { # desc, expected substring, actual
  local desc="$1" needle="$2" haystack="$3"
  case "$haystack" in
    *"$needle"*) echo "ok   - $desc"; pass=$((pass+1)) ;;
    *) echo "FAIL - $desc (missing: $needle)"; fail=$((fail+1)) ;;
  esac
}
check_not_out() {
  local desc="$1" needle="$2" haystack="$3"
  case "$haystack" in
    *"$needle"*) echo "FAIL - $desc (unexpectedly present: $needle)"; fail=$((fail+1)) ;;
    *) echo "ok   - $desc"; pass=$((pass+1)) ;;
  esac
}

# ---------------------------------------------------------------------------
# Load-bearing invariant #1 (PRIMARY, behavioral): running the tool must not
# change one byte of the working tree, regardless of how the script is
# written. A text-grep can be fooled by how a verb is spelled or quoted;
# a before/after tree snapshot cannot. This is the real gate.
# ---------------------------------------------------------------------------
snapshot_tree() { # $1=repo root -> prints "porcelain-status\ncksum-of-every-tracked+untracked-file"
  local r="$1"
  (
    cd "$r" || exit 1
    git status --porcelain
    echo '---'
    find . -type f -not -path './.git/*' | LC_ALL=C sort | xargs cksum 2>/dev/null
  )
}

R="$(mktemp -d)"
mkdir -p "$R/minions/mail" "$R/minions/plans" "$R/minions/chat"
(cd "$R" && git init -q && git config user.email t@example.com && git config user.name test)
mkdir -p "$R/minions/mail/2026-01-02-behavioral-candidate"
printf 'Status: CLOSED — COMPLETE\nbody\n' > "$R/minions/mail/2026-01-02-behavioral-candidate/verdict.md"
_ts=$(( $(date +%s) - 41*86400 ))
( cd "$R" && git add -- minions/mail/2026-01-02-behavioral-candidate/verdict.md >/dev/null 2>&1 \
    && GIT_AUTHOR_DATE="@$_ts" GIT_COMMITTER_DATE="@$_ts" git commit -q -m "add candidate" )
BEFORE="$(snapshot_tree "$R")"
( cd "$R" && "$SUT" report >/dev/null 2>&1 )
AFTER="$(snapshot_tree "$R")"
check "PRIMARY: no-mutation invariant holds on the real script (clean pass)" test "$BEFORE" = "$AFTER"
rm -rf "$R"

# Negative control for the behavioral check itself: prove it actually
# detects mutation by running it against a scratch copy of the SUT with a
# real repo-path write injected, and asserting the snapshot changes.
MUT_SUT="$(mktemp -t archive-reporter-mutated.XXXXXX.sh)"
cp "$SUT" "$MUT_SUT"
# inject BEFORE the script's own `exit 0` (appending after it would be dead code)
sed -i.bak "s#^set -uo pipefail#set -uo pipefail\necho x > minions/mail/pwned.md#" "$MUT_SUT" 2>/dev/null || \
  sed -i "" "s#^set -uo pipefail#set -uo pipefail\necho x > minions/mail/pwned.md#" "$MUT_SUT"
rm -f "$MUT_SUT.bak"
chmod +x "$MUT_SUT"

R="$(mktemp -d)"
mkdir -p "$R/minions/mail" "$R/minions/plans" "$R/minions/chat"
(cd "$R" && git init -q && git config user.email t@example.com && git config user.name test)
mkdir -p "$R/minions/mail/2026-01-02-behavioral-candidate"
printf 'Status: CLOSED — COMPLETE\nbody\n' > "$R/minions/mail/2026-01-02-behavioral-candidate/verdict.md"
( cd "$R" && git add -- minions/mail/2026-01-02-behavioral-candidate/verdict.md >/dev/null 2>&1 \
    && GIT_AUTHOR_DATE="@$_ts" GIT_COMMITTER_DATE="@$_ts" git commit -q -m "add candidate" )
BEFORE="$(snapshot_tree "$R")"
( cd "$R" && "$MUT_SUT" report >/dev/null 2>&1 )
AFTER="$(snapshot_tree "$R")"
check "control: the behavioral check DOES catch a mutated script (injected write detected)" test "$BEFORE" != "$AFTER"
rm -rf "$R" "$MUT_SUT"

# ---------------------------------------------------------------------------
# Load-bearing invariant #2 (SECONDARY, textual): a repaired grep-based
# detector, wired into an actual check (not dead code), that flags a bare
# `> path` / `>> path` write to a repo path or a real git rm/add/commit/mv
# invocation, while NOT false-positiving on: the tool's own mktemp
# temp-file writes, >&2 / >/dev/null redirects, and the printf'd DISPLAY
# string for the human ('git rm -r "%s"' is output text, not a command).
# ---------------------------------------------------------------------------
mutating_hit() { # $1 = path to script under test
  local sut="$1"
  grep -n . "$sut" \
    | grep -vE '^[0-9]+:[[:space:]]*#' \
    | grep -vE "printf[[:space:]]+'[^']*(git rm|git add|git commit|git mv)" \
    | grep -E \
       -e '\bgit[[:space:]]+(rm|add|commit|mv)\b' \
       -e '(^|[[:space:];&|])(mkdir|rm|mv|touch)([[:space:]]|$)' \
       -e '>>?[[:space:]]*[^&[:space:]][^[:space:]]*' \
    | grep -vE '>[[:space:]]*(&2|/dev/null)' \
    | grep -vE '>>?[[:space:]]*"?\$(UNITS_FILE|CANDIDATE_LINES|MUT_SUT)"?\b'
}

detector_clean() { [ -z "$(mutating_hit "$1")" ]; }
detector_dirty() { [ -n "$(mutating_hit "$1")" ]; }

check "SECONDARY: repaired text-grep detector is clean on the real script" detector_clean "$SUT"

# rebuild a throwaway mutated copy just for this detector check so the two
# invariants (behavioral + textual) stay independently verified.
MUT_SUT2="$(mktemp -t archive-reporter-mutated2.XXXXXX.sh)"
cp "$SUT" "$MUT_SUT2"
sed -i.bak "s#^set -uo pipefail#set -uo pipefail\necho x > minions/mail/pwned.md#" "$MUT_SUT2" 2>/dev/null || \
  sed -i "" "s#^set -uo pipefail#set -uo pipefail\necho x > minions/mail/pwned.md#" "$MUT_SUT2"
rm -f "$MUT_SUT2.bak"
check "SECONDARY: repaired text-grep detector catches an injected repo-path write" detector_dirty "$MUT_SUT2"
rm -f "$MUT_SUT2"

# ---------------------------------------------------------------------------
# Fixture builder
# ---------------------------------------------------------------------------
mkrepo() {
  local r="$1"
  mkdir -p "$r/minions/mail" "$r/minions/plans" "$r/minions/chat" "$r/docs"
  (cd "$r" && git init -q && git config user.email t@example.com && git config user.name test)
}

# commit a path with a specific age in days (relative to now)
commit_aged() { # $1=repo $2=relpath $3=age-days
  local r="$1" p="$2" age="$3"
  local ts
  ts=$(( $(date +%s) - age*86400 ))
  ( cd "$r" && git add -- "$p" >/dev/null 2>&1 && \
    GIT_AUTHOR_DATE="@$ts" GIT_COMMITTER_DATE="@$ts" git commit -q -m "add $p" )
}

RUN() { # $1=repo, rest = args
  local r="$1"; shift
  ( cd "$r" && "$SUT" "$@" )
}

# ---------------------------------------------------------------------------
# Basic argument discipline
# ---------------------------------------------------------------------------
R="$(mktemp -d)"; mkrepo "$R"
OUT="$(RUN "$R" --help 2>&1)"; RC=$?
check "--help exits 0" test "$RC" -eq 0
OUT="$(RUN "$R" -h 2>&1)"; RC=$?
check "-h exits 0" test "$RC" -eq 0
OUT="$(RUN "$R" help 2>&1)"; RC=$?
check "help exits 0" test "$RC" -eq 0
OUT="$(RUN "$R" --bogus 2>&1)"; RC=$?
check "unknown arg exits 2" test "$RC" -eq 2
OUT="$(RUN "$R" --bogus 2>&1 1>/dev/null)"
check_out "unknown arg prints usage on stderr" "usage" "$OUT"
BARE="$(RUN "$R" 2>&1)"; RC=$?
REPORTV="$(RUN "$R" report 2>&1)"; RC2=$?
check "bare invocation succeeds like report" test "$RC" -eq "$RC2"
rm -rf "$R"

# below-7 age without --force-age rejected
R="$(mktemp -d)"; mkrepo "$R"
OUT="$(RUN "$R" report --age-days 3 2>&1)"; RC=$?
check "--age-days below 7 without --force-age rejected (exit 2)" test "$RC" -eq 2
OUT="$(RUN "$R" report --age-days 3 --force-age 2>&1)"; RC=$?
check "--age-days below 7 with --force-age accepted" test "$RC" -eq 0
rm -rf "$R"

# ---------------------------------------------------------------------------
# closed+aged candidate vs open+aged / closed+fresh
# ---------------------------------------------------------------------------
R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-01-02-closed-aged"
printf 'Status: CLOSED — COMPLETE\nSome text.\n' > "$R/minions/mail/2026-01-02-closed-aged/verdict.md"
commit_aged "$R" "minions/mail/2026-01-02-closed-aged/verdict.md" 41

mkdir -p "$R/minions/mail/2026-01-03-open-aged"
printf 'Status: OPEN\nSome text.\n' > "$R/minions/mail/2026-01-03-open-aged/verdict.md"
commit_aged "$R" "minions/mail/2026-01-03-open-aged/verdict.md" 41

mkdir -p "$R/minions/mail/2026-01-04-closed-fresh"
printf 'Status: CLOSED — COMPLETE\nSome text.\n' > "$R/minions/mail/2026-01-04-closed-fresh/verdict.md"
commit_aged "$R" "minions/mail/2026-01-04-closed-fresh/verdict.md" 1

OUT="$(RUN "$R" report 2>&1)"; RC=$?
check "report exits 0 with mixed units" test "$RC" -eq 0
check_out "closed+aged appears as a candidate" "2026-01-02-closed-aged" "$OUT"
check_not_out "open+aged does not appear as a candidate git rm line" "git rm -r \"minions/mail/2026-01-03-open-aged\"" "$OUT"
check_not_out "closed+fresh does not appear as a candidate git rm line" "git rm -r \"minions/mail/2026-01-04-closed-fresh\"" "$OUT"
rm -rf "$R"

# ---------------------------------------------------------------------------
# CLOSED — SUPERSEDED also matches; OPEN does not
# ---------------------------------------------------------------------------
R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-02-01-superseded"
printf 'Status: CLOSED — SUPERSEDED (superseded-by: x)\n' > "$R/minions/mail/2026-02-01-superseded/verdict.md"
commit_aged "$R" "minions/mail/2026-02-01-superseded/verdict.md" 41
OUT="$(RUN "$R" report 2>&1)"
check_out "CLOSED — SUPERSEDED matches as closed" "2026-02-01-superseded" "$OUT"
rm -rf "$R"

# ---------------------------------------------------------------------------
# Closure-marker placement edge cases (each its own fixture): fence,
# indented, quoted, past line 10, non-designated file.
# ---------------------------------------------------------------------------
mk_unit() { # $1=repo $2=dirname $3=file $4=content
  mkdir -p "$1/minions/mail/$2"
  printf '%b' "$4" > "$1/minions/mail/$2/$3"
}

R="$(mktemp -d)"; mkrepo "$R"
mk_unit "$R" "2026-03-01-fenced" "verdict.md" '```\nStatus: CLOSED — COMPLETE\n```\nbody\n'
commit_aged "$R" "minions/mail/2026-03-01-fenced/verdict.md" 41
OUT="$(RUN "$R" report 2>&1)"
check_not_out "marker inside a fence is not closed" "git rm -r \"minions/mail/2026-03-01-fenced\"" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mk_unit "$R" "2026-03-02-indented" "verdict.md" '  Status: CLOSED — COMPLETE\nbody\n'
commit_aged "$R" "minions/mail/2026-03-02-indented/verdict.md" 41
OUT="$(RUN "$R" report 2>&1)"
check_not_out "indented marker is not closed" "git rm -r \"minions/mail/2026-03-02-indented\"" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mk_unit "$R" "2026-03-03-quoted" "verdict.md" '> Status: CLOSED — COMPLETE\nbody\n'
commit_aged "$R" "minions/mail/2026-03-03-quoted/verdict.md" 41
OUT="$(RUN "$R" report 2>&1)"
check_not_out "quoted marker is not closed" "git rm -r \"minions/mail/2026-03-03-quoted\"" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mk_unit "$R" "2026-03-04-past-line-10" "verdict.md" 'l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\nl10\nStatus: CLOSED — COMPLETE\n'
commit_aged "$R" "minions/mail/2026-03-04-past-line-10/verdict.md" 41
OUT="$(RUN "$R" report 2>&1)"
check_not_out "marker past line 10 is not closed" "git rm -r \"minions/mail/2026-03-04-past-line-10\"" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-03-05-non-designated"
printf 'no marker here\n' > "$R/minions/mail/2026-03-05-non-designated/verdict.md"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-03-05-non-designated/notes.md"
commit_aged "$R" "minions/mail/2026-03-05-non-designated" 41
OUT="$(RUN "$R" report 2>&1)"
check_not_out "marker in a non-designated file is not closed" "git rm -r \"minions/mail/2026-03-05-non-designated\"" "$OUT"
rm -rf "$R"

# ---------------------------------------------------------------------------
# Designated-file order: request.md closure when no verdict/response;
# a directory with none of the three -> not closed, no error.
# ---------------------------------------------------------------------------
R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-04-01-request-only"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-04-01-request-only/request.md"
commit_aged "$R" "minions/mail/2026-04-01-request-only" 41
OUT="$(RUN "$R" report 2>&1)"; RC=$?
check "designated-file order: request.md closure -> exit 0" test "$RC" -eq 0
check_out "designated-file order: request.md-only closure is closed" "2026-04-01-request-only" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-04-02-none"
printf 'nothing relevant\n' > "$R/minions/mail/2026-04-02-none/notes.md"
commit_aged "$R" "minions/mail/2026-04-02-none" 41
OUT="$(RUN "$R" report 2>&1)"; RC=$?
check "no designated file at all -> exit 0 (no error)" test "$RC" -eq 0
check_not_out "no designated file at all -> not closed" "git rm -r \"minions/mail/2026-04-02-none\"" "$OUT"
rm -rf "$R"

# ---------------------------------------------------------------------------
# Sole-holder screen: literal variants + the Unicode dash byte variants.
# ---------------------------------------------------------------------------
NB="$(printf '\xe2\x80\x91')"   # U+2011 non-breaking hyphen
EN="$(printf '\xe2\x80\x93')"   # U+2013 en dash
EM="$(printf '\xe2\x80\x94')"   # U+2014 em dash

sole_case() { # $1=label $2=marker-text
  local label="$1" marker="$2"
  local R name
  R="$(mktemp -d)"; mkrepo "$R"
  name="2026-05-$(printf '%02d' "$sole_n")-sole"
  sole_n=$((sole_n+1))
  mkdir -p "$R/minions/mail/$name"
  printf 'Status: CLOSED — COMPLETE\n%s\n' "$marker" > "$R/minions/mail/$name/verdict.md"
  commit_aged "$R" "minions/mail/$name/verdict.md" 41
  OUT="$(RUN "$R" report 2>&1)"
  check_not_out "sole-holder ($label) is withheld, not a candidate" "$name\"" "$OUT"
  check_out "sole-holder ($label) counted in withheld summary" "withheld: sole-holder" "$OUT"
  rm -rf "$R"
}
sole_n=1
sole_case "SOLE-HOLDER:" "SOLE-HOLDER: fact"
sole_case "SOLE HOLDER:" "SOLE HOLDER: fact"
sole_case "SOLE_HOLDER:" "SOLE_HOLDER: fact"
sole_case "SOLE-HOLDER :" "SOLE-HOLDER : fact"
sole_case "em-dash SOLE—HOLDER:" "SOLE${EM}HOLDER: fact"
sole_case "en-dash SOLE–HOLDER:" "SOLE${EN}HOLDER: fact"
sole_case "nb-hyphen SOLE‑HOLDER:" "SOLE${NB}HOLDER: fact"

# ---------------------------------------------------------------------------
# Reference integrity: withheld on a minions/chat/ reference; not withheld
# on a CHANGELOG.md-only reference.
# ---------------------------------------------------------------------------
R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-06-01-referenced"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-06-01-referenced/verdict.md"
printf 'see minions/mail/2026-06-01-referenced for background\n' > "$R/minions/chat/note.md"
commit_aged "$R" "minions/mail/2026-06-01-referenced/verdict.md" 41
( cd "$R" && git add minions/chat/note.md && GIT_AUTHOR_DATE="@$(date +%s)" GIT_COMMITTER_DATE="@$(date +%s)" git commit -q -m "chat ref" )
OUT="$(RUN "$R" report 2>&1)"
check_not_out "referenced by minions/chat/ is withheld" "2026-06-01-referenced\"" "$OUT"
check_out "referenced-by-live-surface counted" "withheld: referenced-by-live-surface" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-06-02-changelog-only"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-06-02-changelog-only/verdict.md"
printf '## 1.0.0\n- did minions/mail/2026-06-02-changelog-only work\n' > "$R/CHANGELOG.md"
commit_aged "$R" "minions/mail/2026-06-02-changelog-only/verdict.md" 41
( cd "$R" && git add CHANGELOG.md && GIT_AUTHOR_DATE="@$(date +%s)" GIT_COMMITTER_DATE="@$(date +%s)" git commit -q -m "changelog" )
OUT="$(RUN "$R" report 2>&1)"
check_out "CHANGELOG.md-only reference is NOT withheld (exempt ledger)" "2026-06-02-changelog-only" "$OUT"
rm -rf "$R"

# MINOR fix regression: EXEMPT_LEDGER_RE must be anchored so a lookalike
# path like CHANGELOG.md.bak does NOT get treated as an exempt ledger --
# a reference from it must still withhold the unit (fail-unsafe direction).
R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-06-03-changelog-bak-only"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-06-03-changelog-bak-only/verdict.md"
printf '## 1.0.0\n- did minions/mail/2026-06-03-changelog-bak-only work\n' > "$R/CHANGELOG.md.bak"
commit_aged "$R" "minions/mail/2026-06-03-changelog-bak-only/verdict.md" 41
( cd "$R" && git add CHANGELOG.md.bak && GIT_AUTHOR_DATE="@$(date +%s)" GIT_COMMITTER_DATE="@$(date +%s)" git commit -q -m "changelog bak" )
OUT="$(RUN "$R" report 2>&1)"
check_not_out "CHANGELOG.md.bak reference is NOT exempt -> unit is withheld" "2026-06-03-changelog-bak-only\"" "$OUT"
check_out "CHANGELOG.md.bak reference counted as referenced-by-live-surface" "withheld: referenced-by-live-surface" "$OUT"
rm -rf "$R"

# ---------------------------------------------------------------------------
# not-removable: uncommitted, untracked, subdir, symlink, non-text, .issue
# ---------------------------------------------------------------------------
R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-07-01-uncommitted"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-07-01-uncommitted/verdict.md"
commit_aged "$R" "minions/mail/2026-07-01-uncommitted/verdict.md" 41
printf 'edited\n' >> "$R/minions/mail/2026-07-01-uncommitted/verdict.md"
OUT="$(RUN "$R" report 2>&1)"
check_not_out "uncommitted mod withheld as not-removable" "2026-07-01-uncommitted\"" "$OUT"
check_out "not-removable counted (uncommitted)" "withheld: not-removable" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-07-02-untracked"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-07-02-untracked/verdict.md"
commit_aged "$R" "minions/mail/2026-07-02-untracked/verdict.md" 41
printf 'stray\n' > "$R/minions/mail/2026-07-02-untracked/scratch.txt"
OUT="$(RUN "$R" report 2>&1)"
check_not_out "untracked file withheld as not-removable" "2026-07-02-untracked\"" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-07-03-subdir/nested"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-07-03-subdir/verdict.md"
printf 'x\n' > "$R/minions/mail/2026-07-03-subdir/nested/f.md"
commit_aged "$R" "minions/mail/2026-07-03-subdir" 41
OUT="$(RUN "$R" report 2>&1)"
check_not_out "subdirectory present withheld as not-removable" "2026-07-03-subdir\"" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-07-04-symlink"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-07-04-symlink/verdict.md"
( cd "$R/minions/mail/2026-07-04-symlink" && ln -s verdict.md alias.md )
commit_aged "$R" "minions/mail/2026-07-04-symlink" 41
OUT="$(RUN "$R" report 2>&1)"
check_not_out "symlink present withheld as not-removable" "2026-07-04-symlink\"" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-07-05-nontext"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-07-05-nontext/verdict.md"
printf '\x00\x01\x02binary' > "$R/minions/mail/2026-07-05-nontext/blob.bin"
commit_aged "$R" "minions/mail/2026-07-05-nontext" 41
OUT="$(RUN "$R" report 2>&1)"
check_not_out "non-text file withheld as not-removable" "2026-07-05-nontext\"" "$OUT"
rm -rf "$R"

R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-07-06-issuesidecar"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-07-06-issuesidecar/verdict.md"
printf 'issue: 42\n' > "$R/minions/mail/2026-07-06-issuesidecar/.issue"
commit_aged "$R" "minions/mail/2026-07-06-issuesidecar" 41
OUT="$(RUN "$R" report 2>&1)"
check_not_out ".issue sidecar withheld as not-removable" "2026-07-06-issuesidecar\"" "$OUT"
rm -rf "$R"

# ---------------------------------------------------------------------------
# Age: shallow-clone-style empty git-log -> not-aged -> omit (simulated via
# a file that exists on disk but was never committed, so git log for its
# path returns nothing, matching the "empty output" code path the spec
# requires regardless of cause).
# ---------------------------------------------------------------------------
R="$(mktemp -d)"; mkrepo "$R"
# need at least one commit so the repo is non-empty / HEAD exists
mkdir -p "$R/minions/plans"; printf 'seed\n' > "$R/minions/plans/seed.md"
commit_aged "$R" "minions/plans/seed.md" 0
mkdir -p "$R/minions/mail/2026-08-01-nolog"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-08-01-nolog/verdict.md"
OUT="$(RUN "$R" report 2>&1)"; RC=$?
check "empty git-log unit does not crash the reporter" test "$RC" -eq 0
check_not_out "empty git-log (never committed) -> not aged -> omit" "2026-08-01-nolog\"" "$OUT"
rm -rf "$R"

# ---------------------------------------------------------------------------
# Drift: unmarked-but-aged count and oldest-unit line present
# ---------------------------------------------------------------------------
R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-09-01-unmarked-a"
printf 'no status marker\n' > "$R/minions/mail/2026-09-01-unmarked-a/verdict.md"
commit_aged "$R" "minions/mail/2026-09-01-unmarked-a/verdict.md" 50
mkdir -p "$R/minions/mail/2026-09-02-unmarked-b"
printf 'no status marker\n' > "$R/minions/mail/2026-09-02-unmarked-b/verdict.md"
commit_aged "$R" "minions/mail/2026-09-02-unmarked-b/verdict.md" 100
OUT="$(RUN "$R" report 2>&1)"
check_out "unmarked-but-aged count present" "unmarked-but-aged: 2" "$OUT"
check_out "unmarked-but-aged oldest unit surfaced" "2026-09-02-unmarked-b" "$OUT"
rm -rf "$R"

# ---------------------------------------------------------------------------
# Well-formedness of the printed git rm line and ARCHIVED.md row.
# ---------------------------------------------------------------------------
R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-10-01-wellformed"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-10-01-wellformed/verdict.md"
commit_aged "$R" "minions/mail/2026-10-01-wellformed/verdict.md" 41
OUT="$(RUN "$R" report 2>&1)"
check_out "well-formed git rm line" 'git rm -r "minions/mail/2026-10-01-wellformed"' "$OUT"
check_out "well-formed ARCHIVED.md row comment" '| mail | 2026-10-01-wellformed |' "$OUT"
rm -rf "$R"

# ---------------------------------------------------------------------------
# LC_ALL=C pinned on sorts; NUL-safe enumeration (filename with a space)
# ---------------------------------------------------------------------------
check "LC_ALL=C pinned before any sort in the script" bash -c "grep -n 'sort' '$SUT' | grep -qv 'LC_ALL=C' && exit 1 || exit 0"
R="$(mktemp -d)"; mkrepo "$R"
mkdir -p "$R/minions/mail/2026-11-01-with space"
printf 'Status: CLOSED — COMPLETE\n' > "$R/minions/mail/2026-11-01-with space/verdict.md"
commit_aged "$R" "minions/mail/2026-11-01-with space/verdict.md" 41
OUT="$(RUN "$R" report 2>&1)"; RC=$?
check "unit with a space in its name does not crash the reporter" test "$RC" -eq 0
check_out "unit with a space in its name is surfaced intact" "2026-11-01-with space" "$OUT"
rm -rf "$R"

echo "archive-reporter: $pass passed, $fail failed"; [ "$fail" -eq 0 ]
