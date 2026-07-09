# Model Tiering: Role-to-Capability Guidance

An **optional** guidance layer for which model capability tier should run which
role or activity. It is advisory, not enforced: a downstream pinned to a single
model ignores all of it and loses nothing. This doc is not part of the
governance-scanned invariant set (see `MEMORY.md`) — it is guidance, not a hard
contract.

## Why this exists

The template's premise is role decomposition (`minions/roles/`, the launcher
families, prompt modes). Decomposition by itself does not decompose *cost*: the
path of least resistance is running every role in one strong model, including
work that only needed a clear brief. A field session that onboarded the
template and ran a full milestone in a single frontier-tier orchestrator seat
surfaced exactly that anti-pattern — nearly all of the work was mechanical
(applying a convention across files, tabulating CLI output, drift-diffing,
bookkeeping) and none of it needed frontier reasoning. What it needed was the
role charter's clear brief, run at a cheaper tier.

## Tiers as capability bands, not vendor names

Tiers are **capability bands**. Vendor examples are given for orientation only,
labeled as aging examples — never requirements. A Codex, Copilot, or Claude
adopter maps these bands onto whatever models are currently available to them.

- **Frontier** — the top reasoning tier available. Use for decomposition,
  synthesis, second-order judgment, and gate decisions: cheap to run
  occasionally, expensive to get wrong. (Aging examples: Claude Opus/Fable,
  GPT-5-class, Gemini Ultra-class.)
- **Mid** — a strong, cheap workhorse tier. Use for bounded work under a clear
  charter brief. (Aging examples: Claude Sonnet, GPT-5-mini-class.)
- **Economy** — a fast, cheap execution tier. Use for pure mechanical passes
  against an explicit spec. (Aging examples: Claude Haiku, GPT-5-nano-class.)

## Role / activity → tier map

| Role / activity | Tier | Rationale |
| --- | --- | --- |
| PM orchestrator seat; AM architecture; gate decisions | **Frontier** | Decomposition, synthesis, second-order judgment; cheap to run, expensive to get wrong |
| SM security review; adversarial verify of findings | **Frontier** | The skeptic that kills false findings before they enter the record |
| CM as reviewer / final verifier | **Frontier** | Final-gate correctness check; same reasoning demand as a gate decision |
| CM bounded implementation under a clear charter brief | **Mid** | Spec-driven work; use the pipeline `coder` / `tester` variants (see `docs/minion-prompt-modes.md`) |
| DM runbooks / docs | **Mid** | Bounded documentation work under a clear brief |
| OM production / rollback judgment | **Frontier** | Deploy, rollback, and incident-recovery decisions carry second-order operational stakes — expensive to get wrong |
| OM routine runtime checks | **Mid** | Bounded runtime verification (health checks, "report what is actually running") under a clear charter brief |
| Mechanical passes (bulk edits, index regen, CLI-output tabulation, bookkeeping) | **Economy** | Pure execution against an explicit spec |

**CM splits by activity, not by role name.** CM acting as reviewer or final
verifier carries the same stakes as a gate decision and belongs at Frontier;
CM doing bounded implementation against a clear brief is exactly the "spec
already narrows the search space" case Mid is for. Do not read "CM" as a single
tier — read the activity. **OM splits the same way:** production deploy,
rollback, and incident-recovery decisions carry second-order stakes and belong
at Frontier; routine runtime checks under a clear brief are Mid.

**Why the adversarial-verify line is Frontier, with evidence.** During a
coverage audit in the field session above, the (frontier) orchestrator itself
produced a HIGH-severity "diverged duplicates" finding that was wrong — the
files were byte-identical once a just-added header was excluded, and the
finding came from a sloppy diff. It shipped in a PR and had to be corrected in
the next commit. An independent adversarial-verify pass — a skeptic prompted to
refute, not confirm — is exactly the guard that catches this before it ships,
and it is the cheapest insurance in the stack: a bad finding pollutes the
governance record and the "truth" that later work builds on. That is the case
for keeping the skeptic pass at Frontier even when the rest of a session runs
cheaper.

## Target token profile

The shape to aim for is a **strong-but-occasional orchestrator over
cheap-and-frequent minions** — a Frontier seat making a small number of
high-leverage decisions, surrounded by Mid/Economy minions doing the volume of
bounded execution. The anti-pattern is the inverse: one frontier model doing
everything, including work that only needed a clear brief.

## Escalate-by-session-stakes

A routine, execution-heavy session (bulk edits, refreshes, bookkeeping passes)
can run with a Mid orchestrator end to end. Escalate to a Frontier orchestrator
for sessions with onboarding-scale scope, security review, or architecture
decisions — the moments where a wrong call is expensive and judgment is the
bottleneck, not throughput.

## Advisory, and safe to ignore

None of this is a blocker:

- A downstream pinned to a single model (or a single tier) loses nothing by
  ignoring this doc entirely — there is no code path or gate that depends on
  tier selection.
- Tier hints are advisory metadata on launchers, never an enforced constraint.
- This guidance sits outside the governance-scanned invariant set on purpose
  (see `MEMORY.md`); `tools/tests/governance-consistency.test.sh` does not, and
  should not, check for tier compliance.

## Per-family mechanics

- **All three launcher families carry the same advisory line.** Every role
  launcher in `.github/agents/`, `.codex/agents/`, and `.claude/agents/` gets an
  identical `Recommended tier:` line, per the cross-family sync rule in
  `MEMORY.md`'s Instruction-File Audit Rule (launcher bodies for the same role
  must stay behaviorally identical across families; only genuinely
  tool-specific mechanics may differ). The line is advisory prose, not a
  functional field, so it is safe to add uniformly across families that have no
  native model-selection mechanism.
- **Claude Code's `model:` frontmatter is that family's optional enforcement
  mechanism.** Where Codex and Copilot launchers can only carry the advisory
  line as prose, Claude Code's `.claude/agents/*.md` frontmatter has a real
  `model:` field that pins the tier functionally. The template's Claude
  family ships all seven launchers pinned, and the pin set implements the
  tier map above exactly: six Frontier pins (`pm`, `am`, `cm`, `sm`, `om`,
  `rm` at `model: opus`) and one Mid pin (`dm` at `model: sonnet`). Two of
  the Frontier pins deserve their reasoning spelled out: `cm` pins Frontier
  because its charter bundles final-gate review into the same launcher as
  implementation — the launcher can't distinguish "CM as implementer" from
  "CM as verifier" the way the tier map above does, so it is pinned to the
  higher-stakes activity (bounded implementation moves to Mid via the
  pipeline `coder`/`tester` variants instead). `rm` pins Frontier because it
  is read-only research synthesis feeding decisions elsewhere; its output
  quality has the same second-order-judgment shape as a gate call, at a much
  lower call frequency.
- **Codex and Copilot adopters map bands to their available models.** Neither
  family has a functional per-agent model-pin mechanism today, so their
  launchers carry the `Recommended tier:` line as guidance only; when either
  platform exposes a model-selection field, wire the tier map to it the same
  way Claude's `model:` frontmatter does.

## The effort dial

Model band is one dial; **reasoning effort** is a second, orthogonal one. A
Frontier model at `low` effort and a Mid model at `high` effort are different
cost/quality points, and the least-resistance path spends both at maximum on
every subagent. Claude Code exposes a functional `effort:` frontmatter field
(`low | medium | high | xhigh | max`) that overrides the session effort
whenever that subagent is spawned — the effort analog of `model:`.

The Claude launchers pin effort per the same Frontier/Mid split as the model
map, so the pipeline right-sizes effort **deterministically, regardless of the
session's effort**:

- **Judgment roles → `high`** (`am`, `sm`, `om`, `rm`), with the final-verifier
  `cm` at **`xhigh`** — the documented sweet spot for correctness-critical
  review.
- **`pm` → `medium`.** PM's spawned role is orchestration and routing —
  capable, but it should not run hotter than needed (matching the Codex
  baseline). A genuine hard-gate go/no-go is the main-loop orchestrator seat,
  which uses the session effort, not this launcher's pin.
- **`dm` → `medium`** — bounded documentation work under a clear brief.
- **`/ship` `coder` / `tester` → `low`** — validated (3/3 objective probes, see
  `docs/effort-calibration.md`): these stages always run under a clear AM spec
  with a downstream test + review backstop, so `low` reasons enough to produce
  correct code without paying for effort the pipeline doesn't need. (Correct
  but scruffier than higher tiers — the test/review stages absorb that.)

This makes the "strong-but-occasional orchestrator over cheap-and-frequent
minions" shape hold even in a cheap session: the skeptic and the gate never
drop below high, and bounded execution never runs at max. **Effort is
functional in both Claude and Codex:** Claude uses the `effort:` frontmatter
field; Codex uses each role TOML's `model_reasoning_effort` (see
`.codex/agents/README.md`, "Model And Effort Policy"), and the two agree
role-for-role (`am`/`sm`/`om`/`rm` high, `pm`/`dm` medium, `coder`/`tester` low;
only Claude's `cm` escalates to `xhigh` for the reason above). Copilot has no
per-agent effort field and carries the tier as advisory prose. The task-class
calibration behind the pins, and the local validation discipline, live in
`docs/effort-calibration.md`.
