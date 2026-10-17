#!/usr/bin/env bash
set -euo pipefail

# unlink-skills.sh — Remove symlinks created by link-skills.sh from the
# registration directories read by the supported AI coding agents:
#
#   ~/.agents/skills   read by Codex, GitHub Copilot, and others
#   ~/.claude/skills   read by Claude Code, which does not read ~/.agents/skills
#
# Usage:
#   ./scripts/unlink-skills.sh                 # unlink all skills
#   ./scripts/unlink-skills.sh --dry-run        # preview only, no changes
#   ./scripts/unlink-skills.sh --help

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=("$HOME/.agents/skills" "$HOME/.claude/skills")

DRY_RUN=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
usage() {
  cat <<'EOF'
Usage: unlink-skills.sh [OPTIONS]

Remove symlinks created by link-skills.sh from ~/.agents/skills and
~/.claude/skills.
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
      warn "--agents is no longer supported: skills are now unlinked from the registration directories ($HOME/.agents/skills, $HOME/.claude/skills)."
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
total_unlinked=0
total_skipped=0
seen_dests=" "

for dest in "${DESTS[@]}"; do
  if [[ ! -d "$dest" ]] && [[ ! -L "$dest" ]]; then
    info "skipping $dest (does not exist)"
    continue
  fi

  # Two destinations can resolve to the same directory (for example when
  # ~/.claude/skills is a symlink to ~/.agents/skills): clean it once only.
  if ! canonical="$(cd "$dest" 2>/dev/null && pwd -P)"; then
    warn "$dest is not a directory (dangling symlink?) — skipping"
    continue
  fi
  if [[ "$seen_dests" == *" $canonical "* ]]; then
    info "skipping $dest — same directory as one already cleaned"
    continue
  fi
  seen_dests="$seen_dests$canonical "

  echo "── $dest ──"

  unlinked=0
  skipped=0

  # Iterate over every entry in the skills directory
  for target in "$dest"/*; do
    # Handle empty directory (glob literal). Test -L as well so dangling
    # symlinks (e.g. left behind by a renamed skill) are still cleaned up.
    [[ -e "$target" ]] || [[ -L "$target" ]] || continue

    name="$(basename "$target")"

    if [[ ! -L "$target" ]]; then
      # Not a symlink — wasn't created by link-skills.sh, skip it.
      info "skipping $name (not a symlink, not managed by link-skills.sh)"
      skipped=$((skipped + 1))
      continue
    fi

    # Resolve where the symlink points
    resolved="$(readlink -f "$target" 2>/dev/null || readlink "$target")"

    # Check if the target points into this repo's skills/ tree
    case "$resolved" in
      "$REPO/skills/"*)
        if $DRY_RUN; then
          info "[dry-run] would remove  $name → $resolved"
          unlinked=$((unlinked + 1))
        else
          rm "$target"
          ok "removed $name"
          unlinked=$((unlinked + 1))
        fi
        ;;
      *)
        info "skipping $name (points outside this repo: $resolved)"
        skipped=$((skipped + 1))
        ;;
    esac
  done

  echo

  if $DRY_RUN; then
    echo "Dry run complete — $unlinked symlink(s) would be removed, $skipped skipped in $dest."
  else
    echo "Done — $unlinked symlink(s) removed, $skipped skipped in $dest."
  fi

  echo

  total_unlinked=$((total_unlinked + unlinked))
  total_skipped=$((total_skipped + skipped))
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if $DRY_RUN; then
  echo "Dry run complete — $total_unlinked symlink(s) would be removed, $total_skipped skipped in ${#DESTS[@]} directories."
else
  echo "Done — $total_unlinked symlink(s) removed, $total_skipped skipped in ${#DESTS[@]} directories."
fi
