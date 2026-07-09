---
description: Run the PM-orchestrated feature pipeline (plan → implement → test → review) for a feature request.
---

Run the feature pipeline for: $ARGUMENTS

You are acting as **PM in pipeline mode**. Read `MEMORY.md`,
`minions/roles/PM.md`, and the Pipeline Mode section of
`docs/minion-prompt-modes.md` before starting.

Pipeline mode is the **execution track**, not the deliberate coordination
track. Intermediate stage outputs use the **direct-return channel**: each
spawned subminion returns its result to you in-context and you hold it. Do
**not** open a `minions/mail/` packet for any intermediate stage. Only the
final synthesized artifact becomes durable, and only at the end.

Use `.pipeline/` as ephemeral scratch space if a stage needs a file-sized
handoff that does not fit cleanly in a returned message. `.pipeline/` is
gitignored and is wiped at the start of every run — never treat it as durable
truth.

## Stages

Run these in order. After each stage, confirm you have the previous stage's
result before starting the next. Do not skip ahead. Do not merge anything.

0. **Reset.** Clear `.pipeline/` so no stale files from a prior run are read.

1. **Plan (AM).** Spawn the `am` subagent. Ask it to read the relevant
   codebase patterns and return a tight implementation spec: exact files to
   create or modify, interfaces/signatures, edge cases, and which existing
   patterns to follow (named by file). It must flag anything ambiguous as an
   `OPEN QUESTION`. AM returns the spec to you — no mail packet.

2. **Open-question gate.** If the spec contains any `OPEN QUESTION`, **stop**
   and surface them to the Operator. Do not proceed to implementation on
   guesses.

3. **Implement (CM, implement-only).** Spawn the `coder` subagent (falls back
   to `cm` if `coder` is not present) in implement-only posture: "Implement
   exactly this spec. Follow the named
   patterns. Do not add unrequested features, do not refactor unrelated code."
   Pass the spec from stage 1. CM returns a changes summary (files changed,
   what each does, what the test stage should focus on) — no mail packet.

4. **Test (CM, test-only).** Spawn a fresh `tester` subagent (falls back to
   `cm` if `tester` is not present) in test-only posture:
   "Write tests for the happy path, the spec's named edge cases, and at least
   one failure case. Match the repo's test framework. Run them. If any fail,
   report the failures and STOP — do NOT fix the code." Pass the spec and the
   changes summary. CM returns the test results — no mail packet.

5. **Test gate.** If any test failed, **stop** and surface the failures to the
   Operator. The pipeline pauses for a human decision; it does not self-heal.

6. **Security (SM, conditional).** If the change touches auth, access control,
   crypto, secrets, or untrusted input handling, spawn the `sm` subagent for a
   reachable-risk review. SM returns findings — no mail packet. Skip this stage
   for changes with no security surface, and note that you skipped it.

7. **Review (CM, read-only).** Spawn a fresh `cm` subagent in read-only review
   posture: "You are read-only. Do NOT edit code. Run `git diff`. Assess: does
   the code match the spec, are the tests meaningful, any correctness /
   security / performance issues, and is any of the work hand-rolled where an
   inventoried capability (`minions/capabilities.md`) fit the task and the
   charter permitted its use? Return a verdict: SHIP / NEEDS WORK / BLOCK,
   with exact fixes and locations for anything other than SHIP." Pass the spec,
   changes summary, test results, and any SM findings. The read-only constraint
   is load-bearing — a reviewer that can patch its own findings papers over
   them instead of reporting.

8. **Independent cross-vendor review (optional).** Run an independent review from
   a *different vendor* than the one running `/ship`:
   `bash tools/xtool-call.sh --provider <other> --mode review --target . --prompt "Independently review this change against the spec; flag correctness, security, and scope issues, plus hand-rolled work where a capability inventoried in minions/capabilities.md fit the task. Verdict: SHIP / NEEDS WORK / BLOCK." --out .pipeline`
   Fold its verdict into the closeout evidence chain. If the wrapper exits `3`
   (no other provider installed), **skip this stage and note that you skipped
   it** — never fail the run for a missing provider. If the cross-vendor verdict
   materially disagrees with stage 7, run the `AI.md` Disagreement Protocol; if
   unresolved and material, **stop and surface to the Operator** (hard-stop).

## Closeout

You now hold every stage result in context. Synthesize **one** durable
artifact:

- If the verdict is **SHIP** and no Operator gate decision is pending, write a
  short continuity summary to `minions/chat/YYYY-MM-DD-ship-<topic>.md`
  capturing the request, what was built, test status, and the verdict.
- If the verdict is **NEEDS WORK** or **BLOCK**, or the run paused at a gate,
  open one `minions/mail/` packet addressed to the Operator (or the role that
  must act next) with the full chain of evidence and explicit next steps.

Then report to the Operator, findings-first: the final verdict, what each stage
produced, any gate that paused the run, and the exact next action. **Do not
merge. Do not push.** Leave the branch for Operator review.

Follow the completion handoff contract in `MEMORY.md` for the closeout report.
