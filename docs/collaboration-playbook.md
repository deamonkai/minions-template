# Collaboration Playbook

This is the high-level operating pattern behind the minion workflow.

## Core Idea

Keep the repo as the durable source of coordination truth.

- mail is for actionable request/response/verdict packets
- chat is for PM summaries, continuity, and operator-facing recap
- plans are for formal scope and gates
- role files define responsibilities
- prompt modes sharpen role posture without changing ownership
- Copilot custom agents in `.github/agents/`, Codex custom agents in
  `.codex/agents/`, and Claude Code subagents in `.claude/agents/` let the
  Operator spawn minion roles explicitly while keeping `minions/roles/` as the
  policy source of truth
- documentation truth has an explicit owner through `DM`
- runtime truth is validated separately from commit history
- handoffs must be commit-backed; push is required whenever the next owner is on a different computer

## Prompt Modes

Use `docs/minion-prompt-modes.md` when the Operator asks for a named shortcut
such as `/debug`, `/security`, `/devops`, `/performance`, `/refactor`,
`/frontend`, `/docs`, `/runbook`, `/brief`, `/challenge`, or `/scout`.

Prompt modes define posture and expected output. They do not override role
boundaries, handoff order, evidence requirements, or approval requirements.

## Copilot, Codex, and Claude Custom Agents

Use `.github/agents/` (Copilot), `.codex/agents/` (Codex), or
`.claude/agents/` (Claude Code) when the Operator wants role agents that map
directly to minion roles. The agent files should remain thin launchers that
point to `MEMORY.md` and the relevant `minions/roles/*.md` charter.

By default, tools should keep workflows moving — spawn role agents, advance
pipeline stages, and fire independent second opinions without waiting for
permission. Hard-stops (merge/push to `main`, destructive production-affecting
actions without rollback, unresolved AI disagreement) still require Operator
approval. See AI.md "Role Agents" for the authoritative autonomous-orchestration
posture. Example invocation:

```text
Spawn the pm, am, and sm agents to review this plan. Wait for all three, then
consolidate findings, conflicts, and next owners.
```

Use `minions/roles/` for durable role policy, `docs/minion-prompt-modes.md` for
named postures, and `.github/agents/`, `.codex/agents/`, or `.claude/agents/`
only for custom-agent launch config. See `.github/agents/README.md`,
`.codex/agents/README.md`, and `.claude/agents/README.md` for tool-specific
Operator prompt patterns. See `docs/model-tiering.md` for advisory guidance on
which model capability tier to run a given role or activity at when spawning
these agents.

`RM` (Research Manager) is a consult role: spawn it when an issue needs in-depth,
vendor-documentation-grounded research and option analysis. RM returns ranked
options and a recommended next step; it recommends only and may not create or
execute code. Route any resulting implementation to `CM`.

## Mailbox-First Coordination

Use a mailbox-style packet model for primary minion communication.

- `minions/mail/` is the primary coordination surface
- one packet thread gets one packet directory
- one owned message gets one owned file
- sender writes `request.md`
- recipient writes `response.md`
- gate owner writes `verdict.md` when needed
- `PM` mirrors outcomes into same-day chat summary
- `PM` or `DM` updates shared state docs based on ownership

`minions/chat/` is still durable, but it is no longer the default multi-writer
request/response surface.

See `docs/project/mailbox-collaboration-model.md` for the full operating model.

Rollout posture:

- existing in-flight legacy chat packets may finish where they started
- all new follow-up packets should open in `minions/mail/`
- `PM` should leave transition notes in legacy packets during staged rollout

## Recommended Lifecycle

1. `PM` opens a mailbox packet or plan packet
2. `AM` reviews architecture/design when work changes system boundaries, data flow, major dependencies, or overall design direction
3. `SM` reviews architecture foundations and risk posture when the work changes trust boundaries or security exposure
4. `CM` responds with findings or implementation inside the approved architecture
5. `OM-Test` / `OM` verifies deployed/runtime truth when relevant and reports runtime-design mismatches
6. `DM` validates documentation, runbooks, and reader paths when the work changes documented behavior or operating practice
7. `PM` accepts, rejects, or narrows the next step
8. `Operator` reviews live results and raises human concerns

## PM-Owned Onboarding

Before normal execution cadence, `PM` runs onboarding with the Operator and captures decisions in `docs/operator-onboarding-checklist.md`.

Onboarding should explicitly set:

- who fills the `AM` role and how architecture decisions will be captured
- who fills the `DM` role and how documentation truth will be kept current
- the default handoff sync mode for each role: `commit-only` or `commit-and-push`
- where the vendored template snapshot will live (recommended `.minions-template/`)
- who owns downstream template upgrades (default `PM`)
- whether escalation response clocks are enabled for this project
- how `CHANGELOG.md`, `ROADMAP.md`, and `TODO.md` will be maintained
- project-specific guardrail additions beyond template defaults

Onboarding should use `docs/downstream-onboarding-playbook.md`, not a blind
repo copy.

- vendor an export-ready template snapshot into `.minions-template/` with `.git/` and `do-not-export` files excluded
- export the live operating files using `docs/export-manifest.md`
- manually merge `INIT.md`, `MEMORY.md`, `docs/operator-onboarding-checklist.md`, and `minion-version.md`
- commit the vendored snapshot and exported live state together as the initial baseline

## Downstream Upgrades

Use `PM` as the default owner for downstream template upgrades.

- onboarding should establish `.minions-template/` first; upgrades depend on that baseline
- keep the approved export-ready template snapshot in `.minions-template/`
- stage the incoming export-ready template in a temporary path such as `.minions-template.next/`
- compare old template, new template, and live downstream files before changing production minion docs
- use `docs/export-manifest.md` to decide whether each file is replaced, manually merged, or left downstream-owned
- update the downstream base template version only after the live files and vendored snapshot both match the approved upgrade

## Common Failure Modes This Prevents

- code merged but not deployed
- deployed but not actually running
- architecture drifting without an explicit owner
- documentation drifting without an explicit owner
- PM approving commit history instead of runtime truth
- packet discussion being lost or overwritten between sessions
- role boundaries blurring under pressure
