# uplevel

A Claude Code skill. The deliverable is markdown that changes agent behaviour, so an inaccurate
sentence is a defect.

## Gate

```sh
./scripts/check-repo.sh
```

Runs on every commit via `.git/hooks/pre-commit`, and in CI. Hooks are not tracked by git, so run
`./scripts/install-hooks.sh` after cloning. Bypass with `git commit --no-verify` and say why.

## Constraints

- `skills/uplevel/` is symlinked into `~/.claude/skills/`. The working tree is the installed skill;
  an edit takes effect in the next session.
- `SKILL.md` has a 4000-token budget, enforced by the gate. It loads on every trigger; `references/`
  load only when read. New detail goes in a reference.
- Every command in the skill should have been run and observed to work before it is written down.
  This is a discipline, not an enforced rule: the gate parses fenced blocks and validates `grep -E`
  patterns, which proves they are well-formed, not that they do what the text claims.
- Bumping `version:` in `SKILL.md` alongside any change to `SKILL.md` or `references/` is enforced at
  commit time.
- Every reference file must be linked from `SKILL.md`, and every link must resolve. Both directions
  are enforced.
- CI is `ubuntu-latest` (bash 5, GNU coreutils); a maintainer may be on bash 3.2 with BSD or ugrep
  tools, and the commit hook gates on that one. Gate scripts therefore avoid GNU-only constructs,
  listed in `scripts/gnu-only-constructs.txt` and enforced. Add to that file rather than working
  around it.
- `.claude/guardrails.yml` is the per-repo checklist and must parse as YAML — enforced where
  `python3` and `pyyaml` are available, skipped where they are not. Quote or use a block scalar for
  any value containing `#` or `: `.
