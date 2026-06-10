#!/usr/bin/env bash
set -euo pipefail

# link-skills.sh — Symlink each skill in this repo into the skills directories of
# one or more AI coding agents (Claude Code, Codex, GitHub Copilot, etc.).
#
# Usage:
#   ./scripts/link-skills.sh                 # auto-detect installed agents
#   ./scripts/link-skills.sh --agents claude,codex,copilot
#   ./scripts/link-skills.sh --dry-run        # preview only, no changes
#   ./scripts/link-skills.sh --force          # overwrite existing files/dirs
#   ./scripts/link-skills.sh --help

REPO="$(cd "$(dirname "$0")/.." && pwd)"

# ---------------------------------------------------------------------------
# Agent → skills-directory map
# ---------------------------------------------------------------------------
agent_dir() {
  case "$1" in
    claude)  echo ".claude/skills" ;;
    codex)   echo ".codex/skills" ;;
    copilot) echo ".copilot/skills" ;;
  esac
}

# Ordered list of all known agents (used for validation and auto-detect)
KNOWN_AGENTS=(claude codex copilot)

# Default: auto-detect which agents have their config directory present.
# Users can override with --agents.
AGENTS=()
DRY_RUN=false
FORCE=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
usage() {
  cat <<'EOF'
Usage: link-skills.sh [OPTIONS]

Symlink every skill in this repository into the skills directories of
AI coding agents so they become available as slash commands / skills.

Options:
  --agents NAME,...   Comma-separated list of agents to link for.
                      Supported: claude, codex, copilot
                      Default: auto-detect (link for every agent whose
                      config directory already exists under $HOME).
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
      IFS=',' read -r -a AGENTS <<< "$2"
      shift 2
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
# Resolve agent list
# ---------------------------------------------------------------------------
if [[ ${#AGENTS[@]} -eq 0 ]]; then
  # Auto-detect: include every agent whose config directory exists.
  for agent in "${KNOWN_AGENTS[@]}"; do
    agent_d="$(agent_dir "$agent")"
    if [[ -d "$HOME/$agent_d" ]] || [[ -L "$HOME/$agent_d" ]]; then
      AGENTS+=("$agent")
    fi
  done
  if [[ ${#AGENTS[@]} -eq 0 ]]; then
    warn "No agent config directories found under $HOME."
    warn "Use --agents to specify agents explicitly, e.g.:"
    warn "  $0 --agents claude,codex,copilot"
    exit 1
  fi
fi

# Validate agent names
for agent in "${AGENTS[@]}"; do
  if [[ -z "$(agent_dir "$agent")" ]]; then
    warn "Unknown agent '$agent'. Supported: ${KNOWN_AGENTS[*]}"
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# Guard: if the user's skills directory is already a symlink into THIS repo,
# we would end up writing symlinks back into the repo.  Detect and refuse.
# ---------------------------------------------------------------------------
for agent in "${AGENTS[@]}"; do
  DEST="$HOME/$(agent_dir "$agent")"
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
done

# ---------------------------------------------------------------------------
# Build the list of skills to link
# ---------------------------------------------------------------------------
SKILLS=()
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  name="$(basename "$src")"
  SKILLS+=("$name|$src")
done < <(find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/deprecated/*' -print0)

if [[ ${#SKILLS[@]} -eq 0 ]]; then
  warn "No SKILL.md files found under $REPO/skills/."
  exit 1
fi

# ---------------------------------------------------------------------------
# Link
# ---------------------------------------------------------------------------
linked_total=0
skipped_total=0

for agent in "${AGENTS[@]}"; do
  DEST="$HOME/$(agent_dir "$agent")"
  mkdir -p "$DEST"

  echo "── ${agent} (→ $(agent_dir "$agent")) ──"

  agent_linked=0
  agent_skipped=0

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
        ((agent_skipped++))
        continue
      fi
    fi

    if $DRY_RUN; then
      info "[dry-run] would link  $name → $src"
      ((agent_linked++))
    else
      ln -sfn "$src" "$target"
      ok "$name"
      ((agent_linked++))
    fi
  done

  linked_total=$((linked_total + agent_linked))
  skipped_total=$((skipped_total + agent_skipped))
  echo
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
if $DRY_RUN; then
  echo "Dry run complete — $linked_total link(s) would be created, $skipped_total skipped."
else
  echo "Done — $linked_total skill(s) linked, $skipped_total skipped across ${#AGENTS[@]} agent(s)."
fi
