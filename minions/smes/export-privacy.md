# Export/Privacy SME — SME Charter

## Domain

What may leave this repo and in what form: the `docs/export-manifest.md`
classification of every tracked file (`do-not-export`, `downstream-owned`,
`template-replace`, `manual-merge`, `reference`), the neutralization-token
sweep and seed-reset steps in `docs/runbooks/public-export.md`, and any
change that touches `feedback.md`, the `AI/` maintainer-local tree, or
personal-data-adjacent content. This SME's domain covers both the
downstream-onboarding export (`docs/downstream-onboarding-playbook.md`)
and the public-mirror publish — the second is irreversible the moment it
is pushed, which makes this SME's judgment the highest-stakes on the
bench.

## Question Answered

"Can this go public or downstream?"

## Consult When

- A change adds a new tracked file (it needs a manifest row before the
  next export/upgrade cycle, per the manifest-completeness guard).
- A change alters `docs/export-manifest.md` classification for any
  existing row, especially a shift between `do-not-export`,
  `downstream-owned`, and an exportable strategy.
- A public-mirror refresh is being prepared (any pass through
  `docs/runbooks/public-export.md`).
- A change touches `feedback.md`, the `AI/` directory, or any content
  that could carry Operator-personal phrasing, names, or condition-
  specific references (the neutralization-token surface).
- A change touches the split-merge delimiter or seed-reset content in
  `minions/smes/README.md` or `minions/review-matrix.md` (D6 seed-reset:
  local rows must reset to empty below the delimiter before publish).

## Do Not Consult For

- Internal-only edits that never export and never touch a manifest row
  (e.g. a `minions/mail/` packet, a `minions/chat/` summary) — these
  have no export-privacy surface to review.
- Whether a template-replace file's *shape* changed in a way that breaks
  downstream upgrades — that is `upgrade-path`'s domain, even when the
  same file also carries an export-manifest row this SME classifies.
- Governance-text correctness of the manifest's own prose (hard-stops,
  roster language) — that is `governance-invariant`'s domain; this SME
  reviews manifest *classification decisions*, not governance wording.
- Launcher-family behavioral parity — that is `cross-family-launcher`'s
  domain, even for SME launchers this SME's own bench introduced.

## Focus Areas

- Manifest classes and whether a file's assigned class (`do-not-export`,
  `downstream-owned`, `template-replace`, `manual-merge`, `reference`)
  still matches its actual content and purpose.
- Neutralization tokens: personal data, Operator-identifying phrasing,
  condition-specific references, and their cross-references (heading
  echoes, dangling pointers) — tree-wide, token-based sweeps, not
  single-line fixes (the personal-condition-token echo miss is the canonical case
  law for why single-line passes are insufficient).
- The fresh-history rule: canonical Git history never crosses into the
  public copy; every publish is a manifest-filtered tree committed fresh.
- Seed-reset files: `feedback.md`, and the Local Registry /
  Local Matrix sections below the split-merge delimiter in
  `minions/smes/README.md` and `minions/review-matrix.md`, must reset to
  their seed/stub state before publish.
- Pre-push hard gates: test suite (`tools/tests/*.test.sh`), `gitleaks`
  secret scan, and the forbidden-files check (`.mm.md`, `AI/`,
  `.remember/`, `.superpowers/`) — all three must pass before any push,
  never as post-push cleanup.
- Irreversibility: every judgment here is made knowing a public push
  cannot be un-published — caching and forking happen the instant
  content lands.

## Explicitly Excluded

- ownership of implementation
- approval or gate authority
- change scheduling
- architecture authority
- writes to shared surfaces
- executing the publish — OM/Operator run the runbook; this SME reviews
  the manifest/neutralization/gate decisions feeding into it, it does
  not push

## Paired Roles

PM, SM, DM

## Paired RM Domain

export-privacy-practices

## Findings Packet Format

Findings-only Completion Handoff: findings, risks, options,
recommendation. No DECISION field, no NEXT OWNER authority — the
consulting role owns the decision.

## Escalation Triggers

- A neutralization token is found in already-published history —
  escalate to PM immediately; the exposure is irreversible and the
  response is Operator-level (caching/forking may already have
  occurred).
- A file with no manifest row is found in the export or upgrade path —
  escalate to PM before the export proceeds; an unmanifested file is
  invisible to the classification pipeline by design.
- Any of the three pre-push gates (test suite, gitleaks, forbidden-files
  check) fails — halt the publish and escalate to PM/OM; these are hard
  gates, not advisory.
- A question turns out to be about downstream upgrade *shape* (a
  template-replace file changing structure) rather than export
  classification — redirect to `upgrade-path` and say so explicitly.
