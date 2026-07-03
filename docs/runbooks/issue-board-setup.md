# Issue Board Setup Runbook

**Owner:** OM  
**Scope:** One-time per repository (template and every downstream clone)  
**Reference:** `tools/issue-board-bootstrap.sh`, `tools/issue-sync.sh`  
**Supported `tea` version:** **v0.14.1** (verified against a live Gitea
host). The scripts are version-tolerant where cheap (issue
create/edit auto-detects `--description`/`--add-labels` vs the legacy
`--body`/`--labels`), but 0.14.1 is the tested-correct baseline. See the
**tea v0.14.1 compatibility notes** at the end of this runbook.

Run these steps once when enabling the issue-tracking workflow for a repo.
The procedure creates the `type:` and `role:` labels via the bootstrap
script, then completes the remainder manually in the web UI (project board
creation cannot be automated — see below). A project picks one host's
recipe; the underlying label schema is the same everywhere.

---

## 1. Run the bootstrap script

The script is gated by the `MINION_ISSUES` flag and exits silently when
disabled. Enable it explicitly for the run:

```bash
MINION_ISSUES=on tools/issue-board-bootstrap.sh
```

What the script does:

- Resolves the VCS host from `git remote get-url origin` (or
  `MINION_ISSUE_HOST` if set). Detected values: `gitea`, `github`,
  `none`.
- Exits no-op if the corresponding CLI (`tea` for Gitea, `gh` for
  GitHub) is not installed.
- Idempotently creates `type:` labels (`mail`, `gate`, `blocker`,
  `pipeline`, `chat`) and `role:` labels (`pm`, `am`, `cm`, `sm`, `dm`,
  `om`, `om-test`, `rm`) using `tea labels create` or `gh label create`.
- Prints one line per label:
  - `created: <label>` — label was newly created.
  - `exists: <label>` — label already existed; no change.
- Prints a final `board:` line stating there is **no automated board
  creation on this host** and that the board must be created manually
  (see host recipes below).

Expected output (abbreviated):

```
created: type:mail
created: type:gate
...
exists: role:pm
...
board: no automated board creation on this host; create it manually per \
  docs/runbooks/issue-board-setup.md (manual)
```

The script is safe to re-run: it queries the existing labels (`tea labels
list` / `gh label list`) and **skips** any that already exist, so a re-run
never duplicates labels. This matters on `tea` v0.14.1 specifically, where
`tea labels create` exits 0 and creates a *second* same-named label on a
duplicate name (it does not fail on collision) — so blind re-creation would
silently double the label set. The query-then-skip path makes re-runs
genuinely idempotent regardless of host.

---

## 2. Create the project board (manual)

The bootstrap script always prints a `board: ... (manual)` line because
no supported CLI provides a portable, idempotent board-creation command.
Follow the host-specific recipe below to create the board in the web UI.

---

## Host-Specific Recipes

### Gitea Recipe

**Applies to:** repositories hosted on a Gitea instance.

#### Run the bootstrap — Gitea

```bash
MINION_ISSUES=on tools/issue-board-bootstrap.sh
```

`tea` must be installed and authenticated. If it is not, install it:

```bash
# macOS (Homebrew, if available)
brew install tea

# Any OS — prebuilt binary
# https://dl.gitea.com/tea/  or  https://gitea.com/gitea/tea/releases
chmod +x tea && mv tea /usr/local/bin/tea
```

Authenticate:

```bash
tea login add \
  --url https://<your-gitea-host> \
  --token <your-personal-access-token>
```

Generate the token in Gitea under `Settings → Applications → Generate
Token`. Scope: `repository`.

#### Create the project board — Gitea (manual)

Gitea does not expose project-board creation via `tea`. Create it in the
web UI:

1. Navigate to the repository in your browser.
2. Go to `Projects → New Project`.
3. Name the board (e.g. `Minion Pipeline`), choose **Board** type, and
   save.
4. Add these columns in order:

   | Column | Purpose |
   | --- | --- |
   | `Triage` | Newly opened issues awaiting classification |
   | `In Progress` | Actively being worked |
   | `Awaiting Review` | PR open, under review |
   | `Awaiting Operator` | Blocked on operator decision |
   | `Done` | Closed / resolved |

5. After creating the board, add a link or note in `MEMORY.md` with the
   board URL so all roles can find it.

**Toolless web-UI path:** everything above is done in the browser; no
CLI is required for board creation.

#### Verify — Gitea

```bash
# Confirm labels exist
tea labels list
# Expected: type:mail, type:gate, type:blocker, type:pipeline, type:chat,
#           role:pm, role:am, role:cm, role:sm, role:dm, role:om,
#           role:om-test, role:rm  all appear in the output
```

Check the board via the web UI: `Projects` should show the board with
all five columns.

---

### GitHub Recipe

**Applies to:** repositories hosted on GitHub (github.com or GitHub
Enterprise).

#### Run the bootstrap — GitHub

```bash
MINION_ISSUES=on tools/issue-board-bootstrap.sh
```

`gh` must be installed and authenticated. If it is not, install it:

```bash
# macOS (Homebrew, if available)
brew install gh

# Any OS — prebuilt binary from GitHub releases
# https://github.com/cli/cli/releases

# Authenticate
gh auth login
```

The script calls `gh label create` for each `type:` and `role:` label
and prints `created:` or `exists:` per label, then the `board: ...
(manual)` line.

#### Create the project board — GitHub (manual)

GitHub Projects v2 boards can be created via `gh project create` or the
web UI. Both paths are shown below.

**Option A — `gh` CLI (if installed):**

```bash
gh project create --title "Minion Pipeline" --owner @me
# Note the project number printed; you will need it to add columns.
```

GitHub Projects v2 uses **fields** rather than fixed columns. Add a
single-select `Status` field with the required options:

```bash
PROJECT_NUM=<number from above>

gh project field-create $PROJECT_NUM \
  --owner @me \
  --name "Status" \
  --data-type SINGLE_SELECT \
  --single-select-options "Triage,In Progress,Awaiting Review,Awaiting Operator,Done"
```

Alternatively, add the field and options interactively in the web UI
after creating the project (see Option B).

**Option B — web UI (toolless, no CLI required):**

1. Go to your GitHub profile or organization.
2. Click **Projects → New project**.
3. Choose **Board** layout, name it `Minion Pipeline`, and create it.
4. GitHub creates three default columns (`Todo`, `In Progress`, `Done`).
   Rename / add columns to match the required set:

   | Column / Status option | Purpose |
   | --- | --- |
   | `Triage` | Newly opened issues awaiting classification |
   | `In Progress` | Actively being worked |
   | `Awaiting Review` | PR open, under review |
   | `Awaiting Operator` | Blocked on operator decision |
   | `Done` | Closed / resolved |

5. Link the board to the repository: on the project page go to
   `Settings → Linked repositories` and add the repo.
6. Record the project URL in `MEMORY.md`.

#### Verify — GitHub

```bash
# Confirm labels exist
gh label list
# Expected: type:mail, type:gate, type:blocker, type:pipeline, type:chat,
#           role:pm, role:am, role:cm, role:sm, role:dm, role:om,
#           role:om-test, role:rm  all appear in the output

# Confirm project exists (if gh is installed)
gh project list --owner @me
# Expected: Minion Pipeline appears
```

---

## 3. Enable the workflow

Once the board and labels are in place, enable issue tracking for all
roles by setting the following environment variable (in `.env`,
`~/.zshrc`, or your CI environment):

```bash
export MINION_ISSUES=on
export MINION_OPERATOR=<your-username>
```

`MINION_OPERATOR` is the GitHub/Gitea username that owns operator-gate
issues. Without it, roles cannot correctly address operator-decision
issues.

Re-run the bootstrap at any time to restore missing labels:

```bash
MINION_ISSUES=on tools/issue-board-bootstrap.sh
```

---

## Notes

- The bootstrap script (`tools/issue-board-bootstrap.sh`) and this
  runbook are the authoritative source for the label schema and board
  columns. If you add a new `type:` or `role:` value to the script,
  update this runbook's column tables accordingly.
- If the Gitea instance does not support the `Projects` feature (older
  versions), use a GitHub-hosted mirror for the board or track pipeline
  state in `minions/plans/` files until a board is available.
- Labels are colored for visual grouping: `type:` labels are blue
  (`#0366d6`), `role:` labels are purple (`#5319e7`). These colors are
  set by the bootstrap script and cannot be changed via this runbook
  without editing the script.
- Re-run `issue-board-bootstrap` after cloning the template to a new
  downstream repo; labels are per-repo and are not inherited.

---

## tea v0.14.1 compatibility notes

The Gitea host CLI `tea` changed flag names across versions. The scripts are
written to be correct on **v0.14.1** (the version verified against a live
Gitea host) and tolerant of older builds:

- **Issue body flag:** v0.14.1 uses `--description` (`-d`); older builds used
  `--body`. `issue-sync.sh` detects which the installed `tea` supports (from
  `tea issues create --help`) and uses the right one. A `--body`-only call
  fails outright on 0.14.1, so without this detection every `sync` would
  soft-fail (exit 4) and create nothing.
- **Edit-time label flag:** v0.14.1 uses `--add-labels` on `tea issues edit`;
  older builds used `--labels`. `issue-sync.sh` detects and uses the right one.
  (On `create`, `--labels` is still correct on 0.14.1.)
- **Duplicate labels:** `tea labels create` on v0.14.1 exits 0 and creates a
  duplicate on a name collision. `issue-board-bootstrap.sh` therefore queries
  `tea labels list` first and skips existing labels rather than relying on a
  create failure (see the idempotency note in step 1).

These behaviors are covered by the dependency-free test suites
`tools/tests/issue-sync.test.sh` and `tools/tests/issue-board-bootstrap.test.sh`,
whose fake `tea` provider (`tools/tests/fixtures/make-fake-provider.sh`) mimics
the real 0.14.1 behavior.

> **Provenance:** this compatibility fix was authored downstream (a project
> running `tea` v0.14.1 against a live Gitea host) and absorbed upstream in
> template v1.21.3, so downstream clones no longer need to carry it as a
> local patch.

## Validation

The label checks in the recipes above are the validation: label listing
shows all `type:*` and `role:*` labels, and re-running the bootstrap is
a no-op (idempotency is the contract).

## Rollback

Set `MINION_ISSUES` off (or unset) — the mirror layer is default-off and
goes silently inert; existing issues and labels may be left in place or
deleted via the host UI. No repo state depends on them.
