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
mkdir -p ~/.claude/skills
ln -s "$PWD/skills/uplevel" ~/.claude/skills/uplevel
```

Or copy it instead of linking:

```sh
cp -R skills/uplevel ~/.claude/skills/
```

Restart Claude Code and confirm with `/skills`. For a single project, copy it to that repo's
`.claude/skills/` and commit it.

## Use

```
/uplevel
```

Or ask in plain language: "uplevel this repo", "audit our engineering process", "we keep breaking
production — what should we enforce?"

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
./scripts/install-hooks.sh   # after cloning; hooks are not tracked by git
./scripts/check-repo.sh      # runs on every commit and in CI
```

See [`CLAUDE.md`](CLAUDE.md) for project conventions.

## License

MIT. Copyright (c) 2026 Lior Rudnik and Tracey Mercer.
