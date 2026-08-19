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
done < <(grep -oE 'references/[a-z0-9-]+\.md' SKILL.md | sort -u)
for f in references/*.md; do
  grep -q "$(basename "$f")" SKILL.md || note "$(basename "$f") ships but is never referenced"
done

echo "== load cost =="
w=$(wc -w < SKILL.md); tok=$((w * 4 / 3))
# Print the headroom, not just the number. The ceiling is a wall you hit without
# warning; the remainder is what tells you a change is nearly the last one that fits.
echo "  SKILL.md ≈ $tok tokens of 4000 ($((4000 - tok)) left; loaded whenever the skill triggers)"
[ "$tok" -gt 4000 ] && note "SKILL.md is over the 4k budget — it loads on every trigger; move detail into references/"

echo "== shipped commands parse =="
# bash -n catches shell syntax. It does NOT catch a bad regex -- which is how a
# PCRE lookahead once shipped inside a grep -E and failed on every repo it ran on.
blocks=0; pats=0
tmp="$(mktemp -d)"
for f in SKILL.md references/*.md; do
  awk -v d="$tmp" -v base="$(basename "$f")" '
    /^[ \t]*```(sh|bash)[ \t]*$/ { c=1; n++; out=d "/" base "." n ".sh"; next }
    /^[ \t]*```[ \t]*$/          { if (c) { close(out); c=0 }; next }
    c                             { print > out }
  ' "$f"
  while IFS= read -r pat; do
    [ -z "$pat" ] && continue
    pats=$((pats+1))
    grep -E "$pat" </dev/null >/dev/null 2>&1
    [ $? -eq 2 ] && note "invalid extended regex in $f: $pat"
  done < <(grep -ohE "grep [^|]*-[a-zA-Z]*E[a-zA-Z]* '[^']+'" "$f" | sed -E "s/.*E[a-zA-Z]* '//; s/'$//")
done
for b in "$tmp"/*.sh; do
  [ -e "$b" ] || continue
  blocks=$((blocks+1))
  bash -n "$b" 2>/dev/null || note "unparseable shell block: $(basename "$b")"
done
rm -rf "$tmp"
echo "  $blocks shell blocks, $pats extended regexes checked"

echo "== no project-specific leakage =="
if grep -rniE 'clarus|candor|tendingus|/Users/|~/dev/' --include='*.md' . >/dev/null 2>&1; then
  note "project-specific strings found:"; grep -rniE 'clarus|candor|tendingus|/Users/|~/dev/' --include='*.md' . | head -5
fi

echo "== the skill follows its own rules =="
grep -q "Never read secret values" SKILL.md || note "the secrets rule is missing"
grep -q "advisory" SKILL.md || note "the advisory posture is missing"

[ "$fail" = "0" ] && echo "OK" || { echo "FAILED"; exit 1; }
