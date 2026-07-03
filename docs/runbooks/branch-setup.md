# Branch Setup Runbook

**Owner:** OM  
**Scope:** One-time per repository (template and every downstream clone)  
**Reference:** `docs/branching-and-release-model.md`

Run these steps once when creating or onboarding a new repo. The procedure
creates `dev` and `staging` branches and configures branch-protection rules
to enforce the 4-tier flow described in the branching model.

The **universal steps** (Sections 1–3 below) are identical on every VCS host.
After completing them, follow **one** host-specific recipe section (Gitea or
GitHub) to configure branch protection and open the `staging→main` PR. A
project picks one host's recipe; the underlying model is the same.

---

## 1. Create `dev` and `staging` branches

These commands create both branches from the current `main` HEAD and push
them to the remote in one step.

```bash
git fetch origin
git branch dev origin/main
git branch staging origin/main
git push origin dev staging
```

Verify both branches exist remotely:

```bash
git ls-remote --heads origin
# Expected: refs/heads/dev and refs/heads/staging appear in the output
```

---

## 2. Protect `main`

`main` must never accept direct pushes. All changes must arrive through a
pull request from `staging` (or `hotfix/<topic>` in an emergency — see the
branching model). Apply the following intent using the host recipe below:

| Intent | Value |
| --- | --- |
| Branch name pattern | `main` |
| Require pull request before merging | enabled |
| Required number of approvals | `1` |
| Dismiss stale reviews on push | enabled |
| Restrict direct push | disabled for everyone (including admins, unless policy allows) |

---

## 3. Lightly protect `dev` and `staging`

`dev` and `staging` must accept normal merges from minions but must never be
force-pushed or have their history rewritten. Apply the following intent to
both branches:

| Intent | Value |
| --- | --- |
| Block force push | enabled |
| Block deletion | enabled |
| Require pull request before merging | disabled |
| Required approvals | 0 |

---

## Host-Specific Recipes

### Gitea Recipe

**Applies to:** repositories hosted on a Gitea instance
(example: `git.molloyhome.net`).

#### Install and authenticate `tea` (OPTIONAL)

`tea` is the official Gitea CLI. It is **NOT required** — every step below
can be done via the Gitea web UI or REST API without it. `tea` only makes
opening the `staging→main` PR scriptable. Enterprise environments and servers
without Homebrew may not have it; that is expected and fine.

If you choose to use `tea`, pick whichever install path fits your environment:

```bash
# macOS (Homebrew, if available)
brew install tea

# Any OS — download a prebuilt binary and put it on PATH
# https://dl.gitea.com/tea/  or  https://gitea.com/gitea/tea/releases
chmod +x tea && mv tea /usr/local/bin/tea

# If Go is available
go install code.gitea.io/tea@latest

# If none of the above are available: skip tea entirely and use the
# web UI / REST API fallbacks described below.
```

If you installed `tea`, add a login entry pointing at the Gitea instance:

```bash
tea login add \
  --url https://git.molloyhome.net \
  --token <your-personal-access-token>
```

Generate the personal access token in Gitea under
`Settings → Applications → Generate Token`. Scope: `repository`.

Confirm the login was registered:

```bash
tea login list
# Expected: a row showing https://git.molloyhome.net with your username
```

#### Protect `main` — Gitea

**Web UI path (toolless fallback):**
`Repository → Settings → Branches → Add Rule`

| Setting | Value |
| --- | --- |
| Branch name pattern | `main` |
| Protect this branch | enabled |
| Require pull request before merging | enabled |
| Required number of approvals | `1` |
| Dismiss stale reviews on push | enabled |
| Restrict who can push | disable direct push for everyone (including admins, unless your policy allows) |
| Restrict which branches can merge | `staging` (or leave unrestricted if Gitea version does not support source-branch restriction) |

**Via REST API (scriptable):**

```bash
curl -s -X PATCH \
  -H "Authorization: token <your-personal-access-token>" \
  -H "Content-Type: application/json" \
  "https://git.molloyhome.net/api/v1/repos/Molloy-Home/minions-template/branches/main/protection" \
  -d '{
    "enable_push": false,
    "require_signed_commits": false,
    "required_approvals": 1,
    "dismiss_stale_approvals": true
  }'
```

Adjust the repo path (`Molloy-Home/minions-template`) for the target
downstream repo.

#### Lightly protect `dev` and `staging` — Gitea

**Web UI:** create a rule for each branch with these settings:

| Setting | Value |
| --- | --- |
| Branch name pattern | `dev` (repeat for `staging`) |
| Protect this branch | enabled |
| Block force push | enabled |
| Block deletion | enabled |
| Require pull request before merging | disabled |
| Required approvals | 0 |

**Via REST API:**

```bash
for BRANCH in dev staging; do
  curl -s -X PATCH \
    -H "Authorization: token <your-personal-access-token>" \
    -H "Content-Type: application/json" \
    "https://git.molloyhome.net/api/v1/repos/Molloy-Home/minions-template/branches/${BRANCH}/protection" \
    -d '{
      "enable_push": true,
      "enable_push_whitelist": false,
      "enable_force_push": false,
      "block_on_outdated_branch": false,
      "required_approvals": 0
    }'
done
```

#### Verify the setup — Gitea

**Check branches exist remotely:**

```bash
git ls-remote --heads origin
# dev and staging must appear
```

**Confirm `main` rejects a direct push (expected to fail):**

```bash
# Make a harmless local change
git checkout main
echo "# test" >> /tmp/branch-protection-probe.txt
git add /tmp/branch-protection-probe.txt 2>/dev/null || true

# Attempt a direct push — it must be rejected
git push origin main
# Expected: "! [remote rejected] main -> main (protected branch hook declined)"
#           or equivalent Gitea rejection message
# If this succeeds, the protection rule is not active — revisit the
# Protect main section above
```

**Open a test PR (choose whichever path fits your environment):**

```bash
# First, create the probe branch and push it:
git checkout -b test/branch-protection-probe
git commit --allow-empty -m "chore: branch-protection probe (delete me)"
git push origin test/branch-protection-probe
```

**Primary — web UI (no tools required):**
Gitea prints a "Create a new pull request" URL when you push; click it.
Or go to `Repository → Pull Requests → New Pull Request`, set base
`staging` ← compare `test/branch-protection-probe`. Confirm the PR
appears, then close it without merging.

**Scriptable — REST API:**

```bash
curl -s -X POST \
  -H "Authorization: token <your-personal-access-token>" \
  -H "Content-Type: application/json" \
  "https://git.molloyhome.net/api/v1/repos/Molloy-Home/minions-template/pulls" \
  -d '{
    "title": "chore: branch-protection probe",
    "body": "Verify PR flow works end-to-end. Close without merging.",
    "head": "test/branch-protection-probe",
    "base": "staging"
  }'
# Note the returned "number" field, then close the PR via the web UI or:
# curl -s -X PATCH ... /pulls/<number> -d '{"state":"closed"}'
```

**Convenience — `tea` CLI (if installed):**

```bash
tea pr create \
  --repo Molloy-Home/minions-template \
  --head test/branch-protection-probe \
  --base staging \
  --title "chore: branch-protection probe" \
  --description "Verify PR flow works end-to-end. Close without merging."

# Confirm the PR appears in Gitea, then close it
tea pr close <pr-number> --repo Molloy-Home/minions-template
```

**Clean up after the probe (all paths):**

```bash
git checkout main
git branch -d test/branch-protection-probe
git push origin --delete test/branch-protection-probe
```

#### Open the `staging→main` PR — Gitea

At Promotion Flow step 7, PM opens the `staging→main` PR. Choose whichever
path fits your environment:

- **Web UI (no tools required):** Gitea shows a PR link on push; click it.
  Or go to `Repository → Pull Requests → New Pull Request`, set base `main`
  ← compare `staging`.
- **REST API:** `curl` to
  `POST /repos/{owner}/{repo}/pulls` with `"base":"main","head":"staging"`.
- **`tea` CLI (if installed):** `tea pr create --base main --head staging`.

`tea` is optional; a role without it — or without Homebrew — is never
blocked.

#### Notes — Gitea

- Adjust `Molloy-Home/minions-template` to the target repo path wherever it
  appears above.
- If the Gitea version does not support source-branch merge restriction,
  enforce the `staging→main` source convention through the minion workflow
  (`docs/branching-and-release-model.md` §Gates & Hard-Stops) rather than a
  Gitea rule.
- Re-run from the protection steps if branch protection is ever accidentally
  removed.

---

### GitHub Recipe

**Applies to:** repositories hosted on GitHub (github.com or GitHub
Enterprise).

#### Install and authenticate `gh` (OPTIONAL)

`gh` is the official GitHub CLI. It is **NOT required** — every step below
can be done via the GitHub web UI or REST API without it. `gh` only makes
opening the `staging→main` PR scriptable. Enterprise environments and servers
without Homebrew may not have it; that is expected and fine.

If you choose to use `gh`, pick whichever install path fits your environment:

```bash
# macOS (Homebrew, if available)
brew install gh

# Any OS — download a prebuilt binary from GitHub releases
# https://github.com/cli/cli/releases
# Extract and place the binary on PATH

# If Go is available
go install github.com/cli/cli/v2/cmd/gh@latest
```

If you installed `gh`, authenticate with GitHub:

```bash
gh auth login
# Follow the prompts to authenticate via browser or token
```

#### Protect `main` — GitHub

**Web UI path (toolless fallback):**
`Repository → Settings → Branches → Branch protection rules → Add rule`

Alternatively, use **Rulesets** (`Settings → Rules → Rulesets → New ruleset`)
for the modern GitHub branch-protection interface.

| Setting | Value |
| --- | --- |
| Branch name pattern | `main` |
| Require a pull request before merging | enabled |
| Required number of approvals before merging | `1` |
| Dismiss stale pull request approvals when new commits are pushed | enabled |
| Restrict who can push to matching branches | enabled; restrict force push for everyone |

**Via REST API (scriptable):**

```bash
curl -s -X PUT \
  -H "Authorization: Bearer <your-personal-access-token>" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/{owner}/{repo}/branches/main/protection" \
  -d '{
    "required_pull_request_reviews": {
      "required_approving_review_count": 1,
      "dismiss_stale_reviews": true
    },
    "restrictions": null,
    "enforce_admins": false,
    "required_status_checks": null,
    "allow_force_pushes": false,
    "allow_deletions": false
  }'
```

Replace `{owner}` and `{repo}` with the target repository's owner and name.

#### Lightly protect `dev` and `staging` — GitHub

**Web UI:** add a branch protection rule for each branch:

| Setting | Value |
| --- | --- |
| Branch name pattern | `dev` (repeat for `staging`) |
| Allow force pushes | disabled |
| Allow deletions | disabled |
| Require a pull request before merging | disabled |

**Via REST API:**

```bash
for BRANCH in dev staging; do
  curl -s -X PUT \
    -H "Authorization: Bearer <your-personal-access-token>" \
    -H "Content-Type: application/json" \
    "https://api.github.com/repos/{owner}/{repo}/branches/${BRANCH}/protection" \
    -d '{
      "required_pull_request_reviews": null,
      "restrictions": null,
      "enforce_admins": false,
      "required_status_checks": null,
      "allow_force_pushes": false,
      "allow_deletions": false
    }'
done
```

#### Verify the setup — GitHub

**Check branches exist remotely:**

```bash
git ls-remote --heads origin
# dev and staging must appear
```

**Confirm `main` rejects a direct push (expected to fail):**

```bash
git push origin main
# Expected: "! [remote rejected] main -> main (protected branch)"
#           or equivalent GitHub rejection message
# If this succeeds, revisit the Protect main section above
```

**Open a test PR:**

```bash
# Create the probe branch and push it:
git checkout -b test/branch-protection-probe
git commit --allow-empty -m "chore: branch-protection probe (delete me)"
git push origin test/branch-protection-probe
```

**Primary — web UI (no tools required):**
GitHub shows a "Compare & pull request" banner after a push; click it.
Or go to `Pull requests → New pull request`, set base `staging` ←
compare `test/branch-protection-probe`. Confirm the PR appears, then
close it without merging.

**Scriptable — REST API:**

```bash
curl -s -X POST \
  -H "Authorization: Bearer <your-personal-access-token>" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/{owner}/{repo}/pulls" \
  -d '{
    "title": "chore: branch-protection probe",
    "body": "Verify PR flow works end-to-end. Close without merging.",
    "head": "test/branch-protection-probe",
    "base": "staging"
  }'
# Note the returned "number" field, then close the PR via the web UI or:
# curl -s -X PATCH ... /pulls/<number> -d '{"state":"closed"}'
```

**Convenience — `gh` CLI (if installed):**

```bash
gh pr create \
  --base staging \
  --head test/branch-protection-probe \
  --title "chore: branch-protection probe" \
  --body "Verify PR flow works end-to-end. Close without merging."

# Confirm the PR appears, then close it
gh pr close <pr-number>
```

**Clean up after the probe (all paths):**

```bash
git checkout main
git branch -d test/branch-protection-probe
git push origin --delete test/branch-protection-probe
```

#### Open the `staging→main` PR — GitHub

At Promotion Flow step 7, PM opens the `staging→main` PR. Choose whichever
path fits your environment:

- **Web UI (no tools required):** GitHub shows a "Compare & pull request"
  banner after a push; click it. Or go to
  `Pull requests → New pull request`, set base `main` ← compare `staging`.
- **REST API:** `POST /repos/{owner}/{repo}/pulls` with
  `"base":"main","head":"staging"`.
- **`gh` CLI (if installed):**
  `gh pr create --base main --head staging`.

`gh` is optional; a role without it — or without Homebrew — is never
blocked.

#### Notes — GitHub

- Replace `{owner}` and `{repo}` with the target repository's owner and
  name wherever they appear above.
- The GitHub REST API branch protection endpoint requires a token with
  `repo` scope (classic token) or `contents:write` + `administration:write`
  fine-grained permissions.
- Re-run from the protection steps if branch protection is ever accidentally
  removed.

## Validation

- `git ls-remote --heads origin` lists `dev` and `staging`.
- A test push directly to `main` is rejected; a PR from `staging` to
  `main` is accepted (create and close one without merging).

## Rollback

Remove the protection rules via the same host UI/API used to create
them, then delete the branches if truly unwinding:
`git push origin --delete dev staging`. Protection removal is
non-destructive; branch deletion loses any unmerged work — check
`git log origin/dev --not origin/main` first.
