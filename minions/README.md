# Minions Directory

This folder is the durable coordination layer for the minion workflow.

## Layout

```text
minions/
  roles/   # Role-specific charters, including DM documentation ownership
  plans/   # Formal plans and milestone docs
  mail/    # Mailbox packets and handoffs
  chat/    # PM-owned summaries and continuity
```

## Rules

- `MEMORY.md` remains the shared project truth
- `roles/` contains only role-specific deltas
- `docs/minion-prompt-modes.md` defines reusable mode shortcuts that sharpen
  role posture without changing ownership
- `plans/` should be formal and reviewable
- `mail/` is the default coordination surface for actionable packets
- `chat/` should be PM-owned, human-readable, and durable across sessions
