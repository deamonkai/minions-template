# Codex Agents

This directory defines repo-scoped Codex custom agents for the minion workflow.

Each agent is a thin Codex launcher around the durable role charter in
`minions/roles/`. Keep role policy in the role files; keep these TOML files
limited to Codex-specific spawning posture and pointers to the source charter.

## Agents

| Agent | Role charter | Reasoning effort | Purpose |
| --- | --- | --- | --- |
| `pm` | `minions/roles/PM.md` | `medium` | planning, gates, review structure, and operator-facing decisions |
| `am` | `minions/roles/AM.md` | `high` | architecture direction, system design, and structural fitness |
| `cm` | `minions/roles/CM.md` | `high` | implementation quality, technical validation, and engineering findings |
| `sm` | `minions/roles/SM.md` | `high` | security review, risk framing, and hardening acceptance criteria |
| `dm` | `minions/roles/DM.md` | `medium` | documentation truth, reader paths, runbooks, and doc-sync validation |
| `om` | `minions/roles/OM.md` | `high` | OM-Test / OM runtime validation, deploy posture, rollback, and health |
| `rm` | `minions/roles/RM.md` | `high` | in-depth research, vendor-doc-grounded option analysis, out-of-box next steps |

## Pipeline Stage Launchers

`coder` and `tester` (`coder.toml`, `tester.toml`) are a separate launcher class
from the seven roles above: Mid-tier CM-lane stage launchers for bounded,
spec-driven implementation (`coder`, implement-only) and test authoring
(`tester`, test-only). Both point at the CM charter (`minions/roles/CM.md`); the
posture travels in the spawn prompt, not the launcher body. They are tracked
separately and intentionally kept out of the seven-role `## Agents` table.

They mirror the Claude Code pipeline stage launchers for cross-family parity,
but the Mid tier is **advisory here**: Codex has no per-launcher `model:`
selector (only `model_reasoning_effort`), and there is no `/ship` command in this
family to prefer them over `cm` or fall back automatically. Spawn them manually
and state the implement-only / test-only posture in your prompt. See
`.claude/agents/README.md` (Pipeline Stage Launchers) and `docs/model-tiering.md`.

## Model And Effort Policy

The Codex agents intentionally do not pin `model`. They inherit the active Codex
model for the session, while each role sets its own `model_reasoning_effort`.

Recommended baseline:

- general project chat / router: `GPT-5.5` with `medium` reasoning
- `pm`: `medium`, because planning and routing should be capable without
  running hotter than needed
- `am`, `cm`, `sm`, `om`, and `rm`: `high`, because architecture, implementation,
  security, runtime, and in-depth research work usually need deeper reasoning
- `dm`: `medium`, because documentation truth and reader-path work should be
  careful but usually does not need the deepest reasoning tier

`rm` (Research Manager) is research-and-recommend only and may not create or
execute code. On the Claude projection this is enforced by a read-only + web
tool whitelist; Codex role TOMLs have no tool-restriction field, so RM's
prohibition is carried in its `developer_instructions` prose.

Pin a `model` in a role TOML only when a downstream project needs a hard
cost/performance lane. Otherwise, tune the main session model and let these
role efforts shape the spawned agents.

## Usage

Autonomous orchestration posture applies: spawn role agents, advance pipeline
stages, and fire second opinions without asking permission, except at the three
hard-stops defined in `AI.md`. Vendoring external skill code into
`skills/vendored/` without Operator approval (the optional `MINION_SKILLS`
layer, `docs/skill-adoption-model.md`) is an instance of hard-stop #2
(irreversible-publish), not a new fourth hard-stop — the enumerated count is
unchanged. The Operator should choose between three practical patterns:

1. Focus one role in the current conversation.
2. Spawn one role agent for bounded work.
3. Spawn several role agents for parallel review, then consolidate.

### Focus One Role

Use this when the Operator wants to think through a problem from one minion's
perspective without creating a formal packet yet.

```text
Use the am posture and challenge this design. Stay in the architecture lane and
give me the tradeoffs before CM implements anything.
```

```text
Talk to me as sm. Is this reachable risk or just theoretical concern?
```

This pattern keeps the discussion lightweight. If the conversation produces a
decision, gate, or action for another role, capture it in `minions/mail/` or the
active plan before handing off.

### Spawn One Role Agent

Use this when the Operator wants one role to investigate or review with its own
bounded context.

```text
Spawn cm to investigate this failing test. Do not edit files yet. Return root
cause, evidence, likely fix, and next owner.
```

```text
Spawn dm to review the README and docs for drift against the current repo.
Return documentation findings and exact files that need updates.
```

Use one role agent when the work is mostly independent and the Operator wants a
clean role-specific answer without mixing it into the main thread.

### Spawn Multiple Role Agents

Use this when the Operator wants different minion lenses on the same problem.
Ask Codex to wait for all agents before consolidating.

```text
Spawn the pm, am, and sm agents to review this milestone plan. Wait for all
three, then consolidate findings, conflicts, and next owners.
```

```text
Spawn cm to investigate this failing test and sm to review the security impact.
Wait for both and summarize the evidence before making changes.
```

This pattern is best for plan reviews, design challenges, risk review, bug
triage, release gates, and pre-deploy checks. It costs more tokens than a
single-agent run, so use it when the role separation is likely to improve the
decision.

## Operator Prompt Patterns

Useful prompts:

```text
Spawn am to review whether this proposed feature changes architecture,
boundaries, data flow, or dependencies. Return findings-first with evidence.
```

```text
Spawn pm to turn this messy request into scope, acceptance criteria, open
questions, and next owner. Do not assign implementation until blockers are
clear.
```

```text
Spawn sm to review this change for secrets, auth, unsafe controls, and reachable
exploitability. Return severity, evidence, and acceptance criteria.
```

```text
Spawn om to review deploy and rollback posture for this change. Do not restart
or deploy anything; report runtime checks and missing evidence.
```

```text
Spawn pm, am, cm, sm, dm, and om to review this release candidate. Wait for all
agents, then consolidate blockers, risks, accepted progress, and next owner.
```

## Handoff Discipline

Agent discussion is not the same as durable handoff.

When a role conversation creates actionable work, the Operator or PM should
move it into the normal minion surfaces:

- use `minions/mail/` for request, response, and verdict packets
- use `minions/plans/` for formal milestone scope and gates
- use `minions/chat/` for PM-owned continuity summaries
- update `MEMORY.md`, `TODO.md`, `ROADMAP.md`, or `CHANGELOG.md` when shared
  truth changes

For implementation or operational changes, be explicit about whether the agent
is allowed to edit files, deploy, restart, or only review and report.

## Loading Changes

Codex may need a new thread or app/session refresh before newly added or edited
project agents appear as spawnable agents.
