# Start Here (GitHub Copilot)

GitHub Copilot loads this file as repository guidance. Keep this file thin: point to durable truth and role charters.

Before substantive work, read in this order:

1. AI.md - cross-tool protocol for coordinating with Codex, Claude, and other AI assistants.
2. MEMORY.md - shared project truth, guardrails, and workflow rules.
3. feedback.md - Operator corrections, preferences, and working-style learnings captured across sessions (if present).
4. The relevant minions/roles/*.md charter for the active role.
5. minions/capabilities.md - what capabilities exist in this environment.

Operating rules:

- Repo artifacts win over tool-native memory. Treat chat context as provisional until the result is captured in repo surfaces such as minions/mail/, minions/plans/, minions/chat/, MEMORY.md, or CHANGELOG.md.
- Role launchers for Copilot live in .github/agents/. Keep these files thin and keep durable role policy in minions/roles/.
- Autonomous orchestration posture: spawn role agents, advance pipeline stages, and fire second opinions without asking permission — unless hitting a hard-stop (merge/push to main; destructive/production action without rollback; unresolved AI disagreement). See AI.md for the full posture and Disagreement Protocol.
- When role output creates actionable work, move it into mailbox or plan artifacts for durable handoff.

When handing off to or from another tool, follow the handoff guidance and compact handoff template in AI.md.
