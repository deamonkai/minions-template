# Start Here (Codex)

Codex reads this file before doing work and rebuilds project instructions at the
start of each run or session. It is a thin pointer to durable truth, not a place
for role policy or project state.

Before substantive work, read in this order:

1. `AI.md` — cross-tool protocol for coordinating with Claude and other AI
   assistants (source-of-truth order, handoff discipline, disagreement routing).
2. `MEMORY.md` — shared project truth, guardrails, and workflow rules.
3. `feedback.md` — Operator corrections, preferences, and working-style learnings
   captured across sessions (if present).
4. The relevant `minions/roles/*.md` charter for the active role.
5. `minions/capabilities.md` — what capabilities exist in this environment.
6. `minions/smes/README.md` and `minions/review-matrix.md` — which SMEs
   exist here and how reviews route (both may be empty starters; absence
   of content is normal).

Operating rules:

- Repo artifacts win over tool-native memory. Do not treat this thread, a
  subagent's final message, or hidden tool memory as authoritative until the
  useful result is written into a repo surface (`minions/mail/`,
  `minions/plans/`, `minions/chat/`, `MEMORY.md`, `CHANGELOG.md`, etc.).
- Role minions are available as custom agents in `.codex/agents/` (`pm`, `am`,
  `cm`, `sm`, `dm`, `om`, `rm`). Autonomous orchestration posture: spawn them,
  advance pipeline stages, and fire second opinions without asking permission —
  unless hitting a hard-stop (merge/push to `main`; destructive/production
  action without rollback; unresolved AI disagreement). See `.codex/agents/README.md` and `AI.md`.
- Keep durable role policy in `minions/roles/`, never in this file.

When handing off to or from Claude, follow the handoff steps and the compact
handoff template in `AI.md`.
