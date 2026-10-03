#!/usr/bin/env bash
set -euo pipefail

# list-skills.sh — List the top-level skills that link-skills.sh registers.

REPO="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO"
find skills -mindepth 2 -maxdepth 2 -name SKILL.md | sort
