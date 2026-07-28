# TODO.md — Actionable Backlog

Required by `MEMORY.md` (Shared Rules). Tracks actionable backlog items with
current status. Owned by `PM` / `DM`.

**Class A** (mainline-authoritative per `docs/branching-and-release-model.md`):
the copy on `main`/`dev`/`staging` is the real one. A copy seen on a feature
branch may be stale — merge `dev` in before relying on it.

**Relationship to the issue mirror:** when `MINION_ISSUES=on`, host Issues are a
one-way projection of git-native surfaces. This file wins. If an Issue and an
entry here disagree, regenerate the Issue, never the reverse.

**Scope:** actionable items with an owner and a next step. Direction and
sequencing live in `ROADMAP.md`; Operator corrections live in `feedback.md`;
formal milestone scope lives in `minions/plans/`.

## Conventions

```
- [ ] **Short title** — what actually needs doing
  - status: open | in-progress | blocked | done
  - owner: PM | AM | CM | SM | DM | OM-Test | OM | RM | Operator
  - evidence: file:line, packet path, or command output
```

Status `done` items are pruned at the next milestone once reflected in
`CHANGELOG.md` — this file tracks open work, not history.
