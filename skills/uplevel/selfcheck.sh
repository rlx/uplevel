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
# References cite each other by bare filename, because they sit in the same
# directory -- `references/foo.md` from inside references/ would mean
# references/references/foo.md. Uppercase names (CLAUDE.md, AGENTS.md) are repo
# files being discussed, not citations, so the pattern deliberately excludes them.
while read -r m; do
  [ -f "references/$m" ] || note "a reference cites $m, which does not exist in references/"
done < <(grep -ohE '`[a-z0-9][a-z0-9-]*\.md`' references/*.md | tr -d '`' | sort -u)
grep -q 'references/' references/*.md && note "a reference cites another with a references/ prefix; use the bare filename"

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
  # A valid regex is not a runnable command. A recursive grep shipped without a
  # path operand, or trailing a bare `--`, compiles fine and then does nothing
  # useful -- which is how two unrunnable commands shipped in this skill.
  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    case "$cmd" in
      *'--`'|*'-- `') note "shipped command ends in a bare -- with no operand in $f: $cmd" ;;
    esac
    # The last token before the closing backtick must not be the pattern itself.
    # An unquoted pattern followed by a path is fine, so test the ending, not the shape.
    case "$cmd" in
      *"grep -r"*"'\`") note "recursive grep with no path operand in $f: $cmd" ;;
    esac
  done < <(grep -ohE '`grep -r[^`]*`' "$f")
done
for b in "$tmp"/*.sh; do
  [ -e "$b" ] || continue
  blocks=$((blocks+1))
  bash -n "$b" 2>/dev/null || note "unparseable shell block: $(basename "$b")"
done
rm -rf "$tmp"
echo "  $blocks shell blocks, $pats extended regexes checked"

echo "== no machine- or project-specific leakage =="
# Shapes, not known names: a denylist of names you already found catches only
# that leak. Patterns live in a data file so they cannot match themselves, and
# .sh is scanned as well as .md -- the previous version scanned only markdown,
# which is exactly why a leak inside this script went unnoticed.
leaks=0; scanned=0
while read -r p; do
  case "$p" in ''|'#'*) continue;; esac
  scanned=$((scanned+1))
  if grep -rniE --include='*.md' --include='*.sh' -- "$p" . >/dev/null 2>&1; then
    note "machine- or project-specific string found ($p):"
    grep -rniE --include='*.md' --include='*.sh' -- "$p" . | head -3
    leaks=$((leaks+1))
  fi
done < leak-patterns.txt
[ "$leaks" = "0" ] && echo "  $scanned leak patterns checked, none present"

echo "== the skill follows its own rules =="
# Anchored to the sentence that carries the rule, not to a word that appears
# elsewhere: "advisory" alone also matches an unrelated line about warning-only
# checks, so the old check passed even with the posture statement deleted.
grep -q "Never read secret values" SKILL.md || note "the secrets rule is missing"
grep -q "posture is advisory" SKILL.md || note "the advisory posture is missing"

[ "$fail" = "0" ] && echo "OK" || { echo "FAILED"; exit 1; }
