# Export Manifest

This manifest defines how files from the template should be treated in
downstream repositories.

Use this manifest with:

- `docs/downstream-onboarding-playbook.md` for first export into a downstream repo
- `docs/downstream-upgrade-playbook.md` for later template migrations

## Strategy Meanings

- `template-replace`: usually replace from the new template version, then
  consciously reapply any intentional downstream divergence
- `manual-merge`: always review and merge with downstream state
- `downstream-owned`: do not overwrite during template upgrades
- `do-not-export`: keep out of downstream live files and out of the vendored
  `.minions-template/` snapshot unless the Operator explicitly chooses
  otherwise

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
  template, so file-level criticality does not apply. One exception:
  `minions/capabilities.md` is `downstream-owned` yet rated `baseline`,
  because the session bootstrap read order depends on it — its starter must
  land at first export even though upgrades never touch the filled inventory.

> **Note:** Class-A files (`MEMORY.md`, `AI.md`, `CLAUDE.md`, `AGENTS.md`,
> `minions/roles/*`, `ROADMAP.md`, `TODO.md`, `minions/chat/`) are
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
| `AI.md` | yes | `manual-merge` | `baseline` | PM / Operator | cross-tool coordination notes for AI assistants; preserve downstream-specific handoff guidance |
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
| `.codex/agents/README.md` | yes | `template-replace` | `feature` | PM | Codex custom agent usage guidance |
| `.codex/agents/pm.toml` | yes | `template-replace` | `feature` | PM | Codex custom agent launcher for `minions/roles/PM.md` |
| `.codex/agents/am.toml` | yes | `template-replace` | `feature` | PM / AM | Codex custom agent launcher for `minions/roles/AM.md` |
| `.codex/agents/cm.toml` | yes | `template-replace` | `feature` | PM / CM | Codex custom agent launcher for `minions/roles/CM.md` |
| `.codex/agents/sm.toml` | yes | `template-replace` | `feature` | PM / SM | Codex custom agent launcher for `minions/roles/SM.md` |
| `.codex/agents/dm.toml` | yes | `template-replace` | `feature` | PM / DM | Codex custom agent launcher for `minions/roles/DM.md` |
| `.codex/agents/om.toml` | yes | `template-replace` | `feature` | PM / OM | Codex custom agent launcher for `minions/roles/OM.md` |
| `.codex/agents/rm.toml` | yes | `template-replace` | `feature` | PM / RM | Codex custom agent launcher for `minions/roles/RM.md` |
| `.claude/agents/README.md` | yes | `template-replace` | `feature` | PM | Claude Code subagent usage guidance |
| `.claude/agents/pm.md` | yes | `template-replace` | `feature` | PM | Claude Code subagent launcher for `minions/roles/PM.md` |
| `.claude/agents/am.md` | yes | `template-replace` | `feature` | PM / AM | Claude Code subagent launcher for `minions/roles/AM.md` |
| `.claude/agents/cm.md` | yes | `template-replace` | `feature` | PM / CM | Claude Code subagent launcher for `minions/roles/CM.md` |
| `.claude/agents/sm.md` | yes | `template-replace` | `feature` | PM / SM | Claude Code subagent launcher for `minions/roles/SM.md` |
| `.claude/agents/dm.md` | yes | `template-replace` | `feature` | PM / DM | Claude Code subagent launcher for `minions/roles/DM.md` |
| `.claude/agents/om.md` | yes | `template-replace` | `feature` | PM / OM | Claude Code subagent launcher for `minions/roles/OM.md` |
| `.claude/agents/rm.md` | yes | `template-replace` | `feature` | PM / RM | Claude Code subagent launcher for `minions/roles/RM.md`; read-only + web tool whitelist |
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
| `docs/designing-an-sme.md` | yes | `template-replace` | `reference` | PM | SME design craft (consultable-expertise-vs-process test, disjoint-domain drawing, tier selection, evidence discipline); precedes the Adding-an-SME mechanics and `tools/sme-charter-check.sh` |
| `docs/minion-plugin-pairings.md` | yes | `template-replace` | `feature` | PM | recommended (conditional) minion-to-plugin/connector/skill pairings; adjust to the downstream stack |
| `docs/project/mailbox-collaboration-model.md` | yes | `template-replace` | `baseline` | PM | baseline mailbox-first coordination model |
| `docs/operator-onboarding-checklist.md` | yes | `manual-merge` | `reference` | PM | preserve completed downstream decisions |
| `docs/downstream-onboarding-playbook.md` | yes | `template-replace` | `reference` | PM | baseline initial onboarding procedure |
| `docs/downstream-upgrade-playbook.md` | yes | `template-replace` | `reference` | PM | baseline downstream-upgrade procedure; holds Version-Specific Required Changes |
| `docs/export-manifest.md` | yes | `template-replace` | `reference` | PM | baseline export/merge strategy |
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
| `ROADMAP.md` | downstream required | `downstream-owned` | `n/a` | PM / DM | currently required by the workflow but not shipped as a template file |
| `TODO.md` | downstream required | `downstream-owned` | `n/a` | PM / DM | currently required by the workflow but not shipped as a template file |
| `tools/xtool-call.sh` | yes | `template-replace` | `feature` | PM / CM | cross-tool orchestration wrapper (Codex / Copilot, review / delegate postures); adopt if project uses cross-vendor review |
| `tools/upgrade-classify.sh` | yes | `template-replace` | `reference` | PM / CM | upgrade helper: classifies a template change-set (manifest class + live-vs-snapshot divergence) for downstream upgrades; see `docs/downstream-upgrade-playbook.md` |
| `tools/export-seed-check.sh` | yes | `template-replace` | `feature` | PM / OM | public-export pre-push gate (runbook Step 3, gate 4): asserts Local Registry / Local Matrix are header-only below the split-merge delimiter in the export tree; point `SEED_FILES` at the downstream's own delimited local sections |
| `tools/sme-charter-check.sh` | yes | `template-replace` | `feature` | PM / CM | mechanical SME-charter validator (required sections, non-empty negative discovery, Local Registry row, launcher parity in all three families); not a domain-merit judge — see `docs/designing-an-sme.md` |
| `tools/tests/` | yes | `template-replace` | `feature` | CM | test suites (`xtool-call`, `governance-consistency`, `upgrade-classify`, `issue-sync`, `issue-board-bootstrap`, `manifest-completeness`), fixtures, and the `governance-scan.allow` scan list; adopt as reference and regression harness |
| `.claude/commands/second-opinion.md` | yes | `template-replace` | `feature` | PM | `/second-opinion` slash command; read-only cross-vendor review via `tools/xtool-call.sh` |
| `.claude/commands/delegate.md` | yes | `template-replace` | `feature` | PM | `/delegate` slash command; isolated-worktree cross-vendor implementation via `tools/xtool-call.sh` |
| `.claude/commands/handoff.md` | yes | `template-replace` | `feature` | PM | `/handoff` slash command; flush-then-snapshot session handoff (ephemeral, deleted on pickup) |
| `docs/cross-tool-orchestration.md` | yes | `template-replace` | `feature` | PM / DM | exported cross-tool orchestration protocol doc; operator reference for the review/delegate/ship workflow |
| `docs/risk-posture-shadow-first.md` | yes | `template-replace` | `feature` | PM / AM | optional shadow-first / dark-ship risk posture for behavior-changing changes with a comparable incumbent; opt-in, no code shipped |
| `AI/specs/` | no | `do-not-export` | `n/a` | MM / Operator | template-maintenance design specs; template-maintainer-local only |
| `AI/plans/` | no | `do-not-export` | `n/a` | MM / Operator | template-maintenance implementation plans; template-maintainer-local only |
| `docs/superpowers/` | no | `do-not-export` | `n/a` | MM / Operator | superpowers session artifacts (design specs + implementation plans); template-maintainer-local only |
| `docs/branching-and-release-model.md` | yes | `template-replace` | `baseline` | PM | canonical branching model; downstream adopts |
| `docs/runbooks/branch-setup.md` | yes | `template-replace` | `reference` | OM | one-time branch-protection + PR setup (host-agnostic: Gitea & GitHub recipes) |
| `CHANGELOG.d/README.md` | yes | `template-replace` | `feature` | DM | changelog fragment convention |
| `CHANGELOG.d/*.md` (fragments) | no | `downstream-owned` | `n/a` | DM | per-feature fragments; Class B; do not export the template's |
| `tools/issue-sync.sh` | yes | `template-replace` | `feature` | CM | optional Issue-mirror wrapper (default-off) |
| `tools/issue-board-bootstrap.sh` | yes | `template-replace` | `feature` | OM | idempotent label/board bootstrap |
| `docs/issue-mirror-model.md` | yes | `template-replace` | `feature` | PM | canonical issue-mirror model |
| `docs/runbooks/issue-board-setup.md` | yes | `template-replace` | `reference` | OM | issue board/label setup |
| `.issue` sidecars (`minions/mail/*/*.issue`) | no | `downstream-owned` | `n/a` | CM / Operator | Class B / downstream-owned; not exported from template |
| `docs/memory-recall-model.md` | yes | `template-replace` | `feature` | PM | canonical memory-recall (Mnemoverse) view-layer model |
| `docs/runbooks/memory-recall-setup.md` | yes | `template-replace` | `reference` | OM | operator setup: `MINION_MEMORY`, extension, API key, smoke test |
| `docs/runbooks/public-export.md` | yes | `template-replace` | `reference` | PM | publish a privacy-safe public copy (fresh history, neutralization sweep, gitleaks gate) |
| `docs/coordinator-mode.md` | yes | `template-replace` | `feature` | PM | coordinator-mode overlay (opt-in multi-project) |
| `docs/runbooks/add-submodule.md` | yes | `template-replace` | `reference` | PM | submodule registration sequence (coordinator overlay) |
| `.github/instructions/documentation-quality.instructions.md` | yes | `template-replace` | `feature` | DM | submodule doc-quality instructions (coordinator/submodule repos) |
| `minions/capabilities.md` | yes | `downstream-owned` | `baseline` | PM | per-repo capability inventory; bootstrap read + activation record for `docs/minion-plugin-pairings.md`. Template ships the starter (instructions + example rows); downstream fills and owns the content — do not overwrite the filled inventory during upgrades |
| `minions/handoffs/README.md` | yes | `template-replace` | `feature` | PM | session-handoff surface protocol (ephemeral courier, delete-on-pickup) |
| `minions/handoffs/*.md` (snapshots) | no | `downstream-owned` | `n/a` | PM | transient session snapshots; never exported; deleted on pickup |
| `minions/smes/README.md` | yes | `template-replace` | `feature` | PM | expertise-layer surface protocol (SMEs: advisory class, not roles) + downstream-owned registry table; seed only below delimiter (local registry resets at export) |
| `minions/smes/sme-template.md` | yes | `template-replace` | `feature` | PM | SME charter template (discovery sections required) |
| `minions/smes/*.md` (SME charters) | no | `downstream-owned` | `n/a` | PM | downstream expertise content; never exported from the template |
| `minions/review-matrix.md` | yes | `downstream-owned` | `feature` | PM | review-routing starter (change types → required reviewers); template ships generic examples, downstream fills and owns; seed only below delimiter (local matrix resets at export) |
| `docs/runbooks/README.md` | yes | `template-replace` | `reference` | DM | runbook structure contract (required sections + two hard rules) |
| `.claude/agents/sme-*.md` (SME launchers) | no | `downstream-owned` | `n/a` | PM | SME launchers are expertise content owned by each repo — canonical's bench included; never exported from the template |
| `.codex/agents/sme-*.toml` (SME launchers) | no | `downstream-owned` | `n/a` | PM | SME launchers are expertise content owned by each repo — canonical's bench included; never exported from the template |
| `.github/agents/sme-*.agent.md` (SME launchers) | no | `downstream-owned` | `n/a` | PM | SME launchers are expertise content owned by each repo — canonical's bench included; never exported from the template |
