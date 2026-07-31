# PM Judgment Model

Every other rule in this template tells an agent what it **may not do**:
hard-stops, lane boundaries, gate criteria, single-writer durability. This
document covers the part none of them address — **how to tell what kind of
problem you are looking at**, and **how to tell whether a returned packet is
actually done**.

Two forcing functions, both bound to steps that are already mandatory rather
than added as new rituals:

1. **Landscape routing** — a dispatch brief for multi-step work names its
   quadrant, and the quadrant selects the stage chain.
2. **The creep check** — before consolidating a returned packet, the single
   writer tests two specific failure modes by name.

Binding statements live in `MEMORY.md` (Execution Quality, and the Completion
Handoff Contract). `minions/roles/PM.md` carries the charter duty. This file is
the detail those three pointers refer to.

## Part 1 — Landscape routing

### The two axes

Classify work on two independent questions:

- **Goal clarity** — do we know what "done" looks like, in terms someone could
  check? Not "do we know how", just *what*.
- **Solution clarity** — do we know the approach? Not in full detail, but well
  enough that an implementer would not have to invent the design.

These are genuinely independent, which is the whole reason the model earns its
place. The intuitive assumption is that a clear goal implies a clear solution;
the expensive cases are exactly the ones where it does not.

### The routing map

|  | **Clear solution** | **Unclear solution** |
| --- | --- | --- |
| **Clear goal** | Dispatch the implementer directly. | **Architecture spec first** (AM), then implement. |
| **Unclear goal** | Return to the Operator — goal-setting is theirs. | Research first (RM, recommend-only). No implementation dispatch. |

**Exemption:** single-step consults — one SME **or** RM question, one read — are
exempt, matching the carve-out in `MEMORY.md`'s Workflow Ownership rule. This
model targets workflows, not every dispatch. Note the "or": three steps that
each look like a consult are still a workflow.

### Why the declaration is load-bearing and not a box-tick

The quadrant *selects the routing*, so a wrong declaration produces visibly
wrong routing. A brief that claims "clear goal, clear solution" and then
dispatches an architecture spec is self-contradicting on its face — the
mismatch is the signal. A brief that declares a quadrant nobody can defend
after the fact is reviewable evidence, not a checkbox.

This is also why the declaration rides the dispatch-brief field list next to
the model-tier and reasoning-effort declaration instead of getting its own
ceremony. The brief already has a mandatory field list; this is one more field
on it.

### The unclear/unclear cell is not an execution path

That cell routes to RM for **research only**. RM's findings return through PM,
who decides and dispatches implementation as a separate step. RM never hands
work directly to an implementer.

This is a security boundary, not a bureaucratic one. RM is the role *chartered*
to ingest untrusted external content — web pages, vendor documentation,
third-party repositories — and the one whose launchers are pinned read-only for
that reason. If RM could act on what it reads, a prompt injection in a scouted
page becomes an action in the repo. The separation is what keeps "read the
internet" and "change the codebase" in different hands.

**State the limit precisely, because the containment is narrower than it looks.**
RM being pinned does not mean untrusted content reaches only RM: in the Claude
family every other role has unrestricted tools including `WebFetch`/`WebSearch`,
so any role *can* ingest a web page. What RM's pin buys is that the role we
deliberately point at untrusted sources cannot write. Roles holding write and
execute tools are contained by charter and review, not by a tool whitelist — so a
change that gives another role a standing web-research posture needs its own
boundary rather than an assumption that this one covers it.

The pin is enforced in the launchers, and an implementation of this model must
not weaken it. In the Claude family RM is the only launcher carrying a `tools:`
restriction at all:

- **Claude** pins `Read, Grep, Glob, WebSearch, WebFetch, Skill(deep-research)`.
  The `Skill(...)` grant is deliberately scoped to one research skill rather
  than a blanket `Skill` grant, so RM cannot reach a file-writing skill.
- **Copilot** pins `[read, search, todo]`. Note that in this family *every*
  launcher pins `tools:` — the other roles get `edit`, and `cm`/`om`/`coder`/
  `tester` also get `execute`. RM is distinguished here by the absence of
  `edit`, not by being the only restricted launcher.
- **Codex** has no tool-restriction field, so there the prohibition is binding
  prose only. Its launcher states that limitation explicitly rather than
  implying parity it cannot enforce.

Any change touching RM's launchers is a launcher-family edit and adds the
Cross-Family Launcher SME to review routing.

### The unclear-goal branch is not a fourth hard-stop

This repo counts hard-stops precisely, and the count is unchanged by this
document. The enumeration itself lives in `MEMORY.md` (Collaboration Model) and
`AI.md` (Role Agents) — read it there, not here.

This file deliberately does **not** restate it. A governance enumeration copied
into one more surface is one more place for it to drift, and the asymmetry makes
that worse than usual: this file is `template-replace` and propagates to every
downstream on upgrade, while `MEMORY.md` is `manual-merge` and does not. A
drifted copy here would reach downstreams that never took the corresponding law.
The same reasoning is why skills-vendoring is framed as an *instance* of an
existing hard-stop rather than a new one — the count is load-bearing, so it is
kept in as few places as possible.

Declining to dispatch un-scoped work is not an Operator interrupt — it is PM
doing what its charter already says: "translate operator concerns into plans,
gates, and acceptance criteria." Un-scoped work goes back for scoping through
the normal conversational path, not through a hard-stop.

### Worked example 1 — clear goal, unclear solution

**v1.46.0, item A2 (the seed-only marker gate).** The goal was checkable: the
export gate should be able to distinguish "a seed-only file was reset
correctly" from "it never had a marker in the first place". The solution was
not obvious — it turned into a two-legged invariant (Leg S asserting the source
carries the marker, Leg E asserting no marker survives in the export tree),
which is not a design an implementer would land by feel.

An architecture spec came first, then implementation. (The spec is
maintainer-local — it lives under `docs/superpowers/`, which is `do-not-export`,
so the path will not resolve in a downstream or public-mirror clone. Named here
for the maintainer checkout only.) That was the right sequence, and it is what happened.

It is also the case that motivated this model: **the sequence was chosen by
instinct, because the Operator asked for it.** Nothing in the repo would have
produced it deterministically, and nothing would have flagged its absence. The
routing map is the deterministic version of a call that previously depended on
someone feeling it.

### Worked example 2 — unclear goal, clear solution

**The deferred archive-reporter automation.** The solution was unusually
well-specified: a v3 design document, three review rounds, and
SHIP-WITH-CONDITIONS verdicts from both SM and the Shell/Test-Harness SME. By
any solution-clarity measure it was ready.

It was still not dispatched, and correctly so. The *goal* was unvalidated: AM's
durability concern was that closure-marking has no forcing function, so the
automated sweep's yield could trend to zero — automating a process that
produces nothing. The work is now evidence-gated: build it only if the
read-only reporter demonstrates over two or more milestones that units actually
accumulate *and* get marked `Status: CLOSED` (`TODO.md`, owner PM, re-open on
evidence).

The lesson this example carries: **a fully-specified solution is not a licence
to build.** Solution clarity is the horizontal axis only. A ready design with
an unvalidated goal sits in the "return to the Operator" cell, and the right
output is an evidence gate rather than a dispatch.

## Part 2 — The creep check at consolidation

Bound to the consolidation step the single writer already performs for
`DURABLE LESSONS:` and `SOLE-HOLDER:` items. Before relaying or consolidating a
returned packet, the writer tests two questions.

### Hope Creep

**Is success claimed on evidence that survives inspection, or on the claim
itself?**

*Case law, v1.46.0:* a test fixture reported green because the script under
test **crashed**, and the crash exited 1 — which happened to be the exit code
the fixture expected. The suite reported 37/37 passing. Three
required-to-fail fixtures were passing on a crash, and the guard they were
supposed to be proving was a silent no-op on the target shell.

The tell: the evidence and the claim were the same object. "Exit code 1" was
treated as "the check fired", when it equally meant "the script died before the
check ran". The check for Hope Creep is to ask what *else* would produce this
exact evidence.

### Effort Creep

**Is "done" proven by something that would fail if it were not done?**

*Case law, v1.46.0:* a guard was correct in code but unproven by any test —
reverting the fix changed no observable output. The work was real and the code
was right; nothing demonstrated it.

The tell: the deliverable exists but nothing distinguishes the world with it
from the world without it. The check is the mutation question — if I undid this,
what would go red?

### Scope Creep and Feature Creep

Named here so the taxonomy is complete, and pointed at the existing rule rather
than duplicated: **scope expansion is flagged explicitly, and the work proceeds
with the smallest change** (`MEMORY.md`, Common Guardrails and the Autonomous
orchestration posture). It is not a hard-stop.

Duplicating those two here is what would turn a two-question check into a
four-item rubber stamp. Two questions that require thought beat four that
invite skimming.

## Known limit — stated, not implied

**No guard can verify that the judgment was real.**

A dispatch brief may declare "clear/clear" thoughtlessly and pass every
mechanical check. The creep check may be performed as a formality. The
governance token check proves the *rule is present in `MEMORY.md`*; it never
proves the rule was *applied*.

This limit is recorded here rather than left for a reviewer to discover,
because the v1.46.0 milestone established exactly this discipline: a green
check covering the wrong property is worse than no check, because it
manufactures confidence. That honesty applies to a rule that cannot be
mechanically enforced just as much as to a test fixture. The mitigations are
the ones already in the repo — reviewable briefs, matrix-routed SME review, and
the fact that a mis-declared quadrant produces visibly wrong routing.

## Attribution

The two axes and the four-quadrant landscape are Robert Wysocki's Project
Landscape model. The creep taxonomy — including the terms *hope creep* and
*effort creep* — is also associated with Wysocki's project-management writing
rather than with PMBOK; PMBOK addresses scope creep but does not use those two
terms. [Likely — asserted from secondary familiarity, not verified against a
primary source. An earlier draft of this file credited the creep taxonomy to
PMI/PMBOK, which is probably wrong; if you are verifying attributions, verify
this one, and route it to RM on the `governance-practices` domain rather than
correcting it from memory.]

These are widely-taught frameworks and the taxonomy *names* are the only borrowed
surface. The prose, the routing map's bindings to this repo's roles and gates,
the worked examples, and the security rationale for the unclear/unclear cell are
original to this template.

## Scope of this phase

**Shipped (phase 1 — routing judgment):** the landscape matrix as a dispatch
routing map, and the Hope/Effort creep check at consolidation.

**Deliberately deferred (phase 2):** the expanded Scope Triangle as
Operator-facing trade-off vocabulary. Routing was chosen first; the advisory
half earns its place once routing has proven itself. It is not stubbed here on
purpose — a stub would imply a commitment that has not been made.

**Rejected, recorded so they are not re-litigated:**

| Rejected | Why |
| --- | --- |
| Intake mode-selection that prompts the human per task | Contradicts the autonomous posture; adds an Operator interrupt per task. |
| EVM / CPI / SPI | Requires cost and effort baselines this repo does not track. Cargo-cult metrics. |
| Waterfall/Agile/Hybrid methodology selection | A second lifecycle competing with `feature → dev → staging → main` and `/ship`. |
| Planning-time rules of thumb measured in days | Calibrated for human teams; meaningless at agent speed. |
| Prescribed communication-style profiles | `MEMORY.md`'s no-filler rules and the `[Certain]`/`[Likely]`/`[Guessing]` tags are sharper. |

Design record: the milestone's approved spec, maintainer-local under
`docs/superpowers/` (`do-not-export` — the path resolves in the template
maintainer's checkout only, not in a downstream or public-mirror clone).
