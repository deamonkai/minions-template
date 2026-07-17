# Second Brain Model

This document is the single source of truth for the optional local
second-brain layer — a local, Obsidian-backed Markdown vault. It describes
the design rationale, invariants, write and read paths, vault layout,
security boundary, enablement steps, and the tool reference. `MEMORY.md`,
`AI.md`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, and
`docs/runbooks/second-brain-setup.md` link here; do not duplicate this
content in those files.

Design of record: the Phase 1 design of record (maintainer-local; Phase 2
curation and Phase 3 richness are out of scope for this document and not
yet built).

## Why a Local Corpus Layer

Promoted project knowledge lives in the repo, and a curated slice of it also
reaches the cloud Memory Recall layer (`docs/memory-recall-model.md`). Both
are intentionally narrow: git for auditable history, Memory Recall for
high-precision semantic search over *promoted* knowledge only.

Neither is a good home for the Operator's local fast-onboard corpus — code
and diff snippets, packet bodies, session context, working notes — content
that is genuinely useful to re-onboard quickly but is either too
unrestricted for a third-party cloud service or too voluminous for a
curated recall index (a semantic index over an ambient dump returns noise,
not signal). The second brain is a **local, unrestricted-minus-exclusions
corpus** that fills that gap:

- **Fast local onboarding** — a plain-Markdown vault the Operator browses
  and graphs in Obsidian, and minions read/write through a thin repo-native
  tool, with no dependency on Obsidian being installed or running.
- **A capture inbox distinct from curated recall** — raw notes land in
  `inbox/`; nothing here is presumed high-precision the way a promoted
  Memory Recall entry is.
- **Single-Mac, tool-agnostic** — no MCP dependency, no 3rd-party runtime;
  a small shell tool (`tools/second-brain.sh`) any orchestrator (Claude,
  Codex, Copilot) can call the same way.

## Invariants

The second brain reuses four of Memory Recall's five invariants unchanged,
relaxes one, and replaces the security boundary. See the design doc's D3 for
the full mapping.

1. **Files always win.** The repo is still canonical state. Vault content
   that disagrees with a repo artifact is not authoritative — the repo
   wins. (Vault-origin content that never existed in git is *promoted* into
   git, not reconciled against it, at a future curation pass; Phase 1 ships
   no promotion tooling yet.)

2. **Recall is input, not authority.** The same law that binds subagent and
   Memory Recall output binds second-brain output: it informs decisions, it
   never decides them.

3. **Recalled runtime facts are presumptive.** A vault note describing
   runtime state must still be confirmed live before acting.

4. **Optional and graceful.** The layer is gated on `MINION_SECONDBRAIN=on`
   (default: off). When unset/off, or when the vault directory is absent,
   every second-brain step is a silent no-op. No minion workflow is ever
   blocked by second-brain absence.

5. **Curated and writer-owned — relaxed for the inbox.** Memory Recall
   allows no bulk dumps at all. The second brain relaxes this for the
   **capture inbox only**: `inbox/` accepts batched, orchestrator-mediated
   captures without per-item curation. This relaxation does not extend past
   the inbox — a future curation pass (Phase 2, not yet built) is what
   would promote inbox content into a curated, recall-eligible state.

## Security Boundary (replaces Memory Recall's boundary)

Memory Recall excludes secrets, `SOLE-HOLDER:` facts, personal data, and
packet bodies/diffs/code outright, because its target is a third-party
cloud. The second brain's target is a local vault, so "local" is a location,
not a security property — a plain-Markdown vault is still durable, copyable,
and re-shareable, with weaker access control than a managed cloud. The
boundary is therefore **unrestricted corpus MINUS these excluded classes**,
never a literally-unrestricted dump:

- **Secrets / credentials-adjacent state** — never enters, even locally.
  MEMORY.md's Do-Not-Do rule is unconditional; a local store is still a
  leak vector.
- **`SOLE-HOLDER:` facts** (rollback anchors, checksums, backup paths) —
  git/packet-only. The vault is not a git-durable surface; a copy here both
  exposes the fact and creates a false backup.
- **Personal data** — Phase 1 ships no built-in personal-data pattern (no
  PII regexes). An Operator may opt in to excluding project-specific
  personal-data patterns via `$VAULT/.secondbrain-exclude` (one regex per
  line, `#` comments, absent by default).
- **Vault containment** — the vault path must sit outside any synced or
  backed-up tree (`~/Documents`, iCloud `~/Library/Mobile Documents`,
  Dropbox/Drive/OneDrive) and be Time-Machine-excluded. No Obsidian-Git
  remote on this vault — that is the single rule most likely to betray
  "never leaves the Mac." `tools/second-brain.sh path --check` runs a
  warn-only preflight for this; it never blocks, it only surfaces drift.
- **No public remote, ever.** If the vault is ever versioned at all
  (Phase 1 ships it un-versioned), it is private-only with a pre-commit
  gitleaks gate.

Everything else — code/diff snippets, packet bodies, source docs, personal
working notes, session context — is in-scope corpus content.

## Write Path (capture)

Writes route by content class per the design's D1 table (repeated here for
the second brain's slice of it):

| Content class | Destination |
| --- | --- |
| Distilled, promoted, non-sensitive lesson/decision text | Memory Recall (unchanged) |
| Unrestricted corpus: code/diff snippets, packet bodies, working notes, session context | **Local vault** |
| Secrets / credentials-adjacent | Neither |
| `SOLE-HOLDER:` facts | Git / packet single-writer only |

Capture is **orchestrator-mediated and batched** (the Phase 1 default;
fully-ambient per-writer capture is out of scope — see the design doc's Out
of Scope). The AC-2 exclusion filter runs BEFORE any write, over the full
assembled note (frontmatter + body):

1. A `SOLE-HOLDER:` line, or a match against a fixed set of high-signal
   secret patterns (private-key headers, AWS/GitHub/Slack/Google API-key
   shapes, a generic `key/secret/token/password/bearer = <8+ chars>`
   assignment) → **reject, write nothing**, report the offending class and
   line to stderr, exit 3.
2. Optionally, a match against an Operator-authored
   `$VAULT/.secondbrain-exclude` pattern (absent by default) → same
   reject-and-report behavior.
3. Otherwise → append to `$VAULT/inbox/<timestamp>-<slug>.md` with a small
   YAML-ish frontmatter block (`title`, `tags`, `source`, `date`).

This is **reject-and-report, never redact**: redaction hides leaks and
corrupts meaning, where rejection is atomic and honest about what happened.

Writer ownership follows the single-writer law: a spawned minion never
calls `capture` directly on its own initiative outside the orchestrator's
batching; the orchestrator (top of the spawn chain) mediates capture the
same way it mediates Memory Recall writes.

## Read Path (search)

At run start, the orchestrator runs `tools/second-brain.sh search <query>`
against the vault and folds useful hits into dispatch briefs — the same
posture as the Memory Recall read path. Spawned minions do not need direct
vault access for the default posture; recall rides the brief.

Recall folded into a brief remains input, not authority: recalled runtime
facts are presumptive, and the brief still instructs the receiving agent to
confirm live state first (invariant 3).

## Vault Layout

The vault root is a plain directory of Markdown files, resolved from
`MINION_SECONDBRAIN_VAULT` (default `~/second-brain/`) — never hardcoded.
Obsidian, if installed, simply points at this same directory as its vault;
it is the Operator's GUI/graph layer, not a minion dependency.

| Path | Purpose |
| --- | --- |
| `$VAULT/inbox/` | Batched capture landing zone (append-only, Phase 1) |
| `$VAULT/.secondbrain-exclude` | Optional Operator-authored personal-data exclude patterns (absent by default) |

A future curation pass (Phase 2, not yet built) would add a recall-eligible
tier between the inbox and eventual git promotion; Phase 1 ships only the
inbox.

## Enabling It

The layer is off by default. Enabling it is a two-step process:

1. **Choose and create a vault location** that satisfies the containment
   rule above (outside synced/backed-up trees, Time-Machine-excluded).
2. **Set the gates** in the environment where minions run:

   ```bash
   export MINION_SECONDBRAIN=on
   export MINION_SECONDBRAIN_VAULT=~/second-brain   # only if not the default
   ```

To disable, unset `MINION_SECONDBRAIN` (or set it to any value other than
`on`); the layer goes inert with no cleanup required. Full setup recipes,
verification steps, the smoke test, and rollback are in
`docs/runbooks/second-brain-setup.md`.

## Tool Reference

`tools/second-brain.sh` is the only interface minions use; it never assumes
Obsidian is installed or running.

| Subcommand | Gated? | Purpose | Exit codes |
| --- | --- | --- | --- |
| `capture [--title <t>] [--tag <t>]... [--source <path>] [--file <path>]` | yes | Filter, then append a note to `inbox/`; body from `--file` or stdin | 0 written · 2 usage/empty body · 3 filter reject · 4 I/O |
| `search <query> [--limit <n>] [--scope inbox\|all]` | yes | Read-only recall (`rg` preferred, `grep -r` fallback) | 0 always (including zero hits) |
| `filter [--file <path>]` | no (pure/offline) | The AC-2 exclusion primitive alone, testable with the gate off | 0 clean · 3 trip |
| `scan` | yes | `gitleaks detect --source "$VAULT" --no-git` over the vault | 0 clean/no-op · 5 finding |
| `path [--check]` | no (pure/offline) | Echo the resolved vault path; `--check` runs the warn-only AC-1 preflight | 0 always |
| `migrate-tags` | yes | One-off: convert existing notes' **frontmatter** tags from the inline array (`tags: [a, b]`) to the Obsidian-canonical block list, stripping a leading `#`; body text is never touched; every changed note is backed up first; idempotent | 0 migrated/no-op · 4 I/O |

`capture` writes frontmatter tags as the Obsidian-canonical block list (a
YAML list, no leading `#` — the `#` prefix is for inline *body* tags only) and
strips a leading `#` a caller passes. `migrate-tags` brings vaults captured by
older versions (which emitted the inline `tags: [a, b]` array) up to the same
form: it rewrites only the first frontmatter block, backs up each changed note
under a timestamped `.sb-tag-backup-<ts>/` dir (relative paths preserved), and
is safe to re-run — an already-converted note has no inline-array line to
match, so it is skipped.

`filter` and `path` short-circuit before the `MINION_SECONDBRAIN` gate by
design — the same split `tools/issue-sync.sh` uses between its pure
`render` subcommand and its gated `sync` subcommand — so the exclusion
primitive and the containment preflight stay testable and usable even with
the layer off.
