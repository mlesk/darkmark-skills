#!/usr/bin/env bash
# Regression check for plan-graph.sh, on throwaway workspaces. A valid five-phase
# plan with live state, then one broken plan per error class. Exit 0 = all pass.
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fails=0
check() { # name expected actual
  if [[ "$2" == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1: expected [$2] got [$3]"; fails=$((fails+1)); fi; }
has() { # name needle haystack
  if [[ "$3" == *"$2"* ]]; then echo "ok   $1"; else echo "FAIL $1: no [$2] in:"; printf '%s\n' "$3" | sed 's/^/     /'; fails=$((fails+1)); fi; }
json() { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2]))" "$1" "$2"; }

# ws NAME — a workspace whose 03 §13 is stdin.
ws() { mkdir -p "$tmp/$1/specs"; { printf '# Architecture: t\n## 12. Risks\nnone\n## 13. Build plan\n'; cat; printf '## 14. After\n### PHASE-999 Appended late — MS-2\ntouches: z\ndepends-on: none\nacceptance tests: none\n'; } > "$tmp/$1/specs/03-architecture.md"; echo "$tmp/$1"; }

# ---- 1. A valid plan: a diamond plus a tail, sized, with live state ------------
W=$(ws good <<'EOF'
verify: `make test`
hotspots: src/app.py, README.md
| MS | What the human can run | Phases |
|---|---|---|
| MS-1 | the CLI counts words | PHASE-001, PHASE-002, PHASE-003 |
| MS-2 | export and report | PHASE-004, PHASE-005 |
### PHASE-001 Foundation — MS-1 · layer: foundation
goal: toolchain and smoke test
acceptance tests: none — verify green with a smoke test
touches: `pyproject.toml`, src/app.py, README.md
depends-on: none
size: S
### PHASE-002 Count words — MS-1 · slice: count · risk: normal
goal: count "words" in a file
acceptance tests: REQ-001.1 → counts
touches: src/count/, src/app.py
depends-on: PHASE-001
size: L
### PHASE-003 Ignore list — MS-1 · slice: ignore · risk: high
acceptance tests: REQ-002.1 → ignores
touches: src/ignore.py (new, small), src/app.py
depends-on: PHASE-001
size: M
### PHASE-004 Export — MS-2 · slice: export
acceptance tests: REQ-003.1 → csv
touches: src/export.py
depends-on: PHASE-002 (counts, "words"), PHASE-003 (the ignore list (nested))
size: XL
### PHASE-005 Report — MS-2 · slice: report
acceptance tests: REQ-004.1 → report
touches: src/report.py
depends-on: PHASE-004
EOF
)
cat > "$W/state.md" <<'EOF'
# Agent Team State
run: V001-tally
size: standard
mode: yolo
max-parallel: 2
stage: S2-build
status: in-progress
next-action: integrate PHASE-002
## Build
current-milestone: MS-1
| Phase | Milestone | Status | Lane | Base | Revise rounds | Notes |
|---|---|---|---|---|---|---|
| PHASE-001 Foundation | MS-1 | done | – | abc123 | 0 | |
| PHASE-002 | MS-1 | in-progress | lane-1 | def456 | 1 | REVISE: "tab" handling |
| PHASE-003 | MS-1 | done | lane-2 | def456 | 0 | |
| PHASE-F01 | MS-1 | pending | – | – | 0 | majors from MS-1 review on PHASE-002 |
## Log (one row per dispatch or resume, when its Return arrives)
| When (date -u) | Stage | Agent · mode | Tier · effort | Round | Result | Notes |
|---|---|---|---|---|---|---|
| 2026-11-03T10:00Z | S2 | builder · PHASE-002 | mid · medium | 1 | REVISE | precheck red |
| 2026-11-03T11:00Z | S2 | builder · PHASE-002 (resume) | mid · high | 2 | in-progress | retry |
EOF
out=$("$here/plan-graph.sh" --workspace "$W"); rc=$?
check "valid plan exits 0" 0 "$rc"
has "valid plan says VALID" "plan-graph: VALID" "$out"
check "critical path follows weights" "['PHASE-001', 'PHASE-002', 'PHASE-004', 'PHASE-005']" "$(json "$W/plan.json" "d['critical_path']['phases']")"
check "critical weight S+L+XL+M" 11 "$(json "$W/plan.json" "d['critical_path']['weight']")"
check "remaining path skips done phases" "['PHASE-002', 'PHASE-004', 'PHASE-005']" "$(json "$W/plan.json" "d['remaining_path']['phases']")"
check "a phase outside §13 is read; fix phase from state.md kept" "['PHASE-001', 'PHASE-002', 'PHASE-003', 'PHASE-004', 'PHASE-005', 'PHASE-999', 'PHASE-F01']" "$(json "$W/plan.json" "[n['id'] for n in d['nodes']]")"
check "status, lane, rounds from state.md" "in-progress lane-1 1" "$(json "$W/plan.json" "' '.join(str(x) for x in [d['nodes'][1][k] for k in ('status','lane','revise_rounds')])")"
check "fix phase flagged; only warnings are PHASE-999's" "True ['PHASE-999: defined under \"## 14. After\", outside §13']" "$(json "$W/plan.json" "f\"{d['nodes'][6]['fix']} {[w for w in d['warnings']]}\"")"
check "levels" "[0, 1, 1, 2, 3, 0, 0]" "$(json "$W/plan.json" "[n['level'] for n in d['nodes']]")"
check "ready: no-dependency phases only (PHASE-004 waits on PHASE-002)" "['PHASE-999', 'PHASE-F01']" "$(json "$W/plan.json" "[n['id'] for n in d['nodes'] if n['ready']]")"
check "last log row and count" "2 in-progress" "$(json "$W/plan.json" "f\"{d['nodes'][1]['log']['count']} {d['nodes'][1]['log']['last']['result']}\"")"
check "title, meta, and quotes survive" "Count words|count|count \"words\" in a file" "$(json "$W/plan.json" "'|'.join([d['nodes'][1]['title'], d['nodes'][1]['slice'], d['nodes'][1]['goal']])")"
check "touches normalised" "['pyproject.toml', 'src/app.py', 'README.md']" "$(json "$W/plan.json" "d['nodes'][0]['touches']")"
check "critical edges marked" "3" "$(json "$W/plan.json" "sum(e['critical'] for e in d['edges'])")"
check "milestones with phases (F01 joins MS-1 from state.md)" "MS-1:4 MS-2:3" "$(json "$W/plan.json" "' '.join(m['id']+':'+str(len(m['phases'])) for m in d['milestones'])")"
check "state header copied" "V001-tally yolo" "$(json "$W/plan.json" "d['state']['run']+' '+d['state']['mode']")"

# ---- 1b. Progress lines (last 8 kept, in order), the log array, first_when -------
mkdir -p "$W/logs"; for i in 1 2 3 4 5 6 7 8 9 10; do printf '2026-11-03T12:%02d:00Z step %s\n' "$i" "$i"; done > "$W/logs/PHASE-002-progress.log"
"$here/plan-graph.sh" --workspace "$W" >/dev/null
check "progress count and last 8 in order" "10 step 3 step 10" "$(json "$W/plan.json" "f\"{d['nodes'][1]['progress']['count']} {d['nodes'][1]['progress']['lines'][0]['text']} {d['nodes'][1]['progress']['lines'][-1]['text']}\"")"
check "progress time split from text" "2026-11-03T12:10:00Z" "$(json "$W/plan.json" "d['nodes'][1]['progress']['lines'][-1]['when']")"
check "no progress file is empty" "0 []" "$(json "$W/plan.json" "f\"{d['nodes'][0]['progress']['count']} {d['nodes'][0]['progress']['lines']}\"")"
check "log array with phases" "2 ['PHASE-002'] REVISE" "$(json "$W/plan.json" "f\"{len(d['log'])} {d['log'][0]['phases']} {d['log'][0]['result']}\"")"
check "first_when is the first row" "2026-11-03T10:00Z" "$(json "$W/plan.json" "d['nodes'][1]['log']['first_when']")"

# ---- 2. --check writes nothing -------------------------------------------------
rm -f "$W/plan.json"; "$here/plan-graph.sh" --workspace "$W" --check >/dev/null
check "--check writes no plan.json" "absent" "$([[ -f "$W/plan.json" ]] && echo present || echo absent)"

# ---- 3. A cycle ----------------------------------------------------------------
W=$(ws cycle <<'EOF'
### PHASE-001 A — MS-1
touches: a
depends-on: none
acceptance tests: none
### PHASE-002 B — MS-1
touches: b
depends-on: PHASE-001, PHASE-003
acceptance tests: none
### PHASE-003 C — MS-1
touches: c
depends-on: PHASE-002
acceptance tests: none
EOF
)
out=$("$here/plan-graph.sh" --workspace "$W"); rc=$?
check "cycle exits 1" 1 "$rc"
has "cycle is named" "dependency cycle: PHASE-00" "$out"
check "plan.json still written, invalid" "False" "$(json "$W/plan.json" "d['valid']")"

# ---- 4. Unknown, self, later-milestone, malformed dependencies; missing lines ---
W=$(ws deps <<'EOF'
### PHASE-001 A — MS-1
touches: a
depends-on: none
### PHASE-002 B — MS-1
touches: b
depends-on: PHASE-002, PHASE-009, PHASE-003, phase two
acceptance tests: none
### PHASE-003 C — MS-2
depends-on: PHASE-001
acceptance tests: none
### PHASE-003 C again — MS-2
touches: c
depends-on: none
EOF
)
out=$("$here/plan-graph.sh" --workspace "$W" --check); rc=$?
check "dependency errors exit 1" 1 "$rc"
has "self dependency" "PHASE-002: depends on itself" "$out"
has "unknown dependency" "depends on PHASE-009, which the plan does not define" "$out"
has "later milestone" "PHASE-002 (MS-1) depends on PHASE-003 in a later milestone (MS-2)" "$out"
has "malformed tokens, one error" 'PHASE-002: depends-on: has "phase two", which is not a phase ID' "$out"
has "duplicate phase" "PHASE-003: defined twice" "$out"
has "missing acceptance warning" "warning: PHASE-001: no acceptance tests: line" "$out"

W=$(ws nolines <<'EOF'
### PHASE-001 A — MS-1
goal: nothing else
EOF
)
out=$("$here/plan-graph.sh" --workspace "$W" --check)
has "no depends-on line" "PHASE-001: no depends-on: line" "$out"
has "no touches line" "PHASE-001: no touches: line" "$out"

# ---- 5. Parallel overlap: an error above max-parallel 1, a warning at 1 ---------
W=$(ws overlap <<'EOF'
hotspots: src/routes.py
### PHASE-001 A — MS-1
touches: src
depends-on: none
acceptance tests: none
### PHASE-002 B — MS-1
touches: src/b/, src/routes.py
depends-on: PHASE-001
acceptance tests: none
### PHASE-003 C — MS-1
touches: src/b/c.py, src/routes.py
depends-on: PHASE-001
acceptance tests: none
### PHASE-004 D — MS-1
touches: src/d.py, src/routes.py
depends-on: PHASE-001
acceptance tests: none
EOF
)
out=$("$here/plan-graph.sh" --workspace "$W" --check --max-parallel 2); rc=$?
check "overlap at max-parallel 2 exits 1" 1 "$rc"
has "overlap names the shared path" "PHASE-002 and PHASE-003 can run in parallel but both touch src/b/c.py" "$out"
check "hotspot and ancestor overlaps are not errors" 1 "$(printf '%s\n' "$out" | grep -c '^error:')"
out=$("$here/plan-graph.sh" --workspace "$W" --check --max-parallel 1); rc=$?
check "overlap at max-parallel 1 exits 0" 0 "$rc"
has "overlap warning at 1" "1 phase pair(s) the graph lets run together share files" "$out"

# ---- 6. Fix phases: a plan phase may depend on a state-only PHASE-F##; accept sorts last
W=$(ws fix <<'EOF'
### PHASE-001 A — MS-1
touches: a
depends-on: none
acceptance tests: none
### PHASE-F03 Accept-gate changes — accept · slice: human changes
touches: a
depends-on: PHASE-F02
acceptance tests: none
EOF
)
printf '# s\nmax-parallel: 1\n## Build\n| Phase | Milestone | Status | Lane | Base | Revise rounds | Notes |\n|---|---|---|---|---|---|---|\n| PHASE-001 | MS-1 | done | | | 0 | |\n| PHASE-F02 | MS-1 | done | | | 1 | majors |\n| PHASE-F03 | accept | pending | | | 0 | |\n' > "$W/state.md"
out=$("$here/plan-graph.sh" --workspace "$W"); rc=$?
check "dependency on a state-only fix phase is valid" 0 "$rc"
check "accept milestone sorts after MS-n" "['MS-1', 'MS-2', 'accept']" "$(json "$W/plan.json" "[m['id'] for m in d['milestones']]")"
check "fix phase ready once its fix dependency is done" "True" "$(json "$W/plan.json" "[n for n in d['nodes'] if n['id']=='PHASE-F03'][0]['ready']")"

# ---- 7. Plan in 04, no state.md, unknown size, bad arguments -------------------
mkdir -p "$tmp/p04/specs"; printf '# Architecture\n' > "$tmp/p04/specs/03-architecture.md"
printf '### PHASE-001 A — MS-1\ntouches: a\ndepends-on: none\nacceptance tests: none\nsize: huge\n' > "$tmp/p04/specs/04-build-plan.md"
out=$("$here/plan-graph.sh" --workspace "$tmp/p04"); rc=$?
check "04 plan without state.md exits 0" 0 "$rc"
has "unknown size warned" "size: HUGE is not S, M, L, or XL" "$out"
check "unknown status defaults to pending" "pending True" "$(json "$tmp/p04/plan.json" "d['nodes'][0]['status']+' '+str(d['nodes'][0]['ready'])")"
mkdir -p "$tmp/empty/specs"; printf '# Architecture\n## 13. Build plan\nnothing yet\n' > "$tmp/empty/specs/03-architecture.md"
out=$("$here/plan-graph.sh" --workspace "$tmp/empty" --check); rc=$?
check "empty plan exits 1" 1 "$rc"
has "empty plan named" "the plan defines no phases" "$out"
"$here/plan-graph.sh" >/dev/null 2>&1; check "no arguments exit 2" 2 "$?"
"$here/plan-graph.sh" --workspace "$tmp/missing" >/dev/null 2>&1; check "missing workspace exits 2" 2 "$?"

exit $fails
