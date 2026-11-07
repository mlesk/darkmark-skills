#!/usr/bin/env bash
set -uo pipefail

# monitor.sh — a live page for a dm-agent-team run. Every few seconds it reruns
# plan-graph.sh (03 §13 + state.md + builder progress lines → plan.json) and
# writes <workspace>/logs/monitor/plan-data.js beside a copy of plan.html, adding
# the machine's load and the project's git state. It serves that folder on
# 127.0.0.1 with python3's http.server, or prints a file:// URL without python3
# (the page loads its data through a script tag, so both work). Read-only for
# the run: it writes only plan.json and logs/monitor/. Stop it with Ctrl-C.
#
# Usage:
#   monitor.sh --workspace DIR [--port N] [--interval S] [--no-serve] [--open] [--once]
#
# --port defaults to 4317 · --interval to 3 seconds · --once refreshes the data
# once and exits (no server) · --open opens the page in the default browser.
# Exit 0 stopped or --once done · 2 could not run.

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WORKSPACE="" PORT=4317 INTERVAL=3 SERVE=true OPEN=false ONCE=false
usage() { sed -n '4,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 2; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --port)      PORT="$2"; shift 2 ;;
    --interval)  INTERVAL="$2"; shift 2 ;;
    --no-serve)  SERVE=false; shift ;;
    --open)      OPEN=true; shift ;;
    --once)      ONCE=true; SERVE=false; shift ;;
    -h|--help)   usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done
fail() { echo "monitor: $*" >&2; exit 2; }
[[ -n "$WORKSPACE" ]] || usage
[[ -d "$WORKSPACE" ]] || fail "no workspace $WORKSPACE"
WORKSPACE="$(cd "$WORKSPACE" && pwd -P)"
[[ "$PORT" =~ ^[0-9]+$ && "$INTERVAL" =~ ^[0-9]+$ && "$INTERVAL" -ge 1 ]] || fail "--port and --interval take whole numbers (interval ≥ 1)"
VIEW="$WORKSPACE/logs/monitor"
mkdir -p "$VIEW" || fail "cannot create $VIEW"
cp "$SKILL_DIR/scripts/plan.html" "$VIEW/index.html" || fail "cannot copy plan.html"
PROJECT="$(git -C "$WORKSPACE" rev-parse --show-toplevel 2>/dev/null || true)"

jstr() { printf '"%s"' "$(printf '%s' "$1" | tr -d '"\\' | tr -d '\000-\037')"; }
env_json() {
  local load="" branch="" head="" up="" ahead=0 behind=0 dirty=0 counts
  load="$(uptime 2>/dev/null | sed -E 's/.*load averages?: *//; s/,/ /g; s/  +/ /g')"
  if [[ -n "$PROJECT" ]]; then
    branch="$(git -C "$PROJECT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    head="$(git -C "$PROJECT" rev-parse --short HEAD 2>/dev/null || true)"
    up="$(git -C "$PROJECT" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)"
    if [[ -n "$up" ]]; then
      counts="$(git -C "$PROJECT" rev-list --left-right --count "HEAD...@{upstream}" 2>/dev/null || echo "0 0")"
      ahead="${counts%%[[:space:]]*}"; behind="${counts##*[[:space:]]}"
    fi
    # Changes outside the team folder: what an in-flight builder has not handed back yet.
    dirty="$(git -C "$PROJECT" status --porcelain -- . ':!.agent-team' 2>/dev/null | wc -l | tr -d ' ')"
  fi
  printf '{"now": %s, "interval": %s, "project": %s, "branch": %s, "head": %s, "upstream": %s, "ahead": %s, "behind": %s, "dirty": %s, "load": %s}' \
    "$(date +%s)" "$INTERVAL" "$(jstr "$PROJECT")" "$(jstr "$branch")" "$(jstr "$head")" "$(jstr "$up")" \
    "${ahead:-0}" "${behind:-0}" "${dirty:-0}" "$(jstr "$load")"
}
refresh() {
  local line
  line="$("$SKILL_DIR/scripts/plan-graph.sh" --workspace "$WORKSPACE" 2>&1 | grep '^plan-graph:' | head -1)"
  [[ -f "$WORKSPACE/plan.json" ]] || { echo "monitor: plan-graph.sh wrote no plan.json${line:+ ($line)}" >&2; return 1; }
  { printf 'window.__PLAN__({"plan": '; cat "$WORKSPACE/plan.json"; printf ', "env": %s});\n' "$(env_json)"; } > "$VIEW/plan-data.js.tmp" \
    && mv "$VIEW/plan-data.js.tmp" "$VIEW/plan-data.js"
  LAST_LINE="$line"
}

LAST_LINE=""
refresh || fail "first refresh failed"
echo "$LAST_LINE"
if $ONCE; then echo "wrote $VIEW/plan-data.js"; exit 0; fi

URL="file://$VIEW/index.html"
SERVER_PID=""
cleanup() { [[ -n "$SERVER_PID" ]] && kill "$SERVER_PID" 2>/dev/null; exit 0; }
trap cleanup INT TERM EXIT
if $SERVE; then
  if command -v python3 >/dev/null 2>&1; then
    python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$VIEW" >"$VIEW/server.log" 2>&1 &
    SERVER_PID=$!
    sleep 0.6
    if kill -0 "$SERVER_PID" 2>/dev/null; then URL="http://127.0.0.1:$PORT/"
    else echo "monitor: could not serve on port $PORT (see $VIEW/server.log); use --port or the file URL" >&2; SERVER_PID=""; fi
  else
    echo "monitor: no python3, so no server; open the file URL instead" >&2
  fi
fi
echo "monitor: $URL — refreshing every ${INTERVAL}s, Ctrl-C to stop"
if $OPEN; then (command -v open >/dev/null && open "$URL") || (command -v xdg-open >/dev/null && xdg-open "$URL") || true; fi

prev="$LAST_LINE"
while sleep "$INTERVAL"; do
  refresh || continue
  # Print only when the plan's summary changes, so the terminal reads as a status log.
  if [[ "$LAST_LINE" != "$prev" ]]; then echo "$(date +%H:%M:%S) $LAST_LINE"; prev="$LAST_LINE"; fi
done
