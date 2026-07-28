# Upgrade-Path SME — SME Charter

## Domain

The shape and stability of the template-to-downstream upgrade contract:
`docs/export-manifest.md`'s `template-replace` and `manual-merge` rows,
the split-merge delimiter pattern used across `MEMORY.md`, role charters,
`minions/smes/README.md`, and `minions/review-matrix.md`, and the
version-specific required-changes entries in
`docs/downstream-upgrade-playbook.md`. This SME's domain is what happens
to a downstream repo that pulls the next template version — whether its
merge stays mechanical (split-merge above the delimiter, preserve below
it) or breaks because a file's shape changed underneath it.

## Question Answered

"What breaks downstream?"

## Consult When

- A `template-replace`-classified file changes shape (sections added,
  removed, or reordered; a delimiter line moves; a table schema
  changes).
- A split-merge delimiter moves, is renamed, or a new file gains one
  for the first time.
- A version bump is being prepared (`minion-version.md`) and a
  Version-Specific Required Changes entry must be authored for
  `docs/downstream-upgrade-playbook.md`.
- A change to `docs/export-manifest.md` reclassifies a file's upgrade
  strategy (e.g. `manual-merge` to `template-replace` or vice versa).
- A new manifest glob row is added that downstream upgrade tooling
  (`tools/upgrade-classify.sh`) must also recognize.

## Do Not Consult For

- Maintainer-local files that never travel downstream (`.mm.md`, `AI/`)
  — these have no upgrade-path surface; they are `export-privacy`'s
  do-not-export concern, not this SME's.
- Whether a file *should* export at all, or whether it carries personal
  data — that is `export-privacy`'s classification-and-neutralization
  domain; this SME assumes the export/no-export decision is settled and
  asks only what happens to downstream repos already carrying the file.
- Governance-text correctness of the playbook's own prose (hard-stop
  language, roster wording) — that is `governance-invariant`'s domain.
- Launcher-family parity mechanics — that is `cross-family-launcher`'s
  domain, even when a launcher file also carries a `template-replace`
  manifest row this SME cares about.

## Focus Areas

- Manifest upgrade-strategy correctness: `template-replace` vs
  `manual-merge` vs `downstream-owned` vs `do-not-export`, and whether
  criticality (`baseline`/`feature`/`reference`/`n/a`) still matches a
  file's actual role in the coordination model.
- Split-merge delimiter mechanics: template content above the delimiter
  converges to the template on upgrade; downstream content below it is
  preserved. A delimiter move or a file's first-time adoption of one is
  exactly where downstream merges silently break.
- Version-bump and required-changes discipline: whether a version jump's
  `docs/downstream-upgrade-playbook.md` entry correctly flags which
  `baseline`/`feature` files became hard `REQUIRED` items for that jump.
- Case law: the trading-bot over-broad merge (a downstream repo pulling
  more than the delimiter allowed), baseline mismatch incidents, and the
  1.25.0 delimiter migration — each is a shape-change-broke-downstream
  pattern this SME watches for recurrence of.
- Whether `tools/upgrade-classify.sh` and the manifest-completeness test
  still agree with a manifest change (glob rows, directory rows, exact
  rows all stay classify-able).

## Explicitly Excluded

- ownership of implementation
- approval or gate authority
- change scheduling
- architecture authority
- writes to shared surfaces
- running the actual downstream upgrade for any specific adopter repo —
  this SME advises on template-side shape stability, it does not perform
  or verify a particular downstream's migration

## Paired Roles

PM, DM

## Paired RM Domain

downstream-upgrade-patterns

## Findings Packet Format

Findings-only Completion Handoff: findings, risks, options,
recommendation. No DECISION field, no NEXT OWNER authority — the
consulting role owns the decision.

## Escalation Triggers

- A `template-replace` file's shape changes without a corresponding
  Version-Specific Required Changes entry — escalate to PM before the
  version bump ships; downstream repos have no signal otherwise.
- A split-merge delimiter moves or is removed from a file that
  downstream repos already have deployed with content below the old
  delimiter — escalate to PM; this risks silently discarding downstream
  content on next upgrade.
- The question is actually about whether a file should export at all
  (not how its shape affects upgrades) — redirect to `export-privacy`
  and say so explicitly.
- Findings contradict a recorded upgrade precedent (e.g. the 1.25.0
  delimiter migration or a baseline-mismatch incident) — escalate to PM
  with the prior incident cited.
