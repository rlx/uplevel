# uplevel

A Claude Code skill. The deliverable is markdown that changes agent behavior, so an inaccurate
sentence is a defect.

## Gate

```sh
./scripts/check-repo.sh
```

Runs on every commit via `.git/hooks/pre-commit`, and in CI. The hook source is tracked at
`scripts/hooks/pre-commit`; git does not install it into `.git/hooks/` for you, so run
`./scripts/install-hooks.sh` after cloning. Bypass with `git commit --no-verify` and say why.

## Constraints

- `skills/uplevel/` is symlinked into `~/.claude/skills/`. The working tree is the installed skill;
  an edit takes effect in the next session.
- `SKILL.md` has a 4000-token budget, enforced by the gate. It loads on every trigger; `references/`
  load only when read. New detail goes in a reference.
- Every command in the skill should have been run and observed to work before it is written down.
  This is a discipline, not an enforced rule: the gate parses fenced blocks and validates `grep -E`
  patterns, which proves they are well-formed, not that they do what the text claims.
- Bumping `version:` in `SKILL.md` alongside any change under `skills/uplevel/` is enforced at commit
  time. Tagging is not: the gate prints when the declared version has no tag, and does not fail.
  Failing at commit time would fail the commit that does the bump, and failing in CI would leave
  `main` red between merge and tag. Tag after merge.
- Every reference file must be linked from `SKILL.md`, and every link must resolve. Both directions
  are enforced.
- CI is `ubuntu-latest` (bash 5, GNU coreutils); a maintainer may be on bash 3.2 with BSD or ugrep
  tools, and the commit hook gates on that one. Gate scripts therefore avoid GNU-only constructs,
  listed in `scripts/gnu-only-constructs.txt` and enforced. Add to that file rather than working
  around it.
- Commit messages and PR bodies say what was done — concise, accurate, simple — and never how it was
  found. Anything beyond what was done is context: ask before adding it. Detail lives in the
  untracked plan, not in public history. The shipped guidance is
  `skills/uplevel/references/commit-hygiene.md`.
- Prose is **en-US** throughout — behavior, license, judgment, labeled. The repository is public and
  the skill ships as text; mixed spelling reads as two authors who never compared notes.
- `.claude/guardrails.yml` is public, so it records only what is **in place**. Absent, unverified, and
  undecided items go in the untracked `.claude/improvement-plan.md` — a public list of a project's own
  gaps is a roadmap for whoever wants to use them.
- `.claude/guardrails.yml` is the per-repo checklist and must parse as YAML — enforced where
  `python3` and `pyyaml` are available, skipped where they are not. Quote or use a block scalar for
  any value containing `#` or `: `.
