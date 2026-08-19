# uplevel

A Claude Code skill that audits your repository's engineering process and returns a ranked plan to
fix it.

Most repositories keep their process in people's heads: which command is the real gate, which
environment a script points at, which operation cannot be undone. That knowledge does not survive a
new joiner, a busy week, or an agent working unattended.

uplevel finds the process that actually exists, writes it down, and names what is missing — no CI on
pull requests, actions pinned to mutable tags, a check that reports green having run nothing, a
deploy with no tested rollback. It reports what it verified and marks what it could not.

Then it hands back a numbered plan. Every item says what it prevents, what it costs, who it affects,
and how to undo it, ordered by damage prevented per unit of effort. Reply with the numbers you want.

It changes nothing until you pick. Anything that could fail a colleague's merge — branch protection,
required checks, shared hooks — is proposed for a maintainer, never applied.

## Install

```sh
git clone https://github.com/rlx/uplevel.git
cd uplevel
mkdir -p ~/.claude/skills
ln -sfn "$PWD/skills/uplevel" ~/.claude/skills/uplevel
```

`-sfn` matters: without it, a second run follows the existing link and creates a nested copy inside
the clone. Linking means the working tree *is* the installed skill — `git pull` updates it, and moving
or deleting the clone breaks it. To copy instead, so the install survives the clone:

```sh
cp -R skills/uplevel ~/.claude/skills/uplevel
```

Name the destination explicitly there too. `cp -R skills/uplevel ~/.claude/skills/` works the first
time and nests a copy inside itself the second.

Restart Claude Code. The skill is then available as `/uplevel`. For a single project, copy it into
that repo's `.claude/skills/` and commit it.

To uninstall: `rm -rf ~/.claude/skills/uplevel` (removes the link or the copy, never the clone).

## Use

```
/uplevel
```

Or ask in plain language: "uplevel this repo", "audit our engineering process", "we keep breaking
production — what should we enforce?"

## What the output looks like

Findings first, each tied to a file and line. Then a plan where every item carries the same six
fields, so you can decide without reading back through the report:

```
**1. Make `make fmtcheck` actually check.**
prevents: a target named "check" silently rewriting a contributor's working tree
if skipped: item 2 tells people to run a command that edits their files
effort: 15 min, incl. review · affects: everyone who commits
undo: `git revert` — one line · needs: —
```

Reply with the numbers you want. `if skipped` is there so you can decline an item on purpose rather
than by omission, and `needs` is there so picking `1, 3` never leaves you half-applied.

Full worked example, from a real audit of `hashicorp/terraform`:
[`references/example-output.md`](skills/uplevel/references/example-output.md).

## What it covers

The gate and what it fails to cover, CI trigger correctness, Actions supply chain and token scopes,
branch protection, release and deploy gates, destructive operations, migrations and backfills, and
how completion is claimed.

Full detail in [`skills/uplevel/README.md`](skills/uplevel/README.md), which ships with the skill.

## What it has been tested on

22 public repositories across 9 languages — Angular, Grafana, Symfony, Airflow, Rails, Rust,
Terraform, Django, Neovim, Redis, five NVIDIA projects and seven others. 19 of those audits were run
by agents with no prior context, and every headline finding was re-checked against the source file,
commit or API response it rested on.

**Two limits worth knowing before you rely on it.**

Every repository tested was mature, public, and multi-contributor. **None had a deployed service, a
production database, or an on-call rotation the audit could observe** — so the parts of this skill
that deal with deploys, migrations against real data, and environment safety are the least exercised,
and they are also the parts it argues matter most. If your process problem is a Friday deploy nobody
watched, this has not yet been tested on your case.

The three modes are unevenly proven. Investigation and enforcement each have 22 repositories behind
them; automation has four. The enforcement runs asked for a real change in each repository — a
migration, a public API addition, a release-path check — and only six of the 22 could run the
project's own gate, the rest lacking a toolchain. That is the ordinary condition, and the reports say
so rather than substituting a command that happened to run.

## Development

```sh
./scripts/install-hooks.sh   # after cloning; git does not install hooks for you
./scripts/check-repo.sh      # runs on every commit and in CI
```

See [`CLAUDE.md`](CLAUDE.md) for project conventions.

## License

MIT. Copyright (c) 2026 Lior Rudnik and Tracey Mercer.
