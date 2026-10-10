#!/usr/bin/env bash
set -euo pipefail

# run.sh — keep a dm-agent-team run going across fresh host sessions until it
# reaches a human stop, finishes, or stops making progress. Each session
# resumes the active run (.agent-team/active → runs/<run>/state.md), so context
# never accumulates.
#
# Usage:
#   run.sh [--host opencode|claude|copilot|codex] [--project DIR]
#          [--lead-model MODEL] [--max-sessions N] [-- extra host args]
#
# Examples:
#   run.sh                                  # opencode, current dir
#   run.sh --host claude --lead-model sonnet -- --permission-mode acceptEdits
#   run.sh --host copilot -- --allow-all-tools
#
# Each session's cost and turn count (when the host reports them: Claude Code's
# JSON output) are appended to <run>/costs.tsv for the retro and for comparing
# versions of this skill.
#
# Exit codes: 0 done (or no active run) · 1 usage or no run to drive · 2 awaiting human · 3 no progress · 4 host failed · 5 session cap

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HOST="opencode"
PROJECT="$PWD"
MAX_SESSIONS=40
LEAD_MODEL=""
EXTRA=()

usage() { sed -n '4,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)          HOST="$2"; shift 2 ;;
    --project)       PROJECT="$(cd "$2" && pwd -P)"; shift 2 ;;
    --max-sessions)  MAX_SESSIONS="$2"; shift 2 ;;
    --lead-model)    LEAD_MODEL="$2"; shift 2 ;;
    --help|-h)       usage ;;
    --)              shift; EXTRA=("$@"); break ;;
    *)               echo "Unknown option: $1" >&2; usage ;;
  esac
done

# Every supported host CLI accepts --model.
if [[ -n "$LEAD_MODEL" ]]; then EXTRA=(--model "$LEAD_MODEL" "${EXTRA[@]+"${EXTRA[@]}"}"); fi

# The active run is named in .agent-team/active (runs/<name>/ holds its state).
TEAM="$PROJECT/.agent-team"
if [[ -f "$TEAM/state.md" ]]; then
  echo "$TEAM holds a run in the old single-folder layout. Run /dm-agent-team interactively once to migrate it to runs/." >&2
  exit 1
fi
ACTIVE=""
if [[ -f "$TEAM/active" ]]; then ACTIVE="$(tr -d '[:space:]' < "$TEAM/active")"; fi
if [[ -z "$ACTIVE" || "$ACTIVE" == none ]]; then
  if [[ -d "$TEAM/runs" ]]; then
    echo "No active run on this branch: the last run is finished or abandoned, or a brownfield run is active on an agent-team/* branch. Start or resume it with /dm-agent-team interactively."
    exit 0
  fi
  echo "No run yet in $TEAM. Start one with /dm-agent-team interactively: the brief gate always needs a human." >&2
  exit 1
fi
RUN_DIR="$TEAM/runs/$ACTIVE"
STATE="$RUN_DIR/state.md"
LOGS="$RUN_DIR/logs"

if [[ ! -f "$STATE" ]]; then
  echo "No $STATE. Run /dm-agent-team interactively first: the brief gate always needs a human." >&2
  exit 1
fi
mkdir -p "$LOGS"

field() { grep -m1 "^$1:" "$STATE" | sed "s/^$1:[[:space:]]*//" || true; }
# Progress = any change to state.md.
state_hash() { cksum < "$STATE"; }

PROMPT="Read $SKILL_DIR/SKILL.md and act as the dm-agent-team Lead it defines. driver: true. \
Project root: $PROJECT. Resume the active run named in .agent-team/active, at the next-action in its state.md. \
Do not ask the human anything in this session: at a stop, set status: awaiting-human, \
write next-action, and end. End the session after finishing the current stage or milestone."

run_host() {
  case "$HOST" in
    opencode) (cd "$PROJECT" && opencode run "${EXTRA[@]+"${EXTRA[@]}"}" "$PROMPT") ;;
    # The prompt goes first: options such as --allowedTools take a variable
    # number of values and would swallow a prompt placed after them.
    claude)   (cd "$PROJECT" && claude -p "$PROMPT" --output-format json "${EXTRA[@]+"${EXTRA[@]}"}") ;;
    copilot)  (cd "$PROJECT" && copilot -p "$PROMPT" "${EXTRA[@]+"${EXTRA[@]}"}") ;;
    codex)    (cd "$PROJECT" && codex exec "${EXTRA[@]+"${EXTRA[@]}"}" "$PROMPT") ;;
    *) echo "Unsupported host: $HOST" >&2; exit 1 ;;
  esac
}

if [[ "$(field mode)" == "stepwise" ]]; then
  echo "Note: mode is stepwise, so the run stops at every gate. Switch to checkpoint or yolo at a stop for longer unattended runs."
fi

COSTS="$RUN_DIR/costs.tsv"
[[ -f "$COSTS" ]] || printf 'when\tsession\tstage\tcost_usd\tturns\tduration_ms\tlog\n' > "$COSTS"
# Claude Code's --output-format json ends with one JSON object holding
# total_cost_usd, num_turns, and duration_ms. Other hosts report nothing: blank cells.
record_cost() {
  local cost turns dur
  cost="$(grep -o '"total_cost_usd":[0-9.]*' "$2" | tail -1 | cut -d: -f2 || true)"
  turns="$(grep -o '"num_turns":[0-9]*' "$2" | tail -1 | cut -d: -f2 || true)"
  dur="$(grep -o '"duration_ms":[0-9]*' "$2" | tail -1 | cut -d: -f2 || true)"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$1" "$stage" "$cost" "$turns" "$dur" "${2##*/}" >> "$COSTS"
  [[ -z "$cost" ]] || echo "  cost: \$$cost · turns: $turns"
}

stalls=0
failures=0
for ((i = 1; i <= MAX_SESSIONS; i++)); do
  # Runs started before stages were renamed still have a phase: field.
  stage="$(field stage)"; [[ -n "$stage" ]] || stage="$(field phase)"; st="$(field status)"
  if [[ "$stage" == "done" ]]; then
    echo "DONE — see $RUN_DIR/retro.md"; exit 0
  fi
  if [[ "$st" == "awaiting-human" || "$st" == "blocked" ]]; then
    echo "STOP ($st) at $stage — $(field next-action)"
    if [[ "$st" == "blocked" ]]; then echo "  halt: $(field halt)"; fi
    echo "Answer it in an interactive /dm-agent-team session, then rerun this script."
    exit 2
  fi

  before="$(state_hash)"
  log="$LOGS/driver-$(date +%Y%m%d-%H%M%S)-s$i.log"
  echo "[session $i/$MAX_SESSIONS] $stage — $(field next-action)"
  if run_host > "$log" 2>&1; then
    failures=0
  else
    failures=$((failures + 1))
    echo "  host exited non-zero (see $log)"
    if (( failures >= 2 )); then echo "Host failed twice in a row." >&2; exit 4; fi
  fi
  record_cost "$i" "$log"
  tail -n 3 "$log" | cut -c1-200 | sed 's/^/  │ /'

  if [[ "$(state_hash)" == "$before" ]]; then
    stalls=$((stalls + 1))
    if (( stalls >= 2 )); then
      echo "No progress in 2 sessions; state.md did not change. Inspect $log." >&2
      exit 3
    fi
  else
    stalls=0
  fi
done

echo "Reached --max-sessions $MAX_SESSIONS. Rerun to continue."
exit 5
