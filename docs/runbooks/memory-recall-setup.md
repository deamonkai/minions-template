# Memory Recall Setup Runbook

**Owner:** OM  
**Scope:** Per machine (gate variable optionally per repo)  
**Reference:** `docs/memory-recall-model.md`

Run these steps to enable the optional memory recall layer on a machine.
The model itself — invariants, write/read paths, domain scheme, and the
exclusion list — lives in `docs/memory-recall-model.md`; this runbook
covers only Operator setup: the gate variable, connecting the service,
the REST fallback key, the smoke test, and disable/rollback. The layer is
off by default and stays inert until both steps 2 and 3 below are done.

---

## 1. What `MINION_MEMORY` is

`MINION_MEMORY` is a shell environment variable convention, the same
family as `MINION_ISSUES`. Agents read it via their shell (the Bash
tool); when it is `on`, memory steps run, and when it is unset or
anything else, every memory step is a silent no-op.

It is not set anywhere by default — no installer, config file, or script
in this repo sets it for you. Setting it is a deliberate per-machine (or
per-repo) Operator choice, which is why the recipes below exist.

---

## 2. Set the gate variable

Pick the recipe that matches how long you want the gate to stay on. In
every case the variable must be exported in the shell that launches the
agent CLI — child processes inherit the environment.

### Per-session (one run)

```bash
export MINION_MEMORY=on
claude   # or the agent CLI of choice, launched from this same shell
```

The gate lasts until the terminal closes.

### Persistent (this machine, all sessions)

**zsh (macOS default):** the export goes in `~/.zshenv` — **not**
`~/.zshrc`. Agent tool-shells are non-interactive zsh, and
non-interactive zsh sources only `~/.zshenv`; `~/.zshrc` is read by
interactive shells only. An export placed in `~/.zshrc` makes the gate
look "on" in your interactive terminal while every agent shell still
sees it as unset — the layer stays silently inert with no error.

```bash
echo 'export MINION_MEMORY=on' >> ~/.zshenv
```

Then open a new terminal (or `source ~/.zshenv` in the current one).

**bash:** non-interactive bash's handling of `~/.bashrc` varies by how
it's invoked (some launchers source it, some don't — the `BASH_ENV`
convention isn't universal either). The portable move is to set the
export in *both* `~/.bashrc` and `~/.bash_profile`, or better, just run
the verify step below and confirm from an actual agent shell rather
than trusting either file.

**Whichever shell:** the interactive terminal's answer is not proof.
Always verify from the agent's own shell — see Verify below.

### Per-repo (direnv)

With `direnv` installed, add an `.envrc` entry in the repo root:

```bash
echo 'export MINION_MEMORY=on' >> .envrc
direnv allow
```

`.envrc` must stay untracked — never committed. This repo's `.gitignore`
covers it, but downstream `.gitignore`s may differ, so verify before
writing anything into the file:

```bash
git check-ignore .envrc
# Expected: ".envrc" echoed back. If the command prints nothing,
# add the ignore first:
#   echo '.envrc' >> .gitignore   # or add it to .git/info/exclude
```

The gate is a per-machine choice, not repo state; downstream clones opt
in on their own machines.

### Verify

Verification must happen from the agent's own tool shell, in a **fresh**
session started after the export was added — not from the interactive
terminal you edited the profile in, and not from a session already
running before the change. Ask the agent to run:

```bash
echo ${MINION_MEMORY:-<unset>}
# Expected: on
```

If the output is `<unset>`, the variable was not exported in the shell
that launched the agent — re-check which recipe applies (for zsh,
confirm the export is in `~/.zshenv`, not `~/.zshrc`) and relaunch. The
interactive terminal seeing `on` does not mean the agent shell does;
these are two different shell types reading two different files, and
only the agent-shell answer counts.

**Field note:** this defect was found by dogfooding on 2026-07-02 — the
Operator had exported `MINION_MEMORY=on` in `~/.zshrc` exactly as an
earlier version of this runbook instructed. Their interactive terminal
reported the gate as `on`; every agent shell reported it `<unset>`. The
layer had been silently inert the whole time. Root cause: agent
tool-shells are non-interactive zsh, and non-interactive zsh never
sources `~/.zshrc`.

---

## 3. Connect Mnemoverse (per machine)

The gate variable alone does nothing without the memory tools; connect
the service on each machine where an orchestrator runs.

- **Claude:** add the Mnemoverse extension via the connector settings
  (claude.ai connector settings in the web UI, or the desktop app's
  extension settings). On this template's development machine it is
  already installed. Once connected, the MCP tools appear:
  `memory_write`, `memory_read`, `memory_stats`, `memory_delete`,
  `memory_delete_domain`, `memory_feedback`.
- **Other tools (ChatGPT, Cursor, VS Code, …):** add the Mnemoverse MCP
  server via each tool's own MCP configuration, signed in to the same
  Mnemoverse account. Same account = same memories — recall is shared
  per account, not per tool.

Verify: call `memory_stats` from the connected tool. Expected: it
returns statistics (even zero atoms is fine) rather than an unknown-tool
error.

---

## 4. REST fallback (toolless environments)

For non-Claude orchestrators or environments with no MCP support, the
vendor exposes a REST API (see `docs/memory-recall-model.md` § REST
Fallback for the endpoint table).

1. Create an API key in your Mnemoverse account (web UI, account/API
   settings — no CLI required).
2. Store it as an environment variable only:

   ```bash
   export MNEMOVERSE_API_KEY=<your-key>
   ```

   Never commit the key to the repo — environment-only, per the
   security boundary in the canonical doc. The shell profile is the
   preferred home for the key; `.envrc` is acceptable only after
   verifying git ignores it (`git check-ignore .envrc` — see the
   direnv recipe in section 2).
3. Verify the key with the stats endpoint — base URL
   `https://core.mnemoverse.com/api/v1`, auth via `X-Api-Key` header:

   ```bash
   curl -s https://core.mnemoverse.com/api/v1/memory/stats \
     -H "X-Api-Key: ${MNEMOVERSE_API_KEY}"
   # Expected: JSON statistics — confirms the key works
   ```

The delete operations have no documented REST paths today; they are
MCP-only. Consult the vendor API reference before scripting deletes over
REST — never guess endpoint paths.

---

## 5. Smoke test

Run this loop once after connecting, from the tool where the
orchestrator runs. It uses the throwaway `test:smoke` domain — never a
`project:*` domain — and cleans up after itself.

1. `memory_write` — content
   `"minions-template smoke test — safe to delete"`, concepts
   `["smoke", "runbook-validation"]`, domain `test:smoke`.
2. `memory_read` — query `"smoke test"`, domain `test:smoke`.
   Expected: the memory written in step 1 comes back.
3. `memory_stats` — expected: the total memory count includes the test
   atom and `test:smoke` appears in the domain list (stats reports a
   total count plus domain names, not per-domain counts).
4. `memory_delete_domain` — domain `test:smoke`, with the tool's
   `confirm: true` safety interlock (it refuses without it; deletion is
   irreversible). Expected: it reports how many memories were deleted
   from the domain.
5. `memory_stats` — expected: `test:smoke` is gone and counts are back
   to the pre-test baseline.

If any step diverges from the expectations above, stop and resolve it
(connection, account, or key) before relying on the layer for real
promotion writes.

---

## 6. Disable / rollback

**Disable the layer** — unset the variable (or set it to anything other
than `on`):

```bash
unset MINION_MEMORY
```

The layer goes inert immediately; no cleanup is required. If you used
the persistent or direnv recipe, also remove the export line from
`~/.zshenv` (zsh), `~/.bashrc`/`~/.bash_profile` (bash), or `.envrc`.

**Purge a project's memories** — `memory_delete_domain` on
`project:<repo-name>` (this repo: `project:minions-template`) removes
that project's memories entirely. Repo files are unaffected — the repo
stays canonical, and memories can be regenerated from files at future
promotion moments.

---

## Notes

- This runbook is setup-only. The rules governing *what* gets written
  (curated, writer-owned, promotion moments only) and *what never
  crosses* (the four excluded classes) are in
  `docs/memory-recall-model.md` — read its Security Boundary section
  before any Operator-directed "remember this" write.
- Toolless path: connecting the extension and creating the API key are
  both web-UI operations, and the REST fallback needs only `curl` — no
  vendor CLI is required anywhere in this runbook.
- Downstream repos repeat sections 2–3 per machine and use their own
  domain (`project:<repo-name>`); the smoke test is identical.
