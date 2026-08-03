# Export Manifest

This manifest defines how files from the template should be treated in
downstream repositories.

Use this manifest with:

- `docs/downstream-onboarding-playbook.md` for first export into a downstream repo
- `docs/downstream-upgrade-playbook.md` for later template migrations

## Initial Export Meanings

The `Initial export` column says whether a file goes into an export tree at
all — the downstream-onboarding export and the public-mirror export both read
it. `Upgrade strategy` then says what happens to it on *later* upgrades.

- `yes`: copy into the export tree as-is.
- `no`: never copied.
- `seed only`: copy the file, then strip it to its content-free seed — the
  structure, conventions, and rules a downstream needs, with none of this
  repo's content. The seed ships; the content does not. Public-export Step 2
  item 4 performs the strip, and the class is enumerated mechanically with
  `grep 'seed only' docs/export-manifest.md` rather than from memory. A
  `seed only` file must carry a `STUB BOUNDARY` marker (see the
  "seed-only `STUB BOUNDARY` marker" subsection under Manual-Merge Guidance
  in `docs/downstream-upgrade-playbook.md` for the exact line — NOT the
  split-merge delimiter section, which documents the different
  `DOWNSTREAM CONTENT BELOW` marker and carries no `STUB BOUNDARY` text) so
  `tools/export-seed-check.sh` can verify the strip ran.
  If the file also carries an ABOVE-marker field with repo-specific content
  (like `docs/MECHANICS.md`'s `verified @ <sha>` / `Mapped areas: <paths>`),
  add a row for it to that script's `SEED_ANCHORS` table in the same commit
  — the table is hand-maintained and unenforced by any other guard, so a new
  above-marker field with no `SEED_ANCHORS` row publishes silently.
- `bootstrap reference only`: copy as a starting point that the downstream is
  expected to replace wholesale (today: `README.md`).

The distinction that matters: `bootstrap reference only` ships something that
*describes this repo* and invites replacement; `seed only` ships a *shape* that
never described this repo in the first place. A file whose value to a
downstream is its structure rather than its text belongs in `seed only`.

## Strategy Meanings

- `template-replace`: usually replace from the new template version, then
  consciously reapply any intentional downstream divergence
- `manual-merge`: always review and merge with downstream state
- `downstream-owned`: do not overwrite during template upgrades
- `do-not-export`: keep out of downstream live files and out of the vendored
  `.minions-template/` snapshot unless the Operator explicitly chooses
  otherwise

**Row precedence:** a more-specific per-file `do-not-export` row overrides a
broader exportable/`template-replace` glob (e.g. a private SME excluded from the
`minions/smes/*.md` glob). There is no automated export filter — exclusion is
operator-applied at public-export Step 1 — so apply the specific row
deliberately; the glob does not exclude it for you.

## Criticality Meanings

`Upgrade strategy` says *how* to bring a file across; `Criticality` says *how
much it matters that you do*. This is the stable, file-level signal; the
**Version-Specific Required Changes** section of
`docs/downstream-upgrade-playbook.md` is where a given version says which
`baseline`/`feature` files become hard `REQUIRED` items for that jump.

- `baseline`: shared truth, guardrails, roles, and the coordination model every
  tool and role depends on. Dropping or skipping a `baseline` merge breaks
  cross-role coherence — treat these as merge-blocking. Several are
  `manual-merge` (e.g. `MEMORY.md`, `.gitignore`), so a `template-replace` pass
  will not bring them across on its own. Delimiter-bearing files (the role
  charters, `MEMORY.md`) use split-merge per the playbook's Manual-Merge
  Guidance — take the template above the marker, preserve downstream content
  below it — making their manual merge mechanical.
- `feature`: adopt only if the project uses that capability (a specific AI tool's
  agent launchers, the `/ship` pipeline, plugin pairings). Required *if* the
  capability is in use; safely skipped otherwise.
- `reference`: procedural, onboarding, and scaffolding docs. Useful to keep
  current but safe to adopt lazily; lagging one does not break the operating
  model.
- `n/a`: `do-not-export` and `downstream-owned` files — not adopted from the
  template, so file-level criticality does not apply. Note:
  `minions/capabilities.md` is a `template-replace` split-merge file rated
  `baseline` — its template-shipped **Default Capabilities** block above the
  delimiter ships and upgrades, while the **Local Inventory** below stays
  downstream-owned (the same two-tier pattern as `minions/smes/README.md`).

> **Note:** Class-A files (`MEMORY.md`, `AI.md`, `CLAUDE.md`, `AGENTS.md`,
> `.github/copilot-instructions.md`, `minions/roles/*`, `ROADMAP.md`,
> `TODO.md`, `minions/chat/`, `minions/ARCHIVED.md`) are
> mainline-authoritative per the branching model
> (`docs/branching-and-release-model.md` §Coordination Plane).

## Vendored Snapshot Rule

`.minions-template/` is an export-ready snapshot, not a full clone of the
template repo.

- exclude `.git/`
- exclude all `do-not-export` files
- keep only the files needed to onboard and later upgrade downstream minion
  workflow

## Manifest

| Path | Initial export | Upgrade strategy | Criticality | Default owner | Notes |
| --- | --- | --- | --- | --- | --- |
| `.mm.md` | no | `do-not-export` | `n/a` | MM / Operator | local template-maintainer context only |
| `AI/README.md` | no | `do-not-export` | `n/a` | MM / Operator | template-maintenance layer guide; not for downstream projects |
| `AI/decisions.md` | no | `do-not-export` | `n/a` | MM / Operator | cross-AI template-maintenance decision register; template-maintainer-local |
| `AI/open-questions.md` | no | `do-not-export` | `n/a` | MM / Operator | cross-AI template-maintenance open questions; template-maintainer-local |
| `AI/feedback/` | no | `do-not-export` | `n/a` | MM / Operator | vendored field-feedback packets + evidence triage; template-maintainer-local |
| `.gitignore` | yes | `manual-merge` | `baseline` | PM / Operator | not auto-managed and outside most merge tooling; merge new template ignore patterns (e.g. `.pipeline/`) while preserving downstream-specific entries. Confirm during every upgrade |
| `AI.md` | yes | `manual-merge` | `baseline` | PM / Operator | cross-tool coordination notes for AI assistants; split-merge per delimiter since 1.46.0 (see playbook) — follows `MEMORY.md`'s prose shape (template content above the marker, downstream-additive notes below under `## Template/Downstream Split`), not a registry table. Never edit above-the-line content downstream; contradictions get promoted upstream or filed as feedback — the pre-delimiter "preserve downstream-specific handoff guidance" (in-place edits) is superseded by this |
| `CLAUDE.md` | yes | `manual-merge` | `feature` | PM / Operator | Claude Code auto-loaded entry point; thin pointer to `AI.md`/`MEMORY.md`. Preserve downstream project-specific guidance |
| `AGENTS.md` | yes | `manual-merge` | `feature` | PM / Operator | Codex auto-loaded entry point; thin pointer to `AI.md`/`MEMORY.md`. Preserve downstream project-specific guidance |
| `.github/copilot-instructions.md` | yes | `manual-merge` | `feature` | PM / Operator | Copilot auto-loaded entry point; thin pointer to `AI.md`/`MEMORY.md`. Preserve downstream project-specific guidance |
| `.github/agents/README.md` | yes | `template-replace` | `feature` | PM | Copilot custom agent usage guidance |
| `.github/agents/copilot-role-prompts.md` | yes | `template-replace` | `feature` | PM | Copilot operator prompt patterns by role and workflow |
| `.github/agents/pm.agent.md` | yes | `template-replace` | `feature` | PM | Copilot custom agent launcher for `minions/roles/PM.md` |
| `.github/agents/am.agent.md` | yes | `template-replace` | `feature` | PM / AM | Copilot custom agent launcher for `minions/roles/AM.md` |
| `.github/agents/cm.agent.md` | yes | `template-replace` | `feature` | PM / CM | Copilot custom agent launcher for `minions/roles/CM.md` |
| `.github/agents/sm.agent.md` | yes | `template-replace` | `feature` | PM / SM | Copilot custom agent launcher for `minions/roles/SM.md` |
| `.github/agents/dm.agent.md` | yes | `template-replace` | `feature` | PM / DM | Copilot custom agent launcher for `minions/roles/DM.md` |
| `.github/agents/om.agent.md` | yes | `template-replace` | `feature` | PM / OM | Copilot custom agent launcher for `minions/roles/OM.md` |
| `.github/agents/rm.agent.md` | yes | `template-replace` | `feature` | PM / RM | Copilot custom agent launcher for `minions/roles/RM.md`; read-only tools (read, search, todo) |
| `.github/agents/coder.agent.md` | yes | `template-replace` | `feature` | PM / CM | Copilot pipeline stage launcher (Mid tier, advisory); implement-only; spawned manually (no `/ship` in this family) |
| `.github/agents/tester.agent.md` | yes | `template-replace` | `feature` | PM / CM | Copilot pipeline stage launcher (Mid tier, advisory); write-and-run-tests-only; spawned manually (no `/ship` in this family) |
| `.codex/agents/README.md` | yes | `template-replace` | `feature` | PM | Codex custom agent usage guidance |
| `.codex/agents/pm.toml` | yes | `template-replace` | `feature` | PM | Codex custom agent launcher for `minions/roles/PM.md` |
| `.codex/agents/am.toml` | yes | `template-replace` | `feature` | PM / AM | Codex custom agent launcher for `minions/roles/AM.md` |
| `.codex/agents/cm.toml` | yes | `template-replace` | `feature` | PM / CM | Codex custom agent launcher for `minions/roles/CM.md` |
| `.codex/agents/sm.toml` | yes | `template-replace` | `feature` | PM / SM | Codex custom agent launcher for `minions/roles/SM.md` |
| `.codex/agents/dm.toml` | yes | `template-replace` | `feature` | PM / DM | Codex custom agent launcher for `minions/roles/DM.md` |
| `.codex/agents/om.toml` | yes | `template-replace` | `feature` | PM / OM | Codex custom agent launcher for `minions/roles/OM.md` |
| `.codex/agents/rm.toml` | yes | `template-replace` | `feature` | PM / RM | Codex custom agent launcher for `minions/roles/RM.md` |
| `.codex/agents/coder.toml` | yes | `template-replace` | `feature` | PM / CM | Codex pipeline stage launcher (Mid tier, advisory); implement-only; spawned manually (no `/ship` in this family) |
| `.codex/agents/tester.toml` | yes | `template-replace` | `feature` | PM / CM | Codex pipeline stage launcher (Mid tier, advisory); write-and-run-tests-only; spawned manually (no `/ship` in this family) |
| `.claude/agents/README.md` | yes | `template-replace` | `feature` | PM | Claude Code subagent usage guidance |
| `.claude/agents/pm.md` | yes | `template-replace` | `feature` | PM | Claude Code subagent launcher for `minions/roles/PM.md` |
| `.claude/agents/am.md` | yes | `template-replace` | `feature` | PM / AM | Claude Code subagent launcher for `minions/roles/AM.md` |
| `.claude/agents/cm.md` | yes | `template-replace` | `feature` | PM / CM | Claude Code subagent launcher for `minions/roles/CM.md` |
| `.claude/agents/sm.md` | yes | `template-replace` | `feature` | PM / SM | Claude Code subagent launcher for `minions/roles/SM.md` |
| `.claude/agents/dm.md` | yes | `template-replace` | `feature` | PM / DM | Claude Code subagent launcher for `minions/roles/DM.md` |
| `.claude/agents/om.md` | yes | `template-replace` | `feature` | PM / OM | Claude Code subagent launcher for `minions/roles/OM.md` |
| `.claude/agents/rm.md` | yes | `template-replace` | `feature` | PM / RM | Claude Code subagent launcher for `minions/roles/RM.md`; read-only + web tool whitelist |
| `.claude/agents/coder.md` | yes | `template-replace` | `feature` | PM / CM | Claude Code pipeline stage-3 launcher (Mid/Sonnet tier); implement-only via the `/ship` spawn prompt; `/ship` falls back to `cm` when absent |
| `.claude/agents/tester.md` | yes | `template-replace` | `feature` | PM / CM | Claude Code pipeline stage-4 launcher (Mid/Sonnet tier); write-and-run-tests-only via the `/ship` spawn prompt; `/ship` falls back to `cm` when absent |
| `.claude/commands/ship.md` | yes | `template-replace` | `feature` | PM | `/ship` pipeline-mode orchestrator slash command; pairs with the `baseline` two-channel comm model in `MEMORY.md` |
| `README.md` | bootstrap reference only | `downstream-owned` | `n/a` | Operator / PM / DM | downstream repos should replace this with a project-specific README |
| `CHANGELOG.md` | yes | `downstream-owned` | `n/a` | PM / DM | keep downstream project history; do not overwrite with template history |
| `feedback.md` | seed only | `downstream-owned` | `n/a` | Operator / PM | ship the seed (purpose, capture-vs-curated rule, promotion path, format); downstream keeps its own Operator-feedback content — do not overwrite with template examples |
| `INIT.md` | yes | `manual-merge` | `baseline` | PM | preserve project-specific onboarding context while merging new baseline workflow rules |
| `MEMORY.md` | yes | `manual-merge` | `baseline` | PM | merge new template guardrails while preserving project-specific truth; carries the two-channel comm model; split-merge per delimiter (see playbook) |
| `minion-version.md` | yes | `manual-merge` | `baseline` | PM | update base-template version after upgrade; preserve downstream version suffix |
| `docs/collaboration-playbook.md` | yes | `template-replace` | `baseline` | PM | baseline workflow doc |
| `docs/minion-prompt-modes.md` | yes | `template-replace` | `baseline` | PM | baseline operator prompt-mode and advisor-posture guidance; carries Pipeline Mode |
| `docs/model-tiering.md` | yes | `template-replace` | `reference` | PM | advisory model-tier guidance (vendor-neutral bands) |
| `docs/effort-calibration.md` | yes | `template-replace` | `reference` | PM | PROTOTYPE effort-tier calibration (task-class → reasoning-effort); companion to model-tiering; idea from effortmining (MIT) |
| `docs/pm-judgment-model.md` | yes | `template-replace` | `feature` | PM | PM domain judgment — landscape routing map (goal-clarity × solution-clarity selects the stage chain) + the Hope/Effort creep check at consolidation; detail behind three `MEMORY.md` laws. `feature`, NOT `reference`: `tools/tests/governance-consistency.test.sh` asserts this file exists, so it cannot be lagged if you run the governance guard — the capability it is required by. Unlike `docs/model-tiering.md`, which sits outside the governance-scanned set and IS safely lazy (Upgrade-Path SME ruling, 1.47.0) |
| `docs/designing-an-sme.md` | yes | `template-replace` | `reference` | PM | SME design craft (consultable-expertise-vs-process test, disjoint-domain drawing, tier selection, evidence discipline); precedes the Adding-an-SME mechanics and `tools/sme-charter-check.sh` |
| `docs/minion-plugin-pairings.md` | yes | `template-replace` | `feature` | PM | recommended (conditional) minion-to-plugin/connector/skill pairings; adjust to the downstream stack |
| `docs/project/mailbox-collaboration-model.md` | yes | `template-replace` | `baseline` | PM | baseline mailbox-first coordination model |
| `docs/operator-onboarding-checklist.md` | yes | `manual-merge` | `reference` | PM | preserve completed downstream decisions |
| `docs/downstream-onboarding-playbook.md` | yes | `template-replace` | `reference` | PM | baseline initial onboarding procedure |
| `docs/downstream-upgrade-playbook.md` | yes | `template-replace` | `reference` | PM | baseline downstream-upgrade procedure; holds Version-Specific Required Changes |
| `docs/export-manifest.md` | yes | `template-replace` | `reference` | PM | baseline export/merge strategy; split-merge per delimiter since 1.46.0 (see playbook) — registry shape like `minions/capabilities.md`/`minions/smes/README.md`/`minions/review-matrix.md`: the template-shipped Manifest table above the marker ships and upgrades, the downstream-owned Downstream Additions table below it holds project-specific rows and resets at export. A downstream that mechanically `template-replace`s this file WITHOUT first moving its own hand-appended trailing rows into the Downstream Additions table loses that table outright — the exact hazard the delimiter exists to prevent, and self-referential: a botched merge of this file's own manifest row can feed wrong `seed only` / `export=yes` sets into `tools/export-seed-check.sh`, cascading failures onto unrelated paths |
| `minions/README.md` | yes | `template-replace` | `reference` | PM | directory structure guidance |
| `minions/roles/PM.md` | yes | `template-replace` | `baseline` | PM | review local role customizations before overwrite; split-merge per delimiter (see playbook) |
| `minions/roles/AM.md` | yes | `template-replace` | `baseline` | PM / AM | review local role customizations before overwrite; split-merge per delimiter (see playbook) |
| `minions/roles/CM.md` | yes | `template-replace` | `baseline` | PM / CM | review local role customizations before overwrite; split-merge per delimiter (see playbook) |
| `minions/roles/SM.md` | yes | `template-replace` | `baseline` | PM / SM | review local role customizations before overwrite; split-merge per delimiter (see playbook) |
| `minions/roles/DM.md` | yes | `template-replace` | `baseline` | PM / DM | review local role customizations before overwrite; split-merge per delimiter (see playbook) |
| `minions/roles/OM.md` | yes | `template-replace` | `baseline` | PM / OM | review local role customizations before overwrite; split-merge per delimiter (see playbook) |
| `minions/roles/RM.md` | yes | `template-replace` | `baseline` | PM / RM | review local role customizations before overwrite; split-merge per delimiter (see playbook) |
| `minions/plans/README.md` | yes | `template-replace` | `reference` | PM | baseline planning guidance |
| `minions/plans/milestone-plan-template.md` | yes | `template-replace` | `reference` | PM | baseline planning template |
| `minions/mail/README.md` | yes | `template-replace` | `reference` | PM | baseline mailbox workflow guidance |
| `minions/mail/packet-template.md` | yes | `template-replace` | `reference` | PM | baseline packet structure |
| `minions/chat/README.md` | yes | `template-replace` | `reference` | PM | baseline PM-summary workflow guidance |
| `minions/chat/general-thread-template.md` | yes | `template-replace` | `reference` | PM | baseline daily summary template |
| `minions/chat/topic-thread-template.md` | yes | `template-replace` | `reference` | PM | baseline topic summary template |
| `minions/mail/*/` live packet history | no | `downstream-owned` | `n/a` | PM / Operator | preserve downstream packet history; do not export template packet history |
| `minions/chat/*.md` daily/topic history | no | `downstream-owned` | `n/a` | PM / Operator | preserve downstream summary history; do not export template history |
| `minions/plans/*.md` live plan docs | no | `downstream-owned` | `n/a` | PM / DM | preserve project-specific plans and status |
| `minions/ARCHIVED.md` | no | `downstream-owned` | `n/a` | PM / Operator | coordination archive index; created on first `archive-reporter` prune; downstream-owned history (like `CHANGELOG.md`), Class A / not exported. The row exists so `manifest-completeness` stays green once the file is first appended — never add a row by hand |
| `ROADMAP.md` | seed only | `downstream-owned` | `n/a` | PM / DM | ship the seed (horizon headings + the entry conventions); downstream keeps its own approved direction — do not overwrite with template roadmap content |
| `TODO.md` | seed only | `downstream-owned` | `n/a` | PM / DM | ship the seed (section shape + status conventions); downstream keeps its own backlog — do not overwrite with template backlog items |
| `docs/MECHANICS.md` | seed only | `downstream-owned` | `n/a` | AM / DM | living code map (system-at-a-glance); ships the shape, downstream fills its own; on-demand detail in `docs/mechanics/` |
| `docs/DESIGN.md` | seed only | `downstream-owned` | `n/a` | CM / DM | design-standards scaffold the Design/UX Reviewer SME reviews UI changes against; ships the standards headings + placeholder shape, downstream fills its own real token/theme/component values — do not overwrite with template placeholder content |
| `tools/xtool-call.sh` | yes | `template-replace` | `feature` | PM / CM | cross-tool orchestration wrapper (Codex / Copilot, review / delegate postures); adopt if project uses cross-vendor review |
| `tools/upgrade-classify.sh` | yes | `template-replace` | `reference` | PM / CM | upgrade helper: classifies a template change-set (manifest class + live-vs-snapshot divergence) for downstream upgrades; see `docs/downstream-upgrade-playbook.md` |
| `tools/export-seed-check.sh` | yes | `template-replace` | `feature` | PM / OM | public-export pre-push gate (runbook Step 3, one invocation asserting four properties — the former gates 4 and 5 are collapsed into it): (1) Local Registry / Local Matrix / Local Inventory below the split-merge delimiter are header-only in the export tree — point `SEED_FILES` at the downstream's own delimited local sections, `WAIVER` at delimited files with no downstream content to reset; (2) every delimited exportable file is classified in `SEED_FILES` or `WAIVER`, so a new one can never silently go unenrolled; (3) no `seed only` file's `STUB BOUNDARY` marker survives in the export tree; (4) above-marker staleness anchors (the `SEED_ANCHORS` table, e.g. `docs/MECHANICS.md`'s `verified @ <sha>` / `Mapped areas: <paths>`) read back as their literal placeholders — a downstream with its own above-marker repo-specific fields adds rows to `SEED_ANCHORS`. `--completeness .` runs the source-repo-invariant half (delimiter classification + seed-only marker presence) continuously, independent of any export |
| `.gitleaks.toml` | yes | `template-replace` | `feature` | PM / OM | repo-root gitleaks config for the public-export gitleaks gate (`docs/runbooks/public-export.md` Step 2); extends the default ruleset and allowlists only the second-brain AC-2 test fixtures (intentionally secret-shaped test data) — must export with the tree so gitleaks honors it; extend narrowly, never broaden past the actual test surface |
| `tools/sme-charter-check.sh` | yes | `template-replace` | `feature` | PM / CM | mechanical SME-charter validator (required sections, non-empty negative discovery, Local Registry row, launcher parity in all three families); not a domain-merit judge — see `docs/designing-an-sme.md` |
| `tools/tests/` | yes | `template-replace` | `feature` | CM | test suites (`xtool-call`, `governance-consistency`, `upgrade-classify`, `issue-sync`, `issue-board-bootstrap`, `manifest-completeness`, `second-brain`, `skill-airlock`, `skill-scout`, `layer-adopted`, `instruction-size`), fixtures, and the `governance-scan.allow` / `manifest-completeness.allow` allowlists (the latter is downstream-owned, fail-open — list your own project paths there so the completeness guard stays green); adopt as reference and regression harness |
| `.claude/commands/second-opinion.md` | yes | `template-replace` | `feature` | PM | `/second-opinion` slash command; read-only cross-vendor review via `tools/xtool-call.sh` |
| `.claude/commands/delegate.md` | yes | `template-replace` | `feature` | PM | `/delegate` slash command; isolated-worktree cross-vendor implementation via `tools/xtool-call.sh` |
| `.claude/commands/handoff.md` | yes | `template-replace` | `feature` | PM | `/handoff` slash command; flush-then-snapshot session handoff (ephemeral, deleted on pickup) |
| `.claude/commands/onboard.md` | yes | `template-replace` | `feature` | PM | `/onboard` slash command; read-only session-start ready-state report (read-chain, code-map staleness, pending-handoff fold-in, gate state) |
| `docs/cross-tool-orchestration.md` | yes | `template-replace` | `feature` | PM / DM | exported cross-tool orchestration protocol doc; operator reference for the review/delegate/ship workflow |
| `docs/risk-posture-shadow-first.md` | yes | `template-replace` | `feature` | PM / AM | optional shadow-first / dark-ship risk posture for behavior-changing changes with a comparable incumbent; opt-in, no code shipped |
| `docs/instruction-size-budgets.md` | yes | `template-replace` | `feature` | PM / DM | instruction-surface word-budget reference + downstream override surface; split-merge per delimiter — template default-budget table above the marker, Local Overrides below are downstream-owned; consumed fail-open by tools/tests/instruction-size.test.sh |
| `AI/specs/` | no | `do-not-export` | `n/a` | MM / Operator | template-maintenance design specs; template-maintainer-local only |
| `AI/plans/` | no | `do-not-export` | `n/a` | MM / Operator | template-maintenance implementation plans; template-maintainer-local only |
| `docs/superpowers/` | no | `do-not-export` | `n/a` | MM / Operator | superpowers session artifacts (design specs + implementation plans); template-maintainer-local only |
| `docs/branching-and-release-model.md` | yes | `template-replace` | `baseline` | PM | canonical branching model; downstream adopts |
| `docs/runbooks/branch-setup.md` | yes | `template-replace` | `reference` | OM | one-time branch-protection + PR setup (host-agnostic: Gitea & GitHub recipes) |
| `CHANGELOG.d/README.md` | yes | `template-replace` | `feature` | DM | changelog fragment convention |
| `CHANGELOG.d/*.md` (fragments) | no | `downstream-owned` | `n/a` | DM | per-feature fragments; Class B; do not export the template's |
| `tools/issue-sync.sh` | yes | `template-replace` | `feature` | CM | optional Issue-mirror wrapper (default-off) |
| `tools/issue-board-bootstrap.sh` | yes | `template-replace` | `feature` | OM | idempotent label/board bootstrap |
| `tools/layer-adopted.sh` | yes | `template-replace` | `feature` | CM | shared fail-open adoption-record cross-check (`layer-adopted.sh <MINION_* key>`); parses the `adopted:` token on the onboarding checklist so remote-mutating layer tools no-op when a repo records a layer adopted:off despite a machine-global env gate |
| `docs/issue-mirror-model.md` | yes | `template-replace` | `feature` | PM | canonical issue-mirror model |
| `docs/runbooks/issue-board-setup.md` | yes | `template-replace` | `reference` | OM | issue board/label setup |
| `.issue` sidecars (`minions/mail/*/*.issue`) | no | `downstream-owned` | `n/a` | CM / Operator | Class B / downstream-owned; not exported from template |
| `docs/memory-recall-model.md` | yes | `template-replace` | `feature` | PM | canonical memory-recall (Mnemoverse) view-layer model |
| `docs/runbooks/memory-recall-setup.md` | yes | `template-replace` | `reference` | OM | operator setup: `MINION_MEMORY`, extension, API key, smoke test |
| `tools/archive-reporter.sh` | yes | `template-replace` | `feature` | PM / CM | read-only reporter of closed+aged coordination units (mail/plans/chat); prints `git rm` + `ARCHIVED.md` row for a human to run at milestones, never mutates; no `run` subcommand, no `MINION_*` gate |
| `docs/archive-reporter-model.md` | yes | `template-replace` | `feature` | PM | canonical archive-reporter model (read-only subset; the automated `run` path is deferred) |
| `tools/second-brain.sh` | yes | `template-replace` | `feature` | PM / CM | optional local second-brain vault tool (capture/search/filter/scan/path), default-off (`MINION_SECONDBRAIN=on`) |
| `docs/second-brain-model.md` | yes | `template-replace` | `feature` | PM | canonical local second-brain (Obsidian-backed corpus) model |
| `docs/runbooks/second-brain-setup.md` | yes | `template-replace` | `reference` | OM | operator setup: `MINION_SECONDBRAIN`/`MINION_SECONDBRAIN_VAULT`, vault containment, smoke test |
| `docs/skill-adoption-model.md` | yes | `template-replace` | `feature` | PM | canonical skill-adoption (Scout + Airlock) model; adopted-row schema, run posture, unconditional-vs-gated invariant, Enabling It / rollback; gated on `MINION_SKILLS=on` |
| `tools/skill-airlock.sh` | yes | `template-replace` | `feature` | PM / CM | optional skill-adoption airlock (`check` advisory signals + `verify-quarantine`); advisory-only, gated on `MINION_SKILLS=on` — a clean `check` is never a safety gate |
| `tools/skill-scout.sh` | yes | `template-replace` | `feature` | PM / CM | optional skill-adoption scout (`survey`, findings-only); documented WebFetch/web-UI fallback when `npx` absent; gated on `MINION_SKILLS=on` |
| `skills/vendored/` | no | `do-not-export` | `n/a` | MM / Operator | maintainer-local adopted-skill payloads + quarantined SOURCE.txt; default-deny by construction; see docs/skill-adoption-model.md |
| `docs/runbooks/public-export.md` | yes | `template-replace` | `reference` | PM | publish a privacy-safe public copy (fresh history, neutralization sweep, gitleaks gate) |
| `docs/coordinator-mode.md` | yes | `template-replace` | `feature` | PM | coordinator-mode overlay (opt-in multi-project) |
| `docs/runbooks/add-submodule.md` | yes | `template-replace` | `reference` | PM | submodule registration sequence (coordinator overlay) |
| `.github/instructions/documentation-quality.instructions.md` | yes | `template-replace` | `feature` | DM | submodule doc-quality instructions (coordinator/submodule repos) |
| `minions/capabilities.md` | yes | `template-replace` | `baseline` | PM | per-repo capability inventory; bootstrap read + activation record for `docs/minion-plugin-pairings.md`. Split-merge: the template-shipped Default Capabilities block above the delimiter ships and upgrades (so a template capability-row change propagates); the Local Inventory below the delimiter is downstream-owned and resets at export. Take the template above the marker, preserve downstream content below it — same handling as `minions/smes/README.md` |
| `minions/handoffs/README.md` | yes | `template-replace` | `feature` | PM | session-handoff surface protocol (ephemeral courier, delete-on-pickup) |
| `minions/handoffs/*.md` (snapshots) | no | `downstream-owned` | `n/a` | PM | transient session snapshots; never exported; deleted on pickup |
| `minions/smes/README.md` | yes | `template-replace` | `feature` | PM | expertise-layer surface protocol (SMEs: advisory class, not roles); a template-shipped Default Bench (above the delimiter) ships and upgrades; the Local Registry below the delimiter is downstream-added and resets at export |
| `minions/smes/sme-template.md` | yes | `template-replace` | `feature` | PM | SME charter template (discovery sections required) |
| `minions/smes/*.md` (SME charters) | yes | `template-replace` | `feature` | PM | template-default SME charters ship as starter bench; a downstream marks any private SME `do-not-export` with an explicit row |
| `minions/review-matrix.md` | yes | `template-replace` | `feature` | PM | review-routing: a template-shipped Default Matrix (above the delimiter) ships and upgrades; the Local Matrix below the delimiter is downstream-added routing and resets at export |
| `docs/runbooks/README.md` | yes | `template-replace` | `reference` | DM | runbook structure contract (required sections + two hard rules) |
| `.claude/agents/sme-*.md` (SME launchers) | yes | `template-replace` | `feature` | PM | template-default SME launchers ship with the bench (Claude/Codex/Copilot) |
| `.codex/agents/sme-*.toml` (SME launchers) | yes | `template-replace` | `feature` | PM | template-default SME launchers ship with the bench (Claude/Codex/Copilot) |
| `.github/agents/sme-*.agent.md` (SME launchers) | yes | `template-replace` | `feature` | PM | template-default SME launchers ship with the bench (Claude/Codex/Copilot) |

Downstream-added manifest rows for project-specific files not covered by the
Manifest table above go in the **Downstream Additions** section below the
delimiter, using the same schema as the Manifest table. That section is
header-only in the template; each downstream repo appends its own rows there.
Replace nothing above the delimiter; add everything project-specific below
it — do not hand-append rows to the end of the Manifest table above.

<!-- ================= DOWNSTREAM CONTENT BELOW — template upgrades replace above this line only ================= -->

## Downstream Additions (this repo)

| Path | Initial export | Upgrade strategy | Criticality | Default owner | Notes |
| --- | --- | --- | --- | --- | --- |
