#!/usr/bin/env bash
set -uo pipefail

# sweep.sh — deterministic nightly health check for one project.
#
# Usage:
#   sweep.sh --project DIR [--out DIR] [--dry-run] [--no-tests] [--json]
#
# Writes <out>/YYYY-MM-DD.md and prints one machine line:
#   SWEEP <health> <decisions> <file>
#
# Exit codes: 0 GREEN/AMBER · 2 RED · 3 usage. The digest is always written.

PROJECT="" OUT="" DRY=false RUN_TESTS=true AS_JSON=false TIMEOUT=600
usage() { sed -n '4,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 3; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --out)     OUT="$2"; shift 2 ;;
    --dry-run) DRY=true; shift ;;
    --no-tests) RUN_TESTS=false; shift ;;
    --json)    AS_JSON=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done
[[ -n "$PROJECT" ]] || usage
PROJECT="$(cd "$PROJECT" 2>/dev/null && pwd -P)" || { echo "sweep: no such project: $PROJECT" >&2; exit 3; }

# A launchd job that has not been granted Full Disk Access can block forever on
# an external volume. Probe with a deadline and fail fast with the remedy.
run_limited() {
  local secs="$1"; shift
  if command -v gtimeout >/dev/null 2>&1; then gtimeout "$secs" "$@"; return $?; fi
  if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@"; return $?; fi
  "$@" & local pid=$!
  ( sleep "$secs"; kill -TERM "$pid" 2>/dev/null ) & local watcher=$!
  wait "$pid"; local rc=$?
  kill "$watcher" 2>/dev/null; wait "$watcher" 2>/dev/null
  return "$rc"
}
rel_age_days() { # unix timestamp -> whole days
  local then="${1:-0}" now; now="$(date +%s)"
  echo $(( (now - then) / 86400 ))
}

if ! run_limited 5 git -C "$PROJECT" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "sweep: cannot read $PROJECT within 5s." >&2
  echo "  If this runs from launchd, grant Full Disk Access to /bin/bash:" >&2
  echo "  System Settings > Privacy & Security > Full Disk Access." >&2
  exit 3
fi
OUT="${OUT:-$PROJECT/.agent/inbox}"
mkdir -p "$OUT"
DATE="$(date +%Y-%m-%d)"
STAMP="$(date +%Y-%m-%dT%H:%M:%S)"
FILE="$OUT/$DATE.md"
DECISIONS="$(mktemp)"; DETAILS="$(mktemp)"; ROWS="$(mktemp)"
trap 'rm -f "$DECISIONS" "$DETAILS" "$ROWS"' EXIT
HEALTH=0   # 0 green, 1 amber, 2 red

bump() { [[ "$1" -gt "$HEALTH" ]] && HEALTH="$1"; }
decide() { printf '%s\t%s\n' "$1" "$2" >> "$DECISIONS"; }
row() { printf '| %s | %s | %s |\n' "$1" "$2" "$3" >> "$ROWS"; }
detail() { printf '\n### %s\n%s\n' "$1" "$2" >> "$DETAILS"; }

# ---- git ----------------------------------------------------------------------
BRANCH="$(git -C "$PROJECT" branch --show-current 2>/dev/null || echo detached)"
COMMIT="$(git -C "$PROJECT" log -1 --format='%h %s' 2>/dev/null | cut -c1-80)"
DIRTY="$(git -C "$PROJECT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
LAST_TS="$(git -C "$PROJECT" log -1 --format=%ct 2>/dev/null || echo 0)"
LAST_AGE="$(rel_age_days "$LAST_TS")"
UNPUSHED=0
if git -C "$PROJECT" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
  UNPUSHED="$(git -C "$PROJECT" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)"
fi
STALE_BRANCHES="$(git -C "$PROJECT" for-each-ref --format='%(committerdate:unix) %(refname:short)' refs/heads 2>/dev/null \
  | while read -r ts name; do [[ "$(rel_age_days "$ts")" -gt 30 ]] && echo "$name"; done | wc -l | tr -d ' ')"

row git "$([[ "$DIRTY" -gt 0 ]] && echo AMBER || echo ok)" "branch $BRANCH · dirty $DIRTY · unpushed $UNPUSHED · last commit ${LAST_AGE}d ago"
[[ "$DIRTY" -gt 0 ]] && bump 1 && decide 2 "[git] $DIRTY uncommitted file(s) on $BRANCH"
[[ "$UNPUSHED" -gt 0 ]] && bump 1 && decide 3 "[git] $UNPUSHED unpushed commit(s) on $BRANCH"
[[ "$LAST_AGE" -gt 14 && "$DIRTY" -eq 0 ]] && decide 4 "[stale] no commit in ${LAST_AGE}d"

# ---- tests --------------------------------------------------------------------
if $RUN_TESTS && ! $DRY; then
  TEST_CMD=""
  if [[ -f "$PROJECT/package.json" ]] && grep -q '"test"[[:space:]]*:' "$PROJECT/package.json"; then
    TEST_CMD="npm test --silent"
  elif [[ -f "$PROJECT/pyproject.toml" || -f "$PROJECT/pytest.ini" || -d "$PROJECT/tests" ]]; then
    if [[ -x "$PROJECT/.venv/bin/python" ]]; then TEST_CMD=".venv/bin/python -m pytest -q"
    elif command -v python3 >/dev/null 2>&1; then TEST_CMD="python3 -m pytest -q"; fi
  elif [[ -f "$PROJECT/Cargo.toml" ]]; then TEST_CMD="cargo test -q"
  elif [[ -f "$PROJECT/go.mod" ]]; then TEST_CMD="go test ./..."
  fi
  if [[ -n "$TEST_CMD" ]]; then
    TLOG="$(mktemp)"
    ( cd "$PROJECT" && run_limited "$TIMEOUT" bash -c "$TEST_CMD" ) >"$TLOG" 2>&1
    TRC=$?
    TTAIL="$(tail -n 12 "$TLOG" | sed 's/|/\\|/g')"
    if [[ "$TRC" -eq 0 ]]; then
      row tests ok "\`$TEST_CMD\` exit 0"
      detail "Tests" "\`$TEST_CMD\` exit 0"$'\n\n```\n'"$TTAIL"$'\n```'
    else
      row tests FAIL "\`$TEST_CMD\` exit $TRC"
      bump 2; decide 1 "[tests] \`$TEST_CMD\` failed (exit $TRC)"
      detail "Tests" "\`$TEST_CMD\` exit $TRC"$'\n\n```\n'"$TTAIL"$'\n```'
    fi
    rm -f "$TLOG"
  else
    row tests n/a "no test command detected"
  fi
else
  row tests skipped "$($DRY && echo 'dry run' || echo '--no-tests')"
fi

# ---- todos --------------------------------------------------------------------
TODOS="$(git -C "$PROJECT" grep -nEI 'TODO|FIXME|HACK|XXX' -- . 2>/dev/null | wc -l | tr -d ' ')"
TROW=ok; [[ "$TODOS" -gt 25 ]] && TROW=AMBER && bump 1
row todos "$TROW" "$TODOS tracked TODO/FIXME/HACK"
[[ "$TODOS" -gt 25 ]] && decide 5 "[todos] $TODOS markers; triage into issues or delete"

# ---- docs ---------------------------------------------------------------------
if [[ -f "$PROJECT/README.md" ]]; then
  README_TS="$(git -C "$PROJECT" log -1 --format=%ct -- README.md 2>/dev/null || echo 0)"
  DRIFT=$(( (LAST_TS - README_TS) / 86400 ))
  if [[ "$DRIFT" -gt 30 ]]; then
    row docs AMBER "README ${DRIFT}d behind last commit"
    bump 1; decide 4 "[docs] README is ${DRIFT}d behind the code"
  else
    row docs ok "README within ${DRIFT}d of last commit"
  fi
else
  row docs AMBER "no README.md"
  bump 1
fi

# ---- dependencies -------------------------------------------------------------
if [[ -f "$PROJECT/package-lock.json" ]] && command -v npm >/dev/null 2>&1 && ! $DRY; then
  AJSON="$( cd "$PROJECT" && run_limited 180 npm audit --json 2>/dev/null || true )"
  if [[ -n "$AJSON" ]] && command -v python3 >/dev/null 2>&1; then
    ASUM="$(printf '%s' "$AJSON" | python3 -c '
import json,sys
try: d=json.load(sys.stdin)
except Exception: print("unparsed"); raise SystemExit
m=d.get("metadata",{}).get("vulnerabilities",{})
print(f"{m.get(\"critical\",0)} critical, {m.get(\"high\",0)} high, {m.get(\"moderate\",0)} moderate")
' 2>/dev/null)"
    if printf '%s' "$ASUM" | grep -qE '^[1-9]'; then
      row deps AMBER "npm audit: $ASUM"
      bump 1; decide 2 "[deps] npm audit: $ASUM"
    else
      row deps ok "npm audit: $ASUM"
    fi
    detail "Dependencies" "npm audit: $ASUM"
  fi
else
  row deps n/a "no lockfile or dry run"
fi

# ---- secrets ------------------------------------------------------------------
SECRETS="$(git -C "$PROJECT" grep -nEI 'AKIA[0-9A-Z]{16}|-----BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY-----|ghp_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}' -- . 2>/dev/null | head -5 || true)"
ENV_TRACKED="$(git -C "$PROJECT" ls-files 2>/dev/null | grep -E '(^|/)\.env$' | head -3 || true)"
if [[ -n "$SECRETS$ENV_TRACKED" ]]; then
  row secrets FAIL "possible secret in tracked files"
  bump 2; decide 1 "[secrets] possible credential committed — rotate and remove"
  detail "Secrets" "${SECRETS:-}(tracked .env: ${ENV_TRACKED:-none})"
else
  row secrets ok "no obvious credential patterns"
fi

# ---- large files --------------------------------------------------------------
LARGE=""
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  sz="$(wc -c <"$PROJECT/$f" 2>/dev/null | tr -d ' ')"
  [[ -n "$sz" && "$sz" -gt 2097152 ]] && LARGE+="$f ($((sz/1048576))MB) "
done <<< "$(git -C "$PROJECT" ls-files 2>/dev/null | head -2000)"
if [[ -n "$LARGE" ]]; then
  row size AMBER "tracked files over 2MB: $LARGE"
  bump 1
else
  row size ok "no tracked file over 2MB"
fi

# ---- agent runs ---------------------------------------------------------------
AGENT_ROWS=""
AWAITING=0
for st in "$PROJECT"/.agent-team/runs/*/state.md; do
  [[ -f "$st" ]] || continue
  run="$(basename "$(dirname "$st")")"
  stage="$(grep -m1 '^stage:' "$st" | sed 's/^stage:[[:space:]]*//')"
  status="$(grep -m1 '^status:' "$st" | sed 's/^status:[[:space:]]*//')"
  nxt="$(grep -m1 '^next-action:' "$st" | sed 's/^next-action:[[:space:]]*//' | cut -c1-100)"
  AGENT_ROWS+="| $run | $stage | $status | $nxt |"$'\n'
  if [[ "$status" == "awaiting-human" || "$status" == "blocked" ]]; then
    AWAITING=$((AWAITING + 1)); bump 1
    decide 1 "[agent] $run is $status at $stage — $nxt"
  fi
  if [[ "$status" == "done" && "$BRANCH" == "agent-team/$run" ]]; then
    bump 1
    decide 2 "[branch] run $run is done on $BRANCH — merge it or delete the branch"
  fi
done

# ---- rtk ----------------------------------------------------------------------
if command -v rtk >/dev/null 2>&1; then
  RLINE="$(rtk gain 2>/dev/null | grep -E 'Tokens saved|Efficiency' | tr '\n' ' ' | cut -c1-120)"
  [[ -n "$RLINE" ]] && row rtk ok "$RLINE"
fi

# ---- write --------------------------------------------------------------------
STATUS_LABEL="GREEN"; [[ "$HEALTH" -eq 1 ]] && STATUS_LABEL="AMBER"; [[ "$HEALTH" -eq 2 ]] && STATUS_LABEL="RED"
NDEC="$(wc -l < "$DECISIONS" | tr -d ' ')"
{
  echo "# Sweep: $(basename "$PROJECT") — $DATE"
  echo
  echo "\`$STAMP\` · \`$PROJECT\`"
  echo
  echo "**$STATUS_LABEL** · $NDEC decision(s)"
  echo
  echo "## Needs a decision (max 5)"
  echo
  if [[ "$NDEC" -eq 0 ]]; then
    echo "Nothing. The lane is clean."
  else
    sort -n "$DECISIONS" | cut -f2- | head -5 | nl -w1 -s'. '
  fi
  echo
  echo "## Health"
  echo
  echo "| Check | Result | Detail |"
  echo "|---|---|---|"
  cat "$ROWS"
  if [[ -n "$AGENT_ROWS" ]]; then
    echo
    echo "## Agent runs"
    echo
    echo "| Run | Stage | Status | Next action |"
    echo "|---|---|---|---|"
    printf '%s' "$AGENT_ROWS"
  fi
  echo
  echo "## Details"
  cat "$DETAILS"
  echo
  echo "---"
  echo "_Generated by dm-sweep. Decisions are proposals, not actions._"
} > "$FILE"

if $AS_JSON; then
  printf '{"project":"%s","health":"%s","decisions":%s,"file":"%s"}\n' \
    "$(basename "$PROJECT")" "$STATUS_LABEL" "$NDEC" "$FILE"
else
  printf 'SWEEP\t%s\t%s\t%s\n' "$STATUS_LABEL" "$NDEC" "$FILE"
fi
[[ "$HEALTH" -eq 2 ]] && exit 2
exit 0
