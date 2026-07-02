# Chat Threads

Use this folder for PM-owned summaries and historical continuity.

This is not the primary role-to-role request/response surface anymore.
Actionable minion communication should default to `minions/mail/`.

## Recommended Files

- `YYYY-MM-DD.md` for PM daily summary notes
- `YYYY-MM-DD-topic-name.md` for PM topic summaries or historical recap

## Required Workflow

- `PM` owns the daily chat thread by default
- when a minion is bootstrapped or a packet closes, `PM` should mirror a short
  same-day summary into the current `YYYY-MM-DD.md`
- all chat-thread changes are commit-by-default to keep the continuity trail
  durable
- default commit message format for chat-thread updates: `chat: YYYY-MM-DD thread update`

## When To Break Out A Topic Thread

Create a dedicated PM topic summary when:

- a mailbox packet series needs a condensed historical recap
- a design or review topic has enough history that a summary helps humans
- bug scrub findings need a clean summary separate from the daily thread
- a deploy / runtime topic needs a durable operator-facing recap

## Summary Format

Daily or topic summaries should usually include:

- current gate
- important packet links
- current next owner
- operator-relevant context

## Required Format For Summary Decisions

```text
DECISION:
RATIONALE:
ACTION NEEDED:
NEXT OWNER:
```

## Important Rule

Use `minions/mail/` for primary handoffs and packet exchanges. Use
`minions/chat/` to summarize them.
