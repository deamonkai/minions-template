# ROADMAP.md — Approved Direction

Required by `MEMORY.md` (Shared Rules). Reflects approved direction and
upcoming milestones. Owned by `PM` / `DM`.

**Class A** (mainline-authoritative per `docs/branching-and-release-model.md`):
the copy on `main`/`dev`/`staging` is the real one. A copy seen on a feature
branch may be stale — merge `dev` in before relying on it.

**Scope:** direction and sequencing. Actionable items with owners live in
`TODO.md`; formal milestone scope and acceptance criteria live in
`minions/plans/`; shipped history lives in `CHANGELOG.md`.

## Conventions

Horizons, not dates — this project's cadence is release-driven, not calendar-
driven.

- **Now** — in flight on a branch today.
- **Next** — approved and specified; the next things to build.
- **Later** — designed, scouted, or deferred; real but unscheduled.
- **Not doing** — explicitly declined, with the reason. Entries are kept, not
  deleted; a declined idea that keeps resurfacing is a signal.

An entry earns a place here only with evidence — a spec, a scouting packet, an
Operator decision. Speculative direction stays out of this file until it is
approved — keep it wherever this project tracks open questions.
