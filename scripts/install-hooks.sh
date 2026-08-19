#!/usr/bin/env bash
# Install this repo's git hooks. Safe to re-run; run it after a fresh clone.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
install -m 755 "$ROOT/scripts/hooks/pre-commit" "$ROOT/.git/hooks/pre-commit"
echo "installed .git/hooks/pre-commit -> runs scripts/check-repo.sh"
