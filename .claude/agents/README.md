# Claude Code Agents

This directory defines repo-scoped Claude Code subagents for the minion
workflow. They are the Claude projection of the same roles defined for Codex in
`.codex/agents/`.

Each agent is a thin Claude Code launcher around the durable role charter in
`minions/roles/`. Keep role policy in the role files; keep these agent files
limited to Claude-specific spawning posture and pointers to the source charter.

## Agents

| Agent | Role charter | Model | Purpose |
| --- | --- | --- | --- |
| `pm` | `minions/roles/PM.md` | opus | planning, gates, review structure, and operator-facing decisions |
| `am` | `minions/roles/AM.md` | opus | architecture direction, system design, and structural fitness |
| `cm` | `minions/roles/CM.md` | opus · `effort: xhigh` | implementation quality, technical validation, and engineering findings |
| `sm` | `minions/roles/SM.md` | opus | security review, risk framing, and hardening acceptance criteria |
| `dm` | `minions/roles/DM.md` | sonnet | documentation truth, reader paths, runbooks, and doc-sync validation |
| `om` | `minions/roles/OM.md` | opus | OM-Test / OM runtime validation, deploy posture, rollback, and health |
| `rm` | `minions/roles/RM.md` | opus | in-depth research, vendor-doc-grounded option analysis, out-of-box next steps |

These seven map one-to-one to the Codex agents in `.codex/agents/`. There is no
`mm` or `pr` agent: MM (minion design/maintenance) is interactive Operator work
that belongs in the main thread, not a fire-and-return subagent; PR review is
covered by Claude Code's built-in `/review`.

## Design Notes

- **No tool restrictions, with one exception.** Every agent has full tool access
  by Operator decision; lane discipline lives in the role charter prose
  (`minions/roles/*.md`) and the completion handoff contract, not in a tool
  whitelist — the same advisory model Codex and Copilot use. The sole exception
  is `rm`, pinned to a read-only + web + research-skill whitelist
  (`Read, Grep, Glob, WebSearch, WebFetch, Skill(deep-research)`) because it is
  research-and-recommend only and must not create or execute code. The skill is
  scoped (`Skill(deep-research)`, not blanket `Skill`) deliberately: a research
  skill gives RM a fan-out/cited-synthesis engine without reopening the
  code-execution door — blanket `Skill` would let it invoke file-writing skills
  (docx, commit, etc.) and erode the guardrail. Add more research skills the same
  way, one `Skill(name)` each. Do not generalize the whitelist itself to other
  roles.
- **Models mirror Codex reasoning tiers.** Codex `model_reasoning_effort = high`
  maps to `model: opus`; DM's `medium` maps to `model: sonnet`. To run every
  role at full Opus, change DM's `model:` to `opus`. To let a role follow your
  current session model, set `model: inherit`.
- **Effort tuning.** Pin a reasoning-effort level per agent with an `effort:`
  frontmatter field (`low | medium | high | xhigh | max`); it overrides the
  session default whenever that agent is spawned. `cm` is pinned to
  `effort: xhigh` — the documented sweet spot for coding/agentic work — so it
  reasons deeper on implementation and debugging. Other roles use the session
  default. Prefer `xhigh` over `max` (max tends to overthink for diminishing
  returns and may not persist reliably). Note: `ultrathink` is a per-*turn*
  prompt keyword, not a subagent setting; the `effort:` field is the persistent
  equivalent. The field takes effect on a fresh session — verify your Claude
  Code version accepts it.
- **Thin launchers only.** Each agent's body is a "read these first" preamble
  plus a lane reminder. Durable behavior changes go in `minions/roles/`, never
  here.

## Usage

A Claude Code subagent runs in its own isolated context, does bounded work, and
returns a single final message. That return is the packet — treat it like any
other minion handoff. Autonomous orchestration posture applies: spawn role
agents, advance pipeline stages, and fire second opinions without asking
permission, except at the three hard-stops defined in `AI.md`.

The Operator has three practical patterns.

### Focus One Role

Adopt one minion's posture in the current thread, without spawning a subagent,
when you want to think through a problem from one lens before creating a packet.

```text
Use the am posture and challenge this design. Stay in the architecture lane and
give me the tradeoffs before CM implements anything.
```

```text
Talk to me as sm. Is this reachable risk or just theoretical concern?
```

### Spawn One Role Agent

Delegate bounded investigation or review to one role with its own clean context.

```text
Use the cm subagent to investigate this failing test. Do not edit files yet.
Return root cause, evidence, likely fix, and next owner.
```

```text
Use the dm subagent to review the README and docs for drift against the current
repo. Return documentation findings and exact files that need updates.
```

### Spawn Multiple Role Agents

Get several minion lenses on the same problem in parallel, then consolidate.
Claude Code can run these concurrently; ask it to wait for all of them before
synthesizing.

```text
Use the pm, am, and sm subagents to review this milestone plan. Run them in
parallel, wait for all three, then consolidate findings, conflicts, and next
owners.
```

```text
Use the cm subagent to investigate this failing test and the sm subagent to
review the security impact. Wait for both and summarize the evidence before
making any changes.
```

This pattern is best for plan reviews, design challenges, risk review, bug
triage, release gates, and pre-deploy checks. It costs more tokens than a
single-agent run, so use it when role separation is likely to improve the
decision.

## Handoff Discipline

Subagent discussion is not the same as durable handoff. When a role
conversation produces actionable work, move it into the normal minion surfaces:

- use `minions/mail/` for request, response, and verdict packets
- use `minions/plans/` for formal milestone scope and gates
- use `minions/chat/` for PM-owned continuity summaries
- update `MEMORY.md`, `TODO.md`, `ROADMAP.md`, or `CHANGELOG.md` when shared
  truth changes

For implementation or operational changes, be explicit in the spawn prompt about
whether the agent may edit files, deploy, or restart — or only review and report.

## Pipeline Track (`/ship`)

There are two ways to drive these agents:

- **Deliberate track** — the Operator or PM explicitly spawns one or more roles
  (the patterns above). Each handoff is a `minions/mail/` packet. Use it for
  planning, design challenges, security review, release gates, and any
  cross-session work.
- **Execution track** — the `/ship` slash command (`.claude/commands/ship.md`)
  has PM orchestrate a single feature end to end: `am` plans, `cm` implements
  under an implement-only posture, a fresh `cm` tests under a test-only posture
  (it does not fix failures), `sm` reviews when there is a security surface, and
  a fresh read-only `cm` returns a SHIP / NEEDS WORK / BLOCK verdict.

In the execution track, intermediate stage results use the **direct-return
channel** — each spawned agent returns to PM's context rather than opening a
mail packet. PM consolidates one durable artifact at the end. The posture
constraints live in the `/ship` spawn prompts, not in these launcher files, so
the agents stay general-purpose. See the Pipeline Mode section of
`docs/minion-prompt-modes.md` for the full stage map, the two-channel model, the
gates, and the planned Phase 2 cost-tier stage agents (`coder`, `tester`).

## Prompt Modes and MM

- Named prompt modes (`/challenge`, `/tech-lead`, `/debug`, ...) are defined in
  `docs/minion-prompt-modes.md`. The first one projected into Claude Code as a
  `.claude/commands/*.md` slash command is `/ship` (pipeline mode); the rest can
  follow the same pattern as needed.
- MM (minion design and maintenance) is interactive Operator work. When built
  for Claude Code it belongs in the main thread as a skill or command (for
  example `/spec-minion`), not as a subagent here.

## Loading Changes

Claude Code discovers agents in `.claude/agents/` at session start. After adding
or editing an agent file, start a new session (or reload) before the change is
reflected. Use `/agents` to inspect and manage discovered subagents.

## Worktree Hygiene

A worktree-isolated subagent (or `/delegate`) leaves its git worktree behind
after its branch lands — Claude Code's harness only auto-removes worktrees whose
branch was never touched, so the ones that *did* work accumulate. After the
branch merges (or you discard it), prune the leftover: `git worktree list` to see
them, then `git worktree remove <path>` (or `git worktree prune` to sweep stale
entries). Cross-vendor delegate worktrees live under `.xtool-worktrees/`; see
`docs/cross-tool-orchestration.md`.
