#!/usr/bin/env bash
set -euo pipefail

# unlink-skills.sh — Remove symlinks created by link-skills.sh from the
# central ~/.agents/skills directory.
#
# Usage:
#   ./scripts/unlink-skills.sh                 # unlink all skills
#   ./scripts/unlink-skills.sh --dry-run        # preview only, no changes
#   ./scripts/unlink-skills.sh --help

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.agents/skills"

DRY_RUN=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
usage() {
  cat <<'EOF'
Usage: unlink-skills.sh [OPTIONS]

Remove symlinks created by link-skills.sh from ~/.agents/skills.
Only symlinks that point into this repository are removed;
regular files, directories, and symlinks pointing elsewhere are left untouched.

Options:
  --dry-run           Print what would be done without making changes.
  --help              Show this message.
EOF
  exit 0
}

warn()  { echo "  ⚠  $*" >&2; }
info()  { echo "  •  $*"; }
ok()    { echo "  ✓  $*"; }

# ---------------------------------------------------------------------------
# Parse CLI
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agents)
      warn "--agents is no longer supported: skills are now unlinked from the central $HOME/.agents/skills directory."
      exit 1
      ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help)    usage ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Unlink
# ---------------------------------------------------------------------------
if [[ ! -d "$DEST" ]] && [[ ! -L "$DEST" ]]; then
  warn "$DEST does not exist — nothing to do."
  exit 0
fi

echo "── ~/.agents/skills ──"

unlinked=0
skipped=0

# Iterate over every entry in the central skills directory
for target in "$DEST"/*; do
  # Handle empty directory (glob literal). Test -L as well so dangling
  # symlinks (e.g. left behind by a renamed skill) are still cleaned up.
  [[ -e "$target" ]] || [[ -L "$target" ]] || continue

  name="$(basename "$target")"

  if [[ ! -L "$target" ]]; then
    # Not a symlink — wasn't created by link-skills.sh, skip it.
    info "skipping $name (not a symlink, not managed by link-skills.sh)"
    ((skipped++))
    continue
  fi

  # Resolve where the symlink points
  resolved="$(readlink -f "$target" 2>/dev/null || readlink "$target")"

  # Check if the target points into this repo's skills/ tree
  case "$resolved" in
    "$REPO/skills/"*)
      if $DRY_RUN; then
        info "[dry-run] would remove  $name → $resolved"
        ((unlinked++))
      else
        rm "$target"
        ok "removed $name"
        ((unlinked++))
      fi
      ;;
    *)
      info "skipping $name (points outside this repo: $resolved)"
      ((skipped++))
      ;;
  esac
done

echo

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if $DRY_RUN; then
  echo "Dry run complete — $unlinked symlink(s) would be removed, $skipped skipped."
else
  echo "Done — $unlinked symlink(s) removed, $skipped skipped in $DEST."
fi
