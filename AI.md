# AI Collaboration Notes

Purpose: provide a shared working agreement for AI assistants operating in this
repo, especially Copilot, Codex, and Claude.

This file is not a replacement for `MEMORY.md`, role charters, plans, or
mailbox packets. It is the cross-tool protocol: how AI assistants should switch
work cleanly, preserve context, and avoid treating private chat history as
project truth.

## Source Of Truth

When Codex and Claude collaborate, repo-native artifacts win over tool-native
memory.

Use these surfaces in this order:

1. `MEMORY.md` for shared project truth, guardrails, and workflow rules.
2. `minions/roles/*.md` for role-specific behavior.
3. `minions/mail/` for actionable handoff packets, responses, and verdicts.
4. `minions/plans/` for milestone scope, acceptance criteria, and gates.
5. `minions/chat/` for PM-owned continuity summaries.
6. `CHANGELOG.md`, `TODO.md`, and `ROADMAP.md` for durable project state.
7. `.github/agents/`, `.codex/agents/`, and `.claude/agents/` for
  tool-specific launch config only.

`feedback.md` sits outside this ranking: read it at session start for Operator
working-style context (it is shared across all tools), but it is a capture log,
not a source of truth — `MEMORY.md` outranks it. Promote durable items out of
`feedback.md` into the curated surfaces above rather than treating the log as
authoritative.

Do not treat a Codex thread, Claude chat, subagent final message, or hidden tool
memory as authoritative unless the useful result has been written into one of
the repo surfaces above.

### Reading Truth in a Multi-Branch World

The repo uses a mainline (`main`, mirrored to `dev`/`staging`) plus short-lived
feature branches. This affects which copy of a file is authoritative:

**Class A — mainline-authoritative files:** `MEMORY.md`, `AI.md`, `CLAUDE.md`,
`AGENTS.md`, `minions/roles/*`, `ROADMAP.md`, `TODO.md`, `minions/chat/`.
These are authoritative ONLY on the mainline. A copy seen on a feature branch
may be stale — merge `dev` in to refresh before relying on them.

**Class B — branch-authoritative files:** implementation code, plans, mail
packets, changelogs, and other work product live on the branch that owns the
work and are authoritative there until promoted via the `staging→main` review
gate.

See `docs/branching-and-release-model.md` for the full branching model and
promotion rules.

## Cross-Tool Handoff

Before switching from one AI tool to another:

1. Capture the useful state in the repo.
2. Name the next owner.
3. Include evidence, not just conclusions.
4. State whether files were changed, tests were run, and risks remain.
5. Commit when the active handoff rules require it.

Good handoff prompt:

```text
Read AI.md, MEMORY.md, and the active packet in minions/mail/. Continue from
repo truth only. Review the prior tool's conclusions as input, not authority.
```

If the prior tool only discussed an idea but did not write it down, treat that
idea as a draft. Re-read the repo and reconstruct the claim from evidence.

## Role Agents

Codex and Claude both expose the same project-local minion roles:

- `pm`
- `am`
- `cm`
- `sm`
- `dm`
- `om`
- `rm`

These are launcher names only; the role set is defined in MEMORY.md's
Collaboration Model roster (the single `om` launcher serves both `OM` and
`OM-Test`).

Use one role for focused thinking when the Operator wants a specific lens.
Use multiple role agents when parallel review is likely to improve the decision.

**Autonomous orchestration posture:** keep the workflow moving — spawn role
agents/subagents, advance pipeline stages, and fire independent second opinions
WITHOUT asking permission first. Three hard-stops require interrupting the
Operator: (1) merge to `main` (the `staging→main` promotion; done via a pull
request on the project's VCS host with Operator approval); (2) destructive or
production-affecting actions without rollback posture; (3) unresolved AI
disagreement that evidence and role ownership cannot settle (see Disagreement
Protocol below). Scope expansion is NOT a hard-stop — flag it explicitly and
proceed with the smallest change. All other safety guardrails are retained.

Subagent output is packet input, not a durable packet by itself. Under
Single-Writer Durability (MEMORY.md, Communication Model), a spawned minion
returns its packet up the spawn chain and the top of the chain — whichever
tool's orchestrator that is — performs the durable write with `WRITTEN-BY:`
attribution. The same law binds a Codex, Copilot, or Claude orchestrator:
one writer per packet, checkpoint commits at stage boundaries, and the
return-only posture for everything spawned.

An optional memory recall layer may exist (`docs/memory-recall-model.md`).
Recall output is input, not authority — the same rule that binds subagent
output. The documented REST fallback keeps non-Claude orchestrators
capable, and absence of the layer never blocks any workflow.

## Disagreement Protocol

Codex and Claude may disagree. Resolve disagreements by evidence and role
ownership, not by model preference.

Use this order:

1. Identify the exact claim in dispute.
2. Find repo evidence, runtime evidence, or source evidence.
3. Apply the relevant role charter.
4. Route unresolved tradeoffs to `PM`.
5. Route architecture uncertainty to `AM`.
6. Route security uncertainty to `SM`.
7. Route implementation uncertainty to `CM`.
8. Route runtime uncertainty to `OM-Test` / `OM`.
9. Route documentation truth gaps to `DM`.
10. Route unknowns needing external research or option analysis to `RM`.
11. Route final unresolved decisions to the Operator.

If evidence is incomplete, say so directly and assign the next owner for
verification.

## Tool Selection

It is acceptable for the Operator to choose a tool by strength. The examples
below are starting heuristics, not ownership rules:

- Codex is often useful for repo-native implementation, local verification,
  commits, and Codex custom-agent workflows.
- Claude is often useful for alternate reasoning, critique, writing passes, and
  Claude Code subagent workflows.
- Either tool may be used for any role-focused discussion or task when the repo
  truth is clear and the Operator chooses that tool.

No tool gets permanent ownership because of prior chat context. Ownership comes
from the minion role model and the current repo artifacts.

## Do Not

- Do not summarize private chat as fact without repo evidence.
- Do not skip `MEMORY.md` and the relevant role charter.
- Do not let `.github/agents/`, `.codex/agents/`, or `.claude/agents/` drift
  from `minions/roles/`.
- Do not use `AI.md` as a long-running task log; use `minions/mail/`,
  `minions/plans/`, or `minions/chat/`.
- Do not preserve local tool runtime state such as `.remember/`, logs, cache
  files, PID files, or `.DS_Store` in commits.

## Compact Handoff Template

```text
TOOL HANDOFF:
FROM:
TO:
ROLE / POSTURE:
REPO STATE:
FILES CHANGED:
EVIDENCE:
RISKS / GAPS:
NEXT OWNER:
OPERATOR ACTION NEEDED:
```
