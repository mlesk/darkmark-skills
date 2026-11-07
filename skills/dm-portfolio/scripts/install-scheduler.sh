#!/usr/bin/env bash
set -euo pipefail

# install-scheduler.sh — install the weekly portfolio refresh on macOS.
#
# Copies the runner to the internal disk (launchd cannot execute scripts from
# an external volume under TCC) and writes a LaunchAgent for Monday 06:00.
#
# Usage:
#   scripts/install-scheduler.sh [--ops DIR] [--hour 6] [--minute 0] [--uninstall]
#
# After install, grant Full Disk Access to /bin/bash if projects live on an
# external volume: System Settings > Privacy & Security > Full Disk Access.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SKILL_DIR="$(cd "$HERE/.." && pwd -P)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/dm-portfolio/bin"
PLIST="$HOME/Library/LaunchAgents/dev.darkmark.dm-portfolio.plist"
LABEL="dev.darkmark.dm-portfolio"
OPS="${DM_PORTFOLIO_OPS:-}"
HOUR=6 MINUTE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ops) OPS="$2"; shift 2 ;;
    --hour) HOUR="$2"; shift 2 ;;
    --minute) MINUTE="$2"; shift 2 ;;
    --uninstall)
      launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
      rm -f "$PLIST"
      echo "Removed $LABEL. The copied runner remains in $DEST."
      exit 0 ;;
    -h|--help) sed -n '4,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$OPS" ]]; then
  if [[ -f "$HOME/.config/dm-portfolio/ops" ]]; then
    OPS="$(tr -d '[:space:]' < "$HOME/.config/dm-portfolio/ops")"
  else
    OPS="$HOME/ops"
  fi
fi
[[ -d "$OPS" ]] || { echo "No ops repo at $OPS" >&2; exit 2; }
OPS="$(cd "$OPS" && pwd -P)"

mkdir -p "$DEST" "$HOME/.config/dm-portfolio" "$HOME/.local/bin" "$(dirname "$PLIST")" "$HOME/Library/Logs"
install -m 755 "$HERE/weekly.sh" "$DEST/weekly.sh"
install -m 755 "$HERE/dm-portfolio" "$DEST/dm-portfolio"
install -m 644 "$HERE/inventory.py" "$DEST/inventory.py"
install -m 644 "$HERE/plan.py" "$DEST/plan.py"
install -m 644 "$HERE/manage.py" "$DEST/manage.py"
install -m 644 "$SKILL_DIR/SKILL.md" "$DEST/SKILL.md"
printf '%s\n' "$OPS" > "$HOME/.config/dm-portfolio/ops"
ln -sf "$DEST/dm-portfolio" "$HOME/.local/bin/dm-portfolio"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$DEST/weekly.sh</string>
    <string>--ops</string>
    <string>$OPS</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key>
    <integer>1</integer>
    <key>Hour</key>
    <integer>$HOUR</integer>
    <key>Minute</key>
    <integer>$MINUTE</integer>
  </dict>
  <key>RunAtLoad</key>
  <false/>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/dm-portfolio.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/dm-portfolio.error.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    <key>HOME</key>
    <string>$HOME</string>
    <key>DM_PORTFOLIO_OPS</key>
    <string>$OPS</string>
  </dict>
  <key>WorkingDirectory</key>
  <string>$HOME</string>
  <key>ProcessType</key>
  <string>Background</string>
  <key>LowPriorityIO</key>
  <true/>
  <key>Nice</key>
  <integer>10</integer>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed $LABEL for Monday $HOUR:$MINUTE."
echo "Ops:    $OPS"
echo "Runner: $DEST/weekly.sh"
echo "CLI:    $HOME/.local/bin/dm-portfolio"
echo "Digest: $OPS/backlog/INDEX.md"
echo
echo "If projects live on an external volume and the weekly run reports MISSING,"
echo "grant Full Disk Access to /bin/bash in System Settings > Privacy & Security."
