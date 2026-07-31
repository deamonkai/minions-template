# DESIGN.md — design standards

Required companion to the Design/UX Reviewer SME (`minions/smes/design-ux.md`):
the Design/UX SME reviews UI changes against this file and flags drift.
**Maintained by:** downstream owner (design-decision docs → DM doc-sync).
Update this file in the same change set that alters tokens/components.

## Design tokens

Fill from the project's actual token source (CSS vars / theme config / Figma).

- **Color** — semantic roles, not raw hues: `bg`, `surface`, `fg`,
  `fg-muted`, `primary`, `accent`, `border`, and semantic `success` / `warning`
  / `danger` / `info`. List each token + its light and dark value.
  `<name: #light / #dark>`
- **Spacing scale** — `<4 8 12 16 24 32 48 64 …>` (px or rem); state whether
  arbitrary values are allowed (usually no).
- **Radius** — `<sm / md / lg / full>` = `<values>`.
- **Elevation / shadow** — `<levels + values>`.
- **Z-index scale** — `<named layers: base, dropdown, sticky, overlay, modal,
  toast>`.

## Typography

- **Families** — `<display / body / mono>` + fallbacks.
- **Scale** — named sizes + px/rem + line-height: `<xs sm base lg xl 2xl …>`.
- **Weights** — `<regular / medium / semibold / bold>` and where each is used.
- **Rules** — max line length, truncation/wrapping policy, min body size.

## Layout & responsive

- **Grid / container** — `<max width, columns, gutter>`.
- **Breakpoints** — `<sm md lg xl>` = `<px>`; mobile-first or not.
- **Density** — default spacing rhythm, any compact mode.

## Accessibility targets (hard standards — a "block" if failed)

- **Conformance level** — `<WCAG 2.1 AA / AAA>`.
- **Contrast minimums** — text `<4.5:1>`, large text/UI `<3:1>`.
- **Focus** — visible focus indicator required on all interactive elements;
  focus order follows visual order; no focus traps.
- **Keyboard** — every interactive element operable by keyboard; documented
  shortcuts.
- **Motion** — honor `prefers-reduced-motion`; no essential info conveyed by
  motion/color alone.
- **Semantics** — semantic HTML first; ARIA only to fill genuine gaps; label
  every control; alt text on meaningful images.

## Component standards

For each shared component, the required **states** and **variants**:

- **Required states (every interactive component):** default, hover, focus,
  active, disabled, loading, and where applicable empty / error / selected.
- **Variants** — `<size(s), tone(s), density>` per component.
- **Do / Don't** — `<per-component conventions: button hierarchy, input
  validation display, modal dismissal, toast timing, etc.>`

## Theming

- **Light / dark** — both required; all color via tokens (no hardcoded hex in
  components). State how the theme is applied (`data-theme` / class / media
  query) and the switching mechanism.

## Motion & interaction

- **Durations / easing** — `<standard transition ms + easing curve>`.
- **Patterns** — `<loading skeletons vs spinners, optimistic UI, transition
  conventions>`; all gated behind `prefers-reduced-motion`.

## Content in UI (light — copy TRUTH stays DM's)

- **Voice/tone for microcopy** — `<terse? sentence case? …>` (the SME checks
  UI-fit — length, truncation, empty/error phrasing shape — not factual
  correctness, which is DM's).

## Review rubric (how the Design/UX SME uses this file)

- **ship** — meets the standards above; consistent with tokens; a11y targets met.
- **iterate** — off-system or incomplete states, but the approach is sound; fix
  before merge.
- **block** — violates a hard standard: fails the WCAG target, breaks a theme,
  or introduces off-token values with no justification.

