#!/usr/bin/env python3
"""lint-skill.py — static checks for agent skills.

Usage:
  lint-skill.py <skill-dir> [<skill-dir> ...]
  lint-skill.py --all <skills-root>      # every <skills-root>/*/SKILL.md, plus
                                         # the README.md next to <skills-root>

Errors (exit 1): missing frontmatter, name/directory mismatch, bad name,
missing or over-long description, broken relative links.
Warnings: long SKILL.md body, repo-local or absolute paths.
With --all, README.md errors: a top-level skill that is not linked, or a
relative link that does not resolve.
"""
import re
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
LINK_RE = re.compile(r"\]\(([^)\s]+)\)")
SIBLING_RE = re.compile(r"`(\.\./[A-Za-z0-9_.\-/]+)`")
SUSPECT_PATHS = [r"\.github/skills/", r"/Users/", r"/home/", r"~/\.claude/skills/"]
MAX_DESC = 1024
MAX_NAME = 64
WARN_LINES = 500
WARN_WORDS = 2500


def parse_frontmatter(text):
    if not text.startswith("---\n"):
        return None, text
    end = text.find("\n---", 4)
    if end == -1:
        return None, text
    raw, body = text[4:end], text[end + 4:]
    fields, key = {}, None
    for line in raw.splitlines():
        m = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            fields[key] = "" if val in (">-", ">", "|", "|-") else val
        elif key and line.startswith((" ", "\t")):
            fields[key] = (fields[key] + " " + line.strip()).strip()
    return fields, body


def lint(skill_dir):
    errors, warnings = [], []
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.is_file():
        return [f"{skill_dir}: no SKILL.md"], []
    text = skill_md.read_text(encoding="utf-8")
    fm, body = parse_frontmatter(text)
    if fm is None:
        errors.append("missing or unterminated YAML frontmatter")
        fm = {}

    name = fm.get("name", "")
    if not name:
        errors.append("frontmatter has no name")
    else:
        if name != skill_dir.name:
            errors.append(f"name '{name}' does not match directory '{skill_dir.name}'")
        if not NAME_RE.match(name) or len(name) > MAX_NAME:
            errors.append(f"name '{name}' must be lowercase-hyphenated and <= {MAX_NAME} chars")

    desc = fm.get("description", "").strip("'\"")
    if not desc:
        errors.append("frontmatter has no description")
    elif len(desc) > MAX_DESC:
        errors.append(f"description is {len(desc)} chars (max {MAX_DESC})")
    elif not re.search(r"\buse (when|for|if|after|before)\b", desc, re.I):
        warnings.append("description has no 'Use when ...' trigger clause")

    lines, words = body.count("\n"), len(body.split())
    if lines > WARN_LINES or words > WARN_WORDS:
        warnings.append(f"SKILL.md body is {lines} lines / {words} words; move detail into references/")

    for md in sorted(skill_dir.rglob("*.md")):
        content = md.read_text(encoding="utf-8")
        rel = md.relative_to(skill_dir)
        targets = [t for t in LINK_RE.findall(content)] + SIBLING_RE.findall(content)
        for target in targets:
            if re.match(r"^[a-z]+:", target) or target.startswith("#"):
                continue
            path = target.split("#", 1)[0]
            if not path or "<" in path:
                continue
            if not (md.parent / path).exists():
                errors.append(f"{rel}: broken link '{target}'")
        for pattern in SUSPECT_PATHS:
            if re.search(pattern, content):
                warnings.append(f"{rel}: contains repo-local or absolute path matching '{pattern}'")
    return errors, warnings


def lint_readme(readme, skill_dirs):
    errors = []
    text = readme.read_text(encoding="utf-8")
    links = LINK_RE.findall(text)
    for target in links:
        if re.match(r"^[a-z]+:", target) or target.startswith("#"):
            continue
        path = target.split("#", 1)[0]
        if path and not (readme.parent / path).exists():
            errors.append(f"broken link '{target}'")
    linked = {(readme.parent / t.split("#", 1)[0]).resolve() for t in links}
    for d in skill_dirs:
        if (d / "SKILL.md").resolve() not in linked:
            errors.append(f"skill '{d.name}' is not linked to its SKILL.md")
    return errors


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__.strip())
        return 0 if argv else 1
    if argv[0] == "--all":
        root = Path(argv[1] if len(argv) > 1 else "skills")
        dirs = sorted(p.parent for p in root.glob("*/SKILL.md"))
    else:
        dirs = [Path(a) for a in argv]

    failed = 0
    for d in dirs:
        errors, warnings = lint(d.resolve())
        status = "FAIL" if errors else "ok"
        print(f"{status:4}  {d.name}")
        for e in errors:
            print(f"      error: {e}")
        for w in warnings:
            print(f"      warn:  {w}")
        failed += bool(errors)
    print(f"\n{len(dirs) - failed}/{len(dirs)} skills passed")

    if argv[0] == "--all":
        readme = root.resolve().parent / "README.md"
        if readme.is_file():
            errors = lint_readme(readme, [d.resolve() for d in dirs])
            print(f"{'FAIL' if errors else 'ok':4}  README.md")
            for e in errors:
                print(f"      error: {e}")
            failed += bool(errors)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
