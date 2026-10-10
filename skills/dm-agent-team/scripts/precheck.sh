#!/usr/bin/env bash
set -uo pipefail

# precheck.sh — the mechanical precheck for one build phase, run by the Lead
# instead of dispatching a reviewer. It makes no judgment calls: it runs
# verify and checks scope, test names, markers, quality configs, and
# dependencies against the specs, then writes the precheck review file.
#
# Usage:
#   precheck.sh --workspace DIR --workdir DIR --phase PHASE-### --round N --base SHA
#               [--touches "path ..."] [--ids "REQ-001.1 DATA-003 ..."]
#               [--brownfield --baseline SHA [--behaviour-changes "D-012 ..."] [--deletes "path ..."]]
#
# --touches and --ids override what is read from the build plan (03 §13, or an
# older run's 04-build-plan.md). Use them for
# fix phases (PHASE-F##), which live only in state.md and their handoff.
#
# --brownfield adds check 6: a test that existed at --baseline may be edited or
# deleted only if the phase lists it in touches: and declares behaviour-changes:;
# any other baseline file may be deleted only if listed under deletes:; and every
# cited D-### must exist in decisions.md. Tests are the files matching 03 §10
# 'test files:' globs (a filename heuristic only when that line is missing).
#
# Exit codes: 0 PASS · 1 REVISE · 2 could not run (bad arguments, or a spec the
# script cannot parse). On 2, the Lead dispatches dm-at-reviewer in precheck mode.

WORKSPACE="" WORKDIR="" PHASE="" ROUND="" BASE="" TOUCHES_OVERRIDE="" IDS_OVERRIDE=""
BROWNFIELD=false BASELINE="" BEHAV_OVERRIDE="" DELETES_OVERRIDE=""
usage() { sed -n '4,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 2; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --workdir)   WORKDIR="$2"; shift 2 ;;
    --phase)     PHASE="$2"; shift 2 ;;
    --round)     ROUND="$2"; shift 2 ;;
    --base)      BASE="$2"; shift 2 ;;
    --touches)   TOUCHES_OVERRIDE="$2"; shift 2 ;;
    --ids)       IDS_OVERRIDE="$2"; shift 2 ;;
    --brownfield) BROWNFIELD=true; shift ;;
    --baseline)  BASELINE="$2"; shift 2 ;;
    --behaviour-changes) BEHAV_OVERRIDE="$2"; shift 2 ;;
    --deletes)   DELETES_OVERRIDE="$2"; shift 2 ;;
    -h|--help)   usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done
[[ -n "$WORKSPACE" && -n "$WORKDIR" && -n "$PHASE" && -n "$ROUND" && -n "$BASE" ]] || usage
if $BROWNFIELD && [[ -z "$BASELINE" ]]; then echo "precheck: --brownfield needs --baseline SHA" >&2; usage; fi
ARCH="$WORKSPACE/specs/03-architecture.md"
# The build plan is 03 §13; runs from older versions keep a separate 04.
PLAN="$WORKSPACE/specs/04-build-plan.md"; [[ -f "$PLAN" ]] || PLAN="$ARCH"
REVIEW="$WORKSPACE/reviews/$PHASE-r$ROUND-precheck.md"
LOG="$WORKSPACE/logs/$PHASE-r$ROUND-precheck.log"
fail() { echo "precheck: $*" >&2; exit 2; }
[[ -f "$ARCH" && -d "$WORKDIR" ]] || fail "missing $ARCH or $WORKDIR"
mkdir -p "$WORKSPACE/reviews" "$WORKSPACE/logs"

strip() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^`//' -e 's/`$//'; }

# ---- Read the specs -----------------------------------------------------------
VERIFY="$(grep -m1 '^verify:' "$PLAN" | sed 's/^verify:[[:space:]]*//' | strip)"
[[ -n "$VERIFY" ]] || fail "no 'verify:' line in the build plan ($PLAN)"

phase_block() {   # lines of this phase's entry in 04
  awk -v id="$PHASE" '
    $0 ~ "^### " id "( |$)" { on=1; next }
    on && /^##/ { exit }
    on { print }' "$PLAN"
}
BLOCK="$(phase_block)"
field() { printf '%s\n' "$BLOCK" | grep -m1 "^$1:" | sed "s/^$1:[[:space:]]*//"; }

if [[ -n "$TOUCHES_OVERRIDE" ]]; then TOUCHES="$TOUCHES_OVERRIDE"
else
  [[ -n "$BLOCK" ]] || fail "$PHASE not found in $PLAN (pass --touches and --ids for a fix phase)"
  TOUCHES="$(field touches | tr ',' ' ' | tr -d '`')"
fi
[[ -n "${TOUCHES// /}" ]] || fail "$PHASE has no touches:"

if [[ -n "$IDS_OVERRIDE" ]]; then IDS="$IDS_OVERRIDE"
else IDS="$(field 'acceptance tests' | grep -oE '(REQ-[0-9]+\.[0-9]+|DATA-[0-9]+|API-[0-9]+|SCR-[0-9]+)' | sort -u | tr '\n' ' ')"
fi

section() {   # body of a "## N." or "### N.N" section of 03, up to the next heading
  awk -v h="$1" '
    index($0, h) == 1 { on=1; next }
    on && /^##/ { exit }
    on { print }' "$ARCH"
}
table_col() {   # print column $1 of the data rows of a markdown table on stdin
  awk -F'|' -v c="$1" '/^\|/ && !/^\|[-: |]+\|?$/ { n++; if (n > 1) print $(c+1) }' | strip
}
ALLOWLIST="$(section '## 11.' | table_col 1 | tr -d '`' | grep -v '^$' || true)"
DEPS_CMD="$(section '## 11.' | grep -m1 -i '^list command:' | sed 's/^[Ll]ist command:[[:space:]]*//' | strip)"
QUALITY_CONFIGS="$(section '### 10.1' | table_col 4 | tr ',' '\n' | strip | grep -vE '^(–|-|n/a|none)?$' || true)"
TEST_GLOBS="$(section '## 10.' | grep -m1 -i '^test files:' | sed 's/^[^:]*:[[:space:]]*//' | tr ',' ' ' | tr -d '`')"
SUPPRESS_OK="$(section '## 9.' | grep -m1 -i '^suppression exceptions:' | sed 's/^[^:]*:[[:space:]]*//' | tr -d '`')"

# ---- Helpers ------------------------------------------------------------------
in_touches() {   # is $1 inside one of the touches entries (exact, folder, or glob)?
  local f="$1" t
  for t in $TOUCHES; do
    t="${t%/}"
    # shellcheck disable=SC2053
    [[ "$f" == $t || "$f" == "$t"/* ]] && return 0
  done
  return 1
}
is_test() {
  local f="$1" b g
  if [[ -n "${TEST_GLOBS// /}" ]]; then   # the project's own definition, from 03 §10
    for g in $TEST_GLOBS; do
      # shellcheck disable=SC2053
      [[ "$f" == $g || "$f" == ${g#\*\*/} ]] && return 0
    done
    return 1
  fi
  b="$(basename "$f")"
  [[ "/$f" == */test/* || "/$f" == */tests/* || "/$f" == */__tests__/* || "/$f" == */spec/* ]] && return 0
  [[ "$b" == test_* || "$b" == *_test.* || "$b" == *.test.* || "$b" == *.spec.* || "$b" == *_spec.* || "$b" == *Test.* || "$b" == *Tests.* ]]
}
suppression_allowed() {
  local f="$1" g
  for g in $SUPPRESS_OK; do
    # shellcheck disable=SC2053
    [[ "$f" == $g ]] && return 0
  done
  return 1
}

ROWS=() FINDINGS=()
add_row()     { ROWS+=("| $1 | $2 | $3 | $4 |"); }
add_finding() { FINDINGS+=("| $(( ${#FINDINGS[@]} + 1 )) | major | $1 | $2 | $3 | precheck $4 |"); }

cd "$WORKDIR" || fail "cannot enter $WORKDIR"
git rev-parse --verify -q "$BASE^{commit}" >/dev/null || fail "base $BASE is not a commit in $WORKDIR"

# Mark new files intent-to-add first, so verify's changed-file ratchets
# (git diff <baseline>) see them, and so does the scope check below. Reports go
# to the live workspace, not the worktree: any change to the worktree's
# .agent-team/ snapshot is out of scope.
git add --all --intent-to-add >/dev/null 2>&1

# 1. Verify ---------------------------------------------------------------------
bash -c "$VERIFY" > "$LOG" 2>&1; VEXIT=$?
VSUM="$(tail -n 3 "$LOG" | tr '\n' ' ' | cut -c1-200)"
if [[ $VEXIT -eq 0 ]]; then add_row 1 "verify" PASS "\`$VERIFY\` · exit 0 · $LOG"
else add_row 1 "verify" FAIL "\`$VERIFY\` · exit $VEXIT · $LOG"
     add_finding "$LOG" "verify exited $VEXIT: $VSUM" "make verify pass" 1; fi

CHANGED="$(git status --porcelain --untracked-files=all | sed -E 's/^.{3}//; s/^.* -> //' | sort -u)"

# 2. Scope ----------------------------------------------------------------------
OUT=""
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  in_touches "$f" || is_test "$f" || case " ${DELETES_OVERRIDE} $(field deletes | tr ',' '\n' | sed 's/(.*//' | strip | tr '\n' ' ') " in *" $f "*) ;; *) OUT+="$f " ;; esac
done <<< "$CHANGED"
if [[ -z "$OUT" ]]; then add_row 2 "scope: changes inside touches: or tests" PASS "$(printf '%s\n' "$CHANGED" | grep -c . ) files checked"
else add_row 2 "scope: changes inside touches: or tests" FAIL "outside: $OUT"
     add_finding "$OUT" "changed outside the phase's touches:" "revert, or raise a CR if the plan is wrong" 2; fi

# 3. A test per acceptance-tests item ---------------------------------------------
MISSING=""
TEST_FILES="$(git ls-files --cached --others --exclude-standard | while IFS= read -r f; do is_test "$f" && printf '%s\n' "$f"; done)"
for id in $IDS; do
  code="$(printf '%s' "$id" | tr '.-' '__')"
  if [[ -z "$TEST_FILES" ]] || ! printf '%s\n' "$TEST_FILES" | tr '\n' '\0' | xargs -0 grep -l -- "$code" >/dev/null 2>&1; then
    MISSING+="$id "
  fi
done
if [[ -z "$IDS" ]]; then add_row 3 "a test per acceptance-tests item" n/a "no IDs listed (foundation phase?)"
elif [[ -z "$MISSING" ]]; then add_row 3 "a test per acceptance-tests item" PASS "found: $IDS"
else add_row 3 "a test per acceptance-tests item" FAIL "no test name contains: $MISSING"
     add_finding "test files" "no test named for $MISSING" "add a test named with the ID in code form (REQ-004.2 → REQ_004_2)" 3; fi

# 4. Markers, suppressions, quality configs -------------------------------------
ADDED="$(git diff "$BASE" -U0 --no-color | awk '/^\+\+\+ b\//{f=substr($0,7)} /^\+[^+]/{print f": "substr($0,2)}')"
B='(^|[^A-Za-z0-9_])'   # portable word start (BSD grep has no reliable \b)
SKIP_RE="\\.skip\\(|\\.only\\(|${B}xit\\(|${B}xdescribe\\(|${B}fit\\(|${B}fdescribe\\(|@pytest\\.mark\\.skip|@unittest\\.skip|\\[Ignore\\]|@Disabled|t\\.Skip\\(|#\\[ignore\\]|${B}(TODO|FIXME)([^A-Za-z0-9_]|\$)"
SUPP_RE='eslint-disable|# *noqa|type: *ignore|@ts-ignore|@ts-nocheck|pragma warning disable|@SuppressWarnings|#\[allow\(|nolint|rubocop:disable|pylint: *disable'
MARKS="$(printf '%s\n' "$ADDED" | grep -E "$SKIP_RE" | head -5 || true)"
SUPPS="$(printf '%s\n' "$ADDED" | grep -E "$SUPP_RE" | while IFS= read -r l; do suppression_allowed "${l%%:*}" || printf '%s\n' "$l"; done | head -5 || true)"
CFG=""
for c in $QUALITY_CONFIGS; do
  printf '%s\n' "$CHANGED" | grep -qxF "$c" && ! in_touches "$c" && CFG+="$c "
done
if [[ -z "$MARKS$SUPPS$CFG" ]]; then add_row 4 "no skip/focus markers, TODO/FIXME, suppressions, or quality-config edits" PASS "diff against $BASE"
else
  add_row 4 "no skip/focus markers, TODO/FIXME, suppressions, or quality-config edits" FAIL "see findings"
  [[ -n "$MARKS" ]] && add_finding "$(printf '%s\n' "$MARKS" | cut -d: -f1 | sort -u | tr '\n' ' ')" "skip/focus marker or TODO: $(printf '%s\n' "$MARKS" | cut -c1-80 | tr '\n' ';' | tr '|' '/')" "remove them; never skip tests or leave stubs" 4
  [[ -n "$SUPPS" ]] && add_finding "$(printf '%s\n' "$SUPPS" | cut -d: -f1 | sort -u | tr '\n' ' ')" "suppression comment: $(printf '%s\n' "$SUPPS" | cut -c1-80 | tr '\n' ';' | tr '|' '/')" "fix the finding at its cause, or add the file to 03 §9 suppression exceptions via a CR" 4
  [[ -n "$CFG" ]] && add_finding "$CFG" "quality config changed outside touches:" "revert; quality rules change only through the plan" 4
fi

# 5. Dependencies ---------------------------------------------------------------
if [[ -z "$DEPS_CMD" ]]; then
  add_row 5 "dependencies on the allowlist" n/a "03 §11 has no 'list command:'; check by hand at review"
else
  DEPS="$(bash -c "$DEPS_CMD" 2>>"$LOG" | strip | grep -v '^$' || true)"
  EXTRA=""
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    printf '%s\n' "$ALLOWLIST" | grep -qixF "$d" || EXTRA+="$d "
  done <<< "$DEPS"
  if [[ -z "$EXTRA" ]]; then add_row 5 "dependencies on the allowlist" PASS "\`$DEPS_CMD\` · $(printf '%s\n' "$DEPS" | grep -c .) deps"
  else add_row 5 "dependencies on the allowlist" FAIL "not allowlisted: $EXTRA"
       add_finding "dependency manifest" "not on the 03 §11 allowlist: $EXTRA" "remove it, or raise a dependency CR (hard stop)" 5; fi
fi

# 6. Brownfield: baseline tests and files change only under declared decisions --
if $BROWNFIELD; then
  git rev-parse --verify -q "$BASELINE^{commit}" >/dev/null || fail "baseline $BASELINE is not a commit in $WORKDIR"
  if [[ -n "$BEHAV_OVERRIDE" ]]; then BEHAV="$BEHAV_OVERRIDE"; else BEHAV="$(field behaviour-changes | grep -oE 'D-[0-9]+' | tr '\n' ' ')"; fi
  DEL_LINE="$DELETES_OVERRIDE"; [[ -n "$DEL_LINE" ]] || DEL_LINE="$(field deletes)"
  DELETES="$(printf '%s' "$DEL_LINE" | tr ',' '\n' | sed 's/(.*//' | strip | tr '\n' ' ')"
  DEL_DS="$(printf '%s' "$DEL_LINE" | grep -oE 'D-[0-9]+' | tr '\n' ' ')"
  BAD_TESTS="" BAD_DELETES="" UNKNOWN_DS=""
  # NUL-separated and unquoted, so unusual paths can't slip past.
  while IFS= read -r -d '' st; do
    if [[ "$st" == R* || "$st" == C* ]]; then IFS= read -r -d '' f; IFS= read -r -d '' _new; else IFS= read -r -d '' f; fi
    git cat-file -e "$BASELINE:$f" 2>/dev/null || continue          # not a baseline file
    if is_test "$f"; then
      if [[ -z "${BEHAV// /}" ]] || ! in_touches "$f"; then BAD_TESTS+="$f "; fi
    elif [[ "$st" == D* ]]; then
      case " $DELETES " in *" $f "*) [[ -n "${DEL_DS// /}" ]] || BAD_DELETES+="$f " ;; *) BAD_DELETES+="$f " ;; esac
    fi
  done < <(git -c core.quotePath=false diff -z --name-status -M "$BASE")
  for d in $BEHAV $DEL_DS; do
    grep -qE "^## $d( |$)" "$WORKSPACE/decisions.md" 2>/dev/null || UNKNOWN_DS+="$d "
  done
  if [[ -z "$BAD_TESTS$BAD_DELETES$UNKNOWN_DS" ]]; then
    add_row 6 "baseline tests and files change only under declared decisions" PASS "baseline $BASELINE · behaviour-changes: ${BEHAV:-none} · deletes: ${DELETES:-none}"
  else
    add_row 6 "baseline tests and files change only under declared decisions" FAIL "see findings"
    [[ -n "$BAD_TESTS" ]] && add_finding "$BAD_TESTS" "a test that existed at baseline was edited or deleted without a declared behaviour change" "restore it and fix the regression, or get a D-### accepting the change and add behaviour-changes: (and the file to touches:) via the plan" 6
    [[ -n "$BAD_DELETES" ]] && add_finding "$BAD_DELETES" "a baseline file was deleted without being listed under deletes: with a D-###" "restore it, or get a human D-### and list it under deletes: via the plan" 6
    [[ -n "$UNKNOWN_DS" ]] && add_finding "decisions.md" "cited decisions not found: $UNKNOWN_DS" "cite a D-### that exists in decisions.md" 6
  fi
fi

# ---- Write the review file ------------------------------------------------------
VERDICT=PASS; [[ ${#FINDINGS[@]} -gt 0 ]] && VERDICT=REVISE
{
  echo "# Review: $PHASE — precheck — round $ROUND"
  echo "verdict: $VERDICT"
  echo "checked-against: ${PLAN##*/}#$PHASE, specs/03-architecture.md §9 §10.1 §11"
  echo "by: scripts/precheck.sh (mechanical; no judgment calls)"
  echo "## Evidence"
  echo "| Command | Exit | Summary |"
  echo "|---|---|---|"
  echo "| \`$VERIFY\` | $VEXIT | $(printf '%s' "$VSUM" | tr '|' '/') |"
  echo "## Findings"
  echo "| # | Severity | Location | Finding | Required fix | Rule/ID |"
  echo "|---|---|---|---|---|---|"
  for f in ${FINDINGS[@]+"${FINDINGS[@]}"}; do echo "$f"; done
  echo "## Checklist"
  echo "| # | Check | Result | Evidence |"
  echo "|---|---|---|---|"
  for r in ${ROWS[@]+"${ROWS[@]}"}; do echo "$r"; done
} > "$REVIEW"

echo "precheck $PHASE r$ROUND: $VERDICT — $REVIEW"
[[ $VERDICT == PASS ]] && exit 0 || exit 1
