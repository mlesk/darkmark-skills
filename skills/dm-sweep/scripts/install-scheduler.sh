#!/usr/bin/env bash
set -euo pipefail

# install-scheduler.sh — install the nightly sweep on macOS.
#
# Copies the runner to the internal disk (launchd cannot execute scripts from
# an external volume under TCC), writes the LaunchAgent, and loads it.
#
# Usage:
#   scripts/install-scheduler.sh [--hour 2] [--minute 0] [--uninstall]
#
# After install, grant Full Disk Access to /bin/bash if your projects live on
# an external volume: System Settings > Privacy & Security > Full Disk Access.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/dm-sweep/bin"
PLIST="$HOME/Library/LaunchAgents/dev.darkmark.dm-sweep.plist"
LABEL="dev.darkmark.dm-sweep"
HOUR=2 MINUTE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
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

mkdir -p "$DEST" "$(dirname "$PLIST")" "$HOME/Library/Logs"
install -m 755 "$HERE/sweep.sh" "$DEST/sweep.sh"
install -m 755 "$HERE/sweep-all.sh" "$DEST/sweep-all.sh"

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
    <string>$DEST/sweep-all.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>$HOUR</integer>
    <key>Minute</key>
    <integer>$MINUTE</integer>
  </dict>
  <key>RunAtLoad</key>
  <false/>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/dm-sweep.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/dm-sweep.error.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    <key>HOME</key>
    <string>$HOME</string>
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
echo "Installed $LABEL at $HOUR:$MINUTE."
echo "Runner: $DEST/sweep-all.sh"
echo "Digest: ${XDG_DATA_HOME:-$HOME/.local/share}/dm-sweep/latest.md"
echo "Logs:   $HOME/Library/Logs/dm-sweep.log"
echo
echo "If projects live on an external volume and the digest shows MISSING,"
echo "grant Full Disk Access to /bin/bash in System Settings > Privacy & Security."
