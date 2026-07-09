# minions/review-matrix.md — Review Routing

Downstream-owned. Maps change types to the reviewers (roles and/or SMEs)
a change of that type must receive, giving the orchestrator
deterministic review routing. The template ships this starter with
generic example rows; each repo fills and owns its own matrix.

Absence is a silent no-op: no matrix — or no row matching a change —
means charter-default routing (the role charters and the branching
model's stage gates). The matrix only ever ADDS reviewers; it never
removes or substitutes a charter-required role review.

Precedence: matrix rows are deterministic and always win over SME
discovery metadata — a required reviewer stays required even if its
charter's Do Not Consult For appears to exclude the change. Such a
disagreement is registry-hygiene drift and a review finding. When no row
matches, SME selection falls to the Consult When / Do Not Consult For
sections (see `minions/smes/README.md`).

Skipping a matrix-required reviewer on a matching change is a review
finding (MEMORY.md, Execution Quality).

## Matrix

| Change type | Required reviewers | Notes |
| --- | --- | --- |
| _example: auth or access-control change_ | SM | charter-default made explicit |
| _example: infra provisioning change_ | Infra SME, SM | SME advises; SM reviews |
| _example: production migration_ | AM, SM, OM | packet precedent |

The rows above are illustrative examples. Template-default routing lives in
the "Default Matrix (template-shipped)" section (above the delimiter, ships and
upgrades with the template); downstream-added routing goes in the "Local Matrix
(this repo)" section below the delimiter. In coordinator
mode the root matrix routes coordinator-shared-surface and cross-project
policy changes; project lanes keep their own matrix (in the lane or in
the project submodule).

## Default Matrix (template-shipped)

Template-owned routing for the default infrastructure SME bench (generic
template plumbing). These ship with the template and are replaced on
upgrade.

| Change type | Required reviewers | Notes |
| --- | --- | --- |
| governance-file edit (MEMORY.md, AI.md, entry points, charters) | Governance-Invariant SME | on top of charter-default review |
| launcher-family edit (any `.claude/agents/`, `.codex/agents/`, `.github/agents/` file) | Cross-Family Launcher SME | parity per Instruction-File Audit Rule |
| manifest / export / public-mirror change | Export/Privacy SME, Upgrade-Path SME | guards irreversible publishes |
| template-replace file shape change; version bump | Upgrade-Path SME | required-changes impact |
| `tools/*.sh` or test-guard edit | Shell/Test-Harness SME | guard-quality review |
| skill adopt-candidate (external skill into `skills/vendored/`) | Skill-Provenance SME, Shell/Test-Harness SME, SM, Export/Privacy SME, Governance-Invariant SME | PM convenes and routes the panel; Skill-Provenance SME synthesizes the returned findings; RM supplies `external-skill-provenance` provenance; PM decides, Operator approves |
| adopted-skill wrapper-charter authoring (framework-native wrapper text) | Governance-Invariant SME, Skill-Provenance SME | Gov-Invariant reviews the framework-authored wrapper prose (advisory-on-text); Skill-Provenance confirms it neutralizes the upstream injection surface; a role writes the wrapper with `WRITTEN-BY:` attribution |

<!-- ================= DOWNSTREAM CONTENT BELOW — template upgrades replace above this line only ================= -->

## Local Matrix (this repo)

| Change type | Required reviewers | Notes |
| --- | --- | --- |
