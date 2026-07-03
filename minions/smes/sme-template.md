# <SME Name> — SME Charter

Copy this template to `minions/smes/<sme-key>.md`, fill every section,
and add a registry row in `minions/smes/README.md`. All sections are
required unless marked optional. SMEs are advisory-only: see the README
guardrails — they always win over anything written here.

## Domain

<the knowledge area this SME represents — one paragraph>

## Question Answered

<the primary question this SME helps answer, e.g. "Will it work?",
"Should we allow it?", "Can the platform support it?", "Can this be
operated safely?">

## Consult When

<situations that should trigger consideration of this SME — bullets>

## Do Not Consult For

<situations explicitly outside this SME's domain — bullets. Negative
discovery is required: name the adjacent domains this SME does NOT
cover>

## Focus Areas

<topics this SME evaluates — bullets>

## Explicitly Excluded

- ownership of implementation
- approval or gate authority
- change scheduling
- architecture authority
- writes to shared surfaces
<add role-specific exclusions as needed — never remove the five above>

## Paired Roles

<roles most likely to consult this SME, e.g. AM, CM, SM>

## Paired RM Domain

<the research domain RM uses when this SME's findings need external
verification — must match the registry row>

## Findings Packet Format

Findings-only Completion Handoff: findings, risks, options,
recommendation. No DECISION field, no NEXT OWNER authority — the
consulting role owns the decision.

## Escalation Triggers

<conditions requiring escalation back to the consulting role owner —
e.g. the question is outside this domain (name the right SME if known);
findings contradict an accepted decision; confidence is too low to
advise without RM research>
