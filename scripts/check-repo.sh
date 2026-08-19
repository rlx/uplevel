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
if [ "$tagn" = "0" ]; then
  echo "  no v* tags yet; SKILL.md declares $cur"
elif git rev-parse -q --verify "refs/tags/v$cur" >/dev/null 2>&1; then
  echo "  $tagn $tw checked; SKILL.md declares $cur, which is tagged"
else
  echo "  $tagn $tw checked; SKILL.md declares $cur, not yet tagged - tag it when it reaches main"
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

echo "== the skill's own gate =="
skills/uplevel/selfcheck.sh | sed 's/^/  /' || fail=1

[ "$fail" = "0" ] && echo "REPO OK" || { echo "REPO FAILED"; exit 1; }
