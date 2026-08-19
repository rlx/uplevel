# engineering-guardrails — working rules

This repo is the source of a Claude Code skill. Its product is prose that changes how agents behave,
so a wrong sentence here is a defect that ships.

## The gate

```sh
./scripts/check-repo.sh          # ~0.2s — links, hook, then the skill's own selfcheck
```

It runs automatically on every commit via `.git/hooks/pre-commit`. **Hooks are not tracked by git**, so
after a fresh clone run `./scripts/install-hooks.sh` — the gate checks that you did, because a clone
that silently has no gate is exactly the failure this repo exists to prevent.

Bypass deliberately with `git commit --no-verify`, and say why in your reply.

## Two things that are easy to get wrong here

- **`skills/engineering-guardrails/` is symlinked into `~/.claude/skills/`.** The working tree *is* the
  deployed artifact — an edit is live in the next session. There is no build, no publish, no staging.
  Rollback is `git` and nothing else.
- **`SKILL.md` must stay under 4000 tokens.** It loads on every single trigger, while `references/*.md`
  load only when read. The gate enforces the budget. New detail belongs in a reference, not here.

## Adding to the skill

- Every command written into the skill must have been **run and observed to work**. The gate parses
  fenced blocks and validates `grep -E` patterns, because a PCRE lookahead once shipped and failed on
  every repo it ran on.
- Every reference file must be linked from `SKILL.md`, and every link must resolve. Both directions
  are enforced.
- Claims about how repos behave belong in `research/validation/findings.md` with the measurement that
  backs them. A rule with no evidence is an opinion in a list of facts.

## Corpora

`research/validation/corpus*/` are shallow clones of other people's repositories, gitignored and
reproducible from the commands in `research/validation/README.md`. They are safe to delete; they cost
a few minutes to re-clone. Never write to them, and never propose anything upstream from them.
