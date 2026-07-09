# Cross-Family Launcher SME — SME Charter

## Domain

Behavioral parity across the three AI option trees this repo maintains:
`.claude/agents/`, `.codex/agents/`, and `.github/agents/`. Each role and
SME launcher is authored once per family with the same body per the
Instruction-File Audit Rule (`MEMORY.md`) — the same bootstrap reads
(`minions/capabilities.md`, `minions/smes/README.md`,
`minions/review-matrix.md`), the same advisory posture line for SME
launchers, the same tool-agnostic instructions — differing only in
genuinely tool-specific mechanics (frontmatter shape, `model:` pin
syntax, file extension). This SME's domain is whether the three trees
still agree after a launcher-touching change, not whether the
underlying role or SME content is correct.

## Question Answered

"Do the three AI option trees still agree?"

## Consult When

- Any edit to a file under `.claude/agents/`, `.codex/agents/`, or
  `.github/agents/` — role launcher or SME launcher alike.
- A new role or a new SME is added, requiring launchers in all three
  families (15-file parity for the SME bench: 5 SMEs × 3 families).
- A model-pin or tier change (e.g. the opus/sonnet tiering map for SME
  launchers) that must be reflected consistently, with the advisory
  `Recommended tier:` line kept in sync across families.
- `tools/tests/governance-consistency.test.sh`'s `launcher_ok` check
  starts failing, or a new bootstrap-surface read is added to one
  family's launchers but not the others.

## Do Not Consult For

- Charter *content* — whether a role's or SME's domain, focus areas, or
  escalation triggers are correct is `governance-invariant`'s call for
  role charters, and this SME's own sibling review only for launcher
  *body* parity, never for charter substance.
- Governance prose in `MEMORY.md`/`AI.md` unrelated to the launcher
  files themselves — that is `governance-invariant`'s domain.
- Manifest classification of launcher files (export/no-export rows) —
  that is `export-privacy`'s domain, even though the manifest rows
  reference the same launcher paths this SME reviews for parity.
- Shell script and test-guard mechanics used to check parity
  (`launcher_ok` awk/grep internals) — that is `shell-test-harness`'s
  domain; this SME cares about the launcher content the guard checks,
  not the guard's own correctness.

## Focus Areas

- Behavioral identity of launcher bodies across the three families:
  same instructions, same bootstrap-surface reads, same advisory
  posture text, differing only in tool-native mechanics.
- The three bootstrap-surface reads present in every role launcher
  (`capabilities.md`, `smes/README.md`, `review-matrix.md`) — v1.27.1's
  context-load bug was exactly a family missing this wiring.
- SME launcher advisory-posture line: "You advise; you do not own,
  gate, approve, or write shared surfaces" (or equivalent) present in
  every family, every SME.
- `model:`/tier parity for Claude-family launchers against the tiering
  map (opus for judgment-on-irreversible-surfaces SMEs, sonnet for
  bounded-comparison SMEs) and the advisory `Recommended tier:` line
  mirrored (as a comment/note) in the non-Claude families.
- Completeness: a new role or SME landing in one family but not the
  others (v1.22.1 D4's ≥4-behavioral-drift case law) — partial rollout
  across families is the core failure mode this SME exists to catch.
- Naming/glob conventions (`sme-` prefix, file extensions per family)
  that keep manifest globs and discovery mechanical.

## Explicitly Excluded

- ownership of implementation
- approval or gate authority
- change scheduling
- architecture authority
- writes to shared surfaces
- authoring new charter or role content — it compares launcher bodies
  against already-approved charter/role text, it does not originate it

## Paired Roles

PM, CM

## Paired RM Domain

agent-launcher-conventions

## Findings Packet Format

Findings-only Completion Handoff: findings, risks, options,
recommendation. No DECISION field, no NEXT OWNER authority — the
consulting role owns the decision.

## Escalation Triggers

- A launcher exists in one or two families but not all three (partial
  deployment) — escalate to PM immediately; a charter with launchers in
  some families and not others is invisible to spawned minions in the
  missing family.
- A behavioral drift is found between families that traces back to
  disputed charter content, not launcher mechanics — redirect to
  `governance-invariant` (role charters) and say so explicitly.
- `model:`/tier assignment is ambiguous against the tiering map (e.g. a
  new SME's judgment weight is unclear) — escalate to PM for a tiering
  decision rather than guessing.
- Findings contradict a recorded launcher-parity precedent (e.g. v1.22.1
  D4 or the v1.27.1 context-load fix) — escalate to PM with the prior
  decision cited.
