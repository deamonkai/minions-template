# Plans

Use this folder for formal milestone plans, review plans, and closeout docs.

## Good Plan Characteristics

- clearly scoped
- explicit owner view
- current phase visible at the top
- next review point visible at the top
- exit criteria defined

## Bad Plan Characteristics

- vague success criteria
- hidden scope changes
- no owner
- no review gate

## STATUS Lifecycle

Every plan carries a top-of-file `Status:` marker with exactly one of
three values:

- `OPEN` — the plan is live and still governs work
- `CLOSED — COMPLETE` — the plan's exit criteria are met
- `CLOSED — SUPERSEDED (superseded-by: <ref>)` — a later plan or
  decision replaced this one; `<ref>` names the successor

The top-of-file STATUS marker is the closure signal, not checkbox
completion. Same-day supersede rule: a plan must not remain OPEN when
the execution model it was written against no longer exists — mark it
`CLOSED — SUPERSEDED` the same day and name what replaced it.

Legacy plans predating this lifecycle marker may carry the old literal
`Status: Active` heading — that reads as `OPEN` until someone edits the
file; there is no retroactive invalidation, and no sweep is required to
relabel them.
