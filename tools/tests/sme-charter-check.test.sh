#!/usr/bin/env bash
set -uo pipefail
# Self-test for tools/sme-charter-check.sh — the mechanical SME-charter validator.
# An untested guard is theater (house rule). Fixtures are built under mktemp roots;
# the last case runs the validator against the LIVE repo (the 5 canonical charters
# must pass) so a future broken/partial SME reddens CI.
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/sme-charter-check.sh"
[ -f "$SCRIPT" ] || { echo "FAIL - sme-charter-check.sh not found at $SCRIPT"; exit 1; }
pass=0; fail=0
run_expect() { # $1=label $2=expected-exit $3=root
  bash "$SCRIPT" "$3" >/dev/null 2>&1; local rc=$?
  if [ "$rc" -eq "$2" ]; then echo "ok   - $1"; pass=$((pass+1))
  else echo "FAIL - $1 (expected exit $2, got $rc)"; fail=$((fail+1)); fi
}

SECTIONS="Domain|Question Answered|Consult When|Do Not Consult For|Focus Areas|Explicitly Excluded|Paired Roles|Paired RM Domain|Findings Packet Format|Escalation Triggers"

# write a well-formed charter for <key> into <root>, with all 10 sections filled
write_good_charter() { # $1=root $2=key
  mkdir -p "$1/minions/smes"
  { echo "# $2 SME"; echo
    local IFS='|'; for s in $SECTIONS; do echo "## $s"; echo; echo "- content for $s"; echo; done
  } > "$1/minions/smes/$2.md"
}
# registry (README) with a Local Registry row referencing <key>.md
write_registry() { # $1=root  $2..=keys
  local root="$1"; shift
  mkdir -p "$root/minions/smes"
  { echo "# SMEs"; echo
    echo '<!-- ================= DOWNSTREAM CONTENT BELOW ================= -->'; echo
    echo "## Local Registry (this repo)"; echo
    echo "| SME | Charter | Domain | Consult when | Do not consult | Paired roles | RM domain | Status |"
    echo "| --- | --- | --- | --- | --- | --- | --- | --- |"
    for k in "$@"; do echo "| $k SME | \`$k.md\` | d | c | n | PM | rm | active |"; done
  } > "$root/minions/smes/README.md"
}
# launchers in all three families for <key>
write_launchers() { # $1=root $2=key
  mkdir -p "$1/.claude/agents" "$1/.codex/agents" "$1/.github/agents"
  : > "$1/.claude/agents/sme-$2.md"; : > "$1/.codex/agents/sme-$2.toml"; : > "$1/.github/agents/sme-$2.agent.md"
}
# a fully valid single-SME bench
mkbench() { # $1=root $2=key
  write_good_charter "$1" "$2"; write_registry "$1" "$2"; write_launchers "$1" "$2"
}

# 1) a fully valid bench passes
r="$(mktemp -d)"; mkbench "$r" foo
run_expect "valid single-SME bench passes" 0 "$r"; rm -rf "$r"

# 2) missing a required section fails
r="$(mktemp -d)"; mkbench "$r" foo
perl -0pi -e 's/## Escalation Triggers\n\n- content for Escalation Triggers\n\n//' "$r/minions/smes/foo.md"
run_expect "charter missing a required section fails" 1 "$r"; rm -rf "$r"

# 3) empty Do Not Consult For fails (negative discovery mandatory)
r="$(mktemp -d)"; mkbench "$r" foo
perl -0pi -e 's/## Do Not Consult For\n\n- content for Do Not Consult For\n/## Do Not Consult For\n/' "$r/minions/smes/foo.md"
run_expect "charter with empty Do Not Consult For fails" 1 "$r"; rm -rf "$r"

# 4) missing a launcher family fails (partial deployment)
r="$(mktemp -d)"; mkbench "$r" foo; rm -f "$r/.codex/agents/sme-foo.toml"
run_expect "charter missing a launcher family fails" 1 "$r"; rm -rf "$r"

# 5) missing registry row fails (invisible to routing)
r="$(mktemp -d)"; mkbench "$r" foo; write_registry "$r"   # registry with NO rows
run_expect "charter with no Local Registry row fails" 1 "$r"; rm -rf "$r"

# 6) README.md and sme-template.md are NOT treated as charters
r="$(mktemp -d)"; write_registry "$r"; : > "$r/minions/smes/sme-template.md"
run_expect "README + sme-template are not charters (empty bench passes)" 0 "$r"; rm -rf "$r"

# 8) Do Not Consult For with only non-substantive filler (fenced block) fails —
#    the gutted-section-masked hole (Shell/Test-Harness SME finding).
r="$(mktemp -d)"; mkbench "$r" foo
perl -0pi -e 's/## Do Not Consult For\n\n- content for Do Not Consult For\n/## Do Not Consult For\n\n```\nplaceholder, not a real exclusion\n```\n/' "$r/minions/smes/foo.md"
run_expect "charter with fenced-only Do Not Consult For fails" 1 "$r"; rm -rf "$r"

# 7) LIVE repo: the five canonical charters pass (drift guard)
run_expect "live repo: all canonical SME charters valid" 0 "$(cd "$(dirname "$0")/../.." && pwd)"

echo "----- $pass passed, $fail failed -----"
[ "$fail" -eq 0 ]
