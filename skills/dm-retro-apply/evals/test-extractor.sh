#!/usr/bin/env bash
set -uo pipefail

# test-extractor.sh — retro-items.py must read both retro formats: dm-agent-team
# ("costliest failures" / "proposed changes") and dm-research ("Costliest misses" /
# "Proposed skill changes"). Usage: evals/test-extractor.sh   Exit 0 when it does.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$(python3 "$HERE/../scripts/retro-items.py" "$HERE/fixtures/dm-research-retro.md")"
if [[ "$(grep -c $'^R[0-9]*\tfailure' <<<"$OUT")" -eq 1 && "$(grep -c $'^R[0-9]*\tproposal' <<<"$OUT")" -eq 2 ]] \
   && grep -q $'\treferences/REPORT.md\t9\t' <<<"$OUT" && grep -q $'\tscripts/retro.sh\t64\t' <<<"$OUT"; then
  echo "ok    extractor: reads a dm-research retro (1 miss, 2 proposals with file and line)"; exit 0
fi
echo "FAIL  extractor: dm-research retro not read"; echo "$OUT"; exit 1
