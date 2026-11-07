#!/usr/bin/env bash
set -uo pipefail

# weekly.sh — refresh the portfolio evidence and deterministic backlog.
#
# Usage:
#   weekly.sh [--ops DIR] [--agent] [--host opencode|claude]
#
# Without --agent it runs inventory.py and plan.py only: no model, no cost.
# With --agent it then asks the host to run the dm-portfolio review (adds
# exploratory opportunities, re-scores, rewrites the index).
#
# Exit: 0 prepared · 2 one project missing · 3 usage/lock · 4 agent failed.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SKILL_FILE="$HERE/SKILL.md"
[[ -f "$SKILL_FILE" ]] || SKILL_FILE="$HERE/../SKILL.md"
OPS="${DM_PORTFOLIO_OPS:-}"
AGENT=false
HOST="opencode"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ops) OPS="$2"; shift 2 ;;
    --agent) AGENT=true; shift ;;
    --host) HOST="$2"; shift 2 ;;
    -h|--help) sed -n '4,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 3 ;;
  esac
done
if [[ -z "$OPS" ]]; then
  if [[ -f "$HOME/.config/dm-portfolio/ops" ]]; then
    OPS="$(tr -d '[:space:]' < "$HOME/.config/dm-portfolio/ops")"
  else
    OPS="$HOME/ops"
  fi
fi
[[ -d "$OPS" ]] || { echo "weekly: no ops repo at $OPS" >&2; exit 3; }
OPS="$(cd "$OPS" && pwd -P)"
if ! ( : > "$OPS/.write-test" ) 2>/dev/null; then
  echo "weekly: cannot write $OPS." >&2
  echo "  If this runs from launchd, grant Full Disk Access to /bin/bash:" >&2
  echo "  System Settings > Privacy & Security > Full Disk Access." >&2
  exit 3
fi
rm -f "$OPS/.write-test"
LOCK="$OPS/.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  pid="$(cat "$LOCK/pid" 2>/dev/null || true)"
  if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
    rm -rf "$LOCK"; mkdir "$LOCK" 2>/dev/null || exit 3
  else
    echo "weekly: another run is active (pid ${pid:-unknown})" >&2
    exit 3
  fi
fi
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK" 2>/dev/null || true' EXIT

echo "[1/2] inventory"
python3 "$HERE/inventory.py" --ops "$OPS" || { echo "weekly: inventory failed" >&2; exit 2; }
echo "[2/2] plan"
python3 "$HERE/plan.py" --ops "$OPS" || { echo "weekly: plan failed" >&2; exit 2; }

# A launchd job without Full Disk Access sees the project paths but cannot run
# git in them. Say so instead of producing a silently empty snapshot.
ACCESSIBLE="$(python3 - "$OPS" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1] + "/inventory/latest.json"))
    print(d.get("summary", {}).get("accessible", 0))
except Exception:
    print(0)
PY
)"
if [[ "${ACCESSIBLE:-0}" == "0" ]]; then
  echo "weekly: 0 projects were readable. If this runs from launchd, grant Full Disk Access to /bin/bash." >&2
fi

if $AGENT; then
  PROMPT="Read $SKILL_FILE and run the weekly portfolio review for $OPS. \
Do not start any work. Read inventory/latest.json, goals.md, projects.json, config.json, seeds.json, and backlog/INDEX.md. \
Add 3-5 exploratory opportunities to seeds.json that the deterministic plan cannot see, each grounded in a goal and an existing asset. \
Re-score the open items only where the evidence justifies it, and write one line of why for every changed score. \
Run: python3 $HERE/plan.py --ops $OPS. \
Then write backlog/REVIEW.md with the top five, what changed since last week, and the one human decision that would unlock the most value."
  LOG="$OPS/agent-$(date +%Y%m%d-%H%M%S).log"
  echo "[agent] $HOST -> $LOG"
  case "$HOST" in
    opencode)
      if command -v opencode >/dev/null 2>&1; then
        ( cd "$OPS" && opencode run "$PROMPT" ) >"$LOG" 2>&1 || { echo "weekly: agent failed (see $LOG)" >&2; exit 4; }
      else
        echo "weekly: opencode not found" >&2; exit 4
      fi ;;
    claude)
      if command -v claude >/dev/null 2>&1; then
        ( cd "$OPS" && claude -p "$PROMPT" --model sonnet \
            --allowedTools "Read Write Edit Glob Grep Bash" --output-format json ) >"$LOG" 2>&1 \
          || { echo "weekly: agent failed (see $LOG)" >&2; exit 4; }
      else
        echo "weekly: claude not found" >&2; exit 4
      fi ;;
    *) echo "weekly: unknown host $HOST" >&2; exit 3 ;;
  esac
fi

echo "OPS $OPS"
echo "INDEX $OPS/backlog/INDEX.md"
echo "NEXT $OPS/backlog/NEXT.md"
exit 0
