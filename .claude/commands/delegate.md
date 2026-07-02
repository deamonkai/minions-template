---
description: Delegate a role's work to another installed AI CLI in an isolated git worktree; merge stays a human gate.
---

Delegate work to another AI: $ARGUMENTS

Parse `$ARGUMENTS` as `<role> <task...>` (role is one of pm|am|cm|sm|dm|om|rm).
Optionally a leading `--provider <codex|copilot>`.

1. **Pick the provider** (default `codex` for repo-native implementation; honor an
   explicit `--provider`). The delegate runs as `<role>`, reusing that tool's
   role launcher where applicable.
2. **Invoke the wrapper** in delegate mode:
   `bash tools/xtool-call.sh --provider <p> --mode delegate --role <role> --topic <slug> --prompt "<task + acceptance>" --out .pipeline`
   If it exits `3`, report provider-unavailable and stop.
3. The wrapper creates branch `xtool/<provider>-<role>-<topic>` in a worktree and
   captures the proposed diff. **It does not merge.**
4. **Verify before the gate.** Optionally run the `/ship` test + read-only review
   stages against the worktree branch so the Operator sees a verdict with the
   diff. (Reuse the pipeline; do not re-implement it.)
5. **Present the merge gate.** Show the Operator the branch, the diff summary, and
   any verdict. **Merging/pushing to `main` is a hard-stop — wait for explicit
   Operator sign-off.** Do not merge or push on your own.
6. On Operator approval, merge the branch and remove the worktree
   (`git worktree remove`). On rejection, remove the worktree and delete the
   branch.

Keep evidence custody: the durable artifact carries the delegate's raw output and
the verdict chain.
