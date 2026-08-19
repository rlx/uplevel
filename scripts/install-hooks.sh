#!/usr/bin/env bash
# Install this repo's git hooks. Safe to re-run; run it after a fresh clone.
# An existing hook that is not ours is backed up rather than overwritten --
# a contributor using husky or pre-commit should not lose it silently.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
src="$ROOT/scripts/hooks/pre-commit"
dst="$ROOT/.git/hooks/pre-commit"

if [ -e "$dst" ] && ! cmp -s "$src" "$dst"; then
  backup="$dst.backup-$(git -C "$ROOT" rev-parse --short HEAD)"
  if [ -e "$backup" ]; then
    echo "refusing to overwrite $dst: a different hook is installed and $backup already exists" >&2
    echo "move or remove one of them, then re-run" >&2
    exit 1
  fi
  cp "$dst" "$backup"
  echo "existing pre-commit hook backed up to ${backup#"$ROOT"/}"
fi

install -m 755 "$src" "$dst"
echo "installed .git/hooks/pre-commit -> runs scripts/check-repo.sh"
