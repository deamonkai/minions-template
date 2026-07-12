# Issue / Project Mirror Model

This document is the single source of truth for the optional Issue/board mirror
layer. It describes the design rationale, invariants, packet-to-Issue mapping,
label and board conventions, full lifecycle, the `tools/issue-sync.sh` wrapper,
and how to enable the feature. `MEMORY.md` and
`docs/runbooks/issue-board-setup.md` link here; do not duplicate this content
in those files.

## Why a View Layer

Minion workflow artifacts live in the repo: mail packets in
`minions/mail/<packet>/`, gate artifacts in `minions/plans/`, chat in
`minions/chat/`, etc. Git is the primary coordination surface, and that is
intentional — it keeps history auditable, merge-friendly, and host-agnostic.

Issue trackers and project boards (Gitea, GitHub) add value that git-native
files do not provide out of the box:

- **At-a-glance dashboards** — board columns communicate pipeline state without
  requiring a consumer to know which directories to look in.
- **Host notifications** — assignees receive email or in-app alerts when an
  Issue is created or updated.
- **Search and filter** — label queries let the Operator find all open gate
  blockers, all mail from a specific role, or all pipeline runs for a sprint,
  without touching the file tree.

The mirror is therefore a *view* of file state, not a parallel source of truth.
Issues are generated from packets; they are never the origin of information.

## Invariants

Five invariants hold unconditionally.

1. **Files win.** The repo is the canonical state. If an Issue and a file
   disagree, the file is correct. Regenerate the Issue from the file, never
   the reverse.

2. **One-way projection: file → Issue.** The wrapper writes to Issues; it
   never reads from them for decision-making. No minion polls the tracker or
   uses Issue comments as inputs.

3. **Comments don't count until promoted.** Issue comments are ephemeral
   discussion. They do not enter the workflow until someone manually promotes
   them into a packet file (`request.md`, `response.md`, `verdict.md`, etc.)
   and commits.

4. **Optional and graceful.** The feature is off by default
   (`MINION_ISSUES=off`). When it is off, or when the host CLI is absent or
   unreachable, every call to `issue-sync.sh sync` exits 0 silently. No
   minion role is blocked by Issue creation failure. Exit code 4 signals a
   soft backend failure; the caller may log it but must not abort the pipeline
   on that basis.

5. **Host-abstracted.** The wrapper resolves the backend (`gitea` via `tea`,
   `github` via `gh`) from the `origin` remote URL or from the
   `MINION_ISSUE_HOST` override. Roles call `issue-sync.sh`; they do not
   contain host-specific logic.

The banner placed at the top of every generated Issue body expresses invariants
1–3 in one line:

```
Generated from <path> — edit the packet, not this issue.
```

## Mapping

Each minion artifact type maps to a distinct Issue granularity. The table below
is normative.

| Artifact type | `--type` | Granularity | Assignee | Notes |
|---|---|---|---|---|
| Mail packet | `mail` | One Issue per packet | None | Labels include `role:<sender>` and `role:<recipient>` derived from the filename |
| Gate artifact | `gate` | One Issue per gate checkpoint | `MINION_OPERATOR` | Requires Operator visibility; assigned so the Operator is notified |
| Blocker | `blocker` | One Issue per blocker | `MINION_OPERATOR` | Same assignee rule as `gate`; tracks unresolved hard-stops |
| `staging→main` gate | — | The PR card on the host | — | **No separate Issue.** The PR itself is the Operator gate artifact; creating a duplicate Issue would be redundant and confusing |
| Pipeline run | `pipeline` | One Issue per run | None | Captures per-run health; suitable for automation hooks |
| Chat artifact | `chat` | One Issue per day | None | `minions/chat/YYYY-MM-DD.md` maps to a single rolling Issue for that date |

Assignee-Operator rule: only `gate` and `blocker` types set an assignee, and
only to `$MINION_OPERATOR`. All other types leave the assignee field empty.

### Label Axes

Labels follow two axes: `type:` and `role:`.

| Axis | Values | Color |
|---|---|---|
| `type:` | `mail`, `gate`, `blocker`, `pipeline`, `chat` | `#0366d6` |
| `role:` | `pm`, `am`, `cm`, `sm`, `dm`, `om`, `om-test`, `rm` | `#5319e7` |

Every Issue carries exactly one `type:` label. Mail Issues additionally carry
`role:<sender>` and `role:<recipient>` derived by splitting the packet filename
on the `<date>-<sender>-to-<recipient>-<topic>` convention. Other types do not
receive `role:` labels automatically; add them manually when relevant.

## Board & Labels

The project board has five columns. Minions advance Issues leftward through the
board by moving cards (when the host API supports it) or by using label
conventions when it does not.

```
Triage → In Progress → Awaiting Review → Awaiting Operator → Done
```

| Column | Meaning |
|---|---|
| `Triage` | Newly created Issue; not yet picked up |
| `In Progress` | Actively being worked by a minion role |
| `Awaiting Review` | Work complete; waiting for a peer or SM review gate |
| `Awaiting Operator` | Hard-stop reached; Operator decision required |
| `Done` | Resolved, merged, or closed |

`Awaiting Operator` is the only column where the Operator is the expected actor.
It corresponds to the Operator gate in the Promotion Flow (see
`docs/branching-and-release-model.md`, step 7). Gate and blocker Issues that
trigger the Operator hard-stop belong here; the `staging→main` PR card lives
in this column as well.

`tools/issue-board-bootstrap.sh` creates the labels idempotently. Board columns
require manual creation on most hosts (the bootstrap script reports which steps
need manual action); follow `docs/runbooks/issue-board-setup.md`.

## Lifecycle

### Creation

When a minion role produces an artifact (sends mail, opens a gate, raises a
blocker, finishes a pipeline run, writes the day's chat digest), the
producing role returns the artifact to its caller. Under Single-Writer
Durability (see `MEMORY.md`, Communication Model), the packet's single writer
— the top of the spawn chain, or the role itself when it drives its own
session — performs the durable write and then calls:

```bash
tools/issue-sync.sh sync --type <type> --packet <path> [--title <s>]
```

If `MINION_ISSUES` is not `on`, the call exits 0 immediately. Otherwise,
`issue-sync.sh` resolves the host, derives the title, labels, and assignee from
the packet path and type, renders the Issue body (starting with the canonical
banner), and creates the Issue via the host CLI. The Issue number is written
to a `.issue` sidecar file next to the packet (`<dir>/.issue` for directories,
`<file>.issue` for flat files).

### Idempotency

If the sidecar already exists, subsequent `sync` calls *update* the existing
Issue rather than creating a new one. This means re-running a sync after
editing a packet body reflects the new content in the Issue without creating
duplicates. The sidecar is a repo file and travels with the packet in Class B.

### Update

Edit the packet file (not the Issue). Re-run `issue-sync.sh sync` (or wait
for the pipeline to re-run it automatically). The Issue body is overwritten
with the new content. The banner is always regenerated verbatim.

### Close

Issues are closed manually or by automation rules on the host. `issue-sync.sh`
does not close Issues; lifecycle transitions (In Progress → Done, etc.) are
board-management actions that the Operator or assigned minion performs on the
host UI or via direct CLI calls outside this wrapper.

### Exit Codes

| Code | Meaning |
|---|---|
| `0` | Success or no-op (feature disabled, CLI absent) |
| `2` | Usage error (missing or invalid argument) |
| `4` | Backend failure (host CLI returned an error) — soft; caller must not abort |

## The Wrapper

`tools/issue-sync.sh` is the single entry point for all Issue projection.

### Subcommands

| Subcommand | Effect |
|---|---|
| `host` | Print the resolved host name (`gitea`, `github`, `none`) and exit |
| `render` | Print the derived title, labels, assignee, and body to stdout (offline; no network call) |
| `sync` | Create or update the Issue on the resolved host (requires `MINION_ISSUES=on`) |

### Invocation

```
tools/issue-sync.sh sync --type <mail|gate|blocker|pipeline|chat> \
                          --packet <path> \
                          [--title <override>]
```

`--title` is optional. When omitted, the title is derived as
`[<type>] <basename of packet>`.

### Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `MINION_ISSUES` | `off` | Master switch; must be `on` to enable any Issue writes |
| `MINION_ISSUE_HOST` | _(auto)_ | Override host detection: `gitea` or `github` |
| `MINION_OPERATOR` | _(empty)_ | Username assigned to `gate` and `blocker` Issues |

When `MINION_ISSUE_HOST` is unset, the host is inferred from the `origin`
remote URL: URLs containing `github.com` → `github`; empty remote → `none`;
anything else → `gitea`.

### Backends

| Host | CLI | Notes |
|---|---|---|
| Gitea | `tea` | Full create + edit support |
| GitHub | `gh` | Create + body edit supported; Projects-v2 board wiring deferred (spec §9) |

If the required CLI is absent or the command fails, `issue-sync.sh sync` exits
0 (soft no-op) or exits 4 on confirmed backend error, per invariant 4.

## Enabling It

The feature is off by default. Enabling it is a two-step process:

### Step 1 — Bootstrap labels and board

```bash
MINION_ISSUES=on tools/issue-board-bootstrap.sh
```

This script idempotently creates the `type:*` and `role:*` labels on the
configured host. For each label it reports `created: <label>` or
`exists: <label>`. Board column creation is not automated; the script prints
a `manual` notice directing you to `docs/runbooks/issue-board-setup.md`.

Run this once per repo, or after changing hosts. It is safe to re-run; it will
not duplicate labels.

### Step 2 — Set the master switch

Export `MINION_ISSUES=on` in the environment where minions run. For persistent
activation, add it to the project's `.env` or the shell profile used by the
orchestrator.

```bash
export MINION_ISSUES=on
export MINION_OPERATOR=<your-host-username>   # required for gate/blocker assignee
export MINION_ISSUE_HOST=gitea                # optional; omit to auto-detect
```

After these steps, every `tools/issue-sync.sh sync` call will project packets
into Issues. To disable, unset `MINION_ISSUES` or set it to any value other
than `on`.

See `docs/runbooks/issue-board-setup.md` for per-host board setup recipes
and CLI authentication notes.

When `MINION_ISSUES=on`, `issue-sync.sh` and `issue-board-bootstrap.sh`
additionally honor an explicit `adopted: off` in this repo's onboarding
checklist by no-op'ing (fail-open otherwise); see `tools/layer-adopted.sh`
and the Optional Layers convention in `MEMORY.md`.
