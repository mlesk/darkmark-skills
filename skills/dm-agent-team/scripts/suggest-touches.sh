#!/usr/bin/env bash
set -uo pipefail

# suggest-touches.sh — brownfield helper (V003 retro R6). Lists the baseline
# test files that pin a string literal the diff removes, so a phase can name
# them in touches: (and behaviour-changes:) before precheck check 6 blocks it.
#
# Usage:
#   suggest-touches.sh --workdir DIR --base SHA --baseline SHA [--head REV] [--tests GLOB]
#
# --base/--head: the diff to inspect (head defaults to the working tree).
# --baseline: the commit whose test files count as baseline tests.
# --tests: a git pathspec for test files (default 'src/tests/*.test.ts').
# Prints one path per line (sorted, unique); exit 0 always unless arguments are bad.
# Changed text: 24-character windows of removed non-test lines absent from added ones.

WORKDIR="" BASE="" BASELINE="" HEAD="" TESTS='src/tests/*.test.ts'
usage() { sed -n '4,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 2; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --baseline) BASELINE="$2"; shift 2 ;;
    --head) HEAD="$2"; shift 2 ;;
    --tests) TESTS="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done
[[ -n "$WORKDIR" && -n "$BASE" && -n "$BASELINE" ]] || usage
cd "$WORKDIR" || exit 2

range=("$BASE"); [[ -n "$HEAD" ]] && range=("$BASE" "$HEAD")
# ls-tree does not expand globs: list everything and match the glob in bash.
baseline_tests=$(git ls-tree -r --name-only "$BASELINE" | while IFS= read -r f; do [[ $f == $TESTS ]] && echo "$f"; done)
[[ -n "$baseline_tests" ]] || exit 0

# Changed text: 24-character windows of removed non-test lines that do not
# occur in any added line (so an insertion inside a string still shows).
diff=$(git diff -U0 "${range[@]}" -- . ":(exclude)$TESTS" ":(exclude).agent-team")
literals=$(LC_ALL=C awk -v W=24 '
  /^\+\+\+|^---/ {next}
  /^\+/ {added=added "\n" substr($0,2); next}
  /^-/   {del[++nd]=substr($0,2)}
  END {
    for (i=1;i<=nd;i++) { s=del[i]; gsub(/^[ \t]+/,"",s)
      for (j=1;j+W-1<=length(s);j++) { w=substr(s,j,W)
        if (w ~ /^[ \t]*$/ || seen[w]++) continue
        if (!index(added,w)) print w } } }' <<<"$diff")
[[ -n "$literals" ]] || exit 0

tmp=$(mktemp); printf '%s\n' "$literals" > "$tmp"
# Search each baseline test as it was at --base: the pin the phase breaks is the
# old text, even after the builder has already edited the test.
# (Matching in Python: BSD grep -F -f with thousands of patterns takes seconds a file.)
dir=$(mktemp -d)
for f in $baseline_tests; do
  { git show "$BASE:$f" 2>/dev/null; [[ -f "$f" ]] && cat "$f"; } > "$dir/$(printf '%s' "$f" | tr '/' '%')"
done
python3 - "$tmp" "$dir" <<'PY' | sort -u
import os, sys
pats = [p for p in open(sys.argv[1], "rb").read().split(b"\n") if p]
for name in os.listdir(sys.argv[2]):
    text = open(os.path.join(sys.argv[2], name), "rb").read()
    if any(p in text for p in pats):
        print(name.replace("%", "/"))
PY
rm -rf "$tmp" "$dir"
