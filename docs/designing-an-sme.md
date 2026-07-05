# Designing an SME

This is the **design craft** for adding a Subject-Matter Expert to the bench —
the judgment that precedes the mechanics. The deployment steps (copy the
template, add the registry row, land launchers in every family) live in
`minions/smes/README.md` → "Adding an SME"; the mechanical checks are enforced
by `tools/sme-charter-check.sh`. This guide is about the part a checklist and a
linter cannot decide for you: **whether the SME should exist, and where its
domain begins and ends.**

Ownership: the PM curates the bench and frames the proposal brief; the Operator
approves before anything is authored (`minions/smes/README.md` → "Growing the
bench"). This guide is PM-facing reference, not a gate.

## First test: is this consultable expertise, or owned process?

The single most important filter, and the one that has already excluded a
proposed SME (the Release-Train SME, v1.28.0):

> **Gate mechanics and framework process are PM ownership, not consultable
> expertise.**

An SME advises on a **change to a domain**. If the "expertise" is really *how
the framework runs itself* — how releases gate, how the bench grows, how work is
routed — it is process the PM owns, and dressing it as an advisory seat only
blurs the "roles own; SMEs advise" boundary. Ask: *does this answer "will this
change work / should we allow it / can the platform support it?" about a
technical surface?* If instead it answers "how should we run our own process?",
it is not an SME.

Corollary — **do not build an SME whose domain is the bench itself.** A member
whose job is designing members is recursive (its own charter would be reviewed
by the governance SME it also judges) and its domain is the union of existing
SMEs plus this guide. That craft belongs here, in a guide, not in a seat.

## Second test: SME vs RM vs role

- **Role** answers *"who owns the work?"* — a standing responsibility with a lane.
- **SME** answers *"who can advise on this work?"* — standing **domain judgment**,
  recommend-only, no gates, no shared-surface writes.
- **RM** answers *"what does the outside world say?"* — one-shot external
  investigation, vendor-doc-grounded, not standing judgment.

If the need is a durable responsibility → it is a role's duty. If it is
one-time external research → route to RM (and pair the SME with an RM domain for
findings that need verification). Only a *standing, internal, domain-specific
judgment* is an SME.

## Evidence discipline

The five canonical SMEs were derived from **22 releases of failure-class
history** — each charter carries named case law. A proposal brief *requires*
"observed gap with case-law evidence" and "cost of absence." Do not add an SME
on a hunch that a domain *might* need one: a speculative SME is precisely the
consult-everyone drift the negative-discovery rule guards against, and it
weakens the evidence gate that makes the whole bench trustworthy. No failure
history for the domain yet → capture the concern in `feedback.md` / `DURABLE
LESSONS:` and let it accumulate.

## Drawing the domain (Consult When / Do Not Consult For)

A well-designed SME has a **disjoint** domain — its boundary must not bleed into
a sibling's.

- **Consult When** — the situations that make this SME a *candidate*. Concrete
  change types (file classes, operations, review triggers), not vibes. This is
  what lets an orchestrator identify the SME without tribal knowledge.
- **Do Not Consult For** — mandatory **negative discovery**. It must name the
  *actual adjacent domains* that are someone else's (e.g. "governance prose →
  Governance-Invariant; launcher parity → Cross-Family Launcher"). If you cannot
  write a Do Not Consult For that stays disjoint from the existing bench without
  gutting a neighbour, the domain does not exist as a separate seat — fold it
  into the neighbour or drop it.

Overlap is a **review-matrix precedence** question, not a free-for-all: a
matrix-required reviewer always wins over discovery metadata, and an apparent
contradiction is registry-hygiene drift and a review finding.

## Tier selection

Tier follows the **judgment-vs-mechanical** split (`docs/model-tiering.md`):

- **Frontier** — irreversible or governance-critical judgment (export/privacy,
  governance-invariant, upgrade-path: a wrong call ships to `main` or a public
  mirror).
- **Mid** — bounded comparison or mechanical analysis (cross-family launcher
  parity, shell/test-harness guard quality).

State the tier and the one-line reason; the Claude family carries a functional
`model:` pin, the other families carry the advisory `Recommended tier:` line
(prose-only by design).

## Before you propose — run the checks

- **Mechanical:** `bash tools/sme-charter-check.sh` — required sections present,
  negative discovery non-empty, a Local Registry row, launchers in all three
  families. Deterministic; catches partial deployment.
- **Design review:** the **Governance-Invariant SME** reviews a newly-authored
  or materially-revised charter's *text* — domain-boundary disjointness, overlap
  with the existing bench, registry-row hygiene, and Escalation Triggers
  section completeness. This is advisory on the text; it does **not** decide
  whether the SME exists (that is the PM bench loop + Operator).

## Summary — the questions a proposal brief must answer

1. Is this consultable domain expertise, or PM-owned process? (If process → stop.)
2. Is it a standing internal judgment, or a role duty / RM investigation?
3. What failure-class evidence and cost-of-absence justify it *now*?
4. Can its Do Not Consult For stay disjoint from every existing SME?
5. What tier, and why (judgment vs mechanical)?
6. Do the mechanical checks pass, and has Governance-Invariant reviewed the
   boundary?
