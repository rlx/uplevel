#!/usr/bin/env bash
# Structural check for the skill itself. Cheap, and it fails for a reason.
#   ./selfcheck.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; cd "$HERE"
fail=0; note() { echo "  !! $1"; fail=1; }

echo "== frontmatter =="
head -1 SKILL.md | grep -q '^---$' || note "SKILL.md does not open with YAML frontmatter"
for k in name description version; do
  awk '/^---$/{n++;next} n==1' SKILL.md | grep -q "^$k:" || note "frontmatter missing '$k'"
done

echo "== references resolve =="
while read -r r; do
  [ -f "$r" ] || note "SKILL.md points at missing $r"
done < <(grep -oE 'references/[a-z-]+\.md' SKILL.md | sort -u)
for f in references/*.md; do
  grep -q "$(basename "$f")" SKILL.md || note "$(basename "$f") ships but is never referenced"
done

echo "== load cost =="
w=$(wc -w < SKILL.md); tok=$((w * 4 / 3))
echo "  SKILL.md ≈ $tok tokens (loaded whenever the skill triggers)"
[ "$tok" -gt 4000 ] && note "SKILL.md is over the 4k budget — it loads on every trigger; move detail into references/"

echo "== no project-specific leakage =="
if grep -rniE 'clarus|candor|tendingus|/Users/|~/dev/' --include='*.md' . >/dev/null 2>&1; then
  note "project-specific strings found:"; grep -rniE 'clarus|candor|tendingus|/Users/|~/dev/' --include='*.md' . | head -5
fi

echo "== the skill follows its own rules =="
grep -q "Never read secret values" SKILL.md || note "the secrets rule is missing"
grep -q "advisory" SKILL.md || note "the advisory posture is missing"

[ "$fail" = "0" ] && echo "OK" || { echo "FAILED"; exit 1; }
