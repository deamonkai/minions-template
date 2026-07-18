# minions/smes/ — Expertise Layer (SMEs)

This directory holds Subject-Matter Expert charters: advisory expertise
modules that roles consult for domain findings. The template ships this
README, `sme-template.md`, and a default bench of infrastructure SMEs
(above the delimiter) as starters; each downstream repo adds its own SMEs
below the delimiter. An empty downstream section is normal — absence of
downstream-added SMEs never blocks any workflow.

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

Template-default SME rows live in the "Default Bench (template-shipped)"
table below (above the delimiter); downstream-added SME rows go in the
"Local Registry (this repo)" section below the delimiter. The table here
is the schema and example.

| SME | Charter | Domain | Consult when | Do not consult | Paired roles | RM domain | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| _example: Payments SME_ | `payments.md` | payment flows | checkout, refunds, PCI scope | infra sizing, UI copy | AM, CM, SM | payments-vendors | active |

Status values: `active`, `deferred`, `retired` (rows are never deleted).
Coordinator-mode benches may add an advisory `Maturity` column:
`experimental | standard | trusted | authoritative` — a tie-breaker when
SMEs overlap, never a mandatory router, never an override of a matrix
row.

## Growing the bench

The bench is PM-curated, Operator-approved. PM reviews the repo's
expertise needs at each milestone/run start and whenever `DURABLE
LESSONS:` or `feedback.md` entries flag a recurring domain gap — the
same triggers as the capability refresh (MEMORY.md, Capability
Inventory). A gap that warrants a new SME gets a **bench proposal
brief** to the Operator: observed gap with case-law evidence, the
question the SME would answer, Consult When / Do Not Consult For
sketch, expected review-matrix rows, recommended model tier, and the
cost of not having it. Retirement works the same way (consult history +
where the domain's duties land). The Operator approves before anything
is authored.

For the design craft behind a good proposal — the consultable-expertise-
vs-process test, drawing a disjoint domain, tier selection, and the
evidence discipline — see `docs/designing-an-sme.md`. The mechanical
checks (required sections, non-empty negative discovery, a registry row,
launcher parity in every family) are enforced by
`tools/sme-charter-check.sh`; the Governance-Invariant SME reviews a new
charter's domain boundaries as advisory-on-text (not a second gate).

## Adding an SME

Every new SME lands through this checklist — partial deployment is the
known failure mode (a charter with no launchers is invisible to spawned
minions; a launcher with no registry row is invisible to routing):

An SME lands only after a PM bench proposal brief and Operator approval (see Growing the bench).

1. Copy `sme-template.md` to `minions/smes/<key>.md` and fill every
   section (Consult When and Do Not Consult For are required).
2. Add the row to the Local Registry below the split-merge delimiter —
   charter, domain, both summary columns, paired roles, RM domain,
   status `active`.
3. Author launchers in EVERY AI option tree this repo uses —
   `.claude/agents/<key>.md`, `.codex/agents/<key>.toml`,
   `.github/agents/<key>.agent.md` — from the snippets below, bodies
   behaviorally identical per the Instruction-File Audit Rule
   (MEMORY.md). A family that is exported but not yet active carries the
   DEFERRED notice per `docs/downstream-onboarding-playbook.md`.
4. Add `minions/review-matrix.md` rows for any change types this SME
   must review deterministically (optional — discovery covers the rest).
5. **If the SME is private / downstream-only:** add a `do-not-export` row for
   its charter and every launcher to your export manifest. Since 1.34.0 the
   `minions/smes/*.md` and `sme-*` launcher globs are `template-replace`
   (exportable by default), so a private SME rides into a public mirror — and
   into the downstream-onboarding `.minions-template/` snapshot — unless
   excluded (an Export/Privacy concern, not optional if you export). Exclusion
   is operator-enforced at export Step 1: the more-specific `do-not-export` row
   wins over the glob, but there is no automated filter, so apply it
   deliberately. Excluding the FILES is necessary but not sufficient — also
   sweep the SME's key/name as a neutralization token tree-wide (public-export
   runbook Step 2), since a paired-role reference, a `capabilities.md` note, or
   an above-delimiter routing mention can still echo the private name. The
   seed-state reset clears only the below-delimiter Local Registry / Local
   Matrix rows, not the charter/launcher files or any name echo elsewhere.
6. In coordinator mode, bench registry edits go through the coordinator
   seat, with lane packets as the request path.

Removing an SME: set its registry status to `retired` (rows are never
deleted), remove its launchers from every family, and drop its matrix
rows in the same commit.

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

## Default Bench (template-shipped)

Template-owned infrastructure SMEs (generic template plumbing). These ship
with the template and are replaced on upgrade; a downstream may mark any
one `do-not-export` with an explicit manifest row.

| SME | Charter | Domain | Consult when | Do not consult | Paired roles | RM domain | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Governance-Invariant SME | `governance-invariant.md` | governance text & invariants | MEMORY.md/AI.md/entry-point/charter edits, hard-stop & token language | scripts, runbooks, non-governance docs | PM, DM, SM | governance-practices | active |
| Cross-Family Launcher SME | `cross-family-launcher.md` | launcher-family parity | launcher edits, new role/SME, model-pin or tier changes | charter content, governance prose | PM, CM | agent-launcher-conventions | active |
| Export/Privacy SME | `export-privacy.md` | export & privacy filtering | manifest changes, new tracked files, public refresh, feedback.md/AI/ touches | internal-only edits that never export | PM, SM, DM | export-privacy-practices | active |
| Upgrade-Path SME | `upgrade-path.md` | downstream upgrade impact | template-replace shape changes, delimiter moves, version bumps | maintainer-local files | PM, DM | downstream-upgrade-patterns | active |
| Shell/Test-Harness SME | `shell-test-harness.md` | bash/awk guard quality | tools/*.sh or test-guard edits | markdown-only changes | CM, OM | shell-test-patterns | active |
| Skill-Provenance SME | `skill-provenance.md` | external-skill trust | adopt-candidate, wrapper-charter authoring, re-adoption of a newer SHA | framework-native skills, non-skill capabilities | PM, SM, RM | external-skill-provenance | active |

<!-- ================= DOWNSTREAM CONTENT BELOW — template upgrades replace above this line only ================= -->

## Local Registry (this repo)

| SME | Charter | Domain | Consult when | Do not consult | Paired roles | RM domain | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
