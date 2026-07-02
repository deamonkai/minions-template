# CHANGELOG

All notable changes to this repository are tracked here.

## 2026-07-02 (v1.21.3 — tea v0.14.1 compat, downstream-authored)

- Commit hash: pending (staging→main PR merge)
- **Provenance:** downstream-authored (Molloy-trading-bot team), absorbed
  upstream 2026-07-02 so future downstream upgrades stop re-fighting it.
- `tools/issue-sync.sh`: `tea` v0.14.1 renamed the issue-body flag
  (`--body` → `--description`/`-d`) and the edit-time label flag
  (`--labels` → `--add-labels`); a `--body` call fails outright on 0.14.1,
  so every `sync` soft-failed (exit 4) and created nothing. The Gitea
  backend funcs now detect the installed `tea`'s flag names from
  `tea issues create --help` and prefer `--description`/`--add-labels`,
  falling back to `--body`/`--labels` on older builds.
- `tools/issue-board-bootstrap.sh`: on 0.14.1 `tea labels create` exits 0
  on a duplicate name and creates a *second* same-named label (it does not
  fail on collision), so blind re-creation silently doubled the label set.
  The bootstrap now snapshots existing labels once (`tea labels list` /
  `gh label list`) and skips those already present — query-then-skip,
  genuinely idempotent re-runs on any host.
- `tools/tests/fixtures/make-fake-provider.sh`: 0.14.1-faithful fake `tea`
  (rejects `--body`, edit rejects `--labels`, `labels create` records
  duplicates and exits 0, `labels list` replays the recorded set).
- Tests: +9 issue-sync cases (create uses `--description`, edit uses
  `--add-labels`, legacy flags rejected) and +3 bootstrap idempotency cases
  (re-run does not double labels) — suites now at 50 and 20 cases.
- `docs/runbooks/issue-board-setup.md`: supported-`tea`-version header,
  query-then-skip idempotency note, and a "tea v0.14.1 compatibility notes"
  section.
- **Known coverage gap:** the fake tea's `--help` exits non-zero, so
  `tea_supports_flag`'s grep-detection and legacy-fallback branches aren't
  exercised by the suite (only the assume-modern path is); a help-capable
  fake variant is future work.

## 2026-07-02 (v1.21.2 — Memory gate shell-profile fix: .zshenv, not .zshrc)

- Commit hash: pending (staging→main PR merge)
- Fixed a defect in `docs/runbooks/memory-recall-setup.md`: the
  persistent-setting recipe told the Operator to put
  `export MINION_MEMORY=on` in the shell profile (`~/.zshrc`), but agent
  tool-shells are non-interactive zsh, which never sources `~/.zshrc` —
  only `~/.zshenv`. An export in `~/.zshrc` makes the gate look "on" in
  the Operator's interactive terminal while every agent shell still
  reads it as unset, so the memory recall layer stayed silently inert.
- Fix: for zsh (macOS default), the persistent export now goes in
  `~/.zshenv`, which is sourced by all zsh invocations, interactive and
  non-interactive alike. For bash, since non-interactive sourcing of
  `~/.bashrc` varies by invocation convention, the runbook now
  recommends setting the export in both `~/.bashrc` and
  `~/.bash_profile`, or better, verifying directly.
- New rule: verification must run from the agent's own fresh tool shell
  (`echo ${MINION_MEMORY:-<unset>}`), never from the interactive
  terminal — the two shell types read different profile files and can
  disagree silently.
- Provenance: found by dogfooding on 2026-07-02 — the Operator followed
  the runbook exactly, saw the gate as `on` in their terminal, but every
  agent shell saw it as unset the whole time.

## 2026-07-02 (v1.21.1 — Verdict distribution in gate briefs)

- Commit hash: pending (staging→main PR merge)
- New rule: dispatch briefs for gate decisions must carry the reviewer
  verdicts explicitly — distilled verdict, conditions, and severities,
  transcribed verbatim by the orchestrator. Raw artifacts stay available
  as reference, never as the gate's primary input.
- Two-sided brief-content pairing with the v1.20.1 live-state-briefs rule:
  mutable world facts (runtime state) are NOT embedded — the brief
  instructs live verification, because they age. Immutable decision
  records (verdicts, conditions) ARE embedded verbatim — the gate must
  not be made to re-derive them from large artifacts, because reader-side
  reads can truncate silently.
- Added to MEMORY.md (Execution Quality, sibling bullet to the v1.20.1
  live-state bullet) and `minions/roles/PM.md` (Single-Writer Durability:
  PM-authored gate briefs embed verdicts verbatim instead of directing
  the gate agent to re-read raw artifacts).
- Provenance: downstream PM-codex truncation incident — a gate agent's
  own reader-side re-read of a large raw review artifact came up
  truncated, and the gate proceeded on partial evidence. v1.20.0's
  single-writer durability window already prevents half-*written*
  artifacts (writer commits each deliverable before the next stage);
  this rule closes the complementary reader-side case, where the
  artifact was written whole but the gate's own read of it truncated.

## 2026-07-02 (v1.21.0 — Memory recall layer: Mnemoverse as optional view layer)

- Commit hash: pending (staging→main PR merge)
- New optional recall layer, off by default: Mnemoverse (or a compatible
  memory service) as a semantic index over promoted repo knowledge.
  Enabled via `MINION_MEMORY=on`; when the variable is unset or the
  memory tools/API are absent, every memory step is a silent no-op — no
  minion workflow is ever blocked by memory absence. Files always win;
  recall output is input, not authority.
- **Write path (curated, writer-owned):** only the packet's single
  writer calls `memory_write`, and only at promotion moments — an
  applied `DURABLE LESSONS:` item, an accepted decision or release
  summary, or an Operator-directed "remember this." Domain scheme
  `project:<repo-name>` (this repo: `project:minions-template`).
- **Read path (orchestrator recall into briefs):** the orchestrator
  queries the project domain at run start and folds relevant recall into
  dispatch briefs — spawned minions need no MCP access. Recalled runtime
  facts are presumptive; briefs still instruct live-state verification.
- **Security boundary — four excluded classes, never mirrored:**
  secrets/credentials and credentials-adjacent state; `SOLE-HOLDER:`
  facts; personal data; packet bodies, diffs, or code. Only distilled
  lesson/decision text crosses.
- **Transport:** MCP tools today (`memory_write/read/stats/delete/
  delete_domain`); REST fallback documented for non-Claude orchestrators
  (base `https://core.mnemoverse.com/api/v1`, endpoint paths transcribed
  from the vendor llms.txt, `MNEMOVERSE_API_KEY` environment-only).
- New docs: `docs/memory-recall-model.md` (canonical model) and
  `docs/runbooks/memory-recall-setup.md` (operator runbook: gate
  variable facilitation, per-machine connection, API key, smoke test,
  disable/rollback). Wired into `MEMORY.md`, `minions/roles/PM.md`, and
  `AI.md`; export-manifest rows added for both docs; version bumped to
  `1.21.0-1.0.0`.
- **Backtest:** smoke loop validated live against the real service on
  2026-07-02 (write -> read [relevance-scored hit] -> stats -> delete_domain
  [confirm interlock] -> stats clean); runbook step semantics corrected to
  observed tool behavior.

## 2026-07-02 (v1.20.1 — Live-state briefs: confirm runtime state, don’t embed snapshots)

- Commit hash: pending (staging→main PR merge)
- New rule: dispatch briefs for runtime-touching work must instruct the
  agent to confirm live state first, never embed a presumed runtime
  snapshot — embedded state ages between authoring and execution; a brief
  states what to verify, not what is true.
- Provenance: downstream field report (third distilled rule, six agent
  datapoints) — a deploy brief embedded a presumed runtime snapshot
  ("assume a flat book"); reality at execution time was 10 carried
  positions. The executing agent handled it but had to guess, which is the
  failure mode this rule closes.
- Applied to `MEMORY.md` (Execution Quality), `minions/roles/OM.md`
  (Guardrails — briefs OM/OM-Test receives or authors must say "confirm
  live state first" before acting on positions, config checksums, or
  service status), and `minions/roles/PM.md` (Single-Writer Durability
  area — PM-authored runtime-touching briefs instruct verification instead
  of embedding presumed state).

## 2026-06-29 (v1.20.0 — Single-writer durability for the comm model)

- Commit hash: pending (staging→main PR merge)
- Driven by a downstream field report: parallel/fan-out minion work was
  producing repo/branch write contention and half-written handoff packets
  when multiple spawned minions committed concurrently. This milestone
  canonizes **single-writer durability** to close that gap.
- **Rule:** spawned minions do not commit or push. They complete their work
  and *return* the Completion Handoff packet to whoever spawned them,
  verbatim. Only the top of the spawn chain — the single writer for that
  chain — commits to the repo/branch. Rationale: eliminates repo/branch write
  contention, fan-out coordination overhead, and the risk of a half-written
  packet landing mid-commit.
- **Scope split:** coordination artifacts (handoff packets, mailbox state,
  plan/status tracking) roll up through the spawn chain to the single writer;
  code deliverables stay in-lane and are committed by the implementer on its
  own feature branch — the writer never re-commits code, only coordination
  artifacts roll up to the writer.
- **Durability window:** the writer commits each returned deliverable before
  dispatching the next stage of work — at most one in-flight (uncommitted)
  deliverable at any time, bounding how much work is at risk if a session
  drops.
- **Attribution:** returned packets carry a `WRITTEN-BY:` header identifying
  the actual writer, and are transcribed verbatim into the repo rather than
  summarized or reformatted — preserving the original author's record even
  though they didn't commit it themselves.
- **`DURABLE LESSONS:`** — an optional handoff section a spawned minion can
  use to flag durable, cross-cutting learnings; the single writer batches
  these across a run rather than committing them piecemeal.
- **Escape valve:** oversized deliverables that shouldn't be transcribed
  inline (large diffs, generated artifacts) may be written directly to disk
  by the spawned minion without committing, with a return path back to the
  writer that points at the on-disk location instead of embedding content.
- **Generalized across the model:** all seven role charters, `AI.md`, and
  Pipeline Mode now state the single-writer rule consistently, replacing the
  earlier ad hoc "direct return" language with one normalized law.
  Governance drift-guard tokens updated so future edits can't silently
  reintroduce concurrent-writer language.
- **`SOLE-HOLDER:`** return flag + persist-first rule, added from a
  downstream OM-Test field report: an execution-seat agent's rollback
  anchors (config md5, backup path) existed only in its return until
  persisted. The packet's single writer now persists sole-holder facts
  immediately on return, ahead of the normal durability window.

## 2026-06-29 (v1.19.1 — issue-sync test-hardening + soft-fail diagnostic)

- Commit hash: pending (staging→main PR merge)
- Closes the non-blocking coverage/diagnostic gaps deferred from the v1.19.0
  final review. Patch bump to `1.19.1-1.0.0`. No new files; the default-off
  layer is unchanged in behavior except the diagnostic improvement below.
- **Changed — `tools/issue-sync.sh` surfaces backend diagnostics on soft-fail.**
  The Gitea/GitHub create+edit functions previously ran `tea`/`gh` with
  `2>/dev/null`, hiding the backend error when a sync soft-failed (exit 4). They
  now surface the backend's stderr while keeping the soft-fail contract intact
  (exit 4, no `.issue` sidecar written on a failed create, idempotent).
- **Added — +14 `tools/tests/issue-sync.test.sh` cases:** GitHub edit + GitHub
  soft-fail (mirroring Gitea); hyphenated-topic recipient parse anchored to
  reject `role:<recipient>-*` corruption; exact banner (incl. em dash);
  `--type blocker` Operator assignee; label comma-separation.

## 2026-06-29 (v1.19.0 — Issue/project mirror: visibility & coordination layer)

- Commit hash: pending (staging→main PR merge)
- Adds an **optional, default-off, host-agnostic** Issue/board mirror so
  inter-agent comms gain Operator visibility, gate tracking, and notifications —
  while git files remain the source of truth. Bumped template version to
  `1.19.0-1.0.0`. Assembled from the `CHANGELOG.d/issue-mirror.md` fragment at
  the staging gate. Enable with `MINION_ISSUES=on` after bootstrapping the board;
  off, the layer is inert.
- **`tools/issue-sync.sh`** — one-way projection of git-native packets onto the
  host Issue tracker (files always win). Subcommands `host` / `render` / `sync`;
  `sync --type mail|gate|blocker|pipeline|chat --packet <path>` (pipeline =
  per-run, chat = per-day). Idempotent via a `.issue` sidecar; soft-fail (exit 4)
  never blocks a handoff; disabled/CLI-absent → no-op exit 0.
- **`tools/issue-board-bootstrap.sh`** — idempotent label bootstrap (the standard
  `type:`/`role:` set); board creation is manual per the runbook. Safe to re-run.
- **Backends:** Gitea full create/edit via `tea`; GitHub interface-ready via `gh`
  (same verbs + exit-code contract; Projects-v2 board wiring deferred).
- **Mapping (tiered granularity):** per-packet mail, per-gate gate/blocker
  (assigned to the Operator), `staging→main` gate = the PR card, per-run pipeline,
  per-day chat. Labels on two axes (`type:`/`role:`); status lives in the board
  column (`Triage → In Progress → Awaiting Review → Awaiting Operator → Done`).
- **Docs:** new `docs/issue-mirror-model.md` (canonical model) and
  `docs/runbooks/issue-board-setup.md` (OM-owned setup, Gitea + GitHub recipes).
  `MEMORY.md` Communication Model + PM/CM/DM charters wired to the layer.
- **Meta:** export-manifest rows for the new tools/docs (`.issue` sidecars are
  Class B / downstream-owned, not exported); offline fake-provider tests keep the
  full `tools/tests/*.test.sh` suite green.

## 2026-06-27 (v1.18.0 — Branching & release model for minions)

- Commit hash: pending (staging→main PR merge)
- Adopts a 4-tier `feature → dev → staging → main` branching model into the
  minion workflow, dogfooded through its own flow and documented as the
  downstream convention. Bumped template version to `1.18.0-1.0.0`. Assembled
  from the `CHANGELOG.d/branching-model.md` fragment at the staging gate.
- **New canonical doc: `docs/branching-and-release-model.md`.** Single source of
  truth for the branches, the eight-step promotion flow, the gate-authority
  table, the Class-A/Class-B coordination plane, the CHANGELOG-fragment
  mechanism, the staleness rule, hotfix/rollback, and a 3-tier downstream
  variant.
- **Relocated hard-stop.** The single Operator hard-stop moves to `staging→main`
  (a pull request); `feature→dev` and `dev→staging` are autonomous CLI merges.
  `MEMORY.md` and `AI.md` updated (still exactly three hard-stops); the
  governance test was extended to assert the relocated wording and the
  coordination plane in both files.
- **Class-A / Class-B coordination plane.** Class A (`MEMORY.md`, `AI.md`,
  `CLAUDE.md`, `AGENTS.md`, `minions/roles/*`, `ROADMAP.md`, `TODO.md`,
  `minions/chat/`) is mainline-authoritative; Class B (a feature's mail packet,
  plan, specs, and `CHANGELOG.d/<topic>.md`) travels with the branch and merges
  up. `AI.md` gains "Reading Truth in a Multi-Branch World".
- **CHANGELOG fragment mechanism.** Feature branches write
  `CHANGELOG.d/<topic>.md` instead of editing `CHANGELOG.md`; DM assembles the
  fragments into `CHANGELOG.md` and deletes them at the staging gate. Eliminates
  cross-branch `CHANGELOG.md` conflicts. `MEMORY.md` CHANGELOG Maintenance Rule
  updated accordingly.
- **Role charters** (`CM`, `OM`/`OM-Test`, `DM`, `PM`) gain Branch Ownership:
  CM authors fragments + drives `feature→dev`; OM-Test validates `dev` + drives
  `dev→staging`; OM validates `staging`, deploys/tags `main`, owns hotfix +
  rollback; DM assembles the CHANGELOG + confirms Class-A doc-sync; PM runs the
  final gate and opens the `staging→main` PR.
- **VCS-host-agnostic.** Model and guardrail docs speak in host-neutral terms
  ("pull request", "the project's VCS host"). Host-specific setup lives in the
  renamed `docs/runbooks/branch-setup.md` as interchangeable **Gitea** and
  **GitHub** recipes. The `tea`/`gh` CLIs are optional conveniences (installable
  without Homebrew); the web UI is the toolless fallback in each.
- **Meta:** `docs/export-manifest.md` gains rows for the new doc, runbook, and
  `CHANGELOG.d/`; `minion-version.md` bumped with an annotation; `feedback.md`
  captures two promote-candidate portability rules (no tool/installer
  assumptions; host-agnostic model).

## 2026-06-24 (v1.17.0 — Shadow-first / dark-ship risk posture)

- Commit hash: pending (next commit)
- Canonizes the deferred downstream "shadow-first" pattern as an **optional**
  risk posture. Bumped template version to `1.17.0-1.0.0`. **No code shipped** —
  the template carries the posture and contract; each downstream implements it in
  its own stack.
- **new doc: `docs/risk-posture-shadow-first.md`.** Generic, domain-neutral
  write-up of the 4-layer pattern (flag-default-off zero-compute pass-through →
  pure comparator emitting `{MATCH, EXPECTED, REGRESSION}` by exact canonical
  equality → empty-by-default `EXPECTED_DIVERGENCES` allow-list with
  `(note_id, justification, predicate)` entries → adopt-on-MATCH + per-decision
  tripwire fallback that counts every divergence), the isolation-test-with-teeth
  discipline (all-OFF byte-identity + a forced-divergence case + a paired
  adopt-changes-it case so the suite can't be vacuous), the third-outcome
  adopt-a-justified-divergence mechanism, and a 7-piece minimal contract. Includes
  an explicit **when-NOT-to-use** (greenfield / no incumbent / non-critical →
  overkill) so it doesn't read as a mandate.
- **MEMORY.md Deployment Discipline** gains an opt-in pointer to the posture.
- **export-manifest.md** lists the new doc (`template-replace`, `feature`,
  PM / AM) so downstreams receive it.
- Distilled from the Molloy-trading-bot downstream's implementation (it runs the
  pattern across multiple independent decision points); trading-specific machinery
  deliberately left out. Class ②/dual-vendor from the same packet was already
  shipped in v1.16.0; this resolves the deferred class ①.
- **cross-tool review:** dual-vendor dogfood (Codex + Copilot) — both
  AGREE-WITH-NITS (Copilot: SHIP). Applied: generalized a "test/paper" domain
  leak, added the side-effect-isolation caveat (observe-and-discard is risk-free
  only if the shadow recompute is pure or its writes are sinked), required
  same-input capture, and added an allow-listed-EXPECTED adopt test case.

## 2026-06-24 (v1.16.0 — Downstream feedback: review-ergonomics quick wins)

- Commit hash: pending (next commit)
- Adopted the low-risk, broadly-applicable items from a Molloy-trading-bot
  downstream feedback packet (heavy-use observations). Bumped template version to
  `1.16.0-1.0.0`. Deferred (Operator's call): parallel/domain-scoped review
  cadence, and the shadow-first risk posture + operator-facing-craft items.
- **review brevity (SM/DM charters).** `minions/roles/SM.md` and `DM.md` review
  postures now mandate **deltas-only** output: one-line verdict, then only action
  items + load-bearing evidence; passing checks collapse to a single "rest
  verified clean" line (no verbatim re-quoting, no all-green tables). Review
  reports were running 50–80 lines for a ~5-line actionable core.
- **dual-vendor on security diffs (cross-tool doc).** `docs/cross-tool-orchestration.md`
  now says to run BOTH `codex` and `copilot` on security/control-surface changes
  (each catches HIGHs the other clears), and to treat vendor severity as input and
  re-triage against repo evidence (vendors miscalibrate) — matching the template's
  own dogfooded practice.
- **operator-facing surfaces as definition-of-done (MEMORY.md).** Execution
  Quality gains a bullet: a change that adds/alters a config flag, journal/log
  event, metric, or feature must review the operator-facing surfaces (config
  editor, dashboard, runbooks) before done — flags drift out of the UI silently.
- **worktree pruning note.** `docs/cross-tool-orchestration.md` (delegate
  worktrees) and `.claude/agents/README.md` (a new Worktree Hygiene section) note
  that worktree-isolated agents accumulate leftover worktrees; prune after the
  branch lands (`git worktree remove` / `git worktree prune`).
- **charters-as-living-state onboarding.** `docs/operator-onboarding-checklist.md`
  now reinforces that each role keeps its own `minions/roles/*.md` current as
  living state — surfacing a high-value habit at onboarding, not just in MEMORY.md.
- **cross-tool review:** dogfooded dual-vendor review (Codex + Copilot via the
  fixed `--prompt -` path — itself an exercise of the dual-vendor practice this
  change documents). Both AGREE-WITH-NITS; all nits applied: vendor-neutral
  severity phrasing (dropped "codex over-rates" from the exported doc), reconciled
  the one-line-verdict wording with the existing findings-first order, and
  cross-referenced "both vendors on security" in the `/ship` stage.
- governance + xtool suite green. The "agents linger as Running / TaskStop
  doesn't recognize IDs" item is a Claude Code harness behavior, not the template —
  routed separately as advice, not a template change.
- Release note: version bumped and CHANGELOG recorded; the `v1.16.0` git tag and
  push to `main` remain an Operator-gated release step (hard-stop), not done here.

## 2026-06-24 (v1.15.0 — Triaged Copilot .github prompt-eval findings)

- Commit hash: pending (next commit)
- First real application of the v1.13.0 Instruction-File Audit Rule: triaged the
  25 prompt-evaluation findings Copilot logged in `AI/open-questions.md` across
  three `.github/` instruction files. Bumped template version to `1.15.0-1.0.0`.
- **fix: 3 clarifications to `.github/instructions/documentation-quality.instructions.md`** —
  defined the `<project-key>` placeholder (substitute the submodule's directory
  name); tied the undefined "gap packet" term to `minions/mail/`; replaced the
  vague "documentation-focused `*.md` files" with concrete examples (guides, ADRs,
  runbooks). Verified both terms were undefined repo-wide before fixing.
- **rejected 22 findings as not-actionable.** `.github/copilot-instructions.md` (9)
  and `.github/agents/README.md` (8) are thin-by-design — "undefined threshold /
  missing fallback" diagnostics are deliberate (detail lives in `MEMORY.md` /
  `AI.md`), already covered (rm "recommends only" is stated), or governance-locked
  (the autonomous-vs-hard-stop line is byte-shared with `CLAUDE.md`/`AGENTS.md`).
  No changes to the two governance-scanned files.
- **chore:** removed the article scratch file `AI/thoughts.md` (an external
  4-agent-pipeline how-to, already superseded by `/ship` + the minion roles, and
  partly contradicting the no-tool-whitelist decision).
- **register:** the three Copilot "Resolve prompt-evaluation findings" entries
  graduated from `AI/open-questions.md` into `AI/decisions.md` (2026-06-24).
- Release note: version bumped and CHANGELOG recorded; the `v1.15.0` git tag and
  push to `main` remain an Operator-gated release step (hard-stop), not done here.

## 2026-06-24 (v1.14.0 — xtool-call.sh review-path hardening)

- Commit hash: pending (next commit)
- Hardens the `review` path of `tools/xtool-call.sh` — the mirror of the
  `delegate` hardening that downstream feedback drove in 1.11.1. Surfaced while
  dogfooding the cross-tool review for 1.13.0 (Copilot silently ran a garbage
  review on a malformed prompt and the wrapper still reported success). TDD:
  10 new failing cases written first, then fixed; suite now 53/53 green,
  dependency-free. Bumped template version to `1.14.0-1.0.0`.
- **fix (A): `--prompt -` now reads stdin.** Previously `--prompt -` set the
  prompt to the literal string `-` (only a standalone `-` token read stdin) —
  codex errored loudly, but copilot ran a garbage review and the envelope still
  said `ok`. `--prompt -` and a standalone `-` are now equivalent.
- **fix (B): review envelope no longer lies on failure.** `run_review` emitted
  `status: "ok"` unconditionally even when the provider exited non-zero. It now
  emits `review-failed` on non-zero rc (the envelope is the durable artifact a
  caller parses). `delegate` mode already had rich failure statuses; `review`
  now matches.
- **fix (C): empty prompt and empty output fail loudly.** An empty prompt
  (including `--prompt -` with empty stdin) is rejected with exit 2 before any
  provider call; a provider that exits 0 but produces empty/whitespace-only
  output is flagged `review-empty-output` with exit 4 instead of a false `ok`.
- **context:** the downstream (Molloy Trading Bot) did not modify the script —
  its committed `xtool-call.sh` is the untouched 1.11.1 baseline, and its earlier
  script feedback (F2 slug sanitization, F4 failed-delegate cleanup, the copilot
  web-fetch note) is already absorbed. These three fixes are net-new review-path
  hardening, not a downstream port.
- **cross-tool review:** dogfooded read-only second opinions (Codex + Copilot via
  `tools/xtool-call.sh`, invoked through the just-fixed `--prompt -` stdin path —
  a live confirmation of fix A). Copilot AGREE (no nits); Codex AGREE-WITH-NITS.
  Both nits applied: `usage()` marks `--prompt` required, and a copilot
  empty-output test was added (the original regression was copilot-specific).
- Release note: version bumped and CHANGELOG recorded; the `v1.14.0` git tag and
  push to `main` remain an Operator-gated release step (hard-stop), not done here.

## 2026-06-24 (v1.13.0 — Instruction-File Audit Standard)

- Commit hash: pending (next commit)
- Establishes a standing workflow convention: audit `CLAUDE.md` and related AI
  instruction/prompt files for quality whenever they change during template
  improvement or upgrade work. Bumped template version to `1.13.0-1.0.0`.
- **convention: Instruction-File Audit Rule.** New rule in `MEMORY.md` — when
  `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `minions/roles/*.md`,
  the `.github/agents/` / `.codex/agents/` / `.claude/agents/` launchers, or this
  repo's slash-command / skill prompt files change, audit them for clarity,
  accuracy, consistency, staleness, and drift before handoff. The manual audit
  (subagent + rubric) is the cross-tool baseline; built-in analyzers are shortcuts
  where available (Claude `/claude-md-improver`; Copilot `/analyze-prompt` in
  surfaces that expose it; Codex manual). `DM` owns instruction-file truth; each
  minion audits files it changes in its own lane.
- **decision + cross-tool review:** recorded in `AI/decisions.md` (2026-06-24).
  Dogfooded read-only second opinions (Codex + Copilot via `tools/xtool-call.sh`)
  both returned AGREE-WITH-NITS; both nits applied — added the Copilot entrypoint to
  the trigger list, and corrected the tool mapping after Copilot CLI reported it has
  no `/analyze-prompt`, making the manual audit the universal baseline.
- Release note: version bumped and CHANGELOG recorded; the `v1.13.0` git tag and
  push to `main` remain an Operator-gated release step (hard-stop), not done here.

## 2026-06-20 (v1.12.0 — Upgrade-Process Tooling)

- Commit hash: pending (next commit)
- Upgrade-process improvements from downstream feedback (Molloy Trading Bot, on
  running the `1.11.0 → 1.11.1` upgrade). Adds the second piece of executable
  tooling after `xtool-call.sh`. Bumped template version to `1.12.0-1.0.0`.
- **feat (#1): annotated release git tags.** Releases are now published as git tags
  (`v1.11.0`, `v1.11.1`, `v1.12.0`, …) so downstreams detect drift with
  `git ls-remote --tags` and diff upstream changes with `git diff <tag> <tag>` —
  no full clone or manual `.next/` staging needed. Convention documented in
  `minion-version.md` (Release Tagging) and `docs/downstream-upgrade-playbook.md`
  (Detecting Upstream Drift).
- **feat (#5): `tools/upgrade-classify.sh`.** Given OLD + NEW export-ready snapshots
  (and optional LIVE repo), prints each changed file's export-manifest class and its
  live-vs-snapshot divergence (identical / diverged / missing / error) — automating
  the discover + classify + verify-divergence front half of an upgrade. 15 TDD cases.
- **fix (#2): governance test location ambiguity.** `governance-consistency.test.sh`
  now accepts `--root` / `GOV_ROOT` and prints the resolved ROOT + scanned file set,
  so running a clone's copy by mistake can't silently produce a misleading PASS.
- **feat (#3): externalized governance scan list.** The scan file list moved to
  `tools/tests/governance-scan.allow` (downstreams extend it); falls back to the
  built-in default. Kept an allowlist, not a blind glob — descriptive docs
  (CHANGELOG, AI/decisions, the playbook) quote the retired norm and would
  false-positive.
- **docs (#4, #6): scale ceremony to the delta.** Playbook now marks
  `.minions-template.next/` staging optional for contained patches (shallow clone +
  `upgrade-classify.sh` or `git diff <tag> <tag>` suffices) and sanctions a
  one-line provenance entry for no-decision patches.
- **cross-vendor review:** dogfooded Codex `/second-opinion` on this branch caught,
  in the new `upgrade-classify.sh`, a misclassification (strategy grep'd from the
  whole row, not the cell), a `cmp`-error-as-`diverged` bug, leading-hyphen filename
  option-injection, a missing-option-value infinite loop (in all three arg parsers),
  and an O(files×rows) perf blowup (60-file classify: >60s → ~0.9s after parsing the
  manifest once). All fixed with regression tests before merge.
- Added:
  - `tools/upgrade-classify.sh`, `tools/tests/upgrade-classify.test.sh`
  - `tools/tests/governance-scan.allow`
- Updated:
  - `tools/tests/governance-consistency.test.sh` (`--root`/`GOV_ROOT` + banner + allowlist)
  - `docs/downstream-upgrade-playbook.md` (drift-detection, `.next/`-optional, classify-tool wiring, lighter provenance)
  - `minion-version.md` (Release Tagging section), `docs/export-manifest.md`, `CHANGELOG.md`, `AI/decisions.md`

## 2026-06-20 (v1.11.1 — Downstream-Feedback Hardening)

- Commit hash: pending (next commit)
- Hardening pass from downstream upgrade feedback (Molloy Trading Bot, via an SM
  review of a real `1.10.0 → 1.11.0` upgrade). No new capability — correctness,
  security, and doc precision only. Bumped template version to `1.11.1-1.0.0`.
- **fix (correctness): `governance-consistency.test.sh` could false-PASS.** The
  line-based grep missed the retired norm when wrapped across lines in prose. The
  detector now normalizes whitespace whole-file and keys on order-independent
  `spawn`+`automatic` / `auto-spawn` / `on its own initiative` patterns
  (sentence-bounded on `.?!`); the false-positive-prone `ask…explicit` branch was
  dropped (the canonical norm is already caught by `spawn…automatic`, and that branch
  mis-flagged legitimate text like "ask for explicit approval before merging"). It
  self-tests each detector signal in isolation against positive and negative samples
  so the detector itself is regression-tested.
- **fix (security, `delegate` mode): F2 — path-unsafe `--role`/`--topic`.**
  `tools/xtool-call.sh` now rejects a slug containing `..` or characters outside
  `[A-Za-z0-9._-]` before creating any branch/worktree, closing a path-traversal /
  unpredictable-placement gap.
- **fix (operational + data-safety, `delegate` mode): F4 — failed-delegate state.**
  A failed delegate now measures work against the *base commit* the worktree was
  created from (not the worktree's moving HEAD), so a delegate that **committed** its
  output before failing is never mistaken for "no work" and deleted. It self-cleans
  worktree+branch only when nothing was produced (freeing the topic for retry), keeps
  partial/committed work with an explicit recovery hint otherwise, and discloses
  residual state if cleanup itself fails rather than claiming success. Also rejects
  charset-safe-but-git-ref-invalid slugs (e.g. `.`, trailing `.lock`) via
  `git check-ref-format`, and makes the worktree-collision message actionable.
- **cross-vendor review:** this pass was itself reviewed by an independent Codex
  second opinion run through `tools/xtool-call.sh` (dogfooding `/second-opinion`). It
  caught a data-loss bug in the first-draft F4 fix (committed work) and remaining
  detector false +/− that a same-context review missed; both are folded in above.
- **docs:** noted copilot's undenied `url`/`web-fetch` read-only fetch channel in
  `docs/cross-tool-orchestration.md` (confidentiality consideration, opt-in deny);
  enumerated the `.superpowers/` `.gitignore` addition in the v1.11.0 entry; added a
  per-file divergence-measurement step and tightened the project-local norm-scan
  guidance (specific phrasing, not broad keywords) in the upgrade playbook, plus a
  `1.11.1` Version-Specific Required Changes entry.
- Updated:
  - `tools/tests/governance-consistency.test.sh`
  - `tools/xtool-call.sh`
  - `tools/tests/xtool-call.test.sh`, `tools/tests/fixtures/make-fake-provider.sh`
  - `docs/cross-tool-orchestration.md`
  - `docs/downstream-upgrade-playbook.md` (`1.11.1` entry + divergence step + scan-precision note)
  - `CHANGELOG.md`, `minion-version.md`, `AI/decisions.md`

## 2026-06-20 (Cross-Tool Orchestration — shipped)

- Commit hash: pending (next commit)
- Shipped the cross-tool orchestration feature: a provider-agnostic primitive that
  lets the active orchestrator invoke another installed AI CLI (Codex, Copilot)
  headlessly as an independent reviewer or a delegated worker.
- Added `tools/xtool-call.sh` — the first executable code in a previously
  markdown-only template. Supports two providers (`codex`, `copilot`), two postures
  (`review` read-only, `delegate` isolated-worktree), and three exit codes
  (`0` success, `2` usage/bad-arguments error, `3` provider-unavailable). Never merges; human gate always required.
- Added `.claude/commands/second-opinion.md` (`/second-opinion`) — read-only
  cross-vendor review; calls `xtool-call.sh review`; surfaces disagreements to the
  Operator without resolving them.
- Added `.claude/commands/delegate.md` (`/delegate`) — isolated-worktree cross-vendor
  implementation; calls `xtool-call.sh delegate`; merge is gated on Operator approval.
- Added a cross-vendor review stage to `/ship` Pipeline Mode
  (`docs/minion-prompt-modes.md`): after the CM read-only verdict, an independent
  review from a different vendor runs (read-only via `tools/xtool-call.sh`), and
  its verdict is folded into the closeout evidence chain before the Operator gate;
  a material unresolved disagreement is a hard-stop.
- Added `docs/cross-tool-orchestration.md` — the exported protocol doc covering the
  review/delegate/ship workflow, exit-code contract, and governance rules (operator
  reference).
- Added `tools/tests/` — TDD test suite (`xtool-call.test.sh`, fixtures) and
  governance-consistency test (`governance-consistency.test.sh`); dependency-free
  bash with PATH-shimmed fake providers.
- Governance change: retired the "do not spawn role agents automatically" norm in
  favor of **autonomous orchestration** bounded by three hard-stops: (1) never merge
  or push to `main` without Operator gate; (2) never take destructive or production
  actions; (3) never resolve genuine AI disagreement autonomously.
- Added:
  - `tools/xtool-call.sh`
  - `tools/tests/xtool-call.test.sh`
  - `tools/tests/governance-consistency.test.sh`
  - `tools/tests/fixtures/`
  - `.claude/commands/second-opinion.md`
  - `.claude/commands/delegate.md`
  - `docs/cross-tool-orchestration.md`
- Updated:
  - `docs/minion-prompt-modes.md` (cross-vendor review stage in `/ship`)
  - `.claude/commands/ship.md` (cross-vendor review integration)
  - `docs/export-manifest.md` (new rows; `AI/specs/`, `AI/plans/` do-not-export)
  - `AI/decisions.md` (governance decision entry)
  - `.gitignore` (`.claude/worktrees/` and `.superpowers/` exclusions)
  - `minion-version.md`
  - `docs/downstream-upgrade-playbook.md` (`1.11.0` Version-Specific Required
    Changes entry: governance norm = `REQUIRED` tool-neutral baseline,
    cross-tool feature = `REQUIRED`-if-using, manual-merge endorsed for legacy
    downstreams, tool-parity caveat; plus a governance-norm callout in the
    Minimum PM Upgrade Packet)
- Bumped template version to `1.11.0-1.0.0` in `minion-version.md`

## 2026-06-20 (Cross-Tool Orchestration — design spec)

- Commit hash: pending (next commit)
- Added a design spec (planning artifact, not yet implemented) for **federated
  minions / cross-tool orchestration**: a provider-agnostic primitive that lets
  the active orchestrator invoke another installed AI CLI (Codex, Copilot)
  headlessly as an **independent reviewer** or a **delegated worker**, capturing
  results into the controlled repo surfaces while the orchestrator keeps sole
  authority over what becomes truth and what reaches `main`.
  - Two postures supplied per call: **review** (read-only, no writes) and
    **delegate** (writes only inside an isolated git worktree; merge is gated).
  - Mechanism: markdown commands (`/second-opinion`, `/delegate`) plus a thin
    `tools/xtool-call.sh` wrapper — the first executable code in a previously
    markdown-only template (recorded as a deliberate decision).
  - Plans a `/ship` integration adding an independent cross-vendor review stage.
  - Includes a governance change: retire the "do not spawn role agents
    automatically" norm in favor of **autonomous orchestration** bounded by three
    hard-stops (merge/push to `main`, destructive/production actions, unresolved
    AI disagreement).
  - Spec is template-maintainer-local (`AI/specs/`, do-not-export). See
    `AI/specs/2026-06-20-cross-tool-orchestration-design.md`.
  - Added the matching implementation plan (9 TDD tasks; dependency-free bash
    test harness with PATH-shimmed fake providers) at
    `AI/plans/2026-06-20-cross-tool-orchestration.md` (also do-not-export).

## 2026-06-18 (Pipeline Mode + Two-Channel Communication)

- Commit hash: pending (next commit)
- Added pipeline mode (`/ship`): a PM-orchestrated execution track that chains
  the existing minions into an automated plan → implement → test → review run
  for a single bounded feature, adapting the four-stage specialist-pipeline
  pattern to the existing roles rather than cloning a parallel agent set.
  - `AM` plans (spec-only), `CM` implements (implement-only posture), a fresh
    `CM` tests (test-only, does not fix failures), `SM` reviews conditionally on
    security surface, a fresh read-only `CM` returns a SHIP / NEEDS WORK / BLOCK
    verdict. Posture constraints live in the spawn prompts, not the agent files.
  - Gates pause the run for the Operator on spec `OPEN QUESTION`s, test failure,
    and NEEDS WORK / BLOCK verdicts. The pipeline never merges or pushes.
- Introduced the **two-channel communication model** to reduce `minions/mail/`
  traffic: intermediate orchestrated-run results use a **direct-return channel**
  (held in the orchestrator's context), and the orchestrator consolidates one
  durable artifact at run end; `minions/mail/` remains the deliberate-track
  surface for formal gates and cross-session handoffs.
- Documented **Phase 2** (planned, not built): optional Sonnet-tier `coder` and
  `tester` launchers to swap model tiers for the mechanical stages without
  changing the architecture.
- Added downstream-upgrade guidance: a **Version-Specific Required Changes**
  section in `docs/downstream-upgrade-playbook.md` with a `1.10.0` entry that
  labels each item `REQUIRED` / `RECOMMENDED` / `OPTIONAL`, flags the comm-stack
  `MEMORY.md` merge and the non-manifest `.gitignore` edit as merge-blocking, and
  states the Claude-Code-only `/ship` tool-parity caveat. Wired it into the
  numbered workflow (new step 5) and the Minimum PM Upgrade Packet.
- Hardened the export manifest so criticality is a first-class, durable signal:
  - Added a `Criticality` column (`baseline` / `feature` / `reference` / `n/a`)
    and a "Criticality Meanings" legend to `docs/export-manifest.md`, classifying
    every tracked file. `Upgrade strategy` says how to bring a file across;
    `Criticality` says how much it matters that you do.
  - Added `.gitignore` to the manifest as `manual-merge` / `baseline` (it was
    previously untracked), closing the gap where future template `.gitignore`
    additions could silently fail to propagate downstream.
- Added:
  - `.claude/commands/ship.md`
- Updated:
  - `MEMORY.md` (Communication Model — two-channel model)
  - `docs/downstream-upgrade-playbook.md` (Version-Specific Required Changes)
  - `docs/export-manifest.md` (Criticality column, `.gitignore` row)
  - `docs/minion-prompt-modes.md` (Pipeline Mode section, `/ship` table row,
    Phase 2 intent)
  - `minions/roles/PM.md` (Pipeline Orchestration capability)
  - `.claude/agents/README.md` (pipeline track vs. deliberate track)
  - `.gitignore` (ignore ephemeral `.pipeline/` scratch space)
  - `minion-version.md`
- Bumped template version to `1.10.0-1.0.0` in `minion-version.md`

## 2026-06-12 (Pairings as Onboarding/Upgrade Step)

- Commit hash: pending (next commit)
- Made wiring this project's minion↔plugin pairings an explicit onboarding and
  upgrade step, turning `docs/minion-plugin-pairings.md` from a passive reference
  into part of the standard flow:
  - onboarding: a checklist line in `docs/operator-onboarding-checklist.md`, a
    numbered step in `docs/downstream-onboarding-playbook.md`, and a step in the
    `INIT.md` startup sequence — review the pairings doc and add "use-when" lines
    (plus any scoped restricted-role whitelist entries) for the integrations the
    project actually uses; skip pairings whose plugin is absent.
  - upgrade: a step in `docs/downstream-upgrade-playbook.md` — re-review the
    refreshed recommendation map and confirm the project's wired pairings (local
    role-charter customizations) survive the role-file merge; add/remove charter
    lines as the project's stack changes.
- Updated:
  - `INIT.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `minion-version.md`
- Bumped template version to `1.9.1-1.0.0` in `minion-version.md`

## 2026-06-12 (Minion-Plugin Pairings)

- Commit hash: pending (next commit)
- Added `docs/minion-plugin-pairings.md` — recommended, **conditional** pairings
  between the minion roles and external integrations (plugins / MCP connectors /
  skills). Use a pairing if the integration is present; fall back to native repo
  surfaces/tools otherwise. No specific vendor is hard-wired into any agent's
  tools allowlist — the portable value is the mapping (which kind of integration
  serves which role), not the vendor.
- Added tool-agnostic "use-if-available" lines to the `PM` charter (issue-tracker
  / planning integrations, as coordination — not product code) and the `RM`
  charter (a web-research integration such as Nimble alongside `deep-research`,
  recommend-only still applies). Operator-confirmed lanes: PM ↔ issue tracker,
  RM ↔ Nimble.
- Documented the activation rule: unrestricted minions inherit session
  skills/connectors and only need the charter "use-when" nudge; the restricted
  `RM` additionally needs a scoped whitelist entry (`Skill(<plugin>:<skill>)` /
  `mcp__<plugin>_<server>__*`) to reach a pairing — kept as a documented opt-in,
  not hard-wired, so it degrades gracefully downstream.
- Added:
  - `docs/minion-plugin-pairings.md`
- Updated:
  - `minions/roles/PM.md`
  - `minions/roles/RM.md`
  - `README.md`
  - `docs/export-manifest.md`
  - `AI/decisions.md`
  - `minion-version.md`
- Bumped template version to `1.9.0-1.0.0` in `minion-version.md`

## 2026-06-12 (RM deep-research Skill)

- Commit hash: pending (next commit)
- Added `Skill(deep-research)` to the Claude RM subagent's `tools:` whitelist
  (`.claude/agents/rm.md`), giving the research minion a fan-out/source-verified/
  cited-synthesis engine. A `tools:` allowlist excludes the Skill tool and MCP
  tools unless listed, so RM — the research role — had ironically been the only
  minion locked out of skills/connectors.
- Scoped via `Skill(deep-research)`, not blanket `Skill`, to preserve RM's
  mechanical code-prohibition: a research skill adds an investigation engine
  without letting RM invoke file-writing/executing skills (docx, commit, etc.).
  The six unrestricted minions already inherit all session skills + connectors by
  default and need no change.
- Connectors (MCP) left off RM for now — it already has native WebSearch/WebFetch,
  and no research-relevant MCP server is configured; it's a one-line `mcp__<server>`
  add when one exists.
- Updated:
  - `.claude/agents/rm.md`
  - `.claude/agents/README.md`
  - `AI/decisions.md`
  - `minion-version.md`
- Bumped template version to `1.8.3-1.0.0` in `minion-version.md`

## 2026-06-12 (CM Effort Bump)

- Commit hash: pending (next commit)
- Pinned the Claude CM subagent to `effort: xhigh` in `.claude/agents/cm.md` so it
  reasons at the coding/agentic sweet-spot depth whenever spawned — the persistent
  equivalent of "ultrathink," which is only a per-turn prompt keyword and cannot be
  pinned to a subagent. Chose `xhigh` over `max` (max overthinks for diminishing
  returns and may not persist reliably). The same `effort:` frontmatter lever is
  available for other Claude roles.
- Documented the effort-tuning lever in `.claude/agents/README.md` and recorded the
  decision with rationale in `AI/decisions.md`.
- Updated:
  - `.claude/agents/cm.md`
  - `.claude/agents/README.md`
  - `AI/decisions.md`
  - `minion-version.md`
- Bumped template version to `1.8.2-1.0.0` in `minion-version.md`

## 2026-06-12 (Copilot Bootstrap Feedback Sync)

- Commit hash: pending (next commit)
- Added `feedback.md` to the Copilot bootstrap order so Copilot now reads the
  shared Operator-feedback capture log at session start, matching the Codex and
  Claude entry points.
- Updated:
  - `.github/copilot-instructions.md`
  - `AI/decisions.md`
  - `minion-version.md`
- Bumped template version to `1.8.1-1.0.0` in `minion-version.md`

## 2026-06-12 (Feedback Capture + Advisor Posture Sharpening)

- Commit hash: pending (next commit)
- Added `feedback.md`, a downstream-owned capture log of Operator corrections,
  preferences, and working-style learnings, read at session start. It de-silos
  per-tool memory (Claude's private memory is unreadable by Codex/Copilot) into
  one shared, git-durable, tool-neutral surface.
- `feedback.md` is a capture log, not a source of truth: a promotion path moves
  durable items into the curated surfaces (`MEMORY.md`, role charters, or
  `AI/decisions.md`), so it never competes with `MEMORY.md`. Established as the
  Feedback Capture Rule in `MEMORY.md`. Added the `/feedback` prompt mode for the
  end-of-session extraction practice.
- Wired `feedback.md` into the `CLAUDE.md`/`AGENTS.md` session-start bootstrap and
  the `AI.md` source-of-truth note (flagged as a capture log subordinate to
  `MEMORY.md`). It is exported and present everywhere, so the bootstrap reference
  does not dangle (contrast `AI/`, which is do-not-export and pull-not-push).
- Sharpened the advisor posture in `MEMORY.md` from two internet-post ideas,
  adapted rather than adopted as law: kept "challenge when the framing has a real
  gap" over the rigid "always challenge first" (which produces contrarian
  theater), and added a self-edit line for filler openers and an
  "advisor-not-assistant" framing.
- Recorded both decisions, with rationale, in `AI/decisions.md`.
- Added:
  - `feedback.md`
- Updated:
  - `MEMORY.md`
  - `AI.md`
  - `CLAUDE.md`
  - `AGENTS.md`
  - `README.md`
  - `INIT.md`
  - `AI/decisions.md`
  - `docs/minion-prompt-modes.md`
  - `docs/export-manifest.md`
  - `docs/operator-onboarding-checklist.md`
  - `minion-version.md`
- Bumped template version to `1.8.0-1.0.0` in `minion-version.md`

## 2026-06-12 (Cross-AI Template-Maintenance Layer)

- Commit hash: pending (next commit)
- Added `AI/`, a template-maintainer-local layer where the AIs that maintain
  this template (Claude, Codex, Copilot) record cross-AI consensus and open
  questions about evolving the minion system itself. This is meta-work, distinct
  from `minions/` (downstream project coordination).
- `AI/` is `do-not-export`: like `.mm.md`, it is excluded from downstream
  onboarding and upgrades — projects built from this template do not receive it.
  `AI.md` (the cross-tool protocol) is still exported; `AI/` (our maintenance
  records) is not. `AI/` is pull-not-push and is intentionally NOT wired into the
  per-session bootstrap, to avoid dangling references in exported entry points.
- Established the boundary rule in `MEMORY.md`: template-maintenance coordination
  goes in `AI/` (never `minions/`); project coordination goes in `minions/`
  (never `AI/`).
- Seeded `AI/decisions.md` with the decisions made over this session (projection
  model as source of truth, no-whitelists-except-RM, per-tool model/effort knobs,
  RM-as-consult-not-gate, MM-as-skill-not-subagent, Fable-as-escalation-only,
  entry-point bootstrap) so other tools inherit the reasoning instead of
  relitigating it.
- Added:
  - `AI/README.md`
  - `AI/decisions.md`
  - `AI/open-questions.md`
- Updated:
  - `MEMORY.md`
  - `docs/export-manifest.md`
  - `docs/downstream-onboarding-playbook.md`
  - `minion-version.md`
- Bumped template version to `1.7.0-1.0.0` in `minion-version.md`

## 2026-06-12 (Copilot RM Onboarding)

- Commit hash: pending (next commit)
- Added RM to the Copilot custom-agent surface for parity with Codex and Claude.
- Added:
  - `.github/agents/rm.agent.md`
- Updated:
  - `.github/agents/README.md`
  - `.github/agents/copilot-role-prompts.md`
  - `minion-version.md`
- Bumped template version to `1.6.1-1.0.0` in `minion-version.md`

## 2026-06-12 (Research Manager Minion)

- Commit hash: pending (next commit)
- Added `RM` (Research Manager) as a first-class template role: in-depth research
  and investigation of build issues, vendor-documentation-grounded option
  analysis, and out-of-box next-step recommendations. RM is research-and-recommend
  only — it MAY NOT create or execute code, deploy, or change runtime; it is a
  consult role, not a gate.
- RM is the one sanctioned exception to the no-tool-restrictions rule: the Claude
  projection pins it to a read-only + web whitelist
  (`Read, Grep, Glob, WebSearch, WebFetch`) so code creation/execution is
  mechanically impossible. Safe here because RM never needs write/execute tools.
  Codex has no tool-restriction field, so RM's prohibition is carried in its
  `developer_instructions` prose.
- Added:
  - `minions/roles/RM.md` (charter — source of truth)
  - `.claude/agents/rm.md` (Claude Code subagent, opus)
  - `.codex/agents/rm.toml` (Codex custom agent, `high` reasoning)
- Added the `/research` prompt mode (RM-owned) and RM role mapping in
  `docs/minion-prompt-modes.md`.
- Wired RM into the role set across `MEMORY.md`, `INIT.md`, `README.md`, `AI.md`,
  `CLAUDE.md`, `AGENTS.md`, both agent READMEs, the export manifest, the operator
  onboarding checklist, and the collaboration playbook. Added `RM` to the
  `NEXT OWNER` enums. RM was initially scoped to the Codex and Claude surfaces;
  the Copilot surface (`.github/agents/`) was onboarded separately afterward —
  see the Copilot RM Onboarding entry above.
- Updated:
  - `MEMORY.md`
  - `INIT.md`
  - `README.md`
  - `AI.md`
  - `CLAUDE.md`
  - `AGENTS.md`
  - `.claude/agents/README.md`
  - `.codex/agents/README.md`
  - `docs/export-manifest.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/minion-prompt-modes.md`
  - `docs/collaboration-playbook.md`
  - `minion-version.md`
- Bumped template version to `1.6.0-1.0.0` in `minion-version.md`

## 2026-06-10 (Codex Agent Effort)

- Commit hash: pending (next commit)
- Set Codex minion agent reasoning effort by role while continuing to inherit
  the active session model.
- Changed `pm` from `high` to `medium` reasoning for general planning,
  routing, and gate work.
- Documented the Codex model/effort policy:
  - general project chat/router should usually use `GPT-5.5` with `medium`
    reasoning
  - `am`, `cm`, `sm`, and `om` stay `high`
  - `dm` stays `medium`
  - role TOML files should pin `model` only when a downstream project needs a
    hard cost/performance lane
- Updated:
  - `.codex/agents/README.md`
  - `.codex/agents/pm.toml`
  - `minion-version.md`
- Bumped template version to `1.5.1-1.0.0` in `minion-version.md`

## 2026-06-09 (Claude Code Subagents)

- Commit hash: pending (next commit)
- Added repo-scoped Claude Code subagents for minion roles, mirroring the Codex
  custom agents so Claude Code can spawn role-specific subagents backed by the
  same durable charters in `minions/roles/`.
- Subagents are thin launchers with a "read these first" preamble; durable role
  policy stays in `minions/roles/`. By Operator decision, no per-role `tools:`
  restrictions are applied — full tool access for every role; lane discipline
  stays in the charter prose. Models mirror Codex reasoning tiers (high → opus,
  DM's medium → sonnet).
- Added Operator usage guidance for focused role discussion, single-agent
  investigation, and multi-agent parallel review.
- Added `AI.md` as a cross-tool collaboration protocol for Codex, Claude, and
  other AI assistants.
- Added `CLAUDE.md` and `AGENTS.md` as auto-loaded main-thread entry points so
  Claude Code and Codex bootstrap from `AI.md`/`MEMORY.md` on session start
  instead of relying on the Operator to paste the handoff prompt. Both are thin
  pointers; Codex verified the `AGENTS.md` convention against the current Codex
  manual and now owns that surface.
- Clarified that the `AI.md` tool-selection guidance is a heuristic, not a hard
  ownership rule between Codex and Claude.
- Ignored `.remember/` and PID files so local AI-tool runtime state is not
  accidentally committed.
- Added:
  - `AI.md`
  - `CLAUDE.md`
  - `AGENTS.md`
  - `.claude/agents/README.md`
  - `.claude/agents/pm.md`
  - `.claude/agents/am.md`
  - `.claude/agents/cm.md`
  - `.claude/agents/sm.md`
  - `.claude/agents/dm.md`
  - `.claude/agents/om.md`
- Updated downstream onboarding, upgrade, export, and collaboration guidance so
  `.claude/agents/` is treated as a template-managed Claude Code subagent surface
  alongside `.codex/agents/`.
- Updated:
  - `INIT.md`
  - `MEMORY.md`
  - `README.md`
  - `.gitignore`
  - `docs/collaboration-playbook.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `docs/operator-onboarding-checklist.md`
  - `minion-version.md`
- Bumped template version to `1.5.0-1.0.0` in `minion-version.md`

## 2026-06-09

- Commit hash: pending (next commit)
- Added repo-scoped Codex custom agents for minion roles so Codex can spawn
  role-specific subagents backed by the existing durable charters.
- Added practical Operator usage guidance for focused role discussion,
  single-agent investigation, and multi-agent parallel review.
- Added:
  - `.codex/agents/README.md`
  - `.codex/agents/pm.toml`
  - `.codex/agents/am.toml`
  - `.codex/agents/cm.toml`
  - `.codex/agents/sm.toml`
  - `.codex/agents/dm.toml`
  - `.codex/agents/om.toml`
- Updated downstream onboarding, upgrade, export, and collaboration guidance so
  `.codex/agents/` is treated as a template-managed Codex custom-agent surface.
- Updated:
  - `INIT.md`
  - `MEMORY.md`
  - `README.md`
  - `docs/collaboration-playbook.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `docs/operator-onboarding-checklist.md`
  - `minion-version.md`
- Bumped template version to `1.4.5-1.0.0` in `minion-version.md`

## 2026-06-08 (DM Baseline)

- Commit hash: pending (next commit)
- Added `DM` (Documentation Manager) as a first-class template role for
  documentation truth, reader paths, runbooks, and documentation-sync
  validation.
- Added:
  - `minions/roles/DM.md`
- Updated shared workflow and role guidance so:
  - documentation-only work has a PM -> DM -> PM -> Operator flow
  - implementation/runtime flows route through DM before PM acceptance when
    documented behavior or operator workflow changes
  - `NEXT OWNER` contracts include `DM`
  - prompt modes include `/docs` and `/runbook`
- Updated:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/collaboration-playbook.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `docs/minion-prompt-modes.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/project/mailbox-collaboration-model.md`
  - `minions/README.md`
  - `minions/mail/README.md`
  - `minions/plans/milestone-plan-template.md`
  - `minions/roles/PM.md`
  - `minions/roles/AM.md`
  - `minions/roles/CM.md`
  - `minions/roles/SM.md`
  - `minions/roles/OM.md`
  - `minion-version.md`
- Bumped template version to `1.4.4-1.0.0` in `minion-version.md`

## 2026-06-08

- Commit hash: pending (next commit)
- Added template-level minion prompt modes adapted from operator-provided
  prompt screenshots so minions can use named advisor postures without breaking
  role boundaries.
- Added:
  - `docs/minion-prompt-modes.md`
- Updated shared and role-specific guidance so:
  - minions lead with missing assumptions, risk, or clarification instead of
    empty agreement when the framing is weak
  - consequential claims use `[Certain]`, `[Likely]`, or `[Guessing]`
    confidence tags
  - filler openers are explicitly discouraged
  - `/startup-team`, `/codebase-audit`, `/debug`, `/performance`,
    `/refactor`, `/backend`, `/frontend`, `/tech-lead`, `/security`, and
    `/devops` map to the proper PM/AM/CM/SM/OM owners
- Updated:
  - `MEMORY.md`
  - `INIT.md`
  - `README.md`
  - `docs/collaboration-playbook.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/export-manifest.md`
  - `minions/README.md`
  - `minions/roles/PM.md`
  - `minions/roles/AM.md`
  - `minions/roles/CM.md`
  - `minions/roles/SM.md`
  - `minions/roles/OM.md`
  - `minion-version.md`
- Bumped template version to `1.4.3-1.0.0` in `minion-version.md`

## 2026-04-21 (Later Entry)

- Commit hash: pending (next commit)
- Added shared execution-quality rules so all minions:
  - start non-trivial work from a durable plan, packet, or checklist
  - re-plan when new evidence invalidates the active plan
  - verify behavior before declaring work complete
  - prefer simple, low-impact root-cause fixes over broader or temporary patches
  - label containment clearly and assign follow-up ownership for the final fix
- Updated:
  - `MEMORY.md`
- Bumped template version to `1.4.2-1.0.0` in `minion-version.md`

## 2026-04-21

- Commit hash: pending (next commit)
- Strengthened role-specific execution quality guidance so:
  - `PM` plans non-trivial work in durable checkpoints and re-plans when evidence breaks the active plan
  - `AM` prefers the simplest architecture that fits the project and steps back from structurally hacky solutions
  - `CM` favors minimal root-cause fixes and explicitly distinguishes containment from a final fix
  - `SM` validates reachable risk and favors targeted hardening that closes the real risk surface
  - `OM` establishes runtime truth with operational evidence and prefers the smallest safe restoring action
- Updated:
  - `minions/roles/PM.md`
  - `minions/roles/AM.md`
  - `minions/roles/CM.md`
  - `minions/roles/SM.md`
  - `minions/roles/OM.md`
- Bumped template version to `1.4.1-1.0.0` in `minion-version.md`

## 2026-04-14

- Commit hash: pending (next commit)
- Added a mailbox-first coordination model so actionable minion communication
  moves into packet directories while `minions/chat/` becomes a PM-owned
  summary surface in:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/collaboration-playbook.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `docs/operator-onboarding-checklist.md`
  - `minions/README.md`
  - `minions/chat/README.md`
  - `minions/chat/general-thread-template.md`
  - `minions/chat/topic-thread-template.md`
  - `minions/plans/milestone-plan-template.md`
- Added template-managed mailbox assets in:
  - `docs/project/mailbox-collaboration-model.md`
  - `minions/mail/README.md`
  - `minions/mail/packet-template.md`
- Added ASCII mailbox flow diagrams to make packet ownership and PM summary
  duties easier to onboard in:
  - `docs/project/mailbox-collaboration-model.md`
  - `minions/mail/README.md`
- Corrected mailbox-model drift so shared rules and role charters point minions
  to owned mail packets while `PM` owns same-day chat summaries, and simplified
  the request template to the single-owner packet shape in:
  - `MEMORY.md`
  - `minions/roles/CM.md`
  - `minions/roles/AM.md`
  - `minions/mail/packet-template.md`
- Clarified staged rollout and downstream export behavior so legacy chat packets
  may finish in place, new follow-up packets move to mail, and template packet
  history is not exported into downstream repos
- Bumped template version to `1.4.0-1.0.0` in `minion-version.md`

## 2026-04-12

- Commit hash: pending (next commit)
- Corrected the downstream onboarding/export model so `.minions-template/` is an export-ready snapshot rather than a raw repo copy in:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/collaboration-playbook.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `minion-version.md`
- Clarified that downstream snapshots must exclude Git metadata and `do-not-export` files such as `.mm.md`
- Removed `REQUIREMENTS.md` from the shared required-documentation contract and aligned the baseline around `README.md`, `ROADMAP.md`, and `TODO.md` in:
  - `MEMORY.md`
  - `.mm.md`
- Reordered the initial onboarding sequence so controlled export happens before downstream checklist completion in:
  - `README.md`
  - `INIT.md`
- Bumped template version to `1.3.1-1.0.0` in `minion-version.md`

## 2026-04-11

- Commit hash: pending (next commit)
- Added `AM` (Architect Minion) as a first-class template role for architecture stewardship, system design review, and structural refinement in:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/collaboration-playbook.md`
  - `minions/roles/PM.md`
  - `minions/roles/AM.md`
  - `minions/roles/CM.md`
  - `minions/roles/SM.md`
  - `minions/roles/OM.md`
  - `minions/chat/README.md`
  - `minions/chat/general-thread-template.md`
  - `minions/chat/topic-thread-template.md`
- Strengthened shared git handoff discipline so every minion must commit before workflow handoff, cross-computer handoffs require commit-and-push, and the Operator records per-role handoff mode in:
  - `INIT.md`
  - `MEMORY.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/collaboration-playbook.md`
- Added a vendored downstream-upgrade model with a PM-owned merge playbook and export manifest in:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/collaboration-playbook.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `minion-version.md`
  - `minions/roles/PM.md`
- Added a separate downstream onboarding model so first-time adoption is treated as a controlled export from `.minions-template/`, not a blind repo copy, in:
  - `README.md`
  - `INIT.md`
  - `MEMORY.md`
  - `docs/collaboration-playbook.md`
  - `docs/operator-onboarding-checklist.md`
  - `docs/downstream-onboarding-playbook.md`
  - `docs/downstream-upgrade-playbook.md`
  - `docs/export-manifest.md`
  - `minion-version.md`
- Reconciled shared role-set drift so `SM` remains consistently present in handoff and `NEXT OWNER` contracts while adding `AM`
- Bumped template version to `1.3.0-1.0.0` in `minion-version.md`

## 2026-04-10 (MM Bootstrap)

- Commit hash: pending (next commit)
- Bootstrapped Manager Minion coordination for the current template-maintenance session by:
  - creating `minions/chat/2026-04-10.md` with the MM bootstrap announcement
  - refreshing `.mm.md` `MM Notes` with a timestamped audit of the active template drift backlog
- No template version bump; MM-context and coordination-doc updates only

## 2026-04-10

- Commit hash: pending (next commit)
- Removed `.mm.md` from `.gitignore` so Manager Minion context can sync across Operator machines
- Added and tracked `.mm.md` as a repository maintainer context file for the template repo
- Added Manager Minion scoping, maintainer guardrails, and Operator continuity-support guidance in:
  - `.mm.md`

## 2026-04-08 (Initial Entry)

- Commit hash: pending (next commit)
- Updated shared runtime handoff order to include `SM` between `CM` and `OM-Test` / `OM` in:
  - `MEMORY.md`
- Updated handoff interpretation to define `SM` security posture check before runtime gate in:
  - `MEMORY.md`
- Updated completion contract `NEXT OWNER` allowed values to include `SM` in:
  - `MEMORY.md`
- Bumped template version to `1.2.5-1.0.0` in `minion-version.md`

## 2026-04-08 (Earlier Entry)

- Commit hash: pending (next commit)
- Added a standardized "Completion Handoff Contract" with exact required order and hard rules in:
  - `MEMORY.md`
  - `INIT.md`
  - `minions/chat/README.md`
- Strengthened PM guardrails to explicitly reject handoffs without evidence and clear `NEXT OWNER` assignment in:
  - `minions/roles/PM.md`
- Bumped template version to `1.2.4-1.0.0` in `minion-version.md`

## 2026-04-08

- Commit hash: pending (next commit)
- Added mandatory completion-update requirements so minions always identify next owner and explicit Operator action needed:
  - updated `MEMORY.md`
  - updated `INIT.md`
  - updated role guardrails in `minions/roles/CM.md`, `minions/roles/PM.md`, `minions/roles/OM.md`, and `minions/roles/SM.md`
- Bumped template version to `1.2.3-1.0.0` in `minion-version.md`
- Initialized repository `CHANGELOG.md` as required by template guardrails
