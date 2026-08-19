# engineering-guardrails

A Claude Code skill for codebases that keep breaking in production because the engineering process
lives in people's heads.

It investigates a repository, reports what it found, and hands back a **numbered plan** of proposed
changes — then builds only the items you pick. It is advisory by default: it changes nothing that
affects other people without being asked.

The skill itself lives in [`skills/engineering-guardrails/`](skills/engineering-guardrails/) — see
[its README](skills/engineering-guardrails/README.md) for what it does and how it behaves.

## Install

```sh
# personal — available in every project on this machine
mkdir -p ~/.claude/skills
ln -s "$PWD/skills/engineering-guardrails" ~/.claude/skills/engineering-guardrails

# or copy, if you prefer not to symlink
cp -R skills/engineering-guardrails ~/.claude/skills/
```

Restart Claude Code, then confirm with `/skills`.

For a project rather than a machine, copy it to that repo's `.claude/skills/` instead and commit it.

## Layout

```
skills/engineering-guardrails/   the skill — SKILL.md + references/
research/                        evidence behind the design: prior-art survey, gap analysis
```

`research/corpus/` is gitignored — it holds shallow clones of other people's skill repos used for
the survey, and is reproducible from `research/prior-art.md`.
