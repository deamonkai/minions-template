# Second Brain Setup Runbook

**Owner:** OM
**Scope:** Per machine (gate variables optionally per repo)
**Reference:** `docs/second-brain-model.md`

Run these steps to enable the optional local second-brain layer on a
machine. The model itself — invariants, write/read paths, vault layout, and
the security boundary — lives in `docs/second-brain-model.md`; this runbook
covers only Operator setup: the gate variables, the vault location, the
tool smoke test, and disable/rollback. The layer is off by default and stays
inert until both steps 2 and 3 below are done.

---

## 1. Purpose / Audience

`MINION_SECONDBRAIN` (and its companion `MINION_SECONDBRAIN_VAULT`) are
shell environment variable conventions, the same family as `MINION_ISSUES`
and `MINION_MEMORY`. Agents read them via their shell (the Bash tool); when
the gate is `on` and the vault directory exists, second-brain steps run;
otherwise every step is a silent no-op.

Audience: the Operator enabling the layer on their own machine. No installer,
config file, or script in this repo sets these variables for you — enabling
the layer is a deliberate per-machine choice, which is why the recipes below
exist.

## 2. Prerequisites / Assumptions

- A `bash` shell (the tool is a plain POSIX-ish `bash` script; no 3rd-party
  runtime required).
- Optional: `rg` (ripgrep) for faster `search` — the tool falls back to
  `grep -r` when absent.
- Optional: `gitleaks` for the `scan` subcommand — absent gitleaks makes
  `scan` a silent no-op (warn + exit 0), never a hard failure.
- Optional: Obsidian, purely as the Operator's GUI/graph over the vault
  directory. Minions never depend on it being installed or running.

## 3. Procedure

### 3.1 Choose and create a vault location (AC-1 containment)

Pick a directory **outside** any synced or backed-up tree:

- NOT under `~/Documents`
- NOT under iCloud Drive (`~/Library/Mobile Documents`)
- NOT under a Dropbox / Google Drive / OneDrive folder
- Time-Machine-excluded (`tmutil isexcluded`)
- If ever placed under version control, **private-only**, never a public
  remote, and never with an Obsidian-Git remote configured — that plugin
  pushes plaintext to a remote and is the single easiest way to betray
  "never leaves the Mac."

The default is `~/second-brain/`, which satisfies containment on a stock
macOS layout. Create it and exclude it from Time Machine:

```bash
mkdir -p ~/second-brain
tmutil addexclusion ~/second-brain
tmutil isexcluded ~/second-brain
# Expected: "[Excluded]" (or similar) for the path
```

If you choose a different location, set `MINION_SECONDBRAIN_VAULT` to it in
step 3.2 below — never hardcode the path anywhere else.

### 3.2 Set the gate variables

Pick the recipe that matches how long you want the gate to stay on. In
every case the variables must be exported in the shell that launches the
agent CLI — child processes inherit the environment.

#### Per-session (one run)

```bash
export MINION_SECONDBRAIN=on
export MINION_SECONDBRAIN_VAULT=~/second-brain   # only if not the default
claude   # or the agent CLI of choice, launched from this same shell
```

The gate lasts until the terminal closes.

#### Persistent (this machine, all sessions)

**zsh (macOS default):** the exports go in `~/.zshenv` — **not**
`~/.zshrc`. Agent tool-shells are non-interactive zsh, and non-interactive
zsh sources only `~/.zshenv`; `~/.zshrc` is read by interactive shells only.
An export placed in `~/.zshrc` makes the gate look "on" in your interactive
terminal while every agent shell still sees it as unset — the layer stays
silently inert with no error. (This is the exact defect that was found by
dogfooding the Memory Recall layer's `MINION_MEMORY` gate on 2026-07-02; see
`docs/runbooks/memory-recall-setup.md` for the field note. Do not repeat it
here.)

```bash
echo 'export MINION_SECONDBRAIN=on' >> ~/.zshenv
echo 'export MINION_SECONDBRAIN_VAULT=~/second-brain' >> ~/.zshenv   # only if not the default
```

Then open a new terminal (or `source ~/.zshenv` in the current one).

**bash:** non-interactive bash's handling of `~/.bashrc` varies by how it's
invoked. The portable move is to set the exports in *both* `~/.bashrc` and
`~/.bash_profile`, or better, just run the verify step below and confirm
from an actual agent shell rather than trusting either file.

#### Per-repo (direnv)

With `direnv` installed, add an `.envrc` entry in the repo root:

```bash
echo 'export MINION_SECONDBRAIN=on' >> .envrc
direnv allow
```

`.envrc` must stay untracked — never committed. This repo's `.gitignore`
covers it, but downstream `.gitignore`s may differ, so verify before writing
anything into the file:

```bash
git check-ignore .envrc
# Expected: ".envrc" echoed back. If the command prints nothing,
# add the ignore first:
#   echo '.envrc' >> .gitignore   # or add it to .git/info/exclude
```

The gate is a per-machine choice, not repo state; downstream clones opt in
on their own machines.

### 3.3 Optional: personal-data exclude file

Phase 1 ships no built-in personal-data pattern (no PII regexes). If you
want the AC-2 filter to also reject project-specific personal-data
patterns, author `$VAULT/.secondbrain-exclude` yourself — one regex per
line, `#` comments, absent by default:

```bash
cat >> ~/second-brain/.secondbrain-exclude <<'EOF'
# one extended-regex pattern per line; matches reject the capture
my-project-internal-id-[0-9]+
EOF
```

**Graceful degradation to know about:** an invalid regex in this file is
silently *skipped*, not rejected — the pattern simply never matches, so
content that pattern was meant to catch is *accepted*, not blocked. There
is no error surfaced at capture time. Validate a pattern once with `grep -E`
directly before relying on it:

```bash
grep -E 'my-project-internal-id-[0-9]+' /dev/null
echo $?   # Expected: 1 (no match, but no "invalid regex" error either)
```

If `grep -E` reports a regex syntax error, fix the pattern in
`.secondbrain-exclude` before trusting it to catch anything.

## 4. Validation

### 4.1 Verify the gate

Verification must happen from the agent's own tool shell, in a **fresh**
session started after the export was added — not from the interactive
terminal you edited the profile in. Ask the agent to run:

```bash
echo ${MINION_SECONDBRAIN:-<unset>}
# Expected: on
tools/second-brain.sh path
# Expected: the vault path you chose
```

If the gate output is `<unset>`, the variable was not exported in the shell
that launched the agent — re-check which recipe applies (for zsh, confirm
the export is in `~/.zshenv`, not `~/.zshrc`) and relaunch.

### 4.2 Verify the AC-1 preflight (warn-only)

```bash
tools/second-brain.sh path --check
# Expected: the vault path, with no WARN lines. Any WARN line names a
# containment gap (synced tree, not Time-Machine-excluded) to fix before
# relying on the layer.
```

### 4.3 Smoke test

Run this loop once after enabling the gate:

1. **Filter, clean input** (works even with the gate off — pure/offline):

   ```bash
   printf 'a normal working note\n' | tools/second-brain.sh filter
   echo $?   # Expected: 0
   ```

2. **Filter, secret-bearing input** (reject-and-report, nothing written):

   ```bash
   printf 'password: notarealsecretvalue\n' | tools/second-brain.sh filter
   echo $?   # Expected: 3, plus the offending class + line NUMBER (never
             # the matched text) on stderr
   ```

3. **Capture** a clean test note:

   ```bash
   printf 'second-brain smoke test — safe to delete\n' \
     | tools/second-brain.sh capture --title "Smoke Test" --tag smoke
   # Expected: the created note's path, exit 0
   ```

4. **Search** for it:

   ```bash
   tools/second-brain.sh search "smoke test"
   # Expected: the note written in step 3 comes back
   ```

5. **Scan** the vault (no-op if `gitleaks` is not installed):

   ```bash
   tools/second-brain.sh scan
   # Expected: exit 0 either way (clean scan, or "gitleaks not installed" no-op)
   ```

6. **Delete the smoke-test note** — it is not part of real corpus content:

   ```bash
   rm "$(tools/second-brain.sh path)"/inbox/*smoke-test*.md
   ```

If any step diverges from the expectations above, stop and resolve it
(gate variable, vault path, tool permissions) before relying on the layer
for real capture.

## 5. Rollback

**Disable the layer** — unset the gate variable (or set it to anything
other than `on`):

```bash
unset MINION_SECONDBRAIN
```

The layer goes inert immediately; no cleanup is required. If you used the
persistent or direnv recipe, also remove the export line(s) from
`~/.zshenv` (zsh), `~/.bashrc`/`~/.bash_profile` (bash), or `.envrc`.

**Remove the vault entirely** — the repo is unaffected either way (the vault
is not a git-durable surface):

```bash
rm -rf ~/second-brain   # or your chosen MINION_SECONDBRAIN_VAULT path
```

There is no data-recovery path for deleted vault content — it was never
mirrored to git. If any content in the vault mattered, promote it (copy the
relevant text into a repo file, a mail packet, or `MEMORY.md`, per the
files-always-win invariant) before deleting.

---

## Notes

- This runbook is setup-only. The rules governing *what* gets written
  (the AC-2 exclusion filter, the reject-and-report posture, the excluded
  classes) are in `docs/second-brain-model.md` — read its Security Boundary
  section before relying on the layer for real capture.
- Toolless path: every step above is a plain `bash` invocation of
  `tools/second-brain.sh`; no vendor CLI or MCP connection is required.
- Downstream repos repeat section 3 per machine and use their own vault
  path; the smoke test is identical.
