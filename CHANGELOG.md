# CHANGELOG

All notable changes to this repository are tracked here.

## 2026-07-30 (v1.47.0 — PM judgment model: landscape routing + the Hope/Effort creep check)

- Commit hash: (staging→main merge; assigned at merge) — workstream commits `5d63c7a`..`2c8a585`, merged to dev at `6f79885`
- **The gap this closes.** Every existing rule in the template tells an agent
  what it may not do — hard-stops, lane boundaries, gate criteria,
  single-writer durability. None told it how to tell *what kind of problem it is
  looking at*, or how to tell whether a returned packet is actually done.
  `minions/roles/PM.md` was 2,025 words of governance mechanics whose entire
  treatment of the project-management domain was one line ("prevent scope creep
  and backlog sprawl").
- **Two forcing functions, both bound to steps that were already mandatory**
  rather than added as new rituals — the design constraint that keeps this from
  becoming ceremony:
  1. **Landscape routing** (`MEMORY.md` → Execution Quality, immediately after
     the tier-declaration bullet, riding the same already-mandatory
     dispatch-brief field list). A brief for multi-step work names its
     goal-clarity × solution-clarity quadrant, and the quadrant selects the
     stage chain: clear/clear dispatches the implementer; clear goal + unclear
     solution takes an AM architecture spec first; unclear goal + clear solution
     is not dispatched until the goal is scoped; both-unclear routes to RM for
     research only. Single-step consults are exempt, matching Workflow
     Ownership.
  2. **The creep check** (`MEMORY.md` → Completion Handoff Contract, at the
     consolidation step the single writer already performs for
     `DURABLE LESSONS:` and `SOLE-HOLDER:`). Hope Creep — is success claimed on
     evidence that survives inspection, or on the claim itself? Effort Creep —
     is "done" proven by something that would fail if it were not done?
- **Why the declaration is load-bearing and not a box-tick:** the quadrant
  *selects the routing*, so a wrong declaration produces visibly wrong routing.
  A brief claiming "clear/clear" that then dispatches a spec is
  self-contradicting on its face.
- **Both motivating failures are from v1.46.0, and both are recorded as case law**
  in the new doc rather than as abstractions: routing was instinct, not method
  (item A2 needed an architecture spec first, which was the right call made by
  feel because the Operator asked — nothing in the repo would have produced it
  deterministically or caught its absence); and two untrustworthy reports nearly
  shipped (a fixture green because the script crashed and the crash exited 1,
  matching the expected code; a guard correct in code but unproven by any test).
- **New `docs/pm-judgment-model.md`** carries the model in full: the two axes,
  the routing map and its exemption, two worked examples from this repo's real
  history, the four creep types, attribution, and the Known Limit. The second
  worked example is the deferred archive-reporter automation — a case where the
  solution was *unusually* well-specified (v3 design, three review rounds,
  SHIP-WITH-CONDITIONS from SM and Shell/Test-Harness) and still correctly not
  dispatched, because the goal was unvalidated. The lesson it carries: a
  fully-specified solution is not a licence to build.
- **Scope Creep and Feature Creep get no second check**, and the law now says why
  honestly: they are handled *prospectively* by the existing scope-expansion rule,
  which runs on the actor's self-report and therefore does not catch an expansion
  nobody flagged. This check does not add that coverage. Recorded as an open
  question rather than described as "covered" (Governance-Invariant SME).
- **The both-unclear cell is research-only — a separation-of-duties boundary.**
  RM is the role *chartered* to ingest untrusted external content and the one
  pinned read-only for it; its findings return through PM, who dispatches
  implementation separately. The doc now also states the limit precisely: the pin
  does **not** mean untrusted content reaches only RM (in the Claude family every
  other role has `WebFetch`/`WebSearch`), it means the role we deliberately point
  at untrusted sources cannot write. An earlier draft — and the spec itself —
  claimed RM was "the one role that ingests untrusted external content" and "the
  single sanctioned tool-whitelist exception among the seven roles"; both were
  wrong and are corrected. In the Copilot family *every* launcher pins `tools:`,
  and RM is distinguished by lacking `edit`.
- **No new hard-stop; the count stays three.** The doc no longer restates the
  enumeration at all — it cites `MEMORY.md`/`AI.md` instead. Removing a
  restatement is cheaper and more durable than guarding one, and the asymmetry
  made a copy here actively dangerous: this file is `template-replace` and
  propagates on upgrade, while `MEMORY.md` is `manual-merge` and does not, so a
  drifted copy would reach downstreams that never took the corresponding law
  (Governance-Invariant SME, the highest-value edit in its packet).
- **Eight assertions** added to `tools/tests/governance-consistency.test.sh`: the
  quadrant rule, PM's duty line, the RM-research-only clause, the
  not-a-fourth-hard-stop clause, the doc's existence, the creep-check
  instruction, `Hope Creep`, and `Effort Creep`.
- **The checks are bounded to the template-owned half of each file.** A new
  `flat_upstream()` helper stops at the split-merge delimiter before flattening,
  using the repo's proven anchored delimiter pattern (post-F-U
  `find_delimited()`/`seed_violations()` shape) so a prose *mention* of the
  marker phrase cannot truncate the scan — the marker-vs-prose defect class,
  instances 1–3. Five `_pos`/`_neg` self-tests in house style, including the
  masked-section case and the no-delimiter case. The three pre-existing tier /
  Workflow-Ownership checks were routed through it too: leaving four unbounded
  checks beside eight bounded ones is how the wrong idiom survives to be copied.
  A deliberate, flagged widening beyond the minimum fix.

### What the review panel found — including in the verification claims

Three matrix-required SMEs reviewed this change (Governance-Invariant,
Upgrade-Path, Shell/Test-Harness). They found real defects, and the two most
serious were in the *evidence* rather than the design:

- **BLOCKER-class, Shell/Test-Harness: the original checks were unbounded
  whole-file greps.** Four one-line edits were *demonstrated* to delete a
  governance law while keeping the suite green — the realistic one being a
  downstream hand-merge that drops the law from `MEMORY.md` (`manual-merge`) and
  writes a note about it below the delimiter, which is that section's designed
  use. Same defect class as instances 1–3, but failing **open** (false pass)
  rather than closed (spurious FAIL) — the strictly worse direction, arriving in
  the same release that hardened against the better one. Fixed by
  `flat_upstream()`; all four cases re-tested and now fail correctly (3, 3, 1 and
  1 FAILs respectively).
- **Two CHANGELOG over-claims, converged on independently by Governance-Invariant
  and Shell/Test-Harness.** An earlier draft of this fragment said the
  not-a-fourth-hard-stop clause was "asserted mechanically … so a later edit
  cannot quietly promote it", and that the RM clause was "documented as
  load-bearing so a future edit cannot weaken it silently." Neither is true.
  **Nothing in the suite counts hard-stops** — the checks assert a literal string
  has not vanished from the template-owned half of a file, which is strictly
  narrower than "the constraint is still in force." An edit adding a fourth
  enumerated hard-stop while leaving the disclaimer intact stays green. This is
  the milestone's own Hope Creep question turned on its own verification claim,
  and it is exactly the v1.46.0 correction shape (the measurement was fine; the
  sentence above it claimed more). The claims are narrowed here, in the playbook
  entry, and in the doc.
- **Upgrade-Path: the manifest criticality argument was valid at `5d63c7a` and
  invalidated by `1713a20`.** `reference` was chosen on the `docs/model-tiering.md`
  precedent — identical structural position, a detail doc behind an unconditional
  `MEMORY.md` dispatch-brief law. But adding the `[ -f ]` assertion broke the
  condition that precedent rests on, and the playbook states that condition
  explicitly in the 1.33.0 entry: `model-tiering.md` is "explicitly outside the
  governance-scanned invariant set … `governance-consistency.test.sh` does not
  check it." A `reference` file that the guard requires is a contradiction, proven
  by running a simulated lazy adoption to a red guard. **Reclassified to
  `feature`** (required if you run the governance guard — the capability it
  belongs to), with the divergence from `model-tiering.md` explained in both the
  manifest row and the playbook.
- **Upgrade-Path: two dangling `do-not-export` pointers shipped in the new doc.**
  Both `docs/superpowers/` spec references resolve to nothing in a downstream or
  public-mirror clone — a direct recurrence of v1.46.0 item C3, in the milestone
  whose thesis is that pointers must resolve. Annotated per the
  `docs/skill-adoption-model.md` remedy shape.
- **Upgrade-Path: `REQUIRED-IF-ADOPTED` was off-idiom and read as skippable.**
  Every other use in the playbook conditions on a *pre-existing downstream state*;
  here it meant "if you adopt this milestone", which is circular. Relabelled to
  the 1.46.0 form, `REQUIRED (unconditional, if you run the governance guard)`,
  plus a REQUIRED-TOGETHER note (doc + suite) on the 1.29.0 precedent and a
  name-collision note.
- **Governance-Invariant: the unclear-goal cell read as an Operator interrupt.**
  `CLAUDE.md`, `AGENTS.md` and `.github/copilot-instructions.md` phrase the
  hard-stop list as a *ceiling* ("advance without asking permission unless
  hitting a hard-stop"), so a law that says "returns to the Operator" *and* "not a
  fourth hard-stop" lets its own disclaimer license ignoring it. Reworded so the
  cell describes work not being dispatched until scoped — closing the conflict
  **without** editing three entry-point files, which is the enlargement of
  hard-stop-adjacent text this milestone was right to avoid.
- **Governance-Invariant: the creep check fired only on "a returned packet"**, yet
  its one piece of real evidence came from applying Effort Creep to this
  milestone's own work, which has no returned packet. A single-session
  orchestrator would never have triggered it. Scope widened to cover the writer's
  own closeout.
- **Governance-Invariant: likely mis-attribution in a publicly-mirrored file.**
  The draft credited the creep taxonomy to PMI/PMBOK; *hope creep* and *effort
  creep* appear to be Wysocki's terms, and PMBOK does not use them. Corrected,
  explicitly marked `[Likely]` and unverified, and routed to RM
  (`governance-practices`) rather than asserted from memory — mis-attributing a
  named taxonomy is more exposed than a vague credit, because a reader can check
  it.
- **Also corrected:** the doc's exemption said "one SME question, one RM
  question, one read", widening `MEMORY.md`'s "one SME **or** RM question" into
  three steps — an implementation deviation from a spec that had it right.

### Known limits — stated, not implied

- **No guard can verify the judgment was real.** A brief may declare
  "clear/clear" thoughtlessly and pass every check; the creep check may be run as
  a formality. The checks prove the rules are *present in upstream law*, never
  that they were *applied*.
- **Nothing counts hard-stops.** See above. The not-a-fourth-hard-stop clause has
  a drop-detector, not a count assertion.
- **Prose above the delimiter still satisfies a presence check.** `flat_upstream()`
  closes the below-delimiter vector, not this one. A `## Retired Practices` note
  naming a token would satisfy the two creep labels — though the added
  creep-check-instruction assertion means that case now fails the suite anyway (1
  FAIL, verified). Closing it fully needs per-token *section* bounding, which
  couples the guard to `manual-merge` heading text and fails on a rename;
  deliberately not half-solved.
- **`[ -f ]` passes on a 0-byte file** and is decoupled from the pointer text
  (Shell/Test-Harness F6). Low stakes given the eight assertions around it.

### Evidence

- All 14 guard suites green. `/bin/bash tools/export-seed-check.sh --completeness .`
  → `ok - export seed classification complete`.
- The eight assertions demonstrated in both directions: each token removed in turn
  from a verified copy produced exactly one correctly-scoped FAIL, no cascade,
  restore green. Independently re-derived by the Shell/Test-Harness SME (7/7 at
  review time), instrumented specifically against the v1.46.0 crash shape by
  counting the `ok` line independently of the exit code.
- The four demonstrated false-pass cases re-tested against `flat_upstream()`: all
  four now fail.
- The playbook's predicted partial-adoption failure mode verified empirically by
  the Upgrade-Path SME against a synthesized tree (five FAILs, all naming
  `MEMORY.md`, `PM.md` silent).
- bash 3.2.57 and 5.1.4 both green. Note the Shell/Test-Harness SME's adjacent
  correction: the suite's `export PATH="/bin:$PATH"` pin is *inert here* — it
  cannot change an already-running interpreter and this suite makes zero child
  `bash` calls. The additions are 3.2-safe on their own merits (POSIX `tr`,
  `grep -q`, `[ -f ]`, `awk`), not because of the pin. This also narrows the
  guard-hardening thread's "pin extended to all 14 suites" claim for three
  suites; flagged for CM, not corrected here.
- Budgets after the edits: `MEMORY.md` and `minions/roles/PM.md` both under
  budget (see the release-gate report).

### Provenance

The Operator surfaced a third-party PM skill repository which has no LICENSE
(default copyright, all rights reserved). This template is publicly mirrored, so
the constraint is not theoretical. **No text from it is copied.** The underlying
frameworks are Wysocki's Project Landscape model and the standard creep
vocabulary, attributed in the doc; the prose, the bindings to this repo's roles
and gates, the worked examples, and the security rationale are original. This is
a charter and law edit, **not** a `MINION_SKILLS` airlock adoption — nothing of
theirs executes and nothing is vendored. The source URL and its repository
metrics are recorded in the maintainer-local spec rather than here, since this
fragment assembles into the public `CHANGELOG.md` (Export/Privacy concern raised
by the Governance-Invariant SME and routed to Export/Privacy).

### Out of scope

- Phase 2 (the Scope Triangle as Operator-facing trade-off vocabulary) —
  deferred, deliberately not stubbed.
- The `minion-version.md` bump to 1.47.0 (release-gate action). Note the
  Upgrade-Path SME's warning: the 1.47.0 playbook heading must broaden to cover
  the other two pending fragments (`guard-hardening`, `doc-freshness`) before the
  gate passes, since the required-changes obligation is per-release, not
  per-fragment.
- The general doc-pointer-resolution sweep (no guard verifies that *any*
  governance pointer resolves) — filed in `TODO.md`. Both the Shell/Test-Harness
  SME and the TODO entry's own reasoning argue for doing it sooner than "later".
- `AM.md`'s Outputs section does not enumerate "architecture spec" as a
  deliverable, though the new law mandates one (Governance-Invariant OBS 9). AM
  charter change, not taken here.
- The `docs/export-manifest.md` `tools/tests/` row enumerates 11 suites but 14
  exist. Pre-existing drift, same class as the open Doc Freshness TODO item.

## 2026-07-30 (v1.47.0 — Guard hardening: bash-3.2 pin across all 14 suites; marker-vs-prose defect class contained)

- Commit hash: (staging→main merge; assigned at merge) — workstream commit `89aefe6`, merged to dev at `1e0f661`; precision note added at assembly
- **Item 1 — bash-3.2 pin extended from 1 of 14 suites to 14 of 14.**
  `tools/tests/export-seed-check.test.sh` was the only harness carrying the
  internal `export PATH="/bin:$PATH"` pin (v1.46.0 Fix 3); the other 13
  relied on the caller typing the prefix, so "verified on bash 3.2" was true
  by construction for one suite only. The same pin now opens all 14
  `tools/tests/*.test.sh` files, right after their `set -uo pipefail` line.
  Evidence: all 14 suites pass under a plain `bash "$t"` invocation with no
  manual PATH prefix (the acceptance-critical case — the guarantee is now
  structural), and again under a deliberately hostile PATH with Homebrew
  bash first (`/usr/local/bin:/opt/homebrew/bin:$PATH`), confirming the
  internal pin wins over PATH order. No new bash-3.2 defects surfaced in the
  13 newly-pinned suites (contrast with `be53b13`, which the export-seed-
  check pin caught on its first real use one day earlier).
  **Precision note on that null result** (Shell/Test-Harness SME, F2): it is a
  genuine exercised negative for 11 of the 13, verified by instrumenting a
  hostile-bash wrapper and sweeping every suite — exactly one hostile
  invocation each (the outer harness launch, before its own pin runs) and zero
  leaks into any child, plus a positive control proving the exec-path pin
  catches a bash-4-only construct.
  **Second precision note, added at 1.47.0 assembly** (Shell/Test-Harness SME,
  reviewing the judgment-model branch): in three suites the pin is not merely a
  narrow measurement, it is **inert**. `export PATH="/bin:$PATH"` cannot change
  an already-running interpreter — `#!/usr/bin/env bash` resolves before line 9
  executes — so it only redirects *child* `bash` invocations. Demonstrated with
  a minimal same-shape script: interpreter 5.1.4 while a child `bash` resolves
  to 3.2.57. `governance-consistency.test.sh`, `manifest-completeness.test.sh`
  and `skill-scout.test.sh` make **zero** child `bash` calls, and `/bin` carries
  no `grep`/`tr`/`awk`/`sed`/`sort`/`mktemp`, so nothing in those three resolves
  differently with the pin than without it. They are 3.2-safe on their own
  merits (POSIX constructs only), not because of the pin. "Extended the pin to
  all 14 suites" is true as a statement about the files; it is not true that the
  pin does work in all 14. The other 11 do exec child bash and the pin governs
  them as intended.
  But `governance-consistency.test.sh` and
  `manifest-completeness.test.sh` never exec a `tools/*.sh` at all — they are
  self-contained scanners that read other files as *text*, never as *executed
  code*. Their pin proves their own inline awk/grep syntax is 3.2-safe and
  nothing more. "13 suites, no new defects" is true; it is not uniform, and 2
  of the 13 could not have surfaced an executed-code defect even in principle.
- **Item 2 — marker-vs-prose defect class, instance 3 fixed + mechanical
  detector added.** `tools/sme-charter-check.sh`'s `section_nonempty()` used
  a bare `index($0,"DOWNSTREAM CONTENT BELOW")` substring test to find the
  split-merge delimiter — the same shape as the F-U defect fixed in
  `seed_violations()` at v1.45.0, except fail-closed here (a false "section
  empty" FAIL only, never a false pass). Fixed to the same anchored pattern
  `find_delimited()`/`seed_violations()` use:
  `$0 ~ /^[[:space:]]*<!--.*DOWNSTREAM CONTENT BELOW.*-->/`.
- Added a `bare_marker_index()` detector to
  `tools/tests/governance-consistency.test.sh`: flags any `tools/*.sh` guard
  implementation containing an awk `index($N, "TOKEN")` call against one of
  the two known structural marker tokens (`DOWNSTREAM CONTENT BELOW`,
  `STUB BOUNDARY`). Scoped deliberately to that one proven shape — both real
  defects were awk `index()` bare-substring calls — rather than every
  conceivable substring test, to avoid manufacturing false positives on
  legitimate `case`/`grep` uses with no observed defect instance. Scans
  `tools/*.sh` only, not `tools/tests/*.sh` (which legitimately quotes
  past-defect code in prose, e.g. this file's own F-U comment). Self-tested
  (positive/negative fixtures) and demonstrated both directions per house
  rule: catches a reconstructed pre-fix instance-3 line, and passes the live
  post-fix `tools/sme-charter-check.sh`.
- Instance 4 (`docs/runbooks/public-export.md`'s prose teaching the
  personal-context token) is explicitly out of scope for mechanical
  detection — handled manually at each export per existing runbook
  discipline; the detector targets guard-script logic, not documentation
  prose about tokens.
- Evidence: all 14 suites green under normal and hostile PATH (see Item 1);
  `governance-consistency`, `instruction-size`, `manifest-completeness` all
  green; `/bin/bash tools/export-seed-check.sh --completeness .` ->
  `ok - export seed classification complete`;
  `tools/tests/sme-charter-check.test.sh` -> 8/8 passed (including the
  live-repo canonical-charters case); `tools/tests/governance-consistency.test.sh`
  -> `ok - governance consistent` (40 scanned surfaces, includes the new
  `bare_marker_index` self-tests and regression demonstration).
- Out of scope (per dispatch brief): `SEED_ANCHORS` completeness backstop,
  the two next-public-export preconditions, `TODO.md` retirement, version
  bump (mined at consolidation), `second-brain.sh` SM-7/SM-9.

## 2026-07-30 (v1.47.0 — Doc freshness: `docs/MECHANICS.md` code map re-verified and re-stamped)

- Commit hash: (staging→main merge; assigned at merge) — workstream commits `7afec03`, `5e9c75a`
- **`docs/MECHANICS.md` re-verified against HEAD and re-stamped**
  `verified @ 6ffc721` → `verified @ 4eba0c0`. The stamp had gone 11 commits
  stale across four mapped areas (`tools/` 9×, `tools/tests/` 7×,
  `minions/smes/` 2×, `.claude/` 1×, `minions/roles/` 1×), so every `/onboard`
  was correctly reporting the code map PARTIAL.
- **Re-verification result: the map's inventories were already accurate.** All
  11 `tools/*.sh` and all 14 `tools/tests/*.test.sh` suites are named correctly
  (4 repo-wide + 10 per-tool), the governance bootstrap order matches
  `CLAUDE.md`'s read-chain, and the release/export flow descriptions still
  hold. The 11 drift commits changed behavior *inside* mapped areas without
  changing the component inventory the map records at its stated altitude —
  worth recording, because a PARTIAL flag says "verify", not "wrong".
- **Two genuine inaccuracies found and fixed**, both in the
  `.claude/commands/` bullet:
  1. It described `onboard` as landing "once Task 2 lands". The command shipped
     with the session-onboarding feature — `.claude/commands/onboard.md` exists
     and `minions/capabilities.md` lists `/onboard` as `active`.
  2. It claimed all five command behaviors are defined tool-neutrally in
     `docs/minion-prompt-modes.md`. True for `handoff`, `ship`, and `onboard`;
     `delegate` and `second-opinion` are defined in
     `docs/cross-tool-orchestration.md`. The bullet now names both sources, so
     a non-Claude orchestrator implementing command parity is not sent to a
     file that never documented two of the five.
- `TODO.md`: the open Gitea transient-failure consolidation item was updated
  from two entries to three, with a note that the new 2026-07-29 entry raises
  its priority — that entry invalidates the `ls-remote | grep` verification the
  2026-07-03 entry prescribes, so the consolidated runbook note must carry the
  non-empty-output assertion rather than only "retry once".
- Evidence: all 14 guard suites green (`archive-reporter` 61, `export-seed-check`
  50, `instruction-size` 59, `issue-board-bootstrap` 36, `issue-sync` 68,
  `layer-adopted` 22, `manifest-completeness` 29, `second-brain` 177,
  `skill-airlock` 32, `skill-scout` 15, `sme-charter-check` 8,
  `upgrade-classify` 37, `xtool-call` 65, `governance-consistency`
  `ok - governance consistent`). Re-stamp follows the `ae52835` precedent
  (stamp = the sha verified against = the map commit's parent).
- **Re-stamped a second time at the 1.47.0 dev merge** (`4eba0c0` → `6f79885`).
  Merging `feature/pm-judgment-model` touched two mapped areas (`tools/tests/`,
  `minions/roles/`), which correctly flipped the map back to PARTIAL. Re-verified
  before re-stamping: the merge added no tool, no test suite, no command, and no
  role (11 / 14 / 5 / unchanged), so the map's inventories still hold and only
  behavior inside mapped areas changed. Worth recording as the expected rhythm —
  a `verified @` stamp goes stale at every merge into a mapped area, and the
  re-stamp is a re-confirmation, not a formality.
- Out of scope: the remaining Doc Freshness backlog items
  (`public-export.md` enumeration drift, `skill-adoption-model.md` describing
  shipped tooling as absent, the two stale `(in flight)` markers in
  `feedback.md`, spec `Status:` line reliability) and the DM-owned Gitea-entry
  consolidation itself.

## 2026-07-29 (v1.46.0 hotfix — `tools/second-brain.sh` bash 3.2 colon-tag mapping; not milestone scope)

- Commit hash: (staging→main merge; assigned at merge)
- **Not part of the Boundary Coverage milestone.** An unrelated, pre-existing
  defect in `tools/second-brain.sh`'s colon-to-slash tag mapping
  (`branch:dev` -> `branch/dev`), reproducing identically on `9f23c33` —
  before `feature/boundary-coverage` merged — and the milestone never
  touched this file. It became visible only because this same milestone
  pinned the guard harness to bash 3.2 (`PATH=/bin:$PATH`); the fix
  (commit `be53b13` on `staging`) was made solely because it was blocking
  the v1.46.0 promotion gate, not as milestone scope.
- `tools/second-brain.sh:229`: bash 5.x strips the backslash before `/` in a
  `${var//pattern/replacement}` replacement text; bash 3.2 (this repo's
  target shell, macOS stock `/bin/bash`) does not, so the intended
  `${tn//:/\/}` emitted the literal `branch\/dev` instead of `branch/dev`
  for every colon-namespaced tag captured with `MINION_SECONDBRAIN=on`.
  Fixed by substituting via a `slash='/'` local variable
  (`${tn//:/$slash}`), removing the escaping ambiguity — behavior identical
  across both interpreters. Two other known pre-existing `second-brain.sh`
  defects (`TODO.md`: SM-7 short-write exit status, SM-9 `SOLE-HOLDER:`
  literal-substring match) are explicitly out of scope for this hotfix.
- Every other `${var//pattern/replacement}` expansion in `tools/*.sh`
  audited for the same bash-3.2 escaped-replacement exposure
  (`second-brain.sh:138` `yaml_dq`; `xtool-call.sh:57-59`); none found.
- Evidence: `PATH="/bin:$PATH" bash tools/tests/second-brain.test.sh` ->
  177/177, 0 failed (including the previously-failing fixture at `:434` and
  its `migrate-frontmatter` sibling at `:782`). Side-by-side repro
  confirmed pre- and post-fix under both `/usr/local/bin/bash` (5.1.4) and
  `/bin/bash` (3.2.57). Full 14-suite guard battery green under `/bin/bash`
  3.2.57; `/bin/bash tools/export-seed-check.sh --completeness .` ->
  `ok - export seed classification complete`.

## 2026-07-29 (v1.46.0 — Boundary Coverage: seed-only marker enforced inbound + outbound; `AI.md` / `docs/export-manifest.md` split-merge delimiters)

- Commit hash: (staging→main merge; assigned at merge)
- **Three independent reports converged on one property this milestone
  closes.** The seed-only boundary (the five `seed only` files —
  `feedback.md`, `ROADMAP.md`, `TODO.md`, `docs/MECHANICS.md`,
  `docs/DESIGN.md`) was specified OUTBOUND (public export strips the
  marker) but never enforced INBOUND (adoption); the split-merge delimiter
  pattern already covered some governance surfaces (`MEMORY.md`,
  `minions/smes/README.md`, `minions/review-matrix.md`,
  `minions/capabilities.md`) but not `AI.md` or `docs/export-manifest.md`;
  and the gate meant to guard the outbound half could not distinguish
  "reset correctly" from "never had a marker." Sources: the v1.45.0
  pre-push SME panel (Export/Privacy F1 — `docs/MECHANICS.md` shipped a
  live `verified @ 6ffc721` into a fresh-history repo), Gitea #55 §2 (same
  SHA, inbound, hit by a downstream adopting from source), Gitea #56 §6
  (same marker, outbound, gate vacuous on a repo that never had one).
- **WS-B — `AI.md` and `docs/export-manifest.md` gain split-merge
  delimiters** (`## Template/Downstream Split` in `AI.md`, following
  `MEMORY.md`'s prose shape; `## Downstream Additions (this repo)` in the
  manifest, following the registry-shape siblings). Closes the gap where a
  downstream override had no additive home and had to be expressed as an
  in-place rewrite of template prose (Gitea #56 §1). Both files enrolled in
  `tools/export-seed-check.sh`'s `WAIVER` list. This is the deliverable;
  the delimiters are its consequence.
- **WS-A wave 1 — `tools/export-seed-check.sh` gains the seed-only marker
  pair.** Leg S (`--completeness` mode) asserts every manifest `seed only`
  path CARRIES a `STUB BOUNDARY` marker in source; Leg E (export-tree/
  `both` mode) asserts none survives — retiring the runbook's old gate-5
  grep and collapsing gates 4+5 into one invocation. Plus `SEED_ANCHORS`/
  `anchor_violations()`, asserting `docs/MECHANICS.md`'s above-marker
  `verified @ <sha>` / `Mapped areas:` lines read back as literal
  placeholders in the export tree. `feedback.md` gains its own marker in
  the same commit (Leg S would otherwise fail on canonical immediately).
  18 new fixtures.
- **Wave 2a (A5 + WS-C doc-sync sweep):** Onboarding Mode gains a third
  code-map state (`unverified`) for an unresolvable sha; `minions/roles/
  DM.md`'s Class-A enumeration corrected (a fifth drifted enumeration
  site); `CLAUDE.md` gains the archive-reporter partial-surface note; four
  dangling `docs/superpowers/` pointers resolved; `docs/downstream-
  upgrade-playbook.md` notes v1.42.0/v1.43.0 tag the same commit.
- **Wave 2b (A6 + retired-gate-5 sweep):** `docs/runbooks/public-export.md`
  stops hand-maintaining the seed-only file roster — the drifted four-
  bullet list that omitted `docs/MECHANICS.md` was the proximate cause of
  the v1.45.0 mis-publish. Both call sites now point at the manifest as
  sole authority via a new `manifest_seed_paths()`. Stale gate-5 references
  fixed on two shipped surfaces.
- **Panel-fix round 1 — bash 3.2 unbound-variable fix**, found by the
  Shell/Test-Harness SME: two zero-array `"${arr[@]}"` expansions under
  `set -u` were fatal on bash 3.2 (this repo's target shell) — one crashed
  the whole run precisely on the "no markers adopted yet" state Leg S
  exists to catch; the other crashed only its subshell, so the parent
  script printed `ok` and exited 0 while silently skipping the anchor
  check. Both guarded with the file's existing zero-array idiom. Six suite
  assertions strengthened to check FAIL message text, not just exit code —
  a crash also exits 1, so the suite had reported 37/37 while actually
  crashing on the required-failure fixtures.
- **Panel-fix round 2 — git-grep blindness in `find_marked()`**, found by
  the Export/Privacy SME and independently reproduced by CM and PM:
  `git grep` only sees tracked paths, so an export tree whose copied-in
  seed-only files were not yet `git add`ed went invisible to Leg E,
  returning a false-clean gate over an unreset tree. Now gated on scan
  mode, not "is this a git work tree." New regression fixture F-S.
- **Panel-fix round 3 — gate-stack re-review: a correctly-prepared export
  tree still could not go green**, found by the Export/Privacy SME by
  building a real manifest-filtered export tree and running the actual
  gates (invisible to the diff and to a fixture suite that was green on
  canonical): `STUB_PATTERN`'s leading-whitespace allowance matched the
  playbook's own indented, code-fenced example of the marker, reading
  documentation *about* the marker as a live one — anchored to column 0
  (fixture F-D2). `seed_violations()`'s bare `index()` substring match read
  a prose mention of the delimiter phrase in `docs/export-manifest.md` as
  the delimiter itself, flagging 200 false FAILs on the legitimate Manifest
  table — now uses `find_delimited()`'s same anchored matcher (fixture
  F-U). Three fixtures (case 12, F-I, F-R) re-rooted off the live-repo path
  onto synthetic trees — they had asserted Leg S (a source invariant)
  against a tree whose markers Step 2 had just stripped, so gates 1 and 4
  were mutually unsatisfiable by construction. The harness itself pinned to
  bash 3.2 (`PATH=/bin:$PATH`) — it had invoked the script under test as
  plain `bash` (resolving to 5.1.4), so every prior "verified on bash 3.2"
  claim from this suite, including several made during this same
  milestone's own review, was false by default. New fixture F-T proves the
  round-1 zero-array guard is actually load-bearing. Suite 45 → 50;
  verified end to end on a real export tree passing both gate 4 (exit 0)
  and gate 1 (all 14 suites inside the tree).
- **DM re-review wave — playbook accuracy/durability fixes**, found by the
  Upgrade-Path SME ("instructs but not shippable"): fixed a wrong
  flagship-command path, a mechanism stated backwards (the public-export
  strip *removes* the marker, never adds it), and three files
  (`TODO.md`, `ROADMAP.md`, `docs/DESIGN.md`) still claiming
  `export-seed-check.sh` "does not apply." Added the missing
  REQUIRED-IF-YOU-PUBLISH `SEED_ANCHORS` obligation (two new hard gate-4
  conditions this release introduces). Closed the durability gap: the
  marker instruction now lives in a permanent `### seed-only STUB BOUNDARY
  marker` subsection under Manual-Merge Guidance, not a one-time
  version-entry notice that expires on the next release. Corrected
  `upgrade-classify.sh`'s `LIVE=diverged` framing (a candidate flag, not a
  signal — it only ever compares LIVE against OLD, never against NEW) and
  several accuracy/completeness fixes across the playbook.
- **DM panel-doc wave — the 1.46.0 playbook entry rewrite (the central
  deliverable) + doc-sync:** rewrote `docs/downstream-upgrade-playbook.md`'s
  1.46.0 entry as a followable procedure instead of a warning — added the
  unconditional REQUIRED marker-adoption action (DM's own finding, the
  panel's highest severity: every existing downstream's five seed-only
  files never received a `STUB BOUNDARY` marker, since the strip that adds
  it runs only on canonical, never on a downstream's live copy), fixed the
  entry's self-contradiction on the `AI.md`/manifest gate-4 reset
  obligation, replaced an unreachable "diff against the template's
  pre-1.46.0 copy" instruction with the real base (the downstream's own
  recorded `minion-version.md` version) plus the `tools/upgrade-
  classify.sh` mechanical detector, and added OPTIONAL/RECOMMENDED coverage
  for four previously-uncovered 1.46.0 changes. `docs/export-manifest.md`
  and `docs/runbooks/public-export.md` doc-synced to match.
- Reviewed across two panel rounds by the Shell/Test-Harness, Export/
  Privacy, and Upgrade-Path SMEs (each finding independently verified and
  fixed), with CM and PM independently reproducing the git-grep finding.
  OM-Test validated the dev→staging promotion. Full `tools/tests/*.test.sh`
  suite green (14 suites, `/bin/bash` 3.2.57, 50/50 in
  `export-seed-check.test.sh`), `governance-consistency.test.sh`,
  `instruction-size.test.sh`, `manifest-completeness.test.sh`, and
  `export-seed-check.sh --completeness .` all green. No governance-token
  change, no new hard-stop.
- **REQUIRED for every existing downstream:** add the `STUB BOUNDARY`
  marker to your five `seed only` files (`feedback.md`, `ROADMAP.md`,
  `TODO.md`, `docs/MECHANICS.md`, `docs/DESIGN.md`) before running the
  test-suite guard — no version of the template has ever shipped you this
  line, and the guard now fails on all of them unconditionally, whether or
  not you publish. **REQUIRED-IF-ADOPTED:** a one-time `AI.md` /
  `docs/export-manifest.md` delimiter migration if either file carries an
  in-place override. **REQUIRED-IF-YOU-PUBLISH:** confirm or add the
  matching `SEED_ANCHORS` row for any `seed only` surface you have filled
  in with your own above-marker fields. This is not a "no required
  changes" release — see `docs/downstream-upgrade-playbook.md`'s 1.46.0
  entry for the full procedure.

## 2026-07-22 (v1.45.0 — Design/UX Reviewer SME: first product-domain reviewer in the bench)

- Commit hash: (staging→main merge; assigned at merge)
- **New Design/UX Reviewer SME (`minions/smes/design-ux.md`)** — the Default
  Bench's 7th member and its **first product-domain (craft)** reviewer; every
  prior default-bench SME was infrastructure/template-plumbing. It gives an
  advisory, findings-only (ship/iterate/block) read on the visual, interaction,
  and accessibility quality of user-facing changes — distinct from correctness
  (CM), security (SM), architecture (AM), or content-truth (DM), with those
  adjacent domains named in its Do Not Consult For.
- **Charter + 3 cross-family launchers** (`sme-design-ux` in Claude/Codex/
  Copilot, behaviorally identical), a Default Bench registry row
  (`minions/smes/README.md`), and 3 routing rows in `minions/review-matrix.md`
  — all above the split-merge delimiter (template-owned, converge on upgrade).
- **New `docs/DESIGN.md` — a `seed only`, downstream-owned convention** the SME
  reviews against (the design analogue of `docs/MECHANICS.md`): the template
  ships the structure + placeholder shape (tokens, typography, layout, a11y
  targets, component states, theming, motion) with a `STUB BOUNDARY` marker;
  each downstream fills its real values.
- Built subagent-driven and reviewed by a **4-SME matrix panel** —
  Cross-Family Launcher (launchers byte-identical), Governance-Invariant
  (charter boundaries disjoint, guardrails intact), Export/Privacy (SAFE —
  `DESIGN.md` seed generic, gate-5-visible), Upgrade-Path (1.45.0 entry +
  collision guidance). SME core cleared on first pass; conditions were
  doc-wiring only. OM-Test validated the dev→staging promotion (14/14).
  No governance-token change, no new hard-stop.

## 2026-07-22 (v1.44.0 — session onboarding command + living code map)

- Commit hash: (staging→main merge; assigned at merge)
- **New `/onboard` command + tool-neutral Onboarding Mode.** Deterministic
  session-start onboarding: the **Onboarding Mode** (`docs/minion-prompt-modes.md`)
  plus its Claude launcher (`.claude/commands/onboard.md`) execute the
  `CLAUDE.md` read-chain to completion, read `docs/MECHANICS.md` and flag its
  staleness, check `minions/handoffs/` for a pending snapshot (absorb into the
  ready-state, **hold** the delete), surface `MINION_*` gates, and emit a
  ready-state report — the forcing function that turns "did you actually read
  your own rules" from a silent read into a visible, checkable artifact. It is
  the read-only inbound complement to `/handoff`; it mutates nothing.
- **New `docs/MECHANICS.md` — a living code map.** The system-at-a-glance
  (components, entry points, guard surface) that the process/governance docs
  never covered — the pragmatic, no-dependency fill for the `absent`
  codebase-intelligence slot. It carries a `verified @ <sha>` + `Mapped areas:`
  staleness contract that `/onboard` reads to flag the map FRESH or PARTIAL.
  Always-read summary is instruction-size budgeted (enforced by the guard);
  `AM` owns it under the Documentation Sync Rule and re-stamps `verified @` on
  re-confirmation, `DM` does doc-sync. Ships **seed-only** (template dogfoods
  its own map, downstream fills its own).
- **Wiring:** `minions/roles/AM.md` (ownership duty), `minions/capabilities.md`
  (Default-Capabilities row, `/onboard` usable in all three environments via
  the tool-neutral mode), `MEMORY.md` (short unconditional pointer),
  `docs/export-manifest.md` (rows), `docs/downstream-upgrade-playbook.md` (1.44.0
  entry).
- Built subagent-driven across three tasks, each reviewed by the matrix-routed
  SME (Shell/Test-Harness proved the budget guard fires; Governance-Invariant
  verified the hard-stop enumeration; a closeout panel of Export/Privacy,
  Upgrade-Path, and Cross-Family Launcher applied conditions). `/onboard`
  dogfooded live (staleness correctly flagged PARTIAL, zero mutation);
  OM-Test validated the dev→staging promotion (14/14 suites). No
  governance-token change, no new hard-stop.

## 2026-07-21 (v1.43.0 — archive reporter: read-only repo-thinning tool)

- Commit hash: (staging→main merge; assigned at merge)
- **New `tools/archive-reporter.sh` — a read-only reporter of stale coordination
  units.** As a project ages, closed `minions/mail/` packets, `minions/plans/`,
  and `minions/chat/` threads accumulate and become high-impact grep and recall
  noise. The reporter lists the units safe to archive — closed (by their
  `Status:` marker) and aged — and **prints** the `git rm` + `minions/ARCHIVED.md`
  row commands for a human or orchestrator to run at a milestone boundary. It
  never mutates the tree, has no `run` subcommand, and needs no `MINION_*` gate;
  the person running the printed command is the safety boundary.
- **Predicate:** closed reuses the existing `Status:` lifecycle (position-bound
  to the first 10 lines / column 0 / outside fenced blocks; directory units read
  `verdict.md` → `response.md` → `request.md`) AND aged (git last-commit time,
  default 30 days, floor 7, `MINION_ARCHIVE_AGE_DAYS` override; shallow-clone
  empty git-log → not-aged). **Screens:** sole-holder (tolerant pattern incl.
  Unicode dashes), referenced-by-live-surface (immutable ledgers exempt),
  not-removable (uncommitted / untracked / subdir / symlink / non-text / `.issue`).
- **Safety enforced two ways** in `tools/tests/archive-reporter.test.sh` (61
  cases, bash-3.2.57 + 5.1): a behavioral no-mutation test (snapshot tree, run,
  assert byte-identical) as the load-bearing gate, plus a textual detector that
  catches a mutating verb or repo-path redirect added by a future edit.
- **`minions/ARCHIVED.md`** (the migration index) is Class A / downstream-owned /
  not exported — created downstream on first prune; the manifest pre-classifies
  it so `manifest-completeness` stays green when the first row is appended. Class-A
  pruning (`chat/` + `ARCHIVED.md`) happens on the integration mainline at the
  milestone gate, never as an off-branch touch.
- Built as the proportionate read-only subset chosen over a full automated-sweep
  design (three review rounds; SHIP-WITH-CONDITIONS from SM + Shell/Test,
  NEEDS-WORK-on-proportionality from AM — the automated `run` path and ledger
  thinning are deferred, see `TODO.md`). Reviewed by Shell/Test-Harness SME
  (code; a read-only-invariant-test BLOCKER + a ledger-regex MINOR fixed and
  re-verified) and by Governance-Invariant + Export/Privacy + Upgrade-Path SMEs
  (wiring; all conditions applied). Docs: new `docs/archive-reporter-model.md`;
  `MEMORY.md` Coordination-Surface Hygiene; `minions/roles/PM.md` milestone duty;
  `minions/capabilities.md` row; `AI.md` / `AGENTS.md` /
  `.github/copilot-instructions.md` partial-surface note. OM-Test validated the
  promotion (14/14 suites, zero-mutation runtime, guards green). No
  governance-token change, no new hard-stop.

## 2026-07-18 (v1.42.0 — TODO.md / ROADMAP.md surfaces: `seed only` export class)

- Commit hash: (staging→main merge; assigned at merge)
- **`TODO.md` and `ROADMAP.md` now exist, closing a self-application gap.**
  `MEMORY.md` (Shared Rules) has declared both required since the baseline, and
  `docs/export-manifest.md` classed them "currently required by the workflow but
  not shipped as a template file" — so the template mandated two surfaces it
  neither shipped nor maintained, and every downstream adopter started by
  inventing the format. Both files now exist in canonical with real content.
- **Manifest reclass `downstream required` → `seed only`** for both rows,
  adopting the existing `feedback.md` precedent (`Initial export: seed only`,
  strategy `downstream-owned`): the template ships the *shape* — section
  structure, status/horizon conventions, ownership and Class-A notes — while the
  repo's own backlog and direction stay canonical-only. Downstreams get a usable
  scaffold instead of a bare requirement; they keep their own content on upgrade.
- **Public-export Step 2 item 4 generalized from one file to a class** — it now
  resets every `seed only` surface and defers to the manifest as the authority on
  membership; **new Step 1 item 2a** copies `seed only` rows explicitly (the
  class is enumerated mechanically via `grep 'seed only' docs/export-manifest.md`);
  **new Step 3 gate 5** fails closed on a surviving `STUB BOUNDARY` marker (the
  grep is anchored, for the same reason `export-seed-check.sh` anchors its
  delimiter scan). Coverage limit stated: gate 5 sees only marker-bearing files
  (`TODO.md`, `ROADMAP.md`); `feedback.md`'s reset stays operator-verified, with
  the durable `export-seed-check.sh` `seed only` leg filed in `TODO.md`.
- **New `Initial Export Meanings` legend** in `docs/export-manifest.md`; **new
  onboarding step 7a** ("take the seed, then own it"). Both new files are
  downstream-owned in full (no template-managed half), so the split-merge
  machinery does not apply and the `STUB BOUNDARY` markers are labelled as
  distinct from the `DOWNSTREAM CONTENT BELOW` token.
- Reviewed by the two `minions/review-matrix.md` reviewers required for a
  manifest/export change: Export/Privacy SME (`seed only` is correct, explicitly
  against `do-not-export`; found F1 + a dangling reference) and Upgrade-Path SME
  (`seed only` + `downstream-owned` correct; found the onboarding contradiction,
  the missing legend, and the missing version entry; confirmed
  `tools/upgrade-classify.sh` behavior byte-identical). No governance-token
  change, no new hard-stop, no `MEMORY.md` edit.

## 2026-07-17 (v1.41.0 — capabilities.md split-merge; manifest-completeness downstream scope)

- Commit hash: (staging→main merge; assigned at merge)
- **`minions/capabilities.md` becomes a split-merge file (#45).** It was
  `downstream-owned`, so a downstream that customized (or dropped a row from) its
  copy silently missed every later template capability-row change — including
  updates to a capability it was actively running. It now has a template-shipped
  **Default Capabilities** block above a `<!-- … DOWNSTREAM CONTENT BELOW … -->`
  delimiter (`template-replace`; carries `tools/second-brain.sh` + repowise,
  which now ship and upgrade) plus a downstream-owned **Local Inventory** below —
  the same two-tier pattern as `minions/smes/README.md`. Activation *status*
  stays the downstream's (recorded in the onboarding-checklist Optional Layers or
  a Local Inventory override row); only a row's DESCRIPTION is template-owned.
  Wiring: manifest reclass `downstream-owned` → `template-replace`;
  `export-seed-check.sh` `SEED_FILES` += `capabilities.md` (below-delimiter resets
  to header-only at export); public-export runbook Step 2 reset; MEMORY.md
  Capability-Inventory + Optional-Layers update; a 1.41.0 upgrade entry with a
  REQUIRED-IF-ADOPTED one-time delimiter migration + dedup (the second-brain/
  repowise rows now ship above the delimiter). Reviewed by a 4-SME panel
  (Shell/Test-Harness + Export/Privacy SHIP-CLEAN — the latter a net privacy
  improvement; Governance-Invariant + Upgrade-Path cleared after doc fixes).
- **`manifest-completeness.test.sh` stays green on a conformant downstream (#44).**
  It flagged the committed `.minions-template/` vendored snapshot and a
  downstream's own project code as UNCOVERED. Now the snapshot
  (`.minions-template/`, `.minions-template.next/`) is excluded built-in, and a
  fail-open `tools/tests/manifest-completeness.allow` (the analogue of
  `governance-scan.allow`) lets a downstream list its own paths — with an
  over-broad-entry reject so a `*` can't silently neuter the guard (Shell/Test-
  Harness SME finding). The template ships the allow file with no active entries.
- Also backfilled the missing **1.40.0** and **1.39.1** upgrade-playbook entries
  (the #43 completeness invariant), and neutralized a downstream project name in
  a `governance-consistency.test.sh` comment (it had been public in the mirror
  since v1.38.0 — a bare-surname neutralization-sweep miss now fixed at source).
- Closes #44, #45. All 13 suites green.

## 2026-07-17 (v1.40.0 — second-brain frontmatter YAML safety + migrate-frontmatter)

- Commit hash: (staging→main merge; assigned at merge)
- **Bug fix (#47):** `tools/second-brain.sh` wrote `title:` and `source:` into
  frontmatter **unquoted** (in the shared `write_note`, so both `capture` and
  `capture-batch`). A value with a colon-space or a leading YAML indicator char
  is invalid YAML — Obsidian then parses no frontmatter and **silently drops
  every tag** on the note. Both are now emitted as double-quoted,
  backslash/quote-escaped YAML scalars (new `yaml_dq` helper).
- **Fix (#49):** tag values are now mapped `:` → `/` before emit (Obsidian tag
  names allow only `[A-Za-z0-9_/-]`; `/` is the nested-tag form and preserves a
  `branch:dev`-style namespace's intent). The colon-tag *protocol* doc that
  prompted #49 is downstream-authored and remains the downstream's to update.
- **New `migrate-frontmatter` subcommand** fixes existing notes captured by
  older versions: re-quote a breaking `title:`/`source:` scalar and map `:` →
  `/` in block-list tags. Frontmatter-only (body untouched), backup-first under
  a timestamped `.sb-frontmatter-backup-<ts>/` dir, idempotent, and precise
  (leaves a valid unquoted `http://x` / `ratio 3:1` and non-`tags:` colon items
  alone). Run `migrate-tags` first if a vault still has inline-array tags.
- Shell/Test-Harness SME review cleared it after a CONFIRMED data-integrity fix:
  `migrate-tags`'s find-prune excluded only `.sb-tag-backup-*`, so running both
  migrators could mutate the other's backup snapshots — both now prune both
  backup globs (cross-migrator regression tests added).
- bash-3.2-safe (verified under stock `/bin/bash` 3.2.57); output validated
  against a strict YAML parser. Docs: `docs/second-brain-model.md` Tool
  Reference + a Frontmatter-YAML-safety note; `minions/capabilities.md`. Suite
  177/0; all 13 suites green. Closes #47, #49.

## 2026-07-17 (v1.39.1 — upgrade-playbook + SME-checklist completeness)

- Commit hash: (staging→main merge; assigned at merge)
- Docs-only. `docs/downstream-upgrade-playbook.md` Version-Specific Required
  Changes gained the missing **v1.38.0** and **v1.39.0** entries (both "No
  required changes — adopt normally"), so a downstream upgrading across them
  confirms rather than infers that nothing is required (issue #43).
- `docs/downstream-upgrade-playbook.md` 1.34.0 entry: added a
  REQUIRED-IF-ADOPTED one-time-dedup bullet for a downstream that adopted the
  canonical SME bench VERBATIM below the delimiter (the split-merge otherwise
  double-registers every default-bench SME), mirroring the 1.28.0 one-time
  delimiter-move note (issue #37).
- `minions/smes/README.md` Adding-an-SME checklist + the 1.34.0 CAUTION:
  documented that since 1.34.0 the `minions/smes/*.md` and `sme-*` launcher
  globs are `template-replace` (exportable by default), so a private downstream
  SME must carry a `do-not-export` row for its charter + launchers — and, per
  Export/Privacy SME review, the operator must also sweep the SME's key/name as
  a neutralization token tree-wide (files-excluded-but-name-echoes is a real
  leak class) (issue #38). `docs/export-manifest.md` gained a Row-precedence
  note (a specific `do-not-export` row overrides a broader exportable glob;
  exclusion is operator-applied at export Step 1, no automated filter).
- Reviewed by the Upgrade-Path SME (#43/#37) and Export/Privacy SME (#38); both
  verified the claims accurate. No governance-token change, no new hard-stop, no
  code touched. Closes #43, #37, #38.

## 2026-07-17 (v1.39.0 — second-brain capture-batch: save many notes in one call)

- Commit hash: (staging→main merge; assigned at merge)
- New `tools/second-brain.sh capture-batch [--file <path>]` subcommand: save
  many notes in a single invocation by piping a directive-prefixed stream
  instead of one `capture` call per note (agent capture ergonomics). Closes the
  doc/tool gap — `MEMORY.md` already described "orchestrator-mediated batched
  capture," but the tool had no batch mode.
- Format: records separated by a line of `%%%` (trailing whitespace tolerated);
  within a record, leading `@title` / `@tags <a, b>` / `@source` lines set
  metadata and the rest (including a leading blank line) is body. Directives are
  leading-only, so a `@`-looking body line is kept verbatim. Tags emit as
  Obsidian-canonical block-list items with a leading `#` stripped.
- Safety: the AC-2 filter runs **per record**, write-clean / skip-tripped —
  clean records written (paths → stdout), tripped (secret/SOLE-HOLDER) or
  empty-body records skipped (reported to stderr, class + line only, never the
  secret content). Exit `0` all written · `3` ≥1 skipped · `2` no records · `4`
  I/O (a per-record I/O failure trumps a content skip).
- Refactor: the assemble → filter → write core of `capture` is extracted into a
  shared `write_note` helper both subcommands call; single-`capture` behavior is
  byte-identical (its assertions pass unchanged as the refactor net).
- Shell/Test-Harness SME review (matrix-required for `tools/*.sh`) cleared after
  a BLOCKER fix: a record beginning with a blank line dropped the blank and then
  silently mis-parsed a following `@`-line as a directive (content corruption,
  exit 0); the record loop now uses a started-flag so a leading blank correctly
  begins the body. Also from the review: `%%%` fence tolerates trailing
  whitespace, and per-record I/O exits `4`.
- bash-3.2-safe (here-strings not pipes, `case` fence match, empty-array guards);
  verified under stock `/bin/bash` 3.2.57. Tests: new `capture-batch` section in
  `tools/tests/second-brain.test.sh` (150/0; all 13 suites green). Docs:
  `docs/second-brain-model.md` Tool Reference + `minions/capabilities.md`.

## 2026-07-17 (v1.38.0 — second-brain Obsidian-canonical block-list tags + migrate-tags; locale-portability test fix)

- Commit hash: (staging→main merge; assigned at merge)
- `tools/second-brain.sh` `capture` now emits frontmatter tags as the
  Obsidian-canonical YAML block list (a list, no leading `#` — the `#` is for
  inline *body* tags only) instead of the inline flow array `tags: [a, b]`,
  and defensively strips a single leading `#` a caller passes on `--tag`. The
  inline-array form worked but is not Obsidian's documented/canonical form and
  is less reliably recognized across some Obsidian versions/plugins.
- New `migrate-tags` subcommand brings existing vaults up to the canonical
  form: it rewrites only the first frontmatter block of each note (body text —
  even a body line that looks like a tags array — is never touched), strips a
  leading `#`, backs up every changed note under a timestamped
  `.sb-tag-backup-<ts>/` dir (relative paths preserved) before writing, and is
  idempotent (an already-converted note has no inline-array line to match, so
  it is skipped). Gated on `MINION_SECONDBRAIN=on`; vault-absent is a silent
  no-op exit 0, consistent with the other gated subcommands.
- `tools/tests/second-brain.test.sh` gained block-list capture assertions, a
  capture strip-`#` case, and a full `migrate-tags` section (gate-off/
  vault-absent no-ops, conversion, stray-`#` strip, frontmatter-only guarantee,
  backup creation, already-block-list byte-identity, idempotency, empty
  `tags: []`, and a trailing-slash-vault backup-path regression guard);
  `docs/second-brain-model.md` Tool Reference gained the `migrate-tags` row.
  Suite 116/0; all 13 suites green.
- Shell/Test-Harness SME review (matrix-required for `tools/*.sh`) cleared it
  after a MAJOR fix: a trailing-slash `MINION_SECONDBRAIN_VAULT` sent
  `migrate-tags` backups to a bogus absolute path while reporting success —
  root-caused by normalizing trailing slashes off `VAULT` at resolution.
  Driven by downstream issue #40 (Network-Inventory 1.37.0-1.0.0; downstream
  PR #31 migrated 110 vault notes, 3 with a stray `#`).
- Locale-portability fix: `tools/tests/governance-consistency.test.sh` no
  longer false-fails on a pristine clone under macOS's default `en_US.UTF-8`
  locale — the `expand_scan_entry` self-test's `sort` is pinned `LC_ALL=C`
  (UTF-8 collation had reordered it against a hard-coded C-collation
  expectation). Every other `sort` in `tools/` was audited and needs no
  pinning; locale-collation portability was added to the Shell/Test-Harness
  SME charter. Verified under `en_US.UTF-8`, `de_DE.UTF-8`, and `C`. Driven by
  a downstream field report (v1.33.0 → v1.37.0 upgrade).

## 2026-07-12 (v1.37.0 — Instruction-surface size budgets; template manages its own size)

- Commit hash: 4729f1a (staging merge)
- Downstream field driver: a CLAUDE.md grew to 160 KB before anyone noticed
  — the thin-pointer discipline was prose-only, with no mechanism that
  notices bootstrap-surface growth. This release adds one.
- New `tools/tests/instruction-size.test.sh`: a whole-file word-budget
  guard for the instruction/bootstrap surface (`CLAUDE.md`, `AGENTS.md`,
  `MEMORY.md`, role charters, SME files, etc). Budgets apply to the WHOLE
  file — below-delimiter, downstream-owned content counts too, because
  whole-file size is the token cost every session pays at bootstrap.
  No-arg self-test (33 checks) plus a real-tree sweep, `--root` override,
  and a `--report` mode that prints a percent-of-budget pressure table
  without failing. Precedence is override-exact > override-class >
  default-exact > default-class; non-numeric arithmetic inputs fail loud
  (never silent); named-vs-class de-dupe; all mutation-verified.
- New `docs/instruction-size-budgets.md`: the canonical budgets reference
  plus a downstream-owned `## Local Overrides` section below a split-merge
  delimiter, consumed fail-open by the guard — an absent or malformed
  override always falls back to template defaults, and an override can
  raise, set, or deliberately tighten a budget — never remove a surface
  from checking or block the guard. Default budgets: entry pointers 600;
  `INIT.md`/`AI.md` 1800; `MEMORY.md` 9000; `capabilities.md` 1500;
  `review-matrix.md` 1200; `feedback.md` 3000; `smes/README.md` 2000;
  role charters class 2400 (`PM.md` exact 3000); SME files class 1100.
  Budgets are sized from template measurements; current tree max usage is
  77% of budget. Field data from adoption surfaced two surface classes:
  guide-class content (e.g. onboarding walkthroughs) relocates cleanly at
  roughly 75% size reduction with zero information loss, while
  binding-rules class content (guardrails, hard-stops) bottoms out —
  promote or override it, never delete the lesson.
- MEMORY.md: new "Instruction-Surface Size Budgets" subsection documenting
  the promote-don't-delete overflow protocol — when a surface approaches
  or exceeds its budget, relocate the content to its canonical home and
  leave a pointer, rather than deleting it to fit — plus a stub lifecycle
  added to the Feedback Capture Rule (promote → condense to pointer stub →
  prune aged stubs), field-proven downstream.
- Wired `docs/export-manifest.md` and `docs/operator-onboarding-checklist.md`
  for the new doc and guard; `export-seed-check.sh` gained a `WAIVER` entry
  for the new surface.
- SME panel: Shell/Test-Harness (3 findings, all closed, real-bash-3.2
  verified); Governance-Invariant (no blocker, 4 findings applied);
  Upgrade-Path (ship-eligible conditional on its Required Changes entry,
  now in `docs/downstream-upgrade-playbook.md`); Export/Privacy (clean,
  7/7). SM review skipped with rationale (no network/secrets/privilege
  surface; injection inputs locked by the guard's self-test). CM read-only
  verdict: SHIP.
- No governance-token change, no new hard-stop.

## 2026-07-12 (v1.36.1 — pre-export drift-audit fixes)

- Commit hash: 16efcf0 (staging merge)
- Fixes from the pre-export drift audit of the v1.36.0 tree (28-agent
  workflow: 15 launcher-triplet parity checks + 7 doc-claim lenses, every
  finding adversarially verified; 19 of 22 sweep surfaces came back clean;
  full report in the audit run record):
  - `minions/smes/cross-family-launcher.md`: stale bench count corrected —
    "15-file parity: 5 SMEs × 3 families" → "18-file parity: 6 SMEs × 3
    families" (drifted when the Skill-Provenance SME joined the default
    bench in v1.32.0 and was never updated).
  - Class A (mainline-authoritative) file enumeration now includes
    `.github/copilot-instructions.md` in all four places it is defined
    (`AI.md`, `docs/branching-and-release-model.md`, `MEMORY.md` Branch
    Coordination Plane, and the `docs/export-manifest.md` Class-A note —
    the fourth found by the Governance-Invariant SME during review of this
    fix). The Copilot entry point is a sibling of
    `CLAUDE.md`/`AGENTS.md`, which were already enumerated; its
    branch-authoritativeness was previously undefined. PM adopted the
    audit's upholding verifier argument (explicit beats undefined for a
    definitional list); no behavior change for repos that never fork the
    entry points on feature branches.
- No governance-token change, no new hard-stop, docs-only.

## 2026-07-12 (v1.36.0 — Remote-tool --help guards; adoption-record cross-check)

- Commit hash: 37e4654 (staging merge)
- **`--help`/`-h`/`help` guards exit 0 before any side effect** in both
  remote-mutating tools. `tools/issue-board-bootstrap.sh` previously had **no
  arg parsing at all** — this was the issue #32 incident: probing it with
  `--help` during INIT capability enumeration ran a real bootstrap and
  created 13 labels on a downstream repo. It now guards `-h|--help|help`
  before any side effect; unknown args reject with usage + exit 2.
  `tools/issue-sync.sh` gains the same help arm (previously exited 2 on
  `--help`, now exits 0).
- **New shared helper `tools/layer-adopted.sh`**: a three-state adoption-record
  fail-open cross-check (exit 0/on, 1/off, 2/indeterminate) parsing the new
  machine-readable `adopted:` token in `docs/operator-onboarding-checklist.md`.
  Fail-open by construction — only exit 1 (explicit `adopted: off`) gates;
  a missing checklist, missing helper, or missing record all fall through to
  the env gate alone deciding, i.e. pre-change behavior. Both
  `issue-board-bootstrap.sh` and `issue-sync.sh` consult it after the
  `MINION_ISSUES` env gate: gate on + repo records `adopted: off` → silent
  no-op. This closes the incident's second root cause — a machine-global
  `MINION_ISSUES=on` bleeding into a repo that never opted in to the issue
  mirror.
- Docs synced: `MEMORY.md` Optional Layers convention bullet documents the
  adoption-record cross-check and the fail-open guarantee;
  `docs/operator-onboarding-checklist.md` converts the Optional Layers
  section to the machine-readable `adopted:` token with an explanatory intro
  paragraph; `docs/issue-mirror-model.md` notes the cross-check and points at
  `tools/layer-adopted.sh`; `docs/export-manifest.md` gains a row for the new
  tool; `minions/smes/shell-test-harness.md` charter lists updated for the new
  tool and its test suite.
- Tests: new `layer-adopted.test.sh` suite (22 cases, including mutation-verified
  prose-masking cases guarding against the helper matching `adopted:` text
  inside comments/prose rather than the real key line);
  `issue-board-bootstrap.test.sh` grows 20→36 (help guard, unknown-arg
  rejection, adoption cross-check wiring, helper-absent fail-open);
  `issue-sync.test.sh` grows 59→68 (same categories). Both callers' test
  suites include a helper-absent fail-open case verified at the actual
  integration point, closing SME findings F1/F2 (F1 mutant-verified). Full
  12-suite sweep green.
- Reviewed by SM (Frontier — acceptable to ship, no reachable finding;
  injection/spoofing/pathological-input cases empirically probed, 3
  informational safe-direction notes), Governance-Invariant SME (PASS all
  axes, 1 optional doc nit — resolved above), Export/Privacy SME (clear to
  export/public-mirror, 0 uncovered files, 1 optional parenthetical nit —
  resolved above), Upgrade-Path SME (drafted the Required Changes entry
  below), Shell/Test-Harness SME (mutation-tested; found the F1/F2 test gaps
  closed in this release). CM read-only final-gate verdict: **SHIP** —
  spec-exact, tests load-bearing, no new findings.
- Driven by downstream field report on Gitea issue #32 (the remote-mutating
  `--help` incident described above).
- **OPTIONAL for downstream** — see the 1.36.0 entry in
  `docs/downstream-upgrade-playbook.md`. No governance-token change, no new
  hard-stop; the adoption-record cross-check can only add a no-op, never
  enable a gate-off layer or block a call.

## 2026-07-10 (v1.35.0 — Tier declaration at dispatch; CM effort lock retired)

- Commit hash: 13a5886 (staging merge)
- **Orchestrator declares model tier + reasoning effort at every dispatch.**
  Wired at three layers so the rule survives at the surfaces orchestrators
  actually re-read at dispatch time, not just in a standalone doc: `MEMORY.md`
  (Execution Quality) gains a new dispatch-brief bullet — "Dispatch briefs
  declare the capability tier" — naming model tier and effort per
  `docs/model-tiering.md` and the actual activity, not the role name;
  `minions/roles/PM.md` gains a matching PM charter duty in the dispatch-brief
  paragraph cluster; `docs/model-tiering.md`'s "The effort dial" section and
  per-family mechanics are rewritten from "pins enforce" to "orchestrator
  declares, pins are fallback defaults" — covering the three Claude
  dispatch-time levers (per-dispatch model override, per-stage effort option
  on workflow spawns, session-inherited effort as fallback), Codex's static
  `model_reasoning_effort` as that family's fallback default (no per-dispatch
  override — launcher choice is the lever there), and Copilot's advisory-prose
  posture.
- **`cm`'s Claude-launcher effort lock is retired.** `.claude/agents/cm.md`
  no longer pins `effort: xhigh`; `model: opus` stays as a fail-safe default.
  Effort for `cm` (including review/final-gate passes) is now declared at
  dispatch instead of pinned. `.claude/agents/README.md` and
  `.codex/agents/README.md` doc-sync to match — the Claude table/prose drop
  the `effort: xhigh` claim, and the Codex README notes its static
  `model_reasoning_effort` values are a fallback default, not an enforced
  ceiling. `.codex/agents/cm.toml`'s `model_reasoning_effort = "high"` is
  unchanged (that family has no per-dispatch override).
- `INIT.md`'s model-tiering bootstrap line now points at the normative rule:
  dispatch briefs declare tier + effort per `MEMORY.md` (Execution Quality),
  not just the advisory doc.
- A new governance guard (`tools/tests/governance-consistency.test.sh`) checks
  that the tier-declaration law's presence survives in `MEMORY.md` and
  `minions/roles/PM.md`; it checks presence only, never per-dispatch tier
  compliance (that boundary is unchanged from `docs/model-tiering.md`'s
  existing "advisory, safe to ignore" stance).
- Driven by downstream field report on Gitea issue #33 (a downstream project): a
  frontier orchestrator dispatched a whole milestone at inherited defaults
  because tiering was wired at one layer, and the same downstream reset CM's
  effort lock to let the orchestrator/PM right-size effort per dispatch.
  `feedback.md` carries the dated learning entry
  (`promoted -> v1.35.0`).
- OPTIONAL for downstream — see the 1.35.0 entry in
  `docs/downstream-upgrade-playbook.md`. No governance-token change, no new
  hard-stop; guard is presence-only (advisory compliance, per
  `docs/model-tiering.md`).

## 2026-07-09 (v1.34.0 — Default SME bench: 6 infrastructure SMEs ship as template defaults)

- Commit hash: pending (staging→main PR merge)
- **Default SME bench ships.** The 6 infrastructure SMEs — Governance-Invariant,
  Cross-Family Launcher, Export/Privacy, Upgrade-Path, Shell/Test-Harness, and
  Skill-Provenance — are reclassified from downstream-owned, no-export
  content to a template DEFAULT bench: `minions/smes/*.md` charters and the
  `sme-*` launchers (Claude, Codex, Copilot) flip `docs/export-manifest.md`
  rows from `no`/downstream-owned to `yes`/template-replace. This reverses
  the 1.28.0 stance that the bench was maintainer-local, each downstream
  starting from an empty registry.
- **Registry/matrix rows move above the delimiter.** The default bench's rows
  in `minions/smes/README.md` and `minions/review-matrix.md` moved from the
  Local (downstream-owned, below-delimiter) sections to new template-owned
  "Default Bench" / "Default Matrix" sections above the split-merge
  delimiter — they now ship and upgrade with the template. The Local
  Registry / Local Matrix sections stay header-only starters; a downstream's
  own SMEs live there, below the delimiter, untouched by this change.
- `docs/runbooks/public-export.md` Step 2.5 updated so the public-mirror seed
  reset only blanks the below-delimiter Local sections — the default bench
  ships intact on every public export.
- **Reconciliation fixes** (same increment, commit `0d4f88a`): the
  `review-matrix.md` manifest row itself was corrected `downstream-owned` →
  `template-replace` so its new above-delimiter Default Matrix actually
  propagates on upgrade; stale manifest Notes on both files updated to the
  two-tier ship-above/reset-below description; a personal-context case-law
  token in the export-privacy charter was neutralized to generic phrasing;
  and the `docs/downstream-upgrade-playbook.md` 1.34.0 entry (below) was
  added in the same commit.
- **Downstream impact — OPTIONAL with one REQUIRED pre-upgrade check.** An
  empty-bench downstream simply receives the 6 charters + 18 launchers + the
  default rows on upgrade; its own SMEs are unaffected. REQUIRED: if a
  downstream authored its own SME under a filename matching one of the 6
  defaults (or a same-named `sme-*` launcher), rename it before upgrading —
  the `template-replace` glob will otherwise overwrite it. See the
  `docs/downstream-upgrade-playbook.md` "1.34.0" entry for the full
  name-collision check.
- **Public-export runbook — secret-fixture exclusion** (commit `fa5c2ea`):
  `docs/runbooks/public-export.md` now documents that GitHub push protection
  rejects the second-brain secret-filter tests (deliberately provider-shaped
  example fixtures) even though the repo's gitleaks gate allowlists them, so
  every public export must exclude `tools/tests/second-brain.test.sh` and
  `tools/tests/fixtures/second-brain/` and note the omission in the README
  divergence list. Field-derived from the v1.33.0 public publish.
- Reviewed by Export/Privacy SME (SAFE), Upgrade-Path SME and
  Governance-Invariant SME (findings fixed in the reconciliation commit
  above). No governance-token change, no new hard-stop, docs/manifest-only.

## 2026-07-09 (v1.33.0 — Effort calibration + external-capability scouting)

- Commit hash: pending (staging→main PR merge)
- **Capability-map records (no adoption).** Scouted two external repos and
  recorded them as capability candidates, not code: **repowise**
  (codebase-intelligence over MCP — dependency graph, git analytics, code-health
  scores, dead-code, refactor plans) gets an `absent`-status connector row in
  `minions/capabilities.md`; its **AGPL-3.0** license makes it connector-only —
  never vendored into the public-mirror tree. **effortmining** contributed an
  idea only (see below), no repo row.
- **Effort-calibration — prototype, then wired, then validated.**
  `docs/effort-calibration.md` (new) extends `docs/model-tiering.md` with a
  second, orthogonal dial — reasoning effort (the Agent tool's `effort`
  parameter) alongside model band — via a task-class → effort table
  (T1–T4/R/C, idea attributed to `nagisanzenin/effortmining`, MIT; only the
  idea is imported, no code/plugin/hooks). It shipped as an unvalidated,
  governance-exempt prototype.
- Wired into launcher frontmatter as `effort:` (Claude) / `model_reasoning_effort`
  (Codex) pins, mirroring the existing `model:` tier pins: judgment roles `am`,
  `sm`, `om`, `rm` at `high`; `cm` stays `xhigh` (final-verifier escalation);
  `pm` and `dm` at `medium`; the six SME launchers split `high`
  (export-privacy, governance-invariant, skill-provenance, upgrade-path) /
  `medium` (cross-family-launcher, shell-test-harness). A Cross-Family
  Launcher SME finding caught the Claude `pm` pin drifting from Codex's
  deliberate `medium` and a Claude-only mischaracterization in
  `model-tiering.md` (effort is functional in both Claude and Codex — only
  Copilot is prose-only); both fixed same-day, and the two families now agree
  role-for-role.
- **Blind-grader validation, 3/3 probes.** A controlled harness (fixed model,
  varied effort arm, independent blind graders plus an objective hidden test
  battery as sole arbiter) ran a SemVer-precedence comparator, an RFC-4180 CSV
  parser, and an arithmetic evaluator with injection rejection. `low` effort
  passed every objective battery across all three probes — clearing the
  "passes repeatedly" bar. Meta-finding promoted to a standing rule: a blind
  LLM grader hallucinated a fatal bug and claimed to have executed it, so an
  **objective execution backstop is now REQUIRED** for any effort-calibration
  run — grader opinion alone is not evidence.
- On the strength of the 3/3 result, the `/ship` `coder` and `tester` pipeline
  stages (Claude and Codex) are lowered to `effort: low` — they run under a
  clear AM spec with a downstream test + review backstop, so the ambiguous
  T3 class default (`medium`) stays put but these two bounded stages don't
  need it.
- This is docs- and launcher-frontmatter-only: no product code, no governance-
  token change, no new hard-stop. OPTIONAL for downstream — see the 1.33.0
  entry in `docs/downstream-upgrade-playbook.md`.

## 2026-07-09 (v1.32.0 — Skill adoption layer: Scout + Airlock + Skill-Provenance SME)

- Commit hash: pending (staging→main PR merge)
- New OPTIONAL, default-off skill-adoption layer (`MINION_SKILLS`), letting an
  untrusted, mutable, instruction-bearing external "skill" (discovered via
  `skills.sh`) cross into the template through a human vetting panel and a
  gated airlock, ending in a framework-wrapped form whose only authoritative
  text is framework-authored. Design of record:
  `docs/superpowers/specs/2026-07-09-skill-adoption-layer-design.md`. Built
  via the `/ship` PM pipeline (plan → gate → implement → test → 7-reviewer
  panel → fix → SHIP); paused once at the plan gate for an Operator decision
  (SME bench approval, combined Phase 1+2, full merge-blocking wiring,
  four-entry-point parity).
- **Skill-Provenance SME** (new) — charter `minions/smes/skill-provenance.md`,
  three `sme-`-prefixed launchers (behaviorally identical across families),
  registry row, and two `minions/review-matrix.md` rows (adopt-candidate;
  wrapper-charter authoring). Recommend-only: synthesizes the vetting panel's
  findings for PM, who convenes and decides; the wrapped-form write is always
  a role's, never the SME's.
- **Governance wiring** — `MINION_SKILLS` gate-conditioned pointer added to
  all four entry points (`CLAUDE.md`, `AGENTS.md`,
  `.github/copilot-instructions.md`, `MEMORY.md`'s new Skill Adoption
  subsection); a hard-stop-#2 **instance** annotation for skill vendoring (no
  new hard-stop, no count change) in `CLAUDE.md`, `AI.md`, and all three agent
  READMEs.
- **Unconditional protections** (stand regardless of the gate): a
  `skills/vendored/` `do-not-export` manifest row + `.gitkeep` placeholder,
  and the same path added to the public-export forbidden-path pre-push gate
  (`docs/runbooks/public-export.md`).
- **`tools/skill-scout.sh`** (new) — findings-only `survey`, with a
  WebFetch/web-UI fallback when `npx` is absent; fetched content is treated
  as inert data, never evaluated.
- **`tools/skill-airlock.sh`** (new) — advisory `check` (exit 0 is never a
  safety gate) plus a pure/offline `verify-quarantine`.
- **New merge-blocking `skills_wired` guard** in
  `tools/tests/governance-consistency.test.sh`, self-tested, asserting the
  four-entry-point wiring and the three unconditional protections.
- **Reader path** — `docs/skill-adoption-model.md` (schema, run posture,
  consumption contract, Enabling It / rollback); an `absent`-status example
  adopted-skill row in `minions/capabilities.md`; an onboarding-checklist
  entry; a merge-blocking `docs/downstream-upgrade-playbook.md` entry.
- Review-panel fix pass: the SM-flagged MEDIUM finding (`verify-quarantine`
  did not match a symlinked `SKILL.md`, a trust-boundary bypass) was closed
  by matching both file and symlink targets, plus three non-blocking quality
  findings; suite re-verified green after the fix.
- Tests: 11/11 guard/test suites green; `skill-airlock.test.sh` at 32/0 (all
  7 static-scan patterns plus the symlink-quarantine case asserted).
- OPTIONAL for downstream (adopt-if-used), but the wiring floor is
  merge-blocking: the `skills_wired` guard fails a downstream that syncs this
  version and skips the four-entry-point pointer or the unconditional
  protections. See the 1.32.0 entry in `docs/downstream-upgrade-playbook.md`.

## 2026-07-08 (v1.31.0 — Local second-brain: Phase 1 corpus layer)

- Commit hash: pending (staging→main PR merge)
- New OPTIONAL, default-off local corpus layer (`MINION_SECONDBRAIN`), complementing
  (not replacing) the cloud Mnemoverse recall layer — a fast, local, unrestricted-corpus
  "second brain" over a plain-Markdown Obsidian vault. Design of record:
  `docs/superpowers/specs/2026-07-08-local-second-brain-design.md`. Built via the `/ship`
  PM pipeline (plan → gate → implement → test → 5-lens + cross-vendor review → hardening
  → SHIP).
- **`tools/second-brain.sh`** (new) — `capture` / `search` / `filter` / `scan` / `path`.
  Vault resolves from `MINION_SECONDBRAIN_VAULT` (default `~/second-brain`); Obsidian is
  never probed (operates on plain files, so deleting Obsidian is a graceful no-op). AC-2
  reject-and-report exclusion filter (secrets + `SOLE-HOLDER:`; reports class + line
  **number**, never the secret text) with an optional `$VAULT/.secondbrain-exclude`; AC-4
  `gitleaks --no-git` scan; `path --check` AC-1 preflight including a git-remote
  containment warning. Silent no-op when the gate is off or the vault is absent.
- **Adoption wiring (Mnemoverse-mirror, not per-launcher):** a gate-conditioned run-start
  PULL line on `CLAUDE.md` / `AGENTS.md` / `.github/copilot-instructions.md` / `AI.md`; a
  `MEMORY.md` Optional-Layers subsection; a `minions/capabilities.md` row (+ a
  `docs/operator-onboarding-checklist.md` adoption row); `/recall` + `/capture` prompt
  modes; and a self-tested `secondbrain_wired` governance guard (block-flatten
  co-location) so the wiring cannot silently rot.
- **`docs/second-brain-model.md`** + **`docs/runbooks/second-brain-setup.md`** (new);
  **`.gitleaks.toml`** (new) allowlisting the test fixtures so they don't trip the
  public-export gate; export-manifest rows for all new tracked files.
- Reframe baked into the design: "local" is not "unrestricted-safe" — secrets and
  `SOLE-HOLDER:` anchors never enter even locally (a Markdown vault is still copyable /
  syncable). Files always win; vault content *informs* and becomes canonical only via
  promotion into git.
- Tests: `tools/tests/second-brain.test.sh` — **90 passed / 0 failed under BOTH stock
  `/bin/bash` 3.2.57 and Homebrew bash** (a portability BLOCKER in the first cut, which
  the cross-vendor SHIP missed, was caught by direct execution and fixed). Full suite
  green; `gitleaks` clean repo-wide.
- OPTIONAL for downstream: additive, default-off, no baseline or governance-token change.
  Phase 2 (DM curation pass, `/curate`, DM charter edit) and Phase 3 (graph/ingest, an
  optional `claude-obsidian` power tier behind an RM+SM security read) remain per the
  design's rollout.

## 2026-07-07 (v1.30.1 — Bug-scrub follow-ups: issue-sync/upgrade-classify fixes, cross-family coder/tester launchers, guard hardening)

- Commit hash: pending (staging→main PR merge)
- Follow-ups from a bug scrub of the minion/SME stack (plan at
  `minions/plans/2026-07-07-bug-scrub-followups.md`): two confirmed defects, one
  launcher-parity completion, and two SME-flagged guard/fixture hardenings.
  Additive/optional; no baseline or governance-token change.
- **`tools/issue-sync.sh`** — `github_edit` now re-applies labels via
  `--add-label` (it set only `--title`/`--body`/`--assignee`, dropping labels on
  re-sync while `github_create` passes `--label` and the Gitea edit path passes
  `--add-labels`). Backend parity; covered by a regression test (issue-sync
  50→59).
- **`tools/upgrade-classify.sh`** — when a live-comparison error (exit 3) and an
  unmanifested exported change (exit 4) both occur in one run, both warnings now
  print and the exit code is 4; the silently-dropped exported file is no longer
  masked by the inconclusive comparison. Docstring updated; C4 both-conditions
  test added (upgrade-classify 34→37).
- **`.codex/agents/{coder,tester}.toml`, `.github/agents/{coder,tester}.agent.md`**
  (new) — the `coder`/`tester` pipeline stage launchers, Claude-only since
  v1.30.0, now exist in all three families for discoverability and parity. The
  Mid tier is advisory outside Claude (no per-launcher model selector, no
  `/ship`) — spawned manually. Four `docs/export-manifest.md` rows added
  (manifest-completeness stays at 0 uncovered).
- **Docs** — reconciled the now-stale "Claude-only, no cross-family
  coder/tester" claims across `.claude/agents/README.md`,
  `docs/minion-prompt-modes.md`, and the v1.30.0 upgrade-playbook entry; added
  Pipeline Stage Launcher discovery sections to the `.codex`/`.github` READMEs.
  Functional tier-pinning and `/ship` stay Claude-only by construction.
- **`tools/tests/governance-consistency.test.sh`** — a cross-family parity check
  for the coder/tester launchers (present in all three families or none; the
  `launcher_ok` bootstrap check now covers the Codex/Copilot stage launchers)
  plus a self-tested `has_stale_stage_claim` detector guarding the authoritative
  launcher docs (bounded on markdown blocks AND sentences so unrelated bullets
  cannot bridge into a false match; covers contraction/existence-verb phrasings).
- **`tools/tests/fixtures/make-fake-provider.sh`** — the `gh` test fake now
  rejects the wrong label flag on the wrong subcommand (create `--label`, edit
  `--add-label`), matching the `tea` fake's flag-faithfulness so a stale-flag
  regression fails at the fake rather than passing a dumb argv recorder;
  fixture-rigor tests added.
- Reviews: Shell/Test-Harness SME (fixes + guards), Cross-Family Launcher SME
  (launchers; HIGH stale-claim finding reconciled), Export/Privacy SME (manifest
  classification) — all findings addressed. Full 8-suite `tools/tests` green.

## 2026-07-07 (v1.30.0 — Model-tiering Phase 2: coder/tester stage launchers)

- Commit hash: pending (staging→main PR merge)
- Model-tiering Phase 2 — documented in `docs/minion-prompt-modes.md` since
  v1.24.0 but never built — is now shipped (Operator decision 2026-07-07; plan
  at `minions/plans/2026-07-07-model-tiering-phase2.md`). The single `cm`
  launcher is hard-pinned to Frontier (opus/xhigh) and runs BOTH implementation
  and verification there because one launcher cannot distinguish implementer
  from verifier. Phase 2 splits the two mechanical `/ship` stages onto Mid
  tier **without changing the architecture**; AM planning (stage 1) and the
  review gate (stage 7) stay Frontier.
- **`.claude/agents/coder.md`** (new) — Mid-tier (`model: sonnet`)
  implement-only launcher for `/ship` stage 3. Points at `minions/roles/CM.md`,
  carries the full bootstrap read chain; the implement-only posture travels in
  the `/ship` spawn prompt.
- **`.claude/agents/tester.md`** (new) — Mid-tier (`model: sonnet`)
  write-and-run-tests-only launcher for `/ship` stage 4. Same shape as `coder`;
  the load-bearing test/implement separation lives in its lane paragraph — it
  reports test failures and STOPS, never patches the code under test.
- **`.claude/commands/ship.md`** — stage 3 (implement) now prefers `coder` and
  stage 4 (test) prefers `tester`, each falling back to `cm` when the launcher
  is absent. Additive and zero-behavior-change when unadopted. Stage 7 review
  gate stays `cm` / read-only / Frontier, unchanged.
- **`docs/export-manifest.md`** — two new rows for the launchers
  (`yes` / `template-replace` / `feature` / PM · CM), keeping
  manifest-completeness at 0 uncovered.
- **`tools/tests/governance-consistency.test.sh`** — a SEPARATE `launcher_ok`
  mini-loop mechanically checks the coder/tester bootstrap-read wiring,
  deliberately kept OUT of the 7-role loop and the role-set drift guard:
  coder/tester are a THIRD launcher class (pipeline stage launchers, not roles)
  and must not enter the one-to-one-with-Codex role set.
- **Docs** — `docs/minion-prompt-modes.md` Phase 2 section retitled
  Planned→Shipped and rewritten to built state; `.claude/agents/README.md`
  gains a "Pipeline Stage Launchers (Claude-only)" subsection (NOT added to the
  7-role Agents table, preserving the Codex one-to-one invariant);
  `docs/downstream-upgrade-playbook.md` updates the 1.10.0 OPTIONAL/DEFERRED
  block to shipped and adds a 1.30.0 Version-Specific Required Changes entry.
- Claude-only is **forced, not a parity gap**: only Claude Code's `model:`
  frontmatter pins tier functionally, and no Codex/Copilot `/ship` exists to
  slot the launchers into, so the Instruction-File Audit Rule's cross-family
  launcher-parity requirement does not reach this class.
- OPTIONAL for downstream (Claude-only, adopt-if-using-`/ship`, fallback-guarded
  to `cm`); no baseline or governance-token change; full `tools/tests` suite
  green.

## 2026-07-07 (v1.29.1 — Memory recall: run-start READ wired onto shared onboarding)

- Commit hash: pending (staging→main PR merge)
- The optional memory-recall layer's **read/onboard path** was documented
  only in `minions/roles/PM.md` and `docs/memory-recall-model.md` — absent
  from every shared onboarding surface. An orchestrator following the
  read-order at run start therefore never onboarded recall unless it was
  PM. This wires the run-start read onto the surface every minion and
  orchestrator already reads.
- **`MEMORY.md`** (Memory Recall section) — new orchestrator-only read-path
  bullet: at run start the orchestrator (top of the spawn chain) queries the
  project domain and folds hits into dispatch briefs; spawned minions never
  query memory and receive recall through their brief. Recall is input, not
  authority; recalled runtime facts are presumptive (brief still instructs
  live-state verification). Points to `docs/memory-recall-model.md` (Read Path).
- **`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`** — thin
  gated operating-rules pointer (parity, house voice): when
  `MINION_MEMORY=on`, the orchestrator queries recall at run start and folds
  hits into briefs; unset/off or tools/API absent is a silent no-op.
- Orchestrator-only read invariant preserved (spawned minions stay
  MCP-free); write path and never-mirrored classes untouched. Deliberately
  did **not** edit the 21 launcher/role charters — `MEMORY.md` reaches every
  minion at a fraction of the surface with no launcher-parity cost.
- Reviews: Governance-Invariant SME **Adopt** (all five invariants hold),
  Cross-Family Launcher SME **Adopt** (three entry points semantically
  identical), DM **Adopt** (no doc drift).
- Docs-only; OPTIONAL for downstream (no baseline or governance-token
  change); full `tools/tests` suite green (8 suites).

## 2026-07-05 (v1.29.0 — SME design support: guide + validator + review hook)

- Commit hash: pending (staging→main PR merge)
- An Operator proposal to add an "SME-creation SME" was pressure-tested by
  a four-seat consult (AM + RM + Codex + Copilot) before any build. All
  four independently recommended against a standing meta-SME.
- **`docs/designing-an-sme.md`** — the design craft: the consultable-
  expertise-vs-PM-process filter, the SME-vs-RM-vs-role test, evidence
  discipline, disjoint-domain drawing, and tier-follows-judgment-vs-
  mechanical.
- **`tools/sme-charter-check.sh`** — a mechanical validator only:
  required sections, non-empty negative discovery, a Local Registry row,
  and launcher parity in all three families. Not a domain-merit judge;
  runs against the live repo as a drift guard.
- **Governance-Invariant SME** gains one `Consult When` line — review a
  new charter's domain boundaries as advisory-on-text (PM + Operator own
  existence; not a second gate). README pointer + manifest rows.
- The `designing-an-sme` skill is deferred until cross-project reuse is
  real.
- Full `tools/tests/` suite green (8 suites).

## 2026-07-04 (v1.28.2 — Optional-layer adoption record)

- Commit hash: pending (staging→main PR merge)
- New "## 4. Optional Layers (Operator Decision)" section in
  `docs/operator-onboarding-checklist.md` (Escalation → 5, Guardrail → 6,
  Sign-Off → 7): per-repo activation state for the `MINION_*` overlays —
  Memory recall (`MINION_MEMORY`) on/off + date + where the gate is
  persisted (with the `.zshenv`-not-`.zshrc` verification note), Issue
  mirror (`MINION_ISSUES`), Coordinator mode — plus a line confirming
  adopted layers' backing capabilities are listed `active` in
  `minions/capabilities.md`. Extends the v1.22.1 launcher-family
  activation-state precedent to the overlay layers it skipped.
- New bullet in `MEMORY.md`'s Optional Layers convention making adoption
  durable state and stating the contract explicitly: "mandatory" for an
  optional layer means standing practice with graceful degradation,
  never a hard gate that blocks a workflow.
- Full `tools/tests/` suite green.

## 2026-07-04 (v1.28.1 — Guard hardening: SME-surface norm scan + public-export seed guard)

- Commit hash: pending (staging→main PR merge)
- Retired-norm scan now covers the SME surfaces (finding B): the
  auto-spawn-norm detector in `tools/tests/governance-consistency.test.sh`
  previously scanned a fixed allowlist that excluded `minions/smes/*.md`
  charters and `sme-*` launchers, so a future edit reintroducing the
  retired phrasing there would have passed CI. A self-tested
  `expand_scan_entry` glob expander (nullglob; `IFS=` guards spaced paths)
  plus new SME-surface globs in `governance-scan.allow` close the gap,
  with a "guard the guard" assertion that every existing SME surface is
  scanned. Describe-the-norm files (`minion-version.md`, CHANGELOG-class)
  stay excluded by design.
- Mechanical public-export seed-state guard (R2 + F3 + R1): the Step 2
  seed-reset (blanking Local Registry / Local Matrix rows below the
  split-merge delimiter) was manual prose with no gate, so a skipped
  reset could silently ship private bench/routing rows to the
  irreversible public mirror. New `tools/export-seed-check.sh` is
  public-export Step 3 gate 4 — a positive header-only assertion (prose,
  bullets, post-separator data rows, and separator-less malformed rows
  all fail) plus a classification-completeness leg that fails any
  delimited exportable file not enrolled as a `SEED_FILES` reset target
  or a `WAIVER` entry (`--completeness` runs it as a live-repo CI
  invariant). WAIVER files (`MEMORY.md` + the role charters) are
  header-only-checked too, so future below-delimiter content there is
  caught, not published.
- Full `tools/tests/` suite green (7 suites).

## 2026-07-04 (v1.28.0 — Canonical SME bench + PM bench-review loop)

- Commit hash: pending (staging→main PR merge)
- Five SME charters in `minions/smes/` — Governance-Invariant,
  Cross-Family Launcher, Export/Privacy, Upgrade-Path, Shell/Test-Harness —
  derived from 22 releases of failure-class history, the first live
  execution of the v1.27.1 Adding-an-SME checklist.
- Launchers for all five SMEs in all three families (`sme-*` prefix),
  tier-pinned per the model-tiering map.
- Canonical-as-its-own-downstream filtering: local registry and local
  matrix now live BELOW new split-merge delimiters in
  `minions/smes/README.md` and `minions/review-matrix.md`; SME
  launchers carry downstream-owned manifest globs; the public-export
  runbook resets below-delimiter content to seed state (the
  `feedback.md` treatment, generalized). Canonical bench content never
  exports.
- PM bench-review loop (Operator-driven addition): PM reviews expertise
  needs at milestone/run start and on flagged lesson gaps, and presents
  bench proposal briefs to the Operator (gap evidence, question
  answered, discovery sketch, matrix rows, tier, cost of absence);
  Operator approval gates bench changes — a proposal gate, not a
  hard-stop. Wired into the PM charter and the smes README (Growing the
  bench + Adding-an-SME step 0).
- Full `tools/tests/` suite green: governance-consistency,
  issue-board-bootstrap (20), issue-sync (50), manifest-completeness
  (10), upgrade-classify (34), xtool-call (65).

## 2026-07-04 (v1.27.1 — Expertise-layer wiring fix + PM-routed workflows)

- Commit hash: pending (staging→main PR merge)
- **Provenance:** two Operator field reports, same-day fixes.
- Spawned minions never read the v1.27.0 expertise surfaces (launcher
  read lists stopped at `capabilities.md`) — all 21 role launchers and
  the six non-PM charters now instruct the `minions/smes/README.md` +
  `minions/review-matrix.md` bootstrap read; new self-tested
  `launcher_ok` governance guard makes the three-layer wiring rule
  (entry-points, launchers, charters) mechanical.
- New "Adding an SME" deployment checklist in `minions/smes/README.md`:
  charter + registry row + launchers in EVERY AI option tree in use +
  optional matrix rows; removal = retire, never delete.
- New Workflow Ownership (PM-routed) law in `MEMORY.md` Shared Rules:
  every multi-step workflow runs through the PM seat (assume it or
  dispatch it); orchestrator-direct workflows that bypass PM's gate and
  documentation duties are a review finding. Posture lines updated in
  `CLAUDE.md`/`AGENTS.md`/`copilot-instructions`/`AI.md` + PM charter;
  guarded by a `MEMORY.md` token check.
- Full `tools/tests/` suite green, including the new `launcher_ok` and
  Workflow Ownership self-tests inside
  `governance-consistency.test.sh`.

## 2026-07-03 (v1.27.0 — Expertise layer: SMEs, review matrix, escalation contracts)

- Commit hash: pending (staging→main PR merge)
- **Provenance:** field packets #5 + follow-up, Copilot-authored cold
  review — the first from a different vendor's seat — vendored with
  evidence triage in `AI/feedback/`, including the recorded
  hierarchy-misread correction.
- `minions/smes/` — new SME surface starters (protocol `README.md` +
  `sme-template.md` charter template). SMEs are an advisory **class, not
  roles**: recommend-only, no gates, no shared-surface writes,
  findings-only handoff packets (no DECISION / NEXT OWNER); never listed
  in the `MEMORY.md` roster. SME = standing domain judgment; RM =
  external investigation; SME findings needing verification route to RM
  via the paired research domain.
- Discovery protocol: required Consult When / Do Not Consult For charter
  sections (negative discovery prevents expertise creep), registry
  summary columns, and a precedence rule — review-matrix rows always win
  over discovery metadata; disagreement between the two is registry-
  hygiene drift and a review finding.
- `minions/review-matrix.md` — new downstream-owned review-routing
  starter (change types → required reviewers). Absence means
  charter-default routing applies; rows only ever ADD reviewers.
  Skipping a matrix-required reviewer is a review finding (see
  `MEMORY.md`, Execution Quality).
- `## Escalation Contract` added to all seven role charters
  (generalizing SM's pre-existing shape): role-specific Triggers, a
  five-part Provide payload (evidence, design pressure, risks, options,
  recommendation), and Route (PM default / AM for architectural
  concerns / Operator only via existing hard-stops). New self-tested
  `esc_ok` governance guard in
  `tools/tests/governance-consistency.test.sh` asserts the section is
  present and complete in all seven charters.
- `docs/runbooks/README.md` — new structure contract (Purpose,
  Prerequisites, Procedure, Validation, Rollback; an explicit "no
  rollback — irreversible" note satisfies the field): no deployment
  procedure may ship without a rollback section, no implementation
  procedure without a validation section; DM enforces this at doc-sync.
  Three existing runbooks (add-submodule, branch-setup,
  issue-board-setup) were brought into compliance; two already complied.
- Coordinator mode: the coordinator repo's `minions/smes/` acts as the
  shared bench, lane-safe because SMEs are advisory-only; the registry
  and root review matrix are coordinator-seat surfaces; projects may add
  an optional local `projects/<key>/smes/` with local-outranks-shared
  precedence; an optional advisory Maturity column is available on the
  registry.
- Wiring: bootstrap read order updated across all three launcher entry
  points plus `AI.md`; `INIT.md` gains an onboarding step 7; `docs/
  minion-prompt-modes.md` gains an SME Consult Mode section; new
  `docs/export-manifest.md` rows for the added surfaces.
- Full `tools/tests/` suite green, including the new `esc_ok`
  self-tests inside `governance-consistency.test.sh`.

## 2026-07-03 (v1.26.0 — /handoff: flush-then-snapshot session handoffs, ephemeral)

- Commit hash: pending (staging→main PR merge)
- Design driven by the Operator's downstream session need for a durable,
  self-contained snapshot so a fresh session (or the post-compaction
  context) resumes cleanly; the single-writer law already mandated
  durability "before session end or Operator handoff" but attached no
  procedure, and the Session Reset template existed only as a
  conversational reframe — `/handoff` composes existing law (the
  durability window, `SOLE-HOLDER:` persistence, verdict distribution,
  live-state verification) into one procedure rather than inventing new
  rules. Design at
  `docs/superpowers/specs/2026-07-03-handoff-command-design.md`.
- `.claude/commands/handoff.md`: new slash command implementing a
  flush-then-snapshot protocol. Phase 1 (flush) discharges every
  outstanding durability obligation before anything is written to the
  snapshot: persist `SOLE-HOLDER:` facts to their canonical home
  immediately, commit each in-flight deliverable per the durability
  window, batch pending `DURABLE LESSONS:` to their canonical homes
  (role charters, `feedback.md`, `minions/capabilities.md`), and note
  (never await) running background work. Phase 2 (snapshot) writes
  `minions/handoffs/<YYYY-MM-DD-HHMM>-<topic>.md` from a template
  covering Session Reset fields, repo state, in-flight work, environment
  gate readings (marked presumptive), pointers, and memory-recall hints.
- Ephemeral, delete-on-pickup lifecycle: a handoff snapshot is a
  **temporary courier, not truth** — it must survive session death (so it
  is committed on the active branch, Class B), but the receiving session
  deletes it after pickup and commits the deletion as the consumption
  receipt. The flush is what makes deletion safe: after it, the snapshot
  duplicates no canonical content, only a pointer map plus resume
  narrative. On any conflict between a snapshot and repo truth, repo
  truth governs (files win); contradictions worth keeping are extracted
  to `feedback.md`, never written back into a handoff.
- Supersede rule: a new `/handoff` for the same seat/topic supersedes any
  prior unconsumed snapshot for that seat/topic — the old snapshot is
  deleted in the same commit that adds the new one, so at most one live
  snapshot exists per seat/topic.
- Staleness sweep: an unconsumed snapshot older than the work it
  describes is dead weight; DM deletes it at the next gate's doc-sync
  pass.
- `minions/handoffs/README.md`: new surface protocol doc — lifecycle
  (write / ride the branch / pickup / verify / delete + receipt),
  naming convention, ephemeral-courier framing, staleness sweep, and the
  "absence is normal" note (most sessions end at natural completion and
  write no handoff).
- Cross-tool parity: `docs/minion-prompt-modes.md` gains a "Handoff
  Mode" entry (command-table row + section) so Codex/Copilot
  orchestrators run the identical flush-then-snapshot protocol by prompt
  — the established `/ship` cross-tool pattern.
- `MEMORY.md`: short "Session handoffs (ephemeral)" note in the
  Communication Model, beside the optional-layer subsections but
  explicitly NOT an optional layer — it is always available, gated by
  nothing — plus a cross-reference from the Session Reset template.
- Meta: `docs/export-manifest.md` rows for `.claude/commands/handoff.md`
  (template-replace/feature) and `minions/handoffs/README.md`
  (template-replace/feature), plus the `minions/handoffs/*.md` glob row
  (downstream-owned/n/a, never exported, deleted on pickup) so the
  manifest-completeness guard classifies the whole surface; version
  bumped to `1.26.0-1.0.0`.
- Guardrails: `/handoff` never merges, pushes, or promotes anything — it
  snapshots around whatever gate state exists; snapshots never contain
  secrets, credentials-adjacent values, or personal data (same exclusion
  classes as the memory layer); `SOLE-HOLDER:` facts are persisted during
  flush and only referenced by location in the snapshot. Full 6-file
  `tools/tests/` suite green, including
  `manifest-completeness.test.sh` now reporting 0 uncovered files.

## 2026-07-02 (v1.25.0 — Upgrade ergonomics: guard, cross-check, backfill, split-merge)

- Commit hash: pending (staging→main PR merge)
- **Provenance:** downstream field packet on the 1.21.2 → 1.24.0 upgrade,
  transcribed verbatim at
  `AI/feedback/2026-07-02-upgrade-ergonomics-field-feedback.md` and
  evidence-verified in `AI/feedback/2026-07-02-upgrade-ergonomics-triage.md`.
  The six-release upgrade landed clean but took substantially more hand-work
  than the playbook + tooling imply: `upgrade-classify.sh` silently missed 5
  genuinely changed files (forcing a full `diff -rq` fallback), the
  living-file hand merge is where the real labor sat (the 1.21.2 first pass
  clobbered ~4,900 charter lines and needed recovery; a single 1.23.0 charter
  bullet had to be hand-grafted into 6 charters), and the playbook's
  Version-Specific Required Changes section had been empty since 1.11.1 —
  owned as maintainer drift; reverse-engineering merge-blocking items per
  release from the CHANGELOG was the single biggest time sink. All four
  friction points CONFIRMED at triage and closed in this release. The
  packet's what-worked-well is kept on record: the `diff <tag> <tag>` +
  vendored-snapshot model is sound, the CHANGELOG provenance blocks are
  genuinely excellent, and the governance role-roster drift guard passed
  cleanly — the tooling and the required-changes section just had not kept
  pace with the release cadence.
- **Friction 1 — required-changes drought:** backfilled one
  Version-Specific Required Changes entry per release, 1.12.0 → 1.24.0
  (negatives included — "No required changes — adopt normally" is itself
  the time-saver), in `docs/downstream-upgrade-playbook.md`. Forward rule:
  DM writes the release's entry in the **same commit** as the CHANGELOG
  assembly at the staging gate, every release, checked at the PM gate
  (DM/PM charters + `docs/branching-and-release-model.md`). The 1.25.0
  entry itself is written on this feature branch, dogfooding the rule.
- **Friction 2 — classify under-reporting (root cause deeper than
  reported):** the export/snapshot pipeline is manifest-row-driven, so
  unmanifested files were invisible to snapshots *and* classify. Closed
  from both ends: new `tools/tests/manifest-completeness.test.sh` (the
  suite's sixth file) FAILs unless every exportable tracked file is
  classified by a manifest row (glob rows count); and
  `tools/upgrade-classify.sh` gains a `--repo <git-repo> --from <rev>
  --to <rev>` git-diff completeness cross-check — any file changed in the
  real tag-to-tag diff but absent from BOTH snapshots is reported as
  `UNMANIFESTED-CHANGE` and the script exits 4 (treat as failure in CI).
  TDD; `upgrade-classify.test.sh` at 34 cases.
- **Friction 3 — living-file merges had zero mechanical support:**
  delimiter convention (Operator decision) — the seven role charters and
  `MEMORY.md` now carry the split-merge marker: template-verbatim content
  above, downstream-owned content below, upgrades replace above the line
  only. Playbook Manual-Merge Guidance gains the mechanical split-merge
  procedure and the merge-blocking one-time migration subsection (first
  upgrade crossing 1.25.0). Per-release `git apply --3way` patches
  REJECTED at triage: a per-release maintainer artifact forever, treating
  the symptom.
- **Friction 4 — classify noise:** `upgrade-classify.sh --hide-excluded`
  suppresses `do-not-export` rows (the recurring `AI/` / `.mm.md` noise);
  default off for back-compat. TDD alongside friction 2.
- Meta: `docs/export-manifest.md` charter/`MEMORY.md` row notes point at
  the split-merge; delimiter convention noted in the manifest's
  criticality preamble; `minion-version.md` annotation.
- Guardrails: no governance-token changes; full 6-file `tools/tests`
  suite green.

## 2026-07-02 (v1.24.0 — Model tiering: vendor-neutral capability bands)

- Commit hash: pending (staging→main PR merge)
- **Provenance:** Network-Inventory downstream field packet
  (`AI/feedback/2026-07-02-model-tiering-field-feedback.md`), triaged and
  evidence-verified in `AI/feedback/2026-07-02-model-tiering-triage.md`.
  The packet's "template says nothing about model tiers" claim was only
  partly true — pipeline-mode tier guidance already existed
  (`docs/minion-prompt-modes.md:243-264`, vendor-named Opus/Sonnet) — so
  the accepted gap was role-level guidance outside pipeline mode, plus
  reconciling the existing vendor-named text onto vendor-neutral bands.
  The packet's own wrong-HIGH-finding evidence (a frontier orchestrator's
  sloppy diff produced a HIGH-severity "diverged duplicates" finding that
  was wrong — the files were byte-identical once a just-added header was
  excluded — and it shipped in a PR before correction) is the cited
  justification for keeping adversarial-verify passes at Frontier even
  when the rest of a session runs cheaper.
- Guidance doc (part 1 of this milestone): new `docs/model-tiering.md`
  canonizes capability bands (Frontier / Mid / Economy, vendor examples
  as aging orientation only, never requirements), the role/activity →
  tier map (PM orchestrator / AM architecture / gate decisions and SM
  security review / adversarial verify at Frontier; CM split by activity
  — reviewer/final-verifier at Frontier, bounded implementation at Mid
  via the existing coder/tester pipeline variants; DM runbooks/docs at
  Mid; mechanical passes at Economy), the target token profile
  (strong-but-occasional orchestrator over cheap-and-frequent minions),
  and the escalate-by-session-stakes rule. Explicitly advisory and
  outside the governance-scanned invariant set — a downstream pinned to
  a single model loses nothing by ignoring it.
- Rebanded prompt-modes: `docs/minion-prompt-modes.md`'s existing
  vendor-named tier language reconciled onto the same Frontier/Mid/
  Economy band vocabulary as the new doc, closing the packet's own
  vendor-neutral non-goal violation.
- Advisory launcher lines (part 2, this fragment): all 21 role launchers
  across the three families (`.github/agents/*.agent.md`,
  `.codex/agents/*.toml`, `.claude/agents/*.md`) gain an identical
  `Recommended tier: ...` prose line placed next to the role-charter
  read reference, one per role, matching the doc's map exactly. Pure
  advisory prose — no `model:` frontmatter or Codex/Copilot functional
  field was added or changed; Claude's seven existing pins (six
  `model: opus`, `dm` at `model: sonnet` — together implementing the tier
  map exactly) are untouched and documented as that family's optional
  enforcement mechanism on top of the shared advisory default.
- Pointers: `docs/export-manifest.md` gains a row for the new doc
  (`yes` / `template-replace` / `reference` / PM); this fragment is the
  changelog pointer; `minion-version.md` bumped to `1.24.0-1.0.0` with a
  dense annotation scoped to both commits on this branch.
- Guardrails unchanged: no governance-token changes, no new functional
  model pins, `tools/tests/governance-consistency.test.sh` does not (and
  per the new doc, should not) check tier compliance. Full
  `tools/tests` suite green.

## 2026-07-02 (v1.23.0 — Capability discovery & utilization)

- Commit hash: pending (staging→main PR merge)
- **Provenance:** work-fork field bug — minions did not know which
  skills, connectors, or plugin agents existed in their environment and
  therefore did not use them, despite `docs/minion-plugin-pairings.md`
  already documenting "Access ≠ use". The gap sat upstream of the
  pairings: no inventory, no bootstrap read, no refresh loop, no
  utilization instruction in cross-tool calls. Design in
  `docs/superpowers/specs/2026-07-02-capability-discovery-design.md`.
- Inventory artifact (D1): new `minions/capabilities.md` starter — a
  downstream-owned, per-repo table of capabilities (name; kind
  `skill`/`connector`/`agent`; per-environment availability for Claude,
  Codex, and Copilot; status `active`/`deferred`/`absent`; paired roles
  per the pairings doc; one-line use-for). The template ships
  instructions plus clearly-marked example rows; each repo fills and
  owns its own copy. It is the activation record for
  `docs/minion-plugin-pairings.md`.
- Onboarding step (D2): `INIT.md` gains an explicit step — enumerate
  each AI tool's skills/connectors/agents and fill the inventory
  (launcher families marked deferred in the checklist enter with status
  `deferred`); `docs/operator-onboarding-checklist.md` gains a
  filled-inventory completion line; the pairings doc backlinks the
  inventory as the record that activation condition 1 (present in the
  environment) holds.
- Bootstrap read + utilization obligation (D3): `minions/capabilities.md`
  joins the session read lists in `CLAUDE.md`, `AGENTS.md`, and
  `.github/copilot-instructions.md`, and ranks in `AI.md`'s
  source-of-truth order as environment truth (absence of a listed
  capability at call time is a silent skip, never a blocker).
  `MEMORY.md` gains a Capability Inventory subsection under Shared
  Rules, and all seven role charters carry an identical obligation
  line: when an inventoried capability fits the task, using it — within
  charter limits — is an obligation, and hand-rolling what a listed
  capability already does is a review finding. Execution Quality gains
  the matching review-lens bullet, and the review-stage prompts carry
  the same check: the `/ship` stage-7 read-only reviewer and stage-8
  cross-vendor prompts flag hand-rolled work where an inventoried
  capability fit the task, per the Pipeline Mode review guidance in
  `docs/minion-prompt-modes.md`. `docs/minion-plugin-pairings.md`
  reframes its former "use-if-available" language to the obligation,
  scoping its conditionality to absent or non-inventoried integrations.
- Refresh loop (D4, PM-owned): PM re-inventories at each milestone/run
  start and whenever a `DURABLE LESSONS:` or `feedback.md` entry flags
  a capability gap, change, or friction. Tool/capability observations
  are a named `DURABLE LESSONS:` category batched into inventory
  updates at consolidation — the Completion Handoff Contract's item 10
  names the category and adds `minions/capabilities.md` to the batching
  destinations — and PM-authored dispatch briefs distribute the
  relevant inventory rows to spawned minions — stable decision
  records, handled like reviewer verdicts.
- Cross-tool utilization line (D5): every `tools/xtool-call.sh` prompt
  — codex and copilot, review and delegate — now carries a standing
  envelope line, mode-aware so review stays read-only: delegate prompts
  carry "Enumerate your available skills/tools first and utilize any
  that fit the task; report which you used."; review prompts carry the
  READ-ONLY-qualified variant ("...utilize any READ-ONLY ones that fit
  the task; make no state-changing tool calls during review...")
  because the review contract is read-only (codex `-s read-only`;
  copilot deny write/shell) but side-effectful MCP connectors remain
  invocable there. One exact string per mode, each defined once so the
  strings cannot drift between paths. TDD: argv-capture cases in
  `tools/tests/xtool-call.test.sh` assert presence per mode, that the
  unqualified line never reaches review argv, placement after the
  caller prompt, and the review-mode Target suffix; suite 65/65.
  The delegate-mode instruction is also part of PM's dispatch-brief
  guidance for spawned minions (`minions/roles/PM.md`), carried in the
  brief alongside the D4 inventory-row distribution.
- Minor sweep (same version): `minions/capabilities.md` starter example
  rows brought into compliance with the file's own legend (the `absent`
  example row no longer claims Claude availability), and all 21 role
  launchers across the three families (`.github/agents/*.agent.md`,
  `.codex/agents/*.toml`, `.claude/agents/*.md`) add
  `Read minions/capabilities.md.` to the bootstrap read preamble,
  matching the MEMORY.md/capabilities.md session-bootstrap claim
  (behaviorally identical wording per the Instruction-File Audit Rule).
- Known test-fidelity gap (deferred, not implemented): the fake
  provider's argv capture (`printf '%s\n' "$@"`) cannot distinguish
  argument boundaries from newlines inside prompts; acceptable for
  today's assertions, future work if multi-line assertion precision is
  ever needed.
- Guardrails unchanged: the utilization obligation never overrides
  charter lanes (RM stays recommend-only; SM and PM still produce no
  product code), and no governance tokens moved. Export-manifest row
  for the new file (initial export yes, `downstream-owned`, `baseline`
  — the starter must land at first export because the bootstrap read
  depends on it; upgrades never overwrite the filled inventory).
- Known limitation: in copilot review mode, read-only is enforced by
  write/shell deny-flags which cannot reach side-effectful MCP connectors;
  the READ-ONLY-qualified utilization line is a prompt-level mitigation,
  not an enforcement boundary.

## 2026-07-02 (v1.22.1 — Overlay discipline + drift guards)

- Commit hash: pending (staging→main PR merge)
- **Provenance:** coordinator feedback triage items 2.1, 2.2, 3.1, 3.2,
  4.1, 4.3, 6.1, 6.2
  (`AI/feedback/2026-07-02-coordinator-feedback-triage.md`); design in
  `docs/superpowers/specs/2026-07-02-overlay-discipline-design.md`.
- Optional-Layers convention codified (D1): new preamble in `MEMORY.md`'s
  Communication Model above the Issue Mirror / Memory Recall subsections —
  optional layers ship default-off behind a `MINION_*` gate, absence is a
  silent no-op that never blocks a workflow, canonical docs carry an
  Enabling It section with activation and rollback, governance files
  reference layers only in gate-conditioned language, and retiring an
  overlay is doc + pointer removal, never a governance sweep.
- Multi-session note (D2): `MEMORY.md`'s Single-Writer Durability subsection
  now states the contention trigger (2+ concurrent sessions committing
  overlapping files on the same branch) and the first-line answer —
  partition write sets (one session per feature branch; coordinator
  session lanes at multi-project scale), never a serialization role.
- Canonical role list (D5): `MEMORY.md`'s Collaboration Model roster is
  declared the canonical role-set enumeration; `AI.md`'s Role Agents list
  now defers to it. `tools/tests/governance-consistency.test.sh` gains a
  self-tested drift guard comparing the two lists in normalized form
  (lowercase; `om-test` folds into `om`).
- Copilot launcher reconciliation (D4): `.github/agents/` bodies for
  `am`, `cm`, `sm`, `dm`, and `om` realigned to the agreeing
  Codex/Claude behavioral reference (CM's review/investigation no-edit
  rule and OM's OM-Test default posture restored, among other
  role-level drifts); `pm` already matched, `rm` reconciled in this
  sweep (added the "lead with options and a recommendation" clause to
  `.codex/agents/rm.toml` and `.github/agents/rm.agent.md`). Copilot-specific
  frontmatter and tool whitelists kept; the Codex/Claude families are
  untouched.
- Cross-family launcher sync line (D4, rule text): `MEMORY.md`'s
  Instruction-File Audit Rule now requires launcher bodies for the same
  role to stay behaviorally identical across the `.github/agents/`,
  `.codex/agents/`, and `.claude/agents/` families, with a cross-family
  audit on any launcher change.
- Deferred-state records (D3): `docs/downstream-onboarding-playbook.md`
  gains the quotable DEFERRED notice for any launcher family exported but
  not yet active (removed on activation; baseline files are not deferred
  by default), and `docs/operator-onboarding-checklist.md` gains one
  activation-state line per launcher family (Copilot / Codex / Claude:
  `active` / `deferred` / `not exported`).
- Extending the role set (D6): `docs/downstream-onboarding-playbook.md`
  gains the minimum touch list for adding a role downstream — role
  charter, every launcher family in use, downstream `MEMORY.md` roster,
  the Completion Handoff `NEXT OWNER` enumeration, and the `AI.md` Role
  Agents list (five mandatory surfaces total) — with the historical `SM`
  drift named as the precedent.
- Plan STATUS lifecycle (D7): `minions/plans/milestone-plan-template.md`
  replaces the hardcoded `Status: Active` with a lifecycle marker —
  `OPEN`, `CLOSED — COMPLETE`, `CLOSED — SUPERSEDED (superseded-by:
  <ref>)` — anchored to the Exit Criteria section;
  `minions/plans/README.md` documents the lifecycle plus the rules that
  the top-of-file marker (not checkbox completion) is the closure
  signal, and that a plan must not remain `OPEN` once the execution
  model it was written against no longer exists — supersede it the
  same day.

## 2026-07-02 (v1.22.0 — Coordinator-mode overlay: multi-project session lanes)

- Commit hash: pending (staging→main PR merge)
- **Provenance:** coordinator field feedback — a real multi-project
  coordinator fork returned a 15-item packet; every item was
  evidence-verified against template main before triage
  (`AI/feedback/2026-07-02-coordinator-feedback.md`,
  `AI/feedback/2026-07-02-coordinator-feedback-triage.md`).
- New `docs/coordinator-mode.md` — canonical opt-in overlay for running one
  template-derived repo as a multi-project coordinator (Optional-Layers
  pattern: single-project baseline unchanged in meaning; a repo that never
  coordinates multiple projects reads nothing new but two pointer
  sentences).
- Session-lane concurrency model: one session = one project lane at a time;
  a session's writes are confined to `projects/<key>/**`, the project's
  submodule via its own branch flow, and the session's own topic-scoped
  `CHANGELOG.d/<topic>.md` fragment; coordinator-shared surfaces (root
  `MEMORY.md`, `projects/index.md`, coordinator `minions/mail/`,
  coordinator `CHANGELOG.md`, root `feedback.md` — lane sessions route
  Operator corrections via lane packet) are written only by the coordinator
  seat, with lane packets as the request path — the roll-up law applied one
  level up. Contention is eliminated by partitioning (lanes plus
  topic-scoped fragments) and single-writer ownership (shared surfaces); no
  serialization role. Multiple sessions inside one project lane are
  explicitly out of scope and unsupported.
- Branch-plane mapping for lane surfaces (When to Scale): lane `MEMORY.md`
  and `chat/` are Class A — mainline-authoritative, staleness rule applies —
  and lane `mail/<packet>/` is Class B, per
  `docs/branching-and-release-model.md`.
- Project registry: `projects/index.md` with required columns (project key,
  submodule path, repo URL, default branch, PM owner, risk tier, onboarding
  status); PM validates every packet's `PROJECT:` field against it and
  rejects unregistered keys; rows are never deleted (status `retired`).
- Mail routing: registered project → `projects/<key>/mail/`; coordinator,
  cross-project, or policy → `minions/mail/`; lane packets carry a
  `PROJECT: <key>` header field added to the baseline packet structure.
  Onboarding carve-out: packets about a project whose registry row is still
  `onboarding` route to `minions/mail/` until the PM gate passes; the
  add-submodule runbook cites the carve-out for its gate packet placement.
- New `docs/runbooks/add-submodule.md` — registration sequence: submodule
  add → lane scaffold (`projects/<key>/MEMORY.md`, `mail/README.md`,
  `chat/`) → registry row at `onboarding` → PM onboarding gate packet → PM
  verifies scaffold before `in-progress`; removal via deinit + registry
  status `retired`, never row deletion.
- `docs/downstream-upgrade-playbook.md` gains a "Coordinator-mode upgrades"
  subsection mapping the coordinator's three upgrade categories onto the
  existing manifest classes (copy-directly ≈ new `template-replace` files;
  take-template ≈ `template-replace`; preserve ≈
  `manual-merge`/`downstream-owned`) and naming coordinator surfaces
  (`projects/`, overlay activation state, coordinator role additions) as
  expected intentional divergence in `upgrade-classify.sh` output.
- One-line baseline pointers only: `INIT.md` (before step content) and
  `docs/project/mailbox-collaboration-model.md` (Directory Layout) link to
  `docs/coordinator-mode.md`; `MEMORY.md` and `AI.md` untouched.
- Manifest hygiene rider (D8): registered the previously-unmanifested
  `.github/instructions/documentation-quality.instructions.md` in
  `docs/export-manifest.md` (`template-replace` / `feature` / DM), plus
  rows for the two new overlay docs.

## 2026-07-02 (v1.21.4 — Public-export runbook)

- Commit hash: pending (staging→main PR merge)
- Codifies the live 2026-07-02 export of a privacy-safe copy of this
  template to a public repo (github.com/deamonkai/minions-template),
  publishing fresh history rather than canonical history.
- New `docs/runbooks/public-export.md` (Operator/PM-owned): manifest-
  filtered export from a tagged canonical release using
  `docs/export-manifest.md` rows marked `Initial export: yes`; deliberately
  adds `README.md` with an "About This Copy" section (source version +
  divergence list) even though the manifest classes it downstream-owned;
  tree-wide token-based privacy-neutralization sweep (the live run's
  single-line pass missed a personal-context heading echoed in `INIT.md`
  and `CHANGELOG.md` — only the tree-wide grep caught it), with
  `feedback.md` reset to a clean capture-log stub; mandatory pre-push
  verification gates (export's own `tools/tests/*.test.sh` suite,
  `gitleaks detect --no-git`, forbidden-file check for `.mm.md`, `AI/`,
  `.remember/`, `.superpowers/`); single-commit publish with an annotated
  tag matching the canonical release; re-publish cadence for later
  canonical releases the Operator chooses to make public.
- New `docs/export-manifest.md` row for the runbook itself
  (`template-replace` / `reference` / PM).
- Rollback note: public content may be cached or forked the moment it is
  pushed, so the neutralization sweep and gitleaks gate are pre-push hard
  gates, never post-push cleanup.

## 2026-07-02 (v1.21.3 — tea v0.14.1 compat, downstream-authored)

- Commit hash: pending (staging→main PR merge)
- **Provenance:** downstream-authored (downstream trading-bot project team), absorbed
  upstream 2026-07-02 so future downstream upgrades stop re-fighting it.
- `tools/issue-sync.sh`: `tea` v0.14.1 renamed the issue-body flag
  (`--body` → `--description`/`-d`) and the edit-time label flag
  (`--labels` → `--add-labels`); a `--body` call fails outright on 0.14.1,
  so every `sync` soft-failed (exit 4) and created nothing. The Gitea
  backend funcs now detect the installed `tea`'s flag names from
  `tea issues create --help` and prefer `--description`/`--add-labels`,
  falling back to `--body`/`--labels` on older builds.
- `tools/issue-board-bootstrap.sh`: on 0.14.1 `tea labels create` exits 0
  on a duplicate name and creates a *second* same-named label (it does not
  fail on collision), so blind re-creation silently doubled the label set.
  The bootstrap now snapshots existing labels once (`tea labels list` /
  `gh label list`) and skips those already present — query-then-skip,
  genuinely idempotent re-runs on any host.
- `tools/tests/fixtures/make-fake-provider.sh`: 0.14.1-faithful fake `tea`
  (rejects `--body`, edit rejects `--labels`, `labels create` records
  duplicates and exits 0, `labels list` replays the recorded set).
- Tests: +9 issue-sync cases (create uses `--description`, edit uses
  `--add-labels`, legacy flags rejected) and +3 bootstrap idempotency cases
  (re-run does not double labels) — suites now at 50 and 20 cases.
- `docs/runbooks/issue-board-setup.md`: supported-`tea`-version header,
  query-then-skip idempotency note, and a "tea v0.14.1 compatibility notes"
  section.
- **Known coverage gap:** the fake tea's `--help` exits non-zero, so
  `tea_supports_flag`'s grep-detection and legacy-fallback branches aren't
  exercised by the suite (only the assume-modern path is); a help-capable
  fake variant is future work.

## 2026-07-02 (v1.21.2 — Memory gate shell-profile fix: .zshenv, not .zshrc)

- Commit hash: pending (staging→main PR merge)
- Fixed a defect in `docs/runbooks/memory-recall-setup.md`: the
  persistent-setting recipe told the Operator to put
  `export MINION_MEMORY=on` in the shell profile (`~/.zshrc`), but agent
  tool-shells are non-interactive zsh, which never sources `~/.zshrc` —
  only `~/.zshenv`. An export in `~/.zshrc` makes the gate look "on" in
  the Operator's interactive terminal while every agent shell still
  reads it as unset, so the memory recall layer stayed silently inert.
- Fix: for zsh (macOS default), the persistent export now goes in
  `~/.zshenv`, which is sourced by all zsh invocations, interactive and
  non-interactive alike. For bash, since non-interactive sourcing of
  `~/.bashrc` varies by invocation convention, the runbook now
  recommends setting the export in both `~/.bashrc` and
  `~/.bash_profile`, or better, verifying directly.
- New rule: verification must run from the agent's own fresh tool shell
  (`echo ${MINION_MEMORY:-<unset>}`), never from the interactive
  terminal — the two shell types read different profile files and can
  disagree silently.
- Provenance: found by dogfooding on 2026-07-02 — the Operator followed
  the runbook exactly, saw the gate as `on` in their terminal, but every
  agent shell saw it as unset the whole time.

## 2026-07-02 (v1.21.1 — Verdict distribution in gate briefs)

- Commit hash: pending (staging→main PR merge)
- New rule: dispatch briefs for gate decisions must carry the reviewer
  verdicts explicitly — distilled verdict, conditions, and severities,
  transcribed verbatim by the orchestrator. Raw artifacts stay available
  as reference, never as the gate's primary input.
- Two-sided brief-content pairing with the v1.20.1 live-state-briefs rule:
  mutable world facts (runtime state) are NOT embedded — the brief
  instructs live verification, because they age. Immutable decision
  records (verdicts, conditions) ARE embedded verbatim — the gate must
  not be made to re-derive them from large artifacts, because reader-side
  reads can truncate silently.
- Added to MEMORY.md (Execution Quality, sibling bullet to the v1.20.1
  live-state bullet) and `minions/roles/PM.md` (Single-Writer Durability:
  PM-authored gate briefs embed verdicts verbatim instead of directing
  the gate agent to re-read raw artifacts).
- Provenance: downstream PM-codex truncation incident — a gate agent's
  own reader-side re-read of a large raw review artifact came up
  truncated, and the gate proceeded on partial evidence. v1.20.0's
  single-writer durability window already prevents half-*written*
  artifacts (writer commits each deliverable before the next stage);
  this rule closes the complementary reader-side case, where the
  artifact was written whole but the gate's own read of it truncated.

## 2026-07-02 (v1.21.0 — Memory recall layer: Mnemoverse as optional view layer)

- Commit hash: pending (staging→main PR merge)
- New optional recall layer, off by default: Mnemoverse (or a compatible
  memory service) as a semantic index over promoted repo knowledge.
  Enabled via `MINION_MEMORY=on`; when the variable is unset or the
  memory tools/API are absent, every memory step is a silent no-op — no
  minion workflow is ever blocked by memory absence. Files always win;
  recall output is input, not authority.
- **Write path (curated, writer-owned):** only the packet's single
  writer calls `memory_write`, and only at promotion moments — an
  applied `DURABLE LESSONS:` item, an accepted decision or release
  summary, or an Operator-directed "remember this." Domain scheme
  `project:<repo-name>` (this repo: `project:minions-template`).
- **Read path (orchestrator recall into briefs):** the orchestrator
  queries the project domain at run start and folds relevant recall into
  dispatch briefs — spawned minions need no MCP access. Recalled runtime
  facts are presumptive; briefs still instruct live-state verification.
- **Security boundary — four excluded classes, never mirrored:**
  secrets/credentials and credentials-adjacent state; `SOLE-HOLDER:`
  facts; personal data; packet bodies, diffs, or code. Only distilled
  lesson/decision text crosses.
- **Transport:** MCP tools today (`memory_write/read/stats/delete/
  delete_domain`); REST fallback documented for non-Claude orchestrators
  (base `https://core.mnemoverse.com/api/v1`, endpoint paths transcribed
  from the vendor llms.txt, `MNEMOVERSE_API_KEY` environment-only).
- New docs: `docs/memory-recall-model.md` (canonical model) and
  `docs/runbooks/memory-recall-setup.md` (operator runbook: gate
  variable facilitation, per-machine connection, API key, smoke test,
  disable/rollback). Wired into `MEMORY.md`, `minions/roles/PM.md`, and
  `AI.md`; export-manifest rows added for both docs; version bumped to
  `1.21.0-1.0.0`.
- **Backtest:** smoke loop validated live against the real service on
  2026-07-02 (write -> read [relevance-scored hit] -> stats -> delete_domain
  [confirm interlock] -> stats clean); runbook step semantics corrected to
  observed tool behavior.

## 2026-07-02 (v1.20.1 — Live-state briefs: confirm runtime state, don’t embed snapshots)

- Commit hash: pending (staging→main PR merge)
- New rule: dispatch briefs for runtime-touching work must instruct the
  agent to confirm live state first, never embed a presumed runtime
  snapshot — embedded state ages between authoring and execution; a brief
  states what to verify, not what is true.
- Provenance: downstream field report (third distilled rule, six agent
  datapoints) — a deploy brief embedded a presumed runtime snapshot
  ("assume a flat book"); reality at execution time was 10 carried
  positions. The executing agent handled it but had to guess, which is the
  failure mode this rule closes.
- Applied to `MEMORY.md` (Execution Quality), `minions/roles/OM.md`
  (Guardrails — briefs OM/OM-Test receives or authors must say "confirm
  live state first" before acting on positions, config checksums, or
  service status), and `minions/roles/PM.md` (Single-Writer Durability
  area — PM-authored runtime-touching briefs instruct verification instead
  of embedding presumed state).

## 2026-06-29 (v1.20.0 — Single-writer durability for the comm model)

- Commit hash: pending (staging→main PR merge)
- Driven by a downstream field report: parallel/fan-out minion work was
  producing repo/branch write contention and half-written handoff packets
  when multiple spawned minions committed concurrently. This milestone
  canonizes **single-writer durability** to close that gap.
- **Rule:** spawned minions do not commit or push. They complete their work
  and *return* the Completion Handoff packet to whoever spawned them,
  verbatim. Only the top of the spawn chain — the single writer for that
  chain — commits to the repo/branch. Rationale: eliminates repo/branch write
  contention, fan-out coordination overhead, and the risk of a half-written
  packet landing mid-commit.
- **Scope split:** coordination artifacts (handoff packets, mailbox state,
  plan/status tracking) roll up through the spawn chain to the single writer;
  code deliverables stay in-lane and are committed by the implementer on its
  own feature branch — the writer never re-commits code, only coordination
  artifacts roll up to the writer.
- **Durability window:** the writer commits each returned deliverable before
  dispatching the next stage of work — at most one in-flight (uncommitted)
  deliverable at any time, bounding how much work is at risk if a session
  drops.
- **Attribution:** returned packets carry a `WRITTEN-BY:` header identifying
  the actual writer, and are transcribed verbatim into the repo rather than
  summarized or reformatted — preserving the original author's record even
  though they didn't commit it themselves.
- **`DURABLE LESSONS:`** — an optional handoff section a spawned minion can
  use to flag durable, cross-cutting learnings; the single writer batches
  these across a run rather than committing them piecemeal.
- **Escape valve:** oversized deliverables that shouldn't be transcribed
  inline (large diffs, generated artifacts) may be written directly to disk
  by the spawned minion without committing, with a return path back to the
  writer that points at the on-disk location instead of embedding content.
- **Generalized across the model:** all seven role charters, `AI.md`, and
  Pipeline Mode now state the single-writer rule consistently, replacing the
  earlier ad hoc "direct return" language with one normalized law.
  Governance drift-guard tokens updated so future edits can't silently
  reintroduce concurrent-writer language.
- **`SOLE-HOLDER:`** return flag + persist-first rule, added from a
  downstream OM-Test field report: an execution-seat agent's rollback
  anchors (config md5, backup path) existed only in its return until
  persisted. The packet's single writer now persists sole-holder facts
  immediately on return, ahead of the normal durability window.

## 2026-06-29 (v1.19.1 — issue-sync test-hardening + soft-fail diagnostic)

- Commit hash: pending (staging→main PR merge)
- Closes the non-blocking coverage/diagnostic gaps deferred from the v1.19.0
  final review. Patch bump to `1.19.1-1.0.0`. No new files; the default-off
  layer is unchanged in behavior except the diagnostic improvement below.
- **Changed — `tools/issue-sync.sh` surfaces backend diagnostics on soft-fail.**
  The Gitea/GitHub create+edit functions previously ran `tea`/`gh` with
  `2>/dev/null`, hiding the backend error when a sync soft-failed (exit 4). They
  now surface the backend's stderr while keeping the soft-fail contract intact
  (exit 4, no `.issue` sidecar written on a failed create, idempotent).
- **Added — +14 `tools/tests/issue-sync.test.sh` cases:** GitHub edit + GitHub
  soft-fail (mirroring Gitea); hyphenated-topic recipient parse anchored to
  reject `role:<recipient>-*` corruption; exact banner (incl. em dash);
  `--type blocker` Operator assignee; label comma-separation.

## 2026-06-29 (v1.19.0 — Issue/project mirror: visibility & coordination layer)

- Commit hash: pending (staging→main PR merge)
- Adds an **optional, default-off, host-agnostic** Issue/board mirror so
  inter-agent comms gain Operator visibility, gate tracking, and notifications —
  while git files remain the source of truth. Bumped template version to
  `1.19.0-1.0.0`. Assembled from the `CHANGELOG.d/issue-mirror.md` fragment at
  the staging gate. Enable with `MINION_ISSUES=on` after bootstrapping the board;
  off, the layer is inert.
- **`tools/issue-sync.sh`** — one-way projection of git-native packets onto the
  host Issue tracker (files always win). Subcommands `host` / `render` / `sync`;
  `sync --type mail|gate|blocker|pipeline|chat --packet <path>` (pipeline =
  per-run, chat = per-day). Idempotent via a `.issue` sidecar; soft-fail (exit 4)
  never blocks a handoff; disabled/CLI-absent → no-op exit 0.
- **`tools/issue-board-bootstrap.sh`** — idempotent label bootstrap (the standard
  `type:`/`role:` set); board creation is manual per the runbook. Safe to re-run.
- **Backends:** Gitea full create/edit via `tea`; GitHub interface-ready via `gh`
  (same verbs + exit-code contract; Projects-v2 board wiring deferred).
- **Mapping (tiered granularity):** per-packet mail, per-gate gate/blocker
  (assigned to the Operator), `staging→main` gate = the PR card, per-run pipeline,
  per-day chat. Labels on two axes (`type:`/`role:`); status lives in the board
  column (`Triage → In Progress → Awaiting Review → Awaiting Operator → Done`).
- **Docs:** new `docs/issue-mirror-model.md` (canonical model) and
  `docs/runbooks/issue-board-setup.md` (OM-owned setup, Gitea + GitHub recipes).
  `MEMORY.md` Communication Model + PM/CM/DM charters wired to the layer.
- **Meta:** export-manifest rows for the new tools/docs (`.issue` sidecars are
  Class B / downstream-owned, not exported); offline fake-provider tests keep the
  full `tools/tests/*.test.sh` suite green.

## 2026-06-27 (v1.18.0 — Branching & release model for minions)

- Commit hash: pending (staging→main PR merge)
- Adopts a 4-tier `feature → dev → staging → main` branching model into the
  minion workflow, dogfooded through its own flow and documented as the
  downstream convention. Bumped template version to `1.18.0-1.0.0`. Assembled
  from the `CHANGELOG.d/branching-model.md` fragment at the staging gate.
- **New canonical doc: `docs/branching-and-release-model.md`.** Single source of
  truth for the branches, the eight-step promotion flow, the gate-authority
  table, the Class-A/Class-B coordination plane, the CHANGELOG-fragment
  mechanism, the staleness rule, hotfix/rollback, and a 3-tier downstream
  variant.
- **Relocated hard-stop.** The single Operator hard-stop moves to `staging→main`
  (a pull request); `feature→dev` and `dev→staging` are autonomous CLI merges.
  `MEMORY.md` and `AI.md` updated (still exactly three hard-stops); the
  governance test was extended to assert the relocated wording and the
  coordination plane in both files.
- **Class-A / Class-B coordination plane.** Class A (`MEMORY.md`, `AI.md`,
  `CLAUDE.md`, `AGENTS.md`, `minions/roles/*`, `ROADMAP.md`, `TODO.md`,
  `minions/chat/`) is mainline-authoritative; Class B (a feature's mail packet,
  plan, specs, and `CHANGELOG.d/<topic>.md`) travels with the branch and merges
  up. `AI.md` gains "Reading Truth in a Multi-Branch World".
- **CHANGELOG fragment mechanism.** Feature branches write
  `CHANGELOG.d/<topic>.md` instead of editing `CHANGELOG.md`; DM assembles the
  fragments into `CHANGELOG.md` and deletes them at the staging gate. Eliminates
  cross-branch `CHANGELOG.md` conflicts. `MEMORY.md` CHANGELOG Maintenance Rule
  updated accordingly.
- **Role charters** (`CM`, `OM`/`OM-Test`, `DM`, `PM`) gain Branch Ownership:
  CM authors fragments + drives `feature→dev`; OM-Test validates `dev` + drives
  `dev→staging`; OM validates `staging`, deploys/tags `main`, owns hotfix +
  rollback; DM assembles the CHANGELOG + confirms Class-A doc-sync; PM runs the
  final gate and opens the `staging→main` PR.
- **VCS-host-agnostic.** Model and guardrail docs speak in host-neutral terms
  ("pull request", "the project's VCS host"). Host-specific setup lives in the
  renamed `docs/runbooks/branch-setup.md` as interchangeable **Gitea** and
  **GitHub** recipes. The `tea`/`gh` CLIs are optional conveniences (installable
  without Homebrew); the web UI is the toolless fallback in each.
- **Meta:** `docs/export-manifest.md` gains rows for the new doc, runbook, and
  `CHANGELOG.d/`; `minion-version.md` bumped with an annotation; `feedback.md`
  captures two promote-candidate portability rules (no tool/installer
  assumptions; host-agnostic model).

## 2026-06-24 (v1.17.0 — Shadow-first / dark-ship risk posture)

- Commit hash: pending (next commit)
- Canonizes the deferred downstream "shadow-first" pattern as an **optional**
  risk posture. Bumped template version to `1.17.0-1.0.0`. **No code shipped** —
  the template carries the posture and contract; each downstream implements it in
  its own stack.
- **new doc: `docs/risk-posture-shadow-first.md`.** Generic, domain-neutral
  write-up of the 4-layer pattern (flag-default-off zero-compute pass-through →
  pure comparator emitting `{MATCH, EXPECTED, REGRESSION}` by exact canonical
  equality → empty-by-default `EXPECTED_DIVERGENCES` allow-list with
  `(note_id, justification, predicate)` entries → adopt-on-MATCH + per-decision
  tripwire fallback that counts every divergence), the isolation-test-with-teeth
  discipline (all-OFF byte-identity + a forced-divergence case + a paired
  adopt-changes-it case so the suite can't be vacuous), the third-outcome
  adopt-a-justified-divergence mechanism, and a 7-piece minimal contract. Includes
  an explicit **when-NOT-to-use** (greenfield / no incumbent / non-critical →
  overkill) so it doesn't read as a mandate.
- **MEMORY.md Deployment Discipline** gains an opt-in pointer to the posture.
- **export-manifest.md** lists the new doc (`template-replace`, `feature`,
  PM / AM) so downstreams receive it.
- Distilled from the a downstream trading-bot project downstream's implementation (it runs the
  pattern across multiple independent decision points); trading-specific machinery
  deliberately left out. Class ②/dual-vendor from the same packet was already
  shipped in v1.16.0; this resolves the deferred class ①.
- **cross-tool review:** dual-vendor dogfood (Codex + Copilot) — both
  AGREE-WITH-NITS (Copilot: SHIP). Applied: generalized a "test/paper" domain
  leak, added the side-effect-isolation caveat (observe-and-discard is risk-free
  only if the shadow recompute is pure or its writes are sinked), required
  same-input capture, and added an allow-listed-EXPECTED adopt test case.

## 2026-06-24 (v1.16.0 — Downstream feedback: review-ergonomics quick wins)

- Commit hash: pending (next commit)
- Adopted the low-risk, broadly-applicable items from a a downstream trading-bot project
  downstream feedback packet (heavy-use observations). Bumped template version to
  `1.16.0-1.0.0`. Deferred (Operator's call): parallel/domain-scoped review
  cadence, and the shadow-first risk posture + operator-facing-craft items.
- **review brevity (SM/DM charters).** `minions/roles/SM.md` and `DM.md` review
  postures now mandate **deltas-only** output: one-line verdict, then only action
  items + load-bearing evidence; passing checks collapse to a single "rest
  verified clean" line (no verbatim re-quoting, no all-green tables). Review
  reports were running 50–80 lines for a ~5-line actionable core.
- **dual-vendor on security diffs (cross-tool doc).** `docs/cross-tool-orchestration.md`
  now says to run BOTH `codex` and `copilot` on security/control-surface changes
  (each catches HIGHs the other clears), and to treat vendor severity as input and
  re-triage against repo evidence (vendors miscalibrate) — matching the template's
  own dogfooded practice.
- **operator-facing surfaces as definition-of-done (MEMORY.md).** Execution
  Quality gains a bullet: a change that adds/alters a config flag, journal/log
  event, metric, or feature must review the operator-facing surfaces (config
  editor, dashboard, runbooks) before done — flags drift out of the UI silently.
- **worktree pruning note.** `docs/cross-tool-orchestration.md` (delegate
  worktrees) and `.claude/agents/README.md` (a new Worktree Hygiene section) note
  that worktree-isolated agents accumulate leftover worktrees; prune after the
  branch lands (`git worktree remove` / `git worktree prune`).
- **charters-as-living-state onboarding.** `docs/operator-onboarding-checklist.md`
  now reinforces that each role keeps its own `minions/roles/*.md` current as
  living state — surfacing a high-value habit at onboarding, not just in MEMORY.md.
- **cross-tool review:** dogfooded dual-vendor review (Codex + Copilot via the
  fixed `--prompt -` path — itself an exercise of the dual-vendor practice this
  change documents). Both AGREE-WITH-NITS; all nits applied: vendor-neutral
  severity phrasing (dropped "codex over-rates" from the exported doc), reconciled
  the one-line-verdict wording with the existing findings-first order, and
  cross-referenced "both vendors on security" in the `/ship` stage.
- governance + xtool suite green. The "agents linger as Running / TaskStop
  doesn't recognize IDs" item is a Claude Code harness behavior, not the template —
  routed separately as advice, not a template change.
- Release note: version bumped and CHANGELOG recorded; the `v1.16.0` git tag and
  push to `main` remain an Operator-gated release step (hard-stop), not done here.

## 2026-06-24 (v1.15.0 — Triaged Copilot .github prompt-eval findings)

- Commit hash: pending (next commit)
- First real application of the v1.13.0 Instruction-File Audit Rule: triaged the
  25 prompt-evaluation findings Copilot logged in `AI/open-questions.md` across
  three `.github/` instruction files. Bumped template version to `1.15.0-1.0.0`.
- **fix: 3 clarifications to `.github/instructions/documentation-quality.instructions.md`** —
  defined the `<project-key>` placeholder (substitute the submodule's directory
  name); tied the undefined "gap packet" term to `minions/mail/`; replaced the
  vague "documentation-focused `*.md` files" with concrete examples (guides, ADRs,
  runbooks). Verified both terms were undefined repo-wide before fixing.
- **rejected 22 findings as not-actionable.** `.github/copilot-instructions.md` (9)
  and `.github/agents/README.md` (8) are thin-by-design — "undefined threshold /
  missing fallback" diagnostics are deliberate (detail lives in `MEMORY.md` /
  `AI.md`), already covered (rm "recommends only" is stated), or governance-locked
  (the autonomous-vs-hard-stop line is byte-shared with `CLAUDE.md`/`AGENTS.md`).
  No changes to the two governance-scanned files.
- **chore:** removed the article scratch file `AI/thoughts.md` (an external
  4-agent-pipeline how-to, already superseded by `/ship` + the minion roles, and
  partly contradicting the no-tool-whitelist decision).
- **register:** the three Copilot "Resolve prompt-evaluation findings" entries
  graduated from `AI/open-questions.md` into `AI/decisions.md` (2026-06-24).
- Release note: version bumped and CHANGELOG recorded; the `v1.15.0` git tag and
  push to `main` remain an Operator-gated release step (hard-stop), not done here.

## 2026-06-24 (v1.14.0 — xtool-call.sh review-path hardening)

- Commit hash: pending (next commit)
- Hardens the `review` path of `tools/xtool-call.sh` — the mirror of the
  `delegate` hardening that downstream feedback drove in 1.11.1. Surfaced while
  dogfooding the cross-tool review for 1.13.0 (Copilot silently ran a garbage
  review on a malformed prompt and the wrapper still reported success). TDD:
  10 new failing cases written first, then fixed; suite now 53/53 green,
  dependency-free. Bumped template version to `1.14.0-1.0.0`.
- **fix (A): `--prompt -` now reads stdin.** Previously `--prompt -` set the
  prompt to the literal string `-` (only a standalone `-` token read stdin) —
  codex errored loudly, but copilot ran a garbage review and the envelope still
  said `ok`. `--prompt -` and a standalone `-` are now equivalent.
- **fix (B): review envelope no longer lies on failure.** `run_review` emitted
  `status: "ok"` unconditionally even when the provider exited non-zero. It now
  emits `review-failed` on non-zero rc (the envelope is the durable artifact a
  caller parses). `delegate` mode already had rich failure statuses; `review`
  now matches.
- **fix (C): empty prompt and empty output fail loudly.** An empty prompt
  (including `--prompt -` with empty stdin) is rejected with exit 2 before any
  provider call; a provider that exits 0 but produces empty/whitespace-only
  output is flagged `review-empty-output` with exit 4 instead of a false `ok`.
- **context:** the downstream (a downstream trading-bot project) did not modify the script —
  its committed `xtool-call.sh` is the untouched 1.11.1 baseline, and its earlier
  script feedback (F2 slug sanitization, F4 failed-delegate cleanup, the copilot
  web-fetch note) is already absorbed. These three fixes are net-new review-path
  hardening, not a downstream port.
- **cross-tool review:** dogfooded read-only second opinions (Codex + Copilot via
  `tools/xtool-call.sh`, invoked through the just-fixed `--prompt -` stdin path —
  a live confirmation of fix A). Copilot AGREE (no nits); Codex AGREE-WITH-NITS.
  Both nits applied: `usage()` marks `--prompt` required, and a copilot
  empty-output test was added (the original regression was copilot-specific).
- Release note: version bumped and CHANGELOG recorded; the `v1.14.0` git tag and
  push to `main` remain an Operator-gated release step (hard-stop), not done here.

## 2026-06-24 (v1.13.0 — Instruction-File Audit Standard)

- Commit hash: pending (next commit)
- Establishes a standing workflow convention: audit `CLAUDE.md` and related AI
  instruction/prompt files for quality whenever they change during template
  improvement or upgrade work. Bumped template version to `1.13.0-1.0.0`.
- **convention: Instruction-File Audit Rule.** New rule in `MEMORY.md` — when
  `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `minions/roles/*.md`,
  the `.github/agents/` / `.codex/agents/` / `.claude/agents/` launchers, or this
  repo's slash-command / skill prompt files change, audit them for clarity,
  accuracy, consistency, staleness, and drift before handoff. The manual audit
  (subagent + rubric) is the cross-tool baseline; built-in analyzers are shortcuts
  where available (Claude `/claude-md-improver`; Copilot `/analyze-prompt` in
  surfaces that expose it; Codex manual). `DM` owns instruction-file truth; each
  minion audits files it changes in its own lane.
- **decision + cross-tool review:** recorded in `AI/decisions.md` (2026-06-24).
  Dogfooded read-only second opinions (Codex + Copilot via `tools/xtool-call.sh`)
  both returned AGREE-WITH-NITS; both nits applied — added the Copilot entrypoint to
  the trigger list, and corrected the tool mapping after Copilot CLI reported it has
  no `/analyze-prompt`, making the manual audit the universal baseline.
- Release note: version bumped and CHANGELOG recorded; the `v1.13.0` git tag and
  push to `main` remain an Operator-gated release step (hard-stop), not done here.

## 2026-06-20 (v1.12.0 — Upgrade-Process Tooling)

- Commit hash: pending (next commit)
- Upgrade-process improvements from downstream feedback (a downstream trading-bot project, on
  running the `1.11.0 → 1.11.1` upgrade). Adds the second piece of executable
  tooling after `xtool-call.sh`. Bumped template version to `1.12.0-1.0.0`.
- **feat (#1): annotated release git tags.** Releases are now published as git tags
  (`v1.11.0`, `v1.11.1`, `v1.12.0`, …) so downstreams detect drift with
  `git ls-remote --tags` and diff upstream changes with `git diff <tag> <tag>` —
  no full clone or manual `.next/` staging needed. Convention documented in
  `minion-version.md` (Release Tagging) and `docs/downstream-upgrade-playbook.md`
  (Detecting Upstream Drift).
- **feat (#5): `tools/upgrade-classify.sh`.** Given OLD + NEW export-ready snapshots
  (and optional LIVE repo), prints each changed file's export-manifest class and its
  live-vs-snapshot divergence (identical / diverged / missing / error) — automating
  the discover + classify + verify-divergence front half of an upgrade. 15 TDD cases.
- **fix (#2): governance test location ambiguity.** `governance-consistency.test.sh`
  now accepts `--root` / `GOV_ROOT` and prints the resolved ROOT + scanned file set,
  so running a clone's copy by mistake can't silently produce a misleading PASS.
- **feat (#3): externalized governance scan list.** The scan file list moved to
  `tools/tests/governance-scan.allow` (downstreams extend it); falls back to the
  built-in default. Kept an allowlist, not a blind glob — descriptive docs
  (CHANGELOG, AI/decisions, the playbook) quote the retired norm and would
  false-positive.
- **docs (#4, #6): scale ceremony to the delta.** Playbook now marks
  `.minions-template.next/` staging optional for contained patches (shallow clone +
  `upgrade-classify.sh` or `git diff <tag> <tag>` suffices) and sanctions a
  one-line provenance entry for no-decision patches.
- **cross-vendor review:** dogfooded Codex `/second-opinion` on this branch caught,
  in the new `upgrade-classify.sh`, a misclassification (strategy grep'd from the
  whole row, not the cell), a `cmp`-error-as-`diverged` bug, leading-hyphen filename
  option-injection, a missing-option-value infinite loop (in all three arg parsers),
  and an O(files×rows) perf blowup (60-file classify: >60s → ~0.9s after parsing the
  manifest once). All fixed with regression tests before merge.
- Added:
  - `tools/upgrade-classify.sh`, `tools/tests/upgrade-classify.test.sh`
  - `tools/tests/governance-scan.allow`
- Updated:
  - `tools/tests/governance-consistency.test.sh` (`--root`/`GOV_ROOT` + banner + allowlist)
  - `docs/downstream-upgrade-playbook.md` (drift-detection, `.next/`-optional, classify-tool wiring, lighter provenance)
  - `minion-version.md` (Release Tagging section), `docs/export-manifest.md`, `CHANGELOG.md`, `AI/decisions.md`

## 2026-06-20 (v1.11.1 — Downstream-Feedback Hardening)

- Commit hash: pending (next commit)
- Hardening pass from downstream upgrade feedback (a downstream trading-bot project, via an SM
  review of a real `1.10.0 → 1.11.0` upgrade). No new capability — correctness,
  security, and doc precision only. Bumped template version to `1.11.1-1.0.0`.
- **fix (correctness): `governance-consistency.test.sh` could false-PASS.** The
  line-based grep missed the retired norm when wrapped across lines in prose. The
  detector now normalizes whitespace whole-file and keys on order-independent
  `spawn`+`automatic` / `auto-spawn` / `on its own initiative` patterns
  (sentence-bounded on `.?!`); the false-positive-prone `ask…explicit` branch was
  dropped (the canonical norm is already caught by `spawn…automatic`, and that branch
  mis-flagged legitimate text like "ask for explicit approval before merging"). It
  self-tests each detector signal in isolation against positive and negative samples
  so the detector itself is regression-tested.
- **fix (security, `delegate` mode): F2 — path-unsafe `--role`/`--topic`.**
  `tools/xtool-call.sh` now rejects a slug containing `..` or characters outside
  `[A-Za-z0-9._-]` before creating any branch/worktree, closing a path-traversal /
  unpredictable-placement gap.
- **fix (operational + data-safety, `delegate` mode): F4 — failed-delegate state.**
  A failed delegate now measures work against the *base commit* the worktree was
  created from (not the worktree's moving HEAD), so a delegate that **committed** its
  output before failing is never mistaken for "no work" and deleted. It self-cleans
  worktree+branch only when nothing was produced (freeing the topic for retry), keeps
  partial/committed work with an explicit recovery hint otherwise, and discloses
  residual state if cleanup itself fails rather than claiming success. Also rejects
  charset-safe-but-git-ref-invalid slugs (e.g. `.`, trailing `.lock`) via
  `git check-ref-format`, and makes the worktree-collision message actionable.
- **cross-vendor review:** this pass was itself reviewed by an independent Codex
  second opinion run through `tools/xtool-call.sh` (dogfooding `/second-opinion`). It
  caught a data-loss bug in the first-draft F4 fix (committed work) and remaining
  detector false +/− that a same-context review missed; both are folded in above.
- **docs:** noted copilot's undenied `url`/`web-fetch` read-only fetch channel in
  `docs/cross-tool-orchestration.md` (confidentiality consideration, opt-in deny);
  enumerated the `.superpowers/` `.gitignore` addition in the v1.11.0 entry; added a
  per-file divergence-measurement step and tightened the project-local norm-scan
  guidance (specific phrasing, not broad keywords) in the upgrade playbook, plus a
  `1.11.1` Version-Specific Required Changes entry.
- Updated:
  - `tools/tests/governance-consistency.test.sh`
  - `tools/xtool-call.sh`
  - `tools/tests/xtool-call.test.sh`, `tools/tests/fixtures/make-fake-provider.sh`
  - `docs/cross-tool-orchestration.md`
  - `docs/downstream-upgrade-playbook.md` (`1.11.1` entry + divergence step + scan-precision note)
  - `CHANGELOG.md`, `minion-version.md`, `AI/decisions.md`

## 2026-06-20 (Cross-Tool Orchestration — shipped)

- Commit hash: pending (next commit)
- Shipped the cross-tool orchestration feature: a provider-agnostic primitive that
  lets the active orchestrator invoke another installed AI CLI (Codex, Copilot)
  headlessly as an independent reviewer or a delegated worker.
- Added `tools/xtool-call.sh` — the first executable code in a previously
  markdown-only template. Supports two providers (`codex`, `copilot`), two postures
  (`review` read-only, `delegate` isolated-worktree), and three exit codes
  (`0` success, `2` usage/bad-arguments error, `3` provider-unavailable). Never merges; human gate always required.
- Added `.claude/commands/second-opinion.md` (`/second-opinion`) — read-only
  cross-vendor review; calls `xtool-call.sh review`; surfaces disagreements to the
  Operator without resolving them.
- Added `.claude/commands/delegate.md` (`/delegate`) — isolated-worktree cross-vendor
  implementation; calls `xtool-call.sh delegate`; merge is gated on Operator approval.
- Added a cross-vendor review stage to `/ship` Pipeline Mode
  (`docs/minion-prompt-modes.md`): after the CM read-only verdict, an independent
  review from a different vendor runs (read-only via `tools/xtool-call.sh`), and
  its verdict is folded into the closeout evidence chain before the Operator gate;
  a material unresolved disagreement is a hard-stop.
- Added `docs/cross-tool-orchestration.md` — the exported protocol doc covering the
  review/delegate/ship workflow, exit-code contract, and governance rules (operator
  reference).
- Added `tools/tests/` — TDD test suite (`xtool-call.test.sh`, fixtures) and
  governance-consistency test (`governance-consistency.test.sh`); dependency-free
  bash with PATH-shimmed fake providers.
- Governance change: retired the "do not spawn role agents automatically" norm in
  favor of **autonomous orchestration** bounded by three hard-stops: (1) never merge
  or push to `main` without Operator gate; (2) never take destructive or production
  actions; (3) never resolve genuine AI disagreement autonomously.
- Added:
  - `tools/xtool-call.sh`
  - `tools/tests/xtool-call.test.sh`
  - `tools/tests/governance-consistency.test.sh`
  - `tools/tests/fixtures/`
  - `.claude/commands/second-opinion.md`
  - `.claude/commands/delegate.md`
  - `docs/cross-tool-orchestration.md`
- Updated:
  - `docs/minion-prompt-modes.md` (cross-vendor review stage in `/ship`)
  - `.claude/commands/ship.md` (cross-vendor review integration)
  - `docs/export-manifest.md` (new rows; `AI/specs/`, `AI/plans/` do-not-export)
  - `AI/decisions.md` (governance decision entry)
  - `.gitignore` (`.claude/worktrees/` and `.superpowers/` exclusions)
  - `minion-version.md`
  - `docs/downstream-upgrade-playbook.md` (`1.11.0` Version-Specific Required
    Changes entry: governance norm = `REQUIRED` tool-neutral baseline,
    cross-tool feature = `REQUIRED`-if-using, manual-merge endorsed for legacy
    downstreams, tool-parity caveat; plus a governance-norm callout in the
    Minimum PM Upgrade Packet)
- Bumped template version to `1.11.0-1.0.0` in `minion-version.md`

## 2026-06-20 (Cross-Tool Orchestration — design spec)

- Commit hash: pending (next commit)
- Added a design spec (planning artifact, not yet implemented) for **federated
  minions / cross-tool orchestration**: a provider-agnostic primitive that lets
  the active orchestrator invoke another installed AI CLI (Codex, Copilot)
  headlessly as an **independent reviewer** or a **delegated worker**, capturing
  results into the controlled repo surfaces while the orchestrator keeps sole
  authority over what becomes truth and what reaches `main`.
  - Two postures supplied per call: **review** (read-only, no writes) and
    **delegate** (writes only inside an isolated git worktree; merge is gated).
  - Mechanism: markdown commands (`/second-opinion`, `/delegate`) plus a thin
    `tools/xtool-call.sh` wrapper — the first executable code in a previously
    markdown-only template (recorded as a deliberate decision).
  - Plans a `/ship` integration adding an independent cross-vendor review stage.
  - Includes a governance change: retire the "do not spawn role agents
    automatically" norm in favor of **autonomous orchestration** bounded by three
    hard-stops (merge/push to `main`, destructive/production actions, unresolved
    AI disagreement).
  - Spec is template-maintainer-local (`AI/specs/`, do-not-export). See
    `AI/specs/2026-06-20-cross-tool-orchestration-design.md`.
  - Added the matching implementation plan (9 TDD tasks; dependency-free bash
    test harness with PATH-shimmed fake providers) at
    `AI/plans/2026-06-20-cross-tool-orchestration.md` (also do-not-export).

## 2026-06-18 (Pipeline Mode + Two-Channel Communication)

- Commit hash: pending (next commit)
- Added pipeline mode (`/ship`): a PM-orchestrated execution track that chains
  the existing minions into an automated plan → implement → test → review run
  for a single bounded feature, adapting the four-stage specialist-pipeline
  pattern to the existing roles rather than cloning a parallel agent set.
  - `AM` plans (spec-only), `CM` implements (implement-only posture), a fresh
    `CM` tests (test-only, does not fix failures), `SM` reviews conditionally on
    security surface, a fresh read-only `CM` returns a SHIP / NEEDS WORK / BLOCK
    verdict. Posture constraints live in the spawn prompts, not the agent files.
  - Gates pause the run for the Operator on spec `OPEN QUESTION`s, test failure,
    and NEEDS WORK / BLOCK verdicts. The pipeline never merges or pushes.
- Introduced the **two-channel communication model** to reduce `minions/mail/`
  traffic: intermediate orchestrated-run results use a **direct-return channel**
  (held in the orchestrator's context), and the orchestrator consolidates one
  durable artifact at run end; `minions/mail/` remains the deliberate-track
  surface for formal gates and cross-session handoffs.
- Documented **Phase 2** (planned, not built): optional Sonnet-tier `coder` and
  `tester` launchers to swap model tiers for the mechanical stages without
  changing the architecture.
- Added downstream-upgrade guidance: a **Version-Specific Required Changes**
  section in `docs/downstream-upgrade-playbook.md` with a `1.10.0` entry that
  labels each item `REQUIRED` / `RECOMMENDED` / `OPTIONAL`, flags the comm-stack
  `MEMORY.md` merge and the non-manifest `.gitignore` edit as merge-blocking, and
  states the Claude-Code-only `/ship` tool-parity caveat. Wired it into the
  numbered workflow (new step 5) and the Minimum PM Upgrade Packet.
- Hardened the export manifest so criticality is a first-class, durable signal:
  - Added a `Criticality` column (`baseline` / `feature` / `reference` / `n/a`)
    and a "Criticality Meanings" legend to `docs/export-manifest.md`, classifying
    every tracked file. `Upgrade strategy` says how to bring a file across;
    `Criticality` says how much it matters that you do.
  - Added `.gitignore` to the manifest as `manual-merge` / `baseline` (it was
    previously untracked), closing the gap where future template `.gitignore`
    additions could silently fail to propagate downstream.
- Added:
  - `.claude/commands/ship.md`
- Updated:
  - `MEMORY.md` (Communication Model — two-channel model)
  - `docs/downstream-upgrade-playbook.md` (Version-Specific Required Changes)
  - `docs/export-manifest.md` (Criticality column, `.gitignore` row)
  - `docs/minion-prompt-modes.md` (Pipeline Mode section, `/ship` table row,
    Phase 2 intent)
  - `minions/roles/PM.md` (Pipeline Orchestration capability)
  - `.claude/agents/README.md` (pipeline track vs. deliberate track)
  - `.gitignore` (ignore ephemeral `.pipeline/` scratch space)
  - `minion-version.md`
- Bumped template version to `1.10.0-1.0.0` in `minion-version.md`

## 2026-06-12 (Pairings as Onboarding/Upgrade Step)

- Commit hash: pending (next commit)
- Made wiring this project's minion↔plugin pairings an explicit onboarding and
  upgrade step, turning `docs/minion-plugin-pairings.md` from a passive reference
  into part of the standard flow:
  - onboarding: a checklist line in `docs/operator-onboarding-checklist.md`, a
    numbered step in `docs/downstream-onboarding-playbook.md`, and a step in the
    `INIT.md` startup sequence — review the pairings doc and add "use-when" lines
    (plus any scoped restricted-role whitelist entries) for the integrations the
    project actually uses; skip pairings whose plugin is absent.
  - upgrade: a step in `docs/downstream-upgrade-playbook.md` — re-review the
    refreshed recommendation map and confirm the project's wired pairings (local
    role-charter customizations) survive the role-file merge; add/remove charter
    lines as the project's stack changes.
- Updated:
  - `INIT.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `minion-version.md`
- Bumped template version to `1.9.1-1.0.0` in `minion-version.md`

## 2026-06-12 (Minion-Plugin Pairings)

- Commit hash: pending (next commit)
- Added `docs/minion-plugin-pairings.md` — recommended, **conditional** pairings
  between the minion roles and external integrations (plugins / MCP connectors /
  skills). Use a pairing if the integration is present; fall back to native repo
  surfaces/tools otherwise. No specific vendor is hard-wired into any agent's
  tools allowlist — the portable value is the mapping (which kind of integration
  serves which role), not the vendor.
- Added tool-agnostic "use-if-available" lines to the `PM` charter (issue-tracker
  / planning integrations, as coordination — not product code) and the `RM`
  charter (a web-research integration such as Nimble alongside `deep-research`,
  recommend-only still applies). Operator-confirmed lanes: PM ↔ issue tracker,
  RM ↔ Nimble.
- Documented the activation rule: unrestricted minions inherit session
  skills/connectors and only need the charter "use-when" nudge; the restricted
  `RM` additionally needs a scoped whitelist entry (`Skill(<plugin>:<skill>)` /
  `mcp__<plugin>_<server>__*`) to reach a pairing — kept as a documented opt-in,
  not hard-wired, so it degrades gracefully downstream.
- Added:
  - `docs/minion-plugin-pairings.md`
- Updated:
  - `minions/roles/PM.md`
  - `minions/roles/RM.md`
  - `README.md`
  - `docs/export-manifest.md`
  - `AI/decisions.md`
  - `minion-version.md`
- Bumped template version to `1.9.0-1.0.0` in `minion-version.md`

## 2026-06-12 (RM deep-research Skill)

- Commit hash: pending (next commit)
- Added `Skill(deep-research)` to the Claude RM subagent's `tools:` whitelist
  (`.claude/agents/rm.md`), giving the research minion a fan-out/source-verified/
  cited-synthesis engine. A `tools:` allowlist excludes the Skill tool and MCP
  tools unless listed, so RM — the research role — had ironically been the only
  minion locked out of skills/connectors.
- Scoped via `Skill(deep-research)`, not blanket `Skill`, to preserve RM's
  mechanical code-prohibition: a research skill adds an investigation engine
  without letting RM invoke file-writing/executing skills (docx, commit, etc.).
  The six unrestricted minions already inherit all session skills + connectors by
  default and need no change.
- Connectors (MCP) left off RM for now — it already has native WebSearch/WebFetch,
  and no research-relevant MCP server is configured; it's a one-line `mcp__<server>`
  add when one exists.
- Updated:
  - `.claude/agents/rm.md`
  - `.claude/agents/README.md`
  - `AI/decisions.md`
  - `minion-version.md`
- Bumped template version to `1.8.3-1.0.0` in `minion-version.md`

## 2026-06-12 (CM Effort Bump)

- Commit hash: pending (next commit)
- Pinned the Claude CM subagent to `effort: xhigh` in `.claude/agents/cm.md` so it
  reasons at the coding/agentic sweet-spot depth whenever spawned — the persistent
  equivalent of "ultrathink," which is only a per-turn prompt keyword and cannot be
  pinned to a subagent. Chose `xhigh` over `max` (max overthinks for diminishing
  returns and may not persist reliably). The same `effort:` frontmatter lever is
  available for other Claude roles.
- Documented the effort-tuning lever in `.claude/agents/README.md` and recorded the
  decision with rationale in `AI/decisions.md`.
- Updated:
  - `.claude/agents/cm.md`
  - `.claude/agents/README.md`
  - `AI/decisions.md`
  - `minion-version.md`
- Bumped template version to `1.8.2-1.0.0` in `minion-version.md`

## 2026-06-12 (Copilot Bootstrap Feedback Sync)

- Commit hash: pending (next commit)
- Added `feedback.md` to the Copilot bootstrap order so Copilot now reads the
  shared Operator-feedback capture log at session start, matching the Codex and
  Claude entry points.
- Updated:
  - `.github/copilot-instructions.md`
  - `AI/decisions.md`
  - `minion-version.md`
- Bumped template version to `1.8.1-1.0.0` in `minion-version.md`

## 2026-06-12 (Feedback Capture + Advisor Posture Sharpening)

- Commit hash: pending (next commit)
- Added `feedback.md`, a downstream-owned capture log of Operator corrections,
  preferences, and working-style learnings, read at session start. It de-silos
  per-tool memory (Claude's private memory is unreadable by Codex/Copilot) into
  one shared, git-durable, tool-neutral surface.
- `feedback.md` is a capture log, not a source of truth: a promotion path moves
  durable items into the curated surfaces (`MEMORY.md`, role charters, or
  `AI/decisions.md`), so it never competes with `MEMORY.md`. Established as the
  Feedback Capture Rule in `MEMORY.md`. Added the `/feedback` prompt mode for the
  end-of-session extraction practice.
- Wired `feedback.md` into the `CLAUDE.md`/`AGENTS.md` session-start bootstrap and
  the `AI.md` source-of-truth note (flagged as a capture log subordinate to
  `MEMORY.md`). It is exported and present everywhere, so the bootstrap reference
  does not dangle (contrast `AI/`, which is do-not-export and pull-not-push).
- Sharpened the advisor posture in `MEMORY.md` from two internet-post ideas,
  adapted rather than adopted as law: kept "challenge when the framing has a real
  gap" over the rigid "always challenge first" (which produces contrarian
  theater), and added a self-edit line for filler openers and an
  "advisor-not-assistant" framing.
- Recorded both decisions, with rationale, in `AI/decisions.md`.
- Added:
  - `feedback.md`
- Updated:
  - `MEMORY.md`
  - `AI.md`
  - `CLAUDE.md`
  - `AGENTS.md`
  - `README.md`
  - `INIT.md`
  - `AI/decisions.md`
  - `docs/minion-prompt-modes.md`
  - `docs/export-manifest.md`
  - `docs/operator-onboarding-checklist.md`
  - `minion-version.md`
- Bumped template version to `1.8.0-1.0.0` in `minion-version.md`

## 2026-06-12 (Cross-AI Template-Maintenance Layer)

- Commit hash: pending (next commit)
- Added `AI/`, a template-maintainer-local layer where the AIs that maintain
  this template (Claude, Codex, Copilot) record cross-AI consensus and open
  questions about evolving the minion system itself. This is meta-work, distinct
  from `minions/` (downstream project coordination).
- `AI/` is `do-not-export`: like `.mm.md`, it is excluded from downstream
  onboarding and upgrades — projects built from this template do not receive it.
  `AI.md` (the cross-tool protocol) is still exported; `AI/` (our maintenance
  records) is not. `AI/` is pull-not-push and is intentionally NOT wired into the
  per-session bootstrap, to avoid dangling references in exported entry points.
- Established the boundary rule in `MEMORY.md`: template-maintenance coordination
  goes in `AI/` (never `minions/`); project coordination goes in `minions/`
  (never `AI/`).
- Seeded `AI/decisions.md` with the decisions made over this session (projection
  model as source of truth, no-whitelists-except-RM, per-tool model/effort knobs,
  RM-as-consult-not-gate, MM-as-skill-not-subagent, Fable-as-escalation-only,
  entry-point bootstrap) so other tools inherit the reasoning instead of
  relitigating it.
- Added:
  - `AI/README.md`
  - `AI/decisions.md`
  - `AI/open-questions.md`
- Updated:
  - `MEMORY.md`
  - `docs/export-manifest.md`
  - `docs/downstream-onboarding-playbook.md`
  - `minion-version.md`
- Bumped template version to `1.7.0-1.0.0` in `minion-version.md`

## 2026-06-12 (Copilot RM Onboarding)

- Commit hash: pending (next commit)
- Added RM to the Copilot custom-agent surface for parity with Codex and Claude.
- Added:
  - `.github/agents/rm.agent.md`
- Updated:
  - `.github/agents/README.md`
  - `.github/agents/copilot-role-prompts.md`
  - `minion-version.md`
- Bumped template version to `1.6.1-1.0.0` in `minion-version.md`

## 2026-06-12 (Research Manager Minion)

- Commit hash: pending (next commit)
- Added `RM` (Research Manager) as a first-class template role: in-depth research
  and investigation of build issues, vendor-documentation-grounded option
  analysis, and out-of-box next-step recommendations. RM is research-and-recommend
  only — it MAY NOT create or execute code, deploy, or change runtime; it is a
  consult role, not a gate.
- RM is the one sanctioned exception to the no-tool-restrictions rule: the Claude
  projection pins it to a read-only + web whitelist
  (`Read, Grep, Glob, WebSearch, WebFetch`) so code creation/execution is
  mechanically impossible. Safe here because RM never needs write/execute tools.
  Codex has no tool-restriction field, so RM's prohibition is carried in its
  `developer_instructions` prose.
- Added:
  - `minions/roles/RM.md` (charter — source of truth)
  - `.claude/agents/rm.md` (Claude Code subagent, opus)
  - `.codex/agents/rm.toml` (Codex custom agent, `high` reasoning)
- Added the `/research` prompt mode (RM-owned) and RM role mapping in
  `docs/minion-prompt-modes.md`.
- Wired RM into the role set across `MEMORY.md`, `INIT.md`, `README.md`, `AI.md`,
  `CLAUDE.md`, `AGENTS.md`, both agent READMEs, the export manifest, the operator
  onboarding checklist, and the collaboration playbook. Added `RM` to the
  `NEXT OWNER` enums. RM was initially scoped to the Codex and Claude surfaces;
  the Copilot surface (`.github/agents/`) was onboarded separately afterward —
  see the Copilot RM Onboarding entry above.
- Updated:
  - `MEMORY.md`
  - `INIT.md`
  - `README.md`
  - `AI.md`
  - `CLAUDE.md`
  - `AGENTS.md`
  - `.claude/agents/README.md`
  - `.codex/agents/README.md`
  - `docs/export-manifest.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/minion-prompt-modes.md`
  - `docs/collaboration-playbook.md`
  - `minion-version.md`
- Bumped template version to `1.6.0-1.0.0` in `minion-version.md`

## 2026-06-10 (Codex Agent Effort)

- Commit hash: pending (next commit)
- Set Codex minion agent reasoning effort by role while continuing to inherit
  the active session model.
- Changed `pm` from `high` to `medium` reasoning for general planning,
  routing, and gate work.
- Documented the Codex model/effort policy:
  - general project chat/router should usually use `GPT-5.5` with `medium`
    reasoning
  - `am`, `cm`, `sm`, and `om` stay `high`
  - `dm` stays `medium`
  - role TOML files should pin `model` only when a downstream project needs a
    hard cost/performance lane
- Updated:
  - `.codex/agents/README.md`
  - `.codex/agents/pm.toml`
  - `minion-version.md`
- Bumped template version to `1.5.1-1.0.0` in `minion-version.md`

## 2026-06-09 (Claude Code Subagents)

- Commit hash: pending (next commit)
- Added repo-scoped Claude Code subagents for minion roles, mirroring the Codex
  custom agents so Claude Code can spawn role-specific subagents backed by the
  same durable charters in `minions/roles/`.
- Subagents are thin launchers with a "read these first" preamble; durable role
  policy stays in `minions/roles/`. By Operator decision, no per-role `tools:`
  restrictions are applied — full tool access for every role; lane discipline
  stays in the charter prose. Models mirror Codex reasoning tiers (high → opus,
  DM's medium → sonnet).
- Added Operator usage guidance for focused role discussion, single-agent
  investigation, and multi-agent parallel review.
- Added `AI.md` as a cross-tool collaboration protocol for Codex, Claude, and
  other AI assistants.
- Added `CLAUDE.md` and `AGENTS.md` as auto-loaded main-thread entry points so
  Claude Code and Codex bootstrap from `AI.md`/`MEMORY.md` on session start
  instead of relying on the Operator to paste the handoff prompt. Both are thin
  pointers; Codex verified the `AGENTS.md` convention against the current Codex
  manual and now owns that surface.
- Clarified that the `AI.md` tool-selection guidance is a heuristic, not a hard
  ownership rule between Codex and Claude.
- Ignored `.remember/` and PID files so local AI-tool runtime state is not
  accidentally committed.
- Added:
  - `AI.md`
  - `CLAUDE.md`
  - `AGENTS.md`
  - `.claude/agents/README.md`
  - `.claude/agents/pm.md`
  - `.claude/agents/am.md`
  - `.claude/agents/cm.md`
  - `.claude/agents/sm.md`
  - `.claude/agents/dm.md`
  - `.claude/agents/om.md`
- Updated downstream onboarding, upgrade, export, and collaboration guidance so
  `.claude/agents/` is treated as a template-managed Claude Code subagent surface
  alongside `.codex/agents/`.
- Updated:
  - `INIT.md`
  - `MEMORY.md`
  - `README.md`
  - `.gitignore`
  - `docs/collaboration-playbook.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `docs/operator-onboarding-checklist.md`
  - `minion-version.md`
- Bumped template version to `1.5.0-1.0.0` in `minion-version.md`

## 2026-06-09

- Commit hash: pending (next commit)
- Added repo-scoped Codex custom agents for minion roles so Codex can spawn
  role-specific subagents backed by the existing durable charters.
- Added practical Operator usage guidance for focused role discussion,
  single-agent investigation, and multi-agent parallel review.
- Added:
  - `.codex/agents/README.md`
  - `.codex/agents/pm.toml`
  - `.codex/agents/am.toml`
  - `.codex/agents/cm.toml`
  - `.codex/agents/sm.toml`
  - `.codex/agents/dm.toml`
  - `.codex/agents/om.toml`
- Updated downstream onboarding, upgrade, export, and collaboration guidance so
  `.codex/agents/` is treated as a template-managed Codex custom-agent surface.
- Updated:
  - `INIT.md`
  - `MEMORY.md`
  - `README.md`
  - `docs/collaboration-playbook.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `docs/operator-onboarding-checklist.md`
  - `minion-version.md`
- Bumped template version to `1.4.5-1.0.0` in `minion-version.md`

## 2026-06-08 (DM Baseline)

- Commit hash: pending (next commit)
- Added `DM` (Documentation Manager) as a first-class template role for
  documentation truth, reader paths, runbooks, and documentation-sync
  validation.
- Added:
  - `minions/roles/DM.md`
- Updated shared workflow and role guidance so:
  - documentation-only work has a PM -> DM -> PM -> Operator flow
  - implementation/runtime flows route through DM before PM acceptance when
    documented behavior or operator workflow changes
  - `NEXT OWNER` contracts include `DM`
  - prompt modes include `/docs` and `/runbook`
- Updated:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/collaboration-playbook.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `docs/minion-prompt-modes.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/project/mailbox-collaboration-model.md`
  - `minions/README.md`
  - `minions/mail/README.md`
  - `minions/plans/milestone-plan-template.md`
  - `minions/roles/PM.md`
  - `minions/roles/AM.md`
  - `minions/roles/CM.md`
  - `minions/roles/SM.md`
  - `minions/roles/OM.md`
  - `minion-version.md`
- Bumped template version to `1.4.4-1.0.0` in `minion-version.md`

## 2026-06-08

- Commit hash: pending (next commit)
- Added template-level minion prompt modes adapted from operator-provided
  prompt screenshots so minions can use named advisor postures without breaking
  role boundaries.
- Added:
  - `docs/minion-prompt-modes.md`
- Updated shared and role-specific guidance so:
  - minions lead with missing assumptions, risk, or clarification instead of
    empty agreement when the framing is weak
  - consequential claims use `[Certain]`, `[Likely]`, or `[Guessing]`
    confidence tags
  - filler openers are explicitly discouraged
  - `/startup-team`, `/codebase-audit`, `/debug`, `/performance`,
    `/refactor`, `/backend`, `/frontend`, `/tech-lead`, `/security`, and
    `/devops` map to the proper PM/AM/CM/SM/OM owners
- Updated:
  - `MEMORY.md`
  - `INIT.md`
  - `README.md`
  - `docs/collaboration-playbook.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/export-manifest.md`
  - `minions/README.md`
  - `minions/roles/PM.md`
  - `minions/roles/AM.md`
  - `minions/roles/CM.md`
  - `minions/roles/SM.md`
  - `minions/roles/OM.md`
  - `minion-version.md`
- Bumped template version to `1.4.3-1.0.0` in `minion-version.md`

## 2026-04-21 (Later Entry)

- Commit hash: pending (next commit)
- Added shared execution-quality rules so all minions:
  - start non-trivial work from a durable plan, packet, or checklist
  - re-plan when new evidence invalidates the active plan
  - verify behavior before declaring work complete
  - prefer simple, low-impact root-cause fixes over broader or temporary patches
  - label containment clearly and assign follow-up ownership for the final fix
- Updated:
  - `MEMORY.md`
- Bumped template version to `1.4.2-1.0.0` in `minion-version.md`

## 2026-04-21

- Commit hash: pending (next commit)
- Strengthened role-specific execution quality guidance so:
  - `PM` plans non-trivial work in durable checkpoints and re-plans when evidence breaks the active plan
  - `AM` prefers the simplest architecture that fits the project and steps back from structurally hacky solutions
  - `CM` favors minimal root-cause fixes and explicitly distinguishes containment from a final fix
  - `SM` validates reachable risk and favors targeted hardening that closes the real risk surface
  - `OM` establishes runtime truth with operational evidence and prefers the smallest safe restoring action
- Updated:
  - `minions/roles/PM.md`
  - `minions/roles/AM.md`
  - `minions/roles/CM.md`
  - `minions/roles/SM.md`
  - `minions/roles/OM.md`
- Bumped template version to `1.4.1-1.0.0` in `minion-version.md`

## 2026-04-14

- Commit hash: pending (next commit)
- Added a mailbox-first coordination model so actionable minion communication
  moves into packet directories while `minions/chat/` becomes a PM-owned
  summary surface in:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/collaboration-playbook.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `docs/operator-onboarding-checklist.md`
  - `minions/README.md`
  - `minions/chat/README.md`
  - `minions/chat/general-thread-template.md`
  - `minions/chat/topic-thread-template.md`
  - `minions/plans/milestone-plan-template.md`
- Added template-managed mailbox assets in:
  - `docs/project/mailbox-collaboration-model.md`
  - `minions/mail/README.md`
  - `minions/mail/packet-template.md`
- Added ASCII mailbox flow diagrams to make packet ownership and PM summary
  duties easier to onboard in:
  - `docs/project/mailbox-collaboration-model.md`
  - `minions/mail/README.md`
- Corrected mailbox-model drift so shared rules and role charters point minions
  to owned mail packets while `PM` owns same-day chat summaries, and simplified
  the request template to the single-owner packet shape in:
  - `MEMORY.md`
  - `minions/roles/CM.md`
  - `minions/roles/AM.md`
  - `minions/mail/packet-template.md`
- Clarified staged rollout and downstream export behavior so legacy chat packets
  may finish in place, new follow-up packets move to mail, and template packet
  history is not exported into downstream repos
- Bumped template version to `1.4.0-1.0.0` in `minion-version.md`

## 2026-04-12

- Commit hash: pending (next commit)
- Corrected the downstream onboarding/export model so `.minions-template/` is an export-ready snapshot rather than a raw repo copy in:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/collaboration-playbook.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `minion-version.md`
- Clarified that downstream snapshots must exclude Git metadata and `do-not-export` files such as `.mm.md`
- Removed `REQUIREMENTS.md` from the shared required-documentation contract and aligned the baseline around `README.md`, `ROADMAP.md`, and `TODO.md` in:
  - `MEMORY.md`
  - `.mm.md`
- Reordered the initial onboarding sequence so controlled export happens before downstream checklist completion in:
  - `README.md`
  - `INIT.md`
- Bumped template version to `1.3.1-1.0.0` in `minion-version.md`

## 2026-04-11

- Commit hash: pending (next commit)
- Added `AM` (Architect Minion) as a first-class template role for architecture stewardship, system design review, and structural refinement in:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/collaboration-playbook.md`
  - `minions/roles/PM.md`
  - `minions/roles/AM.md`
  - `minions/roles/CM.md`
  - `minions/roles/SM.md`
  - `minions/roles/OM.md`
  - `minions/chat/README.md`
  - `minions/chat/general-thread-template.md`
  - `minions/chat/topic-thread-template.md`
- Strengthened shared git handoff discipline so every minion must commit before workflow handoff, cross-computer handoffs require commit-and-push, and the Operator records per-role handoff mode in:
  - `INIT.md`
  - `MEMORY.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/collaboration-playbook.md`
- Added a vendored downstream-upgrade model with a PM-owned merge playbook and export manifest in:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/collaboration-playbook.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `minion-version.md`
  - `minions/roles/PM.md`
- Added a separate downstream onboarding model so first-time adoption is treated as a controlled export from `.minions-template/`, not a blind repo copy, in:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/collaboration-playbook.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `minion-version.md`
- Reconciled shared role-set drift so `SM` remains consistently present in handoff and `NEXT OWNER` contracts while adding `AM`
- Bumped template version to `1.3.0-1.0.0` in `minion-version.md`

## 2026-04-10 (MM Bootstrap)

- Commit hash: pending (next commit)
- Bootstrapped Manager Minion coordination for the current template-maintenance session by:
  - creating `minions/chat/2026-04-10.md` with the MM bootstrap announcement
  - refreshing `.mm.md` `MM Notes` with a timestamped audit of the active template drift backlog
- No template version bump; MM-context and coordination-doc updates only

## 2026-04-10

- Commit hash: pending (next commit)
- Removed `.mm.md` from `.gitignore` so Manager Minion context can sync across Operator machines
- Added and tracked `.mm.md` as a repository maintainer context file for the template repo
- Added Manager Minion scoping, maintainer guardrails, and Operator continuity-support guidance in:
  - `.mm.md`

## 2026-04-08 (Initial Entry)

- Commit hash: pending (next commit)
- Updated shared runtime handoff order to include `SM` between `CM` and `OM-Test` / `OM` in:
  - `MEMORY.md`
- Updated handoff interpretation to define `SM` security posture check before runtime gate in:
  - `MEMORY.md`
- Updated completion contract `NEXT OWNER` allowed values to include `SM` in:
  - `MEMORY.md`
- Bumped template version to `1.2.5-1.0.0` in `minion-version.md`

## 2026-04-08 (Earlier Entry)

- Commit hash: pending (next commit)
- Added a standardized "Completion Handoff Contract" with exact required order and hard rules in:
  - `MEMORY.md`
  - `INIT.md`
  - `minions/chat/README.md`
- Strengthened PM guardrails to explicitly reject handoffs without evidence and clear `NEXT OWNER` assignment in:
  - `minions/roles/PM.md`
- Bumped template version to `1.2.4-1.0.0` in `minion-version.md`

## 2026-04-08

- Commit hash: pending (next commit)
- Added mandatory completion-update requirements so minions always identify next owner and explicit Operator action needed:
  - updated `MEMORY.md`
  - updated `INIT.md`
  - updated role guardrails in `minions/roles/CM.md`, `minions/roles/PM.md`, `minions/roles/OM.md`, and `minions/roles/SM.md`
- Bumped template version to `1.2.3-1.0.0` in `minion-version.md`
- Initialized repository `CHANGELOG.md` as required by template guardrails
