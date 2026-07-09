# Start Here (Claude Code)

Claude Code loads this file automatically at session start. It is a thin
pointer to durable truth, not a place for role policy or project state.

Before substantive work, read in this order:

1. `AI.md` — cross-tool protocol for coordinating with Codex and other AI
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

- Repo artifacts win over tool-native memory. Do not treat this chat, a
  subagent's final message, or hidden tool memory as authoritative until the
  useful result is written into a repo surface (`minions/mail/`,
  `minions/plans/`, `minions/chat/`, `MEMORY.md`, `CHANGELOG.md`, etc.).
- When `MINION_MEMORY=on`, the orchestrator queries the memory recall
  layer at run start and folds hits into dispatch briefs (recall is input,
  not authority; verify runtime facts live). Unset/off, or tools/API
  absent: silent no-op. See `MEMORY.md` (Memory Recall) and
  `docs/memory-recall-model.md`.
- When `MINION_SECONDBRAIN=on`, the orchestrator pulls relevant local
  second-brain vault content at run start and folds it into dispatch briefs
  (recall is input, not authority; verify runtime facts live). Unset/off, or
  the vault absent: silent no-op. See `MEMORY.md` (Second Brain) and
  `docs/second-brain-model.md`.
- When `MINION_SKILLS=on`, adopted external skills (vetted and wrapped through
  the airlock) become reachable as inventoried capabilities, running
  no-network / least-privilege by default. Unset/off, or no skill adopted:
  silent no-op — the airlock and its unconditional guardrails still stand.
  Vendoring external skill code into `skills/vendored/` without Operator
  approval is an instance of hard-stop #2 (irreversible-publish), not a new
  hard-stop. See `MEMORY.md` (Skill Adoption) and `docs/skill-adoption-model.md`.
- Role minions are available as subagents in `.claude/agents/` (`pm`, `am`,
  `cm`, `sm`, `dm`, `om`, `rm`). Autonomous orchestration posture: spawn them,
  advance pipeline stages, and fire second opinions without asking permission —
  unless hitting a hard-stop (merge/push to `main`; destructive/production
  action without rollback; unresolved AI disagreement). See `.claude/agents/README.md` and `AI.md`.
  Multi-step workflows are PM-routed (MEMORY.md, Workflow Ownership).
- Keep durable role policy in `minions/roles/`, never in this file.

When handing off to or from Codex, follow the handoff steps and the compact
handoff template in `AI.md`.
