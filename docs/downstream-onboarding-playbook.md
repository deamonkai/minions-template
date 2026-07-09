# Downstream Onboarding Playbook

Owner: `PM` by default

Use this playbook when introducing the minion template into a downstream
project for the first time.

## Core Idea

Initial onboarding should not be a blind copy of the template repo into the
downstream repo.

Treat onboarding as the first controlled export from a vendored template
snapshot.

This gives AI agents a durable provenance model:

1. vendored template baseline
2. live downstream operating files
3. project-specific downstream state

## Recommended Paths

- approved template snapshot: `.minions-template/`
- live downstream files: repo root, `.github/agents/`, `.codex/agents/`, `.claude/agents/`, `docs/`, and `minions/`

Do not stage onboarding from `.minions-template.next/`; that path is for later
upgrade candidates.

The vendored snapshot is an export-ready copy of the template, not a full Git
clone.

- exclude `.git/`
- exclude files marked `do-not-export` in `docs/export-manifest.md`
- `.mm.md` should not appear in `.minions-template/` unless the Operator
  intentionally chooses to carry maintainer context downstream

## Ownership

- `PM` owns the onboarding export packet and Operator-facing checklist
- `AM` reviews architecture/design assumptions when project structure or system
  boundaries need clarification
- `SM` reviews baseline guardrails, secrets posture, and trust-boundary setup
- `CM` helps apply technical merges where project constraints require them
- `DM` reviews documentation structure, reader paths, onboarding clarity, and
  required shared docs
- `OM-Test` / `OM` confirm environment and runtime workflow expectations when
  relevant
- `Operator` approves the exported operating surface

## Onboarding Workflow

1. Create `.minions-template/` as an export-ready snapshot of the template:
   - copy the files needed for onboarding and future upgrades
   - do not carry Git metadata such as `.git/`
   - do not carry `do-not-export` files such as `.mm.md` or the `AI/` directory
     (the cross-AI template-maintenance layer is not for downstream projects)
2. Review `docs/export-manifest.md` before exporting any live files.
3. Export `template-replace` files from `.minions-template/` into the live
   downstream repo.
4. Create `manual-merge` files by combining the template baseline with
   project-specific reality:
   - `INIT.md`
   - `MEMORY.md`
   - `docs/operator-onboarding-checklist.md`
   - `minion-version.md`
5. Do not export `do-not-export` files, and do not keep them in the vendored
   snapshot, unless the Operator explicitly wants them downstream.
6. Export `.github/agents/`, `.codex/agents/`, and/or `.claude/agents/` when
   the downstream project will use Copilot custom agents, Codex custom agents,
   or Claude Code subagents for minion roles. The agent files should stay thin
   and point at the durable role charters under `minions/roles/`. If a family
   is exported before the project can run it, mark it deferred (see Deferred
   Launcher Families below).
7. Treat downstream-owned files as project surfaces, not template clones:
   - project `README.md`
   - live plans
   - live mail packet history
   - live chat summary history
   - downstream `CHANGELOG.md`
   - `ROADMAP.md`
   - `TODO.md`
8. Run the onboarding checklist with the Operator and fill in project-specific
   decisions.
9. Wire this project's minion↔plugin pairings: review
   `docs/minion-plugin-pairings.md` and, for the integrations this project
   actually uses (issue tracker, observability, security scanner, research, etc.),
   add a tool-agnostic "use-when" line to the owning role charter under
   `minions/roles/`, and add any scoped whitelist entry a restricted role (e.g.
   `RM`) needs. Skip pairings whose plugin is not present. These are local role
   customizations — the upgrade flow preserves them.
10. Bootstrap mailbox use in the live downstream repo:
   - read `MEMORY.md`
   - read `.github/agents/README.md` when using Copilot custom agents
   - read `.codex/agents/README.md` when using Codex custom agents
   - read `.claude/agents/README.md` when using Claude Code subagents
   - read `docs/minion-prompt-modes.md`
   - read `docs/project/mailbox-collaboration-model.md`
   - read `minions/mail/README.md`
   - read `minions/mail/packet-template.md`
   - use `minions/mail/` for new actionable packets
   - use `minions/chat/` for PM daily summaries
11. Commit the vendored snapshot and exported live files together so the repo has
   a clear starting baseline.
12. After onboarding is approved, future template changes should use
   `docs/downstream-upgrade-playbook.md`.

## Deferred Launcher Families

A launcher family may be exported before the downstream project can actually
run it — for example, `.codex/agents/` exported while the project has no
Codex access yet. Record that state explicitly instead of leaving the export
ambiguous. Apply the notice below to any launcher family that is exported but
not yet active (place it at the top of the family's `README.md`), and remove
it when the family is activated:

> **DEFERRED:** This environment is not yet active in this repo.
> When it becomes available, open a scoped migration packet with PM and the
> Operator before activating.

Baseline files are not deferred by default: the notice records a real
deferral decision for a specific launcher family, never a template
placeholder. Track the per-family state (`active` / `deferred` /
`not exported`) in `docs/operator-onboarding-checklist.md`.

## Manual-Merge Guidance

### `INIT.md`

- keep the template workflow framing
- adapt onboarding language to the downstream project
- preserve project-specific paths, environments, and immediate startup notes

### `MEMORY.md`

- keep shared guardrails and role definitions from the template
- add project-specific purpose, architecture, environments, and constraints
- preserve downstream operational truth over template examples

### `docs/operator-onboarding-checklist.md`

- keep the evolving checklist from the template
- record real downstream decisions instead of leaving template placeholders

### `minion-version.md`

- set the initial base-template version from `.minions-template/`
- initialize the downstream version suffix for the project

## Minimum PM Onboarding Packet

- template version being onboarded
- vendored snapshot path
- confirmation that `.git/` and `do-not-export` files were excluded from the vendored snapshot
- files exported directly from template
- whether `.github/agents/`, `.codex/agents/`, and/or `.claude/agents/` were
   exported for Copilot, Codex, or Claude role-agent use
- files manually merged for downstream use
- files intentionally left downstream-owned
- confirmation that mailbox bootstrap docs were reviewed and `minions/mail/` is the active packet surface for new work
- open Operator decisions
- first commit scope and next owner

## Extending the Role Set

Adding a role downstream touches more surfaces than the charter. The role
set has drifted before — per `CHANGELOG.md`, `SM` was added to the shared
handoff order and the Completion Handoff `NEXT OWNER` enumeration in
`MEMORY.md` on 2026-04-08, then had to be explicitly reconciled to "remain
consistently present" in those same contracts three days later, on
2026-04-11, while `AM` was being added as a new role — so treat the
following as the minimum touch list, not a suggestion:

- role charter added under `minions/roles/`
- the role's launcher added to every launcher family in use
  (`.github/agents/`, `.codex/agents/`, and/or `.claude/agents/`)
- downstream `MEMORY.md` Collaboration Model roster updated
- downstream `MEMORY.md` Completion Handoff `NEXT OWNER` enumeration updated
- downstream `AI.md` Role Agents launcher list updated — this surface is
  enforced, not advisory: the roster-drift guard in
  `tools/tests/governance-consistency.test.sh` compares the `AI.md` Role
  Agents list against the `MEMORY.md` Collaboration Model roster and fails
  the suite on any mismatch

A role that exists in its charter but is missing from the roster or the
`NEXT OWNER` enumeration cannot cleanly receive a handoff — that drift
surfaces as a broken handoff later, not as a visible error at add time.
Roster↔launcher-list drift is the one exception: the governance test above
turns it into a visible failure on the next suite run.
