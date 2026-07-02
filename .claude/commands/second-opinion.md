---
description: Get an independent, cross-vendor read-only review (second opinion) from another installed AI CLI.
---

Get an independent second opinion on: $ARGUMENTS

You are orchestrating a **read-only** cross-vendor review. The reviewing AI never
writes to the repo.

1. **Pick the provider.** Default to a vendor *different* from the tool you are
   running in, to guarantee independence (running in Claude -> prefer `codex` or
   `copilot`). If `$ARGUMENTS` names a provider, honor it.
2. **Resolve the target.** Default target is the current diff (`git diff`); if
   `$ARGUMENTS` names a file or packet path, use that.
3. **Invoke the wrapper** in review mode:
   `bash tools/xtool-call.sh --provider <p> --mode review --target <t> --prompt "<review ask>" --out .pipeline`
   If it exits `3` (provider unavailable), say so and stop — do not fall back to
   self-review silently.
4. **Read the envelope + raw output** from `.pipeline/`. Carry the reviewer's raw
   findings forward verbatim (no lossy summary).
5. **Consolidate one durable artifact** per the two-channel model: a
   `minions/chat/` continuity note on a clean pass, or a `minions/mail/` packet if
   the verdict needs a durable addressable handoff.
6. **Disagreement check.** If the reviewer materially disagrees with the work,
   run the Disagreement Protocol in `AI.md` (pin the claim, find evidence, apply
   role ownership). If evidence settles it, record the resolution and continue.
   If it stays material and unresolved, **stop and surface both positions +
   evidence to the Operator** (this is a hard-stop).

Do not merge or push. Report findings-first.
