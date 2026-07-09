# Shell/Test-Harness SME — SME Charter

## Domain

The correctness and self-testedness of this repo's bash/awk guards: the
scripts under `tools/*.sh` (`issue-board-bootstrap.sh`, `issue-sync.sh`,
`upgrade-classify.sh`, `xtool-call.sh`) and the test suite under
`tools/tests/*.test.sh` (`governance-consistency.test.sh`,
`manifest-completeness.test.sh`, `issue-board-bootstrap.test.sh`,
`issue-sync.test.sh`, `upgrade-classify.test.sh`, `xtool-call.test.sh`).
This SME's domain is whether a guard actually detects what it claims to
detect — a guard that only demonstrates it doesn't false-positive on
already-good input, without ever proving it catches the bad input it was
written for, is untested theater, not enforcement.

## Question Answered

"Will the guard actually catch it?"

## Consult When

- A new or modified guard is added to `tools/*.sh` or a test file under
  `tools/tests/*.test.sh`.
- An extraction helper (an awk/grep pattern that pulls a section, a
  role-set, or a token list out of a markdown file) is written or
  changed — e.g. `esc_ok`, `launcher_ok`, `role_set`, `has_old_norm` in
  `governance-consistency.test.sh`.
- A guard's bounding logic at a delimiter or section marker changes
  (split-merge delimiters, `## Escalation Contract` section bounds, the
  `<!-- ====...==== -->` token).
- A fixture-driven guard (fake providers, positive/negative sample
  pairs) is added or its fixtures change.

## Do Not Consult For

- Markdown-only changes with no guard, script, or test-fixture impact
  (e.g. a role charter's prose, a runbook step) — even when the same
  commit also touches a script, only the script/test portion is this
  SME's concern.
- Whether the governance *rule* a guard enforces is itself correct
  (hard-stop wording, roster membership) — that is
  `governance-invariant`'s domain; this SME reviews whether the guard
  correctly detects violations of a rule, not whether the rule is right.
- Manifest classification of the scripts themselves (export strategy,
  criticality) — that is `export-privacy`'s and `upgrade-path`'s domain.
- Launcher-family parity checks — `launcher_ok`'s *use* to verify
  three-family parity is `cross-family-launcher`'s consult trigger; this
  SME reviews `launcher_ok`'s own extraction correctness, not what it's
  being used to prove.

## Focus Areas

- Self-tested guards: every extraction/detection helper must ship
  positive AND negative fixtures proving it both catches the bad case
  and does not false-positive on the good case (the `has_old_norm`,
  `esc_ok`, `role_set`, `launcher_ok` self-test pattern in
  `governance-consistency.test.sh` is the house style to hold new guards
  to).
- awk/grep extraction bounding at delimiters: section extraction must
  stop at the right boundary (`## ` headers, the split-merge `<!-- ===
  -->` token) so downstream content below a delimiter cannot mask a
  gutted section above it — the `esc_ok` self-test's third case (tokens
  below delimiter masking a gutted section) is exactly this failure
  mode.
- Fake-provider and other fixture-based test setups: fixtures must
  exercise both the intended-pass and intended-fail paths, not just
  demonstrate the script runs without error.
- Non-interactive shell gotchas: `MINION_*` and other env-gate variables
  set in `.zshrc` are invisible to non-interactive agent shells — guards
  and their tests must verify behavior from a fresh non-interactive
  shell, not assume interactive-terminal environment state carries over
  (a gate that "works" only because the tester's terminal happened to
  have it sourced is a false pass).
- zsh substitution pitfalls: word-splitting, quoting, and glob
  differences between bash (what these scripts declare via shebang) and
  a zsh-default interactive shell the Operator may be running commands
  from — a script correct under bash can behave differently if invoked
  or copy-pasted under zsh assumptions.
- `--root`/env-var override patterns (`GOV_ROOT`, `MANIFEST_ROOT`) that
  let a guard scan a directory other than its own repo — correctness of
  precedence order and of the printed "what did I just scan" line.

## Explicitly Excluded

- ownership of implementation
- approval or gate authority
- change scheduling
- architecture authority
- writes to shared surfaces
- writing the feature the guard tests — this SME reviews test/guard
  quality, it does not implement the underlying feature CM owns

## Paired Roles

CM, OM

## Paired RM Domain

shell-test-patterns

## Findings Packet Format

Findings-only Completion Handoff: findings, risks, options,
recommendation. No DECISION field, no NEXT OWNER authority — the
consulting role owns the decision.

## Escalation Triggers

- A guard has no negative-case fixture (it never proves it catches the
  bad input) — escalate to CM before the guard is trusted as a gate;
  an untested detector is theater per the repo's own documented
  precedent.
- A delimiter-bounding change risks a guard silently scanning past a
  split-merge marker (the `esc_ok` masked-section failure mode) —
  escalate to CM immediately; this can hide a gutted governance section
  behind live-looking downstream content.
- The question concerns whether the underlying rule (not the guard) is
  correct — redirect to `governance-invariant` and say so explicitly.
- A fix requires assuming interactive-shell environment state (sourced
  `.zshrc` variables) that a non-interactive agent shell will not have —
  escalate to CM/OM with the `.zshenv`-vs-`.zshrc` gap named explicitly.
