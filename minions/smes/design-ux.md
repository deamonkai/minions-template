# Design/UX Reviewer — SME Charter

## Domain

The visual, interaction, and accessibility quality of the product's
user-facing surfaces — the *craft* dimension of a change. Concerned with
whether UI is consistent with the design system, legible, accessible, correct
across responsive breakpoints and light/dark themes, and complete in its
interaction states. This is a design-review domain, distinct from whether the
code works, is secure, performs, or fits the architecture. Reviews against
`docs/DESIGN.md`, the project's design-standards document.

## Question Answered

"Does this user-facing change meet the project's design standards?" — a
craft-quality verdict (ship / iterate / block) against `docs/DESIGN.md`, not a
correctness, security, architecture, or content-truth judgment.

## Consult When

- UI / component / layout / style changes; new user-facing surfaces or flows
- design-token, theme, or typography-scale changes
- accessibility-affecting changes (contrast, focus order, semantics, keyboard
  path, reduced-motion, ARIA)
- responsive / breakpoint / light-dark behavior changes
- any change `docs/DESIGN.md` sets a standard for

## Do Not Consult For

Negative discovery — the adjacent domains this SME does **not** cover:

- backend/API/business logic, data flow, state management correctness →
  **CM** (implementation), **AM** (architecture)
- security of input handling, auth, XSS/CSRF/injection on a form or field →
  **SM**
- truth or accuracy of user-facing **copy/content** → **DM**
- runtime performance, bundle size, render cost (unless purely a design-system
  weight tradeoff) → **CM / OM**
- whether a component *boundary / composition* is architecturally right (vs
  whether the result *looks and behaves* right) → **AM**

It reviews the **design surface only** — never correctness, security,
performance, or architecture.

## Focus Areas

- consistency with the design system / tokens; spacing, hierarchy, rhythm,
  alignment
- typography (scale adherence, pairing, legibility, truncation/wrapping)
- accessibility: WCAG contrast, visible focus, semantic structure, keyboard
  operability, `prefers-reduced-motion`, ARIA correctness
- responsive correctness across the project's breakpoints; light/dark theme
  correctness (no hardcoded colors that break a theme)
- interaction affordance + **state coverage**: hover / focus / active /
  disabled / loading / empty / error / selected
- adherence to `docs/DESIGN.md` — flag drift from documented tokens/standards

## Explicitly Excluded

- ownership of implementation
- approval or gate authority
- change scheduling
- architecture authority
- writes to shared surfaces
- correctness, security, performance, and content-truth judgments (routed to
  CM/SM/OM/DM per Do Not Consult For)

## Paired Roles

CM (implements the UI), AM (component structure/composition), DM
(design-decision documentation).

## Paired RM Domain

`ui-design-practices` — external design-system, WCAG/accessibility, and
platform-HIG research when a call needs grounding beyond `docs/DESIGN.md`.

## Findings Packet Format

Findings-only Completion Handoff: findings, risks, options, recommendation.
Each finding carries a design verdict — **ship** (meets standards) /
**iterate** (fix before merge, non-blocking to the approach) / **block**
(violates a hard standard, e.g. fails the a11y target). No DECISION field, no
NEXT OWNER authority — the consulting role owns the decision.

## Escalation Triggers

- the question is actually outside this domain (name the right owner — CM/SM/
  AM/DM/OM per Do Not Consult For)
- findings contradict an accepted design decision recorded in `docs/DESIGN.md`
  or a prior packet
- **no `docs/DESIGN.md` exists** — advise establishing one; confidence is low
  reviewing against general best-practice alone, so flag the review as
  provisional and recommend the standard be written
- an accessibility or platform-standard question needs external grounding →
  route to RM on `ui-design-practices`
