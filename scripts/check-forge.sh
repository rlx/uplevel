#!/usr/bin/env bash
# Checks .claude/guardrails.yml against the forge it describes: the rules that
# actually protect main, whether the version main declares was released, and the
# description and topics a stranger finds the repository by.
#   ./scripts/check-forge.sh
#
# Everything in check-repo.sh reads the tree, so the commit hook can run it
# offline in about a second. These claims are about GitHub, and two of them drifted
# within four days of being written down while every tree-side claim stayed
# true. Network and an authenticated gh make this a CI step instead, on the same
# reasoning as check-install.sh: the required job carries it, the hook does not.
#
# gh missing or unauthenticated is a skip -- that is a contributor's laptop, and
# the forge is not theirs to answer for. An API error once authenticated is a
# failure, not a skip: a check that cannot see what it audits and says nothing
# is the "green and proving nothing" shape this repository ships warnings about.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
fail=0; note() { echo "  !! $1"; fail=1; }
BRANCH=main

if ! command -v gh >/dev/null 2>&1; then
  echo "no gh here — the forge claims are unchecked on this machine; CI gates them"
  exit 0
elif ! gh auth status >/dev/null 2>&1; then
  echo "gh is not authenticated — the forge claims are unchecked here; CI gates them"
  exit 0
elif ! command -v python3 >/dev/null 2>&1; then
  echo "no python3 — the forge claims are unchecked on this machine; CI gates them"
  exit 0
elif ! python3 -c 'import yaml' >/dev/null 2>&1; then
  echo "no pyyaml — the forge claims are unchecked on this machine; CI gates them"
  exit 0
fi

echo "== main is protected by the rules the checklist records =="
# The checklist records these as data rather than prose so they can be diffed.
# The prose note beside them is still prose, and still hand-maintained.
want="$(mktemp)"; got="$(mktemp)"; live="$(mktemp)"
python3 - > "$want" <<'WANTED'
import sys, yaml
doc = yaml.safe_load(open(".claude/guardrails.yml"))
entry = None
for c in doc.get("checks", []):
    if c.get("id") == "branch-protection-required-checks":
        entry = c
for key in ("required_contexts", "required_rules"):
    if entry is None or not entry.get(key):
        sys.exit("the checklist entry records no %s" % key)
lines = ["context: %s" % c for c in entry["required_contexts"]]
lines += ["rule: %s" % r for r in entry["required_rules"]]
lines += ["strict: %s" % str(bool(entry.get("strict_up_to_date"))).lower()]
print("\n".join(sorted(lines)))
WANTED
if [ $? -ne 0 ]; then
  note "could not read the recorded rules out of .claude/guardrails.yml"
elif ! gh api "repos/{owner}/{repo}/rules/branches/$BRANCH" > "$live" 2>/dev/null; then
  note "could not read the rules protecting $BRANCH — gh is authenticated, so this is a real failure, not an absent control"
else
  python3 - "$live" > "$got" <<'ACTUAL'
import json, sys
rules = json.load(open(sys.argv[1]))
lines = ["rule: %s" % r["type"] for r in rules]
for r in rules:
    if r["type"] != "required_status_checks":
        continue
    p = r.get("parameters", {})
    lines += ["context: %s" % c["context"] for c in p.get("required_status_checks", [])]
    lines += ["strict: %s" % str(bool(p.get("strict_required_status_checks_policy"))).lower()]
print("\n".join(sorted(lines)))
ACTUAL
  if diff -u "$want" "$got" > /dev/null 2>&1; then
    echo "  $(grep -c 'context: ' "$want") required checks and $(grep -c 'rule: ' "$want") rules, as recorded"
  else
    note "the checklist and the ruleset disagree about what protects $BRANCH:"
    diff -u "$want" "$got" | grep -E '^[-+][^-+]' | while IFS= read -r d; do
      case "$d" in
        -*) echo "     recorded, not in force: ${d#-}";;
        +*) echo "     in force, not recorded: ${d#+}";;
      esac
    done
  fi
fi
rm -f "$want" "$got" "$live"

echo "== the description and topics the checklist records are the ones set =="
# The two sentences a stranger reads before the README: the description GitHub
# search returns, and the topics the plugin directories index by. Both are
# settings rather than files, which is the shape that drifted twice here before
# it was written down as data -- nothing in the tree could contradict them, so
# nothing did.
want="$(mktemp)"; got="$(mktemp)"; live="$(mktemp)"
python3 - > "$want" <<'WANTED'
import sys, yaml
doc = yaml.safe_load(open(".claude/guardrails.yml"))
entry = None
for c in doc.get("checks", []):
    if c.get("id") == "repository-description-and-topics":
        entry = c
if entry is None or not entry.get("description") or not entry.get("topics"):
    sys.exit("the checklist records no description or topics")
lines = ["description: %s" % " ".join(entry["description"].split())]
lines += ["topic: %s" % t for t in entry["topics"]]
print("\n".join(sorted(lines)))
WANTED
if [ $? -ne 0 ]; then
  note "could not read the recorded description and topics out of .claude/guardrails.yml"
elif ! gh api "repos/{owner}/{repo}" > "$live" 2>/dev/null; then
  note "could not read the repository settings — gh is authenticated, so this is a real failure, not an absent control"
else
  python3 - "$live" > "$got" <<'ACTUAL'
import json, sys
repo = json.load(open(sys.argv[1]))
lines = ["description: %s" % " ".join((repo.get("description") or "").split())]
lines += ["topic: %s" % t for t in repo.get("topics", [])]
print("\n".join(sorted(lines)))
ACTUAL
  if diff -u "$want" "$got" > /dev/null 2>&1; then
    echo "  the description and $(grep -c 'topic: ' "$want") topics, as recorded"
  else
    note "the checklist and the repository settings disagree:"
    diff -u "$want" "$got" | grep -E '^[-+][^-+]' | while IFS= read -r d; do
      case "$d" in
        -*) echo "     recorded, not set: ${d#-}";;
        +*) echo "     set, not recorded: ${d#+}";;
      esac
    done
  fi
fi
rm -f "$want" "$got" "$live"

echo "== code scanning analyzes the languages the checklist records =="
# Default setup picks its own languages from what is in the tree, and moves them
# without a commit that says so: tracking one .py file added "python" here within
# minutes, while this file still recorded ["actions"]. The set is GitHub's to
# change, which is what makes it worth diffing rather than trusting.
#
# This is the one claim CI cannot answer. The endpoint wants admin-level access;
# the gate job holds contents: read, and was observed to fail on this call with
# security-events: read added too. Widening a required job's token to read one
# config is the worse trade, so a forbidden response is a skip that says so on
# every run, and a maintainer's gh gates it. Any OTHER failure is still a
# failure -- "cannot see it" and "it broke" must not print the same line.
want="$(mktemp)"; got="$(mktemp)"; live="$(mktemp)"; err="$(mktemp)"
python3 - > "$want" <<'WANTED'
import sys, yaml
doc = yaml.safe_load(open(".claude/guardrails.yml"))
entry = None
for c in doc.get("checks", []):
    if c.get("id") == "code-scanning-languages-recorded":
        entry = c
if entry is None or not entry.get("languages") or not entry.get("query_suite"):
    sys.exit("the checklist records no languages or query suite")
lines = ["language: %s" % l for l in entry["languages"]]
lines += ["query suite: %s" % entry["query_suite"]]
print("\n".join(sorted(lines)))
WANTED
if [ $? -ne 0 ]; then
  note "could not read the recorded code scanning setup out of .claude/guardrails.yml"
elif ! gh api "repos/{owner}/{repo}/code-scanning/default-setup" > "$live" 2>"$err"; then
  if grep -qE 'HTTP 40[34]' "$err"; then
    echo "  this token may not read the code scanning setup — unchecked here; a maintainer's gh gates it"
  else
    note "could not read the code scanning setup — gh is authenticated, so this is a real failure, not an absent control"
  fi
else
  python3 - "$live" > "$got" <<'ACTUAL'
import json, sys
setup = json.load(open(sys.argv[1]))
lines = ["language: %s" % l for l in setup.get("languages", [])]
lines += ["query suite: %s" % (setup.get("query_suite") or "")]
print("\n".join(sorted(lines)))
ACTUAL
  if diff -u "$want" "$got" > /dev/null 2>&1; then
    echo "  $(grep -c 'language: ' "$want") languages on the $(awk -F': ' '/query suite/ { print $2 }' "$want") suite, as recorded"
  else
    note "the checklist and code scanning disagree:"
    diff -u "$want" "$got" | grep -E '^[-+][^-+]' | while IFS= read -r d; do
      case "$d" in
        -*) echo "     recorded, not analyzed: ${d#-}";;
        +*) echo "     analyzed, not recorded: ${d#+}";;
      esac
    done
  fi
fi
rm -f "$want" "$got" "$live" "$err"

echo "== the version main declares has been released =="
# The checklist recorded "git tag + GitHub release" while nine consecutive tags
# had no release and the Releases page named a version nine behind. Checked
# forward, like the changelog rule: it asks about the version in the tree, so a
# tag that shipped without its release fails the next run rather than never.
#
# Both questions go to the forge, not to the local clone. Asking git whether the
# tag exists passed here and was vacuous in CI: actions/checkout fetches no tags,
# so rev-parse failed on the runner, every version read as "not tagged yet", and
# the check reported OK having compared nothing. It was green on the first run
# after being written, on the one repository whose release it was watching.
cur="$(awk -F'[ \t]*:[ \t]*' '/^version:/ { print $2; exit }' skills/uplevel/SKILL.md)"
if ! gh api "repos/{owner}/{repo}/git/ref/tags/v$cur" >/dev/null 2>&1; then
  echo "  $cur is not tagged on the forge yet; the release is due when the tag is"
elif gh release view "v$cur" >/dev/null 2>&1; then
  echo "  v$cur is tagged and released"
else
  note "v$cur is tagged with no release — cut it, or the Releases page keeps naming an older version as latest"
fi

[ "$fail" = "0" ] && echo "FORGE OK" || { echo "FORGE FAILED"; exit 1; }
