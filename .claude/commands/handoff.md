---
description: Write a durable, self-contained session snapshot — flush all durability obligations first — so a fresh session or post-compaction context resumes cleanly; snapshot is deleted on pickup.
---

Write a session handoff snapshot for: $ARGUMENTS

You are acting as the **session orchestrator** (the packet's single writer —
usually the PM seat). Read `MEMORY.md` (Single-Writer Durability, Git Handoff
Discipline) and the Handoff Mode section of `docs/minion-prompt-modes.md`
before starting. The surface protocol is `minions/handoffs/README.md`.

A handoff snapshot is a **temporary courier, not truth**: it must survive
session death (so it is committed), but the receiving session deletes it on
pickup. Anything durable never lives only in the snapshot — that is what the
flush guarantees. Run the two phases in order; do not snapshot before the
flush completes.

## Phase 1 — FLUSH (discharge every durability obligation)

The flush is what makes deletion safe: after it, the snapshot duplicates no
canonical content — it is a pointer map plus resume narrative. In order:

1. **Persist `SOLE-HOLDER:` facts immediately.** Any fact whose only copy is
   this session's context — rollback anchors, backup/recovery paths,
   checksums, credentials-adjacent state — is written to its canonical home
   NOW, before anything else. The snapshot will only reference these facts by
   their persisted location, never carry them.
2. **Commit every in-flight deliverable** per the durability window (Git
   Handoff Discipline): each returned-but-uncommitted deliverable gets its
   commit now. Exposure never exceeds one in-flight deliverable; a handoff
   with zero is the goal.
3. **Batch pending `DURABLE LESSONS:` to their canonical homes** — role files
   under `minions/roles/`, `feedback.md`, `minions/capabilities.md` — and
   dispose of each item explicitly: apply, or drop with reason.
4. **Note (do not await) running background work.** For each running task,
   record what it is, where its output will land, and how the resumer can
   verify completion. `/handoff` never waits for background work to finish.

## Phase 2 — SNAPSHOT

Write `minions/handoffs/<YYYY-MM-DD-HHMM>-<topic>.md` from the template
below. Self-containment test: a resumer must need **nothing** from this
(dead) conversation. Fill every section; write `none` rather than omitting
one, so absence is a recorded claim rather than an oversight.

```markdown
# Handoff: <topic>

WRITTEN-BY: <seat/role, tool> — <YYYY-MM-DD HH:MM TZ>

## Session Reset
- where we started:
- what has been completed:
- what remains open:
- current priorities:
- in-flight blockers:
- recommended next action:

## Repo State
- branch:
- HEAD: <short hash — subject>
- unpushed commits: <count + short hashes, or none>
- open PRs / gates: <URL + status for each, or none>
- flow position: <where this work sits in feature → dev → staging → main>

## In-Flight Work
- running background tasks: <task, expected output location, how the
  resumer verifies completion — or none>
- unconsumed review findings: <transcribed VERBATIM per the
  verdict-distribution law (MEMORY.md, Execution Quality) — distilled
  verdict, conditions, severities; never "re-read the raw artifact">

## Environment Gates (as last verified — PRESUMPTIVE)
- <MINION_* gate>: <value>, verified <when>, from a fresh tool shell
  (runtime claims age; the resumer re-verifies before relying on them)

## Pointers
- spec:
- plan:
- ledger:
- packets: <minions/mail/ packet dirs in flight>

## Recall Hints (when MINION_MEMORY=on)
- query terms: <memory-layer search terms for this topic — omit section
  when the gate is off>

---
PICKUP FOOTER — instructions to the resuming session:
1. VERIFY this snapshot's claims against repo truth before relying on
   them. Files win; every runtime claim above is presumptive until
   re-verified.
2. Resume the work.
3. DELETE this file and commit the deletion — the deletion commit is the
   pickup receipt.
If repo truth contradicts this snapshot, repo truth governs; extract
anything worth keeping into `feedback.md`, never back into a handoff.
```

## SUPERSEDE rule

A new `/handoff` for the same seat/topic supersedes any prior unconsumed
snapshot: delete the old snapshot **in the same commit** that adds the new
one. At most one live snapshot per seat/topic.

## COMMIT

Commit the snapshot on the **ACTIVE branch** (Class B — it rides the work it
describes). `/handoff` never merges, pushes, or promotes anything; it
snapshots around whatever gate state exists.

Never include secrets, credentials-adjacent values, or personal data — the
same exclusion classes as the memory layer (`MEMORY.md`, Memory Recall).
`SOLE-HOLDER:` facts were persisted in Phase 1 and appear here only as
references to their persisted location.
