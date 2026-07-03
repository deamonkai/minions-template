# Session Handoffs (`minions/handoffs/`)

This directory is the **ephemeral session-snapshot surface**. A handoff
snapshot lets a fresh session (or the post-compaction context) resume a
dying session's work without needing anything from the dead conversation.
Written by `/handoff` (Claude) or Handoff Mode in
`docs/minion-prompt-modes.md` (Codex/Copilot — identical protocol).

## Lifecycle

1. **Write** — the ending session's orchestrator (the single writer) first
   FLUSHES every durability obligation (persist `SOLE-HOLDER:` facts, commit
   in-flight deliverables, batch `DURABLE LESSONS:`, note running background
   work), then writes one snapshot here and commits it on the **active
   branch** (Class B).
2. **Ride the branch** — the snapshot travels with the work it describes;
   it merges nowhere on its own and promotes nothing.
3. **Pickup** — a resuming session reads the snapshot.
4. **Verify** — the resumer checks the snapshot's claims against repo truth
   before relying on them. Files win; runtime claims (gate readings, service
   state) are presumptive until re-verified.
5. **Delete + receipt** — after resuming, the resumer DELETES the snapshot
   and commits the deletion. The deletion commit is the consumption receipt.

## Naming

```
<YYYY-MM-DD-HHMM>-<topic>.md
```

One live snapshot per seat/topic: a new `/handoff` for the same seat/topic
deletes the prior unconsumed snapshot in the same commit (supersede rule).

## Ephemeral courier, not truth

Snapshots are **temporary couriers**. The flush guarantees nothing durable
lives only in a snapshot — it is a pointer map plus resume narrative. On any
conflict between a snapshot and a repo surface, the repo surface governs
(files win); the snapshot is still deleted after extracting anything useful,
and contradictions worth keeping go to `feedback.md`, never back into a
handoff. Snapshots never contain secrets, credentials-adjacent values, or
personal data; `SOLE-HOLDER:` facts appear only as references to their
persisted location.

## Staleness sweep

An unconsumed snapshot older than the work it describes is dead weight: DM
deletes it at the next gate's doc-sync pass.

## Absence is normal

Most sessions end at natural completion and write no handoff. An empty
directory means nothing is in flight — not that something is missing.
