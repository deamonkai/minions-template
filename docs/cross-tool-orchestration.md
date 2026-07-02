# Cross-Tool Orchestration

This doc covers the machine-mediated cross-tool coordination feature: how the
active orchestrator (Claude Code, or a PM minion) invokes another installed AI
CLI as a read-only reviewer or worktree-isolated delegate, while retaining sole
authority over what becomes truth and what reaches `main`.

The exported surfaces are `tools/xtool-call.sh`, `.claude/commands/second-opinion.md`,
`.claude/commands/delegate.md`, and the `/ship` cross-vendor review stage.

## Purpose

Replace hand-mediated tool-switching with a single, provider-agnostic primitive.
The orchestrator owns the data plane: external output is never authoritative
until the orchestrator writes it into a repo surface. Merge/push to `main`
remains a human gate.

## Providers

The wrapper detects each provider by looking for its binary on `PATH`:

| Provider | Binary | Status |
| -------- | ------ | ------ |
| `codex`  | `codex` | First-class |
| `copilot` | `copilot` | First-class |
| `gemini` | `gemini` | Dormant seam (not yet wired) |

If the requested provider binary is not found, the wrapper exits `3`
("provider unavailable") and logs a message to stderr. Callers check for exit
code `3` and degrade gracefully — the run is not failed by a missing CLI.
Attempting to use `gemini` also returns exit `3` (provider not wired).

## Wrapper

`tools/xtool-call.sh` is the single executable surface. All commands and the
`/ship` pipeline call it; provider-specific mechanics stay in one reviewable
place.

```
bash tools/xtool-call.sh \
  --provider <codex|copilot|gemini> \
  --mode <review|delegate> \
  [--role <pm|am|cm|sm|dm|om|rm>] \
  [--target <path-or-diff>] \
  [--topic <slug>] \
  [--prompt "<text>"] \
  [--out <dir>]
```

The wrapper writes a JSON result envelope to `--out` (default `.pipeline/`)
with fields: `provider`, `mode`, `role`, `target`, `topic`, `branch`,
`worktree`, `exit_status`, `status`, `raw_output_file`, and `invocation`. Raw
provider output is preserved verbatim — no lossy summarization.

Exit codes: `0` = success, `2` = bad arguments, `3` = provider unavailable.

## Two Modes

### review (read-only)

The reviewing AI reads the repo but cannot write files or run shell commands.
Read-only enforcement is applied by the provider's own flags, not only by the
prompt — the wrapper is responsible for passing the enforcing flags:

- **codex:** `codex exec -s read-only "<prompt>"` — the `-s read-only` sandbox
  flag enforces the constraint.
- **copilot:** `copilot -p "<prompt>" --allow-all-tools --deny-tool 'write' --deny-tool 'shell'`
  — denial rules take precedence over `--allow-all-tools`, so write and shell
  access are blocked while read tools remain available.

No write paths are granted; no worktree is created. The raw output lands in
`.pipeline/`.

> **Note — review-mode network surface:** read-only enforcement blocks file writes
> and shell, but copilot's `url` / `web-fetch` tool kind is **not** denied, so
> review mode retains a read-only *outbound fetch* channel. This is a
> confidentiality consideration, not a write/integrity risk. If you point a review
> at a sensitive repository, deny it as well (`--deny-tool 'url'`) or run the review
> offline. (Surfaced by a downstream SM review; left as an opt-in rather than a
> default so legitimate reviews can still fetch referenced material.)

### delegate (worktree-isolated)

The delegating AI is given write access scoped strictly to an isolated git
worktree. It never touches the caller's working tree or `main`.

The wrapper:
1. Creates a new branch `xtool/<provider>-<role>-<topic>` and a worktree at
   `.xtool-worktrees/<provider>-<role>-<topic>`.
2. Invokes the provider inside that worktree with write scope:
   - **codex:** `codex exec -s workspace-write "<prompt>"` (run inside the worktree).
   - **copilot:** `copilot -p "<prompt>" --allow-all-tools --add-dir <worktree-abs-path>`
     — `--add-dir` scopes write access to the worktree path only;
     `--allow-all-paths` is not used.
3. Captures the proposed diff.
4. **Never runs `git merge`, `git push`, or `git switch` on the caller's
   branch.** The isolated branch is the output; merge is a human gate.

## Commands

### `/second-opinion`

Get an independent cross-vendor read-only review of the current diff (or a
named target).

Example invocation inside the command flow:

```bash
bash tools/xtool-call.sh \
  --provider codex \
  --mode review \
  --target . \
  --prompt "Review this change for correctness, security, and scope issues. Verdict: SHIP / NEEDS WORK / BLOCK." \
  --out .pipeline
```

After the wrapper returns, the orchestrator reads the envelope and raw output,
carries the reviewer's findings verbatim, and consolidates **one** durable
artifact: a `minions/chat/` continuity note on a clean pass, or a
`minions/mail/` packet when the verdict needs an addressable handoff.

If the wrapper exits `3`, the orchestrator reports "provider unavailable" and
stops — it does not silently fall back to self-review.

**On security-sensitive diffs, run BOTH vendors, not one.** A single second
opinion is one vendor's blind spots. Run `codex` *and* `copilot` on changes that
touch a security or control surface — in practice each catches real HIGHs the
other clears (a recurring class: a config-only flag that bypasses a guard *by
omission*). Treat each vendor's reported **severity as input, not verdict**, and
re-triage against repo evidence before escalating a gate — different vendors have
different blind spots and severity calibration, so confirm reachability rather
than taking a rating at face value. (Downstream practice, consistent with the
template's own dogfooded dual-vendor reviews.)

### `/delegate`

Spin up an isolated worktree, run the provider as a named role, and present the
diff and merge gate to the Operator.

Example invocation inside the command flow:

```bash
bash tools/xtool-call.sh \
  --provider codex \
  --mode delegate \
  --role cm \
  --topic auth-refactor \
  --prompt "Refactor the auth module per the attached spec. Follow existing patterns in src/auth/. Do not add unrequested features." \
  --out .pipeline
```

The Operator sees the branch name (`xtool/codex-cm-auth-refactor`), the diff
summary, and any review verdict before being asked for merge approval.
Merge/push to `main` requires explicit Operator sign-off — the orchestrator
does not merge on its own.

**Prune the worktree after the branch lands.** A delegate's worktree persists at
`.xtool-worktrees/<provider>-<role>-<topic>` after its branch is merged or
abandoned — these accumulate over a busy week. Once the branch is merged (or
discarded), remove it: `git worktree remove .xtool-worktrees/<slug>` then
`git branch -d xtool/<slug>` (or `git worktree prune` to sweep stale entries).
The wrapper only self-cleans a *failed* delegate that produced no work; a
successful one is left intact for review, so post-merge cleanup is the caller's
job.

### `/ship` cross-vendor review stage

`/ship` includes an optional independent cross-vendor review after the
read-only CM verdict (stage 8 of the pipeline). The provider is chosen to be
*different* from the one running `/ship`:

```bash
bash tools/xtool-call.sh \
  --provider codex \
  --mode review \
  --target . \
  --prompt "Independently review this change against the spec; flag correctness, security, and scope issues. Verdict: SHIP / NEEDS WORK / BLOCK." \
  --out .pipeline
```

If the wrapper exits `3` (no other provider installed), the stage is skipped
and the absence is noted in the closeout evidence chain — the run never fails
for a missing provider. If this stage's verdict materially disagrees with
stage 7, the Disagreement Protocol runs (see below). For a security- or
control-surface change, prefer running **both** vendors at this stage rather than
one (see the dual-vendor note under `/second-opinion`).

## Data-Plane Rules

- External output is **not authoritative** until the orchestrator writes it into
  a repo surface (`minions/mail/`, `minions/chat/`, etc.).
- **Review results** use the direct-return channel inside an orchestrated run.
  The orchestrator holds all stage results in context and writes **one** durable
  artifact at closeout — a `minions/chat/` summary on a clean SHIP, or a
  `minions/mail/` packet when a gate or verdict needs a durable, addressable
  handoff.
- **Delegated work** lands on an isolated branch in a worktree. The branch is
  never merged or pushed by the orchestrator.
- **Merge/push to `main` is a hard-stop** — the Operator approves explicitly
  before any merge happens.
- The result envelope carries the provider's raw output into the durable
  artifact so a run is auditable after the fact.

## Disagreement Handling

When an independent reviewer materially disagrees with the work, the
orchestrator runs the `AI.md` Disagreement Protocol:

1. Pin the exact claim in dispute.
2. Find repo/runtime/source evidence; apply role ownership.
3. If evidence settles it, record the resolution in the durable artifact and
   continue.
4. If the disagreement stays **material and unresolved**, **stop** and surface
   both positions plus evidence to the Operator. The orchestrator does not pick
   a side.

"Material" means the disagreement affects correctness, security, the data
plane, or the gate decision. Cosmetic or stylistic disagreements are resolved
autonomously and noted in the artifact.

## Autonomy Posture

Routine orchestration — spawning agents, advancing pipeline stages, firing
independent second opinions — runs without asking the Operator for permission.

Hard-stops (interrupt the Operator):

1. **Merge/push to `main`** — delegated work reaching the real branch.
2. **Destructive or production-affecting actions** without rollback posture.
3. **Unresolved AI disagreement** — material and evidence cannot settle it.

Scope expansion is not a hard-stop: flag it explicitly and proceed with the
smallest change that addresses the request.

## Downstream Compatibility

The feature degrades gracefully. If neither `codex` nor `copilot` is installed:
- `/second-opinion` and `/delegate` report "provider unavailable" and stop.
- The `/ship` cross-vendor stage is skipped with a logged note.

No functionality other than the cross-vendor stages is affected. Projects that
do not install the provider CLIs can adopt everything else in the template
without modification.
