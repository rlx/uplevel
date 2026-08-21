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
# Only a citation is wrong -- `references/foo.md` from inside references/ would
# mean references/references/. Naming the directory itself is ordinary prose, and
# matching that flagged a sentence about how much of it an audit reads.
grep -qE 'references/[a-z0-9-]+\.md' references/*.md \
  && note "a reference cites another with a references/ prefix; use the bare filename"

echo "== load cost =="
# Measure with a real tokenizer where one is available. `wc -w * 4/3` reads 3-9%
# low on this content: backticks, em-dashes, table pipes and the indentation on
# wrapped list lines all fragment into tokens a word count cannot see, so every
# ceiling here was being compared against a figure that understated what a mode
# actually spends -- Mode A measured 38862 by word count and 42141 by tokenizer,
# already past a ceiling the script reported 1138 of headroom against. Where
# tiktoken is absent the estimate is still printed and the ceilings are not
# asserted: an unmeasured cost is unknown, not passing. CI installs it, so main
# is always guarded, and the commit hook stays useful without it.
EXACT=""
python3 -c 'import tiktoken' >/dev/null 2>&1 && EXACT=1
[ -n "$EXACT" ] || echo "  (no tiktoken here — figures are a word-count estimate that reads low; ceilings not asserted)"
# Print the headroom, not just the number. The ceiling is a wall you hit without
# warning; the remainder is what tells you a change is nearly the last one that fits.
# The ceiling is a visibility mechanism, not a quality cap. It exists because
# this file loads on every trigger, for every user, whether or not they use the
# skill -- so growth is a cost borne by someone else and should be deliberate
# rather than accidental. When quality needs the room, raise the number in the
# same change and say why. Do not cut something worth saying to fit it.
BUDGET=6000

# SKILL.md's budget is the entry cost, not the cost. A mode reads its own file
# and everything that file names, and nothing was measuring that -- so the number
# people optimized was a seventh of what a Mode A audit actually spends before it
# has read a line of the user's repository. The failure is silent: the agent
# reads less of the repo, not less of the skill.
# Record the lists now; count them all in one pass below. A tokenizer import
# per mode would put seconds into the commit hook, which is how a gate stops
# being run.
lists="$(mktemp)"; costs="$(mktemp)"
mode_cost() {
  label="$1"; shift
  for f in "$@"; do
    [ -f "$f" ] || note "mode-cost list names a missing file: $f"
  done
  printf '%s\t%s\n' "$label" "$*" >> "$lists"
  seen="$seen $*"
}
seen=""
mode_cost "SKILL.md" SKILL.md
mode_cost "Mode A, full audit" SKILL.md references/mode-a-investigate.md references/discovery.md \
  references/forge-hygiene.md references/checklist.md references/example-output.md \
  references/destructive-ops.md references/production.md references/automation.md \
  references/evidence.md references/remedies.md
mode_cost "Mode A + write the doc" SKILL.md references/mode-a-investigate.md references/discovery.md \
  references/forge-hygiene.md references/checklist.md references/example-output.md \
  references/destructive-ops.md references/production.md references/automation.md \
  references/evidence.md references/remedies.md references/claude-md-template.md
# The scoped Mode A entry points. Printed next to the full audit because the
# table in mode-a-investigate.md makes a claim about what a scope costs, and a
# claim about cost should be the measurement rather than a number someone typed.
mode_cost "  scope: forge" SKILL.md references/mode-a-investigate.md references/forge-hygiene.md
mode_cost "  scope: gate" SKILL.md references/mode-a-investigate.md references/discovery.md \
  references/evidence.md
mode_cost "  scope: hazards" SKILL.md references/mode-a-investigate.md \
  references/destructive-ops.md references/production.md references/long-runs.md
mode_cost "Mode B" SKILL.md references/automation.md
mode_cost "Mode C, check-in" SKILL.md references/mode-c-enforce.md references/evidence.md \
  references/commit-hygiene.md references/long-runs.md

# The entry cost is bounded by BUDGET above; the Mode A figure is the one that is
# actually spent, and the number that competes with the user's repository for
# context. Raise it in the same change that needs the room, and say why. It is a
# visibility mechanism, not a quality cap: hitting it is a prompt to look at what
# grew, never a reason to cut something worth saying.
MODE_A_BUDGET=44000
if [ -n "$EXACT" ]; then
  python3 - "$lists" <<'PY' > "$costs"
import sys, tiktoken
enc = tiktoken.get_encoding("o200k_base")
for line in open(sys.argv[1], encoding="utf-8"):
    label, files = line.rstrip("\n").split("\t")
    text = "".join(open(f, encoding="utf-8").read() for f in files.split())
    print("%s\t%d" % (label, len(enc.encode(text))))
PY
else
  while IFS="$(printf '\t')" read -r label files; do
    printf '%s\t%s\n' "$label" "$(cat $files | wc -w | awk '{print int($1 * 4 / 3)}')"
  done < "$lists" > "$costs"
fi

while IFS="$(printf '\t')" read -r label total; do
  case "$label" in
    "SKILL.md")
      echo "  SKILL.md ≈ $total tokens of $BUDGET ($((BUDGET - total)) left; loaded whenever the skill triggers)"
      [ -n "$EXACT" ] && [ "$total" -gt "$BUDGET" ] \
        && note "SKILL.md is over its $BUDGET-token budget — raise it deliberately, or move detail into references/"
      ;;
    "Mode A, full audit")
      printf '  %-28s ≈ %6d tokens\n' "$label" "$total"
      [ -n "$EXACT" ] && [ "$total" -gt "$MODE_A_BUDGET" ] \
        && note "Mode A working set is $total tokens, over its $MODE_A_BUDGET ceiling — tighten a reference, or raise it deliberately"
      echo "  (Mode A ceiling $MODE_A_BUDGET; $((MODE_A_BUDGET - total)) left)"
      ;;
    *) printf '  %-28s ≈ %6d tokens\n' "$label" "$total" ;;
  esac
done < "$costs"
rm -f "$lists" "$costs"

for f in references/*.md; do
  case " $seen " in
    *" $f "*) ;;
    *) note "$f is in no mode-cost list, so its load cost is unmeasured" ;;
  esac
done

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
# Anchored to the sentence that carries each rule, not to a word that appears
# elsewhere: "advisory" alone also matches an unrelated line about warning-only
# checks, so an earlier version passed with the posture statement deleted. Two
# rules were anchored by hand and the other nine were not; the list is a data
# file so adding an invariant to SKILL.md means adding it here too.
inv=0
while IFS= read -r rule; do
  case "$rule" in ''|'#'*) continue;; esac
  inv=$((inv+1))
  grep -qF -- "$rule" SKILL.md || note "invariant missing from SKILL.md: $rule"
done < invariants.txt
echo "  $inv invariants stated in SKILL.md"

[ "$fail" = "0" ] && echo "OK" || { echo "FAILED"; exit 1; }
