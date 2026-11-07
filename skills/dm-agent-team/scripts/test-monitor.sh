#!/usr/bin/env bash
# Regression check for monitor.sh on a throwaway workspace: --once writes the
# page and a plan-data.js that wraps plan.json and env; the server answers on
# 127.0.0.1; bad arguments exit 2. Exit 0 = all cases pass.
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tmp=$(mktemp -d); pid=""; trap '[[ -n "$pid" ]] && kill "$pid" 2>/dev/null; rm -rf "$tmp"' EXIT
fails=0
check() { if [[ "$2" == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1: expected [$2] got [$3]"; fails=$((fails+1)); fi; }
W="$tmp/run"; mkdir -p "$W/specs"
printf '## 13. Build plan\n### PHASE-001 Foundation — MS-1\ntouches: a\ndepends-on: none\nacceptance tests: none\n### PHASE-002 Slice — MS-1\ntouches: b\ndepends-on: PHASE-001\nacceptance tests: none\n' > "$W/specs/03-architecture.md"
printf '# s\nrun: V001-t\nmax-parallel: 1\n## Build\n| Phase | Milestone | Status | Lane | Base | Revise rounds | Notes |\n|---|---|---|---|---|---|---|\n| PHASE-001 | MS-1 | in-progress | – | abc | 0 | |\n' > "$W/state.md"
js="$W/logs/monitor/plan-data.js"
parse() { python3 -c 'import json,sys; s=open(sys.argv[1]).read().strip(); p="window.__PLAN__("; assert s.startswith(p) and s.endswith(");"), "wrapper"; d=json.loads(s[len(p):-2]); print(eval(sys.argv[2]))' "$js" "$1"; }

# 1. --once writes the page and the data, and nothing is served.
out=$("$here/monitor.sh" --workspace "$W" --once); rc=$?
check "--once exits 0" 0 "$rc"
check "page copied" "yes" "$([[ -f "$W/logs/monitor/index.html" ]] && cmp -s "$W/logs/monitor/index.html" "$here/plan.html" && echo yes)"
check "plan-data.js wraps plan and env" "V001-t in-progress 3" "$(parse "d['plan']['state']['run']+' '+d['plan']['nodes'][0]['status']+' '+str(d['env']['interval'])")"
check "env has the time and load" "True True" "$(parse "str(abs(d['env']['now'] - __import__('time').time()) < 60)+' '+str(isinstance(d['env']['load'], str))")"
check "plan.json written beside state.md" "yes" "$([[ -f "$W/plan.json" ]] && echo yes)"

# 2. An invalid plan still refreshes, so the page can show the errors.
printf '### PHASE-003 Loop — MS-1\ntouches: c\ndepends-on: PHASE-003\n' >> "$W/specs/03-architecture.md"
"$here/monitor.sh" --workspace "$W" --once >/dev/null; rc=$?
check "invalid plan still refreshes" "0 False" "$rc $(parse "d['plan']['valid']")"

# 3. The server answers on 127.0.0.1 and serves the data.
if command -v python3 >/dev/null && command -v curl >/dev/null; then
  port=$((43000 + RANDOM % 2000))
  "$here/monitor.sh" --workspace "$W" --port "$port" --interval 1 > "$tmp/mon.out" 2>&1 & pid=$!
  for _ in 1 2 3 4 5 6 7 8 9 10; do grep -q "^monitor: http" "$tmp/mon.out" && break; sleep 0.5; done
  check "server url printed" "http://127.0.0.1:$port/" "$(grep -oE 'http://127\.0\.0\.1:[0-9]+/' "$tmp/mon.out" | head -1)"
  check "page served" 200 "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/")"
  check "data served" 200 "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/plan-data.js")"
  before=$(parse "d['env']['now']"); sleep 2.2
  check "data refreshes on the interval" "True" "$(parse "str(d['env']['now'] > $before)")"
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; pid=""
  sleep 0.3
  check "server stops with the monitor" "000" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 1 "http://127.0.0.1:$port/" 2>/dev/null)"
else
  echo "skip server cases (no python3 or curl)"
fi

# 4. Bad arguments exit 2.
"$here/monitor.sh" >/dev/null 2>&1; check "no arguments exit 2" 2 "$?"
"$here/monitor.sh" --workspace "$tmp/missing" >/dev/null 2>&1; check "missing workspace exits 2" 2 "$?"
"$here/monitor.sh" --workspace "$W" --interval 0 --once >/dev/null 2>&1; check "interval 0 exits 2" 2 "$?"
exit $fails
