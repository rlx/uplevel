# uplevel

A Claude Code skill that finds the engineering controls your repository does not have — CI that never
runs on pull requests, a `check` target that quietly rewrites files, a migration with nothing in front
of it — and hands back a numbered plan. It writes nothing until you reply with the numbers you want.

[![Repo gate](https://github.com/rlx/uplevel/actions/workflows/check.yml/badge.svg)](https://github.com/rlx/uplevel/actions/workflows/check.yml)
[![Release](https://img.shields.io/github/v/release/rlx/uplevel)](https://github.com/rlx/uplevel/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

```sh
claude plugin marketplace add rlx/uplevel
claude plugin install uplevel@uplevel     # plugin@marketplace — both are named uplevel
```

Restart Claude Code, then run `/uplevel` in any repository. `claude plugin update uplevel@uplevel`
moves it to the next release. This repository is its own marketplace: the manifests are in
`.claude-plugin/`, the plugin they serve is this tree, so the version you install is the one
`SKILL.md` declares. [Other ways to install](#install), including a symlinked clone that updates with
`git pull`.

## Why absence is the finding

Your repo isn't broken — its process is undocumented, unenforced, and living in three people's heads.
That knowledge doesn't survive a new joiner, a busy week, or an agent working unattended.

Most tools tell you what is wrong. **uplevel tells you what is not there** — no CI on pull requests,
or a check that reports green having run nothing. Absence is the finding nothing else surfaces,
because a missing control produces no error to detect. A linter reads your code; this reads the
process around it.

It reports what it verified and marks what it could not. Then it hands back a numbered plan and
changes nothing until you reply with the numbers you want. Anything that could fail a colleague's
merge is proposed, never applied.

## What a run looks like

Findings first, each tied to a file and a line, and each either run or explicitly marked unverified:

```
**2. The `fmtcheck` target is not a check — it rewrites your working tree.** Line 8 of the script
it calls invokes the language's *format* command rather than its *check* command, and that command
writes in place. In CI this is harmless on an ephemeral checkout, which is exactly why it has
survived. Evidence, from reading the file — I did not run it, because it would modify the clone.
```

Then a plan, where every item carries the same six fields so you can decide without reading back
through the report:

```
**1. Make `make fmtcheck` actually check.**
prevents: a target named "check" silently rewriting a contributor's working tree
if skipped: item 2 tells people to run a command that edits their files
effort: 15 min, incl. review · affects: everyone who commits
undo: `git revert` — one line · needs: —
```

Reply with the numbers you want — `1, 3, 5` is enough. `if skipped` is there so you can decline an
item on purpose rather than by omission, and `needs` is there so picking `1, 3` never leaves you
half-applied.

Full worked example: [`references/example-output.md`](skills/uplevel/references/example-output.md).

## What it costs, and what it touches

- **It reads; it does not write.** The audit runs read-only. Anything that would change a shared
  outcome is proposed for you to pick.
- **It branches before its first write**, so anything it does build is one `git switch -` from undone.
- **It runs commands it has read and judged safe** — the candidate gate commands — and reports the
  literal output. Anything it did not run is marked unverified rather than assumed.
- **About 43,000 tokens of skill text** load for a full audit, under a 44,000 ceiling this repository
  enforces on itself. That is context competing with your repository, so it is measured with a real
  tokenizer on every change rather than estimated.

## What it covers

The gate and what it fails to cover, CI trigger correctness, Actions supply chain and token scopes,
branch protection, release and deploy gates, destructive operations, migrations and backfills, and
how completion is claimed.

Full detail in [`skills/uplevel/README.md`](skills/uplevel/README.md), which ships with the skill.

## What it will not do

- **Settings-derived findings depend on your access.** Branch protection and org policy need
  permissions an auditor may not have. Reported as unknown, never as absent.
- **It does not measure its own effect.** Nothing re-checks incident rate after a plan is applied.
- **The forge audit is GitHub-first.** On GitLab, Bitbucket, Forgejo or Gitea it will name those
  checks rather than run them.
- **Absent domains**: disaster recovery and restore testing, API and client backwards compatibility,
  feature-flag lifecycle, runtime cost regressions, clock and timezone failures.

The full list is in [the shipped README](skills/uplevel/README.md#limitations). If a finding is wrong,
that is the most useful thing you can report — [open an issue](https://github.com/rlx/uplevel/issues).

## It holds itself to the same checks

A tool that audits engineering process is worth exactly as much as its own. Every commit here runs
[`scripts/check-repo.sh`](scripts/check-repo.sh); CI runs the documented install commands against a
clean `HOME` rather than trusting the README; and
[`.claude/guardrails.yml`](.claude/guardrails.yml) is the per-repo checklist this skill produces,
kept as data rather than prose so [`scripts/check-forge.sh`](scripts/check-forge.sh) can diff it
against the rules actually protecting `main`. Both claims that ever drifted were about GitHub, and
both were caught by a script rather than by good intentions.

## Install

The two-line plugin install is at the top of this page. To install the skill on its own instead, with
no plugin machinery and the working tree *as* the install:

```sh
git clone https://github.com/rlx/uplevel.git
cd uplevel
mkdir -p ~/.claude/skills
ln -sfn "$PWD/skills/uplevel" ~/.claude/skills/uplevel
```

Restart Claude Code. The skill is then available as `/uplevel`.

This links, so the working tree *is* the installed skill and `git pull` updates it. To copy instead,
so the install survives deleting the clone:

```sh
mkdir -p ~/.claude/skills
rm -rf ~/.claude/skills/uplevel
cp -R skills/uplevel ~/.claude/skills/uplevel
```

To uninstall: `rm -rf ~/.claude/skills/uplevel` — it removes the link or the copy, never the clone.

<details>
<summary>Why each command is written the way it is</summary>

`-sfn` on the link: without `n`, a second run follows the existing link and creates a nested copy
inside the clone.

`rm -rf` before the copy: `cp -R` into a path that already exists copies *into* it, so re-running
without the removal nests a copy inside the install. Naming the destination explicitly does not
prevent this — `cp -R skills/uplevel ~/.claude/skills/` nests on the second run too. Updating a copy
install means running the block again, so this is the second run, every time.

For a single project rather than every project, use `.claude/skills/uplevel` in that repo and commit
it. Both commands are run against a clean `HOME` in CI, so this section is executed rather than
asserted.

</details>

## Use

```
/uplevel
```

Or ask in plain language: "uplevel this repo", "audit our engineering process", "we keep breaking
production — what should we enforce?"

## Development

```sh
./scripts/install-hooks.sh   # after cloning; git does not install hooks for you
./scripts/check-repo.sh      # runs on every commit and in CI
```

See [`CLAUDE.md`](CLAUDE.md) for project conventions and [`CONTRIBUTING.md`](CONTRIBUTING.md) before
opening a pull request.

## Changelog

[`CHANGELOG.md`](CHANGELOG.md), and the [releases](https://github.com/rlx/uplevel/releases).

## License

MIT. Copyright (c) 2026 Lior Rudnik and Tracey Mercer.
