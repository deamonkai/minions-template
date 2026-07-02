# Memory Recall Model

This document is the single source of truth for the optional memory recall
layer (Mnemoverse, or a compatible memory service). It describes the design
rationale, invariants, write and read paths, domain scheme, security
boundary, enablement steps, and the REST fallback. `MEMORY.md`,
`minions/roles/PM.md`, `AI.md`, and `docs/runbooks/memory-recall-setup.md`
link here; do not duplicate this content in those files.

## Why a Recall Layer

Promoted project knowledge lives in the repo: durable lessons in role files
and `feedback.md`, shared truth in `MEMORY.md`, release summaries in
`CHANGELOG.md`. Git is the primary knowledge surface, and that is
intentional — it keeps history auditable, merge-friendly, and host-agnostic.

A semantic memory service adds value that git-native files do not provide
out of the box:

- **Natural-language recall** — "what did we learn about worktree cwd
  pinning?" retrieves the distilled lesson without knowing which file
  holds it.
- **Cross-session persistence** — recall survives context resets and new
  sessions without re-reading the whole knowledge tree.
- **Cross-tool reach** — the same memories are visible from Claude,
  ChatGPT, Cursor, VS Code, or any tool pointed at the same account.

The recall layer is therefore a *semantic index* over promoted repo
knowledge, patterned on the Issue mirror (`docs/issue-mirror-model.md`):
a view of file state, never a parallel source of truth. It is optional and
off by default.

## Invariants

Five invariants hold unconditionally.

1. **Files always win.** The repo is the canonical state. A memory that
   disagrees with a repo artifact is stale; regenerate the memory from the
   file, never the reverse.

2. **Recall is input, not authority.** The same law that binds subagent
   output in `AI.md` binds recall output: it informs decisions, it never
   decides them, and it is not evidence until verified against repo or
   runtime state.

3. **Recalled runtime facts are presumptive.** A memory describing runtime
   state (branch positions, service status, environment) must be confirmed
   live before acting — the live-state-briefs rule. Briefs that carry
   recall still instruct the receiving agent to verify live state first.

4. **Optional and graceful.** The layer is gated on `MINION_MEMORY=on`
   (default: off). When the variable is unset or off, or when the MCP
   tools / API are absent, every memory step is a silent no-op. No minion
   workflow is ever blocked by memory absence.

5. **Curated and writer-owned.** Only promoted knowledge is mirrored, and
   only the packet's single writer performs memory writes (see
   Single-Writer Durability in `MEMORY.md`). No bulk dumps, no ambient
   capture.

## Write Path

Writes are curated: only promoted items cross into memory, at exactly
three promotion moments.

1. **A `DURABLE LESSONS:` item is applied** — promoted into a role file,
   `feedback.md`, or `MEMORY.md`. Mirror the distilled lesson text, not
   the surrounding discussion. Dropped or rejected lessons are never
   mirrored.
2. **A milestone ships** — mirror the release summary and any accepted
   decisions at CHANGELOG assembly (the staging gate).
3. **The Operator explicitly says "remember this."**

Write shape: `memory_write` with `domain: project:<repo-name>` (this repo:
`project:minions-template`) and concept tags mirroring the lesson's
topics. One memory per promoted item — no bulk dumps.

Writer ownership follows the single-writer law: a spawned minion never
calls `memory_write`; the packet's single writer — the top of the spawn
chain — mirrors promoted items when it makes them durable in the repo.

## Read Path

At run start, the orchestrator queries `memory_read` (project domain,
natural-language query for the milestone's topics) and folds useful hits
into dispatch briefs. Spawned minions do not need MCP access — recall
rides the briefs, consistent with single-writer roll-up.

Recall folded into a brief remains input, not authority: recalled runtime
facts are presumptive, and the brief still instructs the receiving agent
to confirm live state first (invariant 3).

Cross-project recall (querying other domains) is Operator-directed only;
the orchestrator does not reach into other projects' domains on its own.

## Domains

Memories are namespaced by domain. The scheme is `project:<repo-name>`:

| Domain | Use |
|---|---|
| `project:minions-template` | This repo's promoted knowledge |
| `project:<repo-name>` | Each downstream repo, under its own name |
| `test:smoke` | Smoke-test loop only; always deleted after the test |

`memory_delete_domain` on `project:<repo>` purges a project's memories
entirely — the rollback path documented in the setup runbook.

## Security Boundary

Mnemoverse is a third-party cloud with no published privacy, retention, or
encryption posture. Excluded classes are explicit and absolute — never
mirrored under any circumstances:

- secrets/credentials and credentials-adjacent state
- `SOLE-HOLDER:` facts (rollback anchors, checksums, backup paths)
- personal data
- packet bodies, diffs, or code

Only distilled lesson/decision text crosses the boundary. The REST
fallback's API key is environment-only (`MNEMOVERSE_API_KEY`), never
committed; `.gitignore` posture applies.

## Enabling It

The layer is off by default. Enabling it is a two-step process:

1. **Connect the memory service** on the machine where the orchestrator
   runs. Claude: the Mnemoverse extension via connector settings. Other
   tools: their MCP config, pointed at the same account — same account,
   same memories.
2. **Set the gate** in the environment where minions run:

   ```bash
   export MINION_MEMORY=on
   ```

To disable, unset `MINION_MEMORY` or set it to any value other than `on`;
the layer goes inert with no cleanup required. Full setup recipes,
verification steps, the smoke-test loop, and rollback are in
`docs/runbooks/memory-recall-setup.md`.

## REST Fallback

Claude uses the MCP tools directly (`memory_write`, `memory_read`,
`memory_feedback`, `memory_stats`, `memory_delete`,
`memory_delete_domain`). For non-Claude orchestrators or toolless
environments, the vendor exposes a REST API. No wrapper script exists yet
by design; build one only when a non-Claude tool needs it in practice.

Base URL: `https://core.mnemoverse.com/api/v1`
Auth: `X-Api-Key` header (or `Authorization: Bearer`), key stored in the
`MNEMOVERSE_API_KEY` environment variable — never in the repo.

Endpoint paths below are transcribed from the vendor's published llms.txt
(`https://raw.githubusercontent.com/mnemoverse/.github/main/llms.txt`,
fetched 2026-07-02). The authoritative reference is
`https://mnemoverse.com/docs/api/reference`.

| Method | Path | Purpose |
|---|---|---|
| POST | `/memory/write` | Store a memory (content, concepts[], domain) |
| POST | `/memory/read` | Search memories (query, top_k, domain) |
| POST | `/memory/feedback` | Rate usefulness (atom_ids[], outcome -1..1) |
| GET | `/memory/stats` | Memory statistics (total atoms, domains) |
| POST | `/memory/write-batch` | Store up to 500 memories at once |
| POST | `/memory/read-batch` | Batch query up to 50 queries |
| POST | `/memory/consolidate` | Merge similar memories |

Curl shape (write, then read):

```bash
curl -X POST https://core.mnemoverse.com/api/v1/memory/write \
  -H "X-Api-Key: ${MNEMOVERSE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"content": "<distilled lesson text>",
       "concepts": ["<topic>", "<topic>"],
       "domain": "project:minions-template"}'

curl -X POST https://core.mnemoverse.com/api/v1/memory/read \
  -H "X-Api-Key: ${MNEMOVERSE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"query": "<natural-language question>", "top_k": 5,
       "domain": "project:minions-template"}'
```

The llms.txt does not document REST paths for the delete operations
(`memory_delete`, `memory_delete_domain`); over REST, consult the vendor
API reference before scripting deletes — never guess endpoint paths. The
MCP tools cover both delete operations today.
