#!/usr/bin/env bash
set -uo pipefail
# Resolve the repo ROOT to scan. Precedence: --root <dir>  >  $GOV_ROOT  >  the
# repo this script lives in. The resolved ROOT (and the scanned file set, below) are
# printed so "what did I just test" is never ambiguous: running a CLONE's copy by
# mistake scans the clone, not your live repo, and would silently mislead a
# downstream pre-check.
ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "usage: --root needs a value" >&2; exit 2; }; ROOT="$2"; shift 2;;
    *) echo "usage: governance-consistency.test.sh [--root <repo-dir>]   (or set GOV_ROOT)" >&2; exit 2;;
  esac
done
ROOT="${ROOT:-${GOV_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}}"
ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || { echo "FAIL - --root/GOV_ROOT is not a directory" >&2; exit 2; }
cd "$ROOT"
echo "governance scan ROOT: $ROOT"
fail=0

# Retired-norm detector.
# Whole-file whitespace normalization (collapse tabs/newlines/runs of spaces to a
# single space) defeats line-wrapped prose — a line-based grep misses a norm split
# across two lines (e.g. "Do\nnot spawn them automatically"). The reliable signal
# for the retired norm is "spawn" co-occurring with "automatic" (EITHER order,
# within one sentence — bounded by . ? !), or "auto-spawn", or "on its/their own
# initiative". We deliberately do NOT key on a bare "ask ... explicit": in the
# canonical norm it accompanies "spawn automatically" (already caught), and on its
# own it false-positives on legitimate new-posture text such as "ask for explicit
# approval before merging". No regex disambiguates "don't spawn without approval"
# (old) from "spawn freely; approval only for merge" (new), so exotic paraphrases
# are the playbook's manual specific-phrasing scan job, not this heuristic's.
# Returns 0 (true) when $1 still carries the retired auto-spawn norm.
has_old_norm() {
  tr -s '\t\n ' ' ' < "$1" \
    | grep -qiE 'spawn[^.?!]*automatic|automatic[^.?!]*spawn|auto-?spawn|on (its|their) own initiative'
}

# Self-test the detector — an untested detector is theater. It must CATCH a known-bad
# sample that defeats line-based grep (wrapped + "asks explicitly"), and must NOT flag
# a known-good sample (the new posture). Downstream feedback (a downstream trading-bot project SM)
# found the old line-based detector false-PASSing on exactly this shape.
__t="$(mktemp)"
_pos() { printf '%b' "$2" > "$__t"; has_old_norm "$__t"   || { echo "FAIL - detector self-test (missed positive): $1"; fail=1; }; }
_neg() { printf '%b' "$2" > "$__t"; ! has_old_norm "$__t" || { echo "FAIL - detector self-test (false positive): $1"; fail=1; }; }
# positives — each retired-norm signal in isolation (so a broken branch can't hide)
_pos "wrapped 'spawn ... automatically'"        'Launchers are thin. Do\nnot spawn them automatically.\n'
_pos "'automatically spawn' (reverse order)"    'Never automatically spawn role agents.\n'
_pos "'auto-spawn' hyphenated"                  'Do not auto-spawn role agents.\n'
_pos "'on their own initiative'"                'Tools must not act on their own initiative.\n'
# negatives — legitimate new-posture / hard-stop look-alikes must NOT trip
_neg "merge-approval text (not spawning)"       'Ask for explicit approval before merging to main.\n'
_neg "new autonomous posture (spawn freely)"    'Spawn role agents and advance stages without asking permission.\n'
_neg "'task ... explicitly' (substring 'task')" 'Do this unless the task explicitly requires otherwise.\n'
rm -f "$__t"

# Expand one allowlist entry to zero or more repo-relative paths. An entry with
# glob metacharacters (* ? [) is expanded against a base dir (nullglob: no match ->
# nothing emitted, never the literal pattern); a plain path passes through verbatim.
# This lets the allowlist cover whole SME surfaces (minions/smes/*.md, sme-* launchers)
# so a future SME is scanned automatically without editing this file. Selectivity
# matters: '.claude/agents/sme-*.md' must match SME launchers but NOT role launchers.
# IFS= in the glob branch stops word-splitting from shredding a pattern (or a match)
# that contains a space before pathname expansion runs — a spaced path must expand
# whole, never be silently dropped as broken fragments (a silent coverage hole).
expand_scan_entry() { # $1=entry (repo-relative, may contain globs)  $2=base dir (default ".")
  local base="${2:-.}"
  case "$1" in
    *[\*\?\[]*) ( cd "$base" 2>/dev/null && shopt -s nullglob; IFS=; for m in $1; do printf '%s\n' "$m"; done ) ;;
    *)          printf '%s\n' "$1" ;;
  esac
}

# Self-test the expander — an untested guard is theater (same rule as the detectors
# above). Prove: glob expands to every match, sme-* is selective (no role launchers),
# a literal passes through, and a no-match glob yields NOTHING (nullglob, not the
# literal pattern — a literal pattern would silently WARN-skip and mask real coverage).
__ge="$(mktemp -d)"
mkdir -p "$__ge/minions/smes" "$__ge/.claude/agents"
: > "$__ge/minions/smes/governance-invariant.md"; : > "$__ge/minions/smes/README.md"
: > "$__ge/.claude/agents/sme-foo.md"; : > "$__ge/.claude/agents/pm.md"
[ "$(expand_scan_entry 'minions/smes/*.md' "$__ge" | sort | tr '\n' ',')" \
    = "minions/smes/README.md,minions/smes/governance-invariant.md," ] \
  || { echo "FAIL - expand_scan_entry self-test (glob did not expand to all matches)"; fail=1; }
[ "$(expand_scan_entry '.claude/agents/sme-*.md' "$__ge")" = ".claude/agents/sme-foo.md" ] \
  || { echo "FAIL - expand_scan_entry self-test (sme-* not selective — matched a role launcher)"; fail=1; }
[ "$(expand_scan_entry 'MEMORY.md' "$__ge")" = "MEMORY.md" ] \
  || { echo "FAIL - expand_scan_entry self-test (literal path did not pass through)"; fail=1; }
[ -z "$(expand_scan_entry 'minions/smes/zzz-*.md' "$__ge")" ] \
  || { echo "FAIL - expand_scan_entry self-test (no-match glob emitted the literal pattern)"; fail=1; }
mkdir -p "$__ge/dir with space"; : > "$__ge/dir with space/x.md"
[ "$(expand_scan_entry 'dir with space/*.md' "$__ge")" = "dir with space/x.md" ] \
  || { echo "FAIL - expand_scan_entry self-test (spaced glob path word-split into fragments)"; fail=1; }
rm -rf "$__ge"

# Files to scan for the retired norm. Default = the bootstrap/operative surfaces
# where the norm must NOT appear. A repo-local allowlist
# (tools/tests/governance-scan.allow, one path per line, '#' comments) overrides the
# default so a downstream can extend coverage to project-local norm-bearing docs
# without editing this script. This is an ALLOWLIST, not a glob of all markdown —
# files that legitimately *describe* the retired norm (CHANGELOG.md, AI/decisions.md,
# the upgrade playbook) would false-positive under a blind glob.
SCAN_LIST="$ROOT/tools/tests/governance-scan.allow"
raw_entries=()
if [ -f "$SCAN_LIST" ]; then
  while IFS= read -r line; do
    line="${line%%#*}"; line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$line" ] && raw_entries+=("$line")
  done < "$SCAN_LIST"
fi
if [ "${#raw_entries[@]}" -eq 0 ]; then
  # Default = bootstrap/operative surfaces + the SME surfaces (charters + sme-*
  # launchers in every family, as globs). The globs mean a repo with no allowlist
  # still scans its whole bench, and future SMEs are covered automatically.
  raw_entries=(MEMORY.md AI.md CLAUDE.md AGENTS.md .github/copilot-instructions.md \
               .claude/agents/README.md .codex/agents/README.md .github/agents/README.md \
               INIT.md docs/collaboration-playbook.md \
               'minions/smes/*.md' '.claude/agents/sme-*.md' \
               '.codex/agents/sme-*.toml' '.github/agents/sme-*.agent.md')
fi
# Expand glob entries (SME surfaces) to concrete repo-relative paths.
scan_files=()
for entry in "${raw_entries[@]}"; do
  while IFS= read -r p; do [ -n "$p" ] && scan_files+=("$p"); done < <(expand_scan_entry "$entry")
done
echo "governance scan files (${#scan_files[@]}): ${scan_files[*]}"
# Guard the guard (portable, filesystem-derived — not hardcoded to this repo's
# bench): every SME surface that EXISTS must be in the scan set. If the allowlist's
# SME globs are ever removed or a family's launcher glob stops matching, coverage
# silently shrinks and the retired-norm scan would skip norm-bearing SME docs — this
# catches that. A repo with no SMEs iterates nothing here and is unaffected.
while IFS= read -r must; do
  [ -n "$must" ] || continue
  printf '%s\n' "${scan_files[@]}" | grep -qxF "$must" \
    || { echo "FAIL - governance scan omits an existing SME surface: $must"; fail=1; }
done < <( { ls minions/smes/*.md .claude/agents/sme-*.md \
               .codex/agents/sme-*.toml .github/agents/sme-*.agent.md 2>/dev/null; } )
# Old norm must be gone from every scanned surface.
for f in "${scan_files[@]}"; do
  [ -f "$f" ] || { echo "WARN - scan target not found (skipped): $f" >&2; continue; }
  if has_old_norm "$f"; then
    echo "FAIL - stale auto-spawn norm still in $f"; fail=1
  fi
done

# New posture + the three hard-stops must be present in MEMORY.md and AI.md.
for f in MEMORY.md AI.md; do
  grep -qi 'autonomous orchestration' "$f" || { echo "FAIL - $f missing autonomous-orchestration posture"; fail=1; }
  grep -qi 'hard-stop\|hard stop' "$f"     || { echo "FAIL - $f missing hard-stops"; fail=1; }
done

# Branching model: relocated production hard-stop + coordination plane must be
# present in both MEMORY.md and AI.md.
grep -qi 'staging→main\|staging->main' MEMORY.md || { echo "FAIL - MEMORY.md missing staging->main hard-stop"; fail=1; }
grep -qi 'Class A\|Class-A' MEMORY.md            || { echo "FAIL - MEMORY.md missing coordination-plane Class A"; fail=1; }
grep -qi 'staging→main\|staging->main' AI.md     || { echo "FAIL - AI.md missing staging->main hard-stop"; fail=1; }
grep -qi 'Class A\|Class-A' AI.md                || { echo "FAIL - AI.md missing coordination-plane Class A"; fail=1; }

# Single-writer durability: the roll-up comm rule must be present in MEMORY.md.
grep -qi 'single-writer\|single writer' MEMORY.md || { echo "FAIL - MEMORY.md missing single-writer durability rule"; fail=1; }
grep -q 'DURABLE LESSONS' MEMORY.md || { echo "FAIL - MEMORY.md missing DURABLE LESSONS return block"; fail=1; }
grep -q 'SOLE-HOLDER' MEMORY.md || { echo "FAIL - MEMORY.md missing SOLE-HOLDER flag rule"; fail=1; }

# Role-roster drift guard (D5). MEMORY.md's Collaboration Model roster is the
# canonical role-set enumeration; AI.md's Role Agents launcher list must name
# the same set. Extraction: the backticked token opening each bullet in the
# named section ("- `PM` — ..." / "- `pm`"). Normalization: lowercase, then
# fold "om-test" into "om" — the roster names OM and OM-Test as distinct roles
# but a single `om` launcher serves both, so the script-comparable form is
# the launcher-level set.
role_set() { # $1=file  $2=exact "## <heading>" section title
  awk -v h="## $2" '$0==h{s=1;next} /^## /{s=0} s' "$1" \
    | sed -n 's/^- `\([A-Za-z][A-Za-z-]*\)`.*/\1/p' \
    | tr '[:upper:]' '[:lower:]' | sed 's/^om-test$/om/' | sort -u
}

# Self-test the extractor/normalizer — same rule as has_old_norm above: an
# untested guard is theater. Normalization must equate an OM-Test/OM roster
# with a lone om launcher, and a genuinely drifted set must NOT compare equal.
__ra="$(mktemp)"; __rb="$(mktemp)"
printf '%b' '## R\n\n- `PM` — plans\n- `OM-Test` — test ops\n- `OM` — prod ops\n' > "$__ra"
printf '%b' '## R\n\n- `pm`\n- `om`\n' > "$__rb"
[ "$(role_set "$__ra" R)" = "$(role_set "$__rb" R)" ] \
  || { echo "FAIL - role_set self-test (om-test/om should normalize equal)"; fail=1; }
printf '%b' '## R\n\n- `pm`\n- `om`\n- `qa`\n' > "$__rb"
[ "$(role_set "$__ra" R)" != "$(role_set "$__rb" R)" ] \
  || { echo "FAIL - role_set self-test (missed drift: extra qa role)"; fail=1; }
rm -f "$__ra" "$__rb"

mem_roles="$(role_set MEMORY.md 'Collaboration Model')"
ai_roles="$(role_set AI.md 'Role Agents')"
[ -n "$mem_roles" ] || { echo "FAIL - no roles extracted from MEMORY.md Collaboration Model roster"; fail=1; }
[ -n "$ai_roles" ]  || { echo "FAIL - no roles extracted from AI.md Role Agents launcher list"; fail=1; }
if [ -n "$mem_roles" ] && [ -n "$ai_roles" ] && [ "$mem_roles" != "$ai_roles" ]; then
  echo "FAIL - role-set drift: MEMORY.md roster [$(echo $mem_roles)] vs AI.md launchers [$(echo $ai_roles)]"; fail=1
fi

# --- Escalation Contract: all seven charters carry the section with the
# required payload. 7-file conventions are where drift happens (roster
# precedent). Self-tested below, same rule as the other extractors.
esc_ok() { # $1=charter file
  awk '/^## Escalation Contract$/{f=1;next} /^## |^<!-- =/{f=0} f' "$1" \
    | grep -qi 'Triggers' || return 1
  awk '/^## Escalation Contract$/{f=1;next} /^## |^<!-- =/{f=0} f' "$1" \
    | grep -qi 'Provide' || return 1
  awk '/^## Escalation Contract$/{f=1;next} /^## |^<!-- =/{f=0} f' "$1" \
    | grep -qi 'recommendation' || return 1
  awk '/^## Escalation Contract$/{f=1;next} /^## |^<!-- =/{f=0} f' "$1" \
    | grep -qi 'Route' || return 1
}
__ea="$(mktemp)"
printf '%b' '## Escalation Contract\n\nTriggers:\n- x\n\nProvide:\n- evidence\n- recommendation\n\nRoute: PM\n\n## Next\n' > "$__ea"
esc_ok "$__ea" || { echo "FAIL - esc_ok self-test (missed valid section)"; fail=1; }
printf '%b' '## Escalation Contract\n\nTriggers:\n- x\n\n## Next\n' > "$__ea"
! esc_ok "$__ea" || { echo "FAIL - esc_ok self-test (accepted payload-free section)"; fail=1; }
printf '%b' '## Escalation Contract\n\n<!-- ================= DOWNSTREAM CONTENT BELOW — template upgrades replace above this line only ================= -->\n\nTriggers: x\nProvide: evidence, recommendation\nRoute: PM\n' > "$__ea"
! esc_ok "$__ea" || { echo "FAIL - esc_ok self-test (tokens below delimiter masked a gutted section)"; fail=1; }
rm -f "$__ea"
for c in minions/roles/PM.md minions/roles/AM.md minions/roles/CM.md \
         minions/roles/SM.md minions/roles/DM.md minions/roles/OM.md \
         minions/roles/RM.md; do
  esc_ok "$c" || { echo "FAIL - $c missing/incomplete Escalation Contract (Triggers+Provide+recommendation+Route)"; fail=1; }
done

# --- Launcher bootstrap surfaces: every role launcher in every family must
# instruct the three bootstrap reads (capability inventory, SME registry,
# review matrix). v1.27.0 wired the expertise surfaces into entry-point
# files only, and spawned minions never saw them — this guard makes the
# three-layer wiring rule mechanical. Self-tested below.
launcher_ok() { # $1=launcher file
  grep -q 'capabilities\.md'  "$1" || return 1
  grep -q 'smes/README\.md'   "$1" || return 1
  grep -q 'review-matrix\.md' "$1" || return 1
}
__la="$(mktemp)"
printf '%b' 'Read minions/capabilities.md.\nRead minions/smes/README.md and minions/review-matrix.md.\n' > "$__la"
launcher_ok "$__la" || { echo "FAIL - launcher_ok self-test (missed valid launcher)"; fail=1; }
printf '%b' 'Read minions/capabilities.md.\nRead minions/smes/README.md.\n' > "$__la"
! launcher_ok "$__la" || { echo "FAIL - launcher_ok self-test (accepted launcher missing review-matrix)"; fail=1; }
rm -f "$__la"
for r in pm am cm sm dm om rm; do
  for f in ".claude/agents/$r.md" ".codex/agents/$r.toml" ".github/agents/$r.agent.md"; do
    launcher_ok "$f" || { echo "FAIL - $f missing a bootstrap-surface read (capabilities/smes-README/review-matrix)"; fail=1; }
  done
done

# --- Pipeline stage launchers (coder/tester): cross-family PARITY + bootstrap
# wiring. coder/tester are a THIRD launcher class (the Mid-tier implement/test
# stages /ship prefers over cm), deliberately kept OUT of the 7-role loop above
# and the role-set drift guard so they never enter the one-to-one-with-Codex
# role set. They are adopt-if-used — a downstream may ship NONE — but PARTIAL
# deployment is drift: present in one family and missing in another means a
# spawned minion in that other family silently can't reach the stage. Rule:
# present in ALL THREE families, or NONE. Every present launcher still gets the
# launcher_ok bootstrap-read check (same as roles). Self-tested (house rule).
stage_fam_path() { # $1=base  $2=stage  $3=family(claude|codex|github) -> launcher path
  case "$3" in
    claude) printf '%s/.claude/agents/%s.md' "$1" "$2";;
    codex)  printf '%s/.codex/agents/%s.toml' "$1" "$2";;
    github) printf '%s/.github/agents/%s.agent.md' "$1" "$2";;
  esac
}
stage_families_present() { # $1=base  $2=stage -> space-joined subset of {claude codex github} present
  local fam out=""
  for fam in claude codex github; do
    [ -f "$(stage_fam_path "$1" "$2" "$fam")" ] && out="$out $fam"
  done
  printf '%s' "${out# }"
}
__sp="$(mktemp -d)"; mkdir -p "$__sp/.claude/agents" "$__sp/.codex/agents" "$__sp/.github/agents"
[ -z "$(stage_families_present "$__sp" coder)" ] \
  || { echo "FAIL - stage_families_present self-test (none present should be empty)"; fail=1; }
: > "$__sp/.claude/agents/coder.md"; : > "$__sp/.codex/agents/coder.toml"; : > "$__sp/.github/agents/coder.agent.md"
[ "$(stage_families_present "$__sp" coder)" = "claude codex github" ] \
  || { echo "FAIL - stage_families_present self-test (all present should list all three)"; fail=1; }
: > "$__sp/.claude/agents/tester.md"
[ "$(stage_families_present "$__sp" tester)" = "claude" ] \
  || { echo "FAIL - stage_families_present self-test (partial should list only the present family)"; fail=1; }
rm -rf "$__sp"
for stage in coder tester; do
  present="$(stage_families_present "." "$stage")"
  [ -n "$present" ] || continue          # adopt-if-used: none present -> not adopted, skip
  n=0; for _f in $present; do n=$((n+1)); done
  if [ "$n" -lt 3 ]; then
    echo "FAIL - pipeline stage launcher '$stage' partial cross-family deployment (present only in: $present) — parity requires all three families or none"; fail=1
  fi
  for fam in $present; do
    p="$(stage_fam_path "." "$stage" "$fam")"; p="${p#./}"
    launcher_ok "$p" || { echo "FAIL - $p missing a bootstrap-surface read (capabilities/smes-README/review-matrix)"; fail=1; }
  done
done

# --- Stale "coder/tester is Claude-only / does not exist cross-family" claim.
# coder/tester now ship in all three families (enforced above), so an
# AUTHORITATIVE launcher doc still asserting they DON'T exist in Codex/Copilot is
# stale drift a reader would trust. Distinct from has_old_norm (auto-spawn): the
# signal is co-occurrence, in ONE sentence, of a negation AND a family
# (codex|copilot) AND a stage (coder|tester). Requiring a stage token is
# deliberate — it does NOT trip on the still-true "no Codex or Copilot /ship" or
# "Codex has no model: selector" lines, which name no stage alongside the negation.
#
# Bounding is structural, not just punctuation: awk flattens each markdown BLOCK
# (blank line / list item / heading / table row terminate a block; soft-wrapped
# lines within a block join with a space), then we split on .?! so each line is one
# SENTENCE. Three chained greps then test co-occurrence per sentence — order-
# independent and sentence-bounded, so neither two unrelated bullets nor two
# sentences in one paragraph can bridge into a false match. Negation set covers
# plain words, contractions (n't) and existence verbs (lack/missing/unavailable);
# like has_old_norm, exotic paraphrases stay the playbook's manual-scan job. Self-tested.
has_stale_stage_claim() { # $1=file -> 0 (true) if the retired non-existence claim is present
  awk '
    /^[ \t]*$/                    { printf "\n"; next }          # blank line -> block boundary
    /^[ \t]*([-*+#|]|[0-9]+[.)])/ { printf "\n%s ", $0; next }   # list/heading/table -> boundary
    { printf "%s ", $0 }                                         # soft-wrap continuation -> join
  ' "$1" \
    | tr '.?!' '\n' \
    | grep -iE '(codex|copilot)' \
    | grep -iE '(coder|tester)' \
    | grep -qiE "(no|not|never|n't|lack|missing|unavailable)"
}
__ss="$(mktemp)"
printf '%b' 'There is intentionally no Codex or Copilot `coder`/`tester`.\n' > "$__ss"
has_stale_stage_claim "$__ss" || { echo "FAIL - has_stale_stage_claim self-test (missed 'no Codex or Copilot coder/tester')"; fail=1; }
printf '%b' 'The coder/tester launchers do not exist in Codex or Copilot.\n' > "$__ss"
has_stale_stage_claim "$__ss" || { echo "FAIL - has_stale_stage_claim self-test (missed reverse-order claim)"; fail=1; }
printf '%b' "Codex and Copilot don't have coder/tester launchers.\n" > "$__ss"
has_stale_stage_claim "$__ss" || { echo "FAIL - has_stale_stage_claim self-test (missed contraction phrasing)"; fail=1; }
printf '%b' 'Codex and Copilot lack coder/tester support.\n' > "$__ss"
has_stale_stage_claim "$__ss" || { echo "FAIL - has_stale_stage_claim self-test (missed 'lack' phrasing)"; fail=1; }
printf '%b' 'Matching coder/tester launchers exist in all three families including Codex and Copilot.\n' > "$__ss"
! has_stale_stage_claim "$__ss" || { echo "FAIL - has_stale_stage_claim self-test (false positive on reconciled 'exist' statement)"; fail=1; }
printf '%b' 'There is no Codex or Copilot `/ship` equivalent yet.\n' > "$__ss"
! has_stale_stage_claim "$__ss" || { echo "FAIL - has_stale_stage_claim self-test (false positive on still-true no-/ship line)"; fail=1; }
printf '%b' '- There is no plan to add X to Codex\n- coder/tester already exist in Copilot though\n' > "$__ss"
! has_stale_stage_claim "$__ss" || { echo "FAIL - has_stale_stage_claim self-test (bullet bridge: unrelated bullets must not false-match)"; fail=1; }
printf '%b' 'The coder/tester launchers exist. Codex has no /ship command.\n' > "$__ss"
! has_stale_stage_claim "$__ss" || { echo "FAIL - has_stale_stage_claim self-test (sentence bridge: split tokens across two sentences must not match)"; fail=1; }
rm -f "$__ss"
for f in .claude/agents/README.md docs/minion-prompt-modes.md docs/downstream-upgrade-playbook.md; do
  [ -f "$f" ] || { echo "WARN - stale-stage-claim target not found (skipped): $f" >&2; continue; }
  if has_stale_stage_claim "$f"; then
    echo "FAIL - stale 'no cross-family coder/tester' claim still in $f (coder/tester now ship in all three families)"; fail=1
  fi
done

# --- Second Brain onboarding wiring: the four onboarding surfaces must carry
# the gate-conditioned second-brain PULL line (mirrors the Mnemoverse recall
# read-order wiring lesson: a capability documented only in its own model doc,
# with no onboarding-surface pull, is a capability spawned minions never see).
# The gate token and the second-brain token must CO-OCCUR within the same
# onboarding BLOCK (paragraph / list item), not merely anywhere in the file —
# two independent whole-file greps would false-pass a file that mentions
# MINION_SECONDBRAIN in one unrelated block and "second brain" in another.
# Reuses the same block-flatten technique as has_stale_stage_claim above
# (blank line / list item / heading / table row terminate a block; soft-wrapped
# lines within a block join with a space) because the onboarding bullets
# themselves wrap across source lines — a line-only check would miss a bullet
# split across two lines. Self-tested below (house rule: an untested guard is
# theater).
secondbrain_wired() { # $1=file -> 0 (true) when a single flattened block
  # contains BOTH the MINION_SECONDBRAIN gate token and a second-brain token
  # (case-insensitive on the second-brain token so "second brain"/
  # "Second-Brain" both count).
  awk '
    /^[ \t]*$/                    { printf "\n"; next }          # blank line -> block boundary
    /^[ \t]*([-*+#|]|[0-9]+[.)])/ { printf "\n%s ", $0; next }   # list/heading/table -> boundary
    { printf "%s ", $0 }                                         # soft-wrap continuation -> join
  ' "$1" \
    | grep -iE 'MINION_SECONDBRAIN' \
    | grep -qiE 'second[- ]brain'
}
__sb="$(mktemp)"
printf '%b' 'When MINION_SECONDBRAIN=on, pull the local second-brain vault.\n' > "$__sb"
secondbrain_wired "$__sb" || { echo "FAIL - secondbrain_wired self-test (missed valid line)"; fail=1; }
printf '%b' 'When the layer is on, pull the local second-brain vault.\n' > "$__sb"
! secondbrain_wired "$__sb" || { echo "FAIL - secondbrain_wired self-test (accepted line missing the gate token)"; fail=1; }
printf '%b' 'When MINION_SECONDBRAIN=on, pull the local memory recall vault.\n' > "$__sb"
! secondbrain_wired "$__sb" || { echo "FAIL - secondbrain_wired self-test (accepted line missing the second-brain token)"; fail=1; }
printf '%b' 'When MINION_SECONDBRAIN=on, pull hints.\n\nSeparately, the second-brain vault exists.\n' > "$__sb"
! secondbrain_wired "$__sb" || { echo "FAIL - secondbrain_wired self-test (accepted tokens co-occurring only across DIFFERENT blocks)"; fail=1; }
rm -f "$__sb"
for f in CLAUDE.md AGENTS.md .github/copilot-instructions.md AI.md; do
  secondbrain_wired "$f" || { echo "FAIL - $f missing gate-conditioned second-brain PULL line (MINION_SECONDBRAIN + second-brain token)"; fail=1; }
done
grep -q 'Second Brain' MEMORY.md || { echo "FAIL - MEMORY.md missing Second Brain Optional-Layers subsection"; fail=1; }

# --- Skill Adoption layer wiring (merge-blocking). Two obligations, mirroring
# the second-brain wiring guard above but extended to the layer's unconditional
# protections (which must stand REGARDLESS of the MINION_SKILLS gate):
#   1. the gate-conditioned MINION_SKILLS pointer in all FOUR entry points
#      (CLAUDE.md, AGENTS.md, .github/copilot-instructions.md, MEMORY.md), and
#   2. the unconditional protections exist — the skills/vendored/ do-not-export
#      manifest row, that same path in the public-export forbidden-path gate,
#      and the hard-stop-#2 skill-vendoring instance annotation in CLAUDE.md /
#      AI.md / the three agent READMEs.
# skills_wired reuses secondbrain_wired's block-flatten co-occurrence technique:
# the gate token MINION_SKILLS and a skill-adoption token must appear in the
# SAME flattened block, not merely anywhere in the file. The distinct second
# token is `skill[- ]adoption` — which MINION_SKILLS does NOT contain (there is
# no separator between "skill" and "adoption" in the gate name), so a bare
# MINION_SKILLS mention with no adoption context cannot false-pass. Self-tested
# below (house rule: an untested guard is theater).
skills_wired() { # $1=file -> 0 (true) when a single flattened block contains
  # BOTH the MINION_SKILLS gate token and a skill-adoption token.
  awk '
    /^[ \t]*$/                    { printf "\n"; next }          # blank line -> block boundary
    /^[ \t]*([-*+#|]|[0-9]+[.)])/ { printf "\n%s ", $0; next }   # list/heading/table -> boundary
    { printf "%s ", $0 }                                         # soft-wrap continuation -> join
  ' "$1" \
    | grep -iE 'MINION_SKILLS' \
    | grep -qiE 'skill[- ]adoption'
}
__sk="$(mktemp)"
printf '%b' 'When MINION_SKILLS=on, adopt via the skill-adoption airlock.\n' > "$__sk"
skills_wired "$__sk" || { echo "FAIL - skills_wired self-test (missed valid line)"; fail=1; }
printf '%b' 'When the layer is on, adopt via the skill-adoption airlock.\n' > "$__sk"
! skills_wired "$__sk" || { echo "FAIL - skills_wired self-test (accepted line missing the gate token)"; fail=1; }
printf '%b' 'When MINION_SKILLS=on, run the local memory recall layer.\n' > "$__sk"
! skills_wired "$__sk" || { echo "FAIL - skills_wired self-test (accepted line missing the skill-adoption token)"; fail=1; }
printf '%b' 'When MINION_SKILLS=on, adopt skills here.\n\nSeparately, skill-adoption exists.\n' > "$__sk"
! skills_wired "$__sk" || { echo "FAIL - skills_wired self-test (accepted tokens co-occurring only across DIFFERENT blocks)"; fail=1; }
rm -f "$__sk"
for f in CLAUDE.md AGENTS.md .github/copilot-instructions.md MEMORY.md; do
  skills_wired "$f" || { echo "FAIL - $f missing gate-conditioned MINION_SKILLS pointer (MINION_SKILLS + skill-adoption token in one block)"; fail=1; }
done
# Unconditional protection 1: skills/vendored/ do-not-export manifest row.
grep -E 'skills/vendored/' docs/export-manifest.md | grep -qi 'do-not-export' \
  || { echo "FAIL - docs/export-manifest.md missing skills/vendored/ do-not-export row (unconditional skill-adoption protection)"; fail=1; }
# Unconditional protection 2: skills/vendored/ in the public-export forbidden-path gate.
grep -q 'skills/vendored' docs/runbooks/public-export.md \
  || { echo "FAIL - docs/runbooks/public-export.md forbidden-path gate missing skills/vendored/ (unconditional skill-adoption protection)"; fail=1; }
# Unconditional protection 3: hard-stop-#2 skill-vendoring instance (no count change).
for f in CLAUDE.md AI.md .claude/agents/README.md .codex/agents/README.md .github/agents/README.md; do
  grep -qiF 'instance of hard-stop #2' "$f" \
    || { echo "FAIL - $f missing hard-stop-#2 skill-vendoring instance annotation"; fail=1; }
done

# --- Workflow Ownership: the PM-routed-workflows law must stay present.
grep -q 'Workflow Ownership' MEMORY.md || { echo "FAIL - MEMORY.md missing Workflow Ownership (PM-routed) rule"; fail=1; }

test "$fail" -eq 0 && echo "ok - governance consistent"
exit "$fail"
