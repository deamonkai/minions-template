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
   reproducible command rather than manual cross-referencing.
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

### `MEMORY.md`

- preserve project-specific facts, constraints, environments, and operating
  history
- merge new template guardrails, role definitions, and workflow rules
- if the file is later split into template-managed and project-managed sections,
  restrict template upgrades to the template-managed sections

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
