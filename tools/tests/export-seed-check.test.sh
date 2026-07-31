#!/usr/bin/env bash
set -uo pipefail
# Self-test for tools/export-seed-check.sh — the public-export seed-state guard.
# An untested guard is theater (same rule as governance-consistency.test.sh's
# detectors). Fixtures are built under mktemp roots; the guard is never run against
# the live canonical tree here — canonical is intentionally filled and would (rightly)
# fail, so live-tree behavior is proven separately in the runbook gate, not the suite.
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/export-seed-check.sh"
[ -f "$SCRIPT" ] || { echo "FAIL - export-seed-check.sh not found at $SCRIPT"; exit 1; }

# Pin every bare `bash "$SCRIPT"` call below to the bash actually stuck at 3.2 on
# macOS (Apple ships it at /bin/bash and never updates it, for GPLv3 reasons) rather
# than whatever newer bash (Homebrew, asdf, etc.) a developer's PATH resolves first
# — every "verified on bash 3.2" claim from this suite was false by default before
# this line, since plain `bash` on a dev machine commonly resolves to 5.x. PATH
# PREPEND, not a hardcoded `/bin/bash` literal invocation at each call site: this
# degrades gracefully — a downstream whose stock bash is not at that exact path
# still finds `bash` further down its existing PATH — where a hardcoded literal path
# would hard-fail with "no such file" on any system lacking it. One line covers
# every current and future `bash "$SCRIPT"` call in this file without editing each.
export PATH="/bin:$PATH"

fail=0; pass=0
DELIM='<!-- ================= DOWNSTREAM CONTENT BELOW — template upgrades replace above this line only ================= -->'

# assert exit code of the guard run against a fixture root
# $1=label  $2=expected-exit  $3=fixture-root
run_expect() {
  bash "$SCRIPT" "$3" >/dev/null 2>&1; local rc=$?
  if [ "$rc" -eq "$2" ]; then echo "ok   - $1"; pass=$((pass+1))
  else echo "FAIL - $1 (expected exit $2, got $rc)"; fail=$((fail+1)); fi
}

# Build a fixture root with the two seed files. $1=root  $2=registry-below  $3=matrix-below
mkfix() {
  mkdir -p "$1/minions/smes" "$1/minions"
  { printf '# SMEs\n\n## Matrix (template example — above delimiter)\n\n'
    printf '| Example | Reviewer |\n| --- | --- |\n| _example row_ | SM |\n\n'
    printf '%s\n\n' "$DELIM"
    printf '## Local Registry (this repo)\n\n%b' "$2"
  } > "$1/minions/smes/README.md"
  { printf '# Review Matrix\n\n%s\n\n' "$DELIM"
    printf '## Local Matrix (this repo)\n\n%b' "$3"
  } > "$1/minions/review-matrix.md"
}

HEADER_ONLY='| SME | Charter |\n| --- | --- |\n'
FILLED='| SME | Charter |\n| --- | --- |\n| Governance-Invariant SME | `gi.md` |\n'
MATRIX_HDR='| Change | Reviewer |\n| --- | --- |\n'
MATRIX_FILLED='| Change | Reviewer |\n| --- | --- |\n| governance edit | GI SME |\n'

# 1) both header-only -> clean (exit 0). Note the above-delimiter example DATA row
#    must NOT trip the guard — proves the delimiter boundary is respected.
r="$(mktemp -d)"; mkfix "$r" "$HEADER_ONLY" "$MATRIX_HDR"
run_expect "header-only seed (above-delimiter example row ignored)" 0 "$r"; rm -rf "$r"

# 2) registry filled -> leak (exit 1)
r="$(mktemp -d)"; mkfix "$r" "$FILLED" "$MATRIX_HDR"
run_expect "filled Local Registry row is caught" 1 "$r"; rm -rf "$r"

# 3) matrix filled -> leak (exit 1)
r="$(mktemp -d)"; mkfix "$r" "$HEADER_ONLY" "$MATRIX_FILLED"
run_expect "filled Local Matrix row is caught" 1 "$r"; rm -rf "$r"

# 4) heading-reset: a SECOND header-only table below the delimiter must stay clean
r="$(mktemp -d)"; mkfix "$r" "$HEADER_ONLY\n\n## Notes (this repo)\n\n| K | V |\n| --- | --- |\n" "$MATRIX_HDR"
run_expect "second header-only table after a heading stays clean" 0 "$r"; rm -rf "$r"

# 5) heading-reset must NOT mask a filled second table
r="$(mktemp -d)"; mkfix "$r" "$HEADER_ONLY\n\n## Notes (this repo)\n\n| K | V |\n| --- | --- |\n| leaked | secret |\n" "$MATRIX_HDR"
run_expect "filled second table after a heading is still caught" 1 "$r"; rm -rf "$r"

# 6) missing one seed file -> WARN-skip, still clean if the other is header-only
r="$(mktemp -d)"; mkfix "$r" "$HEADER_ONLY" "$MATRIX_HDR"; rm -f "$r/minions/review-matrix.md"
run_expect "absent seed file is a skip, not a failure" 0 "$r"; rm -rf "$r"

# 7) bad root arg -> exit 2 (usage/error, distinct from a clean/leak result)
run_expect "non-directory root errors out" 2 "/nonexistent-$$-path"

# 8) PROSE below the delimiter is caught (Export/Privacy SME F1 — the header-only
#    claim must hold for non-table content, not just data rows).
r="$(mktemp -d)"; mkfix "$r" "$HEADER_ONLY\n\nTuned for the maintainer's private workflow.\n" "$MATRIX_HDR"
run_expect "prose line below delimiter is caught" 1 "$r"; rm -rf "$r"

# 9) a BULLET below the delimiter is caught (F1, list-shaped private content)
r="$(mktemp -d)"; mkfix "$r" "$HEADER_ONLY\n\n- private promoted-context note\n" "$MATRIX_HDR"
run_expect "bullet line below delimiter is caught" 1 "$r"; rm -rf "$r"

# 10) a data row with NO separator is caught (Shell/Test-Harness SME Blocker /
#     Export/Privacy F2 — the old blocklist logic passed this silently).
r="$(mktemp -d)"; mkfix "$r" '| SME | Charter |\n| Leaked SME | secret.md |\n' "$MATRIX_HDR"
run_expect "separator-less data row is caught (no silent leak)" 1 "$r"; rm -rf "$r"

# 11) two header-only tables under the SAME heading (no intervening ##) stay clean
#     (Shell/Test-Harness SME Major — the global-flag logic false-flagged the second
#     table's header; the per-line lookahead must not).
r="$(mktemp -d)"; mkfix "$r" "$HEADER_ONLY\n\n$HEADER_ONLY" "$MATRIX_HDR"
run_expect "two header-only tables under one heading stay clean" 0 "$r"; rm -rf "$r"

# --- Classification completeness (F3) ----------------------------------------
# completeness-only mode: assert every delimited EXPORTABLE file is SEED or WAIVER.
run_expect_c() { # $1=label  $2=expected-exit  $3=root
  bash "$SCRIPT" --completeness "$3" >/dev/null 2>&1; local rc=$?
  if [ "$rc" -eq "$2" ]; then echo "ok   - $1"; pass=$((pass+1))
  else echo "FAIL - $1 (expected exit $2, got $rc)"; fail=$((fail+1)); fi
}
# write a file carrying the STRUCTURAL marker line + a filled local section
mkdelim() { mkdir -p "$(dirname "$1")"; printf '# X\n\n%s\n\n## Local (this repo)\n\n| A | B |\n| --- | --- |\n| filled | row |\n' "$DELIM" > "$1"; }

# 12) synthetic canonical-shaped tree: a representative SEED_FILES entry and a
#     representative WAIVER entry, both delimited and both classified (drift-guard
#     proxy for "no unclassified delimited exportable file exists" — cannot mirror
#     the hardcoded SEED_FILES/WAIVER arrays wholesale without duplicating them, so
#     this builds one file from each class). Re-rooted off the live repo (was
#     `$(cd "$(dirname "$0")/../.." && pwd)`) per the Export/Privacy SME finding:
#     tools/tests/ is export=yes, so once this file is copied into an export tree
#     and the SUITE RUNS FROM THERE, that expression resolves to the EXPORT tree,
#     not canonical — and gate 1 (the export's own tests must pass in the export
#     tree) collides with Leg S (the source invariant demanding marker presence)
#     on the very same reset Step 2 performed correctly. Re-rooting makes the suite
#     test the SCRIPT, so it passes anywhere; the live-repo invariant itself is
#     still asserted continuously via `--completeness .` run directly against
#     canonical — the same invocation docs/runbooks/public-export.md and CI use,
#     never via this suite's own relative test-file location.
r="$(mktemp -d)"
mkdir -p "$r/minions/smes"
printf '# SMEs\n\n%s\n\n## Local Registry (this repo)\n\n' "$DELIM" > "$r/minions/smes/README.md"
printf '# Memory\n\n%s\n\nDownstream content.\n' "$DELIM" > "$r/MEMORY.md"
run_expect_c "synthetic tree: representative SEED_FILES + WAIVER entries both classified" 0 "$r"
rm -rf "$r"

# 13) a NEW delimited file in neither SEED nor WAIVER fails completeness (no manifest
#     -> every delimited file is in scope, conservative). NOTE: mktemp roots are not
#     git work trees, so this (and case 12 and case 14) exercise find_delimited()'s
#     grep -r fallback branch. The git-grep branch (MODE=completeness AND ROOT is a
#     real git work tree) is exercised only by the live `--completeness .` invocation
#     against canonical (docs/runbooks/public-export.md, CI) — no fixture in this
#     suite roots at a real git work tree, by design (see case 12's re-rooting note).
r="$(mktemp -d)"; mkdelim "$r/minions/newthing.md"
run_expect_c "unclassified new delimited file fails completeness (grep -r fallback)" 1 "$r"; rm -rf "$r"

# 14) exportable scoping: a delimited file the manifest marks export=no is OUT of
#     scope (do-not-export never publishes, so it needn't be enrolled). Needs a
#     non-empty export=yes set for the scoping branch to engage.
r="$(mktemp -d)"; mkdelim "$r/minions/newthing.md"; mkdir -p "$r/docs"
{ printf '| Path | Initial export | Upgrade strategy | Criticality | Owner | Notes |\n'
  printf '| --- | --- | --- | --- | --- | --- |\n'
  printf '| `README.md` | yes | `template-replace` | `feature` | PM | a yes row |\n'
  printf '| `minions/newthing.md` | no | `downstream-owned` | `n/a` | PM | not exported |\n'
} > "$r/docs/export-manifest.md"
run_expect_c "do-not-export delimited file is out of completeness scope" 0 "$r"; rm -rf "$r"

# 15) R1 (Export/Privacy SME): the header-only check also covers WAIVER files, so a
#     WAIVER-class file (MEMORY.md) that gains private content below its delimiter is
#     caught — the waiver is from the reset ACTION, not from the check.
r="$(mktemp -d)"; mkfix "$r" "$HEADER_ONLY" "$MATRIX_HDR"
printf '# Memory\n\n%s\n\nPrivate operator note that must not publish.\n' "$DELIM" > "$r/MEMORY.md"
run_expect "WAIVER file with below-delimiter content is caught" 1 "$r"; rm -rf "$r"

# --- A2: seed-only marker pair (Leg S / Leg E) -------------------------------
# Fixtures F-A..F-J per docs/superpowers/specs/2026-07-28-a2-seed-only-gate-design.md §9.
STUB_LINE='<!-- STUB BOUNDARY test marker for fixtures -->'

# build a manifest at $1 with above-delimiter rows $2 and below-delimiter rows ${3:-}
mk_manifest() {
  local file="$1" above="$2" below="${3:-}"
  mkdir -p "$(dirname "$file")"
  {
    printf '# Export Manifest\n\n## Manifest\n\n'
    printf '| Path | Initial export | Upgrade strategy | Criticality | Default owner | Notes |\n'
    printf '| --- | --- | --- | --- | --- | --- |\n'
    printf '%b' "$above"
    printf '\n%s\n\n' "$DELIM"
    printf '## Downstream Additions (this repo)\n\n'
    printf '| Path | Initial export | Upgrade strategy | Criticality | Default owner | Notes |\n'
    printf '| --- | --- | --- | --- | --- | --- |\n'
    printf '%b' "$below"
  } > "$file"
}

# a seed-only surface: $1=file $2=with-marker(0/1)
mk_seed_file() {
  mkdir -p "$(dirname "$1")"
  if [ "$2" -eq 1 ]; then
    printf '# Seed file\n\nSome content.\n\n%s\n\nRest of content.\n' "$STUB_LINE" > "$1"
  else
    printf '# Seed file\n\nSome content, no marker.\n' > "$1"
  fi
}

# F-A (required failure demonstration): manifest declares TODO.md seed-only; file
# exists WITHOUT a marker — the exact Gitea #56 §6 scenario. Asserts on the FAIL
# MESSAGE TEXT, not just the exit code: this is the exact fixture shape (zero
# markers exist anywhere in the tree) that crashes check_leg_s()'s unguarded
# `"${marked_files[@]}"` expansion under bash 3.2 `set -u` — an exit-code-only
# assertion cannot distinguish the designed FAIL from that crash (both exit 1).
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM | F-A |\n'
mk_seed_file "$r/TODO.md" 0
run_expect_c "F-A: seed-only row missing its STUB BOUNDARY marker fails Leg S (required failure demo)" 1 "$r"
out="$(bash "$SCRIPT" --completeness "$r" 2>&1)"
case "$out" in
  *"missing STUB BOUNDARY marker"*) echo "ok   - F-A: failure message names the missing marker (not a crash)"; pass=$((pass+1));;
  *) echo "FAIL - F-A: failure message missing expected wording: $out"; fail=$((fail+1));;
esac
rm -rf "$r"

# F-B: positive control — marker present.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM | F-B |\n'
mk_seed_file "$r/TODO.md" 1
run_expect_c "F-B: seed-only row with its marker present passes Leg S" 0 "$r"
rm -rf "$r"

# F-C: seed-only row, file absent -> WARN + skip, exit 0 (precedent :158).
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM | F-C |\n'
run_expect_c "F-C: seed-only row with absent file warns and skips (exit 0)" 0 "$r"
rm -rf "$r"

# F-D: file mentions "STUB BOUNDARY" inline mid-prose (as the runbooks do) — must
# NOT count as a marker for Leg S (still fails, same as no marker at all) and must
# NOT trip Leg E (both mode stays clean for this file) — the anchor-discrimination case.
# The --completeness leg asserts on FAIL MESSAGE TEXT, not just exit code: an inline
# mid-prose mention means find_marked() matches nothing anywhere in the tree, which
# is the same zero-marker shape that crashes check_leg_s()'s unguarded
# `"${marked_files[@]}"` expansion under bash 3.2 (crash also exits 1, indistinguishable
# from the designed FAIL by exit code alone).
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM | F-D |\n'
mkdir -p "$r"
printf '# TODO\n\nThe gate greps for "STUB BOUNDARY" inline, not as a real marker.\n' > "$r/TODO.md"
run_expect_c "F-D: inline STUB BOUNDARY mention does not satisfy Leg S" 1 "$r"
out="$(bash "$SCRIPT" --completeness "$r" 2>&1)"
case "$out" in
  *"missing STUB BOUNDARY marker"*) echo "ok   - F-D: failure message names the missing marker (not a crash)"; pass=$((pass+1));;
  *) echo "FAIL - F-D: failure message missing expected wording: $out"; fail=$((fail+1));;
esac
run_expect    "F-D: inline STUB BOUNDARY mention does not trip Leg E (both mode stays clean)" 0 "$r"
rm -rf "$r"

# F-D2 (sibling of F-D, the real defect shape): file quotes the marker's REAL
# opening syntax (`<!-- STUB BOUNDARY ...`) verbatim, INDENTED four spaces inside a
# fenced code block — exactly docs/downstream-upgrade-playbook.md:100's copy-paste
# instruction shape, and exactly what a leading-whitespace-tolerant STUB_PATTERN
# (`^[[:space:]]*<!-- STUB BOUNDARY`) used to false-positive as a live marker. F-D's
# plain-text, no-`<!--`, no-line-start mention never exercised this shape — it
# passed under the OLD pattern too, so it never proved the anchor was column-0
# rather than merely "line start after whitespace". Must NOT count as a marker for
# Leg S (still fails, same as no marker) and must NOT trip Leg E (both mode stays
# clean) now that STUB_PATTERN is column-0 anchored.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM | F-D2 |\n'
mkdir -p "$r"
printf '%s\n' \
  '# TODO' '' 'Copy the marker verbatim to add your own:' '' '```' \
  '    <!-- STUB BOUNDARY (not a split-merge delimiter): example only -->' '```' \
  > "$r/TODO.md"
run_expect_c "F-D2: indented, code-fenced, real-syntax marker mention does not satisfy Leg S" 1 "$r"
out="$(bash "$SCRIPT" --completeness "$r" 2>&1)"
case "$out" in
  *"missing STUB BOUNDARY marker"*) echo "ok   - F-D2: failure message names the missing marker (not a crash)"; pass=$((pass+1));;
  *) echo "FAIL - F-D2: failure message missing expected wording: $out"; fail=$((fail+1));;
esac
run_expect    "F-D2: indented, code-fenced, real-syntax marker mention does not trip Leg E (both mode stays clean)" 0 "$r"
rm -rf "$r"

# F-E: export tree, seed file still carries its marker -> both mode exit 1.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM | F-E |\n'
mk_seed_file "$r/TODO.md" 1
run_expect "F-E: export tree with surviving STUB BOUNDARY marker fails Leg E (both mode)" 1 "$r"
rm -rf "$r"

# F-F: same tree, stripped -> both mode exit 0.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM | F-F |\n'
mk_seed_file "$r/TODO.md" 0
run_expect "F-F: export tree with marker stripped passes Leg E (both mode)" 0 "$r"
rm -rf "$r"

# F-G: manifest with the seed-only row BELOW the split-merge delimiter; file lacks
# a marker -> Leg S still fails (proves the whole-file / delimiter-agnostic parse —
# a downstream's own below-delimiter seed-only rows are enforced too). Asserts on
# FAIL MESSAGE TEXT, not just exit code: this fixture too is the zero-marker shape
# that crashes check_leg_s()'s unguarded `"${marked_files[@]}"` expansion under
# bash 3.2 (the crash also exits 1, so exit-code-only would pass on a crash).
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '' '| `DOWNSTREAM.md` | seed only | `downstream-owned` | `n/a` | PM | F-G below-delimiter row |\n'
mk_seed_file "$r/DOWNSTREAM.md" 0
run_expect_c "F-G: below-delimiter seed-only row is still enforced (whole-file parse)" 1 "$r"
out="$(bash "$SCRIPT" --completeness "$r" 2>&1)"
case "$out" in
  *"missing STUB BOUNDARY marker"*) echo "ok   - F-G: failure message names the missing marker (not a crash)"; pass=$((pass+1));;
  *) echo "FAIL - F-G: failure message missing expected wording: $out"; fail=$((fail+1));;
esac
rm -rf "$r"

# F-H: seed-only row naming a glob/directory -> FAIL, exact-file message.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `minions/plans/*.md` | seed only | `downstream-owned` | `n/a` | PM | F-H glob row |\n'
run_expect_c "F-H: glob/directory seed-only row fails with an exact-file message" 1 "$r"
out="$(bash "$SCRIPT" --completeness "$r" 2>&1)"
case "$out" in
  *"exact file"*) echo "ok   - F-H: failure message names the exact-file requirement"; pass=$((pass+1));;
  *) echo "FAIL - F-H: failure message missing exact-file wording: $out"; fail=$((fail+1));;
esac
rm -rf "$r"

# F-I: synthetic canonical-shaped tree — several manifest seed-only rows, each with
# its marker present (Leg S's live multi-row shape: feedback.md/ROADMAP.md/TODO.md/
# docs/MECHANICS.md/docs/DESIGN.md are all declared seed-only in the real manifest).
# Re-rooted off the live repo (was `$(cd "$(dirname "$0")/../.." && pwd)`) — same
# Export/Privacy SME finding as case 12: once tools/tests/ is copied into an export
# tree and the suite runs FROM there, that expression resolves to the EXPORT tree,
# where Step 2 correctly stripped every seed-only marker, so a straight re-run
# there fails Leg S for reasons that have nothing to do with what this fixture
# means to prove. The live-repo invariant is still asserted continuously via the
# runbook/CI's direct `--completeness .` against canonical, never via this suite's
# relative test-file location.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" \
  '| `feedback.md` | seed only | `downstream-owned` | `n/a` | PM | F-I row 1 |\n| `ROADMAP.md` | seed only | `downstream-owned` | `n/a` | PM | F-I row 2 |\n| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM | F-I row 3 |\n'
mk_seed_file "$r/feedback.md" 1
mk_seed_file "$r/ROADMAP.md" 1
mk_seed_file "$r/TODO.md" 1
run_expect_c "F-I: synthetic multi-row seed-only tree passes Leg S (re-rooted off live repo)" 0 "$r"
rm -rf "$r"

# F-J: mode isolation — a source-shaped fixture (seed-only row, marker-less file —
# would fail Leg S if it ran) passes cleanly under `both` mode, proving Leg S does
# not run there.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM | F-J |\n'
mk_seed_file "$r/TODO.md" 0
run_expect "F-J: source-shaped fixture (no marker) passes both mode — Leg S must not run there" 0 "$r"
rm -rf "$r"

# --- Existing no-op guarantee extends to Leg S (cases 12-14 precedent) -------
# No manifest, or a manifest with no seed-only rows, must no-op Leg S rather than
# error under --completeness.
r="$(mktemp -d)"
run_expect_c "Leg S no-op: no manifest present" 0 "$r"
rm -rf "$r"

r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `README.md` | yes | `template-replace` | `feature` | PM | a yes row, no seed-only rows |\n'
run_expect_c "Leg S no-op: manifest present with no seed-only rows" 0 "$r"
rm -rf "$r"

# --- A2b: seed anchor conformance (SEED_ANCHORS / anchor_violations) ---------
# Fixtures F-K..F-R per the A2 spec's ADDENDUM §A2b.4.

# export-tree-shaped MECHANICS.md: marker already stripped (correctly reset),
# anchors possibly wrong. $1=file $2=verified-line $3=mapped-line
mk_mechanics_export() {
  mkdir -p "$(dirname "$1")"
  printf '# MECHANICS\n\n%s\n%s\n\nBody.\n' "$2" "$3" > "$1"
}

# source-shaped MECHANICS.md: marker + body still present (canonical shape).
# $1=file $2=verified-line $3=mapped-line
mk_mechanics_source() {
  mkdir -p "$(dirname "$1")"
  printf '# MECHANICS\n\n%s\n%s\n\nBody.\n\n%s\n\nRest of this repo'"'"'s own map.\n' "$2" "$3" "$STUB_LINE" > "$1"
}

# F-K (required failure demonstration): export tree; `verified @ 6ffc721` (real
# hex) — the literal v1.45.0 defect. Asserts on FAIL MESSAGE TEXT, not just exit
# code, per the same principle as F-A/F-D/F-G above: an exit-code-only assertion
# cannot tell a designed FAIL from an unrelated crash exiting 1.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `docs/MECHANICS.md` | seed only | `downstream-owned` | `n/a` | AM | F-K |\n'
mk_mechanics_export "$r/docs/MECHANICS.md" "verified @ 6ffc721" "Mapped areas: <paths>"
run_expect "F-K: real SHA in verified @ anchor fails the anchor check (both mode; required failure demo)" 1 "$r"
out="$(bash "$SCRIPT" "$r" 2>&1)"
case "$out" in
  *"seed anchor violation"*"6ffc721"*) echo "ok   - F-K: failure message names the leaked SHA"; pass=$((pass+1));;
  *) echo "FAIL - F-K: failure message missing expected wording: $out"; fail=$((fail+1));;
esac
rm -rf "$r"

# F-L: positive control — both anchors exactly as A3 writes them.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `docs/MECHANICS.md` | seed only | `downstream-owned` | `n/a` | AM | F-L |\n'
mk_mechanics_export "$r/docs/MECHANICS.md" "verified @ <sha>" "Mapped areas: <paths>"
run_expect "F-L: both anchors placeholdered correctly passes (positive control)" 0 "$r"
rm -rf "$r"

# F-M: SHA placeholdered, Mapped areas still real -> the second anchor is checked
# independently of the first. Asserts on FAIL MESSAGE TEXT, not just exit code
# (same rationale as F-K above).
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `docs/MECHANICS.md` | seed only | `downstream-owned` | `n/a` | AM | F-M |\n'
mk_mechanics_export "$r/docs/MECHANICS.md" "verified @ <sha>" "Mapped areas: tools/ tools/tests/"
run_expect "F-M: Mapped areas anchor checked independently of verified @ anchor" 1 "$r"
out="$(bash "$SCRIPT" "$r" 2>&1)"
case "$out" in
  *"seed anchor violation"*"Mapped areas: tools/ tools/tests/"*) echo "ok   - F-M: failure message names the leaked Mapped areas value"; pass=$((pass+1));;
  *) echo "FAIL - F-M: failure message missing expected wording: $out"; fail=$((fail+1));;
esac
rm -rf "$r"

# F-N: file absent -> WARN + skip, exit 0.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `docs/MECHANICS.md` | seed only | `downstream-owned` | `n/a` | AM | F-N |\n'
run_expect "F-N: anchor path absent warns and skips (exit 0)" 0 "$r"
rm -rf "$r"

# F-O: file present, `verified @` line absent entirely -> FAIL. This is the
# invariant A5's onboarding unresolvable-SHA scoping depends on (A2 spec addendum
# §A2b.2): under A3 the anchor is assumed always present; this fixture is what
# converts that assumption into an enforced property. Asserts on FAIL MESSAGE
# TEXT, not just exit code (same rationale as F-K/F-M above).
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `docs/MECHANICS.md` | seed only | `downstream-owned` | `n/a` | AM | F-O |\n'
mkdir -p "$r/docs"
printf '# MECHANICS\n\nMapped areas: <paths>\n\nBody with no verified line.\n' > "$r/docs/MECHANICS.md"
run_expect "F-O: verified @ line absent entirely fails (backs A5's absent-anchor precondition)" 1 "$r"
out="$(bash "$SCRIPT" "$r" 2>&1)"
case "$out" in
  *"seed anchor violation"*"found none"*) echo "ok   - F-O: failure message names the absent-anchor case"; pass=$((pass+1));;
  *) echo "FAIL - F-O: failure message missing expected wording: $out"; fail=$((fail+1));;
esac
rm -rf "$r"

# F-P: F-K's real-SHA anchor value, but source-shaped (marker present, as canonical
# always is) and run under --completeness -> must NOT run there; exit 0. Mode-gating
# trap: canonical legitimately carries a real SHA (docs/MECHANICS.md's own
# "Maintaining this map" section instructs re-stamping it).
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `docs/MECHANICS.md` | seed only | `downstream-owned` | `n/a` | AM | F-P |\n'
mk_mechanics_source "$r/docs/MECHANICS.md" "verified @ 6ffc721" "Mapped areas: <paths>"
run_expect_c "F-P: anchor check does not run under --completeness (mode-gating trap)" 0 "$r"
rm -rf "$r"

# F-Q: whitespace near-miss (trailing space, CR) around otherwise-correct anchors —
# tolerate leading/trailing whitespace + CR (matching seed_violations()'s \r
# handling), but still require the token literally once trimmed.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `docs/MECHANICS.md` | seed only | `downstream-owned` | `n/a` | AM | F-Q |\n'
mkdir -p "$r/docs"
printf '# MECHANICS\n\nverified @ <sha>  \r\nMapped areas: <paths>\r\n\nBody.\n' > "$r/docs/MECHANICS.md"
run_expect "F-Q: trailing whitespace/CR near-miss around anchors is tolerated" 0 "$r"
rm -rf "$r"

# F-R: synthetic canonical-shaped tree (source-shaped docs/MECHANICS.md, real SHA)
# — the anchor check must NOT run under --completeness (catches wrong-mode wiring).
# Re-rooted off the live repo (was `$(cd "$(dirname "$0")/../.." && pwd)`) — same
# Export/Privacy SME finding as case 12/F-I: once this suite runs from inside a
# copied export tree, that expression resolves to the export tree, not canonical,
# and this specific assertion happens to still pass there today only because
# canonical's own docs/MECHANICS.md carries a real SHA — a fragile coincidence, not
# a proof of the property. Standalone and self-contained (independent of F-P, which
# proves the same mode-gating trap with a different literal SHA) so this regression
# is caught without relying on canonical's own file state at test time.
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `docs/MECHANICS.md` | seed only | `downstream-owned` | `n/a` | AM | F-R |\n'
mk_mechanics_source "$r/docs/MECHANICS.md" "verified @ 9f3e2a1" "Mapped areas: <paths>"
run_expect_c "F-R: anchor check does not run under --completeness (re-rooted off live repo)" 0 "$r"
rm -rf "$r"

# --- Regression: git-grep blind spot on an untracked export tree (blocker 2) --
# F-S (Export/Privacy SME, independently reproduced by CM): `find_marked()` used to
# branch on "is ROOT a git work tree", not on MODE. An export tree that has had
# `git init` run but whose copied-in files are not yet `git add`ed still satisfies
# `rev-parse --is-inside-work-tree` — so the old code took the `git grep` branch,
# which sees TRACKED paths only, found the untracked marker file invisible, and
# returned a false-clean `both`-mode exit 0 over a tree that still carries an unreset
# STUB BOUNDARY marker. Same fixture shape as F-E (export tree, marker present, both
# mode expects exit 1) EXCEPT the tree is `git init`-ed and the marker file is left
# untracked — this is the exact delta between the two runs of the reproduction: the
# only change is `git init`, and the verdict must NOT flip. Asserts on the FAIL
# MESSAGE TEXT, not just exit code (same discipline as F-A/D/G/K/M/O — an
# exit-code-only assertion cannot tell a designed FAIL from an unrelated crash, and
# here it also cannot tell a correct FAIL from the false-clean regression this
# fixture exists to close).
r="$(mktemp -d)"
mk_manifest "$r/docs/export-manifest.md" '| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM | F-S |\n'
mk_seed_file "$r/TODO.md" 1
git -C "$r" init -q
run_expect "F-S: git-init'd export tree with an UNTRACKED surviving marker still fails Leg E (both mode) — git-grep blind spot closed" 1 "$r"
out="$(bash "$SCRIPT" "$r" 2>&1)"
case "$out" in
  *"STUB BOUNDARY marker survives in export tree"*) echo "ok   - F-S: failure message names the surviving marker, not a false-green (not a crash either)"; pass=$((pass+1));;
  *) echo "FAIL - F-S: failure message missing expected wording (possible regression of the git-grep blind spot): $out"; fail=$((fail+1));;
esac
rm -rf "$r"

# --- Regression: anchor_violations() zero-seed-row guard survives (727c574) ---
# F-T: manifest-less root under `both` mode (same shape as fixture #1 above, which
# already exercises this path incidentally). anchor_violations() builds a
# `seed_paths` array from manifest_seed_paths(); with no docs/export-manifest.md,
# that array has zero elements. Under bash 3.2 `set -u`, `"${seed_paths[@]}"` on an
# empty array is a fatal unbound-variable error unless guarded — and because
# anchor_violations() runs via process substitution (`< <(anchor_violations)`), a
# crash there kills only the SUBSHELL: the parent still prints "ok" and exits 0. So
# exit-code and stdout assertions (fixtures #1-11 above already run this exact
# zero-row shape) cannot distinguish a guarded run from a silently-crashed one —
# reverting the guard fails NOTHING else in this suite. The guard's only observable
# effect is suppressing an "unbound variable" line on stderr, so this fixture is the
# one place that actually proves it: capture stderr alone and assert it stays
# silent of that message.
r="$(mktemp -d)"; mkfix "$r" "$HEADER_ONLY" "$MATRIX_HDR"
err="$(bash "$SCRIPT" "$r" 2>&1 1>/dev/null)"
case "$err" in
  *"unbound variable"*) echo "FAIL - F-T: anchor_violations() zero-seed-row guard regressed (unbound variable on stderr): $err"; fail=$((fail+1));;
  *) echo "ok   - F-T: anchor_violations() zero-seed-row guard holds (stderr silent of unbound variable)"; pass=$((pass+1));;
esac
rm -rf "$r"

# --- Regression: prose mention of the delimiter phrase is not the delimiter ---
# F-U (v1.45.0 defect, fixed under Fix 5): seed_violations() used to match the
# delimiter with a bare substring test (`index($0, "DOWNSTREAM CONTENT BELOW")`),
# not the anchored `^[[:space:]]*<!--.*DOWNSTREAM CONTENT BELOW.*-->` pattern
# find_delimited() already used. docs/export-manifest.md:28 carries exactly this
# shape in the shipped repo: prose naming the marker convention, followed by a
# legitimate above-delimiter data table, followed by the REAL delimiter at
# line 250. Under the old substring match, the prose line alone flipped
# `below=1`, so every legitimate above-delimiter line after it — including a
# real data table — was misread as a below-delimiter leak (200 FAIL lines
# against the live file). This fixture reproduces that exact shape rather than
# only re-running the live file, so the regression is caught even if
# export-manifest.md's prose is later reworded. The Local Registry below the
# REAL delimiter is genuinely header-only, so the whole fixture must pass
# (exit 0) — proving the anchored matcher ignores the prose mention and finds
# only the true delimiter line.
r="$(mktemp -d)"
mkdir -p "$r/minions/smes"
{
  printf '# SMEs\n\n'
  printf 'See the `DOWNSTREAM CONTENT BELOW` marker convention for detail on\n'
  printf 'how this file splits template and downstream content.\n\n'
  printf '## Legitimate above-delimiter table (must not be misread as a leak)\n\n'
  printf '| SME | Charter |\n| --- | --- |\n| Governance-Invariant SME | `gi.md` |\n| Cross-Family Launcher SME | `cf.md` |\n\n'
  printf '%s\n\n' "$DELIM"
  printf '## Local Registry (this repo)\n\n'
  printf '| SME | Charter |\n| --- | --- |\n'
} > "$r/minions/smes/README.md"
run_expect "F-U: a prose mention of the delimiter phrase above the REAL delimiter is not mistaken for it (docs/export-manifest.md:28 shape)" 0 "$r"
rm -rf "$r"

echo "----- $pass passed, $fail failed -----"
[ "$fail" -eq 0 ]
