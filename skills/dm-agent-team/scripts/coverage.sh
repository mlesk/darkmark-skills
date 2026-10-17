#!/usr/bin/env bash
set -uo pipefail

# coverage.sh — the mechanical Must-coverage check, run by the Lead at each
# milestone end and before acceptance (the acceptance reviewer reads its file
# instead of building the table by hand). No judgment calls.
#
# For every Must criterion in 01 (REQ-###.n under a "— Must" heading) and every
# contract in 03 §5 (API-###), it reports the owning phase from 03 §13
# (acceptance tests:) and whether a test file names the ID in code form
# (REQ-004.2 → REQ_004_2). A Must criterion owned by no phase, or owned by a
# done phase and named by no test, is a FAIL.
#
# Usage:
#   coverage.sh --workspace DIR --workdir DIR [--label MS-1] [--phases "PHASE-001 PHASE-002" | --all]
#
# Without --phases or --all, the done phases are read from state.md's Build
# table. Writes <workspace>/reviews/coverage-<label>.md. Exit 0 PASS · 1 FAIL ·
# 2 could not run.

WORKSPACE="" WORKDIR="" LABEL="" PHASES="" ALL=false
usage() { sed -n '4,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 2; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --workdir)   WORKDIR="$2"; shift 2 ;;
    --label)     LABEL="$2"; shift 2 ;;
    --phases)    PHASES="$2"; shift 2 ;;
    --all)       ALL=true; shift ;;
    -h|--help)   usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done
[[ -n "$WORKSPACE" && -n "$WORKDIR" ]] || usage
fail() { echo "coverage: $*" >&2; exit 2; }
REQS="$WORKSPACE/specs/01-requirements.md"
ARCH="$WORKSPACE/specs/03-architecture.md"
PLAN="$WORKSPACE/specs/04-build-plan.md"; [[ -f "$PLAN" ]] || PLAN="$ARCH"
[[ -f "$REQS" && -f "$ARCH" && -d "$WORKDIR" ]] || fail "missing $REQS, $ARCH, or $WORKDIR"
[[ -n "$LABEL" ]] || LABEL="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$WORKSPACE/reviews"
OUT="$WORKSPACE/reviews/coverage-$LABEL.md"
strip() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# ---- Done phases ---------------------------------------------------------------
if $ALL; then
  DONE="$(grep -oE '^### PHASE-[0-9F]+' "$PLAN" | sed 's/^### //' | tr '\n' ' ')"
elif [[ -n "$PHASES" ]]; then
  DONE="$PHASES"
else
  [[ -f "$WORKSPACE/state.md" ]] || fail "no state.md; pass --phases or --all"
  DONE="$(awk -F'|' '/^## Build/{on=1} /^## Log/{on=0} on && /^\| PHASE-/ { gsub(/^[ \t]+|[ \t]+$/, "", $4); if ($4=="done") { split($2, a, " "); print a[1] } }' "$WORKSPACE/state.md" | tr '\n' ' ')"
fi
is_done() { case " $DONE " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# ---- Must criteria from 01, contracts from 03 §5 ----------------------------------
MUST="$(awk '
  /^### REQ-[0-9]+/ { must = ($0 ~ /Must/) ; next }
  /^### / { must = 0 }
  must && /^- REQ-[0-9]+\.[0-9]+/ { sub(/^- /, ""); print $1 }' "$REQS" | sort -u)"
APIS="$(awk 'index($0,"## 5.")==1{on=1; next} on && /^## /{exit} on' "$ARCH" | grep -oE 'API-[0-9]+' | sort -u)"

# ---- Owners from 03 §13 ---------------------------------------------------------
OWNERS="$(awk '
  /^### PHASE-[0-9F]+/ { ph=$2; next }
  /^## / { ph="" }
  ph && /^acceptance tests:/ { n = split($0, w, /[^A-Za-z0-9.\-]+/); for (i=1;i<=n;i++) if (w[i] ~ /^(REQ-[0-9]+\.[0-9]+|API-[0-9]+)$/) print w[i] " " ph }' "$PLAN" | sort -u)"
owner_of() { printf '%s\n' "$OWNERS" | awk -v id="$1" '$1==id {print $2}' | tr '\n' ' ' | strip; }

# ---- Test files -----------------------------------------------------------------
TEST_GLOBS="$(awk 'index($0,"## 10.")==1{on=1; next} on && /^## /{exit} on' "$ARCH" | grep -m1 -i '^test files:' | sed 's/^[^:]*:[[:space:]]*//' | tr ',' ' ' | tr -d '`')"
is_test() {
  local f="$1" b g
  if [[ -n "${TEST_GLOBS// /}" ]]; then
    for g in $TEST_GLOBS; do
      # shellcheck disable=SC2053
      [[ "$f" == $g || "$f" == ${g#\*\*/} ]] && return 0
    done
    return 1
  fi
  b="$(basename "$f")"
  [[ "/$f" == */test/* || "/$f" == */tests/* || "/$f" == */__tests__/* || "/$f" == */spec/* || "/$f" == */e2e/* ]] && return 0
  [[ "$b" == test_* || "$b" == *_test.* || "$b" == *.test.* || "$b" == *.spec.* || "$b" == *_spec.* || "$b" == *Test.* || "$b" == *Tests.* ]]
}
cd "$WORKDIR" || fail "cannot enter $WORKDIR"
TEST_FILES="$(git ls-files --cached --others --exclude-standard -- . ':!.agent-team' | while IFS= read -r f; do is_test "$f" && printf '%s\n' "$f"; done)"
test_for() {   # first test file naming the ID in code form
  local code; code="$(printf '%s' "$1" | tr '.-' '__')"
  [[ -n "$TEST_FILES" ]] || return 1
  printf '%s\n' "$TEST_FILES" | tr '\n' '\0' | xargs -0 grep -l -- "$code" 2>/dev/null | head -1 | grep .
}

# ---- Table ------------------------------------------------------------------------
ROWS=() ; FAILS=0 ; PENDING=0 ; OK=0
check() {   # $1 id, $2 kind
  local id="$1" kind="$2" own st tf
  own="$(owner_of "$id")"
  if [[ -z "$own" ]]; then
    if [[ "$kind" == Must ]]; then st="FAIL: no owning phase"; FAILS=$((FAILS+1)); else st="unowned"; fi
    ROWS+=("| $id | $kind | – | $st | |"); return
  fi
  local done_owner=false p
  for p in $own; do is_done "$p" && done_owner=true; done
  tf="$(test_for "$id" || true)"
  if [[ -n "$tf" ]]; then st="covered"; OK=$((OK+1))
  elif $done_owner; then st="FAIL: no test named $(printf '%s' "$id" | tr '.-' '__')"; FAILS=$((FAILS+1))
  else st="pending ($own not done)"; PENDING=$((PENDING+1)); fi
  ROWS+=("| $id | $kind | $own | $st | ${tf:-} |")
}
for id in $MUST; do check "$id" Must; done
for id in $APIS; do check "$id" API; done

VERDICT=PASS; [[ $FAILS -gt 0 ]] && VERDICT=FAIL
{
  echo "# Coverage: $LABEL — Must criteria and contracts"
  echo "verdict: $VERDICT"
  echo "by: scripts/coverage.sh (mechanical; a named test proves presence, not that the test is good)"
  echo "done phases: ${DONE:-none}"
  echo "summary: $OK covered · $PENDING pending · $FAILS failing"
  echo
  echo "| ID | Kind | Owner | Status | Test file |"
  echo "|---|---|---|---|---|"
  for r in ${ROWS[@]+"${ROWS[@]}"}; do echo "$r"; done
} > "$OUT"
echo "coverage $LABEL: $VERDICT — $OK covered, $PENDING pending, $FAILS failing — $OUT"
[[ $VERDICT == PASS ]] && exit 0 || exit 1
