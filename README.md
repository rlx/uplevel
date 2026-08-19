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

## Development

```sh
./scripts/install-hooks.sh   # after cloning; hooks are not tracked by git
./scripts/check-repo.sh      # runs on every commit and in CI
```

See [`CLAUDE.md`](CLAUDE.md) for project conventions.

## License

MIT. Copyright (c) 2026 Lior Rudnik and Tracey Mercer.
