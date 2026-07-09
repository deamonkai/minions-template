# Effort Calibration (PROTOTYPE)

> **Status: unvalidated prototype (v0), advisory.** Companion to
> `docs/model-tiering.md`. Like that doc, this is guidance, not an enforced
> contract, and it sits **outside** the governance-scanned invariant set
> (`MEMORY.md`) — `tools/tests/governance-consistency.test.sh` does not, and
> should not, check for effort compliance. A downstream pinned to one model at
> one effort loses nothing by ignoring it.
>
> **Idea provenance:** the task-class → minimal-tier calibration pattern here is
> adapted from `nagisanzenin/effortmining` (MIT, `@ fd772f8`), scouted
> 2026-07-09. Only the *idea* is imported — no code, no plugin, no hooks. That
> project's headline claim (−64.7% output tokens at equal quality) is
> **unaudited self-reported benchmark**; treat it as a hypothesis to validate
> locally, never as adopted truth.

## Why this is a separate dial from model-tiering

`docs/model-tiering.md` picks the **model capability band** (Frontier / Mid /
Economy) by role and activity. This doc picks the **reasoning effort** applied
*within* a dispatch — the Agent tool's `effort` parameter
(`low | medium | high | xhigh | max`) and, in workflows, `opts.effort`.

Model band and effort are orthogonal. A Frontier model at `low` effort and a
Mid model at `high` effort are different cost/quality points. The
least-resistance path spends **both** dials at maximum on every subagent; the
lever here is spending high effort only where the task class needs it.

This session is the motivating case: the skill-adoption `/ship` run spawned
~15 subagents (design panel, implement, test, 7-reviewer wave), several at full
Frontier + implicit high effort. Much of that work was bounded and would likely
survive a lower effort tier — but we have not measured it, which is exactly why
this is a prototype, not a rule.

## Task-class → effort (starting hypothesis)

Effort is chosen by **task class**, not by role name — the same
"split-by-activity" principle `model-tiering.md` uses for CM and OM. Classes
adapted from effortmining's T1–T4 / R / C, mapped to this template's work:

| Class | Kind of work | Suggested effort | Our examples |
| --- | --- | --- | --- |
| **T1 — mechanical** | pure execution against an explicit spec | `low` | bulk edits, index/regen, CLI-output tabulation, changelog assembly, manifest-row bookkeeping |
| **T2 — simple transform** | bounded change under a clear brief | `low`–`medium` | apply one convention across files, a single well-specified doc edit |
| **T3 — moderate reasoning** | spec-driven implementation with local judgment | `medium` | the `coder`/`tester` pipeline stages implementing an approved spec |
| **T4 — hard reasoning** | decomposition, synthesis, second-order judgment | `high`–`max` | AM architecture; a hard go/no-go gate; cross-cutting synthesis (the gate moment is the main-loop seat's session effort, not the `medium`-pinned `pm` launcher) |
| **R — research** | external investigation + synthesis feeding a decision | `high` | RM deep-research, provenance/trust reads |
| **C — adversarial / correctness** | skeptic passes that must not miss a real defect | `high`–`max` | SM security review, adversarial verify, CM final-gate review |

The **C** row is the deliberate non-economy line, mirroring model-tiering's
"keep the skeptic at Frontier" evidence: a bad finding pollutes the governance
record, so the refute-pass is the cheapest insurance in the stack — do not
starve it of effort.

## Applying it in a `/ship` run — WIRED (2026-07-09)

The orchestrator (PM) already right-sizes the **model** via the `coder`/`tester`
Mid-tier launchers. The effort dial is now wired the same way: each Claude
launcher carries a pinned `effort:` frontmatter field, so `/ship` picks up the
right effort automatically when it spawns a stage by `subagent_type` — no
per-call argument needed.

Mechanism note: the Agent/Task tool exposes `model` but **no** per-spawn
`effort` override, so effort lives in launcher frontmatter (persistent),
verified supported (`low|medium|high|xhigh|max`). The live pin-set is in
`docs/model-tiering.md` ("The effort dial"): judgment roles `high` (`cm`
`xhigh`), bounded stages `medium`. Per-call effort control is only available
inside the Workflow tool (`opts.effort`) — which is how the validation run
below varied effort on a fixed model.

## Validating before trusting (the blind-grader idea)

effortmining's one genuinely portable discipline is **empirical validation**:
do not assume the cheaper tier is fine — check it. A lightweight local protocol:

1. Pick a recurring, well-specified stage (e.g. a `/ship` implement or a
   mechanical doc pass).
2. Run it at the current effort and at one tier lower on the same input.
3. Have an **independent** minion (a skeptic, not the author) grade whether the
   cheaper output still meets the stage's acceptance criteria — the same
   adversarial-verify posture the review wave already uses.
4. Only lower the standing suggestion for that class if the cheaper tier passes
   repeatedly. Record the evidence; do not port effortmining's −64.7% number.

## Open decisions (for the Operator / a future design pass)

- **Taxonomy granularity** — are six classes right, or should this collapse to
  three (mechanical / bounded / judgment) to match the Frontier/Mid/Economy
  bands 1:1?
- ~~**How far to wire it**~~ — RESOLVED 2026-07-09: wired as pinned effort
  frontmatter (the `model:`-pin pattern) across role, `/ship`-stage, AND the six
  SME launchers, in both Claude (`effort:`) and Codex (`model_reasoning_effort`)
  — Frontier launchers `high`, Mid launchers `medium`. See `docs/model-tiering.md`.
- **Validation harness** — build a small repeatable blind-grader harness, or
  keep validation ad-hoc per stage?

Until those are decided and at least one class is locally validated, this stays
a prototype: consult it as a hint when spawning subagents, not as a rule.

## Validation log

### 2026-07-09 — T3 bounded-implement (SemVer precedence comparator)

First blind-grader run. **Setup:** one effort-sensitive bounded implement task
(a SemVer 2.0.0 precedence comparator) run by three arms at **low / medium /
high** effort, all on the **same** model (Sonnet, the Mid band) so only the
effort dial varied; two independent Opus graders scored the code **blind** to
effort; and a held-out **22-case objective acceptance battery**, run by the
orchestrator, served as ground truth. Executed via a controlled Workflow
(`opts.effort` per arm) since the Agent tool exposes no effort parameter.

**Result:**

- **All three arms passed 22/22** objective cases. **Low effort met the bar** —
  the dial held for this class.
- **Medium ≡ low: byte-identical output.** The low→medium increment bought
  nothing here.
- **High effort added robustness *margin*, not acceptance correctness** — more
  defensive code (`LC_ALL=C` ASCII pin, no `eval`, stricter identifier regex
  rejecting leading-zero pre-release ids), which a harder battery (non-C
  locale, stricter malformed-input rejection) would reward, but no extra pass
  on the stated criteria. Cost scaled with effort: ~46s / 52k tok (low) →
  ~93s / 60k (medium) → ~219s / 72k (high).
- **Meta-finding — blind graders are not ground truth.** The two Opus graders
  disagreed on the high arm; one fabricated a "FATAL `set -u` unbound-variable
  bug" and claimed to have *executed* it. The objective run proved the code
  correct (the grader misread a two-line `local` as one line). **Therefore the
  objective execution backstop is promoted from optional to REQUIRED** for any
  effort-calibration run — independent LLM graders alone can hallucinate both
  bugs and their own "verification."

**Disposition:** one data point, not "repeatedly" — the T3 standing suggestion
stays `medium` for now. Direction: **low is a credible T3 default** for
well-specified, objectively-checkable implement tasks; collect 2–3 more data
points (varied tasks) before lowering the standing suggestion. Note the
confound: an *easy* bounded task compresses the effort dial — the informative
future probes are tasks where the acceptance bar itself is stricter.

### 2026-07-09 (later) — probes 2 & 3, harder tasks

Two deliberately effort-sensitive tasks, same controlled setup (3 effort arms,
same Sonnet model, objective hidden battery as the **sole** arbiter — blind
graders dropped per the meta-finding above):

- **CSV record parser (RFC 4180 quoting** — quoted commas, escaped `""`): low /
  medium / high each **9/9**.
- **Integer arithmetic evaluator** (precedence, parens, unary minus, truncate-
  toward-zero, division-by-zero → exit 2, and must **reject injection** like
  `1;ls` on untrusted input): low / medium / high each **15/15**.

Low effort met the strict bar on both — including the security-sensitive
injection/validation case. One quality blemish: the CSV low arm appended a
stray `</script>` tag (harmless dead code after `exit 0`) — **low is
correct-but-scruffier**, which the `/ship` test + review stages absorb.

**Disposition (updated):** three probes, low passed every one — that clears the
"passes repeatedly" bar. **The `/ship` `coder` and `tester` stages are lowered
to `effort: low`** (both families), because they always run under a clear AM
spec with a downstream test + review backstop. Scope is deliberate: this lowers
the *pipeline stages*, not the abstract T3 class — ambiguous or unspecified T3
work still warrants `medium`. Revert to `medium` if `low` coder/tester output
starts failing the test/review gates in practice.
