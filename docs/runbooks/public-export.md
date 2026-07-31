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

   **Mode-bit note:** if the copy is done via `git show <sha>:<path> >
   <dest>` (or any other content-only extraction) rather than a full
   working-tree checkout/copy, the executable bit (mode `100755`) is
   dropped on every script it touches. This fails closed — Step 3 gate 1
   (the test suite) surfaces it as `Permission denied` on the affected
   scripts — but it can burn real time before the cause is obvious.
   Restore exec bits (`chmod +x`) on script-shaped files after extraction,
   or extract by a method that preserves mode bits.
2a. **Also copy every `seed only` row** — these are neither `yes` nor excluded
   above, so they need naming explicitly or a literal reading of item 2 drops
   them and the export ships without the seeds. They enter the tree WITH their
   canonical content and are stripped to their stubs in Step 2 item 4; they are
   never published as copied. `docs/export-manifest.md`'s `Initial export: seed
   only` rows are the sole authority on this class — enumerate it mechanically,
   never from memory or a list maintained in this runbook:

   ```bash
   grep 'seed only' docs/export-manifest.md
   ```

   `tools/export-seed-check.sh`'s `manifest_seed_paths()` derives the same set
   programmatically for the Step 3 gate below, so the procedure and the guard
   always read the same source.
3. Deliberately **add `README.md`** even though the manifest classes it
   `downstream-owned` (a downstream project is expected to replace it with
   project-specific content). The public copy is different: it has no
   downstream project behind it, and `README.md` is the template's public
   landing page. Write it with an "About This Copy" section stating:
   - the canonical source version (the tag exported from, e.g. `v1.21.3`)
   - the divergence list — anything the public copy deliberately omits or
     changes relative to canonical (maintainer-local files, neutralized
     phrasing, fresh history)
4. **Verify canonical's own delimiter-completeness invariant.** This is a
   numbered precondition of this runbook, not one of the Step 3 gates below:
   Step 3's four gates all run against the *built export tree*; this one
   runs against *canonical* — the checkout you just made in item 1 — and
   must hold before the export tree built from it can be trusted. There is
   no CI in this repo to run it continuously; treat it as a manual gate
   here, and re-run it whenever canonical changes:

   ```bash
   bash tools/export-seed-check.sh --completeness .
   # Expected: ok - export seed classification complete (delimiter completeness + seed-only marker presence)
   ```

   A failure here means canonical itself is broken (an exportable delimited
   file is missing its `SEED_FILES`/`WAIVER` classification, or a `seed
   only` surface is missing its `STUB BOUNDARY` marker) — fix canonical and
   re-run this item before proceeding to Step 2.

---

## Step 2 — Privacy-neutralization sweep

Do this **tree-wide and token-based**, not as a single targeted edit.

The live 2026-07-02 run first tried a single-line pass (fix the one known
personal line in `MEMORY.md`) and it was incomplete: an "(handoff contract)"
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
4. Reset every `seed only` surface to a clean stub. `docs/export-manifest.md`'s
   `Initial export: seed only` rows are the sole authority on which files
   these are — enumerate mechanically (`grep 'seed only' docs/export-
   manifest.md`, or `manifest_seed_paths()` in `tools/export-seed-check.sh`),
   never from a roster kept in this runbook, so a surface added to the class
   later is covered here without editing this step.

   A seed stub ships the *shape* a downstream needs — section headings,
   status/format conventions, structural placeholders — and none of this
   repo's content: no Operator-specific examples or history, no accrued
   backlog or roadmap entries, no template-maintenance direction that names
   downstream projects or maintainer infrastructure, no project-specific
   prose. The reset is a privacy step, not tidiness — several files in this
   class accrue exactly the kind of running history and backlog detail that
   must not publish.

   The reset removes each file's `STUB BOUNDARY` marker line along with
   everything below it, leaving only the seed. Step 3 gate 4 checks exactly
   that, so leaving the marker in place fails the gate.

   **Also reset the above-marker staleness anchors.** `docs/MECHANICS.md`
   carries two fields ABOVE its `STUB BOUNDARY` marker that the strip above
   cannot reach: the real commit SHA on the `verified @ <sha>` line and the
   real area list on the `Mapped areas: <paths>` line. Replace each with its
   literal placeholder so the lines read back exactly as:

   ```
   verified @ <sha>
   Mapped areas: <paths>
   ```

   `tools/export-seed-check.sh` verifies this reset ran (Step 3 gate 4) via
   its `SEED_ANCHORS` table — a skipped anchor reset fails the gate the same
   way a skipped marker strip does.
5. The template-default blocks SHIP as starters: the "Default Bench
   (template-shipped)" / "Default Matrix (template-shipped)" / "Default
   Capabilities (template-shipped)" sections ABOVE the split-merge delimiter
   in `minions/smes/README.md`, `minions/review-matrix.md`, and
   `minions/capabilities.md` publish with the tree — they are generic
   template infrastructure. Reset ONLY the BELOW-delimiter "Local
   Registry (this repo)" / "Local Matrix (this repo)" / "Local Inventory
   (this repo)" sections to header-only seed state; any downstream-project-
   added SMEs, routing rows, or capability rows stay local and never publish
   (the feedback.md-stub treatment, generalized). **Reset the explanatory
   prose too, not just the data rows** — a plain "reset to header-only seed
   state" reading can leave the intro paragraph above an empty table in
   place; `seed_violations()` treats any non-blank, non-heading, non-header-
   row line as a leak, and all three `SEED_FILES` (`minions/smes/README.md`,
   `minions/review-matrix.md`, `minions/capabilities.md`) ship such prose
   below the delimiter today. Step 3 gate 4 enforces the header-only
   below-delimiter state mechanically — skipping this reset fails the
   pre-push gates.

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

4. **Seed-state guard** — one invocation, four properties. Gates that used to
   be numbered 4 and 5 collapse into this single command, which is also the
   verifier for the anchor reset above:

   ```bash
   bash tools/export-seed-check.sh <export-tree>
   # Expected: ok - export seed state clean + classification complete + no seed-only markers or anchor drift survive
   ```

   Run against canonical (intentionally filled) this fails by design — it is
   an export-tree check, run after the Step 2 reset. It asserts, in one pass:

   - the Local Registry / Local Matrix sections below the split-merge
     delimiter are header-only (Step 2, item 5) — a downstream with its own
     delimited local sections points this leg at its own files by editing
     `SEED_FILES` in the script;
   - every file carrying the structural delimiter marker that the manifest
     marks `export=yes` is classified `SEED_FILES` or `WAIVER` (below-delimiter
     content that legitimately publishes, e.g. `MEMORY.md`, the role
     charters) — a new delimited exportable file in neither list fails the
     gate, so `SEED_FILES` can never silently go stale. **A downstream that
     puts real content below a `WAIVER`-classified file's delimiter must
     move that file from its local `WAIVER` list to its local `SEED_FILES`
     list and reset it at Step 2 like any other filled registry** — `WAIVER`
     means "legitimately empty below the marker in this repo," and stays
     true only as long as that holds. This applies uniformly to `AI.md`,
     `docs/export-manifest.md`, and `MEMORY.md`: each ships `WAIVER`/empty
     in the canonical template but becomes real downstream content the
     moment a project adds its own notes below the marker;
   - no `seed only` surface's `STUB BOUNDARY` marker survives anywhere in the
     tree (Step 2, item 4's strip) — a surviving marker means that reset was
     skipped;
   - the `docs/MECHANICS.md` staleness anchors read back as their literal
     placeholders (Step 2, item 4's anchor reset, above) — a downstream with
     its own above-marker anchors points this leg at its own fields via the
     script's `SEED_ANCHORS` table.

   The delimiter-classification and seed-only-marker-presence halves of this
   pair are also asserted directly against canonical, as the SOURCE-side
   guarantee — not only at publish time. **There is no CI in this repo to run
   that continuously**; it is the numbered precondition at Step 1, item 4,
   which runs the identical command against canonical before the export tree
   is even built.

   **Known limits (named, not built for — the guard checks file state, not
   intent):**

   - **Circumvention residual.** The gate can only see whether a marker
     line and the anchor lines read back correctly; it cannot tell "the
     Step 2 reset genuinely ran" from "someone manually deleted the marker
     and content, or hand-typed the literal placeholder values, to make the
     check pass." A deliberately falsified export tree that never went
     through Step 2 can still satisfy this gate. This is a residual risk
     accepted by design, not a gap to close with more tooling — the
     Operator running the export is the trust boundary here, the same as
     every other pre-push gate in this runbook.
   - **`SEED_ANCHORS` completeness is unenforced.** The table in
     `tools/export-seed-check.sh` is hand-maintained data, not derived from
     anything. If a `seed only` surface gains a new above-marker field
     carrying repo-specific content and nobody adds a matching
     `SEED_ANCHORS` row in the same change, that field publishes silently —
     no gate here or elsewhere catches the omission. See
     `docs/export-manifest.md`'s `seed only` definition and
     `docs/MECHANICS.md`'s "Maintaining this map" section, both of which
     carry a reminder at the point an editor would add such a field.
   - **Per-file stub spec lives in the manifest's Notes column, not here.**
     This runbook names the mechanical checks; it does not restate what
     each individual seed stub must and must not contain file by file. That
     detail is `docs/export-manifest.md`'s Notes column for each `seed
     only` row (e.g. what `docs/DESIGN.md`'s stub keeps vs. strips) — read
     it there, not from a roster in this runbook, which is exactly the
     drift A6/wave-2b removed by retiring the hand-maintained per-file
     enumerations that used to live at Step 1 item 2a and Step 2 item 4.
   - **Indented marker.** `STUB_PATTERN` is anchored to column 0, so a
     *real* `STUB BOUNDARY` marker indented even one space is invisible to
     Leg E (the export-tree absence check) — a private-content block placed
     below such a marker in the export tree passes gate 4 as `ok`, exit 0.
     The compensating control is Leg S, which requires the marker at column
     0 in canonical (Step 1, item 4) — an indented marker in canonical fails
     Leg S before an export tree is ever built. This is exactly why that
     precondition running is load-bearing, not optional: a downstream that
     skips it and hand-indents a marker gets no other warning.
   - **Unmanifested delimited file.** A file with a real, column-0
     `STUB BOUNDARY` marker and content below it, but no row in
     `docs/export-manifest.md`, falls outside the completeness scope filter
     — gate 4 returns `ok` without ever inspecting it. For tracked files
     this is contained by `manifest-completeness.test.sh` (every tracked
     file must have a manifest row); it is uncontained for anything
     hand-added directly into the export tree after the manifest-driven
     copy step, which is outside both guards' visibility — the same
     trust-boundary reasoning as the circumvention residual above.
   - **WARN visibility.** `export-seed-check.sh` writes its `WARN` lines to
     stderr and its final `ok`/`FAIL` verdict to stdout. An operator who
     captures stdout only (e.g. `... > log.txt`) sees a clean `ok` with any
     WARNs — an absent seed file, an absent `SEED_FILES`/`WAIVER` row, an
     absent anchor line — silently dropped. Capture stderr too when running
     any gate in this runbook, or the WARN class of finding is invisible by
     construction.

If any gate fails, fix it in the export tree and re-run all four gates
from the top — do not push on a partial pass. (Step 1, item 4 is a
separate precondition against canonical; a failure there means canonical
itself needs fixing before the export tree is worth building at all.)

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
