#!/usr/bin/env bash
set -uo pipefail

# plan-graph.sh — checks the build plan in 03 §13 as a dependency graph and
# writes <workspace>/plan.json: the phases, their edges, live status from
# state.md, the last §Log row per phase, and the critical path. The Lead runs it
# before the spec review (an error is a spec defect) and with each phase commit;
# run.sh runs it after each session. No judgment calls.
#
# Errors: no phases; a phase defined twice; a phase with no depends-on: or
# touches: line; a dependency that names no phase, the phase itself, or a phase
# in a later milestone; a cycle; with max-parallel above 1, two phases the graph
# lets run together whose touches: overlap outside the hotspots.
# Warnings: no acceptance tests: line; an unknown size: or status; a phase with
# no milestone, or whose heading and milestone table disagree; a state.md row
# for a phase the plan does not define (fix phases PHASE-F## excepted).
#
# Critical path: the longest dependency chain weighted by size: (S 1, M 2, L 3,
# XL 5; unsized counts as M). remaining_path counts done phases as 0.
#
# Usage:
#   plan-graph.sh --workspace DIR [--out FILE] [--max-parallel N] [--check]
#
# --check validates without writing plan.json. max-parallel defaults to
# state.md's. Exit 0 valid · 1 plan errors (plan.json is still written,
# listing them) · 2 could not run.

WORKSPACE="" OUT="" MAXPAR="" CHECK=false
usage() { sed -n '4,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 2; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace)    WORKSPACE="$2"; shift 2 ;;
    --out)          OUT="$2"; shift 2 ;;
    --max-parallel) MAXPAR="$2"; shift 2 ;;
    --check)        CHECK=true; shift ;;
    -h|--help)      usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done
[[ -n "$WORKSPACE" ]] || usage
fail() { echo "plan-graph: $*" >&2; exit 2; }
ARCH="$WORKSPACE/specs/03-architecture.md"
PLAN="$WORKSPACE/specs/04-build-plan.md"; [[ -f "$PLAN" ]] || PLAN="$ARCH"
[[ -f "$PLAN" ]] || fail "no $ARCH"
STATE="$WORKSPACE/state.md"; [[ -f "$STATE" ]] || STATE=/dev/null
[[ -n "$OUT" ]] || OUT="$WORKSPACE/plan.json"
[[ -n "$MAXPAR" ]] || MAXPAR="$(grep -m1 '^max-parallel:' "$STATE" | grep -oE '[0-9]+' | head -1)"
[[ "$MAXPAR" =~ ^[0-9]+$ ]] || MAXPAR=1

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# Phases are read from the whole file, as coverage.sh does; one outside §13 is a warning.
HAS13=0; grep -q '^## 13\.' "$PLAN" && HAS13=1

cat > "$TMP/graph.awk" <<'AWK'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
function unq(s) { gsub(/`/, "", s); return trim(s) }
function esc(s,   o, i, c) {
  o = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\\") o = o "\\\\"
    else if (c == "\"") o = o "\\\""
    else if (index(CTRL, c)) o = o " "
    else o = o c
  }
  return o
}
function q(s) { return "\"" esc(s) "\"" }
function err(m) { errs[++nerr] = m }
function warn(m) { warns[++nwarn] = m }
function msnum(m) { if (m == "accept") return 9999; sub(/^MS-/, "", m); return m + 0 }
function splitstr(s, sep, arr,   k, p) {
  k = 0
  if (s == "") return 0
  while ((p = index(s, sep)) > 0) { arr[++k] = substr(s, 1, p - 1); s = substr(s, p + length(sep)) }
  arr[++k] = s
  return k
}
# A touches: entry as a comparable path: no backticks, note, ./, or trailing glob.
function normpath(p) {
  p = unq(p); sub(/[ \t]+\(.*\)$/, "", p); sub(/^\.\//, "", p)
  sub(/\/\*\*?$/, "", p); sub(/\/$/, "", p); return p
}
# Notes in parentheses ("PHASE-010 (toolbar chrome)", "a.ts (new, small)") are prose.
function nopar(s) { while (gsub(/\([^()]*\)/, "", s)) ; return trim(s) }
function overlap(a, b) { return a == b || index(b, a "/") == 1 || index(a, b "/") == 1 }
function addnode(id) { if (!(id in idx)) { n++; ids[n] = id; idx[id] = n } return idx[id] }
function setfield(i, key, val,   v, t, k, tok, nt, bad) {
  v = unq(val)
  if (key == "touches" || key == "depends-on") v = nopar(v)
  if (key == "goal") goal[i] = v
  else if (key == "traces") traces[i] = v
  else if (key == "acceptance tests") acc[i] = v
  else if (key == "risk") risk[i] = v
  else if (key == "layer") layer[i] = v
  else if (key == "slice") slice[i] = v
  else if (key == "size") sz[i] = toupper(v)
  else if (key == "touches") {
    hastouch[i] = 1
    if (v == "none" || v == "–" || v == "-") return
    nt = split(v, t, ",")
    for (k = 1; k <= nt; k++) { tok = normpath(t[k]); if (tok != "") touch[i, ++ntouch[i]] = tok }
  }
  else if (key == "depends-on") {
    hasdeps[i] = 1
    if (v == "none" || v == "–" || v == "-" || v == "") return
    nt = split(v, t, /[ ,;]+/); bad = ""
    for (k = 1; k <= nt; k++) {
      tok = t[k]; sub(/[.]$/, "", tok)
      if (tok == "" || tok == "and") continue
      if (tok ~ /^PHASE-[0-9A-Za-z]+$/) dep[i, ++ndep[i]] = tok
      else bad = bad (bad == "" ? "" : " ") tok
    }
    if (bad != "") err(ids[i] ": depends-on: has \"" bad "\", which is not a phase ID (put notes in parentheses)")
  }
}
function jstrs(arr, k,   s, j) { s = ""; for (j = 1; j <= k; j++) s = s (j > 1 ? ", " : "") q(arr[j]); return "[" s "]" }
function jbool(b) { return b ? "true" : "false" }
function jnum(x) { return (x == "" ? 0 : x + 0) }

BEGIN {
  CTRL = ""; for (k = 1; k < 32; k++) CTRL = CTRL sprintf("%c", k)
  W["S"] = 1; W["M"] = 2; W["L"] = 3; W["XL"] = 5
  split("pending in-progress in-review done stale escalated blocked", sl, " ")
  for (k in sl) VALIDST[sl[k]] = 1
}

# ---- The plan ------------------------------------------------------------------
FILENAME == planf && /^## / { h2 = $0; cur = 0; next }
FILENAME == planf && /^### PHASE-/ {
  id = $2
  if (id in defined) err(id ": defined twice in the plan")
  if (has13 && index(h2, "## 13.") != 1) warn(id ": defined under \"" h2 "\", outside §13")
  defined[id] = 1; nplan++
  cur = addnode(id); inplan[cur] = 1
  rest = substr($0, 5); rest = substr(rest, length(id) + 2)
  p = index(rest, " — ")
  if (p) { title[cur] = trim(substr(rest, 1, p - 1)); meta = substr(rest, p + length(" — ")) }
  else { title[cur] = trim(rest); meta = "" }
  np = splitstr(meta, " · ", parts)
  for (k = 1; k <= np; k++) {
    part = trim(parts[k])
    if (part ~ /^MS-[0-9]+$/ || part == "accept") ms[cur] = part
    else if ((c = index(part, ":")) > 0) setfield(cur, trim(substr(part, 1, c - 1)), substr(part, c + 1))
  }
  next
}
FILENAME == planf && /^#/ { cur = 0; next }
FILENAME == planf && !cur && /^hotspots:/ && (!has13 || index(h2, "## 13.") == 1) {
  nt = split(substr($0, index($0, ":") + 1), ht, ",")
  for (k = 1; k <= nt; k++) { h = normpath(ht[k]); if (h != "" && h != "none" && !(h in hot)) { hot[h] = 1; hots[++nhot] = h } }
  next
}
FILENAME == planf && /^\| *MS-[0-9]+ *\|/ {
  split($0, f, "|"); m = trim(f[2]); mswhat[m] = trim(f[3]); msseen[m] = 1
  s = f[4]
  while (match(s, /PHASE-[0-9A-Za-z]+/)) { tablems[substr(s, RSTART, RLENGTH)] = m; s = substr(s, RSTART + RLENGTH) }
  next
}
FILENAME == planf && cur && /^[a-z][a-z -]*:/ {
  c = index($0, ":"); setfield(cur, substr($0, 1, c - 1), substr($0, c + 1)); next
}

# ---- state.md: header fields, the Build table, the Log -------------------------
FILENAME == statef && /^## / { sec = $0; next }
FILENAME == statef && /^[a-z][a-z-]*:/ && (sec == "" || index(sec, "## Build") == 1) {
  c = index($0, ":"); sf[substr($0, 1, c - 1)] = trim(substr($0, c + 1)); next
}
FILENAME == statef && index(sec, "## Build") == 1 && /^\| *PHASE-/ {
  split($0, f, "|"); split(trim(f[2]), pa, " ")
  i = addnode(pa[1]); srow[i] = 1
  smile[i] = trim(f[3]); status[i] = trim(f[4]); lane[i] = trim(f[5]); base[i] = trim(f[6])
  rev[i] = trim(f[7]); notes[i] = trim(f[8])
  next
}
FILENAME == statef && index(sec, "## Log") == 1 && /^\| / && $0 !~ /^\| *When/ && $0 !~ /^\| *-/ {
  delete rowseen; s = $0
  while (match(s, /PHASE-[0-9A-Za-z]+/)) {
    pid = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
    if (!(pid in rowseen)) { rowseen[pid] = 1; logn[pid]++; logrow[pid] = $0 }
  }
  next
}

END {
  if (nplan == 0) err("the plan defines no phases (no ### PHASE- headings in 03 §13)")

  # ---- Per-phase fields --------------------------------------------------------
  for (i = 1; i <= n; i++) {
    id = ids[i]
    isfix[i] = (id ~ /^PHASE-F/)
    if (inplan[i]) {
      if (!hasdeps[i]) err(id ": no depends-on: line")
      if (!hastouch[i]) err(id ": no touches: line")
      if (!(i in acc)) warn(id ": no acceptance tests: line (coverage.sh reads it)")
      if (ms[i] == "" && (id in tablems)) ms[i] = tablems[id]
      else if (ms[i] != "" && (id in tablems) && tablems[id] != ms[i])
        warn(id ": heading says " ms[i] ", the milestone table says " tablems[id])
      if (ms[i] == "" && smile[i] ~ /^(MS-[0-9]+|accept)$/) ms[i] = smile[i]
      if (ms[i] == "" && !isfix[i]) warn(id ": no milestone (MS-n in its heading or the milestone table)")
    } else {
      if (!isfix[i]) warn("state.md lists " id ", which the plan does not define")
      if (ms[i] == "" && smile[i] ~ /^(MS-[0-9]+|accept)$/) ms[i] = smile[i]
    }
    if (ms[i] != "") msseen[ms[i]] = 1
    if (sz[i] == "") wt[i] = 2
    else if (sz[i] in W) wt[i] = W[sz[i]]
    else { warn(id ": size: " sz[i] " is not S, M, L, or XL; counted as M"); wt[i] = 2 }
    st[i] = (srow[i] && status[i] != "") ? status[i] : "pending"
    if (!(st[i] in VALIDST)) warn(id ": status \"" st[i] "\" is not a phase status")
  }

  # ---- Edges -------------------------------------------------------------------
  for (i = 1; i <= n; i++) for (k = 1; k <= ndep[i]; k++) {
    d = dep[i, k]
    if (d == ids[i]) { err(ids[i] ": depends on itself"); continue }
    # A fix phase may exist only as a state.md row.
    if (!(d in idx) || (!inplan[idx[d]] && !isfix[idx[d]])) { err(ids[i] ": depends on " d ", which the plan does not define"); continue }
    j = idx[d]
    if ((i, j) in haspred) continue
    haspred[i, j] = 1; pred[i, ++npred[i]] = j; succ[j, ++nsucc[j]] = i; nedge++; efrom[nedge] = j; eto[nedge] = i
    if (ms[i] != "" && ms[j] != "" && msnum(ms[j]) > msnum(ms[i]))
      err(ids[i] " (" ms[i] ") depends on " d " in a later milestone (" ms[j] ")")
  }

  # ---- Topological order (Kahn) and cycles -------------------------------------
  head = 1; tail = 0
  for (i = 1; i <= n; i++) { indeg[i] = npred[i]; if (indeg[i] == 0) Q[++tail] = i }
  while (head <= tail) {
    v = Q[head++]; topo[++ntopo] = v
    for (k = 1; k <= nsucc[v]; k++) { s = succ[v, k]; if (--indeg[s] == 0) Q[++tail] = s }
  }
  cyclic = (ntopo < n)
  if (cyclic) {
    # Every node left has a predecessor left: walk predecessors until one repeats.
    for (i = 1; i <= n && indeg[i] == 0; i++) ;
    v = i; step = 0
    while (!(v in visit)) {
      visit[v] = ++step; path[step] = v
      for (k = 1; k <= npred[v]; k++) if (indeg[pred[v, k]] > 0) { v = pred[v, k]; break }
    }
    cyc = ""
    for (k = step; k >= visit[v]; k--) cyc = cyc ids[path[k]] " → "
    err("dependency cycle: " cyc ids[path[step]])
  }

  # ---- Levels, critical path, ancestors (acyclic only) --------------------------
  if (!cyclic) {
    for (ti = 1; ti <= ntopo; ti++) {
      v = topo[ti]; level[v] = 0; best = 0; rbest = 0; from[v] = 0; rfrom[v] = 0
      for (k = 1; k <= npred[v]; k++) {
        p = pred[v, k]
        if (level[p] + 1 > level[v]) level[v] = level[p] + 1
        if (dist[p] > best) { best = dist[p]; from[v] = p }
        if (rdist[p] > rbest) { rbest = rdist[p]; rfrom[v] = p }
        anc[v, p] = 1
        for (j = 1; j <= n; j++) if ((p, j) in anc) anc[v, j] = 1
      }
      dist[v] = best + wt[v]
      rdist[v] = rbest + (st[v] == "done" ? 0 : wt[v])
    }
    e = 0; re = 0
    for (i = 1; i <= n; i++) {
      if (e == 0 || dist[i] > dist[e]) e = i
      if (st[i] != "done" && (re == 0 || rdist[i] > rdist[re])) re = i
    }
    for (v = e; v; v = from[v]) { crit[v] = 1; cp[++ncp] = ids[v]; if (from[v]) critedge[from[v], v] = 1 }
    critw = e ? dist[e] : 0
    for (v = re; v; v = rfrom[v]) if (st[v] != "done") rp[++nrp] = ids[v]
    remw = re ? rdist[re] : 0
    # Reverse into dependency order.
    for (k = 1; k <= ncp / 2; k++) { x = cp[k]; cp[k] = cp[ncp - k + 1]; cp[ncp - k + 1] = x }
    for (k = 1; k <= nrp / 2; k++) { x = rp[k]; rp[k] = rp[nrp - k + 1]; rp[nrp - k + 1] = x }

    # ---- touches: overlap between phases the graph lets run together -----------
    for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++) {
      if (!inplan[i] || !inplan[j] || ((i, j) in anc) || ((j, i) in anc)) continue
      shared = ""
      for (a = 1; a <= ntouch[i] && shared == ""; a++) for (b = 1; b <= ntouch[j] && shared == ""; b++) {
        x = touch[i, a]; y = touch[j, b]
        if (overlap(x, y) && !(x in hot) && !(y in hot)) shared = (length(x) >= length(y) ? x : y)
      }
      if (shared == "") continue
      npairs++
      if (maxpar > 1) err(ids[i] " and " ids[j] " can run in parallel but both touch " shared " (max-parallel " maxpar ")")
    }
    if (npairs && maxpar <= 1)
      warn(npairs " phase pair(s) the graph lets run together share files outside the hotspots: fine at max-parallel 1, errors above it")
  }

  # ---- Ready phases and the summary --------------------------------------------
  for (i = 1; i <= n; i++) {
    ready[i] = 0
    if (st[i] == "pending" || st[i] == "stale") {
      ready[i] = 1
      for (k = 1; k <= npred[i]; k++) if (st[pred[i, k]] != "done") ready[i] = 0
    }
    cnt[st[i]]++; if (ready[i]) nready++
  }

  # ---- Milestones in number order ----------------------------------------------
  for (m in msseen) mlist[++nms] = m
  for (a = 2; a <= nms; a++) { x = mlist[a]; for (b = a - 1; b >= 1 && msnum(mlist[b]) > msnum(x); b--) mlist[b + 1] = mlist[b]; mlist[b + 1] = x }

  # ---- plan.json ---------------------------------------------------------------
  o = "{\n  \"schema\": 1,\n  \"generated\": " q(now) ",\n  \"source\": " q(src) ",\n"
  split("run project kind size mode quality-bar stage status halt next-action current-milestone", hf, " ")
  o = o "  \"state\": {"
  for (k = 1; k <= 11; k++) o = o (k > 1 ? ", " : "") q(hf[k]) ": " q(sf[hf[k]])
  o = o "},\n  \"max_parallel\": " maxpar ",\n  \"valid\": " jbool(nerr == 0) ",\n"
  o = o "  \"errors\": " jstrs(errs, nerr) ",\n  \"warnings\": " jstrs(warns, nwarn) ",\n"
  o = o "  \"hotspots\": " jstrs(hots, nhot) ",\n  \"milestones\": ["
  for (a = 1; a <= nms; a++) {
    m = mlist[a]; nmp = 0; delete mp
    for (i = 1; i <= n; i++) if (ms[i] == m) mp[++nmp] = ids[i]
    o = o (a > 1 ? "," : "") "\n    {\"id\": " q(m) ", \"what\": " q(mswhat[m]) ", \"phases\": " jstrs(mp, nmp) "}"
  }
  o = o "\n  ],\n  \"nodes\": ["
  for (i = 1; i <= n; i++) {
    nd = 0; delete dl; for (k = 1; k <= npred[i]; k++) dl[++nd] = ids[pred[i, k]]
    nt = 0; delete tl; for (k = 1; k <= ntouch[i]; k++) tl[++nt] = touch[i, k]
    o = o (i > 1 ? "," : "") "\n    {\"id\": " q(ids[i]) ", \"title\": " q(title[i]) ", \"milestone\": " q(ms[i])
    o = o ", \"in_plan\": " jbool(inplan[i]) ", \"fix\": " jbool(isfix[i])
    o = o ", \"goal\": " q(goal[i]) ", \"traces\": " q(traces[i]) ", \"acceptance\": " q(acc[i])
    o = o ", \"risk\": " q(risk[i]) ", \"layer\": " q(layer[i]) ", \"slice\": " q(slice[i])
    o = o ", \"size\": " q(sz[i]) ", \"weight\": " wt[i] ", \"depends_on\": " jstrs(dl, nd) ", \"touches\": " jstrs(tl, nt)
    o = o ", \"status\": " q(st[i]) ", \"ready\": " jbool(ready[i]) ", \"lane\": " q(lane[i]) ", \"base\": " q(base[i])
    o = o ", \"revise_rounds\": " jnum(rev[i] ~ /^[0-9]+$/ ? rev[i] : 0) ", \"notes\": " q(notes[i])
    o = o ", \"level\": " jnum(level[i]) ", \"critical\": " jbool(crit[i])
    o = o ", \"log\": {\"count\": " jnum(logn[ids[i]]) ", \"last\": "
    if (ids[i] in logrow) {
      split(logrow[ids[i]], lf, "|")
      o = o "{\"when\": " q(trim(lf[2])) ", \"stage\": " q(trim(lf[3])) ", \"agent\": " q(trim(lf[4])) ", \"tier\": " q(trim(lf[5]))
      o = o ", \"round\": " q(trim(lf[6])) ", \"result\": " q(trim(lf[7])) ", \"notes\": " q(trim(lf[8])) "}"
    } else o = o "null"
    o = o "}}"
  }
  o = o "\n  ],\n  \"edges\": ["
  for (k = 1; k <= nedge; k++)
    o = o (k > 1 ? "," : "") "\n    {\"from\": " q(ids[efrom[k]]) ", \"to\": " q(ids[eto[k]]) ", \"critical\": " jbool((efrom[k], eto[k]) in critedge) "}"
  o = o "\n  ],\n  \"critical_path\": {\"phases\": " jstrs(cp, ncp) ", \"weight\": " jnum(critw) "},\n"
  o = o "  \"remaining_path\": {\"phases\": " jstrs(rp, nrp) ", \"weight\": " jnum(remw) "},\n"
  o = o "  \"summary\": {\"phases\": " n ", \"edges\": " jnum(nedge) ", \"ready\": " jnum(nready)
  for (k = 1; k <= 7; k++) o = o ", " q(sl[k]) ": " jnum(cnt[sl[k]])
  o = o "}\n}\n"
  printf "%s", o > json

  # ---- Report ------------------------------------------------------------------
  for (k = 1; k <= nerr; k++) print "error: " errs[k]
  for (k = 1; k <= nwarn; k++) print "warning: " warns[k]
  line = n " phases, " jnum(nedge) " edges, " jnum(cnt["done"]) " done, " jnum(nready) " ready"
  if (ncp) { line = line "; critical path"; for (k = 1; k <= ncp; k++) line = line (k > 1 ? " →" : "") " " cp[k]; line = line " (weight " critw ")" }
  print "plan-graph: " (nerr ? "INVALID — " nerr " error(s)" : "VALID") " — " line
  exit (nerr ? 1 : 0)
}
AWK

awk -v planf="$PLAN" -v statef="$STATE" -v json="$TMP/plan.json" -v maxpar="$MAXPAR" -v has13="$HAS13" \
    -v now="$(date -u +%Y-%m-%dT%H:%M:%SZ)" -v src="$PLAN" -f "$TMP/graph.awk" "$PLAN" "$STATE"
rc=$?
[[ $rc -le 1 && -s "$TMP/plan.json" ]] || fail "awk failed (exit $rc)"
if ! $CHECK; then
  # Write beside the target, then rename, so a reader never sees half a file.
  cp "$TMP/plan.json" "$OUT.tmp" && mv "$OUT.tmp" "$OUT" || fail "cannot write $OUT"
  echo "wrote $OUT"
fi
exit $rc
