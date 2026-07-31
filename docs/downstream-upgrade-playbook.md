# Downstream Upgrade Playbook

Owner: `PM` by default

Use this playbook when a downstream project wants to adopt a newer version of
the minion template without overwriting project-specific state.

For first-time setup, use `docs/downstream-onboarding-playbook.md` instead.

## Goal

Make downstream upgrades reviewable by comparing:

1. the currently approved vendored template
2. the incoming template version
3. the live downstream files

## Detecting Upstream Drift (git tags)

Each template release is published as an annotated git tag (`v1.11.0`, `v1.11.1`,
`v1.12.0`, …), so a downstream can answer "is there a newer template than mine?"
cheaply, without cloning the whole repo and reading a file:

```
git ls-remote --tags <template-remote>
```

Compare the highest tag to the base-template version in your `minion-version.md`. To
see exactly what the template changed between your current base and the target, diff
the two tags directly:

```
git -C <template-clone> diff v1.11.1 v1.12.0
```

This replaces manual `.minions-template.next/` staging for the "what changed
upstream" half of the upgrade. Pair it with `tools/upgrade-classify.sh` (see Upgrade
Workflow) to turn that change-set into a classified, divergence-flagged work list in
one command.

## Version-Specific Required Changes

Some template versions introduce changes that a downstream project **must**
adopt for the baseline to stay coherent — not opt-in features. Check this
section for every version between the downstream's current base and the target
before classifying files in the Upgrade Workflow. Each entry labels its items
`REQUIRED`, `RECOMMENDED`, or `OPTIONAL`.

`REQUIRED` items frequently live in `manual-merge` files (e.g. `MEMORY.md`,
`.gitignore`) that no `template-replace` step touches, which means a hand merge
can silently drop them. Treat them as merge-blocking: the upgrade is not
complete until every `REQUIRED` item is confirmed present in the live repo. The
`Criticality` column in `docs/export-manifest.md` marks the `baseline` files
that most often carry these.

### 1.47.0 — PM judgment model + guard hardening + doc freshness

Three workstreams ship in this version. Summary of what each asks of you:

| Workstream | Your action |
| --- | --- |
| (a) PM judgment model | **REQUIRED** if you run the governance guard — merge two `MEMORY.md` blocks, take the doc with the suite |
| (b) Guard hardening | **REQUIRED-IF-ADOPTED** — only if you maintain your own `tools/*.sh` |
| (c) Doc freshness | **No required changes** |

---

**(a) PM judgment model (landscape routing + the creep check)**

**REQUIRED (unconditional, if you run the governance guard) — merge two new
`MEMORY.md` blocks, and take `docs/pm-judgment-model.md` with the test suite.**

Two forcing functions join the governance baseline: a **landscape routing map**
(a dispatch brief for multi-step work names its goal-clarity × solution-clarity
quadrant, and the quadrant selects the stage chain) and a **creep check** (the
single writer tests a packet — returned, or its own work — for Hope Creep and
Effort Creep at consolidation). Full model: the new `docs/pm-judgment-model.md`.

- **What converges on a per-manifest-row pass — no action:**
  `minions/roles/PM.md`'s one-line charter duty (`template-replace`, above the
  split-merge delimiter) and the new
  `tools/tests/governance-consistency.test.sh` checks (`template-replace`).
- **REQUIRED-TOGETHER — the doc and the suite must be taken as a pair.**
  `governance-consistency` now asserts `docs/pm-judgment-model.md` exists,
  because two `MEMORY.md` laws and PM's duty line point at it. Adopting the
  suite without the doc is a red guard. Same relationship as 1.29.0's
  `tools/sme-charter-check.sh` + its test.
- **What does NOT converge — the required merge:** `MEMORY.md` is
  `manual-merge`, so a hand merge can silently drop the two new blocks. Adopt
  both:
  1. In **Execution Quality**, the `Dispatch briefs declare the landscape
     quadrant` bullet, immediately after the existing tier-declaration bullet.
  2. In the **Completion Handoff Contract**, the creep-check block (Hope Creep
     / Effort Creep) between optional section 11 and `Hard rules:`.
- **Why it is merge-blocking if you run the guard:** the checks read
  `MEMORY.md` **and** `minions/roles/PM.md`. Because `PM.md` converges via
  `template-replace` while `MEMORY.md` does not, the exact failure mode of a
  dropped merge is a red `governance-consistency` run naming the `MEMORY.md`
  clauses only, with `PM.md` pointing at a law that is not present (verified
  empirically by the Upgrade-Path SME against a synthesized partial-adoption
  tree: five FAILs, all naming `MEMORY.md`). **Eight** assertions in total: the
  quadrant rule, PM's duty line, the RM-research-only clause, the
  not-a-fourth-hard-stop clause, the doc's existence, the creep-check
  instruction, `Hope Creep`, and `Effort Creep`.
- **Pre-upgrade name-collision check (only if you already have one):** a
  downstream that authored its own `docs/pm-judgment-model.md` must rename it
  before upgrading, or the `template-replace` row overwrites it. New name, so a
  collision is unlikely; same shape as the 1.36.0 / 1.37.0 / 1.43.0 / 1.44.0 /
  1.45.0 collision notes.
- **The checks are bounded to the template-owned half of each file.** They stop
  at the split-merge delimiter, so a token appearing only in your
  below-delimiter content cannot satisfy an upstream-law check. If you keep
  local notes about these rules below the delimiter, that is safe and will not
  mask a dropped merge — which was the point of the bounding.
- **No new hard-stop.** The count stays three. The unclear-goal branch is PM
  declining to dispatch un-scoped work — an existing charter duty, not an
  Operator interrupt. **Read the guard's coverage precisely:** it asserts the
  `NOT a fourth hard-stop` clause is *present*; nothing in the suite counts
  hard-stops. An edit that adds a fourth enumerated hard-stop while leaving
  that sentence intact stays green. The clause is a documented commitment with a
  drop-detector, not a mechanically enforced count.
- **The both-unclear cell is research-only, and that is a separation-of-duties
  boundary.** It routes to RM, whose findings return through PM; RM never hands
  work to an implementer. RM is the role *chartered* to ingest untrusted
  external content and the one pinned read-only for it. If you have customized
  RM's launchers, keep the pin intact (Claude pins `Read, Grep, Glob,
  WebSearch, WebFetch, Skill(deep-research)` — note the scoped `Skill(...)`,
  not a blanket grant; Copilot pins `[read, search, todo]`, and note that in
  that family every launcher pins `tools:`, so RM is distinguished by lacking
  `edit` rather than by being restricted at all; Codex has no tool-restriction
  field, so there it is binding prose only). The pin does not mean untrusted
  content reaches only RM — other roles can fetch too; it means the role we
  point at untrusted sources cannot write.
- Manifest: `docs/pm-judgment-model.md` is `yes` / `template-replace` /
  `feature` / PM. **`feature`, not `reference`** — the guard asserts the file
  exists, so it cannot be lazily adopted, and `reference` is defined as safe to
  lag. `docs/model-tiering.md` looks like the same structural position but sits
  outside the governance-scanned set (see the 1.33.0 entry), which is exactly
  what makes it safely lazy and this file not. Upgrade-Path SME ruling.
- Phase 2 (the Scope Triangle as Operator-facing trade-off vocabulary) is
  deliberately deferred and deliberately not stubbed.

---

**(b) Guard hardening — marker-vs-prose detector + bash-3.2 test pin**

**REQUIRED-IF-ADOPTED — only if you maintain your own `tools/*.sh`.** Everything
else converges; `tools/` and `tools/tests/` are `template-replace`.

- **A new live sweep can fail on YOUR scripts.**
  `tools/tests/governance-consistency.test.sh` gains a `bare_marker_index()`
  detector that sweeps **every `tools/*.sh`** and fails on an awk
  `index($N, "TOKEN")` bare-substring test against either structural marker
  token — `DOWNSTREAM CONTENT BELOW` or `STUB BOUNDARY`. If one of your own
  tools uses that shape, the guard goes red on **your** file after upgrading,
  not on a template file.
  - **The fix, and why it is worth taking rather than suppressing:** replace the
    bare substring test with the anchored pattern the template now uses
    everywhere — `$0 ~ /^[[:space:]]*<!--.*DOWNSTREAM CONTENT BELOW.*-->/`. A
    bare `index()` cannot distinguish a *live structural marker* from *prose
    about the marker*, which is a defect class with **four** recorded instances
    in this repo. Three failed closed (a spurious FAIL); the fourth, found in
    1.47.0's own review, failed **open**.
  - Scope is deliberately narrow: `tools/*.sh` only, not `tools/tests/*.sh`
    (which legitimately quote past-defect code in prose), and only the two known
    marker tokens rather than every conceivable substring test.
- **The bash-3.2 `PATH` pin now opens all 14 test suites** (`export
  PATH="/bin:$PATH"`, after `set -uo pipefail`). If you have added your own
  suites under `tools/tests/`, adopt the same pin so "verified on bash 3.2" is
  structural rather than dependent on the caller typing a PATH prefix.
  - **Read the pin's coverage precisely:** it redirects *child* `bash`
    invocations; it cannot change an already-running interpreter. In the three
    suites that make no child `bash` call — `governance-consistency`,
    `manifest-completeness`, `skill-scout` — the pin is inert, and those suites
    are 3.2-safe on their own merits (POSIX constructs) rather than because of
    it. Take the pin for the suites that exec a tool; do not read it as blanket
    3.2 coverage.
- No governance-token change, no new hard-stop, no manifest change.

---

**(c) Doc freshness — `docs/MECHANICS.md` code-map re-verification**

**No required changes.** Recorded so this version's entry is complete rather
than silently partial.

`docs/MECHANICS.md` is `seed only` / downstream-owned: the template re-verified
and re-stamped **its own** map, and nothing overwrites yours on a
per-manifest-row upgrade. (The standing CAUTION still applies: an upgrade that
copies `.minions-template/` wholesale into the live repo, rather than
per-manifest-row, clobbers your `docs/MECHANICS.md` with the template seed —
same as the 1.42.0 / 1.44.0 / 1.45.0 seed CAUTIONs.)

Worth knowing for your own map, since the rhythm is not obvious: a
`verified @ <sha>` stamp goes stale at **every** merge that touches a mapped
area, and `/onboard` will correctly report PARTIAL until someone re-confirms the
map and re-stamps. PARTIAL means "verify", not "wrong" — in both 1.47.0
re-stamps the inventories were already accurate and only behavior inside mapped
areas had changed.

### 1.46.0 — Seed-only marker adoption (unconditional if you run the test-suite guard) + `AI.md` / `docs/export-manifest.md` split-merge delimiter (boundary coverage)

**REQUIRED (unconditional, if you run the test-suite guard) — adopt the
`STUB BOUNDARY` marker on your five `seed only` files.** **REQUIRED-IF-ADOPTED**
— one-time `AI.md` / `docs/export-manifest.md` delimiter migration, only if
you have in-place overrides.

- **REQUIRED — your copy of every `seed only` file is missing its
  `STUB BOUNDARY` marker, and the new source-repo guard will fail on every
  one you have adopted.** The five paths are `feedback.md`, `ROADMAP.md`,
  `TODO.md`, `docs/MECHANICS.md`, and `docs/DESIGN.md` — every row in
  `docs/export-manifest.md` marked `seed only`. A downstream that upgraded
  from below 1.44.0 (`docs/MECHANICS.md`) or 1.45.0 (`docs/DESIGN.md`) and
  never adopted one of those two seeds gets a WARN-and-skip for that path,
  not a FAIL — `check_leg_s()` skips an absent seed-only path rather than
  failing on it. It still fails on `feedback.md`/`ROADMAP.md`/`TODO.md` (the
  older three), which every downstream carries regardless of base version.
  These ship
  `downstream-owned`/`template-replace`-adjacent (never overwritten on
  upgrade), so your existing copies are exactly this repo's content with
  **no marker at all** — the public-export strip (Step 2 item 4) *removes*
  the marker (and everything below it) from canonical's own seed-only files
  before publish; it never adds a marker to anything, and it never touches a
  downstream's live file, so no version of the template has ever shipped you
  this line. If your repo runs
  `tools/export-seed-check.sh --completeness .` (added at 1.28.1,
  hardened this release), it now asserts marker **presence** on the source
  side (Leg S) as well as absence on the export side (Leg E) — Leg S will
  FAIL on every `seed only` file you actually have today, on this upgrade,
  with no other action taken (an unadopted `docs/MECHANICS.md`/
  `docs/DESIGN.md` WARNs-and-skips instead, per above). This is not a
  hypothetical the guard might someday catch;
  it is the guard's designed behavior on every existing downstream, verified
  against the real v1.45.0 export tree (zero markers present). Because
  `tools/tests/` is itself `template-replace` and marketed as this
  template's regression harness, taking the updated
  `tools/tests/export-seed-check.test.sh` also brings three fixture cases
  that run the live repo root — those go red too, and editing the test to
  silence them is not a fix: the edit reverts on the next `tools/tests/`
  sync. **This makes the 1.28.1 entry's claim below FALSE for this version
  onward: "repos that do not publish a public mirror can skip
  `tools/export-seed-check.sh` entirely; it is inert" no longer holds once
  you take the completeness leg — it now fails on every seed-only file that
  never adopted the marker, whether or not you publish.**
  - **The fix:** (durable version of this instruction lives in the
    **`seed-only STUB BOUNDARY marker`** subsection under Manual-Merge
    Guidance below — this entry is the one-time adoption notice, not the
    permanent home for it) add the marker to each of the five files, at the
    point where the template's own seed content ends and your project's own
    content begins. The literal line the guard looks for (`STUB_PATTERN` in
    `tools/export-seed-check.sh`) is a line beginning with `<!-- STUB
    BOUNDARY` — copy the full block verbatim from this repo's own copy of
    the five files (or any current template checkout) so the surrounding
    prose matches; the opening line is:

    ```
    <!-- STUB BOUNDARY (not a split-merge delimiter): everything ABOVE is the
         seed that ships to downstreams and the public mirror; everything BELOW is
         this repo's own <content>, reset away at public-export Step 2 item 4. ...
    -->
    ```

    (fill `<content>` per file — "backlog", "direction", "captured
    feedback", "map", "values" — matching what `TODO.md`/`ROADMAP.md`/
    `feedback.md`/`docs/MECHANICS.md`/`docs/DESIGN.md` each say in this
    repo). This is a one-time, per-file edit; nothing about your existing
    content changes, and the marker is a comment, invisible to a normal
    reader.
  - **If you skip this:** every downstream that runs the guard suite goes
    red on upgrade, not "might" — the fixture completeness leg and the
    live-repo Leg S both fail deterministically on a marker-less seed-only
    file. There is no silent-pass path once the completeness leg is taken.
- `AI.md` and `docs/export-manifest.md` each become split-merge files: a
  template-shipped block above a new
  `<!-- ... DOWNSTREAM CONTENT BELOW ... -->` delimiter, plus a
  downstream-owned additive section below it (`## Template/Downstream
  Split` in `AI.md`; `## Downstream Additions (this repo)` in
  `docs/export-manifest.md`). **`docs/export-manifest.md` joins the
  registry-shape group** — like `minions/capabilities.md`,
  `minions/smes/README.md`, and `minions/review-matrix.md`: a template
  table above the marker, a downstream-owned table below it, header-only in
  the template. **`AI.md` does NOT** — it follows `MEMORY.md`'s shape
  instead: prose above the marker, and downstream-additive prose notes
  below it, not a table. There is no `## Local …` section to expect under
  `AI.md` after migrating; an adopter looking for one will find nothing
  there, and that is not a failed migration. Both files were previously
  undelimited, so a downstream override had no additive place to go — it
  had to be expressed as an in-place rewrite of a template sentence, or (for
  the manifest) a row hand-appended to the end of the shared table.
- **REQUIRED-IF-ADOPTED — check for in-place overrides in `AI.md` and
  `docs/export-manifest.md` BEFORE replacing:** if your copy of either file
  carries downstream-specific content expressed as an IN-PLACE REWRITE of a
  template sentence (not a new row or section appended at the end), you
  MUST find every such rewrite and move its substance BELOW the new
  delimiter as an additive note BEFORE taking the new template file —
  exactly as the 1.28.0 / 1.34.0 / 1.41.0 delimiter migrations required for
  the SME registry, matrix, and capabilities inventory. `AI.md` is
  `manual-merge`, not `template-replace` — but a downstream that instead
  replaces it mechanically anyway (a bulk `.minions-template/` copy, or a
  hand-merge that just takes the new file wholesale), in violation of its
  own manifest classification, gets exactly this failure: the file still
  parses, every guard still passes (nothing detects a semantic revert of
  prose that still reads as a valid template sentence), and the repo
  quietly reverts to template-default behavior while continuing to believe
  it runs its own rules. This is the exact failure mode reported in Gitea
  #56 §1: a downstream's simplified `feature→main` branching model (no
  staging tier), expressed as four in-place rewrites of `AI.md`'s branching
  prose, would have been silently reverted to the template's branching
  prose by this exact delimiter add, with every guard staying green — a
  careful adopter who checks the manifest row and sees `manual-merge` and
  concludes "the mechanical-replace warning doesn't apply to me, I merge by
  hand" is not safe either: a hand-merge that takes the incoming file
  wholesale rather than diffing sentence-by-sentence has the identical
  effect as a mechanical replace. Treat this as merge-blocking — the
  upgrade is not complete until you have confirmed, file by file, that no
  in-place override existed, or that every one found was relocated below
  the delimiter:
  - `AI.md`: the correct diff base is **your own recorded version**, not
    "the template's pre-1.46.0 copy" — a downstream sitting at, say, 1.38.0
    has six versions of undocumented template drift between its base and
    1.46.0, and diffing against "pre-1.46.0" makes every one of those six
    versions' legitimate template changes look like an in-place override.
    Read your base version from `minion-version.md` (the base-template
    component of `<base-template-version>-<downstream-version>`) — this is
    exactly what this playbook's own "Detecting Upstream Drift" section
    above already teaches you to do for any upgrade. Then use the
    mechanical detector the template already ships, though read its output
    for what it actually measures, not what the name suggests:
    `tools/upgrade-classify.sh --old <base-snapshot> --new <1.46-snapshot>
    --live <repo>` (`tools/upgrade-classify.sh:163`, `cmp -s "$LIVE/$f"
    "$OLD/$f"`) compares LIVE only against OLD — it never compares LIVE
    against NEW. `LIVE=diverged` therefore means only "live ≠ old", not "live
    has an in-place override of new template text" — it is a **candidate
    flag, not a signal**: every genuinely-adopted upstream change between
    your base and 1.46.0 that you already merged also reads `diverged`, so an
    `AI.md` row reading `manual-merge diverged` narrows where to look, it
    does not confirm an override. This is especially true for `AI.md`, whose
    pre-1.46.0 manifest row invited in-place preservation of downstream
    branching-model text — expect it to fire for essentially every downstream
    that ever touched `AI.md`. Read each flagged row by hand against the
    incoming template text to confirm before treating it as an override. The
    step that actually stages the base snapshot this comparison needs is
    Upgrade Workflow step 2 below (`.minions-template/`).
  - `docs/export-manifest.md`: any row hand-appended to the end of the
    shared Manifest table for a project-specific file is now out of place —
    cut it and paste it into the new "Downstream Additions" table below the
    delimiter, so the next `template-replace` does not require
    re-appending it.
- **Public-export note:** `tools/export-seed-check.sh` gained both files to
  its `WAIVER` list, not `SEED_FILES` — the below-delimiter section is
  downstream-reserved scaffolding that ships EMPTY in the canonical/template
  repo (unlike `minions/capabilities.md`'s Local Inventory, which holds this
  repo's own real rows that must be reset before a public export). WAIVER
  still enforces header-only below the delimiter, so if private content is
  ever added there in a locally-maintained public-export fork, the guard
  still catches it — the waiver is from the manual reset action, not from
  the check.
  - **Correction to the claim below:** "no new reset step is needed for
    these two files" is right for the *canonical/template* repo (which has
    nothing to reset because it never fills the below-delimiter section)
    but is backwards for a downstream that completed the
    REQUIRED-IF-ADOPTED migration above and now runs its own public-export
    mirror. Once you have moved real in-place overrides into
    `AI.md`'s below-delimiter section, that section is no longer
    empty-in-canonical — it is *your* real content, exactly like
    `minions/capabilities.md`'s Local Inventory. A WAIVER classification
    asserts the section stays header-only forever, so publishing with your
    override notes still in place under a `WAIVER` row fails gate 4 on the
    very content this entry told you to create. **The remedy, and which half
    is load-bearing:** moving the file between the `WAIVER` and `SEED_FILES`
    arrays changes nothing on its own — `is_classified()` accepts a file in
    either list identically. **Only actually resetting the below-delimiter
    section to header-only at Step 2 makes the gate pass.** An adopter who
    moves `AI.md` (and, if it grows real below-delimiter content, `MEMORY.md`
    and `docs/export-manifest.md` too) from `WAIVER` to `SEED_FILES` in
    `tools/export-seed-check.sh` and stops there is still red — the array
    move is bookkeeping that documents which files need a reset, not the
    reset itself. **Revert warning:** `tools/export-seed-check.sh` is
    `template-replace` — a downstream's hand-edited `SEED_FILES`/`WAIVER`
    arrays are silently reverted on the next `tools/` sync, exactly the
    argument this entry already makes about `tools/tests/` fixture edits
    above; re-apply your local array edits after every `tools/` re-vendor.
    They participate in the completeness leg
    (`export-seed-check.sh --completeness`) either way, but only within its
    scope: `check_completeness()` scopes to files the manifest marks
    `export=yes`, so a delimited file you never intend to export is not
    forced into `SEED_FILES`/`WAIVER` by this leg.
- **REQUIRED-IF-YOU-PUBLISH — the `SEED_ANCHORS` obligation is entirely new
  this release** (zero occurrences at v1.45.0, six now in
  `tools/export-seed-check.sh`). If you run your own public-export mirror,
  this adds two new hard gate-4 conditions you did not have before: (1) Step
  2 item 4 of `docs/runbooks/public-export.md` gains a mandatory
  above-marker anchor-reset sub-step (placeholder `verified @ <sha>` /
  `Mapped areas: <paths>`), not just the below-marker strip; (2)
  `anchor_violations()` FAILs when a `seed only` surface's above-marker
  anchor line is **absent altogether**, not only when it holds a real value.
  Concretely: a downstream that adopted `docs/MECHANICS.md` and wrote its own
  code map WITHOUT a `verified @ <sha>` line fails gate 4 on its very next
  publish — with nothing in the gate output pointing at `SEED_ANCHORS` as the
  fix. If you publish and have filled in your own `seed only` surfaces with
  above-marker repo-specific fields, add or confirm the matching
  `SEED_ANCHORS` row in `tools/export-seed-check.sh` before your next
  publish.
- **Also changed in 1.46.0, no dedicated migration needed — OPTIONAL /
  RECOMMENDED, adopt normally:**
  - `docs/runbooks/public-export.md` (`template-replace`, rated `reference`)
    — the seed-state guard (Step 3 gate 4) gains the anchor-reset assertion
    and the "Known limits" block documenting it; take the updated runbook if
    you publish.
  - `tools/export-seed-check.sh` (`template-replace`, rated `feature`) — the
    `SEED_ANCHORS` table, `anchor_violations()`, and the Leg S/Leg E
    marker-pair checks all land here; re-vendor together with the runbook
    above and `tools/tests/export-seed-check.test.sh`.
  - `docs/minion-prompt-modes.md` (`template-replace`, rated `baseline`) —
    **RECOMMENDED, and flagged separately because it is a baseline
    `template-replace` file changing real behavior, not just doc polish.**
    Onboarding Mode's code-map step gains a third `unverified` branch for an
    unresolvable `verified @ <sha>` anchor (report unverified, treat as no
    code map, proceed, instead of surfacing a raw `git` error) — and because
    `docs/MECHANICS.md` ships its placeholder `verified @ <sha>` anchor
    literally, **a fresh downstream clone hits this new branch by
    construction**, on the very first `/onboard` run. A baseline
    `template-replace` surface changing behavior with no
    Version-Specific-Required-Changes coverage is exactly the omission this
    milestone exists to close one level down from code; it is called out
    here explicitly so it does not recur as its own future finding.
  - `MEMORY.md` (`manual-merge`) — OPTIONAL. One pointer redirect only: the
    Coordination-Surface-Hygiene paragraph's dead `TODO.md` reference now
    points at `docs/archive-reporter-model.md`'s History section. No
    behavior change; take it on your next `MEMORY.md` merge pass.
  - `minions/roles/DM.md` (`template-replace`) — OPTIONAL. The Class-A file
    enumeration in DM's charter now matches `MEMORY.md`'s canonical list
    (adds `.github/copilot-instructions.md` and `minions/ARCHIVED.md`, a
    fifth enumeration site v1.36.1's sweep missed). Arrives automatically on
    a normal charter sync.
  - `docs/skill-adoption-model.md` (`template-replace`) — OPTIONAL. Its
    pointer to the maintainer-local design-of-record spec now states
    explicitly that the pointer resolves only in the template maintainer's
    own checkout (the spec lives under `do-not-export` `docs/superpowers/`),
    never in an export tree or downstream clone, and that this model doc is
    the only copy a downstream needs. Documentation-only.
- **`CLAUDE.md` doc-sync gap, closed this release:** the 1.43.0 entry below
  enumerated `MEMORY.md`, `AI.md`, `AGENTS.md`, and
  `.github/copilot-instructions.md` as gaining the archive-reporter
  partial-surface note, and omitted `CLAUDE.md` — `CLAUDE.md` never
  received it, on any release between 1.43.0 and 1.45.0. This is exactly
  the failure mode this milestone targets: a correct code/doc change (the
  archive reporter) whose downstream-facing record silently dropped one of
  its four target surfaces. **REQUIRED-IF-YOU-CUSTOMIZED — if your
  `CLAUDE.md` never carried the archive-reporter partial-surface note
  (check for a paragraph mentioning `tools/archive-reporter.sh` near the
  top Operating Rules), add it now**, matching the note already present in
  `AI.md` / `AGENTS.md` / `.github/copilot-instructions.md`: `minions/mail/`,
  `minions/plans/`, and `minions/chat/` may be partial once pruning has
  run; `minions/ARCHIVED.md` indexes migrated units and git history stays
  the durable copy. The 1.43.0 entry below is corrected in place with a
  "(corrected in 1.46.0)" marker rather than treated as append-only, since
  that entry was already touched by this diff.
- No governance-token change, no new hard-stop.

### 1.45.0 — Design/UX SME (first product-domain reviewer in the Default Bench)

**OPTIONAL — additive.**

A 7th default-bench SME, `design-ux` (UI/UX craft: visual, interaction, and
accessibility review against `docs/DESIGN.md`), joins the Default Bench.

- Its charter (`minions/smes/design-ux.md`) and its `sme-design-ux`
  launchers (Claude/Codex/Copilot) are `template-replace` and converge on
  sync. Its registry row (`minions/smes/README.md`) and its 3 routing rows
  (`minions/review-matrix.md`) land above the split-merge delimiter and
  converge on sync too.
- **Pre-upgrade name-collision check (only if you already have one):** a
  downstream that authored its own `design-ux.md` charter or a
  `sme-design-ux` launcher must rename it before upgrading, or the
  `template-replace` globs overwrite it. Same shape as the 1.34.0 / 1.36.0 /
  1.37.0 / 1.43.0 / 1.44.0 collision notes.
- **`docs/DESIGN.md` is `seed only`, downstream-owned** — structure only, a
  placeholder shape. Nothing overwrites an existing downstream
  `docs/DESIGN.md` on a normal per-manifest-row upgrade. **CAUTION —
  snapshot-wide copy:** an upgrade that copies `.minions-template/` wholesale
  into the live repo, rather than per-manifest-row, will clobber an existing
  downstream `docs/DESIGN.md` with the template seed — same as the 1.42.0 /
  1.44.0 seed CAUTIONs.
- Manifest: the charter and 3 launchers are covered by the existing
  `minions/smes/*.md` and `sme-*` globs; `docs/DESIGN.md` gets its own
  seed-only row.
- No governance-token change, no new hard-stop.

### 1.44.0 — session onboarding (`/onboard` + `docs/MECHANICS.md` code map)

**OPTIONAL — additive; adopting changes nothing until you run `/onboard`.**

New Onboarding Mode (`docs/minion-prompt-modes.md`) plus its Claude launcher
(`.claude/commands/onboard.md`) execute the CLAUDE.md read-chain, read
`docs/MECHANICS.md` (flagging staleness), check `minions/handoffs/` for a
pending snapshot (absorb, hold the delete), surface `MINION_*` gates, and
emit a ready-state report. It is read-only end to end — nothing changes
until you actually invoke `/onboard`.

- `MEMORY.md` and `minions/roles/AM.md` carry it: `AM.md` is
  `template-replace` and converges on sync (it gains the `docs/MECHANICS.md`
  ownership + refresh duty); `MEMORY.md` is `manual-merge` — hand-carry the
  short Session Onboarding pointer paragraph.
- `docs/MECHANICS.md` is **seed-only, downstream-owned** — pre-classified in
  `docs/export-manifest.md` so the `manifest-completeness` guard stays green
  the first time a downstream commits its own filled-in copy; the template
  ships only the structure and a `verified @ <sha>` staleness convention, no
  project content.
- The new `.claude/commands/onboard.md` launcher and the Onboarding Mode
  section in `docs/minion-prompt-modes.md` are `template-replace` and arrive
  on a normal sync; `minions/capabilities.md` gains a Default-Capabilities row
  (also `template-replace`).
- **Pre-upgrade name-collision check (only if you already have one):** a
  downstream that authored its own `.claude/commands/onboard.md` must rename
  it before upgrading — `template-replace` overwrites it. Same shape as the
  1.36.0 / 1.37.0 / 1.43.0 collision notes.
- **`docs/MECHANICS.md` is `downstream-owned`, not a rename case.** If you
  already have a file at this path, nothing overwrites it on a normal
  per-manifest-row upgrade — keep it as-is. The actual risk is the same as
  the 1.42.0 `TODO.md`/`ROADMAP.md` **CAUTION — snapshot-wide copy**: an
  upgrade that copies `.minions-template/` wholesale into the live repo,
  rather than per-manifest-row, will clobber an existing downstream
  `docs/MECHANICS.md` with the template seed. If you have neither, adopt the
  seed and fill it in. If you upgrade by bulk copy, exclude this path
  explicitly, or diff before overwriting.
- No governance-token change, no new hard-stop.

### 1.43.0 — archive reporter (read-only repo-thinning tool)

**OPTIONAL — no required changes; adopt normally.**

**Tag-history note:** `v1.42.0` and `v1.43.0` tag the same commit (`57751cb`),
so `git diff v1.42.0..v1.43.0` is empty. A tag-driven upgrade classifier that
walks tags in order will see `v1.43.0` as a phantom release with no content —
that is expected, not a sign your diff or checkout is broken; treat the two
tags' content as identical and read both playbook entries.

New `tools/archive-reporter.sh` (+ `tools/tests/archive-reporter.test.sh`,
`docs/archive-reporter-model.md`) is a **read-only** tool: it lists closed and
aged coordination units (`minions/mail/`, `minions/plans/`, `minions/chat/`)
and **prints** `git rm` + `minions/ARCHIVED.md` row commands for a human or
orchestrator to run at a milestone boundary. It never mutates the tree, has no
`run` subcommand, and needs no `MINION_*` gate — so adopting it changes nothing
until you choose to run it, and running it only prints suggestions.

- All three new files are `template-replace` (`tools/archive-reporter.sh` and
  `docs/archive-reporter-model.md` as exact rows; the test via the existing
  `tools/tests/` directory row) and arrive on a normal template sync.
- **Pre-upgrade name-collision check (only if you already have one):** a
  downstream that authored its own `tools/archive-reporter.sh` or
  `tools/tests/archive-reporter.test.sh` must rename it before upgrading, or
  the template-replace overwrites it. New name, so a collision is unlikely; the
  check is the same shape as the 1.36.0 / 1.37.0 collision notes.
- Governance surfaces: `minions/roles/PM.md` (milestone-run duty) and
  `minions/capabilities.md` (a Default-Capabilities row, above the 1.41.0
  split-merge delimiter — complete that delimiter migration first if jumping
  from ≤1.40) are `template-replace` and converge on sync. The rest are
  `manual-merge` and must be hand-carried: `MEMORY.md` gains a
  Coordination-Surface Hygiene paragraph, and `AI.md` / `AGENTS.md` /
  `.github/copilot-instructions.md` / `CLAUDE.md` each gain a note that
  `minions/mail|plans|chat` may be partial once pruning has run.
  **(Corrected in 1.46.0: this entry originally omitted `CLAUDE.md` from that
  list — the note never reached it until the 1.46.0 entry above closed the
  gap. If you hand-merged this entry as originally written, check `CLAUDE.md`
  now.)** These notes are informational — a downstream that never runs the
  reporter has complete surfaces regardless — so dropping one on a hand-merge
  has no coherence consequence.
- `minions/ARCHIVED.md` is **not** shipped by this version — the reporter only
  prints the row for a human to append; the file is created downstream on first
  use. The manifest already classifies it (`no` / `downstream-owned`, Class A),
  so your `manifest-completeness` guard stays green the first time the reporter's
  row is appended and committed — you never add a manifest row by hand. (The
  automated variant that would create/append it is deferred.)
- No governance-token change, no new hard-stop, no behavior change unless you
  run the tool.

### 1.42.0 — `TODO.md` / `ROADMAP.md` ship as `seed only`

**OPTIONAL — no required changes; one CAUTION.**

`MEMORY.md` has always required `README.md`, `ROADMAP.md`, and `TODO.md`, but
the template shipped only the first — the manifest classed the other two
"required by the workflow but not shipped as a template file", so every adopter
invented its own format. The template now ships both as `seed only`
(structure, status/horizon conventions, ownership and Class-A notes; no
template content), joining `feedback.md` in that class. A new **Initial Export
Meanings** legend in `docs/export-manifest.md` defines the class.

- **Upgrade strategy is unchanged (`downstream-owned`).** Nothing overwrites a
  downstream `TODO.md` or `ROADMAP.md` on upgrade. A downstream that already
  authored either is unaffected and need do nothing.
- **If you have neither**, adopt the seeds and fill them in — see
  `docs/downstream-onboarding-playbook.md` step 7a. Optional, but it is the
  cheapest way to satisfy a `MEMORY.md` requirement you already carry.
- **CAUTION — snapshot-wide copy.** These are the first `seed only` files at
  paths a downstream commonly already occupies. The manifest row protects you,
  but only if consulted: an upgrade that copies `.minions-template/` wholesale
  into the live repo, rather than per-manifest-row, will clobber an existing
  downstream `TODO.md`/`ROADMAP.md` with the template seed. Same failure shape
  as the 1.34.0 SME name-collision check. If you upgrade by bulk copy, exclude
  these two paths explicitly, or diff before overwriting.
- **Public-export adopters:** if you run your own public mirror, the export
  runbook gained a Step 1 item 2a (copy `seed only` rows explicitly) and a
  marker-presence check that catches a skipped stub reset — originally a
  standalone Step 3 gate 5 grep, since folded into the single Step 3 gate 4
  `tools/export-seed-check.sh` invocation. Adopt the current runbook shape
  if you publish; skip if you do not.

### 1.41.0 — capabilities.md split-merge delimiter

OPTIONAL structure change with a REQUIRED-IF-ADOPTED one-time migration.

- `minions/capabilities.md` becomes a split-merge file (like
  `minions/smes/README.md`): a template-shipped **Default Capabilities** block
  above a new delimiter (`template-replace` — the `tools/second-brain.sh` and
  repowise rows now ship and upgrade, so a template capability-row change
  propagates) plus a downstream-owned **Local Inventory** below it. The file was
  `downstream-owned` before, so template capability-row updates never reached a
  customized copy (the #45 gap — a downstream that had DROPPED the
  `second-brain.sh` row while still running the capability silently missed every
  later update to it).
- **REQUIRED-IF-ADOPTED — one-time delimiter migration:** if your
  `minions/capabilities.md` is a filled/customized copy (no delimiter under
  1.40.0 and earlier), move your own capability rows BELOW the new
  `<!-- ... DOWNSTREAM CONTENT BELOW ... -->` delimiter (into "Local Inventory")
  ONCE before taking the new template file — exactly as 1.28.0 / 1.34.0 required
  for the SME registry and matrix. After the one-time move, future upgrades are
  mechanical replace-above; a naive whole-file `template-replace` WITHOUT this
  migration drops your filled inventory, so treat it as merge-blocking. This
  supersedes the 1.23.0 "upgrades never overwrite the filled inventory"
  guarantee for `capabilities.md` — above the delimiter now ships and upgrades.
- **REQUIRED-IF-ADOPTED — dedup the now-template-shipped rows:** the pre-1.41
  template shipped `tools/second-brain.sh` and `repowise` as **real rows** in the
  (then downstream-owned) Inventory, so a vendored downstream copy carries them.
  Those two rows now live in **Default Capabilities** above the delimiter — so
  when you move your rows down, DELETE your copies of `tools/second-brain.sh` and
  `repowise` from the moved set, or you double-register them. This is the same
  one-time dedup the 1.34.0 verbatim-bench entry required; a naive move without
  it leaves two identical rows for each.
- **RECOMMENDED — capture a non-default status as an override:** template-
  replace-above overwrites the **Status** cell of a Default-Capabilities row on
  every upgrade (it ships `second-brain.sh` as `active`). If your real status
  differs (e.g. you run with `MINION_SECONDBRAIN` off → `deferred`/`absent`), add
  a status-override row for it in your Local Inventory below the delimiter as
  part of the one-time move, and/or record adoption in
  `docs/operator-onboarding-checklist.md` (Optional Layers). Only the row's
  DESCRIPTION is template-owned; the status stays yours.
- **Public-export note:** `export-seed-check.sh` gained `minions/capabilities.md`
  as a `SEED_FILES` entry. If you maintain a local public-mirror export, reset
  the below-delimiter Local Inventory to header-only at export (same handling as
  the SME registry/matrix). No governance-token change, no new hard-stop.

### 1.40.0 — second-brain frontmatter YAML safety + migrate-frontmatter

No required changes — adopt normally. `capture`/`capture-batch` now write
`title:`/`source:` as quoted YAML scalars and map `:` → `/` in tags (Obsidian
safety); a new `migrate-frontmatter` subcommand fixes existing notes. All in the
optional `MINION_SECONDBRAIN` layer, `template-replace`. No governance-token /
hard-stop change.

### 1.39.1 — upgrade-playbook + SME-checklist completeness

No required changes — adopt normally. Docs-only: the upgrade playbook gained the
missing 1.38.0/1.39.0 entries and a 1.34.0 verbatim-bench dedup bullet; the
Adding-an-SME checklist and `export-manifest.md` gained the private-SME
`do-not-export` guidance. Nothing to merge unless you maintain a public export.

### 1.39.0 — second-brain capture-batch

No required changes — adopt normally. Additive `capture-batch` subcommand in
the optional `MINION_SECONDBRAIN` layer; `tools/second-brain.sh` plus its tests
and docs are `template-replace`. No governance-token / hard-stop change.

### 1.38.0 — second-brain block-list tags + migrate-tags; locale test fix

No required changes — adopt normally. `capture` now emits Obsidian block-list
frontmatter tags and a new `migrate-tags` subcommand arrives (optional
`MINION_SECONDBRAIN` layer, `template-replace`). Also re-vendor
`tools/tests/governance-consistency.test.sh`: it stops false-failing on macOS's
default UTF-8 locale (a `sort` pinned `LC_ALL=C`) — a baseline governance-guard
portability fix that benefits **every** downstream regardless of whether it uses
the `MINION_SECONDBRAIN` layer, so don't skim past it as second-brain-only. No
governance-token / hard-stop change.

### 1.37.0 — Instruction-surface size budgets (whole-file word guard)

OPTIONAL feature with a REQUIRED awareness item.

- New `tools/tests/instruction-size.test.sh` (`template-replace`): a
  whole-file word-budget guard for the instruction/bootstrap surface
  (`CLAUDE.md`, `AGENTS.md`, `MEMORY.md`, role charters, SME files, etc).
  Budgets apply to the WHOLE file — below-delimiter, downstream-owned
  content counts too, because whole-file size is the token cost every
  session pays at bootstrap.
- New `docs/instruction-size-budgets.md` (`template-replace` above the
  delimiter, `manual-merge` below it): the canonical default-budget
  reference plus a downstream-owned `## Local Overrides` section. The
  override is consulted fail-open — an absent or malformed override always
  falls back to template defaults — and it can only raise, set, or
  deliberately tighten a budget; it can never remove a surface from
  checking or block the guard.
- MEMORY.md gains the "Instruction-Surface Size Budgets" subsection
  documenting the promote-don't-delete overflow protocol (relocate
  overflowing content to its canonical home and leave a pointer, never
  delete it to fit) plus the matching stub lifecycle for `feedback.md`
  (promote → condense to pointer stub → prune aged stubs).
- **REQUIRED awareness:** the guard can go **RED on a large repo's first
  post-upgrade run**. No prior template test ever evaluated
  downstream-owned, below-delimiter bytes, so a repo that has grown its
  `CLAUDE.md`, `MEMORY.md`, or other bootstrap surfaces heavily since
  onboarding may now measure over budget for the first time. Run
  `tools/tests/instruction-size.test.sh --report` before deciding — it
  prints a percent-of-budget pressure table for every surface without
  failing, so you can see how close you are before acting. The **only**
  sanctioned responses to a RED surface are (1) add an override row in the
  `## Local Overrides` section of `docs/instruction-size-budgets.md`, or
  (2) promote the overflowing content to its canonical home per MEMORY.md's
  promote-don't-delete protocol. **Never** delete or skip the test to make
  it pass.
- Overrides live below `docs/instruction-size-budgets.md`'s delimiter and
  survive upgrades — but only if you take the file as a **replace-above,
  merge-below** file, same as every other split-merge file. A naive
  whole-file copy from the incoming template wipes your overrides.
- **New-file collision note:** if your repo already has
  `docs/instruction-size-budgets.md` or
  `tools/tests/instruction-size.test.sh`, rename them before upgrading —
  `template-replace` overwrites the parts of each that are template-owned.
- **Public-export note:** `export-seed-check.sh` gained a `WAIVER` entry
  for this surface. If you maintain a local public-mirror export, re-apply
  your local `SEED`/`WAIVER` extensions on top, and reset the filled
  `## Local Overrides` section of `docs/instruction-size-budgets.md` for
  public export — same handling as `MEMORY.md`'s local section.
- Downstreams that already applied interim size fixes (local ceilings,
  ad hoc maintenance protocols for instruction-file bloat) should reconcile
  them with this shipped mechanism — move the local rule's substance into
  an override row or a promotion, and mark the corresponding local
  `feedback.md` entry promoted/closed.
- No governance-token change, no new hard-stop.

### 1.36.1 — Pre-export audit doc fixes

No required changes — adopt normally. Two docs-only fixes from the
pre-export drift audit of the v1.36.0 tree: `minions/smes/cross-family-launcher.md`'s
stale bench count (18-file parity: 6 SMEs × 3 families, not 15/5) and the
addition of `.github/copilot-instructions.md` to the Class A enumeration in
`AI.md`, `docs/branching-and-release-model.md`, `MEMORY.md`, and
`docs/export-manifest.md` (all `template-replace`/`manual-merge` per their
existing manifest class). All changed files converge on upgrade with the
normal replace/merge for their class; no governance-token change, no new
hard-stop.

### 1.36.0 — Adoption-record cross-check for remote-mutating layer tools

OPTIONAL (opt-in safety control) — no behavior change unless you opt in.

- New shared helper `tools/layer-adopted.sh` (`template-replace`): a
  fail-open cross-check against the `adopted:` token in
  `docs/operator-onboarding-checklist.md`. The `MINION_*` env gate stays
  primary — this record can only **add** a no-op; it can never enable a
  gate-off layer or block a call on its own. `tools/issue-sync.sh` and
  `tools/issue-board-bootstrap.sh` consult it today, and both also gained
  `-h`/`--help` guards. These two tools, `MEMORY.md`'s Optional Layers
  convention bullet, and `docs/issue-mirror-model.md` converge on upgrade
  automatically.
- **OPTIONAL** — reformat your Optional Layers checklist lines to activate
  the cross-check. The checklist is `manual-merge`, so the new `adopted:`
  token does **not** arrive automatically: an unconverted freeform line
  reads as indeterminate, and the env gate alone decides — exactly as
  before (safe). To activate, hand-merge the new intro paragraph and
  rewrite each layer line with `adopted: on|off|unset`.
- Repos running a machine-global `MINION_ISSUES=on` that do **not** want
  the issue mirror active in a given repo **should** set `adopted: off`
  there — this is the protection that motivated issue #32, and it
  supersedes any manual do-not-invoke note you may have relied on before.
- **New-file collision note:** if your repo already has a
  `tools/layer-adopted.sh`, rename it before upgrading — `template-replace`
  overwrites it.
- `tools/issue-sync.sh` / `tools/issue-board-bootstrap.sh` remain
  `template-replace`; re-apply any local patches on top after upgrading.
- No governance-token change, no new hard-stop.

### 1.35.0 — Tier declaration at dispatch; CM effort lock retired

OPTIONAL (docs- and one launcher-frontmatter field) — template-managed
surfaces converge on upgrade; one deliberate behavior change to know about.

- `MEMORY.md` (Execution Quality) gains a dispatch-brief bullet — "Dispatch
  briefs declare the capability tier" — naming model tier and effort per
  `docs/model-tiering.md` and the actual activity, not the role name;
  `minions/roles/PM.md` gains a matching PM charter duty. `docs/model-tiering.md`'s
  "The effort dial" section is rewritten from "pins enforce" to "orchestrator
  declares, pins are fallback defaults." `INIT.md`'s model-tiering bootstrap
  line now points at the normative rule in `MEMORY.md` rather than just the
  advisory doc. These land via `template-replace`; a downstream converges on
  them automatically.
- **Behavior change — `cm`'s Claude-launcher effort lock is retired.**
  `.claude/agents/cm.md` no longer pins `effort: xhigh`; `model: opus` stays
  as a fail-safe default. Effort for `cm` (including review/final-gate
  passes) is now declared at dispatch instead of pinned. If your downstream
  wants the old locked behavior back, **re-pin `effort: xhigh` locally**
  (below-delimiter/local config) — the template will not do this for you.
  Otherwise `cm` effort now follows the session's inherited effort or the
  orchestrator's per-dispatch declaration. `.codex/agents/cm.toml`'s
  `model_reasoning_effort = "high"` is unchanged (Codex has no per-dispatch
  override).
- **Guard note:** a new governance guard in
  `tools/tests/governance-consistency.test.sh` anchors on the tier-declaration
  law's presence in `MEMORY.md` and `minions/roles/PM.md`. A downstream edit
  that rewords the `MEMORY.md` tier-declaration bullet will fail this guard —
  that is intended, not a bug; restore the anchor phrasing or update the guard
  deliberately.
- No governance-token change, no new hard-stop.

### 1.34.0 — Default SME bench (6 infrastructure SMEs ship as template defaults)

OPTIONAL (additive) with a REQUIRED pre-upgrade name-collision check and a
REQUIRED-IF-ADOPTED verbatim-bench dedup (both below).

- The 6 generic infrastructure SMEs — `governance-invariant`,
  `cross-family-launcher`, `export-privacy`, `upgrade-path`,
  `shell-test-harness`, `skill-provenance` — now ship as a template DEFAULT
  bench: their charters (`minions/smes/*.md`) and `sme-*` launchers (Claude /
  Codex / Copilot) are reclassified `template-replace`, and their registry /
  matrix rows move ABOVE the split-merge delimiter in `minions/smes/README.md`
  and `minions/review-matrix.md` (template-owned; ship and upgrade). This
  reverses the earlier stance (see 1.28.0) that the SME bench was
  maintainer-local and each downstream authored its own from scratch.
- On upgrade, a downstream that had an empty bench simply RECEIVES the 6
  charters + 18 launchers + the default registry/matrix rows above the
  delimiter. Your own SMEs stay in the Local Registry / Local Matrix BELOW the
  delimiter and are untouched.
- **REQUIRED — pre-upgrade name-collision check:** if you authored your own SME
  whose charter filename matches a default (`governance-invariant.md`,
  `cross-family-launcher.md`, `export-privacy.md`, `upgrade-path.md`,
  `shell-test-harness.md`, `skill-provenance.md`) or a `sme-*` launcher of the
  same name, RENAME it before upgrading — the `template-replace` glob will
  otherwise overwrite it with the default. Downstream SMEs with distinct names
  are unaffected.
- **REQUIRED-IF-ADOPTED — one-time dedup of a verbatim-adopted bench:** if you
  earlier adopted the canonical bench VERBATIM into your Local Registry / Local
  Matrix BELOW the delimiter (against the 1.28.0 "build your own; do not adopt
  verbatim" guidance), the mechanical split-merge now ships those same default
  rows ABOVE the delimiter while your verbatim copies remain BELOW — leaving
  every default-bench SME double-registered. ONCE, before taking the new
  `minions/smes/README.md` and `minions/review-matrix.md`, delete the duplicated
  default rows from your Local Registry / Local Matrix, keeping only genuinely
  downstream-authored rows below the delimiter. This mirrors the 1.28.0 one-time
  delimiter move; a naive whole-file merge leaves the duplicates in place.
- **CAUTION — private downstream SMEs are now exportable-by-default:** because
  this version reclassifies `minions/smes/*.md` and the `sme-*` launchers as
  `template-replace` (matched by glob), a PRIVATE, downstream-authored SME whose
  files match those globs is now swept into a public-mirror export by default.
  If you maintain a public export and have private SMEs, mark each private
  charter and its launchers `do-not-export` before your next export, AND sweep
  the SME's key/name as a neutralization token tree-wide (a paired-role,
  routing, or `capabilities.md` reference can still echo the private name even
  once the files are excluded) — see the Adding-an-SME checklist in
  `minions/smes/README.md`. Exclusion is operator-enforced at export Step 1 (the
  more-specific `do-not-export` row wins over the glob; there is no automated
  filter), so apply it deliberately. The public-export seed-state reset covers
  only the below-delimiter Local Registry **and** Local Matrix rows, not the
  charter / launcher files or any name echo elsewhere.

### 1.33.0 — Effort calibration + external-capability scouting

OPTIONAL — additive/advisory only; nothing merge-blocking, no new guard, no
governance-token change.

- OPTIONAL: `docs/effort-calibration.md` (new prototype doc, explicitly
  outside the governance-scanned invariant set — like `docs/model-tiering.md`
  itself, `tools/tests/governance-consistency.test.sh` does not check it) and
  its "The effort dial" section added to `docs/model-tiering.md`
  (`template-replace`). A downstream pinned to one model at one effort loses
  nothing by ignoring both docs.
- OPTIONAL: `effort:` (Claude) / `model_reasoning_effort` (Codex) frontmatter
  pins added across the seven role launchers, the `coder`/`tester` `/ship`
  stage launchers, and the six SME launchers, in both functional families.
  These are launcher-frontmatter fields, not baseline/governance surfaces — a
  downstream may take them as-is, override any pin, or ignore the field
  entirely; nothing enforces compliance.
- OPTIONAL: one new `absent`-status connector row in `minions/capabilities.md`
  (repowise — codebase-intelligence over MCP, AGPL-3.0, connector-only per its
  license, never vendored). Informational; no adoption, no code added.
- NOT merge-blocking: no `skills_wired`-style guard was added for this
  version, no Class-A entry-point pointer was added, and no hard-stop framing
  changed. A downstream syncing this version and taking none of the above
  passes every existing guard unchanged.

### 1.32.0 — Skill adoption layer (optional `MINION_SKILLS`, Scout + Airlock)

OPTIONAL layer, but with a REQUIRED / merge-blocking wiring floor: the
capability is adopt-if-used, yet its unconditional guardrails and their
`skills_wired` governance guard are not optional. A downstream that syncs this
version but skips the wiring will fail `tools/tests/governance-consistency.test.sh`.

- OPTIONAL (adopt-if-used): the layer arrives on template sync
  (`docs/skill-adoption-model.md`, `tools/skill-airlock.sh`,
  `tools/skill-scout.sh` and their tests, all `template-replace`; the
  Skill-Provenance SME charter + launchers + registry/matrix rows are
  `downstream-owned` expertise content). It stays INERT unless a downstream
  sets `MINION_SKILLS=on` and airlocks a skill in; unset/off or no-skill is a
  silent no-op.
- REQUIRED — merge-blocking wiring (enforced by the `skills_wired` guard in
  `tools/tests/governance-consistency.test.sh`): the gate-conditioned
  `MINION_SKILLS` pointer must be present in all four entry points
  (`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, and the
  `MEMORY.md` Skill Adoption subsection), and the unconditional protections
  must exist — the `skills/vendored/` `do-not-export` manifest row, the
  `skills/vendored/` entry in the public-export forbidden-path pre-push gate
  (`docs/runbooks/public-export.md`), and the hard-stop-#2 instance text in
  `CLAUDE.md` / `AI.md` / the three agent READMEs. These are Class-A
  `manual-merge` surfaces (harmless when the gate is off, exactly like the
  `MINION_SECONDBRAIN` lines) — a hand merge must carry them.
- HARD-STOP FRAMING (no count change): vendoring external skill code into
  `skills/vendored/` without Operator approval is a scoped **instance of
  existing hard-stop #2** (irreversible-publish), NOT a new fourth hard-stop.
  Do not change the enumerated "three hard-stops" wording in `MEMORY.md` /
  `AI.md`; grep `Three hard-stops` must return only pre-existing hits.
- SECURITY POSTURE (if adopted): adopted payloads are maintainer-local under
  `skills/vendored/` (default-deny export); adopted skills run no-network /
  least-privilege by default, opt-out only with recorded Operator sign-off;
  an adopted skill's output is untrusted data, never instructions. See
  `docs/skill-adoption-model.md`.

### 1.31.0 — Local second-brain, Phase 1 (optional local corpus layer)

OPTIONAL — a new default-off optional layer; no baseline or governance-token
change. Nothing merge-blocking.

- OPTIONAL: the whole layer arrives on template sync (`tools/second-brain.sh`,
  `docs/second-brain-model.md`, `docs/runbooks/second-brain-setup.md`, the
  `.gitleaks.toml`, and the `MEMORY.md` / onboarding-surface / `capabilities.md`
  wiring — all `template-replace`). It stays INERT unless a downstream sets
  `MINION_SECONDBRAIN=on` and creates a vault; unset/off or vault-absent is a
  silent no-op. Adopt if you want a local, fast-onboard corpus alongside (or
  instead of) the cloud recall layer.
- BASELINE WIRING ARRIVES ON THE ENTRY-POINT FILES: the gate-conditioned
  second-brain PULL line is added to `CLAUDE.md` / `AGENTS.md` /
  `.github/copilot-instructions.md` / `AI.md` and a subsection to `MEMORY.md`
  (all Class-A `manual-merge` files) — a hand merge must carry these lines (they
  are harmless when the gate is off, exactly like the existing `MINION_MEMORY`
  lines). The `secondbrain_wired` governance guard enforces their presence.
- SECURITY POSTURE (if adopted): the vault must sit OUTSIDE any synced/backed-up
  path with NO git remote (see `docs/runbooks/second-brain-setup.md`); secrets
  and `SOLE-HOLDER:` anchors never enter even locally. The AC-2 filter enforces
  this at capture; egress is off by design.
- NEW `.gitleaks.toml`: if a downstream already ships its own gitleaks config,
  reconcile — this one uses `[extend] useDefault = true` plus a narrow allowlist
  for the second-brain test fixtures.
- NOTHING in this entry is merge-blocking.

### 1.30.1 — Bug-scrub follow-ups (issue-sync/upgrade-classify fixes, cross-family launchers, guards)

OPTIONAL — bug fixes + launcher parity + test-guard hardening; no baseline or
governance-token change. Nothing merge-blocking.

- FIXES (arrive on template sync; both `template-replace`): `tools/issue-sync.sh`
  (`github_edit` now re-applies labels via `--add-label`) and
  `tools/upgrade-classify.sh` (exit-4 UNMANIFESTED-CHANGE no longer masked by
  exit-3 LIVE=error when both fire in one run). Drop-in corrections. A downstream
  keying CI on `upgrade-classify` exit 3 vs 4 should note that 4 now wins when
  both conditions co-occur (both warnings still print).
- OPTIONAL: the four cross-family stage launchers
  (`.codex/agents/{coder,tester}.toml`, `.github/agents/{coder,tester}.agent.md`)
  and their four `docs/export-manifest.md` rows. Advisory-tier outside Claude (no
  per-launcher model selector, no `/ship` — spawned manually). All additive; a
  downstream already shipping same-named launchers should reconcile before
  syncing.
- TEST-GUARD ONLY: `tools/tests/governance-consistency.test.sh` (cross-family
  coder/tester parity + stale-claim guard) and
  `tools/tests/fixtures/make-fake-provider.sh` (flag-faithful `gh` fake)
  strengthen the suite; no downstream action beyond taking the updated files.
- NOTHING in this entry is merge-blocking.

### 1.30.0 — Model-tiering Phase 2 (coder/tester stage launchers)

OPTIONAL — Claude-only, adopt-if-using-`/ship`; no baseline or governance-token
change.

- OPTIONAL: the two Mid-tier (`model: sonnet`) pipeline stage launchers
  `.claude/agents/coder.md` (implement-only, `/ship` stage 3) and
  `.claude/agents/tester.md` (write-and-run-tests-only, `/ship` stage 4), the
  `.claude/commands/ship.md` preference update, and the two new
  `docs/export-manifest.md` rows. Adopt if the project runs `/ship` on Claude
  Code and wants the bounded implement/test stages at Mid tier while planning
  (AM) and the review gate stay Frontier. All additive.
- FALLBACK-GUARDED: `.claude/commands/ship.md` prefers `coder`/`tester` but
  falls back to `cm` when either launcher is absent, so a downstream that takes
  the updated `ship.md` WITHOUT the launchers keeps the exact prior behavior
  (`cm` runs every stage). Nothing here is merge-blocking.
- ARRIVES ON TEMPLATE SYNC: because both files are `template-replace`, a full
  template sync pulls `coder.md`/`tester.md` automatically — they are not an
  opt-in file-by-file choice. They stay inert unless `/ship` spawns them, but a
  downstream that already ships its own same-named `coder`/`tester` launcher
  should reconcile before syncing.
- CROSS-FAMILY LAUNCHERS ADDED LATER: at v1.30.0 these were Claude-only. A
  subsequent change added matching `coder`/`tester` launchers to `.codex/agents/`
  and `.github/agents/` for discoverability and parity. The tier split stays
  *functional* only in Claude Code (`model:` frontmatter pins the tier), and no
  Codex/Copilot `/ship` exists yet, so in those families the launchers are
  advisory-tier and invoked by hand. Do not flag the cross-family launchers — or
  the Claude-only functional tier-pinning — as drift; see
  `.claude/agents/README.md` (Pipeline Stage Launchers).
- NOTHING in this entry is merge-blocking.

### 1.29.0 — SME design support (guide + validator + review hook)

OPTIONAL — adopt-if-used; no baseline or governance-token change.

- OPTIONAL: `docs/designing-an-sme.md` (SME design craft),
  `tools/sme-charter-check.sh` (mechanical charter validator; joins the
  `tools/tests/` suite via its self-test), and the new
  Governance-Invariant SME `Consult When` line. Adopt if the downstream
  runs an SME bench; all additive. Skipping them costs only the
  SME-design guidance and the mechanical validator.
- REQUIRED TOGETHER (if re-vendoring the validator):
  `tools/sme-charter-check.sh` and
  `tools/tests/sme-charter-check.test.sh` must be taken together (the
  test self-tests the script). The validator asserts every
  `minions/smes/<key>.md` charter has launchers in all three families
  and a Local Registry row; a downstream with a filled bench must have
  those present, or the guard fails — which is the guard doing its job.
  A downstream with no authored charters passes vacuously.
- NOTHING in this entry is merge-blocking.

### 1.28.2 — Optional-layer adoption record

OPTIONAL — docs-only, no baseline or governance-token change.

- OPTIONAL: the new "## 4. Optional Layers (Operator Decision)" section in
  `docs/operator-onboarding-checklist.md` (per-repo `MINION_MEMORY` /
  `MINION_ISSUES` / coordinator-mode activation state, plus where the
  gate is persisted) and the new bullet in `MEMORY.md`'s Optional Layers
  convention. Both arrive via the normal manual-merge of those files;
  adopt when re-vendoring them. Skipping them costs only the durable
  adoption record.
- NOTE: `operator-onboarding-checklist.md` section numbers shifted
  (Escalation 4→5, Guardrail 5→6, Sign-Off 6→7). No repo reference cites
  the checklist by section number, so nothing else needs updating.
- NOTHING in this entry is merge-blocking.

### 1.28.1 — Guard hardening (SME-surface norm scan + public-export seed guard)

OPTIONAL — test/guard-only, no baseline or governance-token change.

- OPTIONAL: the extended retired-norm scan (`tools/tests/governance-consistency.test.sh`
  + the `governance-scan.allow` SME-surface globs) and the new
  `tools/export-seed-check.sh` public-export gate. Adopt if the
  downstream runs the `tools/tests/` suite as its regression harness
  and/or publishes a public mirror. Both are additive; skipping them
  costs only the added CI coverage.
- REQUIRED TOGETHER (if re-vendoring the test): a repo that takes the
  updated `tools/tests/governance-consistency.test.sh` must also take
  the updated `tools/tests/governance-scan.allow` — the test reads the
  allowlist and the new `expand_scan_entry` glob handling and SME-surface
  globs work as a pair.
- Repos that do not publish a public mirror can skip
  `tools/export-seed-check.sh` entirely; it is inert unless run by the
  public-export runbook.
- NOTHING in this entry is merge-blocking.

### 1.28.0 — Canonical SME bench + PM bench-review loop

OPTIONAL — adopt-if-used; with one REQUIRED-IF-ADOPTED delimiter migration.

- OPTIONAL: the five canonical SME charters (`minions/smes/*.md`) and
  their `sme-*` launchers in all three families are canonical-repo
  expertise content — classified `downstream-owned` / never-exported. A
  downstream builds its OWN bench from its OWN failure history; do not
  adopt these charters verbatim. Skipping them costs only the example
  bench; nothing forces adoption.
- REQUIRED (if the 1.27.0 expertise layer's Local Registry was filled):
  1.28.0 adds a split-merge delimiter to `minions/smes/README.md`. A
  repo that filled a Local Registry under 1.27.0 (where no delimiter
  existed) MUST move its filled rows BELOW the new delimiter ONCE
  before taking the new `minions/smes/README.md` — exactly as 1.25.0
  required for charters/`MEMORY.md`. After the one-time move, future
  upgrades are mechanical replace-above. A naive whole-file
  `template-replace` WITHOUT this migration silently drops the filled
  rows — treat it as merge-blocking.
- `minions/review-matrix.md` stays `downstream-owned`: a
  `template-replace` should never run against it, so its new delimiter
  is belt-and-suspenders — note only, no action for repos that already
  own their matrix.
- The PM bench-review loop (PM charter + `minions/smes/README.md`
  "Growing the bench" / Adding-an-SME step 0) arrives via the normal
  manual-merge/template-replace of those files — no separate action.
- Repos that skipped the v1.27.0 expertise layer entirely: all of the
  above is OPTIONAL — there is no registry to migrate and nothing goes
  inert.

### 1.27.1 — Expertise-layer wiring fix + PM-routed workflows

REQUIRED IF 1.27.0's expertise layer was adopted; otherwise OPTIONAL.

- REQUIRED (if the 1.27.0 expertise layer was adopted): the 21 launcher
  read-steps + 6 charter bootstrap lines that make spawned minions
  actually read `minions/smes/README.md` + `minions/review-matrix.md`.
  Without this wiring the SME registry and review matrix stay inert —
  minions never see them. Repos that skipped the expertise layer
  entirely can treat this as OPTIONAL (nothing to wire).
- REQUIRED TOGETHER (if adopting the wiring): the updated
  `tools/tests/governance-consistency.test.sh` (new `launcher_ok` +
  Workflow Ownership guards) must be taken together with the
  launcher/charter updates above and the new `MEMORY.md` Workflow
  Ownership subsection. Taking the updated test alone — without the
  launcher/charter wiring and the `MEMORY.md` law it checks for —
  fails the suite.
- The Workflow Ownership (PM-routed) law and the "Adding an SME"
  checklist in `minions/smes/README.md` arrive via the normal
  manual-merge/template-replace of `MEMORY.md`, entry-point files, the
  PM charter, and `minions/smes/README.md` — no separate action beyond
  the usual upgrade mechanics.
- Repos that skipped the v1.27.0 expertise layer entirely: all of the
  above is OPTIONAL — there is nothing to wire and nothing goes
  inert.

### 1.27.0 — Expertise layer (SMEs, review matrix, escalation contracts)

OPTIONAL — adopt-if-used.

- OPTIONAL: `minions/smes/README.md` + `sme-template.md` starters and
  `minions/review-matrix.md` starter. Take these if the downstream wants
  the SME (subject-matter expert) capability — an advisory-only class
  that recommends but never gates and never writes shared surfaces.
  Skipping them costs only the SME capability; nothing else depends on
  their presence.
- OPTIONAL: `docs/runbooks/README.md` structure contract. Adopt if the
  downstream maintains runbooks and wants the Purpose/Prerequisites/
  Procedure/Validation/Rollback shape enforced at doc-sync.
- The seven role charters' new `## Escalation Contract` sections and the
  `MEMORY.md` / `INIT.md` / read-order wiring arrive via the normal
  template-replace (charters) and split-merge (`MEMORY.md`) merge of
  those files — no separate action beyond the usual upgrade mechanics.
- NOTHING in this entry is merge-blocking. A downstream that skips all
  of the above loses only the SME capability and the runbook structure
  guard; the rest of the baseline stays coherent.
- CAUTION — governance guard/charter pairing: the new `esc_ok` check in
  `tools/tests/governance-consistency.test.sh` FAILs unless all seven
  role charters carry a complete `## Escalation Contract` section. If a
  downstream re-vendors the updated test file, it must also take the
  charter updates in the same step — take both together or neither.

### 1.26.0 — /handoff session snapshots (ephemeral surface)

No required changes — adopt normally.

- OPTIONAL: `.claude/commands/handoff.md` + `minions/handoffs/` surface
  (flush-then-snapshot, delete-on-pickup). Adopt if the project uses
  session handoffs; Codex/Copilot run the same protocol via the Handoff
  Mode section of `docs/minion-prompt-modes.md`.
- NOTE: `MEMORY.md` gains two small additive notes (Session Handoffs
  subsection + Session Reset cross-reference) in the template-managed
  half — the 1.25.0 split-merge migration makes this a mechanical
  replace-above adoption.

### 1.25.0 — Upgrade ergonomics (delimiter split-merge, completeness guards)

**REQUIRED — one-time delimiter migration (charters + `MEMORY.md`):**

- The seven role charters (`minions/roles/*.md`) and `MEMORY.md` now carry
  the split-merge marker. On the first upgrade that crosses 1.25.0, perform
  the merge-blocking migration in this playbook's
  **"One-time migration to the split (first upgrade to ≥ 1.25.0) — REQUIRED"**
  subsection (under Manual-Merge Guidance): move all downstream-authored
  content (charter Learned Context, project-specific `MEMORY.md` sections)
  below the marker once. Every later upgrade of these files then becomes the
  mechanical replace-above/preserve-below split — no more hand-grafting
  template bullets into charters full of downstream content.

**REQUIRED — adopt the manifest-completeness guard:**

- Re-vendor `tools/tests/` (`template-replace`): the suite gains a sixth
  file, `tools/tests/manifest-completeness.test.sh`, which FAILs unless
  every exportable tracked file is classified by a row in the live
  `docs/export-manifest.md` (glob rows count). A downstream's first run may
  fail until its downstream-added files get manifest rows — that is the
  guard working, not a regression; add the rows rather than skipping the
  test. This is the guard that makes silently-unmanifested files (invisible
  to snapshots *and* to `upgrade-classify.sh`) impossible.

**NOTE — `upgrade-classify.sh` new flags (additive, no back-compat break):**

- `--repo <git-repo> --from <rev> --to <rev>` (all three together)
  cross-checks the real `git diff` change set against the snapshot union
  and exits `4` on any `UNMANIFESTED-CHANGE` row — treat exit 4 as a
  failure in CI and upgrade scripts; it means the export/snapshot pipeline
  missed a genuinely changed file.
- `--hide-excluded` suppresses `do-not-export` rows from the report
  (default off for back-compat), silencing the recurring `AI/` / `.mm.md`
  noise.

### 1.24.0 — Model tiering (vendor-neutral capability bands)

No required changes — adopt normally. `docs/model-tiering.md` and the
`Recommended tier:` launcher lines are explicitly advisory (`template-replace`),
outside the governance-scanned invariant set; a downstream pinned to a single
model loses nothing by ignoring them. No governance tokens moved.

### 1.23.0 — Capability discovery & utilization

**REQUIRED — capability-inventory baseline (tool-neutral):**

- Land `minions/capabilities.md` (`downstream-owned`, rated `baseline`): the
  session bootstrap reads added in this version depend on the file existing.
  Take the template starter and fill it for this project — upgrades never
  overwrite the filled inventory.
- Merge the manual-merge hunks that wire it in: the
  `Read minions/capabilities.md.` session-read line in `CLAUDE.md`,
  `AGENTS.md`, and `.github/copilot-instructions.md`; the Capability
  Inventory subsection under Shared Rules in `MEMORY.md`; and the
  environment-truth ranking in `AI.md`'s source-of-truth order. All five are
  `manual-merge` files, so a hand merge can silently drop them. Not
  governance-scanned — verify by hand.
- The utilization obligation itself (role charters, review-lens bullet,
  `/ship` review prompts, `tools/xtool-call.sh` envelope lines) arrives via
  `template-replace`; re-vendor those files normally. Absence of a listed
  capability at call time is a silent skip, never a blocker.

### 1.22.1 — Overlay discipline + drift guards

**REQUIRED — governance test gains a role-roster drift guard:**

- Re-vendor `tools/tests/governance-consistency.test.sh` (`template-replace`).
  It now extracts the backticked role tokens from the live `MEMORY.md`
  `## Collaboration Model` roster and the `AI.md` `## Role Agents` list and
  FAILs on drift (normalized: lowercase, `om-test` folds into `om`). It also
  FAILs if either section extracts **no** roles — the downstream `MEMORY.md`
  must carry a `## Collaboration Model` section whose role bullets open with
  a backticked token (``- `PM` — ...``) and `AI.md` a `## Role Agents` list,
  under exactly those headings.
  A downstream that added or renamed roles must have both surfaces agree.
- Merge the `manual-merge` hunks: `MEMORY.md` Optional-Layers convention
  preamble (Communication Model, above the Issue Mirror / Memory Recall
  subsections), the multi-session contention note in Single-Writer
  Durability, the canonical-roster declaration in Collaboration Model, the
  cross-family launcher sync line in the Instruction-File Audit Rule, and
  `AI.md`'s Role Agents deferral to the roster.

**OPTIONAL:** deferred-state notices and the add-a-role touch list live in
`template-replace` docs (`docs/downstream-onboarding-playbook.md`,
`docs/operator-onboarding-checklist.md`); adopt normally.

### 1.22.0 — Coordinator-mode overlay (multi-project session lanes)

No required changes for a single-project downstream — adopt normally. The
overlay (`docs/coordinator-mode.md`, `docs/runbooks/add-submodule.md`) is
opt-in; the baseline gains only one-line pointers in `INIT.md`
(`manual-merge` — carry the pointer line if merging `INIT.md`) and
`docs/project/mailbox-collaboration-model.md`. `MEMORY.md` and `AI.md` are
untouched.

**OPTIONAL — adopt if the repo coordinates multiple projects:** take the
overlay docs and this playbook's "Coordinator-mode upgrades" subsection;
`projects/**` and the coordinator declaration in the live `MEMORY.md` are
expected intentional divergence in `upgrade-classify.sh` output.

### 1.21.4 — Public-export runbook

No required changes — adopt normally. New `docs/runbooks/public-export.md`
(`template-replace`) is a reference runbook; relevant only when publishing a
privacy-safe public copy.

### 1.21.3 — tea v0.14.1 compat (issue-mirror tooling)

No required changes for downstreams not using the issue mirror.

**OPTIONAL — adopt if the issue mirror (`MINION_ISSUES=on`) runs against
Gitea via `tea`:** re-vendor `tools/issue-sync.sh`,
`tools/issue-board-bootstrap.sh`, and their tests (`template-replace`). On
tea v0.14.1 the old scripts soft-fail every sync (`--body` was renamed) and
blind label re-creation silently doubles the label set; the new versions
detect the installed tea's flags and bootstrap idempotently.

### 1.21.2 — Memory gate shell-profile fix (.zshenv, not .zshrc)

No required changes for downstreams not using the memory recall layer.

**OPTIONAL — adopt if the memory recall layer (`MINION_MEMORY=on`) is
enabled:** re-vendor `docs/runbooks/memory-recall-setup.md` and re-check the
gate. An `export MINION_MEMORY=on` placed in `~/.zshrc` per the old runbook
is invisible to non-interactive agent shells — move it to `~/.zshenv` (zsh)
and verify from a fresh agent tool shell (`echo ${MINION_MEMORY:-<unset>}`),
never from the interactive terminal.

### 1.21.1 — Verdict distribution in gate briefs

**REQUIRED — small `manual-merge` hunk, not governance-scanned:**

- Merge the verdict-distribution bullet into `MEMORY.md` Execution Quality
  (sibling to the 1.20.1 live-state bullet): PM-authored gate briefs embed
  reviewer verdicts — verdict, conditions, severities — verbatim; raw
  artifacts stay reference, never the gate's primary input. The matching
  `minions/roles/PM.md` hunk arrives via `template-replace`. The suite will
  not catch its absence — verify by hand.

### 1.21.0 — Memory recall layer (Mnemoverse, optional)

No required changes — the layer is default-off; with `MINION_MEMORY` unset,
every memory step is a silent no-op.

**OPTIONAL — adopt if the project wants semantic recall
(`MINION_MEMORY=on`):** take `docs/memory-recall-model.md` and
`docs/runbooks/memory-recall-setup.md` (`template-replace`) and merge the
gate-conditioned wiring hunks in `MEMORY.md` and `AI.md` (`manual-merge`).
Files always win; recall output is input, not authority. Note the 1.21.2
`.zshenv` fix before following the setup runbook.

### 1.20.1 — Live-state briefs (confirm runtime state, don't embed snapshots)

**REQUIRED — small `manual-merge` hunk, not governance-scanned:**

- Merge the live-state bullet into `MEMORY.md` Execution Quality: dispatch
  briefs for runtime-touching work instruct the agent to confirm live state
  first, never embed a presumed runtime snapshot. The matching
  `minions/roles/OM.md` and `PM.md` hunks arrive via `template-replace`. The
  suite will not catch its absence — verify by hand.

### 1.20.0 — Single-writer durability for the comm model

**REQUIRED — governance tokens + comm-model law (tool-neutral, every
downstream):**

- Merge the **single-writer durability** law into the live `MEMORY.md`
  Communication Model: spawned minions do not commit or push; they return
  the Completion Handoff packet verbatim to whoever spawned them, and only
  the top of the spawn chain commits — plus the scope split (coordination
  artifacts roll up; code deliverables stay in-lane), the durability window
  (at most one in-flight deliverable), `WRITTEN-BY:` attribution, the
  optional `DURABLE LESSONS:` handoff section, and the `SOLE-HOLDER:`
  return flag with its persist-first rule.
- **Merge-blocking:** `tools/tests/governance-consistency.test.sh` now FAILs
  unless the live `MEMORY.md` carries the tokens `single-writer` (or
  `single writer`), `DURABLE LESSONS`, and `SOLE-HOLDER`. A hand merge that
  drops any of these breaks the downstream's own suite.
- The same law is normalized across all seven `minions/roles/*.md` charters,
  `AI.md`, and Pipeline Mode — the charters are `template-replace`
  (re-vendor; review local customizations); the `AI.md` hunk is
  `manual-merge`.

### 1.19.1 — issue-sync test-hardening + soft-fail diagnostic

No required changes — adopt normally. Re-vendor `tools/issue-sync.sh` and its
tests (`template-replace`) if the issue mirror is adopted; syncs now surface
backend stderr on soft-fail (exit 4) instead of hiding it.

### 1.19.0 — Issue/project mirror (optional, default-off)

No required changes — the layer is default-off; with `MINION_ISSUES` unset or
the host CLI absent, `tools/issue-sync.sh` is a no-op (exit 0) and nothing
blocks.

**OPTIONAL — adopt if the project wants Issue-board visibility
(`MINION_ISSUES=on`):** take `tools/issue-sync.sh`,
`tools/issue-board-bootstrap.sh`, `docs/issue-mirror-model.md`, and
`docs/runbooks/issue-board-setup.md` (`template-replace`); merge the
gate-conditioned Communication Model wiring in `MEMORY.md` (`manual-merge`).
Git files remain the source of truth; `.issue` sidecars are
downstream-owned and never exported.

### 1.18.0 — Branching & release model

**REQUIRED — relocated hard-stop + coordination plane (governance-scanned):**

- Merge the 4-tier branching model's governance hunks into the live
  `MEMORY.md` **and** `AI.md`: the single Operator hard-stop moves to
  **`staging→main`** (a pull request); `feature→dev` and `dev→staging` are
  autonomous CLI merges (still exactly three hard-stops), and the
  **Class-A / Class-B coordination plane** (Class A mainline-authoritative;
  Class B travels with the branch). `AI.md` also gains "Reading Truth in a
  Multi-Branch World".
- **Merge-blocking:** the governance test now FAILs unless **both**
  `MEMORY.md` and `AI.md` contain `staging→main` (or `staging->main`) and
  `Class A`/`Class-A`. Both files are `manual-merge`; a hand merge that
  keeps the old main-hard-stop wording breaks the downstream's own suite.
- Merge the CHANGELOG-fragment mechanism into `MEMORY.md`'s CHANGELOG
  Maintenance Rule (feature branches write `CHANGELOG.d/<topic>.md`; DM
  assembles at the staging gate) and add `CHANGELOG.d/` to the repo.
- Re-vendor (`template-replace`): `docs/branching-and-release-model.md`,
  `docs/runbooks/branch-setup.md`, and the CM/OM/DM/PM role charters (they
  gain Branch Ownership sections).

### 1.17.0 — Shadow-first / dark-ship risk posture

No required changes — the posture is optional and ships no code.

**OPTIONAL — adopt if the project replaces incumbent decision logic:** take
`docs/risk-posture-shadow-first.md` (`template-replace`) and carry the
opt-in pointer in `MEMORY.md` Deployment Discipline when merging that file.
Greenfield / no-incumbent projects skip it by design.

### 1.16.0 — Review-ergonomics quick wins

**REQUIRED — small `manual-merge` hunk, not governance-scanned:**

- Merge the operator-facing-surfaces bullet into `MEMORY.md` Execution
  Quality: a change that adds/alters a config flag, journal/log event,
  metric, or feature must review the operator-facing surfaces (config
  editor, dashboard, runbooks) before done. The suite will not catch its
  absence — verify by hand.

**Routine (`template-replace`):** deltas-only review posture in
`minions/roles/SM.md`/`DM.md`, dual-vendor-on-security-diffs guidance in
`docs/cross-tool-orchestration.md`, worktree-pruning notes, and the
onboarding-checklist line — re-vendor normally.

### 1.15.0 — Triaged Copilot .github prompt-eval findings

No required changes — adopt normally. Three clarifications to
`.github/instructions/documentation-quality.instructions.md`
(`template-replace`); the governance-scanned files are unchanged.

### 1.14.0 — xtool-call.sh review-path hardening

No required changes — adopt normally. Re-vendor `tools/xtool-call.sh` and
`tools/tests/` (`template-replace`) if cross-tool review is used: `--prompt -`
now reads stdin, review envelopes report `review-failed` on provider failure
instead of a false `ok`, and empty prompt/output fail loudly.

### 1.13.0 — Instruction-File Audit Standard

**REQUIRED — small `manual-merge` hunk, not governance-scanned:**

- Merge the **Instruction-File Audit Rule** into the live `MEMORY.md`: when
  `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`,
  `minions/roles/*.md`, any agent-launcher family, or slash-command / skill
  prompt files change, audit them for clarity, accuracy, consistency,
  staleness, and drift before handoff (manual subagent+rubric audit is the
  cross-tool baseline; DM owns instruction-file truth). The suite will not
  catch its absence — verify by hand.

### 1.12.0 — Upgrade-Process Tooling

No required changes — adopt normally. New `tools/upgrade-classify.sh` + tests
and the release-tag convention are `template-replace`; the governance test
gains `--root`/`GOV_ROOT` and a ROOT banner (pure ergonomics, no new token
assertions).

**RECOMMENDED:** the governance scan list is externalized to
`tools/tests/governance-scan.allow` (`template-replace`, falls back to the
built-in default when absent). A downstream that extended the scan file list
inside the test itself should migrate those additions into the allow file
before re-vendoring the test, or the extensions are silently lost.

### 1.11.1 — Hardening (governance-test detector, delegate safety, doc precision)

A correctness/security hardening pass from downstream upgrade feedback. No new
capability; re-vendor the affected files.

**REQUIRED — re-vendor and re-run the fixed governance test:**

- `tools/tests/governance-consistency.test.sh` (`template-replace`) shipped in
  1.11.0 could **false-PASS**: its line-based grep missed the retired norm when it
  was line-wrapped in prose (e.g. a `CLAUDE.md` containing "Do\nnot spawn them
  automatically … asks explicitly"), and `ask .*explicitly` could not match `asks
  explicitly`. The 1.11.1 detector normalizes whitespace whole-file and uses
  boundary-anchored, sentence-bounded patterns, and self-tests itself. Re-vendor it
  and **re-run it** — it may now catch a retired-norm instance your 1.10.0 → 1.11.0
  upgrade left behind that the old test passed over. (If it now fails on a live
  file, that is a real residual to hand-fix, not a regression.)
- When scanning additional project-local files for the retired norm, scan with the
  **specific** retired-norm phrasing (or reuse this test's detector), **not** a
  broad `spawn` / `explicitly` keyword grep — a broad net false-positives on
  unrelated prose (e.g. "unless the task explicitly requires"). Precision matters in
  both the detector and the manual scan.

**RECOMMENDED if the project uses `delegate` mode:**

- Re-vendor `tools/xtool-call.sh` (`template-replace`) for two delegate-mode fixes:
  path-unsafe `--role`/`--topic` are now rejected (no `..`; charset
  `[A-Za-z0-9._-]`) before any branch/worktree is created; and a failed delegate
  self-cleans its worktree+branch (or surfaces an explicit recovery hint when
  partial work exists) so a repeat same-topic delegate is not dead-ended by a stale
  branch. `review` mode is unchanged (independently confirmed read-only against the
  live `codex`/`copilot` binaries by the downstream SM review).

**INFO:**

- `review` mode does not deny copilot's `url`/`web-fetch` read-only fetch channel —
  a confidentiality consideration (not a write/integrity risk), documented in
  `docs/cross-tool-orchestration.md`. Deny it (`--deny-tool 'url'`) when reviewing a
  sensitive repository.

### 1.11.0 — Cross-Tool Orchestration + Autonomous-Orchestration Governance

**REQUIRED — governance baseline (tool-neutral; every downstream, any AI tool):**

- Merge the **autonomous-orchestration posture** into the live `MEMORY.md` and
  `AI.md`: retire the "do not spawn role agents automatically / Operator or PM
  must ask explicitly" norm and replace it with autonomous orchestration bounded
  by exactly **three hard-stops** — (1) merge/push to `main`; (2) destructive or
  production-affecting actions without rollback posture; (3) unresolved AI
  disagreement. Scope expansion is flagged, not stopped. All other safety
  guardrails (secrets hygiene, destructive-action approval, rollback, evidence
  discipline, base-guardrail-change approval) are retained — this retires
  permission *ceremony*, not safety gates.
- The norm also appears in `INIT.md`, `CLAUDE.md`, `AGENTS.md`, and
  `.github/copilot-instructions.md` (all `manual-merge`) and in
  `docs/collaboration-playbook.md` plus the three `*/agents/README.md` (all
  `template-replace`). Because the core lives in `manual-merge` baseline files,
  a hand merge can silently drop it. **Merge-blocking:** confirm the new posture
  and the three hard-stops are present in the live `MEMORY.md` and `AI.md`, and
  that **no** file still carries the old "ask explicitly / on its own initiative
  / spawn automatically" wording.
- For a legacy pre-template downstream, **manual merge is the correct strategy**
  for these baseline files — do **not** `template-replace` `MEMORY.md`, `AI.md`,
  or `INIT.md` (they hold project truth). Merge in the norm section and preserve
  everything else.
- **Verification:** the template ships
  `tools/tests/governance-consistency.test.sh`. Run it in the live repo after
  merging — it must print `ok - governance consistent`. Extend its file list if
  the downstream kept the old norm in additional project-local files.

**REQUIRED if the project uses cross-tool orchestration (Codex / Copilot review
or delegation):**

- Export (`template-replace`): `tools/xtool-call.sh`, `tools/tests/`,
  `.claude/commands/second-opinion.md`, `.claude/commands/delegate.md`, and
  `docs/cross-tool-orchestration.md` (the operator reference).
- Take the `/ship` cross-vendor review stage from `.claude/commands/ship.md` and
  the Pipeline Mode section of `docs/minion-prompt-modes.md` (both
  `template-replace`).
- The provider CLIs must be installed where used; the wrapper degrades
  gracefully (exit `3` + `provider-unavailable` envelope) when a provider is
  absent, so adopting the files is safe even before every CLI is present.

**RECOMMENDED:**

- After upgrade, run `tools/tests/xtool-call.test.sh` and
  `tools/tests/governance-consistency.test.sh`, and verify `/second-opinion` and
  `/delegate` are discoverable in a fresh Claude Code session.
- Decide explicitly whether the project adopts cross-vendor review/delegation.
  The governance change is adopted regardless; the cross-tool feature is additive.

**Tool-parity caveat (call out in the PM upgrade packet):**

- `/second-opinion`, `/delegate`, and the `/ship` cross-vendor stage exist only
  as Claude Code slash commands (`.claude/commands/`). There is no Codex or
  Copilot command equivalent yet. A Codex-only or Copilot-only downstream still
  adopts the `REQUIRED` governance change (it is tool-neutral) and can call
  `tools/xtool-call.sh` directly (portable bash usable from any shell/tool), but
  does not get the slash-command UX.
- First-executable-code note: `tools/xtool-call.sh` is the first executable file
  in a previously markdown-only template. A downstream vendoring into a
  restricted environment should confirm shell execution and `git worktree`
  support before relying on `delegate` mode.

### 1.10.0 — Pipeline Mode + Two-Channel Communication

**REQUIRED — communication-stack baseline (tool-neutral, applies to every
downstream regardless of which AI tools it uses):**

- Merge the **two-channel communication model** into the live `MEMORY.md`
  `## Communication Model` section (direct-return channel for orchestrated runs
  vs. mail packet for deliberate/cross-session work). `MEMORY.md` is
  `manual-merge`, so this will not arrive automatically — confirm the section is
  present after merging. Without it, the direct-return channel is unsanctioned
  and the mail-traffic-reduction intent fails. This is the change that "must be
  implemented."
- This is baseline truth even for projects that never run the pipeline: it
  governs when results may return in-context vs. when they must become a durable
  mail packet.

**REQUIRED if the project uses Claude Code subagents / the `/ship` pipeline:**

- Export the new `.claude/commands/ship.md` (`template-replace`).
- Add `.pipeline/` to the downstream `.gitignore`. `.gitignore` is `manual-merge`
  / `baseline` in the manifest — no `template-replace` step applies it, so this
  is a manual edit. Without it, ephemeral pipeline scratch space can be committed.
- Take the `minions/roles/PM.md` Pipeline Orchestration section and the
  `docs/minion-prompt-modes.md` Pipeline Mode section (both `template-replace`).
  Review local PM-role customizations before overwrite, per the manifest note.

**RECOMMENDED:**

- After upgrade, verify `/ship` is discoverable in a fresh Claude Code session
  and that PM, when orchestrating, reads `MEMORY.md`, `minions/roles/PM.md`, and
  the Pipeline Mode section.
- Decide explicitly whether the project adopts the execution track. The
  deliberate coordination track is unchanged; `/ship` is additive.

**OPTIONAL / DEFERRED:**

- Phase 2 (Sonnet-tier `coder` / `tester` stage launchers) shipped in v1.30.0 —
  see that version's entry above. Adopt the two launchers if the project uses
  `/ship`; `/ship` falls back to `cm` when they are absent, so skipping them
  changes nothing.

**Tool-parity caveat (call out in the PM upgrade packet):**

- The `/ship` orchestrator currently exists only as a Claude Code slash command
  (`.claude/commands/`). There is no Codex or Copilot equivalent yet. A
  Codex-only or Copilot-only downstream still adopts the `REQUIRED` comm-stack
  change (it is tool-neutral), but runs the pipeline by having PM drive the
  stages manually rather than via `/ship`. State this clearly so the project
  does not assume command parity it does not have.

## Recommended Paths

- current approved template snapshot: `.minions-template/`
- incoming candidate snapshot during upgrade: `.minions-template.next/`

If the downstream repo does not already keep a vendored template snapshot, the
first upgrade should establish one that matches the repo's current base-template
version before attempting a larger template jump. If the repo is truly new,
run the onboarding playbook first.

Both snapshot paths should contain export-ready copies of the template, not full
Git clones.

- exclude `.git/`
- exclude files marked `do-not-export` in `docs/export-manifest.md`

**Scale the ceremony to the delta.** For a contained patch (a few files, no
multi-release jump), `.minions-template.next/` staging is optional — a shallow clone
of the target tag plus `tools/upgrade-classify.sh` (or a direct `git diff <tag>
<tag>`) gives the same answer with nothing to stage or clean up. Stage `.next/` when
you want a durable on-disk review artifact, or for large or multi-release jumps.

## Ownership

- `PM` owns the upgrade packet, merge order, and Operator-facing decision
  summary
- `AM` reviews architecture and design changes that affect role boundaries,
  plans, or shared structure
- `SM` reviews new guardrails, security expectations, and trust-boundary changes
- `CM` applies downstream file merges that require implementation-oriented
  technical judgment
- `DM` reviews documentation surface changes, reader-path impact, and doc-sync
  requirements
- `OM-Test` / `OM` review deployment or runtime workflow changes when relevant
- `Operator` approves the downstream adoption decision

## Upgrade Workflow

1. Confirm the downstream repo's current base-template version in
   `minion-version.md`.
2. Stage the current approved export-ready template snapshot in
   `.minions-template/` if it is not already present.
3. Import the incoming template version into `.minions-template.next/` using the
   same export-ready filtering rules. (Optional for a contained patch — see "Scale
   the ceremony to the delta" and "Detecting Upstream Drift": a `git diff <tag>
   <tag>` against the release tags answers the "what changed upstream" half without
   staging `.next/`.)
4. Diff `.minions-template/` against `.minions-template.next/` to see what the
   template changed.
5. Read the **Version-Specific Required Changes** section above for every
   version between the downstream's current base and the target. Note each
   `REQUIRED` item — these are merge-blocking and several live in `manual-merge`
   files (e.g. `MEMORY.md`, `.gitignore`) that no `template-replace` step
   touches, so they will not arrive on their own.
6. Measure per-file divergence before deciding replace-vs-hand-merge. For each
   `baseline` file (especially `manual-merge` ones), compare the live file to the
   approved vendored snapshot, using `cmp`'s three-valued exit status (not a
   boolean): `cmp -s <live> .minions-template/<same-path>; echo $?` →
   `0` = identical (a clean `template-replace` is safe even for a `manual-merge`
   file), `1` = diverged (real downstream divergence needing a surgical hand-merge),
   `>1` = comparison error such as a missing/unreadable input (investigate it; do
   NOT treat it as identical or diverged). Do not collapse this to
   `cmp -s ... && echo identical || echo diverged` — that mislabels an error as
   "diverged"; and a bare `diff <live> <snapshot> | grep -c '^[<>]'` is unsafe for
   the decision too, since `grep -c` returns `0` for identical files AND for a diff
   error. This makes the replace-vs-hand-merge decision objective rather than a
   judgment call (downstream feedback found `AI.md`/`AGENTS.md` byte-identical while
   `MEMORY.md`/`INIT.md` had real divergence). **`tools/upgrade-classify.sh --old
   <old-snapshot> --new <new-snapshot> --live <repo>` automates steps 4, 6, and 7 in
   one pass** — it prints each changed file's manifest class and live-vs-snapshot
   divergence (identical / diverged / missing / error), so the front half of the upgrade is a
   reproducible command rather than manual cross-referencing. Add
   `--repo <git-repo> --from <rev> --to <rev>` (all three together) for a
   git-diff completeness cross-check: every exported file changed between the
   two revs must appear in the snapshot union, and any that does not is
   reported as `UNMANIFESTED-CHANGE` with **exit 4 — treat that as a failure**
   (the export/snapshot pipeline missed a change), not as noise to scroll
   past. `--hide-excluded` suppresses `do-not-export` rows so the work list
   shows only files that can actually reach the downstream.
7. Use `docs/export-manifest.md` to classify each affected live file as:
   - `template-replace`
   - `manual-merge`
   - `downstream-owned`
   - `do-not-export`
8. Apply `template-replace` files first, including `.github/agents/`,
   `.codex/agents/`, and `.claude/agents/` when the downstream project uses
   Copilot custom agents, Codex custom agents, or Claude Code subagents.
   Review any intentional local downstream divergence before overwriting.
9. Manually merge files such as `MEMORY.md`, `AI.md`, `INIT.md`,
   `docs/operator-onboarding-checklist.md`, and `minion-version.md` (`AI.md`
   is split-merge since 1.46.0 — see Manual-Merge Guidance below for the
   mechanical replace-above/preserve-below procedure). Confirm every
   `REQUIRED` item from step 5 landed — especially comm-stack changes in
   `MEMORY.md` and `manual-merge` edits like `.gitignore`.
10. Re-review `docs/minion-plugin-pairings.md` (it is `template-replace`, so the
   recommendation map refreshes) and confirm this project's wired pairings — the
   "use-when" lines and any restricted-role whitelist entries in `minions/roles/`
   and `.claude/agents/` — survive the role-file merge as local customizations.
   Add charter lines for any newly adopted integrations; remove ones whose plugin
   is gone.
11. Preserve `downstream-owned` files unless the Operator explicitly directs a
   project-specific rewrite.
12. Record the upgrade packet in `minions/mail/`, mirror the same-day summary
   into `minions/chat/`, and update the downstream `CHANGELOG.md`. **Scale the
   write-up to the decision surface, not the file count:** a no-decision contained
   patch (every changed file `template-replace` + live-identical, no `REQUIRED` gate
   beyond re-running a test) warrants a one-line provenance entry — version, tag, and
   "clean replace; classify output attached" — not a full packet. Reserve the dense
   provenance entry for upgrades that carried real merge decisions or gate calls. The
   historical-record value is real, so keep *some* entry; just match its weight to
   the decisions made.
13. After approval, replace `.minions-template/` with the new approved snapshot
   (and remove `.minions-template.next/` if you staged it).
14. Update the base-template portion of `minion-version.md` only after the live
   downstream files and vendored snapshot are aligned.

### Coordinator-mode upgrades

Repos running the coordinator overlay (`docs/coordinator-mode.md`) follow this
same workflow — coordinator scale changes how classification output is read,
not the upgrade mechanics. Coordinator field practice sorts upgrade files into
three categories; each maps onto the existing manifest classes, so no separate
categorization is needed:

- **copy-directly** ≈ `template-replace` files that are new in the incoming
  version (no live counterpart yet): apply them directly in step 8.
- **take-template** ≈ `template-replace`: role charters, agent launchers, and
  shared docs converge to the template baseline unless a coordinator-specific
  override was intentional — review divergence before overwriting, per step 8.
- **preserve** ≈ `manual-merge` / `downstream-owned`: files such as
  `MEMORY.md` and `AI.md` carry coordinator-specific state; merge only with
  explicit review, per steps 9 and 11. Both are split-merge delimiter files
  (see Manual-Merge Guidance below) — the delimiter rule supersedes any
  earlier "diverges in place" framing: coordinator-specific additions belong
  BELOW the marker as additive notes, never as an in-place rewrite of
  above-the-marker template text (the same Gitea #56 §1 hazard the 1.46.0
  entry above describes, and coordinator repos are the heaviest-`AI.md`-
  divergence population, so this population is exactly where that hazard
  bites hardest).

Expected intentional divergence: `projects/` (the registry and lane
scaffolds), the overlay activation state (the coordinator-mode declaration in
the live `MEMORY.md`), and coordinator role additions are coordinator surfaces
the template baseline does not carry. Note `tools/upgrade-classify.sh`
builds its change set from the old/new snapshot union, so coordinator-created
files (`projects/**`, added role charters) never appear in its output at all;
the `diverged` reading applies to TEMPLATE files carrying overlay state —
e.g. the live `MEMORY.md` with the coordinator-mode declaration. Both cases
are the overlay working as designed — intentional divergence to preserve,
not drift to reconcile.

## Manual-Merge Guidance

### Split-merge for delimiter-bearing files

Since template version 1.25.0, a growing set of governance, role, and
registry surfaces in this template carry a split-merge delimiter — the seven
role charters (`minions/roles/*.md`), `MEMORY.md`, `AI.md`,
`minions/capabilities.md`, `minions/smes/README.md`,
`minions/review-matrix.md`, `docs/instruction-size-budgets.md`, and
`docs/export-manifest.md` among them, with more added as the template grows.
Rather than re-enumerating that list here (a list that has already gone
stale in this very section once, omitting `AI.md` and `docs/export-manifest.md`
until the 1.46.0 entry above added them), treat the marker as the source of
truth: **any file carrying the marker below is a split-merge file** and
follows the same mechanical procedure regardless of whether it appears in
the paragraph above. The exact marker line (referenced below simply as "the
marker") is:

`<!-- ================= DOWNSTREAM CONTENT BELOW — template upgrades replace above this line only ================= -->`

For any file carrying the marker, the upgrade procedure is mechanical, not a
judgment call:

1. take the incoming template version's above-the-line half **verbatim**
2. keep the live downstream file's below-the-line half **verbatim**
3. concatenate the two halves

The template ships nothing below the marker; everything downstream-authored
(charter Learned Context, project deltas, project-specific `MEMORY.md`
sections) lives below it and survives every upgrade untouched. Never edit
above-the-line content downstream — additive overrides and extensions go
below the marker; anything that contradicts above-the-line content gets
promoted upstream (feedback packet) instead of edited in place.

### One-time migration to the split (first upgrade to ≥ 1.25.0) — REQUIRED

On the first upgrade that crosses 1.25.0, the downstream performs a one-time,
merge-blocking migration of each charter and `MEMORY.md` — this is what makes
every later upgrade a clean split:

- move all downstream-authored content below the marker: charter
  `Learned Context` blocks, project-specific `MEMORY.md` sections (project
  truth, environments, safety constraints), and any other local additions
- re-express inline modifications the downstream made to template text as
  additive below-the-line overrides/extensions
- anything above the line that the downstream changed and cannot express
  additively must be either promoted upstream (feedback packet to the
  template) or dropped in favor of the template wording

After migration, above-the-line content is template-verbatim forever: every
subsequent upgrade replaces it wholesale via the mechanical split above, and
no downstream edit made above the line survives.

### seed-only `STUB BOUNDARY` marker

Distinct from the split-merge delimiter above: this marker applies to the
five `seed only`, fully-downstream-owned files (`feedback.md`, `ROADMAP.md`,
`TODO.md`, `docs/MECHANICS.md`, `docs/DESIGN.md` — enumerate mechanically via
`grep 'seed only' docs/export-manifest.md`, never from memory). These files
have no template-managed half at all, so the split-merge machinery above does
not apply to them; `tools/export-seed-check.sh` does apply, asserting the
marker's presence in your live repo (Leg S, `--completeness` mode) and its
absence in an export tree (Leg E). This subsection is the durable home for
the marker instruction — the 1.46.0 Version-Specific Required Changes entry
above is a one-time adoption notice, not where a downstream reads this from
on a later upgrade or a fresh onboarding.

- **The block** (copy verbatim, filling `<content>` per file — "backlog",
  "direction", "captured feedback", "map", "values"):

  ```
  <!-- STUB BOUNDARY (not a split-merge delimiter): everything ABOVE is the
       seed that ships to downstreams and the public mirror; everything BELOW is
       this repo's own <content>, reset away at public-export Step 2 item 4. ...
  -->
  ```

- **Placement:** at the point where the template's own seed content ends and
  your project's own content begins in that file — but treat that seam as
  presumed, not literal, for these five files. Unlike a split-merge file,
  `ROADMAP.md`/`TODO.md`/`feedback.md` are downstream-owned in full: there is
  no template-managed half actually enforced above the marker, so "where the
  seed ends" is a judgment call, not a mechanical boundary. The two error
  directions are asymmetric: placing the marker too high (near the top,
  under-capturing your content) at worst ships a thin/incomplete stub if you
  ever publish — harmless. Placing it too low (near the bottom,
  over-capturing your content as "seed") risks publishing private backlog,
  direction, or feedback to a public mirror — irreversible. **When in doubt,
  place it higher.** For a downstream that never runs a public-export mirror,
  placement is largely moot either way: Leg S only checks that the marker
  line is *present* somewhere in the file, not where.
- **Verify:**

  ```bash
  bash tools/export-seed-check.sh --completeness .
  # Expected: ok - export seed classification complete (delimiter completeness + seed-only marker presence)
  ```

### `MEMORY.md`

- preserve project-specific facts, constraints, environments, and operating
  history — these live below the marker
- the "later split into template-managed and project-managed sections" this
  guidance once anticipated now exists (since 1.25.0) for `MEMORY.md` and the
  role charters: apply the mechanical split-merge above — replace the
  template-managed half above the marker with the incoming template's,
  preserve the project-managed half below it
- new template guardrails, role definitions, and workflow rules arrive in the
  above-the-line half; run `tools/tests/governance-consistency.test.sh` after
  the merge to confirm the governance tokens survived

### `AI.md`

- `AI.md` is delimiter-bearing but follows `MEMORY.md`'s shape, not the
  registry shape (`minions/capabilities.md`, `minions/smes/README.md`,
  `minions/review-matrix.md`, `docs/export-manifest.md`): prose above the
  marker, and downstream-authored prose below it under the file's own
  `## Template/Downstream Split` heading — not a `## Local …` table. Do not
  expect a table to appear below `AI.md` after migrating; there is none to
  find.
- preserve downstream-specific cross-tool coordination notes, local handoff
  conventions, and tool-specific overrides below the marker
- new template cross-tool protocol changes, source-of-truth ordering, and
  role-agent wiring arrive in the above-the-line half via the mechanical
  split-merge
- run `tools/tests/governance-consistency.test.sh` after the merge to
  confirm governance tokens survived, same as `MEMORY.md`

### `minions/roles/*.md` (role charters)

- delimiter-bearing: apply the mechanical split-merge above — take the
  incoming charter's above-the-line half verbatim, preserve the downstream's
  below-the-line Learned Context and project deltas
- never hand-graft individual template bullets into a locally modified
  charter; the split-merge replaces hand-merging entirely

### `INIT.md`

- preserve the downstream project's onboarding framing and project-specific
  references
- merge new baseline workflow expectations, role sets, and handoff rules

### `docs/operator-onboarding-checklist.md`

- preserve completed downstream decisions
- merge new template checklist items so future onboarding reviews stay current

### `minion-version.md`

- preserve the downstream version suffix
- update the base-template version only after the upgrade is actually complete

## Minimum PM Upgrade Packet

- current downstream version
- target template version
- version-specific `REQUIRED` items (from **Version-Specific Required Changes**)
  and confirmation each one landed in the live repo — call out any comm-stack,
  governance-norm, or `manual-merge` (`.gitignore`) changes and any tool-parity
  caveat explicitly
- files replaced from template
- whether `.github/agents/`, `.codex/agents/`, or `.claude/agents/` changed
   and whether downstream agent names or instructions need local adjustment
- files manually merged
- files intentionally left downstream-owned
- Operator decision needed
- follow-up owners and verification steps
