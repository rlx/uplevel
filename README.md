# uplevel

**Uplevel your repository's engineering process.** Your repo isn't broken — its process is
undocumented, unenforced, and living in three people's heads: which command is the real gate, which
environment a script points at, which operation cannot be undone. That knowledge doesn't survive a
new joiner, a busy week, or an agent working unattended.

Most tools tell you what is wrong. **uplevel tells you what is not there** — no CI on pull requests,
actions pinned to mutable tags, a check that reports green having run nothing, a deploy with no tested
rollback. Absence is the finding nothing else surfaces, because a missing control produces no error to
detect. It reports what it verified and marks what it could not.

Then it hands back a numbered plan: what each item prevents, what skipping it costs, the effort in
maintainer-hours, who it affects, how to undo it, and what it depends on. Reply with the numbers you
want.

It changes nothing until you pick. Anything that could fail a colleague's merge — branch protection,
required checks, shared hooks — is proposed for a maintainer, never applied.

## Install

```sh
git clone https://github.com/rlx/uplevel.git
cd uplevel
mkdir -p ~/.claude/skills
ln -sfn "$PWD/skills/uplevel" ~/.claude/skills/uplevel
```

Linking means the working tree *is* the installed skill: `git pull` updates it, and moving the clone
breaks it. To copy instead:

```sh
cp -R skills/uplevel ~/.claude/skills/uplevel
```

Name the destination explicitly in both forms — omitting it nests a copy inside itself on the second
run.

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

Reply with the numbers you want. `needs` is what keeps `1, 3` from leaving you half-applied.

Full worked example: [`references/example-output.md`](skills/uplevel/references/example-output.md).

## What it covers

The gate and what it fails to cover, CI trigger correctness, Actions supply chain and token scopes,
branch protection, release and deploy gates, destructive operations, migrations and backfills, and
how completion is claimed.

Full detail in [`skills/uplevel/README.md`](skills/uplevel/README.md), which ships with the skill.

## Limits

Exercised against public repositories with real history and many contributors. **Not exercised
against a deployed service, a production database, or an on-call rotation** — so the parts dealing
with deploys, migrations against real data, and environment safety are the least proven, and they are
also the parts it argues matter most.

A repository you have just cloned usually cannot be built. The report says which commands it ran and
marks the rest unverified, rather than substituting one that happened to succeed.

## Development

```sh
./scripts/install-hooks.sh   # after cloning; git does not install hooks for you
./scripts/check-repo.sh      # runs on every commit and in CI
```

See [`CLAUDE.md`](CLAUDE.md) for project conventions.

## License

MIT. Copyright (c) 2026 Lior Rudnik and Tracey Mercer.
