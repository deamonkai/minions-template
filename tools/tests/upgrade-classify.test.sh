#!/usr/bin/env bash
# Dependency-free test harness for tools/upgrade-classify.sh.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUT="$ROOT/tools/upgrade-classify.sh"
pass=0; fail=0
check() { local desc="$1"; shift; if "$@"; then echo "ok   - $desc"; pass=$((pass+1)); else echo "FAIL - $desc"; fail=$((fail+1)); fi; }

TMP="$(mktemp -d)"; OLD="$TMP/old"; NEW="$TMP/new"; LIVE="$TMP/live"; MAN="$TMP/manifest.md"
mkdir -p "$OLD" "$NEW/sub" "$LIVE"

# fake export-manifest (kept OUTSIDE the snapshots so it isn't itself a change-set file)
cat > "$MAN" <<'EOF'
| Path | Initial export | Upgrade strategy | Criticality | Default owner | Notes |
| --- | --- | --- | --- | --- | --- |
| `a.md` | yes | `template-replace` | `feature` | PM | clean path |
| `b.md` | yes | `manual-merge` | `baseline` | PM | merge file |
| `gone.md` | yes | `downstream-owned` | `n/a` | PM | history |
| `sub/` | yes | `template-replace` | `reference` | PM | dir-prefix entry |
| `template-replace-decoy.md` | yes | `downstream-owned` | `n/a` | PM | path contains a strategy keyword (F1 regression) |
EOF

# a.md: modified between snapshots; live identical to old  -> template-replace/modified/identical
printf 'v1\n' > "$OLD/a.md"; printf 'v2\n' > "$NEW/a.md"; printf 'v1\n' > "$LIVE/a.md"
# b.md: modified; live diverged from old                   -> manual-merge/modified/diverged
printf 'v1\n' > "$OLD/b.md"; printf 'v2\n' > "$NEW/b.md"; printf 'LOCAL\n' > "$LIVE/b.md"
# sub/c.md: added in new; dir-prefix class; not in live     -> template-replace/added/missing
printf 'new\n' > "$NEW/sub/c.md"
# d.md: added in new; no manifest entry; not in live        -> unknown/added/missing
printf 'x\n' > "$NEW/d.md"
# gone.md: removed (only in old); live identical to old     -> downstream-owned/removed/identical
printf 'g\n' > "$OLD/gone.md"; printf 'g\n' > "$LIVE/gone.md"
# same.md: identical between snapshots                       -> omitted from output
printf 's\n' > "$OLD/same.md"; printf 's\n' > "$NEW/same.md"
# F1: a PATH containing a strategy keyword must classify by its CELL (downstream-owned)
printf 'v1\n' > "$OLD/template-replace-decoy.md"; printf 'v2\n' > "$NEW/template-replace-decoy.md"
# F3: a leading-hyphen filename must not be mis-handled as a grep/option (no injection, no crash)
printf 'v1\n' > "$OLD/-dash.md"; printf 'v2\n' > "$NEW/-dash.md"

OUT="$(bash "$SUT" --old "$OLD" --new "$NEW" --live "$LIVE" --manifest "$MAN")"

check "usage error without dirs" bash -c "! bash '$SUT' --old /nope >/dev/null 2>&1"
check "a.md -> template-replace/modified/identical" bash -c "printf '%s' \"\$0\" | grep -Eq 'template-replace +modified +identical +a\.md'" "$OUT"
check "b.md -> manual-merge/modified/diverged"     bash -c "printf '%s' \"\$0\" | grep -Eq 'manual-merge +modified +diverged +b\.md'" "$OUT"
check "sub/c.md -> template-replace/added/missing (dir-prefix class)" bash -c "printf '%s' \"\$0\" | grep -Eq 'template-replace +added +missing +sub/c\.md'" "$OUT"
check "d.md -> unknown/added/missing"              bash -c "printf '%s' \"\$0\" | grep -Eq 'unknown +added +missing +d\.md'" "$OUT"
check "gone.md -> downstream-owned/removed/identical" bash -c "printf '%s' \"\$0\" | grep -Eq 'downstream-owned +removed +identical +gone\.md'" "$OUT"
check "unchanged same.md is omitted" bash -c "! printf '%s' \"\$0\" | grep -q 'same\.md'" "$OUT"
check "reports 7 changed files" bash -c "printf '%s' \"\$0\" | grep -q 'changed files: 7'" "$OUT"
# F1: decoy path classified by its CELL (downstream-owned), NOT the keyword in its name
check "F1 keyword-in-path classifies by cell, not name" bash -c "printf '%s' \"\$0\" | grep -Eq 'downstream-owned +modified +missing +template-replace-decoy\.md'" "$OUT"
check "F1 decoy is NOT mislabeled template-replace" bash -c "! printf '%s' \"\$0\" | grep -Eq 'template-replace +modified +missing +template-replace-decoy\.md'" "$OUT"
# F3: leading-hyphen filename handled (row present, no crash/injection)
check "F3 leading-hyphen filename handled" bash -c "printf '%s' \"\$0\" | grep -Eq 'unknown +modified +missing +[-]dash\.md'" "$OUT"

# without --live, LIVE column is '-'
OUT2="$(bash "$SUT" --old "$OLD" --new "$NEW" --manifest "$MAN")"
check "no --live -> LIVE column is '-'" bash -c "printf '%s' \"\$0\" | grep -Eq 'template-replace +modified +- +a\.md'" "$OUT2"

# F4: a missing option value must error (exit 2), not hang. The _need guard makes a
# hang impossible, so we assert exit 2 directly — no GNU `timeout` (keeps the harness
# dependency-free / portable to stock macOS). If the guard regresses this would hang,
# a loud failure a run never completing makes obvious.
check "F4 missing option value -> exit 2 (guard prevents hang)" bash -c "bash '$SUT' --old >/dev/null 2>&1; [ \$? -eq 2 ]"

# F2: a live comparison error (file vs directory) -> LIVE=error and non-zero exit
TMP2="$(mktemp -d)"; O2="$TMP2/old"; N2="$TMP2/new"; L2="$TMP2/live"
mkdir -p "$O2" "$N2" "$L2/e.md"   # live/e.md is a DIRECTORY -> cmp errors
printf 'v1\n' > "$O2/e.md"; printf 'v2\n' > "$N2/e.md"
OUT3="$(bash "$SUT" --old "$O2" --new "$N2" --live "$L2" --manifest "$MAN" 2>/dev/null)"; rc3=$?
check "F2 cmp error -> LIVE=error row" bash -c "printf '%s' \"\$0\" | grep -Eq ' +error +e\.md'" "$OUT3"
check "F2 cmp error -> non-zero exit (3)" test "$rc3" -eq 3
rm -rf "$TMP2"

rm -rf "$TMP"
echo "----- $pass passed, $fail failed -----"
test "$fail" -eq 0
