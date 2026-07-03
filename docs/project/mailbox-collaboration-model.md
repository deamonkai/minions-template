# Mailbox Collaboration Model

Last updated: 2026-06-08
Owner: PM / DM

## Decision

This template uses a mailbox-style, packet-first coordination model for minion
communication.

Accepted model:

- actionable role-to-role communication belongs in `minions/mail/`
- mailbox packets are the primary request/response/verdict surface
- `minions/chat/` becomes a PM-owned summary and continuity surface, not the
  primary multi-writer conversation surface
- shared state docs remain single-owner surfaces, usually `PM` or `DM`

## Problem This Solves

The issue is not plain text itself. The issue is shared mutable text files used
for too many roles at once.

The old pattern mixed:

- communication
- current state
- audit history

inside the same small set of files. That created avoidable collisions:

- multiple minions editing the same daily thread
- packet state and project state blending together
- "current truth" and "historical discussion" fighting in the same document

The mailbox model separates those concerns.

## Core Rule

Minions should post new packet files, not co-edit the same live thread.

That means:

- one packet thread gets one packet directory
- one message gets one owned file
- sender authors the request
- recipient authors the response
- gate owner authors the verdict when needed
- follow-up questions or corrections become new packet files or new packets, not
  rewrites of another minion's message

Authorship names who is accountable for the content; writership names who
performs the durable write. Under Single-Writer Durability (see MEMORY.md,
Communication Model), a spawned minion authors its message and returns it;
the packet's single writer — the top of the spawn chain — performs the
write.

- Packet headers record both: `WRITTEN-BY: <writer> on behalf of <role>`.
- The writer transcribes returned content **verbatim** — the writer
  transcribes, never edits. The no-rewrites rule now binds the writer.
- The writer commits each returned deliverable before dispatching the next
  stage, and always before session end or Operator handoff.
- A minion driving its own Operator session writes its own packets; the
  header form `WRITTEN-BY: <role>` (no on-behalf-of) covers that case.
- Returns flagged `SOLE-HOLDER:` are persisted first, immediately on return;
  the stage-boundary window applies to everything else.

## Directory Layout

```text
minions/
  mail/
    YYYY-MM-DD-sender-to-recipient-topic/
      request.md
      response.md
      verdict.md        # optional
```

Multi-project coordinators route per-project packets to `projects/<key>/mail/`
instead — the routing decision tree is in `docs/coordinator-mode.md`.

Recommended packet id format:

`YYYY-MM-DD-<sender>-to-<recipient>-<topic>`

Examples:

- `2026-04-14-pm-to-sm-packet-clarification`
- `2026-04-14-cm-to-pm-implementation-pressure`
- `2026-04-14-pm-to-am-architecture-reset`

## File Ownership

Default ownership inside a packet:

- `request.md`: sender only
- `response.md`: addressed recipient only
- `verdict.md`: gate owner only, usually `PM`

Hard rules:

- do not edit another role's packet file
- do not silently rewrite packet history after handoff
- do not use a shared mailbox file for multiple independent topics

If substance changes after a handoff commit:

- open a new follow-up packet, or
- add a new owned file in the same packet only if the workflow explicitly calls
  for it and ownership is clear

## Packet Lifecycle

1. sender opens a packet directory and writes `request.md` (authorship; the
   physical write is the single writer's when the author is spawned)
2. recipient writes `response.md` (authorship; the physical write is the
   single writer's when the author is spawned)
3. gate owner writes `verdict.md` when a decision is needed (authorship; the
   physical write is the single writer's when the author is spawned)
4. `DM` validates documentation changes when a packet changes documented
   behavior, operator workflow, or reader-facing project truth
5. `PM` or `DM` mirrors durable state changes into `README.md`, `MEMORY.md`,
   `ROADMAP.md`, `TODO.md`, plans, or requirement docs as needed
6. `PM` posts a same-day summary into `minions/chat/YYYY-MM-DD.md`

This keeps:

- packet history in mail
- project truth in shared state docs
- human continuity in chat summaries

## ASCII Flow

```text
                          MAILBOX-FIRST COLLABORATION

                  new actionable work / request / finding / handoff
                                      |
                                      v
+----------------------------------------------------------------------------------+
| minions/mail/YYYY-MM-DD-sender-to-recipient-topic/                               |
|                                                                                  |
|  request.md   -> written by sender only                                          |
|  response.md  -> written by addressed recipient only                             |
|  verdict.md   -> written by gate owner only (usually PM, only if needed)         |
+----------------------------------------------------------------------------------+
                                      |
                                      v
                           packet decision / response exists
                                      |
                                      v
                   +---------------------------------------------+
                   | PM / DM mirror durable outcomes into project|
                   | truth docs as needed:                       |
                   | - README.md                                 |
                   | - MEMORY.md                                 |
                   | - ROADMAP.md                                |
                   | - TODO.md                                   |
                   | - plans / other controlled docs             |
                   +---------------------------------------------+
                                      |
                                      v
                   +---------------------------------------------+
                   | PM posts same-day summary into              |
                   | minions/chat/YYYY-MM-DD.md                  |
                   | chat is summary/history only                |
                   | not the live multi-writer work surface      |
                   +---------------------------------------------+
```

(diagram labels are authorship; under Single-Writer Durability the physical
write is the single writer's when the author is spawned — see the
authorship-vs-writership passage above.)

## Role Of Other Surfaces

### `minions/mail/`

Primary coordination surface for:

- requests
- findings
- review responses
- verdicts
- handoff packets

### `minions/chat/`

PM-owned summary surface for:

- daily continuity
- bootstrap announcements mirrored by PM
- high-level packet summaries
- operator-facing recap
- historical topic recap when a lightweight summary is useful

`minions/chat/` is no longer the default place for multi-role live packet
editing.

### Shared State Docs

These remain single-owner surfaces and should not absorb raw packet history:

- `README.md`
- `MEMORY.md`
- `ROADMAP.md`
- `TODO.md`
- milestone plans under `minions/plans/`

`PM` owns gate and summary truth. `DM` owns documentation truth and reader-path
coherence when docs are the affected surface.

## Packet Content Standard

The existing packet style still works. Mailbox changes location and ownership,
not the need for clear handoffs.

Minimum request structure:

- `TARGET ROLE:`
- `DECISION:`
- `RATIONALE:`
- `ACTION NEEDED:`

Minimum response structure:

- `DECISION:`
- `RATIONALE:`
- `ACTION NEEDED:`

Preferred full handoff structure for substantive responses:

- `DECISION:`
- `RATIONALE:`
- `SCOPE COMPLETED:`
- `OUT OF SCOPE:`
- `EVIDENCE:`
- `BLOCKERS/RISKS:`
- `ACTION NEEDED:`
- `NEXT OWNER:`
- `READY CHECK:`

## Migration Rule

Existing chat threads remain historical record and should not be rewritten to
fit the mailbox model.

Migration posture:

- keep current `minions/chat/` files as history
- use `minions/mail/` for new actionable packet flows
- let `PM` summarize mailbox activity into daily chat and let `PM` or `DM`
  update project-control docs based on the affected surface

## Staged Rollout Rule

Mailbox adoption is staged, not all-at-once.

During rollout:

- an already-open packet may remain on its legacy `minions/chat/` surface until
  that exact packet closes
- `PM` should add a transition note in the legacy packet when follow-up work
  must move to mail
- any new follow-up packet spawned from a legacy chat packet should open in
  `minions/mail/`
- do not duplicate the same active packet in both chat and mail
- do not migrate old packet history by rewriting it into mail

Practical rule:

- finish the current packet where it already lives
- open the next packet in `minions/mail/`

## Mailbox Bootstrap

Before opening a new mailbox packet, the acting minion should read:

1. `MEMORY.md`
2. `docs/project/mailbox-collaboration-model.md`
3. `minions/mail/README.md`
4. `minions/mail/packet-template.md`

## Benefits

This model is intended to reduce:

- merge conflicts from shared daily-thread editing
- packet ambiguity from multi-topic thread reuse
- accidental overwrites between minions — under Single-Writer Durability
  (see MEMORY.md, Communication Model), a single writer per packet makes
  within-packet overwrites structurally impossible, not just discouraged
- confusion between project truth and communication history

It also makes ownership clearer:

- communication is append-oriented
- summaries are curated
- state is owned

## When To Revisit

Revisit this model if:

- mailbox packet count becomes too large to navigate
- packet discovery becomes harder than the old thread model
- the repo needs a generated index over packets
- operators need a richer inbox or dashboard view than git paths alone provide

If that happens, the next likely step is not a return to shared chat files. It
is a mailbox index, event log, or generated view layered on top of the packet
model.
