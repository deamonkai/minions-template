#!/usr/bin/env bash
# Creates a fake provider binary in $1 named $2 that records its argv to
# $1/<name>.args and prints a marker so the wrapper captures "output".
# Optional $3 = exit code the fake provider returns (default 0); use a non-zero
# value to simulate a provider failure (for delegate cleanup/F4 tests).
# Optional $4 = canned stdout (default "FAKE_<name>_OUTPUT").
#
# Special-case: when $2 == "tea", a richer fake is emitted that mimics the
# REAL behavior of `tea` v0.14.1 (the version verified against a live
# Gitea host). This is what the issue-mirror suites need to be
# faithful to the host CLI rather than to an idealized one:
#   * `tea issues create` / `tea issues edit` REQUIRE --description (-d) and
#     REJECT --body (0.14.1 renamed the flag); edit REJECTS --labels and
#     wants --add-labels. A --body-only call therefore FAILS, exactly as it
#     does on the real host.
#   * `tea labels create` EXITS 0 even on a duplicate label (it does NOT fail
#     on a name collision), and records the label so a re-run can be observed
#     to double the label set unless the caller is genuinely idempotent.
#   * `tea labels list` prints the labels recorded so far, so an idempotent
#     bootstrap can query-then-skip.
# For $4 with a tea provider, pass the canned create/edit URL (default a
# plausible issues URL) so the wrapper can parse the issue number.
set -euo pipefail
dir="$1"; name="$2"; rc="${3:-0}"
mkdir -p "$dir"

if [ "$name" = tea ]; then
  # 0.14.1-faithful fake. $rc lets a test force a hard backend failure
  # (rc != 0) regardless of flag validity (used by the soft-fail tests).
  # $4 is the canned create/edit URL; if the caller didn't pass one, default
  # to a plausible issues URL (the generic FAKE_<name>_OUTPUT placeholder
  # below is not a valid issue URL, so tea needs its own default here).
  [ $# -ge 4 ] || out="https://git.example.net/o/r/issues/42"
  out="${4:-$out}"
  cat > "$dir/$name" <<EOF
#!/usr/bin/env bash
# fake tea v0.14.1
set -u
HERE="\$(dirname "\$0")"
printf '%s\n' "\$@" >> "\$HERE/tea.args"
FORCE_RC=${rc}
CANNED_OUT='${out}'

have() { # flag present in argv?
  local want="\$1"; shift
  for a in "\$@"; do [ "\$a" = "\$want" ] && return 0; done
  return 1
}

sub1="\${1:-}"; sub2="\${2:-}"

case "\$sub1 \$sub2" in
  "issues create"|"issues edit")
    # 0.14.1 wants --description / -d (NOT --body), and on edit --add-labels
    # (NOT --labels). Model the real rejection so a stale-flag call fails.
    if have --body "\$@"; then
      printf 'Error: unknown flag: --body\n' >&2
      exit 1
    fi
    if [ "\$sub2" = edit ] && have --labels "\$@"; then
      printf 'Error: unknown flag: --labels\n' >&2
      exit 1
    fi
    if ! have --description "\$@" && ! have -d "\$@"; then
      printf 'Error: required flag "--description" not set\n' >&2
      exit 1
    fi
    [ "\$FORCE_RC" -ne 0 ] && { printf 'backend failure\n' >&2; exit "\$FORCE_RC"; }
    printf '%s\n' "\$CANNED_OUT"
    exit 0
    ;;
  "labels create")
    # 0.14.1 does NOT fail on a duplicate name: it exits 0 and creates a
    # second same-named label. Record every create so a test can observe
    # the doubling that a non-idempotent bootstrap produces.
    name_val=""
    while [ \$# -gt 0 ]; do
      case "\$1" in --name) name_val="\${2:-}"; shift 2 || break;; *) shift;; esac
    done
    [ -n "\$name_val" ] && printf '%s\n' "\$name_val" >> "\$HERE/tea.labels.created"
    [ "\$FORCE_RC" -ne 0 ] && exit "\$FORCE_RC"
    exit 0
    ;;
  "labels list")
    # Print the set of distinct labels created so far (one per line), the
    # shape an idempotent bootstrap greps to decide skip-vs-create.
    if [ -f "\$HERE/tea.labels.created" ]; then
      sort -u "\$HERE/tea.labels.created"
    fi
    exit 0
    ;;
  *)
    [ "\$FORCE_RC" -ne 0 ] && exit "\$FORCE_RC"
    printf '%s\n' "\$CANNED_OUT"
    exit 0
    ;;
esac
EOF
  chmod +x "$dir/$name"
  exit 0
fi

if [ "$name" = gh ]; then
  # gh-faithful fake (mirrors the tea fake's rigor). Models the flag surface the
  # issue-sync github path actually uses and REJECTS the wrong label flag on the
  # wrong subcommand, so a stale-flag regression fails here instead of silently
  # passing a dumb argv recorder:
  #   * `gh issue create` is non-interactive: REQUIRES --title and --body, uses
  #     --label (comma-separated), and does NOT know --add-label — passing it is
  #     an unknown-flag error, exactly as on real gh.
  #   * `gh issue edit <n>` REQUIRES the positional issue number, uses --add-label,
  #     and does NOT know a bare --label — passing it is an unknown-flag error.
  # $rc forces a hard backend failure regardless of flag validity (soft-fail test).
  # $4 is the canned create/edit URL the wrapper parses for the issue number.
  # `gh label` subcommands are intentionally NOT modeled (no test exercises them;
  # they fall to the default arm as a plain recorder). Add them here if a github
  # board test ever needs list/create faithfulness — note real `gh label create`
  # FAILS on a duplicate name (unlike tea's exit-0), so do not copy the tea shape.
  [ $# -ge 4 ] || out="https://github.com/o/r/issues/7"
  out="${4:-$out}"
  cat > "$dir/$name" <<EOF
#!/usr/bin/env bash
# fake gh (github issue path faithful)
set -u
HERE="\$(dirname "\$0")"
printf '%s\n' "\$@" >> "\$HERE/gh.args"
FORCE_RC=${rc}
CANNED_OUT='${out}'

have() { local want="\$1"; shift; for a in "\$@"; do [ "\$a" = "\$want" ] && return 0; done; return 1; }

sub1="\${1:-}"; sub2="\${2:-}"; pos3="\${3:-}"
case "\$sub1 \$sub2" in
  "issue create")
    have --add-label "\$@" && { printf 'unknown flag: --add-label\n' >&2; exit 1; }
    { have --title "\$@" && have --body "\$@"; } \
      || { printf 'Error: required flags --title and --body not set\n' >&2; exit 1; }
    [ "\$FORCE_RC" -ne 0 ] && { printf 'backend failure\n' >&2; exit "\$FORCE_RC"; }
    printf '%s\n' "\$CANNED_OUT"; exit 0 ;;
  "issue edit")
    have --label "\$@" && { printf 'unknown flag: --label\n' >&2; exit 1; }
    case "\$pos3" in ''|-*) printf 'Error: issue number required\n' >&2; exit 1;; esac
    [ "\$FORCE_RC" -ne 0 ] && { printf 'backend failure\n' >&2; exit "\$FORCE_RC"; }
    printf '%s\n' "\$CANNED_OUT"; exit 0 ;;
  *)
    [ "\$FORCE_RC" -ne 0 ] && exit "\$FORCE_RC"
    printf '%s\n' "\$CANNED_OUT"; exit 0 ;;
esac
EOF
  chmod +x "$dir/$name"
  exit 0
fi

# Default (non-tea) fake: simple argv recorder used by the xtool-call suite.
out="${4:-FAKE_${name}_OUTPUT}"
cat > "$dir/$name" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" >> "$dir/$name.args"
printf '%s\n' "$out"
exit ${rc}
EOF
chmod +x "$dir/$name"
