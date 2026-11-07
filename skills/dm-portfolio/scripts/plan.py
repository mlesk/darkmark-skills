#!/usr/bin/env python3
"""plan.py — deterministic portfolio planner for dm-portfolio.

Usage:
  plan.py --ops DIR [--limit N]

Reads inventory/latest.json, projects.json, config.json, seeds.json, and the
previous backlog/state.json. Emits one Markdown file per opportunity plus
INDEX.md, NEXT.md, and state.json. It never starts work.
"""
import argparse
import json
import re
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

BASE_LEVERAGE = {"ship": 9, "finish": 8, "fix": 7, "next": 8,
                 "leverage": 9, "explore": 8, "learn": 6, "maintain": 3}
BASE_LEARNING = {"ship": 6, "finish": 3, "fix": 4, "next": 5,
                 "leverage": 7, "explore": 9, "learn": 9, "maintain": 1}
EFFORT_TIME = {"S": 9, "M": 6, "L": 3}
EFFORT_COST = {"S": 9, "M": 6, "L": 3}
EFFORT_DAYS = {"S": 0.5, "M": 1.5, "L": 4.0}


def run_branch(run_name, unmerged):
    """Match a run to its unmerged branch, tolerating the V###- prefix."""
    stem = re.sub(r"^V\d+-", "", run_name)
    for b in unmerged:
        if run_name in b or (stem and stem in b):
            return b
    return None


def read_json(path, default):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return default


def slug(text, limit=60):
    s = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return s[:limit].strip("-")


def clamp(n, lo=1, hi=10):
    return max(lo, min(hi, n))


def score_of(scores, weights):
    total = sum(weights.values())
    return round(sum(clamp(scores.get(k, 5)) * w for k, w in weights.items()) / total, 1)


def prompt_for(item):
    if item.get("prompt"):
        return item["prompt"].strip()
    return (
        f"Goal: {item['title']}\n"
        f"Project: {item['project']}\n"
        f"Why now: {item['why_now']}\n"
        f"Done when: {item['outcome']}\n"
        f"First action: {item['first_action']}\n"
        f"Use: {item['skill']} ({item['model']} tier).\n"
        "Constraints: stay inside the project; no new paid services; stop at the first human gate.\n"
        "Before starting: restate the plan in five lines and name the two ways it could fail."
    )


def candidate(project, category, title, why, outcome, first, skill, effort,
              model="standard", scores=None, evidence=None, expires_days=60,
              source="deterministic", key=None):
    priority = project.get("priority", 3) if project else 4
    s = scores or {
        "goal": clamp(priority * 2),
        "leverage": BASE_LEVERAGE.get(category, 6),
        "time": EFFORT_TIME.get(effort, 6),
        "probability": 7,
        "learning": BASE_LEARNING.get(category, 5),
        "cost": EFFORT_COST.get(effort, 6),
    }
    return {
        "key": key or f"{project['name'] if project else 'career'}:{category}:{slug(title)}",
        "project": project["name"] if project else "career",
        "category": category,
        "title": title,
        "why_now": why,
        "outcome": outcome,
        "first_action": first,
        "skill": skill,
        "model": model,
        "effort": effort,
        "scores": s,
        "evidence": evidence or [],
        "expires_days": expires_days,
        "source": source,
    }


def from_inventory(inv, weights):
    out = []
    for p in inv.get("projects", []):
        if not p.get("exists") or not p.get("is_git"):
            continue
        g = p.get("git", {})
        sweeps = p.get("tests", {}).get("sweep", {}) or {}
        priority = p.get("priority", 3)
        runs = p.get("runs", [])
        unmerged = {b["branch"] for b in g.get("unmerged_branches", [])}

        # One finish item per project, covering every done run whose branch is
        # still unmerged. Merging is mechanical; three identical items is noise.
        done_branches = []
        for r in runs:
            if (r.get("status") or "").lower() == "done":
                b = run_branch(r["name"], unmerged)
                if b:
                    done_branches.append((r["name"], b))
        if done_branches:
            names = ", ".join(n for n, _ in done_branches)
            branches = ", ".join(b for _, b in done_branches)
            title = (f"Merge and archive {done_branches[0][0]}" if len(done_branches) == 1
                     else f"Merge and archive {len(done_branches)} done runs")
            out.append(candidate(
                p, "finish", title,
                f"Closed work is sitting on unmerged branches ({branches}); it is invisible and the repo carries branch debt.",
                f"All listed branches merged to {g.get('default_branch') or 'the default branch'}, verify green, runs archived.",
                "Review each branch diff, run verify, merge in order, then archive the runs.",
                "dm-agent-team", "S" if len(done_branches) == 1 else "M", "standard",
                {"goal": clamp(priority * 2), "leverage": 8,
                 "time": 9 if len(done_branches) == 1 else 7,
                 "probability": 9, "learning": 3,
                 "cost": 9 if len(done_branches) == 1 else 8},
                [f"done run {n} on {b}" for n, b in done_branches],
                30))

        for r in runs:
            status = (r.get("status") or "").lower()
            if status in ("in-progress", "awaiting-human"):
                nxt = r.get("next_action") or "resume the run"
                out.append(candidate(
                    p, "next", nxt[:110],
                    f"The run is {status} at {r.get('stage','')}; the next action is already written.",
                    "The run's next-action is complete and state.md is updated.",
                    "Resume the run at next-action.",
                    "dm-agent-team", "M", "standard",
                    {"goal": clamp(priority * 2), "leverage": 8, "time": 6,
                     "probability": 8, "learning": 5, "cost": 6},
                    [f"run {r['name']} {status}", f"next-action: {nxt[:160]}"],
                    30))
            elif status == "blocked":
                out.append(candidate(
                    p, "next", f"Unblock {r['name']}",
                    f"The run is blocked: {r.get('halt') or 'see state.md'}.",
                    "The block is resolved or the run is deliberately abandoned.",
                    "Read the halt, decide, update state.md.",
                    "dm-agent-team", "S", "deep",
                    {"goal": clamp(priority * 2), "leverage": 7, "time": 8,
                     "probability": 6, "learning": 4, "cost": 8},
                    [f"run {r['name']} blocked"], 14))

        if sweeps.get("health") == "RED":
            out.append(candidate(
                p, "fix", f"Clear the red sweep for {p['name']}",
                "The nightly sweep is red; a red signal compounds if it is ignored.",
                "Sweep returns green or amber with the failure explained.",
                "Open the latest sweep digest and fix the first red item.",
                "dm-debug", "S", "standard",
                {"goal": clamp(priority * 2), "leverage": 6, "time": 9,
                 "probability": 8, "learning": 4, "cost": 9},
                [f"sweep health {sweeps.get('health')}"], 14))

        if not p.get("deploy_url") and (p.get("deploy", {}).get("signals") or
                                         p.get("role") in ("shippable product", "flagship product")):
            out.append(candidate(
                p, "ship", f"Deploy {p['name']}",
                "It is built and tested but has no public URL; deployment is the shortest path to an external user.",
                "A public URL serving the product, with analytics and one external user.",
                "Pick the hosting target, write the deploy phase, run verify, deploy to staging.",
                "dm-agent-team", "M", "deep",
                {"goal": clamp(priority * 2 + 1), "leverage": 9, "time": 7,
                 "probability": 8 if p.get("tests", {}).get("command") else 6,
                 "learning": 5, "cost": 6},
                [f"deploy signals: {p.get('deploy', {}).get('signals') or 'role implies deployable'}",
                 f"users: {p.get('users', 0)}"], 45))

        if p.get("prs"):
            for pr in p["prs"][:3]:
                out.append(candidate(
                    p, "finish", f"Land PR #{pr.get('number')}: {pr.get('title','')[:60]}",
                    "An open PR is work that is done but not in the product.",
                    f"PR #{pr.get('number')} is merged or closed with a reason.",
                    "Review the PR, run the checks, merge or close.",
                    "gstack-review", "S", "standard",
                    {"goal": clamp(priority * 2), "leverage": 6, "time": 9,
                     "probability": 9, "learning": 2, "cost": 9},
                    [f"open PR #{pr.get('number')}"], 21))

        if g.get("dirty", 0) > 0 and not any(r.get("status") in ("in-progress", "awaiting-human") for r in runs):
            out.append(candidate(
                p, "maintain", f"Commit or stash {g['dirty']} file(s) in {p['name']}",
                "A dirty tree makes every agent run harder to review and every diff ambiguous.",
                "The tree is clean or the work is on a named branch.",
                "Review the diff, commit it with a message, or stash it.",
                "none", "S", "standard",
                {"goal": 4, "leverage": 2, "time": 10,
                 "probability": 10, "learning": 1, "cost": 10},
                [f"dirty files: {', '.join(g.get('dirty_files', [])[:5])}"], 14))

        if not p.get("remote") and priority >= 4:
            out.append(candidate(
                p, "leverage", f"Publish {p['name']} as a public artifact",
                "No remote means no one can see or reuse the work; a public artifact is leverage.",
                "A public repository or write-up with a working quickstart.",
                "Decide the artifact (repo, case study, demo), create the remote, publish.",
                "dm-write", "M", "standard",
                {"goal": clamp(priority * 2), "leverage": 9, "time": 6,
                 "probability": 7, "learning": 5, "cost": 6},
                ["no git remote"], 60))

        if p.get("todos", 0) > 40:
            out.append(candidate(
                p, "maintain", f"Triage {p['todos']} TODO markers in {p['name']}",
                "A large TODO count hides the real backlog and inflates the diff.",
                "Every TODO is deleted, turned into an issue, or scheduled.",
                "Group by file, delete stale ones, open issues for the rest.",
                "none", "S", "standard",
                {"goal": 3, "leverage": 3, "time": 7,
                 "probability": 10, "learning": 1, "cost": 9},
                [f"{p['todos']} TODO/FIXME markers"], 30))

    for c in out:
        c["score"] = score_of(c["scores"], weights)
    return out


def from_seeds(ops, weights):
    seeds = read_json(ops / "seeds.json", [])
    out = []
    for s in seeds:
        c = candidate(
            {"name": s.get("project", "career"), "priority": 4},
            s.get("category", "explore"), s["title"], s.get("why_now", ""),
            s.get("outcome", ""), s.get("first_action", ""), s.get("skill", "dm-router"),
            s.get("effort", "M"), s.get("model", "standard"), s.get("scores"),
            s.get("evidence", []), s.get("expires_days", 60), "seed", s.get("key"))
        c["prompt"] = s.get("prompt", "")
        c["score"] = score_of(c["scores"], weights)
        out.append(c)
    return out


def load_previous(ops):
    state = read_json(ops / "backlog" / "state.json", {"items": []})
    return {it["key"]: it for it in state.get("items", []) if it.get("key")}


def merge(prev, candidates, config):
    decay = float(config.get("carry_decay_per_week", 0.97))
    stale_weeks = int(config.get("stale_after_weeks", 4))
    today = date.today()
    merged = []
    for c in candidates:
        old = prev.get(c["key"])
        if old:
            c["id"] = old.get("id") or c.get("id")
            c["first_seen"] = old.get("first_seen") or today.isoformat()
            c["status"] = old.get("status", "open")
            c["claimed_at"] = old.get("claimed_at")
            c["claimed_by"] = old.get("claimed_by")
            c["source"] = old.get("source", c.get("source"))
            age_weeks = max(0, (today - date.fromisoformat(c["first_seen"])).days // 7)
            c["age_weeks"] = age_weeks
            if c["status"] == "open":
                c["score"] = round(c["score"] * (decay ** age_weeks), 1)
                if age_weeks >= stale_weeks:
                    c["status"] = "stale"
        else:
            c["first_seen"] = today.isoformat()
            c["status"] = "open"
            c["age_weeks"] = 0
        c["expires"] = (date.fromisoformat(c["first_seen"]) +
                        timedelta(days=int(c.get("expires_days", 60)))).isoformat()
        if c["status"] == "open" and c["expires"] < today.isoformat():
            c["status"] = "expired"
        merged.append(c)

    # Carried items that the inventory no longer generates: keep them if open,
    # decayed, so a real opportunity does not vanish because a signal changed.
    keys = {c["key"] for c in merged}
    for key, old in prev.items():
        if key in keys or old.get("status") in ("done", "dropped"):
            continue
        if old.get("status") not in ("open", "claimed", "stale"):
            continue
        old = dict(old)
        age_weeks = max(0, (today - date.fromisoformat(old.get("first_seen", today.isoformat()))).days // 7)
        old["age_weeks"] = age_weeks
        if old.get("status") == "open":
            old["score"] = round(float(old.get("score", 5)) * (decay ** age_weeks), 1)
            if age_weeks >= stale_weeks:
                old["status"] = "stale"
        merged.append(old)

    # Deduplicate by key, keep the highest score.
    best = {}
    for c in merged:
        if c["key"] not in best or c["score"] > best[c["key"]]["score"]:
            best[c["key"]] = c
    merged = list(best.values())

    # Rank, then assign stable IDs to new items in rank order.
    merged.sort(key=lambda c: (c.get("status") != "open", -c["score"], -c["scores"].get("time", 5)))
    stamp = today.strftime("%Y%m%d")
    n = 0
    for c in merged:
        if not c.get("id"):
            n += 1
            c["id"] = f"OPP-{stamp}-{n:02d}"
    return merged


def item_md(c):
    scores = c["scores"]
    return f"""<!-- generated by dm-portfolio; edits above the prompt survive nothing -->
# {c['id']} — {c['title']}

| Field | Value |
|---|---|
| Project | `{c['project']}` |
| Category | `{c['category']}` |
| Score | **{c['score']}** (goal {scores.get('goal')}, leverage {scores.get('leverage')}, time {scores.get('time')}, probability {scores.get('probability')}, learning {scores.get('learning')}, cost {scores.get('cost')}) |
| Effort | {c['effort']} (agent-days) |
| Skill | `{c['skill']}` |
| Model tier | {c['model']} |
| Status | {c['status']} |
| First seen | {c['first_seen']} |
| Expires | {c['expires']} |

## Why now

{c['why_now']}

## Outcome (done when)

{c['outcome']}

## First action

{c['first_action']}

## Evidence

{chr(10).join('- ' + e for e in c.get('evidence', [])) or '- none recorded'}

## Risks

- Starting without the named evidence turns this into a guess.
- If the outcome cannot be observed by someone else, it is not done.

## Initiating prompt

```text
{prompt_for(c)}
```
"""


def index_md(items, today, capacity=8):
    rows = ["| Rank | ID | Project | Category | Title | Score | Effort | Days | Load | Skill | Model | Status | Initiating prompt |",
            "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    rank = 0
    load = 0.0
    for c in items:
        if c["status"] in ("done", "dropped", "expired"):
            continue
        rank += 1
        days = EFFORT_DAYS.get(c.get("effort", "M"), 2)
        load = round(load + days, 1)
        mark = "†" if load > capacity else ""
        prompt_line = (c.get("prompt") or c["title"]).splitlines()[0].replace("|", "/")[:58]
        rows.append(f"| {rank} | [{c['id']}]({c['id']}.md) | {c['project']} | {c['category']} | "
                    f"{c['title']} | **{c['score']}** | {c['effort']} | {days} | {load}{mark} | "
                    f"`{c['skill']}` | {c['model']} | {c['status']} | {prompt_line} |")
    open_items = [c for c in items if c["status"] == "open"]
    top = open_items[0] if open_items else None
    head = [f"# Portfolio backlog — {today}", "",
            f"{len(open_items)} open · {sum(1 for c in items if c['status']=='claimed')} claimed · "
            f"{sum(1 for c in items if c['status']=='stale')} stale", ""]
    if top:
        head += [f"**Next:** [{top['id']}]({top['id']}.md) — {top['title']} (score {top['score']}, {top['effort']}). "
                 f"Claim it with `dm-portfolio pick`.", ""]
    head += [f"Capacity: {capacity} agent-days/week. **†** marks the queue past this week's capacity.", ""]
    return "\n".join(head + rows) + "\n"


def next_md(items, today):
    open_items = [c for c in items if c["status"] == "open"]
    if not open_items:
        return f"# Next — {today}\n\nNo open item. Run `dm-portfolio review` to generate one.\n"
    c = open_items[0]
    return f"""# Next — {today}

**{c['id']} — {c['title']}** · score {c['score']} · {c['effort']} · `{c['skill']}`

## Work order

- **Project:** `{c['project']}`
- **Outcome:** {c['outcome']}
- **First action:** {c['first_action']}
- **Done when:** {c['outcome']}
- **Constraints:** stay inside the project; no new paid services; stop at the first human gate.

## Initiating prompt

```text
{prompt_for(c)}
```

Claim it with `dm-portfolio pick {c['id']}`.
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ops", required=True)
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()
    ops = Path(args.ops).expanduser().resolve()
    config = read_json(ops / "config.json", {})
    weights = config.get("weights", {"goal": 30, "leverage": 20, "time": 15,
                                     "probability": 15, "learning": 10, "cost": 10})
    inv = read_json(ops / "inventory" / "latest.json", {"projects": []})
    projects = read_json(ops / "projects.json", {}).get("projects", [])
    pmap = {p["name"]: p for p in projects}
    for p in inv.get("projects", []):
        pmap.setdefault(p["name"], p)

    candidates = from_inventory(inv, weights) + from_seeds(ops, weights)
    # A seed is a human- or agent-curated version of the same work; prefer it
    # over the deterministic item for the same project and category.
    seed_pairs = {(c["project"], c["category"]) for c in candidates if c.get("source") == "seed"}
    candidates = [c for c in candidates
                  if not (c.get("source") == "deterministic" and (c["project"], c["category"]) in seed_pairs)]
    # A seed that ships a project already makes it public; drop the separate
    # "publish as a public artifact" item for that project.
    seed_ship = {c["project"] for c in candidates
                 if c.get("source") == "seed" and c["category"] == "ship"}
    candidates = [c for c in candidates
                  if not (c.get("source") == "deterministic" and c["category"] == "leverage"
                          and c["project"] in seed_ship)]
    # Attach the registry priority to seeds so goal scores can be recomputed.
    for c in candidates:
        p = pmap.get(c["project"])
        if p and c.get("source") == "seed" and "goal" not in (c.get("scores") or {}):
            c["scores"]["goal"] = clamp(p.get("priority", 3) * 2)
            c["score"] = score_of(c["scores"], weights)

    items = merge(load_previous(ops), candidates, config)
    for c in items:
        c["prompt"] = prompt_for(c)

    backlog = ops / "backlog"
    backlog.mkdir(parents=True, exist_ok=True)
    limit = args.limit or int(config.get("max_backlog_items", 12))
    open_items = [c for c in items if c["status"] in ("open", "claimed", "stale")][:limit]
    keep = {c["id"] for c in open_items}
    for c in items:
        if c["id"] not in keep:
            continue
        path = backlog / f"{c['id']}.md"
        if not path.exists() or c["status"] == "open" and c["first_seen"] == date.today().isoformat():
            path.write_text(item_md(c), encoding="utf-8")

    today = date.today().isoformat()
    (backlog / "INDEX.md").write_text(index_md(open_items, today, float(config.get("capacity_agent_days_per_week", 8))), encoding="utf-8")
    (backlog / "NEXT.md").write_text(next_md(open_items, today), encoding="utf-8")
    state = {"generated": datetime.now().isoformat(timespec="seconds"), "items": items}
    (backlog / "state.json").write_text(json.dumps(state, indent=1), encoding="utf-8")

    top = next((c for c in open_items if c["status"] == "open"), None)
    print(json.dumps({
        "open": sum(1 for c in open_items if c["status"] == "open"),
        "claimed": sum(1 for c in open_items if c["status"] == "claimed"),
        "stale": sum(1 for c in open_items if c["status"] == "stale"),
        "top": f"{top['id']} {top['title']} ({top['score']})" if top else None,
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
