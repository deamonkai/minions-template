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

- Phase 2 (Sonnet-tier `coder` / `tester` stage launchers) is documented in
  `docs/minion-prompt-modes.md` but not built. No upgrade action required.

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
9. Manually merge files such as `MEMORY.md`, `INIT.md`,
   `docs/operator-onboarding-checklist.md`, and `minion-version.md`. Confirm
   every `REQUIRED` item from step 5 landed — especially comm-stack changes in
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
  `MEMORY.md` and `AI.md` diverge intentionally; merge only with explicit
  review, per steps 9 and 11.

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

Since template version 1.25.0, the seven role charters (`minions/roles/*.md`)
and `MEMORY.md` carry a split-merge delimiter. The exact marker line
(referenced below simply as "the marker") is:

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
