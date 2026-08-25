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
- Load cost is measured with a real tokenizer when `tiktoken` is importable, and falls back to a word
  count that reads 3-9% low, in which case the gate prints the figures and asserts no ceiling. CI
  installs it, so `main` is always measured exactly. The Mode A working set has a ceiling, currently
  44000; raise it in the change that needs the room and say why.
- `SKILL.md` has a token budget, currently 6000, enforced by the gate. It loads on every trigger;
  `references/` load only when read. New detail goes in a reference by default. The budget makes
  growth deliberate rather than capping quality — raise it in the same change when something belongs
  in the always-loaded file, and say why.
- Every command in the skill should have been run and observed to work before it is written down.
  This is a discipline, not an enforced rule: the gate parses fenced blocks and validates `grep -E`
  patterns, which proves they are well-formed, not that they do what the text claims.
- Bumping `version:` in `SKILL.md` alongside any change under `skills/uplevel/` is enforced at commit
  time. Tagging is not: the gate prints when the declared version has no tag, and does not fail.
  Failing at commit time would fail the commit that does the bump, and failing in CI would leave
  `main` red between merge and tag. Tag after merge — and cut the GitHub release in the same sitting.
  `scripts/check-forge.sh` fails once a declared version is tagged with no release, which is how nine
  consecutive tags stopped being possible; before it existed, nothing looked.
- What `.claude/guardrails.yml` says about GitHub — the required checks, the rules protecting `main`,
  the release — is data, not prose, and `scripts/check-forge.sh` diffs it against GitHub. Every claim
  in that file about the tree was already checked by a script; the claims about the forge were the
  ones that drifted. Update the fields, not only the note.
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
- Plan files live in `.claude/plans/`, untracked. Plan mode writes to `~/.claude/plans/`, a flat
  directory every project on this machine shares, under a random slug that does not name the repo it
  belongs to — so a plan left there is both invisible to this project and in reach of another one's
  agent. Move it in, and name it for what it is. Its contents are the same class as the improvement
  plan: traffic figures, unfixed weaknesses, draft copy.
- `.claude/guardrails.yml` is public, so it records only what is **in place**. Absent, unverified, and
  undecided items go in the untracked `.claude/improvement-plan.md` — a public list of a project's own
  gaps is a roadmap for whoever wants to use them.
- `.claude/guardrails.yml` is the per-repo checklist and must parse as YAML — enforced where
  `python3` and `pyyaml` are available, skipped where they are not. Quote or use a block scalar for
  any value containing `#` or `: `.
- The defects this skill ships come from a blind validation program kept outside this repository:
  rounds of ten previously-unseen repositories, audited against the current version, every finding
  reproduced against the repository before it ships. That tree is deliberately unpublished — it
  names third-party projects and their unfixed findings — and deliberately not a git repository,
  which also leaves it **unbacked, local to one machine, and the only record of which repositories
  have already been used**. Losing it costs the program, not the skill: nothing here builds,
  tests, or gates against it.
