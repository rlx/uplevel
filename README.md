# uplevel

A Claude Code skill that audits a repository's engineering process and proposes improvements.

It investigates the repo, reports what it found, and returns a numbered plan. It changes nothing
until you pick items from that plan.

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

## Usage

```
/uplevel
```

Or ask in plain language: "uplevel this repo", "audit our engineering process", "set up a
pre-commit gate".

See [`skills/uplevel/README.md`](skills/uplevel/README.md) for what the skill covers.

## Development

```sh
./scripts/install-hooks.sh   # after cloning; hooks are not tracked by git
./scripts/check-repo.sh      # runs on every commit and in CI
```

See [`CLAUDE.md`](CLAUDE.md) for project conventions.

## License

MIT. Copyright (c) 2026 Lior Rudnik and Tracey Mercer.
