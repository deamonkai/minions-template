# feedback.md — Operator Feedback Capture

Downstream-owned. This file captures corrections, preferences, and working-style
learnings about the Operator across sessions, so any AI working in this repo
(Claude, Codex, Copilot) starts from the same understanding instead of relearning
it each time. It is read at session start.

## What this is — and is not

- **This is a capture log, not project truth.** Raw corrections and preferences
  land here as they happen.
- **`MEMORY.md` stays the curated truth.** When a pattern here proves durable,
  promote it (see below) and mark the entry `promoted`. Do not let this file
  compete with `MEMORY.md` as a second source of truth.

## Promotion path

When a captured item is durable, graduate it into the right curated surface and
mark the entry `promoted -> <where>`:

- general project truth or operator working style -> `MEMORY.md`
- role-specific behavior -> the relevant `minions/roles/*.md` charter

The log is the buffer; the curated files are the truth.

## End-of-session capture (the practice)

At the end of a working session — or when the Operator runs `/feedback` — do this:

> Read the whole conversation. Extract every correction the Operator made, every
> preference they stated, and anything you would do differently next time. Append
> each as a dated entry below, in the format shown. Then flag which entries are
> durable enough to promote, and where.

Keep entries thin, specific, and tool-neutral (written so Codex and Copilot can
act on them too).

## Format

```
## YYYY-MM-DD — short title  [open | promoted -> MEMORY.md]
**Learning:** what the Operator corrected, preferred, or taught
**Apply:** how to act on it next time
```

---

<!-- Capture entries below. This section ships empty; downstream fills it. -->
