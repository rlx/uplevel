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
done < <(git ls-files '*.md' | xargs grep -noE '\]\([^)]+\)' 2>/dev/null \
         | sed -E 's/:[0-9]+:\]\(/:/; s/\)$//' \
         | grep -vE ':(https?|mailto):')
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

# The three rules below ask what a change contains. At commit time that is the
# index. In CI nothing is staged, so they skipped there and bound only whoever
# had installed the hook -- a web edit, a bot or a --no-verify commit reached
# main unasked. On a pull request the same question is asked of the diff against
# the base branch, which needs the checkout to have fetched it.
RANGE=""; what="staged"
if [ -n "$(git diff --cached --name-only 2>/dev/null)" ]; then
  RANGE="--cached"
elif [ -n "${GITHUB_BASE_REF:-}" ]; then
  if git rev-parse -q --verify "origin/$GITHUB_BASE_REF" >/dev/null 2>&1; then
    RANGE="origin/$GITHUB_BASE_REF...HEAD"; what="in this pull request"
  else
    note "origin/$GITHUB_BASE_REF is not in this checkout, so the pull request cannot be diffed — fetch full history"
  fi
fi
# shellcheck disable=SC2086
changed=$( [ -n "$RANGE" ] && git diff $RANGE --name-only 2>/dev/null )
# shellcheck disable=SC2086
gdiff() { git diff $RANGE "$@"; }

echo "== skill version bumped with skill changes =="
# The rule lives in references/mode-c-enforce.md: bump the version marker in the
# same commit as the change it invalidates. Enforced at commit time, which is the
# only point where "same commit" is a question that can be answered.
# Everything under plugin/ ships, not only SKILL.md and references/ --
# the shipped README, the selfcheck and its data files reach an installed copy
# too, and a version that does not move cannot identify what someone installed.
if [ -z "$changed" ]; then
  echo "  nothing staged and not a pull request, skipping"
elif ! printf '%s\n' "$changed" | grep -qE '^plugin/'; then
  echo "  no skill content $what"
elif gdiff -U0 -- plugin/skills/uplevel/SKILL.md | grep -q '^+version:'; then
  echo "  skill content changed, version bumped"
else
  note "skill content is $what without a version: bump in SKILL.md"
fi

echo "== a new check is recorded in the checklist =="
# The date check below proves the checklist was looked at, not that it says what
# is true: it passed while four controls were in place and unrecorded. A gate
# script gaining a check is the moment the checklist goes stale, so that is where
# this fires. Renames net to zero, so only genuinely new headings ask for an
# entry. Commit time only, for the same reason the version rule is: "in the same
# commit" is a question only answerable here.
gates="scripts/check-repo.sh scripts/check-install.sh scripts/check-forge.sh plugin/skills/uplevel/selfcheck.sh"
if [ -z "$changed" ]; then
  echo "  nothing staged and not a pull request, skipping"
elif ! printf '%s\n' "$changed" | grep -qE '^(scripts/check-(repo|install|forge)\.sh|plugin/skills/uplevel/selfcheck\.sh)$'; then
  echo "  no gate script $what"
else
  # Count assertions, not just section headings: a check added inside an existing
  # section netted zero, which is how the entry for this very rule came to be
  # written by hand. The signals are a data file, because written inline they
  # match their own source line.
  sig="$(mktemp)"
  grep -vE '^[[:space:]]*(#|$)' scripts/gate-check-signals.txt > "$sig"
  # shellcheck disable=SC2086
  d=$(gdiff -U0 -- $gates)
  add=$(printf '%s\n' "$d" | grep '^+' | grep -v '^+++' | sed 's/^.//' | grep -cEf "$sig")
  del=$(printf '%s\n' "$d" | grep '^-' | grep -v '^---' | sed 's/^.//' | grep -cEf "$sig")
  rm -f "$sig"
  net=$((add - del))
  if [ "$net" -le 0 ]; then
    echo "  gate script $what, no check added ($add added, $del removed)"
  elif printf '%s\n' "$changed" | grep -q '^\.claude/guardrails\.yml$'; then
    echo "  $net new check(s) $what, checklist updated alongside"
  else
    note "$net new check(s) $what without a change to .claude/guardrails.yml — record what it enforces"
  fi
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

echo "== the checklist parses, and is current =="
# It shipped unparseable once: an unquoted "#" started a YAML comment mid-value.
# A checklist nothing reads is a checklist nothing notices is wrong. The date is
# checked for the same reason -- an audit date nothing reads decays in silence,
# and a stale checklist reads exactly like a current one.
if ! command -v python3 >/dev/null 2>&1; then
  echo "  no python3, skipping"
elif ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo "  no pyyaml, skipping"
else
  msg=$(python3 - <<'CHECKLIST'
import datetime, sys, yaml
MAX_AGE = 180
try:
    doc = yaml.safe_load(open(".claude/guardrails.yml"))
except Exception as exc:
    print("does not parse as YAML: %s" % str(exc).splitlines()[0])
    sys.exit(1)
audited = doc.get("last_audit") if isinstance(doc, dict) else None
if not isinstance(audited, datetime.date):
    print("has no 'last_audit:' date in YYYY-MM-DD form")
    sys.exit(1)
age = (datetime.date.today() - audited).days
if age < 0:
    print("is audited %s, which is in the future" % audited)
    sys.exit(1)
if age > MAX_AGE:
    print("was audited %s, %d days ago; re-audit and update the date" % (audited, age))
    sys.exit(1)
print("valid YAML, audited %d days ago, %d before it goes stale" % (age, MAX_AGE - age))
CHECKLIST
  )
  if [ $? -eq 0 ]; then
    echo "  .claude/guardrails.yml is $msg"
  else
    note ".claude/guardrails.yml $msg"
  fi
fi

echo "== every tag declares the version it claims =="
# The version bump is gated at commit time; the tag was not, so main once
# carried a version that had never been released and nothing noticed. An
# installed copy is identified by that number, so a tag pointing at a commit
# that declares a different one makes the number useless.
VERSION_FS='[ \t]*:[ \t]*'
tagn=0
while IFS= read -r t; do
  [ -z "$t" ] && continue
  tagn=$((tagn+1))
  # The skill moved into plugin/ at v0.87.0; older tags carry it at the old path.
  tv="$( { git show "$t:plugin/skills/uplevel/SKILL.md" 2>/dev/null \
           || git show "$t:skills/uplevel/SKILL.md" 2>/dev/null; } \
        | awk -F"$VERSION_FS" '/^version:/ { print $2; exit }')"
  [ "$tv" = "${t#v}" ] || note "$t points at a commit declaring version '${tv:-none}'"
done < <(git tag -l 'v*' 2>/dev/null)
cur="$(awk -F"$VERSION_FS" '/^version:/ { print $2; exit }' plugin/skills/uplevel/SKILL.md)"
if [ "$tagn" = "1" ]; then tw="tag"; else tw="tags"; fi
# A tag was published whose own commit did not document the version it released:
# the changelog PR was open, and the release went out first. Checked forward on
# main rather than over history, so it gates the next tag instead of relitigating
# published ones -- and it fails while there is still time to write the entry.
if [ ! -f CHANGELOG.md ]; then
  echo "  no CHANGELOG.md, skipping the entry check"
elif grep -q "^## v$cur" CHANGELOG.md; then
  echo "  CHANGELOG.md documents $cur"
else
  note "CHANGELOG.md has no '## v$cur' entry — write it in the change, not after the tag"
fi

if [ "$tagn" = "0" ] && [ -n "${CI:-}" ]; then
  # A default CI checkout fetches no tags, so every tag check above compared
  # nothing and this line read as a repository that had never released.
  note "this checkout has no v* tags, so no tag was checked — fetch tags"
elif [ "$tagn" = "0" ]; then
  echo "  no v* tags yet; SKILL.md declares $cur"
elif git rev-parse -q --verify "refs/tags/v$cur" >/dev/null 2>&1; then
  echo "  $tagn $tw checked; SKILL.md declares $cur, which is tagged"
else
  echo "  $tagn $tw checked; SKILL.md declares $cur, not tagged - tag it when you release it"
fi

echo "== the plugin folder is what the directory and the marketplace expect =="
# plugin/ is the whole plugin: its manifest, its README and the skill. That is
# the shape Anthropic's directory validates -- a folder holding
# .claude-plugin/plugin.json, a README and a license -- and the folder an install
# copies, so the gate scripts and fixtures beside it never reach a user.
#
# The manifest's version is what "claude plugin update" compares: a change that
# does not move it never reaches an installed copy. The manifest must not sit
# inside skills/uplevel/ itself: a linked or copied skill folder carrying one is
# loaded as a skills-directory plugin, which was observed to report zero skills.
if ! command -v python3 >/dev/null 2>&1; then
  echo "  no python3, skipping"
else
  msg=$(python3 - "$cur" <<'MANIFESTS'
import json, os, re, sys
declared = sys.argv[1]
def load(path):
    try:
        return json.load(open(path))
    except Exception as exc:
        print("%s does not parse: %s" % (path, exc)); sys.exit(1)
plugin = load("plugin/.claude-plugin/plugin.json")
market = load(".claude-plugin/marketplace.json")
if plugin.get("name") != "uplevel":
    print("plugin.json names the plugin %r; an installed copy is recorded under 'uplevel'" % plugin.get("name")); sys.exit(1)
if plugin.get("version") != declared:
    print("plugin.json declares version %r, SKILL.md declares %r - bump both in the same change"
          % (plugin.get("version"), declared)); sys.exit(1)
for field in ("description", "author", "license"):
    if not plugin.get(field):
        print("plugin.json sets no %s, which the directory asks for" % field); sys.exit(1)
entries = [p for p in market.get("plugins", []) if p.get("name") == "uplevel"]
if len(entries) != 1:
    print("marketplace.json lists %d plugins named 'uplevel', expected one" % len(entries)); sys.exit(1)
e = entries[0]
if e.get("source") != "./plugin":
    print("the marketplace entry's source is %r - an install copies that directory, so it must be ./plugin"
          % e.get("source")); sys.exit(1)
if "version" in e and e["version"] != declared:
    print("the marketplace entry declares version %r, SKILL.md declares %r" % (e["version"], declared)); sys.exit(1)
for stray in (".claude-plugin/plugin.json", "plugin/skills/uplevel/.claude-plugin"):
    if os.path.exists(stray):
        print("%s exists - the manifest belongs in plugin/.claude-plugin/ and nowhere else" % stray); sys.exit(1)
try:
    readme = open("plugin/README.md", encoding="utf-8").read()
except OSError:
    print("plugin/README.md is missing - the directory lists a plugin by its README"); sys.exit(1)
words = len(re.sub(r"```.*?```", " ", readme, flags=re.S).split())
if words < 40:
    print("plugin/README.md has %d words outside code blocks; the directory wants 40" % words); sys.exit(1)
# Tracked files only: an install copies what git has, and the Finder drops a
# .DS_Store into any folder someone opens, which is ignored and never ships.
import subprocess
tracked = subprocess.check_output(["git", "ls-files", "plugin"], text=True).split("\n")
extra = sorted({t.split("/")[1] for t in tracked if t} - {".claude-plugin", "README.md", "skills"})
if extra:
    print("plugin/ holds %s - everything in that folder ships to every install" % ", ".join(extra)); sys.exit(1)
print("plugin.json at %s, source ./plugin, README %d words, nothing else in the folder" % (declared, words))
MANIFESTS
  )
  if [ $? -eq 0 ]; then echo "  $msg"; else note "$msg"; fi
fi

echo "== the shipped skill carries the license =="
# An install copies plugin/skills/uplevel/ and nothing above it, so the license at the
# repository root never reached one. The copy inside the skill is the one that
# travels, and two copies of anything drift.
if cmp -s LICENSE plugin/skills/uplevel/LICENSE; then
  echo "  plugin/skills/uplevel/LICENSE matches LICENSE"
else
  note "plugin/skills/uplevel/LICENSE is missing or differs from LICENSE — an installed copy ships without the license text"
fi

echo "== gate scripts stay portable =="
# CI runs ubuntu-latest (bash 5, GNU coreutils). A maintainer's macOS runs bash 3.2
# with BSD or ugrep tools, and the commit hook gates on that one. A GNU-only flag
# would pass for whoever wrote it and fail for the other, so the scripts avoid them.
gnuisms=0; checked=0
while read -r p; do
  case "$p" in ''|'#'*) continue;; esac
  checked=$((checked+1))
  if grep -rnF -- "$p" scripts/*.sh plugin/skills/uplevel/*.sh 2>/dev/null; then
    note "GNU-only construct in a gate script: $p"; gnuisms=$((gnuisms+1))
  fi
done < scripts/gnu-only-constructs.txt
[ "$gnuisms" = "0" ] && echo "  $checked GNU-only constructs checked for, none present"

echo "== prose is en-US =="
# A public repository whose deliverable is text; mixed spelling reads as two
# authors who never compared notes. The list is a data file for the same reason
# leak-patterns.txt is -- a check that searches the tree is in the tree, and a
# list inside the scanned set matches itself.
# One grep over every file, not one per pattern per file: the readable nested
# loop spawned ~1200 processes and cost 3.3s of a 4.5s gate, on the pre-commit
# path. Comments and blank lines are stripped first -- grep -f treats a blank
# line as a pattern matching everything.
pat="$(mktemp)"
grep -vE '^[[:space:]]*(#|$)' scripts/en-gb-spellings.txt > "$pat"
words=$(grep -c . "$pat")
hits="$(git ls-files -z '*.md' '*.yml' | xargs -0 grep -onE -f "$pat" 2>/dev/null)"
rm -f "$pat"
if [ -z "$hits" ]; then
  echo "  $words spellings checked, none present"
else
  printf '%s\n' "$hits" | while IFS= read -r h; do echo "  !! en-GB spelling at $h"; done
  fail=1
fi

echo "== prose stays wrapped =="
# The prose wraps at about 100 columns by hand. The ceiling here is 105, not
# 100: it catches a line that was never wrapped without demanding a reflow of
# every line that runs a character or two over. Tables, fenced code and long
# URLs are exempt because they cannot be wrapped. Counted in characters -- an
# em dash is three bytes, so a byte count flags correctly-wrapped prose.
if ! command -v python3 >/dev/null 2>&1; then
  echo "  no python3, skipping"
else
  long=$(git ls-files '*.md' | python3 -c '
import re, sys
LIMIT = 105
bad = []
for f in sys.stdin.read().split():
    fence = False
    for i, line in enumerate(open(f, encoding="utf-8"), 1):
        line = line.rstrip("\n")
        if line.lstrip().startswith("```"):
            fence = not fence
            continue
        if fence or line.lstrip().startswith("|"):
            continue
        if re.search(r"https?://\S{40,}", line):
            continue
        if len(line) > LIMIT:
            bad.append("%s:%d is %d characters" % (f, i, len(line)))
print("\n".join(bad))
')
  if [ -z "$long" ]; then
    echo "  every markdown line is 105 characters or fewer"
  else
    printf '%s\n' "$long" | while IFS= read -r l; do echo "  !! $l"; done
    fail=1
  fi
fi

echo "== the skill's own gate =="
plugin/skills/uplevel/selfcheck.sh | sed 's/^/  /' || fail=1

[ "$fail" = "0" ] && echo "REPO OK" || { echo "REPO FAILED"; exit 1; }
