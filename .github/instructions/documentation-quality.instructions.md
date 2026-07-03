---
applyTo: "submodules/**/{README.md,CONTRIBUTING.md,ARCHITECTURE.md,docs/**/*.md}"
description: "Documentation quality checklist for DM updates: source-verified, professional style, and diagram usage when it improves clarity."
---

# Documentation Quality Checklist

Use this checklist for Documentation Manager updates in project submodules.
Replace `<project-key>` below with the target submodule's directory name (the
path segment under `submodules/`).

## Accuracy First

- Verify every behavior claim against source truth in `submodules/<project-key>/`.
- If behavior is unclear, stop and open a gap packet in `minions/mail/` (flag the
  unverifiable behavior and name the next owner). Do not infer.
- Avoid future-state language unless explicitly marked as planned.

## Scope and Ownership

- Update doc-layer files only: `README.md`, `docs/**`, and other prose documentation `*.md` files (guides, ADRs, runbooks).
- Do not edit code/config/tests/CI or inline code comments.
- `CHANGELOG.md` remains PM-owned.

## Professional Style

- Use concise, professional language and consistent terminology.
- Prefer short sections, clear headings, and actionable steps.
- Keep instructions deterministic: command, expected result, failure interpretation.

## Visuals: Charts and Diagrams

Use visuals when they materially improve understanding:

- Architecture boundaries and trust zones
- Data flow and integration sequences
- Deployment/recovery paths
- Incident triage/decision flow

Rules for visuals:

- Choose simple, readable diagrams over decorative graphics.
- Keep labels explicit and aligned to source terminology.
- Add a short caption: what the diagram explains and when to use it.
- If uncertain, prefer a table over an ambiguous chart.

## Quality Gate Before Handoff

- Files changed are listed in the DM packet.
- Trigger source is stated (`cm-handoff`, `operator-request`, or `pm-packet`).
- Gaps are either resolved or explicitly listed.
- Next owner and exact action needed are clearly stated.
