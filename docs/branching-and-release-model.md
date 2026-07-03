# Branching and Release Model

This document is the single source of truth for the branching strategy, promotion
flow, gate ownership, and coordination rules used by the minion workflow. All other
docs that reference branches, gates, or Class-A/B files link here.

## Branches

Four named tiers. Everything flows in one direction: feature → dev → staging → main.

| Branch | Pattern | Owner | Purpose |
| --- | --- | --- | --- |
| `feature/<topic>` | One per feature or task | CM | Implementation work; isolated until green |
| `dev` | Single integration branch | OM-Test | Continuous integration; OM-Test validates |
| `staging` | Single pre-release branch | OM | Final validation; DM doc-sync; PM gate |
| `main` | Production | OM | Deployed, tagged, never rewritten |

`hotfix/<topic>` branches are a special case — see [Hotfix & Rollback](#hotfix--rollback).

## Promotion Flow

Eight steps from CM keyboard to deployed tag. Steps 1–6 are autonomous (minions
proceed without Operator approval). Step 7 is the single hard-stop.

1. **CM implements** on `feature/<topic>`, running tests and lint until green.
2. **Review gate** — CM self-reviews for correctness; SM reviews if the change
   touches auth, secrets, access control, or input handling.
3. **CLI merge `feature→dev`** — CM merges after the review gate passes. No
   Operator approval needed.
4. **OM-Test validates** — OM-Test runs integration and smoke checks against
   `dev`. Failures return to CM.
5. **CLI merge `dev→staging`** — OM-Test merges after OM-Test validation passes. No Operator
   approval needed.
6. **OM validates + DM doc-sync + PM gate** — OM confirms staging health; DM
   assembles `CHANGELOG.d/` fragments into `CHANGELOG.md` and deletes the
   fragments, and **in the same commit** writes the release's entry in
   `docs/downstream-upgrade-playbook.md` "Version-Specific Required Changes"
   (even the negative one-liner: "No required changes — adopt normally");
   PM confirms the milestone is complete and gate criteria are met — an
   assembly lacking the playbook entry does not pass the gate.
7. **PM opens the `staging→main` pull request (PR)** on the project's VCS
   host — this is the Operator hard-stop. The Operator reviews the PR,
   confirms everything, and merges. The PR can be opened via that host's
   web UI (toolless), REST API, or CLI (`tea` for Gitea, `gh` for GitHub)
   — all optional conveniences; the web UI is always the toolless path. See
   `docs/runbooks/branch-setup.md` for per-host recipes.
8. **OM deploys and tags** — after merge, OM deploys from `main`, creates a
   version tag, and back-merges `main` into `dev` and `staging` to keep them
   current.

## Gates & Hard-Stops

`feature→dev` and `dev→staging` are autonomous (minions still run review gates).
`staging→main` is the single Operator hard-stop and goes through a pull request
(PR) on the project's VCS host (Gitea, GitHub, etc.).

The minions enforce quality gates at every step, but gate *approval authority*
differs:

| Transition | Approval authority | Gate type |
| --- | --- | --- |
| `feature→dev` | CM (autonomous) | Review + tests green |
| `dev→staging` | OM-Test (autonomous) | OM-Test pass |
| `staging→main` | Operator | PR on the project's VCS host + explicit merge |

No minion may merge or push to `main` unilaterally. If a hard-stop is reached
in an automated pipeline, the orchestrator surfaces the state to the Operator
and waits.

## Coordination Plane (Class A / Class B)

Files are divided into two classes based on how they travel through the
branching model.

**Class A — mainline-authoritative:**
`MEMORY.md`, `AI.md`, `CLAUDE.md`, `AGENTS.md`, `minions/roles/*`, `ROADMAP.md`,
`TODO.md`, `minions/chat/`

**Class B — travels with the branch:**
that feature's `minions/mail/<packet>/`, `minions/plans/<plan>`, its spec and
design docs, `CHANGELOG.d/<topic>.md`

Class A is the shared brain — one version everyone sees; Class B is the work's
own paper trail and merges up with the code.

Because Class-A files are authoritative on the mainline, minions avoid
*incidental mid-feature edits* to them (capturing learnings via `feedback.md`
and promoting at merge time). However, *planned structural changes* to Class-A
files are normal feature deliverables that flow to `main` through the milestone;
this rule does not forbid editing Class-A files on a feature branch when the
edit is the intended deliverable.

When a feature branch picks up stale Class-A state (see [Staleness Rule](#staleness-rule)),
the merge of `dev` into the branch is the mechanism for refreshing that state.

## CHANGELOG Fragments

Each feature drops `CHANGELOG.d/<topic>.md` (Class B). At the staging gate,
DM assembles fragments into `CHANGELOG.md` and deletes them *before* the
pull request (`staging→main`) is opened, so the PR includes the assembled
changelog.

This keeps merge conflicts off `CHANGELOG.md` entirely: every feature writes
into its own namespaced fragment; the consolidation happens exactly once, at the
staging gate (step 6 of the Promotion Flow), under DM ownership. The PR is
opened on the project's VCS host (Gitea, GitHub, etc.) via that host's web UI,
REST API, or CLI (`tea`/`gh`) — all optional conveniences; see
`docs/runbooks/branch-setup.md` for per-host recipes.

Fragment naming convention: `CHANGELOG.d/<feature-topic>.md`, matching the
`feature/<topic>` branch name so fragments are traceable.

## Staleness Rule

A feature branch MUST regularly merge `dev` back into itself so its copy of
Class-A truth stays current. Stale shared truth is this model's primary failure
mode.

The frequency is judgment-driven: merge `dev` into the feature branch whenever
a Class-A file changes in `dev`, or before any gate step where Class-A state
affects the review. Long-running branches should merge `dev` at least daily.

A feature that merges stale Class-A files into `dev` pollutes the shared brain
for all downstream features. OM-Test is the last check before `staging` — catch
staleness before step 4, not after.

## Hotfix & Rollback

**Hotfix:** branch `hotfix/<topic>` off `main`, implement and verify the fix,
then merge back to `main` through the Operator gate (same pull request process
as a normal staging→main merge). Immediately after the `main` merge, OM back-merges
`main` into both `dev` and `staging` so the fix propagates forward.

Hotfixes bypass `dev` and `staging` because the fix target is `main`. The
trade-off is that OM-Test validation is condensed; SM review is still required
if the hotfix touches a security surface.

**Rollback:** rollback = revert merge commit or redeploy previous tag (OM). `main`
is never rewritten. The revert commit preserves audit history; redeploying a
previous tag is the fastest path when the rollback scope is limited to the
runtime artifact. OM owns the rollback decision and execution.

## Downstream Adoption (3-tier variant)

Projects without a real staging environment MAY collapse `staging` into `dev`
for a 3-tier variant (`feature/<topic>` → `dev` → `main`). In this variant, `dev`
carries both the OM-Test and the OM + DM + PM gate responsibilities, and the
Operator hard-stop's *target* moves to `dev→main` (a pull request from `dev`
to `main` replaces the `staging→main` PR).

The gate *authority and ownership rules are unchanged*: the Operator still
approves the production merge via a pull request on the project's VCS host;
the Class-A/B coordination rules
are unchanged; minion autonomy boundaries are unchanged. All other sections of
this document apply without modification to the 3-tier variant — only the branch
count and hard-stop target differ, not the ownership, autonomy, or
coordination-plane rules.

When upgrading from 3-tier to 4-tier, create `staging` off `main`, update CI to
target the new branch, and reconfigure the PR destination on the VCS host. The
`CHANGELOG.d/` fragment workflow is identical in both variants.
