# MECHANICS — minions-template system map

verified @ <sha>
Mapped areas: <paths>

This is the **code map** — how the system actually works — distinct from the
governance/process docs. `/onboard` reads the Summary/Index below in full and
flags this map PARTIAL when a mapped area has changed since the `verified @`
commit. It is a map, not per-function docs: components, entry points, data
flow, key files, and the guard surface at the altitude a fresh session needs.

## Maintaining this map
- Owner: AM (architecture map), DM doc-sync. Update this file in the same
  change set that alters code/architecture in a mapped area (Documentation
  Sync Rule), and re-stamp `verified @ <sha>` when you re-confirm it vs HEAD.
- Keep the Summary/Index within its `docs/instruction-size-budgets.md` cap
  (it is read every `/onboard`). Push per-area detail to `docs/mechanics/<area>.md`.
- If you add another ABOVE-marker field carrying repo-specific content
  (alongside `verified @ <sha>` and `Mapped areas: <paths>`), add a matching
  row to `tools/export-seed-check.sh`'s `SEED_ANCHORS` table in the same
  commit — that table is hand-maintained and the only thing that resets the
  field at public export; nothing else enforces its completeness.

## Summary / Index
<!-- Downstream: replace everything below with your own system-at-a-glance.
     Keep it terse — this section is read on every /onboard. -->

