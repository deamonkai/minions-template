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

# --- C1: directory/glob row matching in class lookup ---------------------------
# The manifest documents directory rows (`sub/`), glob rows (`chat/*.md`) and
# directory-glob rows (`mail/*/`); files under them must classify as that row's
# strategy, not `unknown`. Exact rows beat directory/glob rows; deepest dir wins.
TMP3="$(mktemp -d)"; O3="$TMP3/old"; N3="$TMP3/new"; M3="$TMP3/manifest.md"
mkdir -p "$O3" "$N3/sub/deep" "$N3/chat" "$N3/mail/2026-01"
cat > "$M3" <<'EOF'
| Path | Initial export | Upgrade strategy | Criticality | Default owner | Notes |
| --- | --- | --- | --- | --- | --- |
| `sub/` | yes | `template-replace` | `reference` | PM | directory row (listed BEFORE the exact row on purpose) |
| `sub/exact.md` | yes | `manual-merge` | `baseline` | PM | exact row inside a directory row |
| `sub/deep/` | yes | `downstream-owned` | `n/a` | PM | nested (deeper) directory row |
| `chat/*.md` | yes | `downstream-owned` | `n/a` | PM | glob row |
| `mail/*/` | yes | `manual-merge` | `n/a` | PM | directory-glob row |
EOF
printf 'x\n' > "$N3/sub/exact.md"
printf 'x\n' > "$N3/sub/plain.md"
printf 'x\n' > "$N3/sub/deep/nested.md"
printf 'x\n' > "$N3/chat/2026-01-01.md"
printf 'x\n' > "$N3/chat/readme.txt"
printf 'x\n' > "$N3/mail/2026-01/packet.md"
OUT4="$(bash "$SUT" --old "$O3" --new "$N3" --manifest "$M3")"
check "C1 exact row beats directory row"            bash -c "printf '%s' \"\$0\" | grep -Eq 'manual-merge +added +- +sub/exact\.md'" "$OUT4"
check "C1 directory row classifies file under it"   bash -c "printf '%s' \"\$0\" | grep -Eq 'template-replace +added +- +sub/plain\.md'" "$OUT4"
check "C1 deepest directory row wins"               bash -c "printf '%s' \"\$0\" | grep -Eq 'downstream-owned +added +- +sub/deep/nested\.md'" "$OUT4"
check "C1 glob row classifies matching file"        bash -c "printf '%s' \"\$0\" | grep -Eq 'downstream-owned +added +- +chat/2026-01-01\.md'" "$OUT4"
check "C1 dir-glob row classifies file under it"    bash -c "printf '%s' \"\$0\" | grep -Eq 'manual-merge +added +- +mail/2026-01/packet\.md'" "$OUT4"
check "C1 non-matching file stays unknown"          bash -c "printf '%s' \"\$0\" | grep -Eq 'unknown +added +- +chat/readme\.txt'" "$OUT4"
rm -rf "$TMP3"

# --- C2: git-diff completeness cross-check (--repo/--from/--to) -----------------
# Field evidence: a six-release downstream upgrade silently missed changed files
# that never made it into the snapshots. Given the live git history, every file
# changed <from>..<to> whose manifest row says "Initial export: yes" must appear
# in the old∪new snapshot union; any that does not is an UNMANIFESTED-CHANGE,
# reported loudly at the TOP of the output, with a non-zero (4) exit.
TMP4="$(mktemp -d)"; O4="$TMP4/old"; N4="$TMP4/new"; M4="$TMP4/manifest.md"; R4="$TMP4/repo"
mkdir -p "$O4" "$N4" "$R4/docs"
cat > "$M4" <<'EOF'
| Path | Initial export | Upgrade strategy | Criticality | Default owner | Notes |
| --- | --- | --- | --- | --- | --- |
| `exported-missing.md` | yes | `template-replace` | `feature` | PM | exported; deliberately absent from both snapshots |
| `exported-present.md` | yes | `template-replace` | `feature` | PM | exported; present in snapshots |
| `not-exported.md` | no | `do-not-export` | `n/a` | PM | Initial export: no -> never flagged |
| `docs/` | yes | `template-replace` | `feature` | PM | directory row: cross-check must use glob-aware matching |
EOF
GITT() { git -C "$R4" -c user.name=t -c user.email=t@t "$@"; }
GITT init -q
printf 'v1\n' > "$R4/exported-missing.md"; printf 'v1\n' > "$R4/exported-present.md"
printf 'v1\n' > "$R4/not-exported.md";     printf 'v1\n' > "$R4/docs/under-dir.md"
GITT add -A; GITT commit -q -m one; GITT tag t1
printf 'v2\n' > "$R4/exported-missing.md"; printf 'v2\n' > "$R4/exported-present.md"
printf 'v2\n' > "$R4/not-exported.md";     printf 'v2\n' > "$R4/docs/under-dir.md"
GITT add -A; GITT commit -q -m two; GITT tag t2
# snapshots contain ONLY exported-present.md — everything else changed-and-exported is a gap
printf 'v1\n' > "$O4/exported-present.md"; printf 'v2\n' > "$N4/exported-present.md"
OUT5="$(bash "$SUT" --old "$O4" --new "$N4" --manifest "$M4" --repo "$R4" --from t1 --to t2)"; rc5=$?
check "C2 unmanifested exported change flagged"        bash -c "printf '%s' \"\$0\" | grep -Eq 'UNMANIFESTED-CHANGE +exported-missing\.md'" "$OUT5"
check "C2 dir-row-matched change flagged (glob-aware)" bash -c "printf '%s' \"\$0\" | grep -Eq 'UNMANIFESTED-CHANGE +docs/under-dir\.md'" "$OUT5"
check "C2 loud: first output line is UNMANIFESTED-CHANGE" bash -c "printf '%s' \"\$0\" | head -n 1 | grep -q 'UNMANIFESTED-CHANGE'" "$OUT5"
check "C2 snapshot-present change NOT flagged"         bash -c "! printf '%s' \"\$0\" | grep -E 'UNMANIFESTED-CHANGE' | grep -q 'exported-present\.md'" "$OUT5"
check "C2 Initial-export:no change NOT flagged"        bash -c "! printf '%s' \"\$0\" | grep -E 'UNMANIFESTED-CHANGE' | grep -q 'not-exported\.md'" "$OUT5"
check "C2 unmanifested changes -> exit 4"              test "$rc5" -eq 4
check "C2 partial --repo flags -> usage exit 2"        bash -c "bash '$SUT' --old '$O4' --new '$N4' --manifest '$M4' --repo '$R4' >/dev/null 2>&1; [ \$? -eq 2 ]"
rm -rf "$TMP4"
# back-compat: without the flags, no cross-check output on the original fixture run
check "C2 no --repo flags -> no UNMANIFESTED-CHANGE lines" bash -c "! printf '%s' \"\$0\" | grep -q 'UNMANIFESTED-CHANGE'" "$OUT"

# --- C3: --hide-excluded suppresses do-not-export rows (default off) ------------
# Field evidence: do-not-export noise re-surfaces every upgrade run and buries
# the rows that need action. With the flag, those rows are hidden and the
# summary notes how many; without it, output is unchanged (back-compat).
TMP5="$(mktemp -d)"; O5="$TMP5/old"; N5="$TMP5/new"; M5="$TMP5/manifest.md"
mkdir -p "$O5" "$N5"
cat > "$M5" <<'EOF'
| Path | Initial export | Upgrade strategy | Criticality | Default owner | Notes |
| --- | --- | --- | --- | --- | --- |
| `keep.md` | yes | `template-replace` | `feature` | PM | actionable row |
| `noise.md` | no | `do-not-export` | `n/a` | PM | recurring noise row |
EOF
printf 'v1\n' > "$O5/keep.md";  printf 'v2\n' > "$N5/keep.md"
printf 'v1\n' > "$O5/noise.md"; printf 'v2\n' > "$N5/noise.md"
OUT6="$(bash "$SUT" --old "$O5" --new "$N5" --manifest "$M5")"
OUT7="$(bash "$SUT" --old "$O5" --new "$N5" --manifest "$M5" --hide-excluded)"
check "C3 without flag: do-not-export row shown"     bash -c "printf '%s' \"\$0\" | grep -Eq 'do-not-export +modified +- +noise\.md'" "$OUT6"
check "C3 without flag: summary format unchanged"    bash -c "printf '%s' \"\$0\" | grep -q '^changed files: 2\$'" "$OUT6"
check "C3 with flag: do-not-export row hidden"       bash -c "! printf '%s' \"\$0\" | grep -q 'noise\.md'" "$OUT7"
check "C3 with flag: actionable row still shown"     bash -c "printf '%s' \"\$0\" | grep -Eq 'template-replace +modified +- +keep\.md'" "$OUT7"
check "C3 with flag: summary notes N excluded hidden" bash -c "printf '%s' \"\$0\" | grep -q '^changed files: 1 (1 excluded hidden)\$'" "$OUT7"
rm -rf "$TMP5"

rm -rf "$TMP"
echo "----- $pass passed, $fail failed -----"
test "$fail" -eq 0
