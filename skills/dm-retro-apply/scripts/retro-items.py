#!/usr/bin/env python3
"""retro-items.py — extract actionable items from a dm-agent-team or dm-research retro.

Usage:
  retro-items.py <retro.md> [--json]

Reads the "costliest failures" (or "costliest misses") and "proposed changes"
(or "proposed skill changes") sections and emits
one row per item: id, kind, text, file, line. The file/line is the first
`path:line` or `path (line N)` mentioned in the item, if any.
"""
import json
import re
import sys
from pathlib import Path

PATH_RE = re.compile(
    r"`?([A-Za-z0-9_][A-Za-z0-9_./-]*\.(?:md|sh|py|ts|tsx|js|jsx|json|ya?ml|toml|txt))"
    r"(?::(\d+))?`?"
)
LINE_RE = re.compile(r"~?\s*line\s+(\d+)", re.I)


def sections(lines):
    """Yield (name, body_lines). A heading resets the section."""
    name, body = None, []
    for line in lines:
        if line.startswith("## "):
            if name is not None:
                yield name, body
            name, body = line[3:].strip(), []
        elif name is not None:
            body.append(line)
    if name is not None:
        yield name, body


def items_from(body):
    """Join list items and their indented continuations."""
    out, cur = [], None
    for line in body:
        m = re.match(r"^\s*(?:\d+\.|-)\s+(.*)$", line)
        if m:
            if cur:
                out.append(cur)
            cur = m.group(1).strip()
        elif cur is not None and line.strip() and not line.startswith("#"):
            cur += " " + line.strip()
        elif cur is not None and not line.strip():
            out.append(cur)
            cur = None
    if cur:
        out.append(cur)
    return out


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        return 2
    retro = Path(sys.argv[1])
    as_json = "--json" in sys.argv[2:]
    if not retro.is_file():
        print(f"retro-items: no such file: {retro}", file=sys.stderr)
        return 2

    text = retro.read_text(encoding="utf-8", errors="replace")
    rows = []
    for name, body in sections(text.splitlines()):
        low = name.lower()
        if "costliest failure" in low or "costliest miss" in low:
            kind = "failure"
        elif "proposed change" in low or "proposed skill change" in low:
            kind = "proposal"
        else:
            continue
        for item in items_from(body):
            m = PATH_RE.search(item)
            line = m.group(2) if m else ""
            if not line:
                lm = LINE_RE.search(item)
                line = lm.group(1) if lm else ""
            rows.append({
                "id": f"R{len(rows) + 1}",
                "kind": kind,
                "text": item,
                "file": m.group(1) if m else "",
                "line": line,
            })

    if as_json:
        print(json.dumps(rows, indent=1))
    else:
        print("id\tkind\tfile\tline\titem")
        for r in rows:
            print(f"{r['id']}\t{r['kind']}\t{r['file']}\t{r['line']}\t{r['text']}")
    return 0 if rows else 1


if __name__ == "__main__":
    sys.exit(main())
