#!/usr/bin/env bash
# Regression check for suggest-touches.sh (V003 retro R6), in a throwaway git repo.
# Replays V003's PHASE-F03 block: a link inserted inside the footer string, a
# baseline test pinning the old footer. Exit 0 = all cases pass.
set -uo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(mktemp -d); trap 'rm -rf "$repo"' EXIT
cd "$repo" && git init -q && git config user.email t@t && git config user.name t
mkdir -p src/tests
printf 'export const footer = `<nav><a href="/bookmarks">Saved</a><a href="/skipped">Skipped</a></nav>`;\n' > src/page.ts
printf 'assert.ok(html.includes(%s));\n' "'<a href=\"/bookmarks\">Saved</a><a href=\"/skipped\">Skipped</a>'" > src/tests/footer.test.ts
printf 'assert.equal(1, 1);\n' > src/tests/other.test.ts
git add -A && git commit -qm base && base=$(git rev-parse HEAD)
fails=0
check() { # name expected actual
  if [[ "$2" == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1: expected [$2] got [$3]"; fails=$((fails+1)); fi; }

# 1. Insertion inside a pinned string is found (the PHASE-F03 case).
sed -i.bak 's#Saved</a><a href="/skipped">#Saved</a><a href="/starred">Starred</a><a href="/skipped">#' src/page.ts && rm src/page.ts.bak
check "insertion in pinned markup" "src/tests/footer.test.ts" "$("$here/suggest-touches.sh" --workdir . --base "$base" --baseline "$base")"

# 2. Still found after the builder already updated the test (search uses --base).
sed -i.bak 's#Saved</a><a href="/skipped">#Saved</a><a href="/starred">Starred</a><a href="/skipped">#' src/tests/footer.test.ts && rm src/tests/footer.test.ts.bak
check "after the test was edited" "src/tests/footer.test.ts" "$("$here/suggest-touches.sh" --workdir . --base "$base" --baseline "$base")"

# 3. An unrelated change lists nothing.
git checkout -q -- . && printf 'export const unrelatedValue = 42; // a brand new line\n' >> src/page.ts
check "unrelated change" "" "$("$here/suggest-touches.sh" --workdir . --base "$base" --baseline "$base")"

# 4. Bad arguments exit 2.
"$here/suggest-touches.sh" --workdir . >/dev/null 2>&1; check "bad arguments exit 2" "2" "$?"

exit $fails
