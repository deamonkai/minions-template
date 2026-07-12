# docs/instruction-size-budgets.md — Instruction-Surface Size Budgets

Purpose: bootstrap-surface files (`CLAUDE.md`, `AGENTS.md`, role charters,
SME files, and the rest of the instruction/bootstrap surface) carry a
whole-file word budget so the surface cannot bloat unnoticed as the template
is adopted and extended. Budgets apply to the WHOLE file — content below a
downstream delimiter counts, because whole-file size is the token cost every
session pays at bootstrap. See MEMORY.md, "Instruction-Surface Size Budgets".

## Default budgets

Mirror of the guard defaults — regenerate with
`tools/tests/instruction-size.test.sh --report`; the guard wins on any
disagreement.

| Key | Budget |
| --- | --- |
| CLAUDE.md / AGENTS.md / .github/copilot-instructions.md | 600 each |
| INIT.md / AI.md | 1800 each |
| MEMORY.md | 9000 |
| minions/capabilities.md | 1500 |
| minions/review-matrix.md | 1200 |
| feedback.md | 3000 |
| minions/smes/README.md | 2000 |
| minions/roles/*.md (class) | 2400 |
| minions/roles/PM.md (exact) | 3000 |
| minions/smes/*.md (class) | 1100 |

`minions/roles/PM.md` carries an exact-path budget of 3000, above the
`minions/roles/*.md` class ceiling of 2400 — the exact-path row wins over
the class row per the Precedence section below.

## Two surface classes

Field-measured (downstream report, 2026-07-12, no repo named): guide-class
surfaces (entry points, `MEMORY.md` summaries) relocate well — expect deep
cuts at zero loss. Binding-rules surfaces (role/SME charters, capture logs)
bottom out quickly because everything remaining is binding; their budgets
ship with proportionally more headroom, and a breach there means promote
detail to `docs/*.md`/runbooks or add an override — never delete binding
rules or lessons to fit under a cap.

## Override format

Add one `KEY = BUDGET` line per override in the "Local Overrides" section
below the delimiter. `KEY` is either an exact path (e.g. `CLAUDE.md`) or one
of the class-glob strings above (e.g. `minions/roles/*.md`, matched
literally as a string, not expanded). `BUDGET` is a positive integer. Blank
lines and comments (any line without a bare `KEY = BUDGET` shape) are
ignored.

<!-- Example: -->
<!-- CLAUDE.md = 700 -->

## Fail-open contract

The override file is consulted fail-open: an absent file, an empty file, or
any malformed line falls back to the template default for that key. An
override can **raise, set, or deliberately tighten** a budget — what it can
never do is remove a surface from being checked or block the guard from
running. Downstream owns this file entirely; the template only ever reads
it.

## Precedence

`override-exact > override-class > default-exact > default-class >
not-budgeted (skip)`. A named-file row always beats its class row, and an
override always beats the matching default, at the same specificity level.

<!-- ================= DOWNSTREAM CONTENT BELOW — template upgrades replace above this line only ================= -->

## Local Overrides
