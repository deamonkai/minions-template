#!/usr/bin/env bash
set -uo pipefail
# SME charter validator — MECHANICAL structural checks on the SME bench.
#
# This is NOT a domain-merit judge. Whether an SME should exist, whether its domain
# is well-chosen, and whether its Consult When / Do Not Consult For are drawn on the
# right line are the PM bench-review loop's and the Governance-Invariant SME's calls
# (see minions/smes/README.md "Growing the bench" and docs/designing-an-sme.md). This
# guard only enforces the enumerable, mechanical failure modes the Adding-an-SME
# checklist names — partial deployment (a charter with no launchers is invisible to
# spawned minions; a launcher with no registry row is invisible to routing), a
# missing required section, or an empty negative-discovery section.
#
# Run against a repo root (default: this repo). In a public export tree the charters
# are export=no and absent, so there is nothing to check — it passes vacuously.
#
# Usage: sme-charter-check.sh [<repo-root>]

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || { echo "FAIL - sme-charter-check: not a directory: ${1:-}" >&2; exit 2; }

# The 10 sections every charter (and sme-template.md) carries. Order-independent.
REQUIRED_SECTIONS=(
  "Domain" "Question Answered" "Consult When" "Do Not Consult For" "Focus Areas"
  "Explicitly Excluded" "Paired Roles" "Paired RM Domain" "Findings Packet Format"
  "Escalation Triggers"
)
# Launcher path templates (%s = charter key); every family must carry the launcher.
# This is a fixed list of the three current families — if a fourth AI option tree is
# ever added to the repo, add its launcher path here (the check validates against the
# known families, it does not auto-discover new ones).
FAMILIES=(".claude/agents/sme-%s.md" ".codex/agents/sme-%s.toml" ".github/agents/sme-%s.agent.md")
REGISTRY="minions/smes/README.md"

# has_section <file> <heading>: 0 if a "## <heading>" line exists.
has_section() { grep -qxF "## $2" "$1"; }

# section_nonempty <file> <heading>: 0 if there is SUBSTANTIVE content between this
# "## <heading>" and the next "## " (or the split-merge delimiter / EOF). Blank lines,
# fenced code blocks (delimiters and their contents), and HTML-comment-only lines do
# NOT count — otherwise a gutted section masked by placeholder filler (`<!-- TODO -->`,
# a stray fence) would false-pass, the same masked-section hole the esc_ok guard hit.
section_nonempty() {
  awk -v h="## $2" '
    $0==h {f=1; next}
    f && (/^## / || index($0,"DOWNSTREAM CONTENT BELOW")) {exit (found?0:1)}
    f {
      if ($0 ~ /^[[:space:]]*```/)              { fence = !fence; next }  # fence delimiter: toggle, not content
      if (fence)                                  next                     # inside a fenced block: not substance
      if ($0 ~ /^[[:space:]]*$/)                  next                     # blank
      if ($0 ~ /^[[:space:]]*<!--.*-->[[:space:]]*$/) next                 # HTML-comment-only line
      found=1
    }
    END {exit (found?0:1)}
  ' "$1"
}

# --- self-test the two extractors (house rule: an untested guard is theater) ----
__t="$(mktemp)"
printf '%b' '## Domain\n\n- x\n\n## Consult When\n\n## Do Not Consult For\n' > "$__t"
has_section "$__t" "Domain"            || { echo "FAIL - self-test: has_section missed a present section"; exit 3; }
has_section "$__t" "Missing"           && { echo "FAIL - self-test: has_section matched an absent section"; exit 3; }
section_nonempty "$__t" "Domain"       || { echo "FAIL - self-test: section_nonempty missed content"; exit 3; }
section_nonempty "$__t" "Consult When" && { echo "FAIL - self-test: section_nonempty accepted an empty section (next ## )"; exit 3; }
section_nonempty "$__t" "Do Not Consult For" && { echo "FAIL - self-test: section_nonempty accepted an empty trailing section"; exit 3; }
printf '%b' '## A\n\n```\nfiller\n```\n\n## B\n\n<!-- TODO -->\n' > "$__t"
section_nonempty "$__t" "A" && { echo "FAIL - self-test: section_nonempty accepted a fenced-code-only section"; exit 3; }
section_nonempty "$__t" "B" && { echo "FAIL - self-test: section_nonempty accepted an HTML-comment-only section"; exit 3; }
rm -f "$__t"

fail=0
check_charter() { # $1=charter file  $2=key
  local file="$1" key="$2" s fam path
  for s in "${REQUIRED_SECTIONS[@]}"; do
    has_section "$file" "$s" || { echo "FAIL - $key: missing required section '## $s'"; fail=1; }
  done
  section_nonempty "$file" "Do Not Consult For" \
    || { echo "FAIL - $key: 'Do Not Consult For' is empty — negative discovery is mandatory (prevents consult-everyone drift)"; fail=1; }
  grep -qF "\`$key.md\`" "$ROOT/$REGISTRY" 2>/dev/null \
    || { echo "FAIL - $key: no Local Registry row in $REGISTRY — the charter is invisible to review routing"; fail=1; }
  for fam in "${FAMILIES[@]}"; do
    path="$(printf "$fam" "$key")"
    [ -f "$ROOT/$path" ] || { echo "FAIL - $key: missing launcher $path — partial deployment, invisible to that family"; fail=1; }
  done
}

count=0
for f in "$ROOT"/minions/smes/*.md; do
  [ -f "$f" ] || continue
  base="$(basename "$f" .md)"
  case "$base" in README|sme-template) continue;; esac
  count=$((count+1))
  check_charter "$f" "$base"
done

test "$fail" -eq 0 && echo "ok - SME charters mechanically valid ($count checked)"
exit "$fail"
