# minions/smes/ — Expertise Layer (SMEs)

Downstream-owned. This directory holds Subject-Matter Expert charters:
advisory expertise modules that roles consult for domain findings. The
template ships this README and `sme-template.md` as starters; each
downstream repo authors and owns its own SMEs. An empty bench is normal —
absence of SMEs never blocks any workflow.

## Class, not role

An SME is a **class, not a role**. Roles own work; SMEs advise it.

- SMEs are recommend-only (the RM precedent): they never merge, gate,
  approve, schedule, or write shared surfaces.
- SMEs never appear in the MEMORY.md Collaboration Model roster or the
  AI.md Role Agents list.
- Consulting an SME never substitutes for a charter-required role
  review. The review matrix (`minions/review-matrix.md`) adds reviewers;
  it never removes them.
- These guardrails are also what make the coordinator-mode shared bench
  lane-safe (see below): weaken the advisory posture and you break lane
  isolation with it.

## SME vs RM

- **SME** — standing domain judgment applied to a change: "will it
  work?", "should we allow it?", "can the platform support it?".
- **RM** — external investigation of what nobody in the room knows:
  vendor docs, option research, fresh angles.

Both advise; neither decides. SME findings that need external
verification route to RM via the paired research domain in the registry.

## Discovery (Consult When / Do Not Consult For)

Discovery must need no tribal knowledge. Every SME charter carries two
required sections:

- **Consult When** — situations that make this SME a candidate.
- **Do Not Consult For** — situations explicitly outside its domain.

The negative-discovery principle: an SME describes both what it knows
and what it does not. That is what keeps overlapping domains disjoint
and prevents expertise creep. Two failure modes this exists to prevent:
consulting every SME for everything, and consulting none because
discovery is unclear.

Precedence: `minions/review-matrix.md` rows are the deterministic path
and always win — a matrix-required reviewer stays required even if its
own charter's Do Not Consult For appears to exclude the change (explicit
routing beats self-description; such a disagreement is registry-hygiene
drift and a review finding). The discovery sections govern selection
only when no matrix row matches.

## Registry

Keep every SME listed here. Summary columns are a few keywords each,
distilled from the charter, so an orchestrator selects candidates
without opening every charter.

| SME | Charter | Domain | Consult when | Do not consult | Paired roles | RM domain | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| _example: Payments SME_ | `payments.md` | payment flows | checkout, refunds, PCI scope | infra sizing, UI copy | AM, CM, SM | payments-vendors | active |

Status values: `active`, `deferred`, `retired` (rows are never deleted).
Coordinator-mode benches may add an advisory `Maturity` column:
`experimental | standard | trusted | authoritative` — a tie-breaker when
SMEs overlap, never a mandatory router, never an override of a matrix
row.

## Consulting an SME

- **Launcher path:** author a thin launcher per family, pointing at the
  charter — the same pattern as role launchers:
  - `.claude/agents/<sme>.md` — frontmatter `name`, `description`
    ("<SME name> for advisory domain findings; recommend-only"), body:
    "You are the <SME name>. Read `minions/smes/<sme>.md` and follow it
    exactly. You advise; you do not own, gate, approve, or write shared
    surfaces."
  - `.codex/agents/<sme>.toml` and `.github/agents/<sme>.agent.md` —
    same body text, family-native config.
- **Prompt-only fallback (toolless environments):** point any session at
  the charter: "Act as the <SME name> per `minions/smes/<sme>.md`.
  Advisory posture: findings only." Never assume subagent support.

## Findings packet (the SME return)

An SME returns a Completion Handoff packet in **findings-only posture**:
findings, risks, options, recommendation — no DECISION field, no NEXT
OWNER authority. The consulting role owns the decision and distributes
the SME verdict verbatim per the verdict-distribution law (MEMORY.md,
Execution Quality).

## Coordinator mode

In coordinator mode (`docs/coordinator-mode.md`), the coordinator repo's
`minions/smes/` is the shared expertise bench: any project lane may
consult any registered SME. This is lane-safe by construction — SMEs
write no shared surfaces, and findings packets return to the consulting
lane's own packet surfaces. The registry itself is a coordinator-shared
surface: edits go through the coordinator seat per the single-writer
law, with lane packets as the request path. Project-local SMEs may live
in `projects/<key>/smes/` under the same protocol, consultable only
within that lane; for that project's context the local registry outranks
the shared bench (the root-vs-project MEMORY.md split rule, applied to
expertise).
