# GitHub Copilot Agents

This directory defines repo-scoped GitHub Copilot role launchers for the minion workflow.

Each file is intentionally thin. Durable policy belongs in MEMORY.md and minions/roles/.

## Core Role Agents

- pm: planning discipline, scope gates, and operator-facing decisions
- am: architecture direction, boundaries, and structural tradeoffs
- cm: implementation quality, debugging, tests, and technical validation
- sm: security review, reachable-risk framing, and hardening criteria
- dm: documentation truth, runbooks, and doc-sync validation
- om: runtime truth, deployment posture, rollback, and operational health
- rm: in-depth research, vendor-doc-grounded option analysis, and out-of-box next steps (recommends only)

## Usage Patterns

Autonomous orchestration posture applies: spawn role agents, advance pipeline
stages, and fire second opinions without asking permission, except at the three
hard-stops defined in `AI.md`. Use the same three patterns as Codex and Claude:

1. Focus one role posture in the current thread.
2. Run one role agent for bounded work.
3. Run multiple role agents for parallel lenses, then consolidate.

Example prompts:

- Use the am agent to challenge this design and return architecture tradeoffs before implementation.
- Use the cm agent to investigate this failing test. Do not edit files yet. Return root cause, evidence, likely fix, and next owner.
- Use the rm agent to research this build blocker with vendor documentation first, then return ranked options, recommendation, and next owner.
- Use the pm, am, and sm agents to review this plan. Consolidate blockers, risks, and next owners.

For a larger copy/paste prompt set by role and workflow, see
[.github/agents/copilot-role-prompts.md](copilot-role-prompts.md).
The same file also includes a role-by-role model selection rubric for when to
stay on Auto versus escalate to higher reasoning.

## Handoff Discipline

Agent discussion is not durable handoff.

When role output creates actionable work, capture it in:

- minions/mail/ for request/response/verdict packets
- minions/plans/ for formal milestone scope and gates
- minions/chat/ for PM continuity summaries
- MEMORY.md or CHANGELOG.md when shared truth changes

Be explicit whether the role is allowed to edit files, run commands, deploy, or only review and report.
