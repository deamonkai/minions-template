# Mail Packets

Use this folder for primary minion-to-minion communication.

This is the mailbox-style coordination surface. New actionable requests,
responses, and verdicts should default here rather than going into shared chat
threads.

## Packet Layout

```text
minions/mail/
  YYYY-MM-DD-sender-to-recipient-topic/
    request.md
    response.md
    verdict.md        # optional
```

## Naming Rule

Use:

`YYYY-MM-DD-<sender>-to-<recipient>-<topic>`

Examples:

- `2026-04-14-pm-to-sm-packet-clarification`
- `2026-04-14-cm-to-pm-implementation-pressure`

## Ownership Rule

- sender writes `request.md`
- addressed recipient writes `response.md`
- gate owner writes `verdict.md` when needed
- no minion edits another minion's packet file

## Workflow Rule

1. open packet
2. commit packet request
3. recipient responds in owned file
4. gate owner records verdict if needed
5. `DM` validates documentation changes when documented behavior, reader paths,
   or runbooks are affected
6. `PM` mirrors durable state into same-day chat summary; `PM` or `DM` updates
   shared docs based on ownership

## ASCII Flow

```text
sender        -> opens packet -> writes request.md
recipient     -> reads request -> writes response.md
gate owner    -> reviews       -> writes verdict.md (if needed)
DM            -> validates     -> docs / runbooks when affected
PM            -> curates       -> daily chat summary + gate docs
```

## Staged Rollout Rule

- already-open legacy chat packets may remain where they are until they close
- any new follow-up packet should open in `minions/mail/`
- do not mirror one active packet across both chat and mail

## Bootstrap Steps

Before opening or answering a mailbox packet, read:

1. `MEMORY.md`
2. `docs/project/mailbox-collaboration-model.md`
3. `minions/mail/README.md`
4. `minions/mail/packet-template.md`

## Packet Content Rule

Use `packet-template.md` as the default skeleton.

Keep packet files concise, explicit, and owner-labeled.

## Relationship To `minions/chat/`

- `minions/mail/` is the primary coordination surface
- `minions/chat/` is the PM-owned daily summary and historical continuity
  surface

See `docs/project/mailbox-collaboration-model.md` for the full repo policy.
