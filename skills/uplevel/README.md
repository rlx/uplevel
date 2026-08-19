# uplevel

A Claude Code skill for codebases that keep breaking in production because the process lives in
people's heads.

It does three things:

1. **Investigate, then propose** — inspects the repo (CI config, hooks, task runner, deployment
   manifests, and the revert/hotfix history), *runs* the candidate gate commands it has read and judged
   safe, maps the environments and the path to production, hunts the operations that destroy something
   irreplaceable, runs an **absence audit** that names what is missing — no CI on pull requests, no
   required checks, unpinned actions, no rollback — and asks you the handful of things code cannot
   answer. It writes nothing. It hands
   back **a report of what it found and a numbered plan of proposed changes** — each with what it
   prevents, what it costs, who it affects, and how to undo it — and builds only the items you pick.
2. **Automate, by proposal** — the most valuable plan items are usually the ones that replace a
   sentence with a check: CI gates, secret scanning, migration safety, config validation, deploy smoke
   tests. A document is the weakest form of enforcement. Anything that could fail a colleague's merge —
   branch protection, required checks, shared hooks — is proposed for a maintainer to apply, never
   applied by the skill.
3. **Learn** — the absence checklist is seeded from a universal list, then **kept in the repository**
   and grown from that repo's own incidents, near misses, and whatever a reviewer had to explain by
   hand on a newcomer's first pull request. Re-audits report a diff — resolved, regressed, still open —
   rather than repeating the same survey, so the second audit is more useful than the first.
4. **Enforce** — during ordinary work: run the gate before check-in, print which environment you are
   pointed at before touching one, stop and ask before irreversible operations, ship with a known
   rollback, keep long migrations and backfills resumable, and report results honestly.

Three rules it holds itself to. It is **advisory**: it proposes, you choose, and it changes nothing
that affects other people without being asked. It **branches before its first write**, so anything it
does build is one `git switch -` away from never having happened. And it **discovers, never guesses** —
every command in its report is one it ran and watched pass, or is marked unverified.

## Install

Copy the folder to either location:

```sh
# personal — available in every project
mkdir -p ~/.claude/skills && cp -R uplevel ~/.claude/skills/

# project — checked in, shared with the team
mkdir -p .claude/skills && cp -R uplevel .claude/skills/
```

Restart Claude Code (or start a new session). Confirm it loaded with `/skills`.

## Use

```
/uplevel                         # bootstrap this repo
```

or just ask: *"uplevel this repo"*, *"write a CLAUDE.md documenting our process"*,
*"we keep breaking production — what should we enforce?"*

It will come back with findings and a numbered plan. Reply with the numbers you want — `1, 3, 5` is a
sufficient answer — and it builds those and nothing adjacent. The parts only you know (which data is
irreplaceable, what broke last quarter, who is allowed to deploy) are the parts worth correcting before
you choose.

## Contents

```
SKILL.md                          the three modes, branching, and the rules
references/discovery.md           finding the real gate, per ecosystem, and what it fails to cover
references/production.md          environments, secrets, deploys, migrations, incidents
references/forge-hygiene.md       the universal seed checklist — CI triggers, Actions security, protection
references/checklist.md           the per-repo living checklist — how it grows and re-audits as a diff
references/destructive-ops.md     the stop list, and how to derive a repo's own
references/automation.md          the enforcement ladder — turning rules into checks
references/claude-md-template.md  the template the bootstrap fills in
references/long-runs.md           long reads vs. long writes; resumable backfills
```

## Sharing what one repo learns with the others

There is no built-in mechanism that syncs learning between repositories. Sharing means moving a check
into something that is itself shared:

- **Personal skill** (`~/.claude/skills/`) — already covers every repo you work on, on this machine.
- **Skill in a git repo, installed as a plugin** — reaches everyone who installs it, and updates
  propagate when they pull. This is the mechanism if a team wants shared guardrails.
- **A shared org checklist** the per-repo file inherits from (`extends:`), fetched read-only, with
  local entries winning on conflict.

Promotion from a repo's checklist into the shared seed is gated on one question: *would this check
make sense in a repo that shares none of this one's code, team, or stack?* Promote sparingly and
sanitize the origin — the check travels, the incident narrative stays home.

## Prior art

Surveyed 2026-08-19 against 344 public Claude Code skills. The ecosystem covers incident response and
deploy-time risk well; **CI and forge governance is near-absent** — across those 344 skills, zero
mention `pull_request_target`, required status checks, action SHA-pinning, or secret scanning. That
gap is what this skill is for. Full survey, including the checks it borrowed back, in
`research/prior-art.md` of the source repository.

## Known limitations

Stated plainly, because the skill demands the same of its users:

- **It has not been run end to end.** Discovery has been dry-run against a real repository; the
  report-and-plan output has never been produced in anger, and the execute path is untested.
- **It assumes one service, one gate, one path to production.** A monorepo of twenty services, or one
  service split across repos, will produce a plan that reads as confident and is wrong in shape.
- **It does not measure whether it helped.** Nothing re-checks incident rate after the plan is done,
  so its value is argued rather than demonstrated.
- **Absent domains**: disaster recovery and restore testing, API/client backwards compatibility,
  feature-flag lifecycle, runtime cost regressions, clock and timezone failures.

Run `skills/uplevel/selfcheck.sh` for the structural checks it does enforce.

## Scope

Language-, stack-, and deployment-agnostic; weighted toward services that run somewhere and can page
someone. Sections that do not apply are meant to be deleted — a small library's `CLAUDE.md` should come
out a few lines long, and that is the correct result.
