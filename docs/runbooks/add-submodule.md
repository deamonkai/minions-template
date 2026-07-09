# Add-Submodule Runbook

**Owner:** PM (coordinator seat)  
**Scope:** Once per project onboarded into a coordinator-mode repo  
**Reference:** `docs/coordinator-mode.md` (Project Registry, Mail Routing,
Concurrent Sessions), `docs/project/mailbox-collaboration-model.md`

This runbook is part of the coordinator-mode overlay and applies only to
repos that have enabled it (see Enabling It in `docs/coordinator-mode.md`);
single-project adopters never need it. It is the registration sequence for
bringing a new project under coordinator management: vendor the project as a
submodule, scaffold its session lane, register it, and gate it through PM
before lane work starts. Every step uses plain `git` and the filesystem — no
host CLI is required, so there is no web-UI fallback to document.

Placeholders throughout: `<key>` is the project key (short, stable — it
names the lane; the registry column definitions live in
`docs/coordinator-mode.md`), and `<url>` is the project's upstream remote.

PM owns the onboarding gate below. Roles your repo adds (for example a
coordinator MM) may take duties the overlay assigns to PM; the sequence
itself is unchanged.

Run the steps in order — the registry row must exist before any lane packet
carrying the new key can be accepted.

---

## 1. Add the submodule

```bash
git submodule add <url> submodules/<key>
```

This vendors the project at `submodules/<key>` and records it in
`.gitmodules`. From here on the submodule is written only through its own
branch flow (its feature branches and review gates in the project's upstream
repo), never edited directly from another lane — see Concurrent Sessions in
`docs/coordinator-mode.md`.

## 2. Scaffold the session lane

Create the lane surfaces for the new project:

```bash
mkdir -p projects/<key>/mail projects/<key>/chat

# Per-project context: the project-specific sections INIT.md step 3
# finalizes, one copy per project (When to Scale,
# docs/coordinator-mode.md).
"$EDITOR" projects/<key>/MEMORY.md

# Lane mailbox marker: state the lane's purpose and point at the
# routing tree in docs/coordinator-mode.md.
"$EDITOR" projects/<key>/mail/README.md

# Keep the empty chat directory trackable in git.
touch projects/<key>/chat/.gitkeep
```

The lane (`projects/<key>/**`) is the write surface for the project's
sessions. Packets in `projects/<key>/mail/` follow the packet conventions of
`docs/project/mailbox-collaboration-model.md` plus the required
`PROJECT: <key>` header field (Mail Routing, `docs/coordinator-mode.md`).

## 3. Register the project

Add a row to `projects/index.md` with every required registry column
(Project Registry, `docs/coordinator-mode.md`) and onboarding status
`onboarding`. Until the row exists, PM rejects any packet carrying the new
key — register before routing lane mail.

## 4. Open the PM onboarding gate packet

Open an onboarding gate packet addressed to PM in the coordinator mail tree
(`minions/mail/`) — not in the new lane. This is the onboarding carve-out in
Mail Routing (`docs/coordinator-mode.md`): while the registry row sits at
status `onboarding`, the lane has not yet passed this gate, so packets about
the project route to `minions/mail/`. PM — the coordinator seat — opens the
packet, so the `minions/mail/` write stays inside the coordinator-seat
single-writer rule (Concurrent Sessions, `docs/coordinator-mode.md`).
Suggested packet id:

`YYYY-MM-DD-<sender>-to-pm-onboard-<key>`

The `request.md` should list what steps 1–3 created (submodule path, lane
files, registry row) so PM can verify against it. As the gate owner, PM
holds `verdict.md`.

## 5. PM verifies the scaffold, then `in-progress`

PM runs the verification block below. Only when it is clean does PM flip the
project's registry row from `onboarding` to `in-progress` and close the gate
packet with a verdict. Lane work does not start before this gate passes.

---

## Verify

```bash
# Submodule is registered and initialized
git submodule status -- submodules/<key>

# Lane scaffold is complete
for f in projects/<key>/MEMORY.md projects/<key>/mail/README.md; do
  test -f "$f" || echo "MISSING: $f"
done
test -d projects/<key>/chat || echo "MISSING: projects/<key>/chat/"

# Registry row exists
grep -q "<key>" projects/index.md || echo "MISSING: registry row for <key>"
```

Expected: `git submodule status` prints exactly one line for
`submodules/<key>` (a leading `-` means it is uninitialized — run
`git submodule update --init submodules/<key>`); the remaining commands
print nothing.

---

## Removal / rollback

To retire a project from the coordinator:

```bash
git submodule deinit -f submodules/<key>
git rm submodules/<key>
rm -rf .git/modules/submodules/<key>
```

Then set the project's registry row in `projects/index.md` to status
`retired`. **Never delete the row** — history matters, and the registry is
the record of every project the coordinator has managed (Project Registry,
`docs/coordinator-mode.md`).

Archive the lane (`projects/<key>/`) rather than deleting it: move it aside
or rely on git history; do not rewrite it. This matches the overlay's
rollback posture in `docs/coordinator-mode.md`.

## Validation

- `git submodule status` shows the new path at the expected commit.
- `projects/index.md` has the new row; `projects/<key>/` contains the
  lane scaffold (MEMORY.md sections, mail/ marker, chat/ directory).
- The PM onboarding gate packet exists and PM has marked the row
  `in-progress` (step 5).

## Rollback

Reverse of registration: `git submodule deinit <path>`, remove the
submodule entry and lane scaffold in one commit, and set the registry
row's status to `retired` — rows are never deleted.
