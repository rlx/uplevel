#!/usr/bin/env bash
# Gate for THIS repository. The skill ships its own portable selfcheck.sh;
# this adds the checks that only make sense here, then delegates to it.
#   ./scripts/check-repo.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
fail=0; note() { echo "  !! $1"; fail=1; }

echo "== relative links resolve =="
n=0
while IFS= read -r line; do
  f="${line%%:*}"; link="${line#*:}"
  d="$(dirname "$f")"; t="${link%%#*}"
  [ -z "$t" ] && continue
  n=$((n+1))
  [ -e "$d/$t" ] || note "$f points at missing $t"
done < <(git ls-files '*.md' | xargs grep -noE '\]\([^)h][^)]*\)' 2>/dev/null \
         | sed -E 's/:[0-9]+:\]\(/:/; s/\)$//')
echo "  $n relative links checked"

echo "== commit hook installed =="
if [ -n "${CI:-}" ]; then
  echo "  CI run — hooks are a local concern, skipping"
elif [ -d .git ]; then
  if [ -x .git/hooks/pre-commit ]; then
    cmp -s .git/hooks/pre-commit scripts/hooks/pre-commit \
      || note "the installed pre-commit hook differs from scripts/hooks/pre-commit — rerun scripts/install-hooks.sh"
  else
    note "no pre-commit hook installed — run scripts/install-hooks.sh (a clone starts without one)"
  fi
else
  echo "  not a git checkout, skipping"
fi

echo "== skill version bumped with skill changes =="
# The rule lives in references/mode-c-enforce.md: bump the version marker in the
# same commit as the change it invalidates. Enforced at commit time, which is the
# only point where "same commit" is a question that can be answered.
staged=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$staged" ]; then
  echo "  nothing staged, skipping"
elif ! printf '%s\n' "$staged" | grep -qE '^skills/uplevel/(SKILL\.md|references/)'; then
  echo "  no skill content staged"
elif git diff --cached -U0 -- skills/uplevel/SKILL.md | grep -q '^+version:'; then
  echo "  skill content changed, version bumped"
else
  note "skill content is staged without a version: bump in SKILL.md"
fi

echo "== installed skill resolves =="
if [ -n "${CI:-}" ]; then
  echo "  CI run, installation is a local concern, skipping"
elif [ ! -e "$HOME/.claude/skills/uplevel" ] && [ ! -L "$HOME/.claude/skills/uplevel" ]; then
  echo "  not installed on this machine, skipping"
elif [ -f "$HOME/.claude/skills/uplevel/SKILL.md" ]; then
  echo "  resolves to a skill"
else
  note "~/.claude/skills/uplevel exists but does not resolve; rerun the install step"
fi

echo "== the skill's own gate =="
skills/uplevel/selfcheck.sh | sed 's/^/  /' || fail=1

[ "$fail" = "0" ] && echo "REPO OK" || { echo "REPO FAILED"; exit 1; }
