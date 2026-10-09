# uplevel

Finds the engineering controls your repository does not have — CI that never runs on pull requests, a
`check` target that quietly rewrites files, a migration with nothing in front of it — and hands back
a numbered plan. It writes nothing until you reply with the numbers you want.

It is also written to load before the risky moments in ordinary work — a migration, a backfill, a
deploy. Its rules for those are short: say which environment you are pointed at before touching it,
stop and ask before anything irreversible, and read the names of secrets, never their values.

## What a run looks like

Findings first, each tied to a file and a line, and each either run or marked unverified. This one is
from the worked example that ships with the skill:

```
**2. The `fmtcheck` target is not a check — it rewrites your working tree.** Line 8 of the script it
calls invokes the language's format command rather than its check command, and that command writes
in place. In CI this is harmless on an ephemeral checkout, which is exactly why it has survived.
Evidence, from reading the file — I did not run it, because it would modify the clone.
```

Then a plan in which every item carries the same six fields, so you can decide without reading back
through the report:

```
**1. Make `make fmtcheck` actually check.**
prevents: a target named "check" silently rewriting a contributor's working tree · if skipped: item 2
tells people to run a command that edits their files
effort: 15 min, incl. review · affects: everyone who commits
undo: `git revert` — one line · needs: —
```

Reply with the numbers you want — `1, 3, 5` is enough — and it builds those and nothing adjacent.

## What it looks for

- **What validates a change** before it reaches the default branch, and before it reaches users: the
  real gate, what it does not cover, and whether anything requires it.
- **Controls that exist and do nothing**: a required check nobody emits, a ruleset left in evaluate
  mode, a job that reports green having run nothing.
- **The release path**: unpinned actions beside a publish credential, a release that never reads the
  result of its own tests, an image that carries more than the source.
- **Irreversible operations**: migrations that drop data, commands that default to every environment,
  state nobody can regenerate.
- **A security read of the change itself**, for the logic errors a pattern scanner does not catch.

Absences are named, not skipped, and what could not be seen is reported as unknown, never as missing.

## What it runs, reads and sends

The plugin is instructions and one local script. It has no hooks, no MCP server and no background
process, and it makes no network call of its own.

- **An agent following it runs commands in your repository**: `git`, your own build and test
  commands once it has read them, and read-only `gh api` calls through the GitHub CLI you already
  authenticated. It is told never to run anything that writes to shared infrastructure, spends money,
  or needs credentials it had to go and find.
- **It reads configuration, including files that hold credentials, for key names only.** The
  environment check it prints before a deploy masks the credentials in a connection string and asks
  `kubectl`, `aws` and `gcloud` which account is active. Nothing is sent anywhere but your terminal.
- **`skills/uplevel/selfcheck.sh`** checks the skill's own files. It is run by hand, by people working
  on the skill.

## Rules it holds itself to

- **Advisory.** It proposes, you choose. Nothing affecting other people is applied unasked.
- **Branches before its first write**, so anything it builds is one `git switch -` from undone.
- **Discovers, never guesses.** Every command it reports is one it ran and watched pass, or is
  marked unverified.

## Install as a plugin

```sh
claude plugin marketplace add rlx/uplevel
claude plugin install uplevel@uplevel
```

Both names are `uplevel` because the repository is its own marketplace, and `install` wants the
`plugin@marketplace` form. Restart Claude Code; the skill is then available as `/uplevel`, and
`claude plugin update uplevel@uplevel` moves it to the next release.

## Install

To install the skill on its own instead, with no plugin machinery. **These commands run from a clone
of the repository**, not from an installed copy of the skill:

```sh
git clone https://github.com/rlx/uplevel.git
cd uplevel
```

Personal — available in every project:

```sh
mkdir -p ~/.claude/skills
rm -rf ~/.claude/skills/uplevel
cp -R plugin/skills/uplevel ~/.claude/skills/uplevel
```

Project — checked in, shared with the team:

```sh
mkdir -p .claude/skills
rm -rf .claude/skills/uplevel
cp -R plugin/skills/uplevel .claude/skills/uplevel
```

The `rm -rf` is what makes both repeatable, and updating a copy install means running the block
again. `cp -R` into a path that already exists copies *into* it, so without the removal the second run
nests a copy inside the install — and naming the destination explicitly does not prevent that, only
the removal does.

To link rather than copy, so that `git pull` updates the install, see
[the repository README](https://github.com/rlx/uplevel#install). Restart Claude Code; the skill is
then available as `/uplevel`.

## Use

```
/uplevel
```

Or ask in plain language: "uplevel this repo", "audit our engineering process", "we keep breaking
production — what should we enforce?" The parts only you know — which data is irreplaceable, what
broke last quarter, who may deploy — are worth correcting before you choose from the plan.

## Contents

| file | what it carries |
|---|---|
| [`SKILL.md`](skills/uplevel/SKILL.md) | the three modes, branching, and the invariants |
| [`references/mode-a-investigate.md`](skills/uplevel/references/mode-a-investigate.md) | the audit procedure, report shape and plan rules |
| [`references/mode-c-enforce.md`](skills/uplevel/references/mode-c-enforce.md) | check-in, shipping, hazards, incidents, claims |
| [`references/discovery.md`](skills/uplevel/references/discovery.md) | finding the real gate; toolchain preflight; cleanup |
| [`references/production.md`](skills/uplevel/references/production.md) | environments, secrets, deploys, migrations, incidents |
| [`references/forge-hygiene.md`](skills/uplevel/references/forge-hygiene.md) | CI triggers, Actions security, protection, basics |
| [`references/release-gates.md`](skills/uplevel/references/release-gates.md) | release, deploy and deploy-time checks |
| [`references/code-scan.md`](skills/uplevel/references/code-scan.md) | the security read of a change, done by the agent |
| [`references/remedies.md`](skills/uplevel/references/remedies.md) | what each finding turns into as a plan item |
| [`references/commit-hygiene.md`](skills/uplevel/references/commit-hygiene.md) | commit messages, PR bodies and release notes |
| [`references/checklist.md`](skills/uplevel/references/checklist.md) | the per-repo checklist and how it re-audits as a diff |
| [`references/destructive-ops.md`](skills/uplevel/references/destructive-ops.md) | the stop list, and how to derive a repo's own |
| [`references/automation.md`](skills/uplevel/references/automation.md) | the enforcement ladder — turning rules into checks |
| [`references/claude-md-template.md`](skills/uplevel/references/claude-md-template.md) | the template the bootstrap fills in |
| [`references/long-runs.md`](skills/uplevel/references/long-runs.md) | migrations, backfills, anything measured |
| [`references/evidence.md`](skills/uplevel/references/evidence.md) | wording a completion claim to match the evidence |
| [`references/example-output.md`](skills/uplevel/references/example-output.md) | one worked report and plan |

## Limitations

- **Settings-derived findings depend on your access.** Branch protection and org policy need
  permissions an auditor may not have. Reported as unknown, never as absent.
- **It does not measure its own effect.** Nothing re-checks incident rate after a plan is applied.
- **The deploy, migration and incident guidance has not been run against a live service.** Every
  repository it was validated on was source only. Treat that half as reasoned, not tested.
- **Plans assume a primary gate.** A repository with several independent pipelines gets a plan
  weighted toward one of them.
- **The forge audit is GitHub-first.** CI triggers, Actions supply chain, rulesets, repository
  settings and releases are read through `gh`. GitLab, Bitbucket, Forgejo and Gitea have equivalents
  for nearly all of it, and the skill establishes what the forge can do before auditing — but on a
  non-GitHub host it will name those checks rather than run them.
- **Absent domains**: disaster recovery and restore testing, API and client backwards compatibility,
  feature-flag lifecycle, runtime cost regressions, clock and timezone failures.

Run `skills/uplevel/selfcheck.sh` for the structural checks it enforces on itself.

## Scope

Language-, stack- and deployment-agnostic, weighted toward services that run somewhere and can page
someone. The forge audit assumes GitHub; see *Limitations*. Sections that do not apply are meant to
be deleted; a small library's `CLAUDE.md` should come out a few lines long.
