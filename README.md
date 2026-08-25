# uplevel

A Claude Code skill that uplevels a repository's engineering process.

Your repo isn't broken — its process is undocumented, unenforced, and living in three people's
heads. That knowledge doesn't survive a new joiner, a busy week, or an agent working unattended.

Most tools tell you what is wrong. **uplevel tells you what is not there** — no CI on pull
requests, or a check that reports green having run nothing. Absence is the finding nothing else
surfaces, because a missing control produces no error to detect. It reports what it verified and
marks what it could not.

It hands back a numbered plan and changes nothing until you reply with the numbers you want.
Anything that could fail a colleague's merge is proposed, never applied.

## Install as a plugin

```sh
claude plugin marketplace add rlx/uplevel
claude plugin install uplevel@uplevel
```

Or from inside a session: `/plugin marketplace add rlx/uplevel`, then `/plugin install
uplevel@uplevel`.

Restart Claude Code. The skill is then available as `/uplevel`, and `claude plugin update
uplevel@uplevel` moves it to the next release — qualified with the marketplace, which is the form
that command takes. This repository is its own marketplace — the manifests are in
`.claude-plugin/`, and the plugin they serve is this tree, so the version you install is the one
`SKILL.md` declares.

To install the skill on its own instead, with no plugin machinery and the working tree *as* the
install, use the section below.

## Install

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

## Changelog

[`CHANGELOG.md`](CHANGELOG.md), and the [releases](https://github.com/rlx/uplevel/releases).

## License

MIT. Copyright (c) 2026 Lior Rudnik and Tracey Mercer.
