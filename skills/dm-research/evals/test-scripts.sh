#!/usr/bin/env bash
set -uo pipefail

# test-scripts.sh — runs ledger.sh, cite-check.sh, and retro.sh against the
# clean fixture (must pass) and against one seeded defect at a time (must fail).
# Usage: evals/test-scripts.sh     Exit 0 when every case behaves.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$HERE/../scripts"
PASSED=0 FAILED=0

fresh() {   # copy the clean fixture into a new research root; print the workspace
  local root; root="$(mktemp -d)/.research"
  mkdir -p "$root" && cp -R "$HERE/fixtures/clean/runs" "$root/"
  echo "$root/runs/R001-fixture"
}
expect() {  # expect <exit> <name> <command...>
  local want="$1" name="$2"; shift 2
  "$@" > /dev/null 2>&1; local got=$?
  if [[ "$got" -eq "$want" ]]; then PASSED=$((PASSED + 1)); echo "ok    $name"
  else FAILED=$((FAILED + 1)); echo "FAIL  $name (exit $got, wanted $want)"; fi
}
edit() { sed -i.bak "$2" "$1" && rm -f "$1.bak"; }

# Clean fixture
W="$(fresh)"
expect 0 "ledger: clean fixture passes"            "$SCRIPTS/ledger.sh" --workspace "$W"
expect 0 "ledger: --check one clean file"          "$SCRIPTS/ledger.sh" --workspace "$W" --check "$W/findings/RQ-001.md"
expect 0 "cite-check: clean fixture passes"        "$SCRIPTS/cite-check.sh" --workspace "$W"
expect 0 "retro: runs on the clean fixture"        "$SCRIPTS/retro.sh" --workspace "$W"
if grep -q $'R001-fixture\tV1\t1' "$W/../../rule-hits.tsv"; then PASSED=$((PASSED + 1)); echo "ok    retro: records the V1 hit"
else FAILED=$((FAILED + 1)); echo "FAIL  retro: V1 hit not in rule-hits.tsv"; fi

# retro.sh counts findings with letter-prefixed IDs (R003 retro: round-2 N1–N4 counted as 0)
W="$(fresh)"; cat > "$W/reviews/report-review-r2.md" <<'REV'
# Review: R001-fixture — round 2
verdict: PASS
## Findings
| # | Severity | Check | Location | Finding | Required fix | Evidence |
|---|---|---|---|---|---|---|
| N1 | minor | V8 | report.md | label | fix | – |
REV
OUT="$("$SCRIPTS/retro.sh" --workspace "$W" 2>/dev/null)"
if grep -q '^| 2 | PASS | 0 | 1 |$' <<<"$OUT" && grep -q $'R001-fixture\tV8\t1' "$W/../../rule-hits.tsv"; then PASSED=$((PASSED + 1)); echo "ok    retro: counts a letter-prefixed finding and its check"
else FAILED=$((FAILED + 1)); echo "FAIL  retro: letter-prefixed finding (N1) not counted"; fi

# ledger.sh seeded defects
W="$(fresh)"; edit "$W/findings/RQ-001.md" 's/| fact | https:\/\/example.com\/a\/pricing | 2026-10-17 | "4 vCPU, 16 GB RAM — $380 per month" |/| fact | https:\/\/example.com\/a\/pricing | 2026-10-17 | – |/'
expect 1 "ledger: a fact without a quote"          "$SCRIPTS/ledger.sh" --workspace "$W"
W="$(fresh)"; edit "$W/findings/RQ-001.md" 's/| RQ001-C02 | Provider B lists the same tier at $420\/month | fact |/| RQ001-C02 | Provider B lists the same tier at $420\/month | rumour |/'
expect 1 "ledger: an unknown kind"                 "$SCRIPTS/ledger.sh" --workspace "$W"
W="$(fresh)"; edit "$W/findings/RQ-001.md" '/^RQ001-C03:/d'
expect 1 "ledger: an estimate without derivation"  "$SCRIPTS/ledger.sh" --workspace "$W"
W="$(fresh)"; edit "$W/findings/RQ-002.md" 's/| RQ002-C02 |/| RQ001-C09 |/'
expect 1 "ledger: an ID from another question"     "$SCRIPTS/ledger.sh" --workspace "$W"
W="$(fresh)"; edit "$W/findings/RQ-002.md" 's/medium: survey of 120 teams, single-source/medium/'
expect 1 "ledger: a confidence without a reason"   "$SCRIPTS/ledger.sh" --workspace "$W"
W="$(fresh)"; edit "$W/findings/RQ-002.md" 's/2026-10-16/last week/'
expect 1 "ledger: a bad accessed date"             "$SCRIPTS/ledger.sh" --workspace "$W"
W="$(fresh)"; edit "$W/findings/RQ-002.md" 's/searched: [^|]*|/searched: managed Postgres migration service |/'
expect 1 "ledger: a none-found claim from one search" "$SCRIPTS/ledger.sh" --workspace "$W"
W="$(fresh)"; edit "$W/findings/RQ-002.md" 's/^RQ002-A01:/ASM-001:/'
expect 1 "ledger: a researcher using ASM-###"      "$SCRIPTS/ledger.sh" --workspace "$W" --check "$W/findings/RQ-002.md"

# cite-check.sh seeded defects (ledger built first)
seeded() { local w; w="$(fresh)"; "$SCRIPTS/ledger.sh" --workspace "$w" > /dev/null; edit "$w/$1" "$2"; echo "$w"; }
W="$(seeded report.md 's/\[RQ001-C03\]/[RQ001-C08]/')";               expect 1 "cite-check C1: a claim not in the ledger"   "$SCRIPTS/cite-check.sh" --workspace "$W"
W="$(seeded options.md 's/| L-C01 |/| L-C05 |/')";                    expect 1 "cite-check C2: an undefined L-C"           "$SCRIPTS/cite-check.sh" --workspace "$W"
W="$(seeded report.md 's/D-001/D-009/')";                             expect 1 "cite-check C3: an undefined decision"      "$SCRIPTS/cite-check.sh" --workspace "$W"
W="$(seeded options.md 's/OPT-00/OPT-03/g')";                         expect 1 "cite-check C4: no status quo"              "$SCRIPTS/cite-check.sh" --workspace "$W"
W="$(seeded options.md 's/| K-1 | 7 | $380\/month | RQ001-C01, L-C02 |/| K-1 | 7 | cheap | – |/')"; expect 1 "cite-check C5: a score with no citation" "$SCRIPTS/cite-check.sh" --workspace "$W"
W="$(seeded options.md 's/| RQ001-C01, L-C02 |/| RQ001-C01 |/')"; expect 1 "cite-check C8: a K-1 score with no L-C derivation" "$SCRIPTS/cite-check.sh" --workspace "$W"
W="$(seeded options.md 's/| OPT-02 | K-2 budget ceiling | RQ001-C02 |/| OPT-02 | K-2 budget ceiling | pricing page |/')"; expect 1 "cite-check C5: a veto with no citation" "$SCRIPTS/cite-check.sh" --workspace "$W"
W="$(seeded report.md 's/\[RQ001-C02 (low)\]/[RQ001-C02]/')";         expect 1 "cite-check C6: a low claim unlabelled"     "$SCRIPTS/cite-check.sh" --workspace "$W"
W="$(seeded report.md 's/ (single-source)\]/]/')";         expect 1 "cite-check C6: single-source unlabelled"   "$SCRIPTS/cite-check.sh" --workspace "$W"
W="$(seeded report.md 's/\[RQ001-C02 (low)\]/[RQ001-C02] (low)/')"; expect 1 "cite-check C6: a label detached from its ID" "$SCRIPTS/cite-check.sh" --workspace "$W"
W="$(fresh)"; "$SCRIPTS/ledger.sh" --workspace "$W" > /dev/null; for i in $(seq 1 1600); do printf 'word ' >> "$W/report.md"; done
expect 1 "cite-check C7: over the quick word cap"   "$SCRIPTS/cite-check.sh" --workspace "$W"

echo
echo "$PASSED passed, $FAILED failed"
[[ "$FAILED" -eq 0 ]]
