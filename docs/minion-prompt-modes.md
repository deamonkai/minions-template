# Minion Prompt Modes

This document turns operator prompt shortcuts into durable minion behavior.

Use these modes to sharpen the current role's posture. Modes do not change role
ownership, bypass handoff order, or override `MEMORY.md`.

## Ground Rules

- Role boundaries still apply. A mode changes posture and output shape, not who
  owns the work.
- Do not start with empty agreement. If an assumption is weak, surface the gap,
  missing evidence, or clarifying question first.
- Use confidence tags for consequential claims:
  - `[Certain]` when backed by direct evidence in repo, logs, tests, runtime, or
    an authoritative source.
  - `[Likely]` when the claim is a strong inference from partial evidence.
  - `[Guessing]` when filling gaps. If most of the answer is guessing, say that
    before the rest of the response.
- Avoid filler openers such as "great question", "you're absolutely right",
  "that makes sense", "absolutely", and "definitely".
- Keep claims tied to evidence, impact, and next action.
- For small requests, keep the mode lightweight. Do not expand a one-line task
  into a full process unless the risk justifies it.

## Prompt Formula

When the Operator asks a minion to use a mode, interpret the request with this
formula:

1. `ROLE`: which minion is active and what posture should it take?
2. `CONTEXT`: what repo, system, incident, goal, constraints, or prior packet
   matters?
3. `TASK`: what decision, artifact, review, fix, or verification is requested?
4. `CONSTRAINTS`: what must not change, what risk is unacceptable, and what
   role boundaries apply?
5. `EVIDENCE`: what files, commands, tests, logs, runtime checks, or sources
   must support the answer?
6. `FORMAT`: what output should the Operator or next minion receive?

## General Shortcuts

| Shortcut | Use When | Expected Output |
| --- | --- | --- |
| `/brief` | The Operator needs the shortest useful answer | Decision, evidence, next action |
| `/challenge` | Assumptions may be weak or scope is drifting | Missing assumptions, risk, better framing |
| `/scout` | Looking for risks, blind spots, edge cases, or hidden work | Risk list with severity and owner |
| `/critique` | Reviewing a plan, packet, code path, or design | Findings-first review with evidence |
| `/compare` | Choosing between approaches | Side-by-side tradeoff table and recommendation |
| `/explain` | The Operator needs a clear explanation | Plain-language model, evidence, caveats |
| `/teacher` | The Operator wants guided learning | Concept, examples, checks for understanding |
| `/10x` | Text or plan needs to be sharper | Rewritten version plus material changes |
| `/pitch` | A stakeholder/client summary is needed | Short pitch, value, risk, ask |
| `/artifact` | The answer should become durable repo state | File path, content, verification |
| `/feedback` | Closing a session; capture what was learned about the Operator | Dated `feedback.md` entries (corrections, preferences, do-differently) plus which are durable enough to promote and where |

## Engineering Modes

| Mode | Default Owner | Use When | Required Output |
| --- | --- | --- | --- |
| `/startup-team` | PM | A request spans product, architecture, security, build, docs, and runtime | PM packet plan assigning AM, SM, CM, DM, and OM work |
| `/codebase-audit` | CM with AM as needed | Reviewing unfamiliar code for quality, structure, and maintainability | Architecture map, findings, refactor strategy, tests or evidence |
| `/debug` | CM with OM evidence when runtime is involved | Investigating a bug, regression, incident, or failing check | Reproduction, root cause, edge cases, fix path, verification |
| `/performance` | CM with OM runtime evidence when relevant | Reducing latency, memory, render cost, or scaling pressure | Bottleneck evidence, optimization plan, code changes, measurement |
| `/refactor` | AM then CM | Cleaning messy code without changing behavior | Design constraints, migration steps, behavior-preserving verification |
| `/backend` | AM | Designing service, API, data, queue, cache, or integration architecture | System architecture, data flow, interfaces, operational constraints |
| `/frontend` | CM with AM input for component architecture | Building or reviewing production UI | Component model, states, accessibility, responsiveness, implementation |
| `/tech-lead` | PM or AM | Long-term maintainability, team workflow, or cross-role tradeoffs matter | Decisions, tradeoffs, owner assignments, acceptance criteria |
| `/security` | SM | Auditing security posture or reviewing risk-sensitive changes | Findings, severity, reachability, attack scenario, fix criteria |
| `/docs` | DM | Creating, auditing, or repairing documentation | Doc map, findings, updated docs, doc-sync evidence |
| `/runbook` | DM with OM evidence when runtime is involved | Creating or validating operator procedures | Prerequisites, procedure, verification, rollback, escalation |
| `/devops` | OM | Preparing deployment, CI/CD, monitoring, rollback, or reliability work | Deployment architecture, workflow, health checks, rollback plan |
| `/research` | RM | An issue or unknown needs in-depth, vendor-documentation-grounded research before a decision | Issue framing, vendor-doc findings, corroborating evidence, ranked options with tradeoffs, recommended next step, sources |
| `/ship` | PM (orchestrator) | A bounded feature should run the automated plan → implement → test → review pipeline end to end | Stage chain (AM spec, CM changes, CM tests, optional SM, read-only CM verdict), gates, one durable artifact, no merge — see Pipeline Mode below |
| `/handoff` | PM (orchestrator seat) | The session is ending, compaction is near, or the Operator is handing off with work in flight | Flush of all durability obligations, then one self-contained snapshot in `minions/handoffs/` committed on the active branch; deleted on pickup — see Handoff Mode below |

## Role Mapping

### PM

Use PM for `/startup-team`, `/tech-lead`, `/challenge`, `/brief`, and `/pitch`.
PM decomposes broad requests into packets and gates. PM does not implement code.

### AM

Use AM for `/backend`, `/refactor`, `/compare`, `/scout`, and architecture
parts of `/codebase-audit`. AM defines structure and constraints. AM does not
own implementation unless explicitly assigned.

### CM

Use CM for `/codebase-audit`, `/debug`, `/performance`, `/frontend`,
implementation parts of `/refactor`, and `/artifact` when the artifact is code
or tests. CM must verify behavior before closure.

### DM

Use DM for `/docs`, `/runbook`, `/critique` when documentation is the surface,
and `/artifact` when the artifact is a doc, plan, checklist, handoff, runbook,
or changelog entry. DM validates documentation truth and reader flow. DM does
not own gates, architecture, code, security decisions, or runtime operations.

### SM

Use SM for `/security`, `/scout`, `/critique`, and security parts of
architecture or runtime work. SM validates reachable risk and frames fixes for
CM, AM, or OM.

### OM / OM-Test

Use OM for `/devops`, runtime parts of `/debug`, runtime parts of
`/performance`, deployment checks, monitoring, rollback, and incident response.
OM reports runtime truth and does not produce code by default.

### RM

Use RM for `/research`, `/compare`, and the external-research lens on `/scout`.
RM investigates build issues in depth, grounds findings in official vendor
documentation, and returns ranked options with a recommended next step. RM
recommends only — it may not create or execute code, deploy, or change runtime,
and it does not own gates, architecture, security, implementation, runtime, or
documentation decisions.

## Pipeline Mode (`/ship`)

Pipeline mode is an **execution track** that chains existing minions into an
automated plan → implement → test → review run for a single feature request.
It does not add new roles or new authority — it changes how intermediate
results move between minions during one orchestrated run.

It is the adaptation of the four-stage "specialist pipeline" pattern to this
template's existing minions, rather than a parallel set of pipeline-only
agents. PM orchestrates; AM plans; CM implements, tests, and reviews under
posture constraints; SM gates security when the surface warrants it.

### Two-Channel Communication Model

Direct return is the general default for every spawn, per Single-Writer
Durability in `MEMORY.md`: a spawned minion returns its packet up the spawn
chain, and the top of the chain performs the durable write. Pipeline mode is
one application of that law — this section names the two channels for
inter-minion results within an orchestrated run. Choosing the right one is
what keeps `minions/mail/` from filling with pipeline traffic.

| Channel | Use when | Where it lands |
| --- | --- | --- |
| **Direct return** | A subminion is spawned inside an orchestrated run and returns its result to the caller's context | Held in the orchestrator's (usually PM's) working context; not durable until the orchestrator decides it is |
| **Mail packet** | A formal gate decision, cross-session handoff, or Operator-facing verdict must survive independently of the current context | `minions/mail/` as defined in `docs/project/mailbox-collaboration-model.md` |

Rules:

- Intermediate pipeline stages (spec, changes summary, test results, in-run
  security findings, review verdict) use **direct return**. They do **not** get
  their own mail packets.
- The orchestrator holds every stage result in context, synthesizes, and writes
  **one** durable artifact at the end of the run — a `minions/chat/` continuity
  summary on a clean SHIP, or a `minions/mail/` packet when an Operator gate,
  NEEDS WORK, or BLOCK requires a durable, addressable handoff.
- Direct return never weakens evidence discipline. The final artifact must still
  carry the chain of evidence (what each stage produced) so the run is auditable
  after the fact. "Returned in context" is not an excuse to lose evidence; it is
  a reason to consolidate it into one place.
- Outside an orchestrated run, role-to-role work still lands in
  `minions/mail/` — written by the packet's single writer, per Single-Writer
  Durability in `MEMORY.md`.

### `.pipeline/` Scratch Space

`.pipeline/` is ephemeral, gitignored scratch space for stage handoffs that are
too large to pass cleanly in a returned message. It is wiped at the start of
every `/ship` run. It is never durable truth — anything that must survive the
run is consolidated into the final artifact. Most runs will not need it; prefer
in-context return.

### Stage Map

| Stage | Owner | Posture | Returns |
| --- | --- | --- | --- |
| 1. Plan | `AM` | Spec-only; flags `OPEN QUESTION`s; no code | Implementation spec |
| 2. Implement | `CM` | Implement-only; no planning, no unrequested scope | Changes summary |
| 3. Test | `CM` (fresh) | Test-only; runs tests; does **not** fix failures | Test results |
| 4. Security | `SM` | Reachable-risk review; conditional on security surface | Findings |
| 5. Review | `CM` (fresh) | **Read-only**; SHIP / NEEDS WORK / BLOCK; no edits | Verdict |
| 6. Cross-vendor review | external CLI | Independent read-only review from a *different vendor*; optional, skips if unavailable (stage 8 in `/ship`) | Independent verdict |

#### Cross-Vendor Review Stage (Stage 6)

Stage 6 invokes `tools/xtool-call.sh --mode review` to obtain an independent
read-only verdict from a *different vendor* than the one running `/ship`. It
never writes to the working tree. If the wrapper exits `3` (no other provider
installed), the stage is gracefully skipped and the absence is noted in the
closeout evidence chain — the run never fails for a missing provider. If the
cross-vendor verdict materially disagrees with stage 5, the `AI.md`
Disagreement Protocol runs; an unresolved material disagreement is a
**hard-stop** that surfaces to the Operator.

The posture constraints (implement-only, test-only, read-only review) travel in
the **spawn prompt**, not in the agent files. The `.claude/agents/` launchers
stay general-purpose; `/ship` supplies the constraint per stage.

Both review stages (5 and 6) also apply the Execution Quality capability
lens: the reviewer flags hand-rolled work where an inventoried capability
(`minions/capabilities.md`) fit the task and the charter permitted its use
(see MEMORY.md, Execution Quality). The check travels in the review-stage
prompts the same way the posture constraints do.

Two constraints are load-bearing and must not be relaxed:

- **The test stage does not fix code.** A failing test pauses the run for an
  Operator decision. If the tester also implements, the test/implement
  separation collapses and green tests stop meaning anything.
- **The review stage is read-only.** A reviewer that can patch its own findings
  papers over them instead of reporting them. The read-only constraint is what
  makes the verdict honest.

### Gates That Pause the Run

`/ship` is not fire-and-forget through to merge. It stops and surfaces to the
Operator when:

- the spec contains `OPEN QUESTION`s (stage 2 gate),
- any test fails (stage 5 gate), or
- the review verdict is NEEDS WORK or BLOCK.

The pipeline never merges or pushes. The Operator remains the final human gate.

### Relationship to the Deliberate Coordination Track

Pipeline mode does not replace the deliberate, Operator-directed coordination
model. Both exist:

- **Deliberate track** — Operator or PM explicitly spawns roles, each handoff is
  a mail packet, used for milestone planning, design challenges, release gates,
  and cross-session work.
- **Execution track (`/ship`)** — PM orchestrates a single feature end to end,
  intermediate results return in-context, one durable artifact at the end.

Use the execution track for bounded feature work; use the deliberate track for
governance, architecture direction, and anything spanning sessions or requiring
independent durable packets at each step.

### Phase 2 (Planned, Not Yet Built): Dedicated Cost-Tier Stage Agents

See `docs/model-tiering.md` for the general role-level tier guidance this
section is one application of.

The current pipeline runs the implement and test stages on `cm` (Frontier —
e.g. Opus, `effort: xhigh`). That is correct for quality but is the most
expensive option for the highest-token stages. Phase 2 introduces optional
dedicated launchers that swap the model tier for the mechanical stages
**without** changing the architecture:

- `coder` (Mid — e.g. Sonnet) — implement-only. Slots into stage 2 in place of
  `cm`.
- `tester` (Mid — e.g. Sonnet) — write-and-run-tests-only. Slots into stage 3
  in place of `cm`.

Design intent for Phase 2:

- AM stays on Frontier (planning sets the quality ceiling). The read-only
  review stage stays on Frontier / `cm` (final correctness gate). Only the
  bounded, spec-driven middle stages move to Mid.
- These are **thin launchers** like the existing `.claude/agents/` files — the
  implement-only and test-only postures already live in the `/ship` spawn
  prompts, so Phase 2 is mostly a model-tier swap plus two launcher files and a
  `/ship` update to prefer them when present.
- The two-channel model, the gates, and the read-only review constraint are
  unchanged. Phase 2 is purely a cost optimization, expected to push roughly the
  Anthropic-internal 70/30 Mid/Frontier token split.
- It stays optional: a project can run the whole pipeline on `cm` if it prefers
  uniform quality over cost.

Phase 2 is deferred to a separate session and is documented here so the intent
is durable and not re-litigated.

## Handoff Mode (`/handoff`)

Handoff mode writes a durable, self-contained session snapshot so a fresh
session — or the post-compaction context — resumes cleanly. It is the
procedure behind the single-writer law's "durable before session end or
Operator handoff" mandate, and the durable counterpart of the conversational
Session Reset template in `MEMORY.md`. For Claude the command is
`.claude/commands/handoff.md`; Codex and Copilot orchestrators run the
identical protocol by prompt from this section. The surface protocol
(lifecycle, naming, staleness) is `minions/handoffs/README.md`.

The seat is the session orchestrator — the packet's single writer, usually
PM. A snapshot is a **temporary courier, not truth**: it is committed (it
must survive session death) but the receiving session deletes it on pickup.
Two phases, strictly in order:

### Phase 1 — Flush

Discharge every durability obligation before writing anything to
`minions/handoffs/`. The flush is what makes deletion safe: afterwards the
snapshot duplicates no canonical content — it is a pointer map plus resume
narrative.

1. Persist `SOLE-HOLDER:` facts immediately to their canonical homes; the
   snapshot references them by persisted location only.
2. Commit every in-flight deliverable per the durability window (Git Handoff
   Discipline in `MEMORY.md`).
3. Batch pending `DURABLE LESSONS:` to their canonical homes (role files,
   `feedback.md`, `minions/capabilities.md`), disposing of each item
   explicitly — apply, or drop with reason.
4. Note — do not await — running background work: what it is, where output
   lands, how the resumer verifies completion.

### Phase 2 — Snapshot

Write `minions/handoffs/<YYYY-MM-DD-HHMM>-<topic>.md`, self-contained (a
resumer must need nothing from the dead conversation), with these sections:

- the Session Reset fields (where started / completed / open / priorities /
  blockers / next action);
- repo state — branch, HEAD, unpushed commits, open PRs/gates with URLs,
  position in the `feature → dev → staging → main` flow;
- in-flight work — running background tasks, and unconsumed review findings
  transcribed **verbatim** per the verdict-distribution law;
- environment gates as last verified, marked **presumptive** (runtime claims
  age; the resumer re-verifies);
- pointers — active spec, plan, ledger, packet dirs;
- recall hints — memory-layer query terms, when `MINION_MEMORY=on`;
- `WRITTEN-BY:` + timestamp;
- a **pickup footer** telling the resumer to verify claims against repo
  truth first (files win), resume, then DELETE the snapshot and commit the
  deletion as the pickup receipt; on contradiction repo truth governs and
  useful residue goes to `feedback.md`.

The full template lives in `.claude/commands/handoff.md`; non-Claude
orchestrators reproduce its sections exactly.

### Rules

- **Supersede:** a new handoff for the same seat/topic deletes any prior
  unconsumed snapshot in the same commit — at most one live snapshot per
  seat/topic.
- **Commit:** on the active branch (Class B — the snapshot rides the work it
  describes). Handoff mode never merges, pushes, or promotes anything; it
  snapshots around whatever gate state exists.
- **Exclusions:** never secrets, credentials-adjacent values, or personal
  data — the same exclusion classes as the memory layer.
- **Staleness:** an unconsumed snapshot older than the work it describes is
  deleted at the next gate's DM doc-sync pass. Absence of any handoff is
  normal — most sessions end at natural completion.

## Closure Additions

When a mode affects gates, runtime, architecture, or security, close with the
completion handoff contract in `MEMORY.md`.

Add mode-specific signal inside that existing structure:

- Include `[Certain]`, `[Likely]`, or `[Guessing]` in `RATIONALE:` or
  `EVIDENCE:` when the confidence level matters.
- Put remaining blind spots in `BLOCKERS/RISKS:`.
- Keep `ACTION NEEDED:` and `NEXT OWNER:` explicit.
- If the response is not a formal handoff, still include decision, evidence,
  risk, and next action in the shortest useful form.
