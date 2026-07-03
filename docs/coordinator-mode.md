# Coordinator Mode

This document is the single source of truth for the optional coordinator-mode
overlay: running one template-derived repo as a multi-project manager — a
single coordinator repo that orchestrates many project submodules, each with
its own upstream repo. It describes when to scale past a single project, the
project registry, mail routing at coordinator scale, the concurrent-session
model, the coordinator upgrade path, and how to enable or roll back the
overlay. `INIT.md` and `docs/project/mailbox-collaboration-model.md` link
here; do not duplicate this content in those files.

The overlay is opt-in documentation, patterned on the repo's other optional
layers (`docs/issue-mirror-model.md`, `docs/memory-recall-model.md`): it adds
meaning only when activated, and the single-project baseline is unchanged. A
repo that never coordinates multiple projects reads nothing new but two
pointer sentences.

## When to Scale

A single root `MEMORY.md` is sufficient for one project. It holds everything —
project purpose, architecture, environments, safety constraints, guardrails,
and the role set — and every session may safely load all of it, because there
is only one project in scope.

Introduce `projects/<key>/MEMORY.md` at two or more concurrent projects, and
split the context:

- Root `MEMORY.md` — global policy only: guardrails, role set, workflow law,
  coordinator-level constraints.
- `projects/<key>/MEMORY.md` — that project's purpose, architecture,
  environments, and safety constraints (the project-specific sections
  `INIT.md` step 3 finalizes, one copy per project).

Without the split, every session loads all project contexts at once, which is
both noisy and actively misleading — one project's safety constraints get
applied to a different project's work.

Once split, the `AI.md` source-of-truth hierarchy reads per lane: for a given
project's context, `projects/<key>/MEMORY.md` is the authoritative surface —
it outranks any other recollection of that project's context, whether
tool-native memory, chat history, or another file's summary. Root `MEMORY.md`
stays global policy and still outranks everything for cross-project rules and
guardrails. The ranking order in `AI.md` is otherwise unchanged; lane surfaces
(`projects/<key>/mail/`, `projects/<key>/chat/`) stand in for `minions/mail/`
and `minions/chat/` when the work is lane work (see Mail Routing).

On the Branch Coordination Plane (`docs/branching-and-release-model.md`;
class definitions in `MEMORY.md` and `AI.md`), lane surfaces map onto the
existing classes rather than adding new ones, following the files they stand
in for: `projects/<key>/MEMORY.md` and `projects/<key>/chat/` are Class A —
mainline-authoritative for that lane, with the staleness rule applying
whenever they change in `dev` — and `projects/<key>/mail/<packet>/` is Class
B, authoritative on the branch that owns the work until promoted through the
`staging→main` gate. The mainline-authoritative rule itself is unchanged;
the overlay only extends its file lists into the lanes. The tool entry
points (`.github/copilot-instructions.md`, `CLAUDE.md`, `AGENTS.md`) stay
thin pointers and need no per-lane edits — their read chain reaches the
coordinator-mode declaration through the repo's root `MEMORY.md`.

## Project Registry

`projects/index.md` is the authoritative project list. Required columns:

| Column | Meaning |
|---|---|
| project key | short stable identifier; names the lane (`projects/<key>/`) |
| submodule path | where the project is vendored (`submodules/<key>`) |
| repo URL | the project's upstream remote |
| default branch | the submodule branch that lane work integrates with |
| PM owner | which PM seat answers for the project |
| risk tier | coordinator-assigned gating tier (for example low / medium / high) |
| onboarding status | `onboarding` → `in-progress` → `retired` |

Example row:

| project key | submodule path | repo URL | default branch | PM owner | risk tier | onboarding status |
|---|---|---|---|---|---|---|
| `acme-docs` | `submodules/acme-docs` | `https://git.example.com/acme/acme-docs.git` | `main` | PM | low | `in-progress` |

Registry duties:

- PM (the coordinator seat) validates the `PROJECT:` field of every incoming
  packet against this registry and rejects any packet whose key is not
  registered. Minions never invent project keys.
- Rows are never deleted. A project that leaves the coordinator moves to
  status `retired`; history matters.
- The registration sequence for a new project is
  `docs/runbooks/add-submodule.md`.

## Mail Routing

Coordinator use has two mail scopes. Route every packet with one decision:

```text
Does the packet relate to a single project registered in projects/index.md?
  yes → projects/<key>/mail/    (lane packet)
  no  → minions/mail/           (coordinator, cross-project, or policy)
```

Registered project → `projects/<key>/mail/`; coordinator, cross-project, or
policy → `minions/mail/`. If a packet in the coordinator tree turns out to
concern exactly one registered project, it belongs in that project's lane —
the tree decides, not habit. Defaulting everything to `minions/mail/` obscures
project context and makes filtering by project difficult.

One explicit carve-out: packets about a project whose registry status is
`onboarding` — whose lane has not yet passed the PM onboarding gate — route
to `minions/mail/`, not the lane. Until the gate passes, the lane is not
verified as usable, and onboarding itself changes a coordinator-shared
surface (the registry row), so the gate packet is coordinator business. The
onboarding gate packet is opened by the coordinator seat
(`docs/runbooks/add-submodule.md`, step 4), which keeps the `minions/mail/`
write inside the coordinator-seat single-writer rule (see Concurrent
Sessions). Once the row flips to `in-progress`, the tree applies unmodified.

Lane packets add one header field to the packet content standard of
`docs/project/mailbox-collaboration-model.md`:

- `PROJECT: <key>` — required on every lane packet, carried in the
  `request.md` header block alongside the existing minimum structure. The key
  must match a registered project key in `projects/index.md`; PM rejects
  packets carrying unregistered keys (see Project Registry).

Coordinator-tree packets carry no `PROJECT:` field — if one would be
warranted, the packet is a lane packet and routes to the lane instead. All
other packet conventions (naming, ownership, lifecycle, single-writer
durability) are unchanged; routing changes location, not the model.

## Concurrent Sessions

The concurrency model is session-per-project: multiple simultaneous sessions,
each working one project at a time. One session = one project lane at a time.
A session's writes are confined to its lane:

- `projects/<key>/**` — that project's `MEMORY.md`, `mail/`, `chat/`
- the project's submodule — written through the submodule's own branch flow
  (its feature branches and review gates), never edited from another lane
- the session's own `CHANGELOG.d/<topic>.md` fragment — the CHANGELOG
  Maintenance Rule (`MEMORY.md`) requires one on any feature-branch commit,
  so it is part of every session's write set. Fragments are topic-scoped and
  travel with the owning branch, so concurrent sessions still write disjoint
  files; assembling fragments into `CHANGELOG.md` remains a
  coordinator-seat act at the staging gate.

**Coordinator-shared surfaces** — root `MEMORY.md`, `projects/index.md`, the
coordinator `minions/mail/`, the coordinator `CHANGELOG.md`, and root
`feedback.md` — are written only by the **coordinator seat**: the PM-seat
session the Operator designates. Project sessions request shared-surface
changes by filing a lane packet addressed to the coordinator seat; they never
write shared surfaces directly. For `feedback.md` this refines the Feedback
Capture Rule (`MEMORY.md`) at coordinator scale: lane sessions still capture
Operator corrections at end of session, but route them via lane packet for
the coordinator seat to append — every session still reads `feedback.md` at
session start.

This is the roll-up law applied one level up. Within one session,
Single-Writer Durability (see `MEMORY.md`, Communication Model) makes the top
of the spawn chain the packet's single writer, and spawned minions return
work instead of writing it. Across sessions the same shape repeats: each
session is already the top of its own spawn chain and the single writer for
its own lane, and the coordinator seat is the single writer for the shared
surfaces, with lane packets as the return path.

Why this replaces serialization rather than requiring it:

- **Partitioning for lanes.** Lane confinement plus topic-scoped
  `CHANGELOG.d/` fragments mean concurrent sessions touch disjoint files, so
  cross-session contention is eliminated by partitioning — there is nothing
  to serialize, and no serialization role (a commit coordinator or lock
  holder) to staff.
- **Single-writer for shared surfaces.** The few files every session cares
  about have exactly one writer, the coordinator seat — contention on shared
  surfaces is eliminated by ownership, not by locks.

Scope limit: one session per project. Multiple sessions inside one project
lane are out of scope and unsupported until field evidence demands it. If two
work streams must touch the same lane, run them sequentially in one session
lane, not concurrently.

## Coordinator Upgrades

Template upgrades at coordinator scale follow the standard
`docs/downstream-upgrade-playbook.md` flow. Its "Coordinator-mode upgrades"
subsection maps the coordinator's upgrade experience onto the existing
manifest classes and names the coordinator surfaces (`projects/`, the overlay
activation state, coordinator role additions) as expected intentional
divergence. Note that `tools/upgrade-classify.sh` never lists
coordinator-created files at all (they exist only in the live repo, outside
its snapshot union); a `diverged` result on a template file carrying overlay
state — e.g. the live `MEMORY.md` with the coordinator-mode declaration —
reads as normal. Nothing in this overlay changes the upgrade mechanics; it
changes only how classification output is read.

## Enabling It

The overlay is off by default — the template baseline ships no `projects/`
scaffold and no activation state. Absence of the overlay never blocks
single-project use.

Activation is an adopter-side act, performed in the adopting repo:

1. Create `projects/index.md` with the required registry columns (see
   Project Registry) and one row per project.
2. Declare coordinator mode in the adopting repo's `MEMORY.md`, in the
   project-specific sections that `INIT.md` step 3 has you finalize.
   Suggested form:

   ```markdown
   Coordinator mode: ON — this repo manages multiple projects per
   docs/coordinator-mode.md. Projects are registered in projects/index.md;
   per-project context lives in projects/<key>/MEMORY.md.
   ```

3. Onboard each project with `docs/runbooks/add-submodule.md` (submodule
   add, lane scaffold, registry row, PM onboarding gate).

Rollback:

1. Archive `projects/` — move it aside or rely on git history; do not
   rewrite or silently delete it. Registry history matters.
2. Remove the coordinator-mode declaration from `MEMORY.md`.

The template's baseline files carry no overlay state, so rollback is a local
act with no upstream consequence; the repo reverts to a plain single-project
adopter.
