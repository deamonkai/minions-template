# Archive Reporter Model

This document is the canonical model for `tools/archive-reporter.sh` — a
**read-only** tool that surfaces aging, closed coordination units so a human
or orchestrator can prune them at a milestone boundary. It is the small,
safe subset of a larger automated-sweep design that was reviewed across three
rounds and deliberately deferred (see the History section).

## Why it exists

As a project ages, closed coordination units accumulate in the working tree —
`minions/mail/` packets, `minions/plans/`, `minions/chat/` threads. They
dominate greps and recall hits, get pulled in wholesale when a brief says
"read the mail packets," and clutter the tree. The reporter identifies which
of them are safe to archive and prints the exact commands to do so — without
ever executing them.

Measured on the template's own repo, coordination units are ~8,815 words; the
two big ledgers (`CHANGELOG.md` + `minion-version.md`) are ~29,734. The
reporter targets units first on **mechanism risk, not mass**: moving a whole
unit is trivially reversible, splitting an authoritative timeline is not.
Ledger thinning is tracked as a separate, higher-value follow-up.

## The safety story: it cannot mutate

The reporter's entire value proposition is that **the human running the
printed command is the safety boundary.** The tool:

- has no `run` subcommand, and contains no `git rm` / `git add` / `git commit`
  / `mkdir` / `rm` / redirect-to-repo-path;
- prints `git rm -r "<unit>"` plus a ready-to-paste `minions/ARCHIVED.md` row
  as **text**, for a human to review and execute;
- writes nothing, deletes nothing, commits nothing, needs no lock, and has no
  `MINION_SECONDBRAIN` dependency (that gating existed only for the vault-write
  leg of the deferred automated design, which this subset does not have).

This invariant is enforced by the test suite two ways: a **behavioral**
no-mutation test (snapshot the tree, run the reporter, assert byte-identical)
and a **textual** grep that catches a mutating verb or repo-path redirect
added by a future edit. The behavioral test is the load-bearing gate.

## What it reports

`archive-reporter.sh report` (the default; bare invocation is identical) emits:

1. **Candidates** — units that are closed AND aged AND pass every screen. For
   each, a `# header` line, the `git rm -r` command, and the `ARCHIVED.md` row
   to paste (carrying the source sha `git log -1 --format=%h` so restore is
   `git checkout <sha> -- <path>`).
2. **Withheld + drift summary** — counts by class so nothing is silent:
   `sole-holder`, `referenced-by-live-surface` (with referrers),
   `not-removable`, and `unmarked-but-aged` (the drift signal — aged units
   with no closure marker, plus the single oldest such unit).

Exit codes: `0` normal, `2` usage error, `4` a git/IO failure that prevented a
correct report (never a partial silent one).

## The predicate — closed AND aged

**Closed** reuses the existing `Status:` lifecycle from
`minions/plans/milestone-plan-template.md` (`OPEN` / `CLOSED — COMPLETE` /
`CLOSED — SUPERSEDED`). A unit is closed when a `Status:` line whose value
begins with `CLOSED` (case-insensitive) appears in the first 10 lines, at
column 0, outside any fenced code block — for a directory unit, in a
designated file in order `verdict.md` → `response.md` → `request.md` (none
present → not closed, never an error).

**Aged** is git last-commit time (`git log -1 --format=%ct`) older than the
threshold (`--age-days`, default 30, floor 7; `MINION_ARCHIVE_AGE_DAYS`
overrides the default). An empty git-log result (shallow clone) is treated as
not-aged.

Scope roots: `minions/mail/<dir>/`, `minions/plans/<file>.md`,
`minions/chat/<file>.md`. `README.md` and `*-template.md` are skipped;
coordinator lanes are out of scope for this version.

## Screens — why a closed+aged unit is still withheld

1. **sole-holder** — the body matches `SOLE[[:space:]_-]*HOLDER…:`
   case-insensitive, including the common Unicode dashes (U+2011/2013/2014).
   `SOLE-HOLDER:` facts are the framework's most-precious class and never leave
   the tree.
2. **referenced-by-live-surface** — a live surface references the unit path.
   The immutable historical ledgers (`CHANGELOG.md`, `CHANGELOG.d/`,
   `minion-version.md`, `minions/ARCHIVED.md`) are exempt — a citation there is
   not a live dependency, and the index row + sha keeps it resolvable.
3. **not-removable** — the unit has uncommitted modifications, untracked
   files, a subdirectory, a symlink, a non-text file, or an `.issue` sidecar,
   any of which would make the printed `git rm -r` unsafe or lossy.

## Milestone habit

PM runs the reporter at each milestone/run start and acts on its candidate
list — the same cadence as the `minions/capabilities.md` refresh. The
`unmarked-but-aged` line surfaces drift (a closure-marking convention that has
gone quiet) so the tool cannot silently do nothing.

## History and deferred work

The reporter is the shipped subset of a larger design. The full automated-sweep
design — a tool that captures units to the second-brain vault and performs the
`git rm` itself — was reviewed across three rounds (a 7-reviewer panel, then two
lean rounds). It reached SHIP-WITH-CONDITIONS from the safety reviewers but
NEEDS-WORK-on-proportionality from architecture: an 8-precondition primitive
with a lock, a fence parser, a TOCTOU re-check, a vault leg, and a backfill,
to automate deletion of ~25% of the aging mass that the bootstrap never reads.
That design spec and its review record are maintainer-local (not exported).

The automated `run` path is **deferred, not cancelled** — to be earned only if
the reporter demonstrates over ≥2 milestones that units accumulate AND get
marked closed. Its conditions are recorded in the deferred design's verdict
packet (maintainer-local). The reporter reuses the hardest-won parts of that
design: the closure
predicate, the age derivation, the ledger-exempt reference partition, and the
Unicode-dash-tolerant sole-holder screen.
