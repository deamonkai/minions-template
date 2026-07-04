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

Rows are downstream content — replace the examples. Live rows belong
below the split-merge delimiter at the end of this file. In coordinator
mode the root matrix routes coordinator-shared-surface and cross-project
policy changes; project lanes keep their own matrix (in the lane or in
the project submodule).

<!-- ================= DOWNSTREAM CONTENT BELOW — template upgrades replace above this line only ================= -->

## Local Matrix (this repo)

| Change type | Required reviewers | Notes |
| --- | --- | --- |
