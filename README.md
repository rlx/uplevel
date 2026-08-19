# uplevel

A Claude Code skill for codebases that keep breaking in production because the engineering process
lives in people's heads.

It investigates a repository, reports what it found, and hands back a **numbered plan** of proposed
changes — then builds only the items you pick. It is advisory by default: it changes nothing that
affects other people without being asked.

The skill itself lives in [`skills/uplevel/`](skills/uplevel/) — see
[its README](skills/uplevel/README.md) for what it does and how it behaves.

## Install

```sh
# personal — available in every project on this machine
mkdir -p ~/.claude/skills
ln -s "$PWD/skills/uplevel" ~/.claude/skills/uplevel

# or copy, if you prefer not to symlink
cp -R skills/uplevel ~/.claude/skills/
```

Restart Claude Code, then confirm with `/skills`.

For a project rather than a machine, copy it to that repo's `.claude/skills/` instead and commit it.

## Layout

```
skills/uplevel/   the skill — SKILL.md + references/
research/                        evidence behind the design: prior-art survey, gap analysis
```

`research/corpus/` is gitignored — it holds shallow clones of other people's skill repos used for
the survey, and is reproducible from `research/prior-art.md`.

## Contributing

```sh
./scripts/install-hooks.sh   # after a fresh clone — hooks are not tracked by git
./scripts/check-repo.sh      # the gate; also runs on every commit and in CI
```

See [`CLAUDE.md`](CLAUDE.md) for what a session here needs to know that the code does not say.

## License

MIT — see [`LICENSE`](LICENSE). Copyright (c) 2026 Lior Rudnik and Tracey Mercer.
