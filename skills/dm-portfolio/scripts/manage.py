#!/usr/bin/env python3
"""manage.py — claim, close, and inspect portfolio backlog items.

Usage:
  manage.py status [--ops DIR]
  manage.py pick [ID] [--ops DIR] [--by NAME]
  manage.py close ID --outcome shipped|dropped|blocked|parked [--note TEXT] [--ops DIR]

`pick` marks the item claimed and writes picked/<ID>.md, then prints the
initiating prompt. `close` archives the item with the outcome. Neither starts
any work.
"""
import argparse
import json
import sys
from datetime import datetime
from pathlib import Path


def read_json(path, default):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return default


def write_json(path, data):
    Path(path).write_text(json.dumps(data, indent=1), encoding="utf-8")


def load(ops):
    return read_json(ops / "backlog" / "state.json", {"items": []})


def save(ops, state):
    write_json(ops / "backlog" / "state.json", state)


def status(ops):
    state = load(ops)
    items = state.get("items", [])
    rows = [("Rank", "ID", "Score", "Status", "Project", "Title")]
    rank = 0
    for c in sorted(items, key=lambda x: (x.get("status") != "open", -float(x.get("score", 0)))):
        if c.get("status") in ("done", "dropped", "expired"):
            continue
        rank += 1
        rows.append((str(rank), c["id"], str(c.get("score", "")), c.get("status", ""),
                     c.get("project", ""), c.get("title", "")[:64]))
    widths = [max(len(r[i]) for r in rows) for i in range(len(rows[0]))]
    for r in rows:
        print("  ".join(v.ljust(widths[i]) for i, v in enumerate(r)).rstrip())
    return 0


def pick(ops, item_id, by):
    state = load(ops)
    items = state.get("items", [])
    candidates = [c for c in items if c.get("status") == "open"]
    if item_id:
        candidates = [c for c in candidates if c["id"] == item_id]
    if not candidates:
        print("No open item to pick. Run `dm-portfolio review` or `weekly.sh` first.", file=sys.stderr)
        return 1
    c = sorted(candidates, key=lambda x: -float(x.get("score", 0)))[0]
    c["status"] = "claimed"
    c["claimed_at"] = datetime.now().isoformat(timespec="seconds")
    c["claimed_by"] = by
    save(ops, state)

    picked = ops / "picked"
    picked.mkdir(parents=True, exist_ok=True)
    out = picked / f"{c['id']}.md"
    out.write_text(f"""# Work order — {c['id']} — {c['title']}

Claimed: {c['claimed_at']} by {c['claimed_by']}
Project: `{c['project']}`
Category: `{c['category']}`
Score: {c['score']} · Effort: {c['effort']} · Skill: `{c['skill']}` · Model: {c['model']}

## Outcome (done when)

{c['outcome']}

## First action

{c['first_action']}

## Why now

{c['why_now']}

## Initiating prompt

```text
{c['prompt']}
```

## Close it

```bash
dm-portfolio close {c['id']} --outcome shipped --note "what shipped"
```
""", encoding="utf-8")
    print(c["prompt"])
    print(f"\n[claimed {c['id']} -> {out}]", file=sys.stderr)
    return 0


def close(ops, item_id, outcome, note):
    state = load(ops)
    items = state.get("items", [])
    match = next((c for c in items if c["id"] == item_id), None)
    if not match:
        print(f"No item {item_id}.", file=sys.stderr)
        return 1
    mapping = {"shipped": "done", "dropped": "dropped",
               "parked": "dropped", "blocked": "blocked"}
    match["status"] = mapping.get(outcome, outcome)
    match["closed_at"] = datetime.now().isoformat(timespec="seconds")
    match["outcome"] = outcome
    match["close_note"] = note
    save(ops, state)

    archive = ops / "archive"
    archive.mkdir(parents=True, exist_ok=True)
    (archive / f"{item_id}.md").write_text(f"""# Closed — {item_id} — {match['title']}

Outcome: **{outcome}**
Closed: {match['closed_at']}
Project: `{match['project']}`
Score at close: {match['score']}
Note: {note or '—'}

## Original outcome

{match['outcome']}

## Prompt

```text
{match['prompt']}
```
""", encoding="utf-8")
    print(f"{item_id} -> {outcome}. Next review will drop it from the index.")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("command", choices=["status", "pick", "close"])
    ap.add_argument("id", nargs="?")
    ap.add_argument("--ops", default="")
    ap.add_argument("--by", default="user")
    ap.add_argument("--outcome", default="shipped")
    ap.add_argument("--note", default="")
    args = ap.parse_args()
    if args.ops:
        ops = Path(args.ops).expanduser()
    else:
        cfg = Path.home() / ".config" / "dm-portfolio" / "ops"
        if cfg.is_file():
            ops = Path(cfg.read_text(encoding="utf-8").strip()).expanduser()
        else:
            ops = Path.home() / "ops"
    ops = ops.resolve()
    if args.command == "status":
        return status(ops)
    if args.command == "pick":
        return pick(ops, args.id, args.by)
    if args.command == "close":
        if not args.id:
            print("close needs an item ID.", file=sys.stderr)
            return 2
        return close(ops, args.id, args.outcome, args.note)
    return 2


if __name__ == "__main__":
    sys.exit(main())
