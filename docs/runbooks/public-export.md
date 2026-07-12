# Public Export Runbook

**Owner:** Operator / PM
**Scope:** One-time procedure per publish, repeated on every canonical
release the Operator wants public
**Reference:** `docs/export-manifest.md`, `docs/branching-and-release-model.md`

Run this procedure to publish a privacy-safe copy of this template to a
**public** repository with fresh history. It was field-derived from the
live 2026-07-02 export to `github.com/deamonkai/minions-template`.

**Scope note:** this runbook is written from the template repo's own
perspective — its manifest, its maintainer-local paths, its public
landing page. A downstream project publishing its own repo publicly
follows the same shape, one step at a time, but substitutes its own
export and exclusion decisions throughout: its own manifest (or
equivalent), its own maintainer/operator-local paths, and its own
divergence list. Treat every canonical-specific detail below as an
example of the pattern, not a literal requirement on downstream.

---

## Why fresh history

The canonical repo's Git history tracks maintainer-local files (`.mm.md`,
`AI/`) and personal Operator context across every past commit. Pushing that
history to a public copy would publish every past revision of those files,
not just their current (absent) state in the exported tree.

**Rule: never push canonical history to the public copy.** Each publish is
a manifest-filtered tree, committed fresh on the public repo — either as
the first commit of a new history, or as one more commit on top of the
public copy's own (separate, shallow) history from a prior publish. The
canonical repo's commit graph never crosses the boundary.

---

## Step 1 — Export the tree

Build the export tree from canonical `main` at a tagged release (e.g.
`v1.21.3`), filtered by `docs/export-manifest.md` — the same manifest rows
marked `Initial export: yes` that downstream onboarding uses (see
`docs/downstream-onboarding-playbook.md`).

1. Check out the tagged release commit on canonical `main`.
2. Copy every manifest row marked `yes` into the export tree; exclude every
   `do-not-export` row (`.mm.md`, `AI/README.md`, `AI/decisions.md`,
   `AI/open-questions.md`, `AI/specs/`, `AI/plans/`) and every
   `downstream-owned` row that has no public-facing purpose.
3. Deliberately **add `README.md`** even though the manifest classes it
   `downstream-owned` (a downstream project is expected to replace it with
   project-specific content). The public copy is different: it has no
   downstream project behind it, and `README.md` is the template's public
   landing page. Write it with an "About This Copy" section stating:
   - the canonical source version (the tag exported from, e.g. `v1.21.3`)
   - the divergence list — anything the public copy deliberately omits or
     changes relative to canonical (maintainer-local files, neutralized
     phrasing, fresh history)

---

## Step 2 — Privacy-neutralization sweep

Do this **tree-wide and token-based**, not as a single targeted edit.

The live 2026-07-02 run first tried a single-line pass (fix the one known
personal line in `MEMORY.md`) and it was incomplete: a personal-context
section heading echoed in `INIT.md` and `CHANGELOG.md` referenced the same
personal context and was missed by the single-line pass. Only a tree-wide
grep for the underlying token caught every occurrence, including the
heading echoes and their cross-references.

Procedure:

1. Identify every Operator-personal token to remove (personal phrasing,
   names, condition-specific references, anything identifying).
2. `grep -r` the **entire export tree** for each token — headings,
   prose, and cross-references alike, not just the file where the token
   was first noticed.
3. Neutralize every hit coherently: rewrite the line or heading to the
   generic underlying guidance, and fix every cross-reference that pointed
   at the old heading text or section name so nothing dangles.
4. Reset `feedback.md` to a clean capture-log stub (purpose, capture-vs-
   curated rule, promotion path, format — no Operator-specific examples or
   history), matching the seed style `docs/export-manifest.md` already
   specifies for downstream onboarding.
5. The template-default SME bench SHIPS as starters: the "Default Bench
   (template-shipped)" / "Default Matrix (template-shipped)" sections
   ABOVE the split-merge delimiter in `minions/smes/README.md` and
   `minions/review-matrix.md` publish with the tree — they are generic
   template infrastructure. Reset ONLY the BELOW-delimiter "Local
   Registry (this repo)" / "Local Matrix (this repo)" sections to
   header-only seed state; any downstream-project-added SMEs stay local
   and never publish (the feedback.md-stub treatment, generalized).
   Step 3 gate 4 enforces the header-only below-delimiter state
   mechanically — skipping this reset fails the pre-push gates.

**Verify** — for each neutralized token:

```bash
grep -r "<token>" <export-tree>/
# Expected: zero hits
```

Also confirm no heading reference is left dangling (a doc pointing at a
section name that no longer exists after the rewrite) — grep for the old
heading text specifically, separate from the token sweep, since a heading
can be renamed without every inbound reference being caught by a plain
token search.

---

## Step 3 — Verification gates (mandatory before push)

All of the following must pass in the export tree before anything is
pushed. These are pre-push hard gates, not optional checks.

1. **Test suite** — the export's own `tools/tests/*.test.sh` suite passes
   in the export tree (not just in canonical):

   ```bash
   for t in tools/tests/*.test.sh; do
     bash "$t" || echo "FAIL $t"
   done
   # Expected: no FAIL lines
   ```

2. **Secret scan** — `gitleaks` clean against the export tree with no Git
   history to scan (a fresh tree has no `.git/` yet, or has only the new
   history being built):

   ```bash
   gitleaks detect --source <export-tree> --no-git
   # Expected: no leaks found
   ```

   **GitHub push protection is stricter than gitleaks.** When the public
   remote is GitHub, its secret-scanning push protection ignores the repo's
   `.gitleaks.toml` allowlist and rejects any provider-shaped token —
   including the deliberately-fake fixtures that the second-brain secret
   filter tests depend on (`xoxb-`/`ghp_`/`AIza`/`AKIA`). gitleaks passes;
   the push is still declined (`GH013 ... Push cannot contain secrets`).
   Therefore **exclude `tools/tests/second-brain.test.sh` and
   `tools/tests/fixtures/second-brain/` from the export tree** (Step 1) and
   note the omission in the README divergence list — the second-brain tool
   and feature still ship, only their secret-fixture tests are dropped. First
   hit publishing v1.33.0 (the v1.29.0 export predated the feature).

3. **Forbidden files absent** — confirm none of the maintainer-local or
   local-tooling paths made it into the export tree:

   ```bash
   for f in .mm.md AI/ .remember/ .superpowers/ skills/vendored/; do
     test -e "<export-tree>/$f" && echo "FORBIDDEN PRESENT: $f"
   done
   # Expected: no output
   ```

   `skills/vendored/` is the maintainer-local adopted-skill payload path
   (`do-not-export` by construction). This gate is belt-and-suspenders behind
   its manifest exclusion: even if a manifest row were weakened, no adopted
   payload or quarantined `SOURCE.txt` may reach the export tree.

   This list is the template's own maintainer-local set. A downstream
   project substitutes its own maintainer/operator-local paths here —
   its equivalent private-context files, its untracked scratch, and
   anything its own manifest or conventions mark as not-for-export.

4. **Seed-state guard** — the Local Registry / Local Matrix sections
   below the split-merge delimiter must be header-only in the export
   tree (Step 2, item 5). This is the one gate that catches a skipped
   reset before it publishes private bench/routing rows:

   ```bash
   bash tools/export-seed-check.sh <export-tree>
   # Expected: ok - export seed state clean + classification complete
   ```

   Run against canonical (intentionally filled) the header-only leg
   fails by design — it is an export-tree check, run after the Step 2
   reset. A downstream with its own delimited local sections points it
   at its own files by editing `SEED_FILES` in the script.

   The same gate also runs a **classification-completeness** leg: every
   file carrying the structural delimiter marker that the manifest marks
   `export=yes` must be either a `SEED_FILES` entry (reset here) or a
   `WAIVER` entry (its below-delimiter content legitimately publishes —
   e.g. `MEMORY.md`, the role charters). A new delimited exportable file
   in neither list fails the gate, so `SEED_FILES` can never silently go
   stale. This leg also runs standalone in CI as a live-repo invariant:

   ```bash
   bash tools/export-seed-check.sh --completeness .
   # Expected: ok - export seed classification complete
   ```

If any gate fails, fix it in the export tree and re-run all four gates
from the top — do not push on a partial pass.

---

## Step 4 — Publish

1. Commit the export tree as a single commit on the public repo's `main`.
   The commit message notes the source version and the divergence list
   (same content as the README's "About This Copy" section, condensed).
2. Create an annotated tag matching the canonical release being published
   (e.g. `v1.21.3`), on that commit:

   ```bash
   git tag -a v1.21.3 -m "minions-template v1.21.3 — public export"
   ```

3. Push the branch and the tag:

   ```bash
   git push public-origin main
   git push public-origin v1.21.3
   ```

4. Verify the push landed:

   ```bash
   git ls-remote public-origin
   # Expected: refs/heads/main and refs/tags/v1.21.3 both present,
   # pointing at the commit just pushed
   ```

---

## Re-publish cadence

Not every canonical release is published — only the ones the Operator
chooses to make public. When a canonical release is chosen:

1. Repeat Steps 1–4 in full, sourcing the new tree from the newly tagged
   canonical release.
2. The new commit lands on top of the public repo's own `main` — its
   shallow, publish-only history accumulates one commit per publish. It
   never merges with or imports canonical history.
3. Update the README's "About This Copy" section to reference the new
   source version and current divergence list.
4. Tag the new commit to match the newly published canonical release, and
   push branch + tag as in Step 4.

---

## Rollback note

There is no rollback. Public content may be cached, mirrored, or forked
the moment it is pushed — treat every push to the public repo as
irreversible, regardless of what happens afterward in the canonical repo
or the public repo's own history.

This is exactly why Step 2 (neutralization) and Step 3 (verification
gates) are **pre-push hard gates**, never post-push cleanup. A neutraliz-
ation or secret found after push cannot be un-published; it can only be
covered by a subsequent commit, which does not remove the earlier
exposure from anything that already cached or forked it. Get the sweep
and the gates right before the push, not after.
