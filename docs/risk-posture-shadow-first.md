# Risk Posture: Shadow-First / Dark-Ship

An **optional** posture for landing a behavior-changing change to a critical path
safely and reversibly. It is not required and not a default — reach for it only
when the fit test below is met. The template ships the *posture and contract*, not
code: a downstream implements the pieces in its own stack.

The idea in one line: **ship the new behavior switched off, prove it cannot
regress the incumbent, then let it become authoritative only on measured
evidence — with every divergence counted, never silently dropped.**

## When to use it

Use this when **all** of these hold:

- You are replacing or altering a **behavior-critical decision path** (a swap of
  an engine, a new control/guard, a changed calculation) where a wrong result is
  costly or hard to reverse.
- There is a **comparable incumbent** to diff the new path against — you can run
  old and new on the same inputs and compare outputs.
- The change is risky enough that "tests pass" is not sufficient confidence to
  flip it on in one step.

## When NOT to use it

Skip it (it is overkill) when:

- The work is **greenfield** — there is no incumbent to compare against.
- The change is **not behavior-critical** (cosmetic, additive, easily reversible).
- A feature flag plus normal tests already give you enough confidence.

Do not apply this posture reflexively; its weight is only justified by real
reversal risk. Forcing it onto small changes is its own anti-pattern.

## The pattern, in four layers

### 1. Dark-ship / flag-gate

Put the new behavior behind a flag that **defaults OFF**, where OFF is a
**zero-compute pass-through** to the incumbent — the new path is not merely
ignored, it is not invoked. Two phases, in order:

- **Shadow (observe & discard):** recompute the new result alongside the
  incumbent, compare, record the verdict — then **throw the new result away** and
  let the incumbent drive. This proves correctness offline with **no behavior
  change — provided the recompute is side-effect-free**: a pure recomputation, or
  one whose external writes (DB, network, files, queues) are disabled or
  redirected to a sink in shadow mode. If the new path can write, gate those
  writes off, or "observe & discard" is not actually risk-free.
- **Authoritative-but-dark:** consume the new result **only when it is identical**
  to the incumbent. Still a no-op in effect (identical means nothing changed), but
  now you are exercising the live wiring, the divergence counter, and the fallback
  ordering.

Keep the flag that *activates* an intended behavior change **separate** from the
flag that routes the engine, so the machinery can be live while the behavior
change stays inert. For a disarmable safety flag, default it to a **tri-state
"unset"** so an explicit "off" is distinguishable from "not set" and is not
silently re-enabled by a config default. Gate the whole thing behind a
**production interlock** that *code-refuses* to enable these flags outside a safe
(test / sandbox / non-production) mode — independent of the flag value.

### 2. The shadow comparator (the heart of the pattern)

A **pure, total** function that compares incumbent-vs-new and emits a **three-way
verdict**:

```
classify(old, new) -> { verdict: MATCH | EXPECTED | REGRESSION,
                        equal: bool,          # the gate: exact canonical equality
                        dims:  [all mismatching fields],
                        note:  <allow-list id when EXPECTED> }
```

Load-bearing rules:

- **The verdict is computed in auditable code, never re-derived in a dashboard or
  UI filter.** The view *reads* the verdict; it does not compute it. (A UI that
  recomputes can lie — e.g. by averaging over a mismatched window.)
- **The gate is exact equality of a canonical serialization, field by field — no
  epsilon.** Comparing only a summary lets wrong details slip through. Canonicalize
  unstable representations (e.g. normalize signed zero, reject NaN/Inf) so equality
  is deterministic.
- **Report every mismatching dimension, not the first.** First-divergence-only
  hides compound regressions.
- **Scrub or record-forensic-only any volatile / out-of-scope field — never gate
  on it.** Gate exactly the decision this layer owns; record everything else for
  analysis, but never let it trip a regression.

### 3. The `EXPECTED_DIVERGENCES` allow-list

A registry that promotes a *specific, justified* divergence from REGRESSION to a
logged, counted **EXPECTED** — **empty by default**. Entry schema:

```
ExpectedDivergence = (
  note_id:       stable audit key, written into the divergence event
  justification: human "why", logged and surfaced to the gatekeeper
  predicate:     (old, new, dims) -> bool   # "this entry explains THIS divergence"
)
```

- A divergence is EXPECTED **only if a registered predicate matches**; otherwise
  REGRESSION. A predicate that throws **falls through to REGRESSION** (fail toward
  safety).
- Make the predicate **tight** — assert the full semantics of the intended change,
  not just its shape, so an unrelated divergence cannot masquerade as the
  justified one.
- Every EXPECTED is **counted and visible**. The allow-list exists so a deliberate
  change registers a *justified explanation* rather than someone *widening a
  tolerance* — an unjustified "ignore" guarantees the candidate silently differs.
  Adding an entry is a gatekeeper (PM/owner) act, recorded like any decision.

### 4. Adopt-on-evidence + tripwire fallback

The wrapper that lets the new path actually drive the decision:

```
adopt(old, new) -> AdoptResult { use_new, new_value, divergence_event }
```

- **Adopt only on MATCH** (plus the small note-pinned allow-set in §5 below). On
  divergence, compute error, or missing input capture, **use the incumbent** and
  emit a **counted** divergence event.
- **MATCH-only is the dark-ship invariant:** when clean, new == incumbent so
  adopting changes nothing; when diverged, fallback uses the incumbent so adopting
  *still* changes nothing. What you gain is the live machinery + the divergence
  counter + a proven fallback — not a behavior change. Trusting the new path on a
  non-MATCH is a strictly later, separately-gated step.
- **Ordering is load-bearing:** the fallback must restore the incumbent value
  **before the next consumer reads it**.
- **Failure isolation is asymmetric:** the shadow path may fail open (telemetry
  only), but the adopt path must **fail closed** — any fault → use the incumbent +
  count it. A missing capture where one was expected is itself counted, never
  treated as clean.

## The isolation test (the no-regression proof)

The test that makes the dark-ship claim real. Drive the **real** reducers and the
**real** comparator (not mocks). Over a matrix of all flag combinations:

- **all-OFF ⇒ byte-identical to the incumbent** (zero divergence recorded).
- **every ON combo ⇒ identical to the incumbent while the tripwire is clean**
  (adopt-on-match is a no-op).
- **A "teeth" case:** construct an input whose incumbent value is *deliberately
  wrong* versus the recomputed value, then assert the fallback **restored the
  incumbent value before the consumer read it** and **exactly one** divergence was
  counted. This proves the test *can* fail — without it the suite is vacuous.
- **A paired "adopt-changes-it" case:** force adoption of a *different* value and
  assert the observable output actually changed. The pair proves the fallback in
  the teeth case is genuinely preventing the change, not a coincidental no-op.
- **If you use the adopt allow-set (third outcome):** add a case asserting an
  allow-listed EXPECTED divergence is **adopted and counted** (not fallen back),
  so the deliberate-improvement path is covered too.

```
clean:            output(any_combo) == output(all_off)   AND  divergences == 0
teeth (forced):   output == INCUMBENT value              AND  divergences == 1
paired adopt:     force-adopt(different) ⇒ output == the new value
```

## Adopting a justified improvement (the third outcome)

When you genuinely *want* the new behavior to differ, it becomes an
**allow-listed, counted, adopted** divergence rather than a regression — by lining
up three independent registrations:

1. an `EXPECTED_DIVERGENCES` entry with a tight predicate (§3),
2. its `note_id` added to a small **adopt allow-set**, and
3. the change still behind its own activation flag (so it stays inert until armed).

When all three agree, the new path drives the decision and the event **honestly
records the new path as authoritative** (not a hardcoded "fell back to
incumbent"). Everything else still falls back. So there are exactly three terminal
outcomes: **MATCH → adopt silently**, **allow-listed EXPECTED → adopt and count**,
**everything else → fall back and count**.

## Minimal contract (the smallest adoptable set)

A downstream needs these seven pieces — implement them in your own stack:

1. **A flag, default OFF, where OFF is a zero-compute pass-through** to the
   incumbent. (Recommend a *second* orthogonal flag to activate any intended
   behavior change, tri-state-default for correct disarm.) Ensure the shadow/new
   path is **side-effect-free, or its external writes are disabled/redirected to a
   sink** in shadow mode — otherwise "observe & discard" is not risk-free.
2. **A canonical serializer** for the decision value (deterministic; unstable
   representations normalized; volatile/out-of-scope fields excluded or
   forensic-only).
3. **A pure, total comparator** returning `{MATCH, EXPECTED, REGRESSION}` + all
   mismatching dims; gate = exact equality of (2); verdict computed in code, never
   in a view.
4. **An `EXPECTED_DIVERGENCES` registry, empty by default**, entries
   `(note_id, justification, predicate)`; predicate errors fail toward REGRESSION.
5. **An adopt wrapper** keyed on evidence — recompute the new value from the
   **same captured inputs** as the incumbent (so a divergence reflects logic, not
   input skew), adopt only MATCH (plus a note-pinned allow-set for justified
   EXPECTED); per-decision tripwire falls back to the incumbent on divergence /
   error / missing-capture and **counts every fallback**; caller threads the result
   before the downstream read.
6. **An isolation test** — flag matrix + all-OFF byte-identity + a teeth case +
   a paired adopt-changes-it case; drive real code.
7. **A production interlock** that code-refuses enabling the flags outside a safe
   mode, independent of flag value.

## Relationship to the rest of the template

- This is a **Deployment Discipline** posture (see `MEMORY.md`); it complements,
  not replaces, the rollback-posture requirement for production-affecting change.
- It pairs naturally with **dual-vendor review** on the control-surface diff (see
  `docs/cross-tool-orchestration.md`): the flag-boundary changes are exactly the
  "config-only bypass by omission" class where a second vendor earns its keep.
- The "every divergence is counted and visible, never silently dropped" rule is
  the same evidence discipline the **Completion Handoff Contract** asks for.

*Pattern distilled from a downstream (Molloy-trading-bot) that runs it across
multiple independent decision points; the trading-specific machinery is
deliberately left out so the posture stays domain-neutral.*
