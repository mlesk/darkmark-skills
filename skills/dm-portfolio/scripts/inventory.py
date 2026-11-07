#!/usr/bin/env python3
"""inventory.py — deterministic evidence snapshot for dm-portfolio.

Usage:
  inventory.py --ops DIR [--out DIR] [--no-gh]

Reads ops/projects.json, inspects each project, and writes
inventory/YYYY-MM-DD.json and .md. Read-only: it never changes a project.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import date, datetime, timezone
from pathlib import Path

GIT_TIMEOUT = 12
GH_TIMEOUT = 20
TODO_TIMEOUT = 20


def run(cmd, cwd=None, timeout=GIT_TIMEOUT):
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True,
                           timeout=timeout, errors="replace")
        return p.returncode, p.stdout.strip(), p.stderr.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError) as exc:
        return 124, "", str(exc)


def git(repo, *args, timeout=GIT_TIMEOUT):
    return run(["git", "-C", str(repo), *args], timeout=timeout)


def read_text(path, limit=20000):
    try:
        return Path(path).read_text(encoding="utf-8", errors="replace")[:limit]
    except OSError:
        return ""


def default_branch(repo):
    for cand in ("main", "master"):
        rc, _, _ = git(repo, "show-ref", "--verify", "--quiet", f"refs/heads/{cand}")
        if rc == 0:
            return cand
    rc, out, _ = git(repo, "symbolic-ref", "--short", "refs/remotes/origin/HEAD")
    if rc == 0 and out:
        return out.rsplit("/", 1)[-1]
    return ""


def parse_state(path):
    text = read_text(path, 12000)
    fields = {}
    for line in text.splitlines()[:70]:
        m = re.match(r"^([a-z][a-z-]*):\s*(.*)$", line)
        if m and m.group(1) not in fields:
            fields[m.group(1)] = m.group(2).strip()
    phases = [l for l in text.splitlines() if l.startswith("| PHASE-")]
    done = sum(1 for l in phases if re.search(r"\|\s*done\s*\|", l, re.I))
    return {
        "stage": fields.get("stage", ""),
        "status": fields.get("status", ""),
        "next_action": fields.get("next-action", ""),
        "kind": fields.get("kind", ""),
        "size": fields.get("size", ""),
        "mode": fields.get("mode", ""),
        "halt": fields.get("halt", ""),
        "phases": len(phases),
        "phases_done": done,
        "updated": datetime.fromtimestamp(os.path.getmtime(path), timezone.utc)
                   .strftime("%Y-%m-%dT%H:%M:%SZ") if os.path.exists(path) else "",
    }


def latest_sweep(repo):
    inbox = Path(repo) / ".agent" / "inbox"
    if not inbox.is_dir():
        return {}
    files = sorted(inbox.glob("*.md"))
    if not files:
        return {}
    text = read_text(files[-1], 4000)
    health = re.search(r"\*\*(GREEN|AMBER|RED)\*\*", text)
    decisions = re.search(r"·\s*(\d+)\s+decision", text)
    return {
        "file": str(files[-1]),
        "health": health.group(1) if health else "",
        "decisions": int(decisions.group(1)) if decisions else None,
    }


def deploy_signals(repo):
    repo = Path(repo)
    names = ["wrangler.toml", "wrangler.jsonc", "fly.toml", "vercel.json",
             "netlify.toml", "Dockerfile", "Procfile", "render.yaml"]
    found = [n for n in names if (repo / n).exists()]
    wf = repo / ".github" / "workflows"
    if wf.is_dir():
        for f in wf.glob("*.y*ml"):
            t = read_text(f, 4000).lower()
            if "deploy" in t or "publish" in t or "pages" in t:
                found.append(f".github/workflows/{f.name}")
    pkg = repo / "package.json"
    if pkg.exists():
        try:
            scripts = json.loads(read_text(pkg)).get("scripts", {})
            found += [f"script:{k}" for k in scripts if k in ("deploy", "publish", "release")]
        except (json.JSONDecodeError, OSError):
            pass
    return found


def test_command(repo):
    repo = Path(repo)
    pkg = repo / "package.json"
    if pkg.exists():
        try:
            scripts = json.loads(read_text(pkg)).get("scripts", {})
            if "test" in scripts:
                return "npm test"
        except (json.JSONDecodeError, OSError):
            pass
    if (repo / "pyproject.toml").exists() or (repo / "pytest.ini").exists() or (repo / "tests").is_dir():
        return ".venv/bin/python -m pytest -q" if (repo / ".venv" / "bin" / "python").exists() else "python3 -m pytest -q"
    if (repo / "Cargo.toml").exists():
        return "cargo test"
    if (repo / "go.mod").exists():
        return "go test ./..."
    return ""


def gh_json(repo, args):
    if not shutil.which("gh"):
        return []
    rc, out, _ = run(["gh", *args, "--limit", "20"], cwd=repo, timeout=GH_TIMEOUT)
    if rc != 0 or not out:
        return []
    try:
        data = json.loads(out)
        return data if isinstance(data, list) else []
    except json.JSONDecodeError:
        return []


def collect(project):
    repo = Path(project["path"])
    info = {
        "name": project["name"],
        "path": str(repo),
        "role": project.get("role", ""),
        "priority": project.get("priority", 3),
        "stage": project.get("stage", ""),
        "users": project.get("users", 0),
        "deploy_url": project.get("deploy_url"),
        "public": project.get("public", False),
        "notes": project.get("notes", ""),
        "exists": repo.is_dir(),
        "git": {}, "readme": {}, "deploy": {}, "tests": {},
        "runs": [], "todos": 0, "prs": [], "issues": [], "remote": "",
    }
    if not repo.is_dir():
        return info

    rc, out, _ = git(repo, "rev-parse", "--show-toplevel")
    info["is_git"] = rc == 0
    if rc != 0:
        return info

    branch = git(repo, "branch", "--show-current")[1]
    rc, raw, _ = git(repo, "status", "--porcelain")
    dirty_files = [l[3:] for l in raw.splitlines() if l.strip()] if rc == 0 else []
    last_rc, last, _ = git(repo, "log", "-1", "--format=%h|%cs|%s")
    last_parts = last.split("|", 2) if last_rc == 0 and last else ["", "", ""]
    age = ""
    if last_parts[1]:
        try:
            d = datetime.strptime(last_parts[1], "%Y-%m-%d").date()
            age = (date.today() - d).days
        except ValueError:
            pass
    commits_14 = git(repo, "rev-list", "--count", "--since=14.days", "HEAD")[1]
    unpushed = 0
    if git(repo, "rev-parse", "--abbrev-ref", "@{u}")[0] == 0:
        try:
            unpushed = int(git(repo, "rev-list", "--count", "@{u}..HEAD")[1] or 0)
        except ValueError:
            pass
    default = default_branch(repo)
    unmerged = []
    if default:
        rc, out, _ = git(repo, "branch", "--no-merged", default,
                         "--format=%(refname:short)|%(committerdate:short)|%(subject)")
        if rc == 0:
            for line in out.splitlines():
                if not line.strip():
                    continue
                name, when, subj = (line.split("|", 2) + ["", ""])[:3]
                if name != default:
                    unmerged.append({"branch": name, "date": when, "subject": subj[:100]})
    remote = git(repo, "remote", "get-url", "origin")[1]
    info["remote"] = remote
    info["git"] = {
        "branch": branch,
        "dirty": len(dirty_files),
        "dirty_files": dirty_files[:10],
        "last_commit": {"hash": last_parts[0], "date": last_parts[1], "subject": last_parts[2][:120]},
        "last_age_days": age,
        "commits_14d": int(commits_14) if commits_14.isdigit() else None,
        "unpushed": unpushed,
        "default_branch": default,
        "unmerged_branches": unmerged,
    }

    readme = repo / "README.md"
    text = read_text(readme, 8000)
    heading = next((l[2:].strip() for l in text.splitlines() if l.startswith("# ")), "")
    info["readme"] = {
        "exists": readme.exists(),
        "heading": heading,
        "excerpt": re.sub(r"\s+", " ", text[:600]).strip(),
        "urls": re.findall(r"https?://[^\s)>\]]+", text)[:5],
    }

    info["deploy"] = {
        "signals": deploy_signals(repo),
        "has_url": bool(project.get("deploy_url")),
    }
    info["tests"] = {"command": test_command(repo), "sweep": latest_sweep(repo)}
    runs_dir = repo / ".agent-team" / "runs"
    if runs_dir.is_dir():
        for state in sorted(runs_dir.glob("*/state.md")):
            run_info = {"name": state.parent.name}
            run_info.update(parse_state(state))
            info["runs"].append(run_info)

    rc, out, _ = git(repo, "grep", "-nEI", "TODO|FIXME|HACK|XXX", "--", ".",
                     timeout=TODO_TIMEOUT)
    info["todos"] = len(out.splitlines()) if rc in (0, 1) else 0

    if info["remote"] and shutil.which("gh"):
        info["prs"] = gh_json(repo, ["pr", "list", "--json", "number,title,isDraft,updatedAt"])
        info["issues"] = gh_json(repo, ["issue", "list", "--json", "number,title,labels,updatedAt"])
    return info


def md_summary(data):
    rows = ["| Project | Branch | Dirty | Last commit | Runs | Sweep | Deploy |",
            "|---|---|---|---|---|---|---|"]
    for p in data["projects"]:
        if not p.get("exists"):
            rows.append(f"| {p['name']} | MISSING | – | – | – | – | – |")
            continue
        g = p.get("git", {})
        runs = ", ".join(f"{r['name']} ({r.get('status') or '?'})" for r in p.get("runs", [])) or "–"
        sweep = (p.get("tests", {}).get("sweep") or {}).get("health") or "–"
        deploy = ", ".join(p.get("deploy", {}).get("signals", [])) or ("url" if p.get("deploy_url") else "none")
        last = g.get("last_commit", {})
        rows.append(f"| {p['name']} | {g.get('branch','')} | {g.get('dirty',0)} | "
                    f"{last.get('date','')} {last.get('hash','')} | {runs} | {sweep} | {deploy} |")
    return "\n".join(rows)


def md_detail(data):
    out = []
    for p in data["projects"]:
        out.append(f"\n## {p['name']}\n")
        if not p.get("exists"):
            out.append("Path missing.\n")
            continue
        g = p.get("git", {})
        out.append(f"- role: {p['role']} · priority {p['priority']} · users {p['users']} · public {p['public']}")
        out.append(f"- branch: `{g.get('branch','')}` · dirty {g.get('dirty',0)} · unpushed {g.get('unpushed',0)} · commits(14d) {g.get('commits_14d')}")
        out.append(f"- last: {g.get('last_commit',{}).get('date','')} {g.get('last_commit',{}).get('subject','')}")
        if g.get("unmerged_branches"):
            out.append("- unmerged: " + ", ".join(b["branch"] for b in g["unmerged_branches"]))
        out.append(f"- tests: `{p.get('tests',{}).get('command','') or 'none'}` · sweep {p.get('tests',{}).get('sweep',{}).get('health','–')}")
        out.append(f"- deploy: {', '.join(p.get('deploy',{}).get('signals',[])) or 'none'}")
        out.append(f"- todos: {p.get('todos',0)}")
        for r in p.get("runs", []):
            out.append(f"- run `{r['name']}`: {r.get('stage','')} · {r.get('status','')} · {r.get('phases_done',0)}/{r.get('phases',0)} phases · {r.get('next_action','')[:140]}")
        if p.get("prs"):
            out.append("- PRs: " + "; ".join(f"#{x.get('number')} {x.get('title')}" for x in p["prs"]))
        if p.get("issues"):
            out.append("- issues: " + "; ".join(f"#{x.get('number')} {x.get('title')}" for x in p["issues"]))
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ops", required=True)
    ap.add_argument("--out", default="")
    ap.add_argument("--no-gh", action="store_true")
    args = ap.parse_args()

    ops = Path(args.ops).expanduser().resolve()
    registry = json.loads(read_text(ops / "projects.json"))
    projects = registry.get("projects", [])
    if registry.get("planning"):
        projects = projects + [registry["planning"]]
    projects = [p for p in projects if not p.get("exclude_from_candidates")]
    data = {
        "generated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "ops": str(ops),
        "projects": [collect(p) for p in projects],
    }
    data["summary"] = {
        "projects": len(data["projects"]),
        "accessible": sum(1 for p in data["projects"] if p.get("is_git")),
        "dirty": sum(1 for p in data["projects"] if p.get("git", {}).get("dirty", 0) > 0),
        "unmerged_branches": sum(len(p.get("git", {}).get("unmerged_branches", [])) for p in data["projects"]),
        "runs": sum(len(p.get("runs", [])) for p in data["projects"]),
        "deployable_undeployed": sum(1 for p in data["projects"] if p.get("deploy", {}).get("signals") and not p.get("deploy_url")),
    }

    outdir = Path(args.out).expanduser().resolve() if args.out else ops / "inventory"
    outdir.mkdir(parents=True, exist_ok=True)
    stamp = date.today().isoformat()
    (outdir / f"{stamp}.json").write_text(json.dumps(data, indent=1), encoding="utf-8")
    md = [f"# Inventory — {stamp}", "", f"Generated `{data['generated']}`", "", md_summary(data), md_detail(data)]
    (outdir / f"{stamp}.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    (outdir / "latest.json").write_text(json.dumps(data, indent=1), encoding="utf-8")
    (outdir / "latest.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print(json.dumps(data["summary"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
