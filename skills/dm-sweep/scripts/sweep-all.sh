#!/usr/bin/env bash
set -uo pipefail

# sweep-all.sh — run sweep.sh over every project in the config and write one
# morning digest.
#
# Usage:
#   sweep-all.sh [--dry-run] [--no-tests] [--config FILE]
#
# Config: ~/.config/dm-sweep/projects, one absolute path per line, # comments.
# Digest: ~/.local/share/dm-sweep/latest.md (and a dated copy).
# Exit: 0 all green/amber · 2 any red · 3 usage/config.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/dm-sweep/projects"
STATE="${XDG_DATA_HOME:-$HOME/.local/share}/dm-sweep"
DRY=""; NOTEST=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY="--dry-run"; shift ;;
    --no-tests) NOTEST="--no-tests"; shift ;;
    --config) CONFIG="$2"; shift 2 ;;
    -h|--help) sed -n '4,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 3 ;;
  esac
done
mkdir -p "$STATE"
if [[ ! -f "$CONFIG" ]]; then
  echo "sweep-all: no config at $CONFIG" >&2
  echo "Create it with one absolute project path per line." >&2
  exit 3
fi

# One run at a time; break a stale lock whose PID is gone or older than 6 hours.
LOCK="$STATE/.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  pid="$(cat "$LOCK/pid" 2>/dev/null || true)"
  if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
    rm -rf "$LOCK"
    mkdir "$LOCK" 2>/dev/null || { echo "sweep-all: cannot take the lock" >&2; exit 3; }
  elif [[ -n "$(find "$LOCK" -maxdepth 0 -mmin +360 2>/dev/null)" ]]; then
    rm -rf "$LOCK"
    mkdir "$LOCK" 2>/dev/null || { echo "sweep-all: locked" >&2; exit 3; }
  else
    echo "sweep-all: another sweep is running (pid ${pid:-unknown})" >&2
    exit 3
  fi
fi
echo $$ > "$LOCK/pid"

# Keep the machine awake for the length of the run. The plist runs bash directly
# so that Full Disk Access has one clear target: /bin/bash.
CAFF=""
if command -v caffeinate >/dev/null 2>&1; then
  caffeinate -i -s -w $$ &
  CAFF=$!
fi
trap 'kill "$CAFF" 2>/dev/null || true; rm -rf "$LOCK" 2>/dev/null || true' EXIT

TODAY="$(date +%Y-%m-%d)"
OUT="$STATE/digest-$TODAY.md"
RED=0
ROWS="$(mktemp)"; BODY="$(mktemp)"
trap 'rm -f "$ROWS" "$BODY"; rmdir "$LOCK" 2>/dev/null || true' EXIT

while IFS= read -r line; do
  line="${line%%#*}"; line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -z "$line" ]] && continue
  res="$("$HERE/sweep.sh" --project "$line" $DRY $NOTEST 2>/dev/null)"
  health="$(printf '%s' "$res" | awk -F'\t' '/^SWEEP/{print $2}')"
  ndec="$(printf '%s' "$res" | awk -F'\t' '/^SWEEP/{print $3}')"
  file="$(printf '%s' "$res" | awk -F'\t' '/^SWEEP/{print $4}')"
  [[ -z "$health" ]] && health="MISSING"
  [[ "$health" == "RED" || "$health" == "ERROR" || "$health" == "MISSING" ]] && RED=1
  printf '| %s | %s | %s | `%s` |\n' "$(basename "$line")" "$health" "${ndec:-–}" "${file:-–}" >> "$ROWS"
  if [[ "$health" == "MISSING" ]]; then
    {
      echo "### $(basename "$line")"
      echo "1. [access] cannot read \`$line\` — grant Full Disk Access to /bin/bash (System Settings → Privacy & Security → Full Disk Access), then rerun."
      echo
    } >> "$BODY"
  elif [[ -f "$file" ]]; then
    echo "### $(basename "$line")" >> "$BODY"
    awk '/^## Needs a decision/{f=1;next} /^## /{f=0} f && NF' "$file" | head -6 >> "$BODY"
    echo >> "$BODY"
  fi
done < "$CONFIG"

{
  echo "# Morning sweep — $TODAY"
  echo
  echo "Generated $(date '+%H:%M'). Read this, answer at most five decisions, close it."
  echo
  echo "| Project | Health | Decisions | Digest |"
  echo "|---|---|---|---|"
  cat "$ROWS"
  echo
  echo "## Decisions"
  echo
  if [[ -s "$BODY" ]]; then cat "$BODY"; else echo "Nothing needs you."; fi
  echo "---"
  echo "_Open a project digest for details. Nothing here has been changed automatically._"
} > "$OUT"
cp "$OUT" "$STATE/latest.md"

echo "DIGEST $OUT"
[[ "$RED" -eq 1 ]] && exit 2
exit 0
