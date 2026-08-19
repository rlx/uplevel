# uplevel

**Uplevel your repository's engineering process.** Your repo isn't broken — its process is
undocumented, unenforced, and living in three people's heads. That knowledge doesn't survive a new
joiner, a busy week, or an agent working unattended.

Most tools tell you what is wrong. **uplevel tells you what is not there** — no CI on pull
requests, or a check that reports green having run nothing. Absence is the finding nothing else
surfaces, because a missing control produces no error to detect. It reports what it verified and
marks what it could not.

Then it hands back a numbered plan, reply with the numbers you want upleveled.

It changes nothing until you pick. Anything that could fail a colleague's merge is proposed, never
applied.

## Install

```sh
git clone https://github.com/rlx/uplevel.git
cd uplevel
mkdir -p ~/.claude/skills
ln -sfn "$PWD/skills/uplevel" ~/.claude/skills/uplevel
```

`-sfn` matters: without it, a second run follows the existing link and creates a nested copy inside
the clone. Linking means the working tree *is* the installed skill — `git pull` updates it, and
moving or deleting the clone breaks it. To copy instead, so the install survives the clone:

```sh
mkdir -p ~/.claude/skills
rm -rf ~/.claude/skills/uplevel
cp -R skills/uplevel ~/.claude/skills/uplevel
```

The `rm -rf` is what makes it repeatable, and it is why the destination is named explicitly on both
lines. `cp -R` into a path that already exists copies *into* it, so re-running without the removal
nests a copy inside the install — and so does `cp -R skills/uplevel ~/.claude/skills/`, which works
the first time and nests the second. Updating a copy install means running the block again, so this
is the second run, every time.

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

Full worked example: [`references/example-output.md`](skills/uplevel/references/example-output.md).

## What it covers

The gate and what it fails to cover, CI trigger correctness, Actions supply chain and token scopes,
branch protection, release and deploy gates, destructive operations, migrations and backfills, and
how completion is claimed.

Full detail in [`skills/uplevel/README.md`](skills/uplevel/README.md), which ships with the skill.

## Development

```sh
./scripts/install-hooks.sh   # after cloning; git does not install hooks for you
./scripts/check-repo.sh      # runs on every commit and in CI
```

See [`CLAUDE.md`](CLAUDE.md) for project conventions.

## License

MIT. Copyright (c) 2026 Lior Rudnik and Tracey Mercer.
