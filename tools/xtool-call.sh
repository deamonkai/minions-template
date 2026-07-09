#!/usr/bin/env bash
# xtool-call.sh — invoke another AI CLI (codex|copilot) headlessly as an
# independent reviewer (read-only) or a worktree-isolated delegate.
# Never merges, never pushes.
set -uo pipefail

PROVIDER=""; MODE=""; ROLE=""; TARGET=""; TOPIC="adhoc"; OUTDIR=".pipeline"; PROMPT=""

# D5 (capability discovery, v1.23.0): standing envelope line appended to every
# cross-tool prompt — both providers, both modes — so the callee enumerates and
# uses its OWN environment's capabilities (Claude/Codex/Copilot carry different
# sets; the caller cannot know the callee's). Mode-aware (v1.23.0 minor sweep):
# the REVIEW path is read-only by contract (codex -s read-only; copilot
# deny-tool write/shell), but side-effectful MCP connectors remain invocable
# there, so the review line qualifies utilization to READ-ONLY tools and
# forbids state-changing calls; the DELEGATE line stays unqualified (delegates
# have write scope by design). Tests assert these exact strings reach the
# provider argv: keep each byte-identical and defined only here, one per mode.
UTIL_LINE_DELEGATE='Enumerate your available skills/tools first and utilize any that fit the task; report which you used.'
UTIL_LINE_REVIEW='Enumerate your available skills/tools first and utilize any READ-ONLY ones that fit the task; make no state-changing tool calls during review; report which you used.'

usage() { echo "usage: xtool-call.sh --provider <codex|copilot|gemini> --mode <review|delegate> --prompt <text|-> [--role r] [--target p] [--topic s] [--out d]   ('-' reads the prompt from stdin)" >&2; }

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      # value options: guard a missing value (a bare `shift 2` with <2 args would
      # not advance -> infinite loop).
      --provider|--mode|--role|--target|--topic|--out|--prompt)
        [ $# -ge 2 ] || { echo "xtool: $1 needs a value" >&2; usage; exit 2; }
        case "$1" in
          --provider) PROVIDER="$2";; --mode) MODE="$2";; --role) ROLE="$2";;
          --target) TARGET="$2";; --topic) TOPIC="$2";; --out) OUTDIR="$2";;
          # `--prompt -` reads the prompt from stdin, same as a standalone `-`.
          # Without this, `--prompt -` would set the prompt to the literal "-"
          # (silent footgun: codex errors, but copilot runs a garbage review).
          --prompt) if [ "$2" = "-" ]; then PROMPT="$(cat)"; else PROMPT="$2"; fi;;
        esac
        shift 2;;
      -)          PROMPT="$(cat)"; shift;;
      *) usage; exit 2;;
    esac
  done
  [ -n "$PROVIDER" ] && [ -n "$MODE" ] || { usage; exit 2; }
  case "$PROVIDER" in codex|copilot|gemini) ;; *) usage; exit 2;; esac
  case "$MODE" in review|delegate) ;; *) usage; exit 2;; esac
  # A prompt is always required. An empty prompt (including `--prompt -` with
  # empty stdin) is a caller mistake — fail loudly before invoking any provider.
  [ -n "$PROMPT" ] || { echo "xtool: --prompt is required and must be non-empty (use --prompt - to read stdin)" >&2; usage; exit 2; }
}

stamp() { date +%Y%m%d-%H%M%S; }

# json_escape: escape \, ", and newline so values are safe inside JSON strings.
json_escape() {
  local v="$1"
  v="${v//\\/\\\\}"   # backslash first
  v="${v//\"/\\\"}"   # double-quote
  v="${v//$'\n'/\\n}" # newline
  printf '%s' "$v"
}

emit_envelope() { # emit_envelope <status> <exit_status> <branch> <worktree> <raw_file>
  mkdir -p "$OUTDIR"
  local f="$OUTDIR/xtool-${PROVIDER}-${MODE}-$(stamp).json"
  local role_e; role_e="$(json_escape "$ROLE")"
  local target_e; target_e="$(json_escape "$TARGET")"
  local topic_e; topic_e="$(json_escape "$TOPIC")"
  cat > "$f" <<EOF
{
  "provider": "$PROVIDER",
  "mode": "$MODE",
  "role": "$role_e",
  "target": "$target_e",
  "topic": "$topic_e",
  "branch": "${3:-}",
  "worktree": "${4:-}",
  "exit_status": ${2:-0},
  "status": "$1",
  "raw_output_file": "${5:-}",
  "invocation": "$PROVIDER $MODE"
}
EOF
  echo "$f"
}

resolve_provider() { command -v "$PROVIDER" >/dev/null 2>&1; }

run_review() {
  # Confirmed read-only enforcement (from --help):
  #   codex:   -s, --sandbox <SANDBOX_MODE> with value "read-only"
  #            (possible values: read-only, workspace-write, danger-full-access)
  #            `codex exec -s read-only <prompt>` enforces sandbox read-only mode.
  #   copilot: Read-only is enforced via the deny-tool mechanism verified from
  #            `copilot help permissions`:
  #              "Denial rules always take precedence over allow rules,
  #               even --allow-all-tools."
  #            Permission kind `write` matches tools that create and modify files
  #            (except shell invocations). Permission kind `shell` matches shell
  #            commands (which can write via redirection). Denying both guarantees
  #            no file writes and no shell access, while read/view/search tools
  #            remain available — exactly read-only review.
  #            --allow-all-tools is still required for non-interactive (-p) mode,
  #            but deny-tool precedence overrides it: the model gets auto-approval
  #            for tools that are not denied (read tools), but write+shell are
  #            blocked by the denial rules regardless of --allow-all-tools.
  #            No --allow-all-paths and no --add-dir are passed, so file access
  #            stays restricted to cwd and subdirectories (default).
  local raw="$OUTDIR/xtool-${PROVIDER}-review-$(stamp).out"
  mkdir -p "$OUTDIR"
  local rc=0
  case "$PROVIDER" in
    codex)
      # read-only enforced by -s read-only (--sandbox read-only)
      codex exec -s read-only "${PROMPT}
${UTIL_LINE_REVIEW}
Target: ${TARGET}" >"$raw" 2>&1 || rc=$?
      ;;
    copilot)
      # non-interactive (--allow-all-tools) + deny-tool beats allow-all-tools
      # (verified: copilot help permissions); write+shell denied = read-only;
      # no write paths granted (no --allow-all-paths, no --add-dir).
      copilot -p "${PROMPT}
${UTIL_LINE_REVIEW}
Target: ${TARGET}" --allow-all-tools --deny-tool 'write' --deny-tool 'shell' >"$raw" 2>&1 || rc=$?
      ;;
    gemini) echo "gemini provider not wired yet" >&2; emit_envelope "provider-unavailable" 3 "" "" "" >/dev/null; return 3;;
  esac
  # Status honesty: the envelope is the durable artifact a caller parses, so it
  # must not report "ok" when the provider failed or produced nothing usable.
  local status="ok"
  if [ "$rc" -ne 0 ]; then
    status="review-failed"
  elif [ -z "$(tr -d '[:space:]' <"$raw" 2>/dev/null)" ]; then
    # provider exited 0 but produced empty/whitespace-only output -> not a real
    # review (auth prompt, silent no-op, etc.); flag with a distinct rc (4).
    status="review-empty-output"; rc=4
  fi
  emit_envelope "$status" "$rc" "" "" "$raw" >/dev/null
  if [ "$status" = "ok" ]; then
    echo "xtool: review complete ($PROVIDER) -> $raw" >&2
  else
    echo "xtool: review $status ($PROVIDER, rc=$rc) -> $raw" >&2
  fi
  return "$rc"
}
run_delegate() {
  # Delegate: create an isolated worktree+branch, run provider with write scope,
  # capture the proposed diff. NEVER runs git merge, git push, or git switch on
  # the caller's branch — merge to main is a human gate handled elsewhere.
  #
  # Confirmed codex write-sandbox flag (from `codex exec --help`):
  #   -s, --sandbox <SANDBOX_MODE>
  #     [possible values: read-only, workspace-write, danger-full-access]
  # Write mode: `codex exec -s workspace-write <prompt>`  (consistent with
  # Task 2's `codex exec -s read-only`; NOT --config sandbox_mode=... form)
  #
  # copilot write mode: --allow-all-tools --add-dir "<worktree abs path>"
  #   --allow-all-tools is required for non-interactive -p mode.
  #   --add-dir scopes write access to the worktree; --allow-all-paths is NOT
  #   used (that would disable path verification and allow writes anywhere).
  #   Denial rules (deny-tool) are NOT set here — delegate needs write+shell.
  #   Isolation comes from the worktree being a separate directory + --add-dir.
  [ -n "$ROLE" ] || { echo "delegate requires --role" >&2; return 2; }
  local slug="${PROVIDER}-${ROLE}-${TOPIC}"
  # F2: --role/--topic flow into the branch name and worktree path. Reject
  # path-unsafe values (path traversal / unpredictable placement) BEFORE creating
  # any worktree or branch — fail loudly rather than silently mangling the path.
  case "$slug" in
    *..*) echo "xtool: --role/--topic must not contain '..' (path-safe slug required); got '$slug'" >&2; return 2;;
    *[!A-Za-z0-9._-]*) echo "xtool: --role/--topic allow only [A-Za-z0-9._-] (no '/', whitespace, etc.); got '$slug'" >&2; return 2;;
  esac
  local branch="xtool/${slug}"
  local wt=".xtool-worktrees/${slug}"
  # Charset-safe but still git-ref-invalid values (e.g. '.', a trailing '.lock',
  # a leading '-') would otherwise fail opaquely at `git worktree add`; reject clearly.
  git check-ref-format "refs/heads/${branch}" >/dev/null 2>&1 || {
    echo "xtool: '$branch' is not a valid git branch name (e.g. '.', trailing '.lock'); pick a different --role/--topic." >&2; return 2; }
  local raw="$OUTDIR/xtool-${PROVIDER}-delegate-$(stamp).out"
  # F4: record the base commit the worktree is created from. Work is measured
  # against THIS base, not the worktree's moving HEAD — a delegate may COMMIT its
  # output (the repo norm asks minions to commit before handoff), so a
  # staged-vs-HEAD check would wrongly read empty and could discard committed work.
  local base; base="$(git rev-parse HEAD 2>/dev/null)"
  mkdir -p "$OUTDIR" ".xtool-worktrees"
  git worktree add -b "$branch" "$wt" HEAD >/dev/null 2>&1 || {
    echo "xtool: could not create worktree $wt — branch '$branch' or dir may already exist." >&2
    echo "xtool: if a prior delegate left it stale: git worktree remove --force $wt ; git branch -D $branch" >&2
    return 1; }
  local rc=0
  case "$PROVIDER" in
    codex)
      # -s workspace-write: allow writes inside the worktree sandbox
      ( cd "$wt" && codex exec -s workspace-write "${PROMPT}
${UTIL_LINE_DELEGATE}" ) >"$raw" 2>&1 || rc=$?
      ;;
    copilot)
      # --add-dir scopes write access to worktree abs path only (no --allow-all-paths)
      local wt_abs; wt_abs="$(cd "$wt" && pwd)"
      ( cd "$wt" && copilot -p "${PROMPT}
${UTIL_LINE_DELEGATE}" --allow-all-tools --add-dir "$wt_abs" ) >"$raw" 2>&1 || rc=$?
      ;;
    gemini) echo "gemini provider not wired yet" >&2; git worktree remove --force "$wt" 2>/dev/null; git branch -D "$branch" 2>/dev/null || true; emit_envelope "provider-unavailable" 3 "" "" "" >/dev/null; return 3;;
  esac
  # Capture the proposed work (committed AND uncommitted) vs the base the worktree
  # was created from; DO NOT merge or push — that is the human gate.
  git -C "$wt" add -A >/dev/null 2>&1 || true
  {
    echo "# commits since base (${base}):"; git -C "$wt" log --oneline "${base}..HEAD" 2>/dev/null
    echo "# working-tree + committed diff vs base:"; git -C "$wt" diff "${base}" 2>/dev/null
  } >>"$raw"
  # Decide whether the delegate produced work, distinguishing "proven empty" from
  # "could not tell". Capture each git query's exit status: ONLY a successful,
  # genuinely-empty inspection of BOTH commits-since-base and dirty-state authorizes
  # self-cleanup. If either query errors, treat work as possibly-present and keep the
  # worktree — never delete on uncertainty (a delegate may have committed its output).
  local rl rl_rc st st_rc clean_safe=""
  rl="$(git -C "$wt" rev-list "${base}..HEAD" 2>/dev/null)"; rl_rc=$?
  st="$(git -C "$wt" status --porcelain 2>/dev/null)"; st_rc=$?
  if [ "$rl_rc" -eq 0 ] && [ "$st_rc" -eq 0 ] && [ -z "$rl" ] && [ -z "$st" ]; then
    clean_safe=1
  fi
  # F4: a failed delegate must not strand a stale worktree+branch that dead-ends the
  # next same-topic run — and must never silently destroy work.
  if [ "$rc" -ne 0 ]; then
    if [ -n "$clean_safe" ]; then
      # failed AND inspection proved empty -> safe to self-clean so the topic is reusable
      if git worktree remove --force "$wt" >/dev/null 2>&1 && git branch -D "$branch" >/dev/null 2>&1; then
        emit_envelope "delegate-failed" "$rc" "" "" "$raw" >/dev/null
        echo "xtool: delegate FAILED (rc=$rc), no work produced -> cleaned up worktree+branch." >&2
      else
        # cleanup itself failed -> DISCLOSE the residual state; do not claim clean
        emit_envelope "delegate-failed-cleanup-incomplete" "$rc" "$branch" "$wt" "$raw" >/dev/null
        echo "xtool: delegate FAILED (rc=$rc); automatic cleanup did NOT fully succeed." >&2
        echo "xtool: remove manually: git worktree remove --force $wt ; git branch -D $branch" >&2
      fi
      return "$rc"
    fi
    # produced work, OR inspection could not confirm empty -> KEEP everything; never
    # delete on uncertainty. Use ';' in the hint so both run even if the worktree is
    # already gone on a rerun.
    emit_envelope "delegate-failed-partial" "$rc" "$branch" "$wt" "$raw" >/dev/null
    echo "xtool: delegate FAILED (rc=$rc); kept worktree $wt / branch $branch (work present or unverifiable)." >&2
    echo "xtool: to discard and free the topic: git worktree remove --force $wt ; git branch -D $branch" >&2
    return "$rc"
  fi
  emit_envelope "ok" "$rc" "$branch" "$wt" "$raw" >/dev/null
  echo "xtool: delegate complete ($PROVIDER as $ROLE) -> branch $branch, worktree $wt" >&2
  echo "xtool: review the diff, then MERGE IS A HUMAN GATE (no auto-merge)." >&2
  return "$rc"
}

main() {
  parse_args "$@"
  if ! resolve_provider; then
    emit_envelope "provider-unavailable" 3 "" "" "" >/dev/null
    echo "xtool: provider '$PROVIDER' not found on PATH; skipping." >&2
    exit 3
  fi
  case "$MODE" in
    review)   run_review;;
    delegate) run_delegate;;
  esac
}
main "$@"
