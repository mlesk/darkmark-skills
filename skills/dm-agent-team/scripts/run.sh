#!/usr/bin/env bash
set -euo pipefail

# run.sh — keep a dm-agent-team run going across fresh host sessions until it
# reaches a human stop, finishes, or stops making progress. Each session
# resumes from .agent-team/state.md, so context never accumulates.
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
# Exit codes: 0 done · 1 usage · 2 awaiting human · 3 no progress · 4 host failed · 5 session cap

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HOST="opencode"
PROJECT="$PWD"
MAX_SESSIONS=40
LEAD_MODEL=""
EXTRA=()

usage() { sed -n '4,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1; }

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

STATE="$PROJECT/.agent-team/state.md"
LOGS="$PROJECT/.agent-team/logs"

if [[ ! -f "$STATE" ]]; then
  echo "No $STATE. Run /dm-agent-team interactively first: kickoff and G0 always need a human." >&2
  exit 1
fi
mkdir -p "$LOGS"

field() { grep -m1 "^$1:" "$STATE" | sed "s/^$1:[[:space:]]*//" || true; }
# Progress = any change to state.md other than the per-session dispatch counter,
# which every session rewrites even when nothing else moves.
state_hash() { grep -v '^session-dispatches:' "$STATE" | cksum; }

PROMPT="Read $SKILL_DIR/SKILL.md and act as the dm-agent-team Lead it defines. driver: true. \
Project root: $PROJECT. Resume from .agent-team/state.md at next-action. \
Do not ask the human anything in this session: at a stop, set status: awaiting-human, \
write next-action, and end. End the session after finishing the current stage or milestone."

run_host() {
  case "$HOST" in
    opencode) (cd "$PROJECT" && opencode run "${EXTRA[@]+"${EXTRA[@]}"}" "$PROMPT") ;;
    # The prompt goes first: options such as --allowedTools take a variable
    # number of values and would swallow a prompt placed after them.
    claude)   (cd "$PROJECT" && claude -p "$PROMPT" "${EXTRA[@]+"${EXTRA[@]}"}") ;;
    copilot)  (cd "$PROJECT" && copilot -p "$PROMPT" "${EXTRA[@]+"${EXTRA[@]}"}") ;;
    codex)    (cd "$PROJECT" && codex exec "${EXTRA[@]+"${EXTRA[@]}"}" "$PROMPT") ;;
    *) echo "Unsupported host: $HOST" >&2; exit 1 ;;
  esac
}

if [[ "$(field mode)" == "stepwise" ]]; then
  echo "Note: mode is stepwise, so the run stops at every gate. Switch to checkpoint or yolo at a stop for longer unattended runs."
fi

stalls=0
failures=0
for ((i = 1; i <= MAX_SESSIONS; i++)); do
  stage="$(field stage)"; st="$(field status)"
  if [[ "$stage" == "done" ]]; then
    echo "DONE — see .agent-team/retro.md"; exit 0
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
  tail -n 3 "$log" | sed 's/^/  │ /'

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
