# Operator Onboarding Checklist

Owner: PM
Status: not started
Date: YYYY-MM-DD

## 1. Project Framing

- project name:
- objective:
- key constraints:
- environments in scope:

## 2. Roles and Boundaries

- PM assigned: pending Operator confirmation
- AM assigned: pending Operator confirmation
- CM assigned: pending Operator confirmation
- SM assigned: pending Operator confirmation
- DM assigned: pending Operator confirmation
- OM-Test assigned: pending Operator confirmation
- OM assigned: pending Operator confirmation
- RM assigned: pending Operator confirmation
- Copilot custom agents enabled for minion roles: yes/no
- Copilot agent names accepted (`pm`, `am`, `cm`, `sm`, `dm`, `om`, `rm`): yes/no
- Copilot launcher-family activation state: `active` / `deferred` / `not exported`
- Codex custom agents enabled for minion roles: yes/no
- Codex agent names accepted (`pm`, `am`, `cm`, `sm`, `dm`, `om`, `rm`): yes/no
- Codex launcher-family activation state: `active` / `deferred` / `not exported`
- Claude Code subagents enabled for minion roles: yes/no
- Claude agent names accepted (`pm`, `am`, `cm`, `sm`, `dm`, `om`, `rm`): yes/no
- Claude launcher-family activation state: `active` / `deferred` / `not exported`
- PM handoff mode: `commit-only` / `commit-and-push`
- AM handoff mode: `commit-only` / `commit-and-push`
- CM handoff mode: `commit-only` / `commit-and-push`
- SM handoff mode: `commit-only` / `commit-and-push`
- DM handoff mode: `commit-only` / `commit-and-push`
- OM-Test handoff mode: `commit-only` / `commit-and-push`
- OM handoff mode: `commit-only` / `commit-and-push`
- RM handoff mode: `commit-only` / `commit-and-push`
- any role exceptions approved by Operator: RM is pinned to a read-only + web tool whitelist on the Claude projection (research-and-recommend only; may not create or execute code)

## 3. Required Artifacts

- `MEMORY.md` reviewed and accepted by Operator
- `CHANGELOG.md` initialized and owner set
- `ROADMAP.md` initialized and owner set
- `TODO.md` initialized and owner set
- `feedback.md` initialized from the template seed (Operator feedback capture; read at session start)
- `AI.md` reviewed for cross-tool Copilot / Codex / Claude collaboration
- prompt mode guidance reviewed (`docs/minion-prompt-modes.md`)
- minion↔plugin pairings reviewed (`docs/minion-plugin-pairings.md`) and the project's actual pairings wired into the relevant role charters (e.g. a "use-when" line for an issue tracker on `PM`, a research integration on `RM`)
- capabilities inventory filled (`minions/capabilities.md`): yes/no, date: YYYY-MM-DD
- instruction-surface size budgets reviewed (`docs/instruction-size-budgets.md`); per-repo overrides set if any: yes/no
- Copilot custom-agent guidance reviewed (`.github/agents/README.md`)
- Codex custom-agent guidance reviewed (`.codex/agents/README.md`)
- Claude Code subagent guidance reviewed (`.claude/agents/README.md`)
- role charters understood as **living state**: each role keeps its own `minions/roles/*.md` current with accumulated learnings as work evolves — confirm role-keepers treat charter upkeep as a standing habit from day one (one of the highest-value parts of the workflow)
- mailbox coordination workflow reviewed (`docs/project/mailbox-collaboration-model.md`, `minions/mail/README.md`)
- vendored template snapshot initialized (recommended `.minions-template/`; exclude `.git/` and `do-not-export` files)
- initial downstream export completed using `docs/downstream-onboarding-playbook.md`
- downstream template-upgrade owner confirmed (default `PM`)
- `minion-version.md` reviewed and downstream version format confirmed

## 4. Optional Layers (Operator Decision)

Optional layers ship default-off; a missing gate or its tooling is always a
silent no-op that never blocks a workflow (see `MEMORY.md` → Optional Layers).
Record which layers this repo has **adopted** so a fresh session knows they are
expected standing practice — not merely available — and where the gate is set.
An adopted layer's backing capability should also be listed `active` in
`minions/capabilities.md`, so the utilization obligation makes using it standing
practice while the silent-no-op guarantee still covers absence at call time.

The `adopted:` token is machine-readable — `tools/layer-adopted.sh
<MINION_* key>` parses it (`on` → adopted/standing practice, `off` →
remote-mutating layer tools silently no-op even when the env gate is on,
`unset` → the env gate alone decides). The shipped default `unset` is
safe: leaving it preserves env-gate-only behavior. Set it to `on`/`off`
when you make the adoption decision for this repo.

- Memory recall (`MINION_MEMORY`) — adopted: unset — date: YYYY-MM-DD; gate
  persisted in: `~/.zshenv` / direnv / CI env / other (non-interactive agent
  shells do **not** read `~/.zshrc` — verify from a fresh tool shell)
- Second brain (`MINION_SECONDBRAIN`) — adopted: unset — date: YYYY-MM-DD;
  vault path: `MINION_SECONDBRAIN_VAULT` (default `~/second-brain/`); gate
  persisted in: `~/.zshenv` / direnv / CI env / other (same non-interactive
  `~/.zshrc` gotcha as memory recall — verify from a fresh tool shell)
- Skill adoption (`MINION_SKILLS`) — adopted: unset — date: YYYY-MM-DD; gate
  persisted in: `~/.zshenv` / direnv / CI env / other (same non-interactive
  `~/.zshrc` gotcha — verify from a fresh tool shell). Even when off, the
  unconditional protections stand (the `skills/vendored/` manifest exclusion +
  forbidden-path gate, the hard-stop-#2 instance, and the Skill-Provenance
  SME); adopt skills only through the airlock — see `docs/skill-adoption-model.md`
- Issue mirror (`MINION_ISSUES`) — adopted: unset — date: YYYY-MM-DD
- Coordinator mode (`projects/` + `MEMORY.md` declaration) — adopted: unset —
  date: YYYY-MM-DD (this `adopted:` token is documentation-only — there is no
  `MINION_*` gate key for coordinator mode, and `tools/layer-adopted.sh` does
  not parse this line)
- Adopted layers' backing capabilities listed `active` in `minions/capabilities.md`: yes/no

## 5. Escalation Policy (Operator Optional)

Enabled by Operator: yes/no

If enabled:

- production blocker response expectation:
- non-critical blocker response expectation:
- incident communication expectation:

## 6. Guardrail Confirmation

- base guardrails accepted
- project-specific guardrails added:
- secret and personal-data handling confirmed
- machine-specific metadata hygiene confirmed (example: .DS_Store stays untracked)
- rollback posture expectation confirmed

## 7. Sign-Off

Operator decision: pending

Notes:
