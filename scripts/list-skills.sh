#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPO"
find . -name SKILL.md -not -path '*/node_modules/*' -not -path './skills/dm-spec-creation/specs/*' | sed 's|^\./||' | sort
