#!/usr/bin/env bash
set -uo pipefail
# Self-test for tools/export-seed-check.sh — the public-export seed-state guard.
# An untested guard is theater (same rule as governance-consistency.test.sh's
# detectors). Fixtures are built under mktemp roots; the guard is never run against
# the live canonical tree here — canonical is intentionally filled and would (rightly)
# fail, so live-tree behavior is proven separately in the runbook gate, not the suite.
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/export-seed-check.sh"
[ -f "$SCRIPT" ] || { echo "FAIL - export-seed-check.sh not found at $SCRIPT"; exit 1; }
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

# 12) the LIVE repo invariant: no unclassified delimited exportable file (drift guard —
#     a future delimited file that nobody enrolls in SEED_FILES/WAIVER breaks this).
run_expect_c "live repo: every delimited exportable file is classified" 0 "$(cd "$(dirname "$0")/../.." && pwd)"

# 13) a NEW delimited file in neither SEED nor WAIVER fails completeness (no manifest
#     -> every delimited file is in scope, conservative). NOTE: mktemp roots are not
#     git work trees, so this (and case 14) exercise find_delimited()'s grep -r
#     fallback branch — the git-grep path is covered by case 12 (live repo).
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

echo "----- $pass passed, $fail failed -----"
[ "$fail" -eq 0 ]
