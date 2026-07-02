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
- Codex custom agents enabled for minion roles: yes/no
- Codex agent names accepted (`pm`, `am`, `cm`, `sm`, `dm`, `om`, `rm`): yes/no
- Claude Code subagents enabled for minion roles: yes/no
- Claude agent names accepted (`pm`, `am`, `cm`, `sm`, `dm`, `om`, `rm`): yes/no
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
- Copilot custom-agent guidance reviewed (`.github/agents/README.md`)
- Codex custom-agent guidance reviewed (`.codex/agents/README.md`)
- Claude Code subagent guidance reviewed (`.claude/agents/README.md`)
- role charters understood as **living state**: each role keeps its own `minions/roles/*.md` current with accumulated learnings as work evolves — confirm role-keepers treat charter upkeep as a standing habit from day one (one of the highest-value parts of the workflow)
- mailbox coordination workflow reviewed (`docs/project/mailbox-collaboration-model.md`, `minions/mail/README.md`)
- vendored template snapshot initialized (recommended `.minions-template/`; exclude `.git/` and `do-not-export` files)
- initial downstream export completed using `docs/downstream-onboarding-playbook.md`
- downstream template-upgrade owner confirmed (default `PM`)
- `minion-version.md` reviewed and downstream version format confirmed

## 4. Escalation Policy (Operator Optional)

Enabled by Operator: yes/no

If enabled:

- production blocker response expectation:
- non-critical blocker response expectation:
- incident communication expectation:

## 5. Guardrail Confirmation

- base guardrails accepted
- project-specific guardrails added:
- secret and personal-data handling confirmed
- machine-specific metadata hygiene confirmed (example: .DS_Store stays untracked)
- rollback posture expectation confirmed

## 6. Sign-Off

Operator decision: pending

Notes:
