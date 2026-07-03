# Minion Template

This repository is a source template for running coordinated AI assistant roles
(minions) with durable markdown-based collaboration in git.

It provides a baseline operating model for:

- PM (planning and gate ownership)
- AM (architecture and system design stewardship)
- CM (implementation and technical validation)
- SM (security review and risk framing)
- DM (documentation truth, reader paths, and doc-sync validation)
- OM-Test / OM (runtime and operational validation)
- RM (in-depth research, vendor-doc-grounded options, out-of-box next steps; recommends only)

Copilot users can run these roles from [.github/agents](.github/agents),
Codex users from [.codex/agents](.codex/agents), and Claude Code users from
[.claude/agents](.claude/agents). All are thin launchers around the durable
role charters in [minions/roles](minions/roles).

## Using Copilot, Codex, or Claude Minion Agents

Operators can use the role agents in three ways, in either tool:

1. Ask the current thread to adopt one role posture for discussion, such as
   `Use the am posture and challenge this design`.
2. Spawn one role agent for bounded investigation or review, such as
   `Use the cm subagent to investigate this failing test. Do not edit files yet`.
3. Spawn several role agents for parallel review, such as
   `Use the pm, am, and sm subagents to review this plan. Wait for all three,
   then consolidate findings`.

Use role-agent discussion for focused thinking. Use `minions/mail/`,
`minions/plans/`, and `minions/chat/` when the result needs durable handoff,
gate evidence, or same-day continuity. See
[.github/agents/README.md](.github/agents/README.md),
[.codex/agents/README.md](.codex/agents/README.md), and
[.claude/agents/README.md](.claude/agents/README.md) for practical Operator
prompt patterns in each tool.

## Important Template Note

This README is template-scaffolding guidance.

When this template is used to create a downstream project, this file should not
be copied forward as-is. Downstream repositories should replace it with a
project-specific README to avoid role/process confusion.

## Repository Purpose

This template exists to make multi-agent coordination explicit, durable, and
reviewable by combining:

- shared memory and guardrails
- role-specific context files
- formal planning artifacts
- mailbox packet history
- PM-owned continuity summaries
- explicit handoff and evidence discipline

## Basic Onboarding

Use this sequence immediately after creating a downstream project from this
template:

1. Establish a filtered vendored template snapshot and perform the first
   controlled export using
   [docs/downstream-onboarding-playbook.md](docs/downstream-onboarding-playbook.md).
2. Complete [docs/operator-onboarding-checklist.md](docs/operator-onboarding-checklist.md)
   with the Operator.
3. Finalize project-specific sections in [MEMORY.md](MEMORY.md).
4. Open the first milestone plan from [minions/plans](minions/plans).
5. Bootstrap mailbox coordination using
  [.github/agents/README.md](.github/agents/README.md) when using Copilot
  custom agents, [.codex/agents/README.md](.codex/agents/README.md) when
  using Codex custom agents, or
  [.claude/agents/README.md](.claude/agents/README.md) when using Claude Code
  subagents,
   [docs/project/mailbox-collaboration-model.md](docs/project/mailbox-collaboration-model.md)
   and [minions/mail](minions/mail); use `minions/mail/` for new actionable
   packets and `minions/chat/` for PM summaries.
6. Initialize and maintain `ROADMAP.md`, `TODO.md`, and `CHANGELOG.md`.
7. Use [docs/downstream-upgrade-playbook.md](docs/downstream-upgrade-playbook.md)
   for later template updates.

## Core Files

- [INIT.md](INIT.md): startup framing and handoff expectations
- [feedback.md](feedback.md): Operator feedback capture log (read at session
  start; promote durable items into `MEMORY.md`)
- [AI.md](AI.md): cross-tool coordination notes for Codex, Claude, and other AI
  assistants
- [CLAUDE.md](CLAUDE.md): Claude Code auto-loaded entry point (thin pointer to
  `AI.md` and `MEMORY.md`)
- [AGENTS.md](AGENTS.md): Codex auto-loaded entry point (thin pointer to `AI.md`
  and `MEMORY.md`)
- [.github/copilot-instructions.md](.github/copilot-instructions.md): Copilot
  auto-loaded entry point (thin pointer to `AI.md` and `MEMORY.md`)
- [MEMORY.md](MEMORY.md): shared truth and baseline guardrails
- [minion-version.md](minion-version.md): template/downstream versioning format
- [docs/collaboration-playbook.md](docs/collaboration-playbook.md): high-level
  operating pattern
- [docs/minion-prompt-modes.md](docs/minion-prompt-modes.md): reusable
  operator prompt modes and advisor-posture shortcuts
- [docs/minion-plugin-pairings.md](docs/minion-plugin-pairings.md): recommended
  (conditional) minion-to-plugin/connector/skill pairings
- [docs/project/mailbox-collaboration-model.md](docs/project/mailbox-collaboration-model.md):
  mailbox-first communication model
- [docs/downstream-onboarding-playbook.md](docs/downstream-onboarding-playbook.md):
  PM-owned initial downstream export workflow
- [docs/downstream-upgrade-playbook.md](docs/downstream-upgrade-playbook.md):
  PM-owned downstream upgrade workflow
- [docs/export-manifest.md](docs/export-manifest.md): per-file export and merge
  strategy
- [.codex/agents](.codex/agents): Codex custom agent definitions for the
  minion roles
- [.claude/agents](.claude/agents): Claude Code subagent definitions for the
  minion roles
- [.github/agents](.github/agents): Copilot custom agent definitions for the
  minion roles
- [minions/roles](minions/roles): role charters
- [minions/plans](minions/plans): formal planning artifacts
- [minions/mail](minions/mail): mailbox packet coordination
- [minions/chat](minions/chat): PM-owned continuity summaries

## Guardrail Reminder

Minions may keep role context in their role files under
[minions/roles](minions/roles), but no minion may alter existing base
guardrails/rules without explicit Operator approval.

## About This Copy

This is the public export of the minions-template, published from the
maintainer's canonical repository at template version `1.26.0-1.0.0`
(shallow publish history; the canonical repo retains full development
history and its maintainer-local context). A few files intentionally
diverge from the canonical copy for privacy: `MEMORY.md`, `INIT.md`, and
`CHANGELOG.md` generalize Operator-specific phrasing, and `feedback.md` is
reset to a clean capture-log stub.
