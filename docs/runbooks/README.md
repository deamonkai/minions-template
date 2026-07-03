# Runbooks — Structure Contract

Every runbook (procedure doc) in this directory carries these sections,
under these names or explicitly labeled equivalents:

1. **Purpose / Audience** — what this procedure does, who runs it
2. **Prerequisites / Assumptions** — required access, tools, state
3. **Procedure** — the numbered steps
4. **Validation** — how to verify the procedure worked (commands with
   expected output where possible)
5. **Rollback** — how to undo it. An explicit "there is no rollback —
   treat as irreversible" statement satisfies this section (see
   `public-export.md`); silence does not.

Optional: Troubleshooting, References.

Two hard rules (DM-checkable at every doc-sync pass; violations are
review findings):

- **No deployment procedure without a rollback section.**
- **No implementation procedure without a validation section.**

These rules restate the existing hard-stop posture — destructive or
production-affecting actions require rollback posture — as a document
contract, so the gap is caught at writing time, not deploy time.
