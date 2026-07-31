#!/usr/bin/env bash
set -uo pipefail
# Export-tree seed-state guard — public-export runbook Step 3, gates 4-5.
#
# Four guarantees:
#
# 1. HEADER-ONLY (seed reset): the neutralization sweep (public-export.md Step 2,
#    item 5) resets the content BELOW the split-merge delimiter in the Local Registry
#    / Local Matrix files to header-only seed state — the canonical repo's own SME
#    bench and routing rows are maintainer content and must never publish. That reset
#    is manual prose; nothing else in the pre-push gate stack (test suite, gitleaks,
#    forbidden-files) notices a skipped reset, so a miss silently ships private rows
#    to the PUBLIC mirror (irreversible). This guard FAILS unless everything below the
#    delimiter in SEED_FILES is header-only.
#
# 2. CLASSIFICATION COMPLETENESS: guarantee 1 is only as good as SEED_FILES. A NEW
#    exportable file that grows a filled local section below a delimiter would ship
#    with a green gate if nobody remembered to enroll it. This check finds every file
#    carrying the STRUCTURAL delimiter marker (the real `<!-- ... -->` line, not a
#    prose mention of it), scopes to export=yes via docs/export-manifest.md, and FAILS
#    any that is neither a SEED_FILE nor explicitly WAIVED — the same drift the
#    manifest-completeness guard closes for manifest rows.
#
# 3. SEED-ONLY MARKER PAIR (A2): an absence assertion is only a gate when paired with
#    a continuously-enforced presence guarantee on the source it derives from — the
#    same shape as guarantees 1/2 above, applied to the `seed only` manifest class
#    (today: feedback.md, TODO.md, ROADMAP.md, docs/MECHANICS.md, docs/DESIGN.md).
#      Leg S (SOURCE invariant, --completeness only): every manifest `seed only`
#      path MUST carry a structural STUB BOUNDARY marker in the live repo. A
#      seed-only surface with no marker FAILS. This is what makes Leg E's absence
#      check non-vacuous: source-has-marker AND export-lacks-marker implies the
#      Step 2 reset ran; without Leg S, "no marker in the export tree" is
#      indistinguishable from "never had one."
#      Leg E (EXPORT-tree state, both/default mode only): no structural STUB
#      BOUNDARY marker survives anywhere in the tree. Retires the old runbook
#      gate-5 grep — same anchored pattern, same find_marked() helper guarantee 2
#      already uses for the DOWNSTREAM CONTENT BELOW delimiter.
#    Never hardcode a seed-file array: manifest_seed_paths() derives the set from
#    docs/export-manifest.md, mirroring manifest_yes_paths() for guarantee 2. The
#    parse is deliberately WHOLE-FILE / delimiter-agnostic (same `^\| \`` anchor),
#    so a downstream's own seed-only rows below ITS split-merge delimiter are
#    enforced too — scoping the parse to above the delimiter would silently void
#    the portability story (see fixture F-G).
#    Leg S and Leg E are mutually exclusive by mode: Leg S must never run in
#    `both` (a correctly-reset export tree has no marker and would fail Leg S by
#    design); Leg E must never run under `--completeness` (canonical is
#    intentionally filled and carries the marker).
#
# 4. SEED ANCHOR CONFORMANCE (A2b): SEED_ANCHORS names above-marker fields on an
#    otherwise-seed-only surface that carry repo-specific content (today:
#    docs/MECHANICS.md's `verified @ <sha>` / `Mapped areas: <paths>` lines, which
#    the public-export Step 2 anchor reset placeholders). Export-tree / `both`
#    mode ONLY — canonical legitimately carries live values there (a real commit
#    SHA), so this must never run under `--completeness`, the same mode trap as
#    Leg S vs Leg E. Rows intersect with manifest_seed_paths() so a row goes
#    dormant if its file ever leaves the seed-only class. See anchor_violations().
#
# Run against the EXPORT TREE (post-reset). Run against canonical the header-only leg
# will — correctly — FAIL (canonical is intentionally filled); the completeness leg
# passes there and is what CI asserts (via --completeness) as a live-repo invariant.
#
# Usage: export-seed-check.sh [--completeness] [<export-tree-root>]
#   (default root: this repo's root; default mode: both legs)

MODE=both
ROOT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --completeness) MODE=completeness; shift;;
    --*) echo "usage: export-seed-check.sh [--completeness] [<export-tree-root>]" >&2; exit 2;;
    *) ROOT_ARG="$1"; shift;;
  esac
done
ROOT="${ROOT_ARG:-$(cd "$(dirname "$0")/.." && pwd)}"
ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || { echo "FAIL - export-seed-check: not a directory: ${ROOT_ARG:-}" >&2; exit 2; }

# Files whose below-delimiter section must be header-only in a public export.
SEED_FILES=(minions/smes/README.md minions/review-matrix.md minions/capabilities.md)

# Delimited, exportable files whose below-delimiter section is downstream-reserved
# scaffolding — EMPTY in canonical, not maintainer content — so they need no manual
# Step-2 reset (unlike SEED_FILES). Listing them is a positive "considered, needs no
# reset" assertion; the completeness leg forces every new delimited exportable file
# into SEED_FILES or here, so the reasoning is never skipped. They are STILL verified
# header-only below (same as SEED_FILES): the waiver is from the reset ACTION, not from
# the check — so if private content is ever added below one of these delimiters it is
# caught, not silently published (closes the Export/Privacy SME's emptiness-snapshot gap).
# docs/instruction-size-budgets.md is the same class: its below-delimiter "Local
# Overrides" section is downstream-reserved scaffolding, empty in canonical.
# AI.md ("## Template/Downstream Split") and docs/export-manifest.md ("## Downstream
# Additions") joined this class in v1.46.0 for the same reason: unlike
# minions/capabilities.md's Local Inventory (this repo's own real rows, which MUST be
# reset before export), the canonical repo has no downstream-authored content to
# strip below either delimiter — so they are WAIVER, not SEED_FILES.
WAIVER=(MEMORY.md \
        minions/roles/AM.md minions/roles/CM.md minions/roles/DM.md \
        minions/roles/OM.md minions/roles/PM.md minions/roles/RM.md minions/roles/SM.md \
        docs/instruction-size-budgets.md \
        AI.md docs/export-manifest.md)

# Above-marker fields on a seed-only surface that carry repo-specific content and
# must read back as a literal placeholder in the export tree (A2b). Data, not code:
# add a row when a seed-only surface gains an above-marker field carrying
# repo-specific content. Format: "<path>|<line-prefix ERE anchor>|<required export-tree line>".
# Both rows are docs/MECHANICS.md today; the required values are the exact literal
# strings docs/runbooks/public-export.md Step 2 item 4 writes during the reset, and
# docs/MECHANICS.md:15's own "Maintaining this map" section teaches the `verified @`
# form (`Mapped areas: <paths>` is established by that same reset step, not restated
# from an existing convention).
SEED_ANCHORS=(
  'docs/MECHANICS.md|^verified @|verified @ <sha>'
  'docs/MECHANICS.md|^Mapped areas:|Mapped areas: <paths>'
)

# Emit each offending line below the delimiter as "<lineno>: <line>". POSITIVE
# header-only assertion (not a data-row blocklist): below the delimiter the ONLY
# permitted lines are blank lines, markdown headings, and a table header row
# IMMEDIATELY followed by its `| --- |` separator (plus the separator itself).
# Everything else is a leak — prose, bullets, a data row after the separator, or a
# table row with no separator (a malformed/hand-botched reset). The per-line separator
# lookahead (not a global flag) lets several header-only tables sit under one heading
# without false-flagging, while any filled/prose content fails.
#
# The delimiter match MUST be the same anchored pattern find_delimited() uses
# (`^[[:space:]]*<!--.*DOWNSTREAM CONTENT BELOW.*-->`), not a bare substring
# search. A repo that documents its own markers (this one does, extensively)
# will always have prose mentioning "DOWNSTREAM CONTENT BELOW" outside a real
# delimiter line — docs/export-manifest.md's Manifest table is one such case,
# read entirely below-delimiter by a substring match. A guard pattern for a
# structural marker that cannot distinguish a live marker from prose about the
# marker is a standing defect class, not a one-off: anchor by default, and
# reuse find_marked()/find_delimited() rather than hand-rolling a second match.
seed_violations() { # $1=file
  awk '
    $0 ~ /^[[:space:]]*<!--.*DOWNSTREAM CONTENT BELOW.*-->/ { below=1; next }
    below { n++; L[n]=$0; LN[n]=FNR }
    END {
      for (i=1; i<=n; i++) {
        line=L[i]; sub(/\r$/, "", line)
        if (line ~ /^[[:space:]]*$/)                            continue   # blank
        if (line ~ /^[[:space:]]*#/)                            continue   # heading
        if (line ~ /^[[:space:]]*\|[[:space:]:|-]+\|[[:space:]]*$/) continue   # separator row
        if (line ~ /^[[:space:]]*\|/) {                                    # any other table row
          nxt = ""; if (i < n) { nxt = L[i+1]; sub(/\r$/, "", nxt) }
          if (nxt ~ /^[[:space:]]*\|[[:space:]:|-]+\|[[:space:]]*$/) continue  # header + separator next = OK
          printf "%d: %s\n", LN[i], line; continue             # data / separator-less / trailing row = leak
        }
        printf "%d: %s\n", LN[i], line                         # prose / bullet / anything else = leak
      }
    }
  ' "$1"
}

# export=yes backticked paths from the manifest (cell 2 = path, cell 3 = Initial export).
manifest_yes_paths() { # $1=manifest
  awk -F'|' '
    /^\| `/ {
      e=$3; gsub(/[[:space:]]/, "", e)
      if (e=="yes" && match($2, /`[^`]*`/)) print substr($2, RSTART+1, RLENGTH-2)
    }' "$1"
}

# seed-only backticked paths from the manifest (cell 2 = path, cell 3 = Initial
# export). Deliberately WHOLE-FILE / delimiter-agnostic (same `^\| \`` line anchor
# as manifest_yes_paths — no change needed to already be so): a downstream declares
# its own seed-only rows BELOW its split-merge delimiter, and this must see them
# too, or the portability story this class exists for is silently false. See F-G.
manifest_seed_paths() { # $1=manifest
  awk -F'|' '
    /^\| `/ {
      e=$3; gsub(/[[:space:]]/, "", e)
      if (e=="seedonly" && match($2, /`[^`]*`/)) print substr($2, RSTART+1, RLENGTH-2)
    }' "$1"
}

# covered <relpath>: 0 when the path matches a row in yes_paths[] (exact, directory,
# glob, or directory-glob). Same matcher shape as manifest-completeness.test.sh.
covered() { # $1=relpath (matches global yes_paths[])
  local f="$1" p
  [ "${#yes_paths[@]}" -eq 0 ] && return 1
  for p in "${yes_paths[@]}"; do
    [ "$p" = "$f" ] && return 0
    case "$p" in
      *[*?[]*/) case "$f" in $p*)   return 0;; esac;;   # directory-glob row
      *[*?[]*)  case "$f" in $p)     return 0;; esac;;   # glob row
      */)       case "$f" in "$p"*)  return 0;; esac;;   # directory row
    esac
  done
  return 1
}

is_classified() { # $1=relpath -> 0 if in SEED_FILES or WAIVER
  local f="$1" c
  for c in "${SEED_FILES[@]}" "${WAIVER[@]}"; do [ "$c" = "$f" ] && return 0; done
  return 1
}

# Repo-relative paths of files carrying a STRUCTURAL comment-marker LINE matching
# $1 (a `grep -E` pattern, anchored at line-start via `^[[:space:]]*` by the caller) —
# the shared tree-scan primitive behind BOTH the split-merge delimiter completeness
# check (guarantee 2) and the seed-only marker legs (guarantee 3/4), so the two
# structurally-identical matchers can never de-sync into two hand-copied regexes.
# Gated on MODE, not merely on "is ROOT a git work tree" (Export/Privacy SME
# blocker: `git grep` only sees TRACKED paths. An export tree can have a `.git`
# while the just-copied-in seed-only files are not yet `git add`ed — `rev-parse
# --is-inside-work-tree` still succeeds there, so a tree-presence check alone
# would silently switch to a scan that is blind to exactly the newest, riskiest,
# unreset surface. --completeness runs only against canonical (or a fixture
# standing in for it), where every path IS tracked, so the git-grep speed win is
# safe there. Every other mode (both/default — i.e. a real export tree) always
# uses the filesystem grep -r, tracked or not, `.git` or not — this is the
# retired runbook gate-5 semantics, restored.
find_marked() { # $1=grep -E pattern
  local pattern="$1"
  if [ "$MODE" = completeness ] && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$ROOT" grep -lE "$pattern" -- . 2>/dev/null
  else
    ( cd "$ROOT" && grep -rlE "$pattern" . --exclude-dir=.git 2>/dev/null | sed 's|^\./||' )
  fi
}

# The `<!-- ... -->` split-merge delimiter line (not a prose mention of it) — the
# upgrade playbook, this script, and the test files all quote it mid-line, so the
# `^[[:space:]]*` anchor is load-bearing to exclude those.
find_delimited() {
  find_marked '^[[:space:]]*<!--.*DOWNSTREAM CONTENT BELOW.*-->'
}

# The structural `STUB BOUNDARY` marker line (not a prose mention of it). Anchored
# at COLUMN 0, not merely "line start after optional leading whitespace": all five
# real markers (feedback.md, ROADMAP.md, TODO.md, docs/MECHANICS.md, docs/DESIGN.md)
# sit at column 0, but docs/downstream-upgrade-playbook.md:100 quotes the marker's
# real opening syntax VERBATIM, indented four spaces inside a fenced code block, as
# the copy-paste instruction for a downstream adding its own marker. A
# leading-whitespace-tolerant anchor matches that quoted example too and
# false-positives the (export=yes) playbook as carrying a live marker in every
# export tree — the exact defect this column-0 anchor closes (see fixture F-D2).
# The pair stays self-correcting: Leg S enforces marker PRESENCE with this same
# pattern, so a downstream that indents its own real marker away from column 0
# fails Leg S in canonical and is pushed back to column 0, not into a waiver list.
# Unlike the split-merge delimiter, the real marker line does not close its own
# `-->` on the same line (it is prose spanning several lines), so this pattern
# intentionally does not require a trailing `-->`.
STUB_PATTERN='^<!-- STUB BOUNDARY'

check_completeness() { # -> 0 clean, 1 an unclassified delimited exportable file exists
  local manifest="$ROOT/docs/export-manifest.md" viol=0 rel
  yes_paths=()
  if [ -f "$manifest" ]; then
    while IFS= read -r p; do [ -n "$p" ] && yes_paths+=("$p"); done < <(manifest_yes_paths "$manifest")
  fi
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    # Scope to exportable when a manifest is present; with none (bare fixture tree),
    # treat every delimited file as in-scope (conservative — nothing slips).
    if [ "${#yes_paths[@]}" -gt 0 ] && ! covered "$rel"; then continue; fi
    is_classified "$rel" && continue
    echo "FAIL - export-seed-check: unclassified delimited exportable file (add to SEED_FILES or WAIVER): $rel"; viol=1
  done < <(find_delimited)
  return "$viol"
}

# Leg S (A2, SOURCE invariant) — --completeness mode ONLY. Every manifest
# `seed only` path must carry the structural STUB BOUNDARY marker in the live
# repo. Absent file -> WARN + skip (precedent below, same rule as check_completeness
# has none but matches guarantee-1's WAIVER absence handling); glob/directory row ->
# FAIL with an exact-file message (a seed-only class member must be a single real
# file, never a pattern); no manifest, or a manifest with no seed-only rows -> no-op
# (return 0), matching existing test cases 12/13/14's no-manifest / no-seed-rows
# no-op requirement.
check_leg_s() {
  local manifest="$ROOT/docs/export-manifest.md" viol=0
  local seed_paths=() marked_files=() p rel found m
  [ -f "$manifest" ] || return 0
  while IFS= read -r p; do [ -n "$p" ] && seed_paths+=("$p"); done < <(manifest_seed_paths "$manifest")
  [ "${#seed_paths[@]}" -eq 0 ] && return 0
  while IFS= read -r rel; do [ -n "$rel" ] && marked_files+=("$rel"); done < <(find_marked "$STUB_PATTERN")
  for p in "${seed_paths[@]}"; do
    case "$p" in
      *[*?[]*/) echo "FAIL - export-seed-check: seed-only manifest row must name an exact file, not a glob/directory: $p"; viol=1; continue;;
      *[*?[]*)  echo "FAIL - export-seed-check: seed-only manifest row must name an exact file, not a glob/directory: $p"; viol=1; continue;;
      */)       echo "FAIL - export-seed-check: seed-only manifest row must name an exact file, not a glob/directory: $p"; viol=1; continue;;
    esac
    if [ ! -f "$ROOT/$p" ]; then
      echo "WARN - export-seed-check: seed-only path absent (skipped): $p" >&2
      continue
    fi
    found=0
    if [ "${#marked_files[@]}" -gt 0 ]; then
      for m in "${marked_files[@]}"; do [ "$m" = "$p" ] && { found=1; break; }; done
    fi
    if [ "$found" -eq 0 ]; then
      echo "FAIL - export-seed-check: seed-only path missing STUB BOUNDARY marker: $p (add the marker, per docs/export-manifest.md's seed-only class, or fix the manifest row if it is no longer seed-only)"
      viol=1
    fi
  done
  return "$viol"
}

# Leg E (A2, EXPORT-tree invariant) — both/default mode ONLY. No structural
# STUB BOUNDARY marker may survive anywhere in the tree; a surviving marker means
# the public-export Step 2 reset was skipped for that file. Retires the old runbook
# gate-5 grep (same anchored pattern, now sharing find_marked with Leg S/guarantee 2
# so the two can never de-sync).
check_leg_e() {
  local viol=0 rel
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    echo "FAIL - export-seed-check: STUB BOUNDARY marker survives in export tree (Step 2 reset was skipped): $rel"
    viol=1
  done < <(find_marked "$STUB_PATTERN")
  return "$viol"
}

# A2b — per-file, per-line-shape assertion over SEED_ANCHORS, a SIBLING of
# seed_violations() (a different property — field-value conformance on a named
# path + line prefix — over a different input, so it is NOT routed through
# find_marked). Emits the same "<lineno>: <line>" shape as seed_violations() for
# the caller to prefix uniformly. Rows are intersected with manifest_seed_paths()
# so a row goes dormant the moment its file leaves the seed-only class (A2b.6).
# Called from `both` mode only — see the caller.
anchor_violations() {
  local seed_paths=() sp row path prefix expected file line lineno content found
  while IFS= read -r sp; do [ -n "$sp" ] && seed_paths+=("$sp"); done \
    < <(manifest_seed_paths "$ROOT/docs/export-manifest.md" 2>/dev/null)
  for row in "${SEED_ANCHORS[@]}"; do
    IFS='|' read -r path prefix expected <<< "$row"
    found=0
    if [ "${#seed_paths[@]}" -gt 0 ]; then
      for sp in "${seed_paths[@]}"; do [ "$sp" = "$path" ] && { found=1; break; }; done
    fi
    [ "$found" -eq 1 ] || continue   # dormant: file is no longer classed seed-only
    file="$ROOT/$path"
    if [ ! -f "$file" ]; then
      echo "WARN - export-seed-check: seed anchor path absent (skipped): $path" >&2
      continue
    fi
    line="$(grep -nE "$prefix" "$file" 2>/dev/null | head -1)"
    if [ -z "$line" ]; then
      printf '0: %s (expected a line matching /%s/, found none)\n' "$path" "$prefix"
      continue
    fi
    lineno="${line%%:*}"
    content="${line#*:}"
    # Tolerate leading/trailing whitespace + CR (same tolerance as seed_violations()'s
    # \r-stripping); the token itself is still required literally — no fuzzy match.
    content="$(printf '%s' "$content" | sed 's/\r$//; s/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [ "$content" != "$expected" ]; then
      printf '%s: %s\n' "$lineno" "$content"
    fi
  done
}

fail=0
if [ "$MODE" = both ]; then
  # Header-only check covers SEED_FILES (reset targets) AND WAIVER (must stay empty) —
  # every delimited exportable file must be header-only below the delimiter in a public
  # export; the two lists differ only in whether a manual Step-2 reset was needed.
  for f in "${SEED_FILES[@]}" "${WAIVER[@]}"; do
    path="$ROOT/$f"
    [ -f "$path" ] || { echo "WARN - export-seed-check: seed file absent (skipped): $f" >&2; continue; }
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      echo "FAIL - export-seed-check: non-seed content below delimiter in $f -> $hit"; fail=1
    done < <(seed_violations "$path")
  done

  # Leg E (A2): no seed-only STUB BOUNDARY marker survives in the export tree.
  check_leg_e || fail=1

  # A2b: seed-only above-marker anchor conformance. Export-tree only — canonical
  # legitimately carries a real SHA, so this must never run under --completeness
  # (see check below; fixtures F-P/F-R prove the mode gating).
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    echo "FAIL - export-seed-check: seed anchor violation -> $hit"; fail=1
  done < <(anchor_violations)
fi

check_completeness || fail=1

if [ "$MODE" = completeness ]; then
  # Leg S (A2): every manifest seed-only path must carry its marker in the source.
  check_leg_s || fail=1
fi

if [ "$fail" -eq 0 ]; then
  if [ "$MODE" = completeness ]; then
    echo "ok - export seed classification complete (delimiter completeness + seed-only marker presence)"
  else
    echo "ok - export seed state clean + classification complete + no seed-only markers or anchor drift survive"
  fi
fi
exit "$fail"
