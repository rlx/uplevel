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

echo "== skill version bumped with skill changes =="
# The rule lives in references/mode-c-enforce.md: bump the version marker in the
# same commit as the change it invalidates. Enforced at commit time, which is the
# only point where "same commit" is a question that can be answered.
# Everything under skills/uplevel/ ships, not only SKILL.md and references/ --
# the shipped README, the selfcheck and its data files reach an installed copy
# too, and a version that does not move cannot identify what someone installed.
staged=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$staged" ]; then
  echo "  nothing staged, skipping"
elif ! printf '%s\n' "$staged" | grep -qE '^skills/uplevel/'; then
  echo "  no skill content staged"
elif git diff --cached -U0 -- skills/uplevel/SKILL.md | grep -q '^+version:'; then
  echo "  skill content changed, version bumped"
else
  note "skill content is staged without a version: bump in SKILL.md"
fi

echo "== a new check is recorded in the checklist =="
# The date check below proves the checklist was looked at, not that it says what
# is true: it passed while four controls were in place and unrecorded. A gate
# script gaining a check is the moment the checklist goes stale, so that is where
# this fires. Renames net to zero, so only genuinely new headings ask for an
# entry. Commit time only, for the same reason the version rule is: "in the same
# commit" is a question only answerable here.
staged=$(git diff --cached --name-only 2>/dev/null)
gates="scripts/check-repo.sh scripts/check-install.sh scripts/check-forge.sh skills/uplevel/selfcheck.sh"
if [ -z "$staged" ]; then
  echo "  nothing staged, skipping"
elif ! printf '%s\n' "$staged" | grep -qE '^(scripts/check-(repo|install|forge)\.sh|skills/uplevel/selfcheck\.sh)$'; then
  echo "  no gate script staged"
else
  # Count assertions, not just section headings: a check added inside an existing
  # section netted zero, which is how the entry for this very rule came to be
  # written by hand. The signals are a data file, because written inline they
  # match their own source line.
  sig="$(mktemp)"
  grep -vE '^[[:space:]]*(#|$)' scripts/gate-check-signals.txt > "$sig"
  # shellcheck disable=SC2086
  d=$(git diff --cached -U0 -- $gates)
  add=$(printf '%s\n' "$d" | grep '^+' | grep -v '^+++' | sed 's/^.//' | grep -cEf "$sig")
  del=$(printf '%s\n' "$d" | grep '^-' | grep -v '^---' | sed 's/^.//' | grep -cEf "$sig")
  rm -f "$sig"
  net=$((add - del))
  if [ "$net" -le 0 ]; then
    echo "  gate script staged, no check added ($add added, $del removed)"
  elif printf '%s\n' "$staged" | grep -q '^\.claude/guardrails\.yml$'; then
    echo "  $net new check(s) staged, checklist updated alongside"
  else
    note "$net new check(s) staged without a change to .claude/guardrails.yml — record what it enforces"
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
audited = doc.get("audited") if isinstance(doc, dict) else None
if not isinstance(audited, datetime.date):
    print("has no 'audited:' date in YYYY-MM-DD form")
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
  tv="$(git show "$t:skills/uplevel/SKILL.md" 2>/dev/null \
        | awk -F"$VERSION_FS" '/^version:/ { print $2; exit }')"
  [ "$tv" = "${t#v}" ] || note "$t points at a commit declaring version '${tv:-none}'"
done < <(git tag -l 'v*' 2>/dev/null)
cur="$(awk -F"$VERSION_FS" '/^version:/ { print $2; exit }' skills/uplevel/SKILL.md)"
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

if [ "$tagn" = "0" ]; then
  echo "  no v* tags yet; SKILL.md declares $cur"
elif git rev-parse -q --verify "refs/tags/v$cur" >/dev/null 2>&1; then
  echo "  $tagn $tw checked; SKILL.md declares $cur, which is tagged"
else
  echo "  $tagn $tw checked; SKILL.md declares $cur, not yet tagged - tag it when it reaches main"
fi

echo "== the plugin manifests agree with the skill =="
# The repository is its own marketplace, so .claude-plugin/plugin.json carries a
# version a consumer installs by. That is a second version marker in the tree,
# and a version marker that disagrees with what shipped is a defect this skill
# ships a warning about -- so it is checked rather than trusted. The manifests
# are also what the plugin tooling parses; a JSON error there is invisible until
# someone tries to install.
if ! command -v python3 >/dev/null 2>&1; then
  echo "  no python3, skipping"
elif [ ! -f .claude-plugin/plugin.json ]; then
  echo "  no plugin manifest, skipping"
else
  msg=$(python3 - "$cur" <<'MANIFESTS'
import json, sys
declared = sys.argv[1]
try:
    plugin = json.load(open(".claude-plugin/plugin.json"))
except Exception as exc:
    print(".claude-plugin/plugin.json does not parse: %s" % exc); sys.exit(1)
try:
    market = json.load(open(".claude-plugin/marketplace.json"))
except FileNotFoundError:
    market = None
except Exception as exc:
    print(".claude-plugin/marketplace.json does not parse: %s" % exc); sys.exit(1)
if plugin.get("version") != declared:
    print("plugin.json declares version %r, SKILL.md declares %r - bump both in the same change"
          % (plugin.get("version"), declared)); sys.exit(1)
if market is not None:
    entries = [p for p in market.get("plugins", []) if p.get("name") == plugin.get("name")]
    if not entries:
        print("marketplace.json lists no plugin named %r" % plugin.get("name")); sys.exit(1)
    for e in entries:
        if "version" in e and e["version"] != declared:
            print("the marketplace entry declares version %r, SKILL.md declares %r"
                  % (e["version"], declared)); sys.exit(1)
print("plugin.json and marketplace.json agree, both at %s" % declared)
MANIFESTS
  )
  if [ $? -eq 0 ]; then echo "  $msg"; else note "$msg"; fi
fi

echo "== gate scripts stay portable =="
# CI runs ubuntu-latest (bash 5, GNU coreutils). A maintainer's macOS runs bash 3.2
# with BSD or ugrep tools, and the commit hook gates on that one. A GNU-only flag
# would pass for whoever wrote it and fail for the other, so the scripts avoid them.
gnuisms=0; checked=0
while read -r p; do
  case "$p" in ''|'#'*) continue;; esac
  checked=$((checked+1))
  if grep -rnF -- "$p" scripts/*.sh skills/uplevel/*.sh 2>/dev/null; then
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
skills/uplevel/selfcheck.sh | sed 's/^/  /' || fail=1

[ "$fail" = "0" ] && echo "REPO OK" || { echo "REPO FAILED"; exit 1; }
