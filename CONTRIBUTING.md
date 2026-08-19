# Contributing

The deliverable is markdown that changes how an agent behaves, so an inaccurate sentence is a defect
in the same way a wrong line of code is. Most of what follows exists to keep that true.

## Before you open a pull request

```sh
./scripts/install-hooks.sh   # once, after cloning
./scripts/check-repo.sh      # the gate; runs on every commit and in CI
```

The gate takes well under a second. If it fails it names what to fix. Bypass it with
`git commit --no-verify` only when you know why, and say so in the pull request.

## The rules the gate enforces

- **`SKILL.md` has a 4000-token budget.** It loads on every trigger; `references/` load only when
  read. New detail goes in a reference, not in `SKILL.md`.
- **Bump `version:` in `SKILL.md`** in the same commit as any change to `SKILL.md` or `references/`.
- **Every reference must be linked from `SKILL.md`, and every link must resolve.** Both directions.
- **References cite each other by bare filename** — `evidence.md`, not `references/evidence.md`, which
  would mean `references/references/`.
- **No GNU-only constructs in gate scripts.** CI is ubuntu-latest; a maintainer may be on bash 3.2
  with BSD tools. The list is `scripts/gnu-only-constructs.txt` — add to it rather than working
  around it.
- **No machine- or project-specific strings.** Patterns in `skills/uplevel/leak-patterns.txt`.

## The rule the gate cannot enforce

**Every command the skill prints must have been run, here, and observed to work.** The gate checks
that a shipped command parses and that its regex compiles; it cannot check that the command does what
the sentence claims. That one is on you.

This matters more than it sounds. A gate command that does not exist is worse than no gate — it
manufactures confidence, and the next session reports green having run nothing.

## Adding a check

Anything you add to the gate must be **proven able to fail**. Break the thing it checks, watch it go
red, restore, watch it go green, and say in the pull request that you did. If the check has a skip
path — it degrades when a tool is absent — exercise that too: an unexercised skip is how a check
becomes vacuous on exactly the machines that needed it, while still reading as green.

A check that searches the tree is *in* the tree. Keep its patterns in a data file, or it will match
itself and report a defect it invented.

## Commits and pull requests

State what changed and why in the code's own terms. Keep it concise; no AI attribution.

## Scope

Repository-specific checks belong in that repository's own checklist, never in the shipped skill —
`references/checklist.md` explains the split. A check that fires everywhere and matters nowhere costs
attention on every audit.
