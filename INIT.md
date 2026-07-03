# [Project Name] Onboarding

This repository is now in active downstream onboarding mode.

Purpose: move from template export into an operating project with PM, AM, CM,
SM, DM, OM, and RM discipline, durable evidence, and milestone execution.

> Managing multiple projects from this repo? Read
> [docs/coordinator-mode.md](docs/coordinator-mode.md) before step 2 — several
> steps below change meaning at coordinator scale.

## Current Status

- collaboration baseline imported
- operator onboarding checklist not yet started
- Codex custom-agent and Claude Code subagent surfaces not yet reviewed
- mailbox coordination not yet initialized
- PM daily summary thread not yet created
- milestone 0 planning not yet started

## Immediate Startup Sequence

1. Establish a filtered vendored template snapshot and perform the first controlled export using [docs/downstream-onboarding-playbook.md](docs/downstream-onboarding-playbook.md).
2. Run and complete [docs/operator-onboarding-checklist.md](docs/operator-onboarding-checklist.md) with the Operator.
3. Finalize project-specific sections in [MEMORY.md](MEMORY.md):
   - project purpose
   - architecture
   - environments
   - safety constraints
4. Open first milestone plan in [minions/plans](minions/plans).
5. Bootstrap mailbox coordination:
   - read [MEMORY.md](MEMORY.md)
   - read [.github/agents/README.md](.github/agents/README.md) when using Copilot custom agents
   - read [.codex/agents/README.md](.codex/agents/README.md) when using Codex custom agents
   - read [.claude/agents/README.md](.claude/agents/README.md) when using Claude Code subagents
   - read [docs/minion-prompt-modes.md](docs/minion-prompt-modes.md)
   - read [docs/project/mailbox-collaboration-model.md](docs/project/mailbox-collaboration-model.md)
   - read [minions/mail/README.md](minions/mail/README.md)
   - read [minions/mail/packet-template.md](minions/mail/packet-template.md)
   - use [minions/mail/](minions/mail/) for new actionable packets
   - use [minions/chat/](minions/chat/) for PM daily summaries
6. Wire this project's minion↔plugin pairings: review [docs/minion-plugin-pairings.md](docs/minion-plugin-pairings.md) and add "use-when" lines to the owning role charters for the integrations this project actually uses (plus any scoped whitelist entry a restricted role needs). Skip pairings whose plugin is absent.
7. Keep [ROADMAP.md](ROADMAP.md), [TODO.md](TODO.md), and [CHANGELOG.md](CHANGELOG.md) updated during execution, and capture Operator feedback in [feedback.md](feedback.md) (promote durable items into [MEMORY.md](MEMORY.md)).
8. Use [docs/downstream-upgrade-playbook.md](docs/downstream-upgrade-playbook.md) for later template updates.

## Roles and Handoff

- AM owns architecture truth and design direction
- CM owns implementation truth
- SM owns security truth and risk framing
- DM owns documentation truth, reader paths, and documentation sync
- OM-Test / OM owns runtime truth
- RM owns in-depth research and option analysis (recommends only; may not create or execute code)
- PM owns gates and acceptance
- Operator is final authority

Role context policy:

- each minion may maintain role-specific context in its own file under
   `minions/roles/` (for example: `PM.md`, `AM.md`, `CM.md`, `SM.md`, `DM.md`,
   `OM.md`)
- no minion may alter existing base guardrails/rules without explicit Operator
   approval

Prompt mode policy:

- named prompt modes live in `docs/minion-prompt-modes.md`
- modes sharpen role posture and output shape, but they do not change role
   ownership, handoff order, evidence requirements, or approval requirements
- formal closures still use the completion handoff contract below

Custom-agent policy (Copilot, Codex, and Claude Code):

- repo-scoped Copilot custom agents live in `.github/agents/`; Codex custom
   agents live in `.codex/agents/`; the equivalent Claude Code subagents live
   in `.claude/agents/`
- custom agents are launch config for explicit subagent spawning; they do
   not replace `MEMORY.md`, role files, prompt modes, mailbox packets, or the
   completion handoff contract
- by default, tools should keep workflows moving — spawn role agents, advance
   pipeline stages, and fire independent second opinions without waiting for
   permission; hard-stops (merge/push to main, destructive production actions,
   unresolved AI disagreement) still require Operator approval (see AI.md
   "Role Agents" for the authoritative autonomous-orchestration posture)
- keep the agent files thin and keep durable role policy in `minions/roles/`

Git handoff policy:

- no minion may hand off workflow state, implementation state, or decision-ready
   work to another minion or the Operator until at least one local commit
   captures the current change set
- a local commit is the minimum handoff checkpoint for every minion role
- if the next owner is operating on a different computer, handoff requires both
   a commit and a push so the work is actually available to them
- the Operator decides the default handoff sync mode for each role:
   `commit-only` or `commit-and-push`
- the default may differ by role, but `commit-and-push` is mandatory whenever
   the next owner is on a different computer
- if remote-visible handoff is required, follow the repo's PR/push policy

Default flow when the work changes architecture, system boundaries, data flow,
major dependencies, or overall design direction:

`DM` is required in the flow when documented behavior, operator workflow,
runbooks, shared docs, or durable reader-facing explanations change. `PM` may
mark `DM` not required only when there is no documentation impact.

1. PM
2. AM
3. SM
4. CM
5. OM-Test / OM
6. DM
7. PM
8. Operator

Implementation-to-runtime flow inside an approved architecture:

1. CM
2. SM
3. OM-Test / OM
4. DM
5. PM
6. Operator

Documentation-only flow:

1. PM
2. DM
3. PM
4. Operator

## Message Format

Use this structure for actions requiring a decision or handoff:

```text
DECISION:
RATIONALE:
ACTION NEEDED:
```

Optional sections when needed: RISK, BLOCKER, DEADLINE.

## Completion Handoff Contract

All minions must close work with a clear handoff packet on the active packet
surface. Default: `minions/mail/`. During staged rollout, `PM` may allow an
already-open legacy chat packet to close where it started.

Required structure (in this exact order):

1. `DECISION:` what is now true
2. `RATIONALE:` why this is the right state
3. `SCOPE COMPLETED:` what was done
4. `OUT OF SCOPE:` what was not done
5. `EVIDENCE:` files, commands, runtime outputs, timestamps as applicable
6. `BLOCKERS/RISKS:` anything that could stop the next step
7. `ACTION NEEDED:` explicit next steps with owner labels
8. `NEXT OWNER:` exactly one of PM, AM, CM, SM, DM, OM-Test, OM, RM, Operator
9. `READY CHECK:` pass/fail statement for handoff readiness

Hard rules:

- No minion may mark work complete without naming the `NEXT OWNER`.
- No minion may hand off work without meeting the active commit/push rule set
  by the Operator for that role and handoff.
- No minion may accept handoff with ambiguous ownership.
- If blocked, handoff is still required with a blocker packet and explicit owner for unblock.
- PM must reject handoffs that do not include evidence and clear next-owner assignment.

## Definition of "Onboarded"

This project is considered fully onboarded when all are true:

- operator onboarding checklist status is approved
- project-specific MEMORY sections are complete
- first milestone plan is active
- mailbox packets are being used for new actionable work
- Codex custom-agent and Claude Code subagent usage is accepted or intentionally disabled by the Operator
- PM daily summary thread is being used for same-day durable recap
- rollback posture expectations are explicitly documented
