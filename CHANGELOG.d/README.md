# CHANGELOG.d — Fragment Convention

This directory holds per-feature changelog fragments. The mechanism exists to
eliminate merge conflicts on `CHANGELOG.md`: every feature writes into its own
namespaced file here; consolidation happens exactly once, at the
`staging→main` gate, under DM ownership.

See `docs/branching-and-release-model.md` for the full branching model and the
canonical description of this mechanism.

## One fragment per feature

Each feature branch drops exactly one fragment:

```
CHANGELOG.d/<topic>.md
```

The `<topic>` matches the `feature/<topic>` branch name so fragments are
traceable back to the branch that produced them.

Fragments are **Class B** — they travel with the branch and merge up into
`staging` with the rest of the feature's work.

## Fragment format

Mirror the entry style used in `CHANGELOG.md` (newest-first, dated, human-
readable). Because the final commit hash is not known until the `staging→main`
merge, leave a placeholder note:

```markdown
## YYYY-MM-DD — <Short milestone title>

- Commit hash: (commit assigned at assembly)
- <Summary bullet 1>
- <Summary bullet 2>
```

Entries are prepended to `CHANGELOG.md` newest-first at assembly time, so
write each fragment as if it will land at the top of the file.

## Assembly at the staging gate

At step 6 of the Promotion Flow (`staging→main` prep), DM:

1. Reads all `CHANGELOG.d/*.md` files.
2. Prepends the assembled content into `CHANGELOG.md`, newest-first,
   filling in the commit hash and date.
3. Deletes the fragment files.
4. Commits the assembled changelog before PM opens the Gitea PR.

The PR therefore always includes the fully assembled `CHANGELOG.md` with no
fragment files remaining — the production history is always complete at the
point the Operator reviews it.

## Rule: no direct edits to CHANGELOG.md on feature branches

Feature branches **must not** edit `CHANGELOG.md` directly. Direct edits
cause the merge conflicts this mechanism was designed to eliminate. Any
minion or contributor who edits `CHANGELOG.md` on a feature branch will face
a merge conflict at `feature→dev` integration. Route all changelog content
through a fragment in this directory instead.

`CHANGELOG.md` is a Class-A file (mainline-authoritative) when considered as
the assembled record, but it is assembled only at the staging gate — never on
a feature branch.
