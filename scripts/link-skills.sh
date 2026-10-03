#!/usr/bin/env bash
set -euo pipefail

# link-skills.sh — Symlink each skill in this repo into the central
# ~/.agents/skills directory, which is the single registration point
# read by all supported AI coding agents (Claude Code, Codex, GitHub
# Copilot, etc.).
#
# Usage:
#   ./scripts/link-skills.sh                 # link all skills
#   ./scripts/link-skills.sh --dry-run        # preview only, no changes
#   ./scripts/link-skills.sh --force          # overwrite existing files/dirs
#   ./scripts/link-skills.sh --help

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.agents/skills"

DRY_RUN=false
FORCE=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
usage() {
  cat <<'EOF'
Usage: link-skills.sh [OPTIONS]

Symlink every skill in this repository into the central ~/.agents/skills
directory so it becomes available to all AI coding agents.

Options:
  --dry-run           Print what would be done without making changes.
  --force             Remove existing files/dirs at the target before
                      linking (default: skip if target exists).
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
      warn "--agents is no longer supported: skills are now linked into the central $HOME/.agents/skills directory."
      exit 1
      ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true;   shift ;;
    --help)    usage ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Guard: if the skills directory is already a symlink into THIS repo,
# we would end up writing symlinks back into the repo.  Detect and refuse.
# ---------------------------------------------------------------------------
if [[ -L "$DEST" ]]; then
  resolved="$(readlink -f "$DEST" 2>/dev/null || readlink "$DEST")"
  case "$resolved" in
    "$REPO"|"$REPO"/*)
      warn "$DEST is a symlink into this repo ($resolved)."
      warn "Remove it (rm \"$DEST\") and re-run; the script will recreate it as a real directory."
      exit 1
      ;;
  esac
fi

# ---------------------------------------------------------------------------
# Build the list of skills to link
# ---------------------------------------------------------------------------
# Only top-level skills (skills/<name>/SKILL.md) are linked. Sub-skills
# nested deeper (e.g. skills/dm-spec-creation/specs/*, marked
# user-invocable: false) are read by their parent via relative paths;
# linking them would expose them as standalone skills, and some agents
# (e.g. OpenCode) ignore the user-invocable frontmatter field.
# skills/deprecated/<name>/ and skills/experimental/<name>/ sit one level
# deeper, so they are skipped too.
SKILLS=()
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  name="$(basename "$src")"
  SKILLS+=("$name|$src")
done < <(find "$REPO/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -print0 | sort -z)

if [[ ${#SKILLS[@]} -eq 0 ]]; then
  warn "No SKILL.md files found under $REPO/skills/."
  exit 1
fi

# ---------------------------------------------------------------------------
# Link
# ---------------------------------------------------------------------------
mkdir -p "$DEST"

echo "── ~/.agents/skills ──"

linked=0
skipped=0

for entry in "${SKILLS[@]}"; do
  name="${entry%%|*}"
  src="${entry##*|}"
  target="$DEST/$name"

  if [[ -e "$target" ]] || [[ -L "$target" ]]; then
    if $FORCE; then
      if $DRY_RUN; then
        info "[dry-run] would remove  $target"
      else
        rm -rf "$target"
      fi
    else
      warn "$target already exists — skipping (use --force to overwrite)"
      skipped=$((skipped + 1))
      continue
    fi
  fi

  if $DRY_RUN; then
    info "[dry-run] would link  $name → $src"
    linked=$((linked + 1))
  else
    ln -sfn "$src" "$target"
    ok "$name"
    linked=$((linked + 1))
  fi
done

echo

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if $DRY_RUN; then
  echo "Dry run complete — $linked link(s) would be created, $skipped skipped."
else
  echo "Done — $linked skill(s) linked, $skipped skipped in $DEST."
fi
