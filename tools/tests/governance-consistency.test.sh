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
# a known-good sample (the new posture). Downstream feedback (Molloy Trading Bot SM)
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

# Files to scan for the retired norm. Default = the bootstrap/operative surfaces
# where the norm must NOT appear. A repo-local allowlist
# (tools/tests/governance-scan.allow, one path per line, '#' comments) overrides the
# default so a downstream can extend coverage to project-local norm-bearing docs
# without editing this script. This is an ALLOWLIST, not a glob of all markdown —
# files that legitimately *describe* the retired norm (CHANGELOG.md, AI/decisions.md,
# the upgrade playbook) would false-positive under a blind glob.
SCAN_LIST="$ROOT/tools/tests/governance-scan.allow"
scan_files=()
if [ -f "$SCAN_LIST" ]; then
  while IFS= read -r line; do
    line="${line%%#*}"; line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$line" ] && scan_files+=("$line")
  done < "$SCAN_LIST"
fi
if [ "${#scan_files[@]}" -eq 0 ]; then
  scan_files=(MEMORY.md AI.md CLAUDE.md AGENTS.md .github/copilot-instructions.md \
              .claude/agents/README.md .codex/agents/README.md .github/agents/README.md \
              INIT.md docs/collaboration-playbook.md)
fi
echo "governance scan files (${#scan_files[@]}): ${scan_files[*]}"
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

test "$fail" -eq 0 && echo "ok - governance consistent"
exit "$fail"
