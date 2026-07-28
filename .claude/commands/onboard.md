---
description: Deterministically onboard the orchestrator at session start — execute the CLAUDE.md read-chain to completion, read the code map (docs/MECHANICS.md) and flag its staleness, check minions/handoffs/ for a pending snapshot (absorb, hold the delete), surface MINION_* gates, and emit a ready-state report. Read-only.
---

Onboard the session orchestrator for: $ARGUMENTS

Follow the **Onboarding Mode** section of `docs/minion-prompt-modes.md` exactly.
`$ARGUMENTS` may name the seat to adopt (default: the session orchestrator / PM
seat). This command is READ-ONLY — it reads and reports, it mutates nothing
(no commits, no writes, no handoff deletion). Emit the ready-state report as
the final step; onboarding is not complete until it is emitted.
