# uplevel

Audits a repository's engineering process and returns a ranked plan to fix it.

## What it does

**Investigate, then propose.** Reads CI config, hooks, task runners, deployment manifests and the
revert history. Runs the candidate gate commands it has read and judged safe. Maps the environments
and the path to production. Finds the operations that destroy something irreplaceable. Runs an
absence audit that names what is missing rather than only what is wrong. It writes nothing, and ends
in a report plus a numbered plan — each item with what it prevents, what it costs, who it affects,
and how to undo it.

**Automate, by proposal.** The valuable plan items replace a sentence with a check: CI gates, secret
scanning, migration safety, config validation, deploy smoke tests. A document is the weakest form of
enforcement. Anything that could fail a colleague's merge is proposed for a maintainer, never
applied.

**Enforce during ordinary work.** Run the gate before check-in, print which environment you are
pointed at before touching one, stop before irreversible operations, ship with a known rollback,
keep backfills resumable, and report results honestly.

## Rules it holds itself to

- **Advisory.** It proposes, you choose. Nothing affecting other people is applied unasked.
- **Branches before its first write**, so anything it builds is one `git switch -` from undone.
- **Discovers, never guesses.** Every command it reports is one it ran and watched pass, or is
  marked unverified.

## Install

From the repository root:

```sh
# personal — available in every project
mkdir -p ~/.claude/skills && cp -R skills/uplevel ~/.claude/skills/uplevel

# project — checked in, shared with the team
mkdir -p .claude/skills && cp -R skills/uplevel .claude/skills/uplevel
```

Name the destination explicitly: `cp -R skills/uplevel ~/.claude/skills/` works the first time and
nests a copy inside itself the second. Restart Claude Code; the skill is then available as `/uplevel`.

## Use

```
/uplevel
```

Or ask: "uplevel this repo", "write a CLAUDE.md documenting our process", "we keep breaking
production — what should we enforce?"

It returns findings and a numbered plan. Reply with the numbers you want — `1, 3, 5` is enough — and
it builds those and nothing adjacent. The parts only you know (which data is irreplaceable, what
broke last quarter, who may deploy) are worth correcting before you choose.

## Contents

| file | what it carries |
|---|---|
| [`SKILL.md`](SKILL.md) | the three modes, branching, and the invariants |
| [`references/mode-a-investigate.md`](references/mode-a-investigate.md) | the audit procedure, report shape and plan rules |
| [`references/mode-c-enforce.md`](references/mode-c-enforce.md) | check-in, shipping, hazards, incidents, claims |
| [`references/discovery.md`](references/discovery.md) | finding the real gate; toolchain preflight; cleanup |
| [`references/production.md`](references/production.md) | environments, secrets, deploys, migrations, incidents |
| [`references/forge-hygiene.md`](references/forge-hygiene.md) | CI triggers, Actions security, protection, releases |
| [`references/checklist.md`](references/checklist.md) | the per-repo checklist and how it re-audits as a diff |
| [`references/destructive-ops.md`](references/destructive-ops.md) | the stop list, and how to derive a repo's own |
| [`references/automation.md`](references/automation.md) | the enforcement ladder — turning rules into checks |
| [`references/claude-md-template.md`](references/claude-md-template.md) | the template the bootstrap fills in |
| [`references/long-runs.md`](references/long-runs.md) | migrations, backfills, anything measured |
| [`references/evidence.md`](references/evidence.md) | wording a completion claim to match the evidence |
| [`references/example-output.md`](references/example-output.md) | one worked report and plan |

## Limitations

- **Settings-derived findings depend on your access.** Branch protection and org policy need
  permissions an auditor may not have. Reported as unknown, never as absent.
- **It does not measure its own effect.** Nothing re-checks incident rate after a plan is applied.
- **Plans assume a primary gate.** A repository with several independent pipelines gets a plan
  weighted toward one of them.
- **Absent domains**: disaster recovery and restore testing, API and client backwards compatibility,
  feature-flag lifecycle, runtime cost regressions, clock and timezone failures.

Run `selfcheck.sh` for the structural checks it enforces on itself.

## Scope

Language-, stack- and deployment-agnostic, weighted toward services that run somewhere and can page
someone. Sections that do not apply are meant to be deleted; a small library's `CLAUDE.md` should
come out a few lines long.
