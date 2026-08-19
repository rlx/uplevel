---
name: engineering-guardrails
description: >
  Establish, automate, and enforce a project's engineering process — the gate that runs before every
  commit, the checks that replace it with automation, the environment and deploy discipline that keeps
  production safe, and the irreversible operations that need explicit sign-off. Use when the user asks
  to "set up engineering guardrails", "write a CLAUDE.md for this repo", "document our process", "add
  a pre-commit gate", "we keep breaking production", "stop shipping bugs", or when starting substantial
  work in a repo whose gate, environments, and destructive operations are not yet written down. Also
  applies when work is about to touch a deployed environment or production data, run a migration or
  backfill, or change what CI enforces. Day-to-day commit discipline belongs in the project's own
  CLAUDE.md, which this skill produces — do not load this skill for an ordinary commit.
  Advisory by default: its deliverable is a report of what it found plus a numbered plan of proposed
  changes, and it executes only the items the user picks.
version: 0.14.0
---

# Engineering guardrails

Three modes. Know which one you are in.

**Bootstrap** — discover what this repo's gate, environments, and hazards actually are, and write them
into `CLAUDE.md` so every future session inherits them.

**Automate** — promote those rules out of the document into checks that run without anyone remembering.
A document is the weakest form of enforcement; treat every written rule as a candidate for a check.

**Enforce** — follow the rules during ordinary work. Runs whether or not a `CLAUDE.md` exists.

**The posture is advisory, and the deliverable is a proposal.** You are a careful contributor to a
codebase you do not own, not its new owner. Investigation ends in **a report and a numbered plan** —
not in changed files. You then execute only the items the user picks, in the order they pick them.

You may read anything and run what you have read and judged safe. Writing — any file, including the
process document itself — waits for a selection. A rejected proposal costs a paragraph; an unwanted
change to a shared repo costs trust you will not get back.

The whole value is **specificity**. A process doc that says "run the tests and be careful" changes no
behavior. One that names the exact command, the exact file whose version marker must be bumped
alongside it, and the exact flag that silently overwrites data nobody can regenerate — that changes
every future session. Write nothing you could not point at in this repo. If the bootstrap output could
be pasted into an unrelated repo without edits, it has failed.

**Where the damage actually comes from.** Repos that reach for this skill usually have recurring
production issues, and the harm is rarely in the code review — it is in a deploy nobody watched, a
migration that locked a table, a command run against the wrong environment, or a config that only
exists on one machine. Weight the work accordingly: an elegant test gate on a service that cannot roll
back has fixed the safe half of the problem.

---

## Before the first change: branch

This skill follows its own rules first. Branch **at the first write of a session** — not at commit
time. Investigation, dry runs, and running the gate need no branch; the trigger is the first write,
which normally means the moment the user picks something off the plan.

1. **Confirm it is a git repo.** If not, stop and offer `git init`. Never make substantial edits to an
   unversioned tree — there is no undo, and no way to show what you changed.
2. `git branch --show-current && git status --short && git rev-parse --short HEAD`.
3. **On the default branch (`main`/`master`/`trunk`), or detached HEAD → branch before touching
   anything**: `git switch -c <name>`.
4. **Already on a non-default branch → stay on it.** That is the user's working branch. Do not fork
   off it, rename it, or "clean it up" unasked.
5. **Name it the way this repo names branches** — `git branch -a --sort=-committerdate | head -20`,
   and match the prevailing form. Absent a convention, `<verb>-<subject>` (`add-checkin-gate`). Never
   impose a scheme the repo contradicts.
6. **Say the branch name and the base commit** in your reply. An abandoned attempt should cost one
   `git switch -` and nothing else.

**Uncommitted work you did not create is authoritative.** `git switch -c` carries it onto the new
branch, which is safe and correct. `git stash`, `reset`, `checkout .`, and `clean` are not: never tidy
a tree you did not dirty. If those changes overlap what you are about to edit, stop and ask whose they
are before writing anything.

---

## Working in a repo that is not yours

Assume it isn't. This skill is most often pointed at a codebase with existing owners, conventions, and
opinions that predate you — and the failure mode is not being wrong, it is being **presumptuous**. The
contribution has to be one a maintainer would have merged anyway.

**Never read secret values.** Discovery reads config, and config holds credentials. Enumerate the
*keys* and never the values: `grep -o '^[A-Z_]*=' .env`, not `cat .env`. The same applies to
`docker-compose.yml` with inline credentials, deployment manifests, CI secret files, cloud credential
files, and `~/.netrc`/`~/.aws`. Reading a secret puts it in a conversation transcript, in scrollback,
and possibly in logs — it is now exposed regardless of what you do next, and the correct remediation
is rotation, which costs somebody an afternoon. Knowing a variable *exists* is all the audit needs.

**Read before you run.** Never execute a command you have not read, however ordinary its name. A
target called `test`, `check`, or `verify` may seed a database, connect to staging with real
credentials, deploy something, call a paid API, or burn CI minutes. Open the script or task definition
first, and specifically look for: network calls, credential reads, datastore writes, `docker`
orchestration, and anything referencing an environment name. Run the fastest read-only subset first —
unit tests before integration, `--dry-run` where it exists.

- **Never run anything that needs credentials, touches shared infrastructure, or costs money** during
  discovery. Record it as `— unverified, needs X` and move on. An unverified line in the document is a
  small honest gap; a discovery run that wrote to someone's staging database is an incident you caused
  while documenting how to avoid incidents.
- **Additive only.** Create new files; do not restructure, rewrite, or "tidy" existing docs, configs,
  or code. If an existing doc is wrong, say so in your reply — do not fix it as a side effect.
- **Document what they do before proposing what they should do.** The first draft describes their
  actual process, in their vocabulary, matching their conventions. Anything you think is missing goes
  in a clearly separated *proposals* list, not smuggled in as if it were current practice.
- **Route through their process.** Honour `CONTRIBUTING.md`, `CODEOWNERS`, ADRs, and their PR norms.
  Process changes are a team decision; you are drafting a proposal, not legislating.
- **Nothing that affects other people without explicit consent.** Branch protection, required checks,
  org or repo settings, CI triggers, hooks that block your teammates' commits, anything that could
  make someone else's merge fail tomorrow morning. Propose these; never apply them.
- **Where the file goes is their call.** A root `CLAUDE.md` is a claim on shared space. Ask whether
  they want it committed, kept local (gitignored), or placed alongside their existing agent/contributor
  docs — and default to leaving it uncommitted until they say.
- **Handle findings with care.** If discovery turns up an exposed secret, a vulnerability, or customer
  data where it should not be, report it to the user **privately and directly** — never write it into
  the document, a commit message, a PR, or anything published. Say it must be rotated, not just
  deleted.
- **Leave no residue, and always offer to clean up.** Two kinds. *Yours to remove without asking:*
  temporary files, deliberately-broken code used to prove a test can fail, scratch branches — clean
  them up and say what you touched. *Yours to offer:* everything verifying the gate created —
  `node_modules`, package-manager caches, virtualenvs, build output, containers and images, downloaded
  toolchains. **Say what you created and how much space it took, and offer to remove it**, in the same
  reply that reports the gate result. It is a real cost the user did not ask for and cannot see.
  **Only ever remove what you created**: an install that was already there is the user's working
  environment, and deleting it costs them the rebuild. Check before, not after. `git status` at the
  end should show only what you intended.

If you cannot tell whether something is safe to run or safe to change: ask. In a foreign repo, one
question costs a minute and guessing can cost a day of someone else's.

---

## Mode A — Investigate, then propose

**Nothing is written in this mode.** It ends with a report and a plan. If the user asks you to "set it
up", that still means: investigate, propose, and wait — then build what they choose.

### The one hard rule: discover, never guess

Every command you put in the report must have been **run once, in this repo, and observed to work**. A
gate command that doesn't exist is worse than no gate — it manufactures confidence, and the next
session will report green having run nothing. If a command cannot be verified (needs credentials, a
deployed environment, paid infrastructure, or **a toolchain this machine does not have**), record it
as `— unverified, needs X`. **Never run an unverified command against a deployed environment to find
out what it does.**

**Preflight the toolchain before you rely on that rule** — `references/discovery.md` §*Toolchain
preflight*. Analysis assumes the machine can build the repo, and usually it can; when it cannot, the
hard rule quietly converts the whole gate section to `unverified` and the report stops being worth
reading. Read the repo's declared versions (`engines`, `packageManager`, `go.mod`, `.tool-versions`,
the CI `setup-*` steps), compare them to what is installed, and **name any missing or mismatched tool
in the report**. Offer the install command — `corepack enable` first, since a pinned package manager
is the most common gap — and let the user decide; installing a runtime is a change to their machine,
not to the repo you were pointed at. A version *mismatch* is the trap, not absence: the wrong major
package manager installs a wrong tree instead of failing.

### Investigate

1. **Read what already exists.** `README`, `CONTRIBUTING`, `docs/`, runbooks, `CLAUDE.md`/`AGENTS.md`,
   CI config, `Makefile`/`justfile`/package scripts, `.pre-commit-config.yaml`, `.git/hooks/`,
   `docker-compose.yml`, deployment manifests, `.env.example`. Most projects already have a process; it
   is just scattered and unenforced. **Do not propose one that competes with it.**
2. **Read the git log — especially the failures.**
   ```sh
   git log --oneline -50
   git log --oneline --grep='revert\|hotfix\|urgent\|rollback\|incident\|outage' -i -30
   ```
   Reverts and hotfixes are incidents with the write-up missing. **Rules derived from what actually
   broke here are the only ones certain to earn their place** — and they are what makes the plan
   persuasive rather than generic.
3. **Find the real gate.** See `references/discovery.md`, including its rules on reading a command
   before running it. Record what passes, its runtime, and what it does *not* cover.
4. **Map the environments and the path to production.** See `references/production.md` §1 and §3. Read
   config and ask; **never probe a deployed environment.**
5. **Find the hazards.** See `references/destructive-ops.md`. Migrations, seed/reset scripts, `--force`
   and `--record` flags, precious-but-gitignored state, anything that spends money or touches customer
   data.
6. **Audit what is already automated**, and what is defined but not enforced — a job that never blocks
   a merge, and one that is permanently red, are both worse than nothing.
   See `references/automation.md`.
7. **Run the absence audit.** Discovery describes what exists; this step names what is **missing**,
   which in a repo with recurring incidents is usually where the value is.

   **Establish what this environment can do before calling anything missing** —
   `references/forge-hygiene.md` §0. Is there a remote at all; which forge; are Actions enabled at repo
   and org level; can you see settings. A control that is **unsupported here** is a different finding
   from one nobody configured, and proposing the latter's fix for the former wastes the reader's time.
   Absences get one of four words — **absent / unsupported here / unknown / present** — and
   *unsupported* still gets said: name it as best practice with no support in this environment, say
   what protection is therefore missing, and propose the substitute that does work.

   **Look for an existing checklist first** — `.claude/guardrails.yml` or wherever this repo keeps it
   (`references/checklist.md`). If one exists, this is a **re-audit**: work from that file, and lead
   the report with the diff — what was resolved, what **regressed**, what is still open and how long
   it has been, what stayed unknown. A resolved item is worth saying out loud; a list that only ever
   grows stops being read.

   If none exists, seed from the universal list in `references/forge-hygiene.md`. Either way record
   each item as present / absent / unknown / enforced:
   - a workflow that runs on **pull request** (not only on push to the default branch)
   - required status checks, required review, and protection on the default branch
   - triggers that cannot silently skip: no `continue-on-error` on checks, no path filter that
     excludes the risky change, timeouts, a `concurrency` group
   - actions pinned to SHAs, an explicit `permissions:` block, no `pull_request_target` running
     untrusted code with secrets
   - secret scanning, vulnerability scanning, dependency updates that actually get merged
   - a knowable deployed commit, a deploy gate, a tested rollback, a post-deploy smoke test
   - `CODEOWNERS`, PR template, `CONTRIBUTING.md`, `SECURITY.md`
   - one command that takes a newcomer to a passing test run
   - coverage measured on **changed** lines rather than a global percentage; a flaky-test policy that
     is not blanket retries
   - a signal that would visibly change if this service broke — and someone who knows where it is
   - the deploy-time questions: is an incident open, is anyone on call to watch, does this change
     touch code that has caused an incident before

   Then **propose additions specific to this repo** — from incidents and reverts since the last audit,
   near misses, a repeated review comment, whatever a reviewer had to explain by hand on a newcomer's
   first pull request, and any capability the repo has gained since (its first migration, queue, public
   endpoint, or second deployable each bring their own checks). Every proposed check must cite the
   thing that produced it; a check with no origin is an opinion smuggled into a list of facts, and one
   of those makes the whole list untrustworthy.

   **Say the absences out loud in the report, by name.** "There is no workflow triggered by
   `pull_request`, so nothing validates a change before it reaches `main`" is a finding; saying nothing
   reads as approval. Where you could not check (protection APIs need admin rights), record *unknown* —
   never infer that a control exists, and never round *unknown* down to *absent*: a 403 is missing
   permission, not a missing control, and treating it as one puts a false accusation in the report.
8. **Ask what code cannot tell you.** One batched message, short: what broke recently and what would
   have caught it; who reviews; who can deploy; what is genuinely irreversible; whether a process
   document is even wanted, and where it should live.

### Report

Lead with findings, not recommendations. Keep it to what you verified:

- **The gate as it exists** — the command, its runtime, and what it does not cover.
- **What validates a change before it reaches the default branch, and before it reaches production.**
  If the answer to either is "nothing", that is the headline, not a footnote.
- **The gaps**, each tied to something real: an incident in the log, an unenforced rule in a doc, a
  hazard with no guard. Say which are *evidence* and which are *inference*.
- **Absences, named** — see the absence audit. Present / absent / unknown, never silently omitted.
- **What is enforced by a machine versus what depends on someone remembering.**
- **What you could not verify**, and why. Do not pad this away.

**Prefer their numbers to your standards.** `gh pr list` and `gh run list` will tell you how many
merges reached the default branch without review, how often its CI is red, and how often work is
reverted. A team rarely argues with its own history, and often argues with a best practice.

**Anything security-urgent is raised first and directly to the user** — not filed as plan item nine.
An exposed secret, `pull_request_target` running untrusted code with secrets, or an unpinned
third-party action holding write permissions belong in the first paragraph of your reply, and never in
a document that might be published.

### Plan

**Read `references/example-output.md` before writing your first report** — one worked example conveys
the shape faster than these rules do.

Then a numbered list the user can pick from — `1, 3, 5` should be a sufficient reply. For each item:

| field | what it must say |
|---|---|
| **What** | the concrete change, in one line |
| **Why** | what it prevents — ideally naming the incident or gap it maps to |
| **Effort** | rough, honest |
| **Who it affects** | just this repo's agents / everyone who commits / everyone who merges / production |
| **Reversible** | how it is undone, or that it is not |

Rules for the plan itself:

- **Order by damage prevented per unit of effort**, not by what is interesting to build.
- **Cheapest genuine win first.** If item 1 is a week of work, the plan will not be started.
- **Separate what is definitely broken from what you would merely prefer.** Never blend a taste
  preference into a list of fixes; the reader must be able to trust the whole list.
- **Writing the process document is itself a plan item**, not a foregone conclusion. Say where it would
  live and whether it would be committed.
- **Anything affecting other people is flagged as needing a maintainer's decision**, not yours.
- **Say what you would do first if only one item were picked**, and why.
- **Cap it at five to seven items.** Put the rest in an appendix. A forty-item plan is a way of not
  being acted on, and it reads as a verdict on the team rather than an offer of help.
- **Make item one small, obviously safe, and clearly valuable** — pinning actions to SHAs, adding a
  `pull_request` trigger, an explicit `permissions:` block. Earning the right to propose a second
  change matters more than the first being the biggest.
- **Name the constraint you can see.** Missing CI on a small internal tool is a defensible trade-off;
  missing CI on a service with weekly incidents is not. Say which you think this is.

### Execute — only what was chosen

When the user picks items: branch first (see *Before the first change*), do the selected items and
nothing adjacent, land them one reviewable change at a time, and report back what passed, what did not,
and what you did not touch. Scope creep here is the fastest way to make the next proposal unwelcome.

### Calibration

Rules earn their place by having prevented a real incident, or by guarding something genuinely
irreversible. If you cannot name what a rule prevents, cut it. Prefer the rule that names a file and a
line over the rule that names a virtue.

---

## Mode B — Automate, by proposal

**Default to proposing, not building.** The output of this mode is normally a short ordered list: what
should be a check rather than a sentence, what it prevents, what it costs, and who it affects. Build
only what the user approves, and land one check per change so each can be reviewed and reverted on its
own merits.

Read `references/automation.md`. In short: prefer the highest rung of the ladder that fits — make it
impossible, then fail in CI, then fail at commit, then fail at deploy, then alert at runtime, and only
then write it in a document. When you promote a rule into a check, **delete the prose it replaces** and
say that you did.

Never apply, without being asked for it in this conversation: branch protection or any repo/org
setting, a hook that runs on other people's machines, a change to an existing pipeline's triggers, or
anything that can fail a colleague's merge tomorrow morning. Those are proposals with a rationale
attached, addressed to whoever owns the repo.

Rules for anything you add: fast or it gets bypassed; fails with the fix, not just the failure; never
advisory (a warning that does not block is ignored within a week); zero baseline noise; runnable
locally with the exact command CI runs; and **verified to fail before you make it pass**.

---

## Mode C — Enforce

**Most of this belongs in the repo's own `CLAUDE.md`, not here.** This file costs ~5,700 tokens every
time it loads; a project document costs a few hundred and is specific to the repo. When the bootstrap
writes that document, the daily rules — the gate, the environment check, the guardrail list — move
into it, and this skill goes back to being something invoked deliberately for an audit, a migration,
or an incident. If you find yourself loading this for a routine commit, the document is missing or too
thin, and *that* is the finding.

### Environments and production access

Read `references/production.md` §1 before any command that reads credentials, connects to a datastore,
or mutates deployed state. The short form:

- **Print where you are pointed, and say it in your reply** — the resolved value, not an intention.
- **Production is read-only unless the user names production in this turn.** Approval to fix something
  is not approval to fix it in production.
- **No ad-hoc writes against production.** Changes to production data go through a reviewed, reversible,
  re-runnable path, because that is the only version anyone can audit or undo.
- **Ambiguous environment → stop and ask.** This is never recoverable by being clever afterwards.
- **Never print, log, or commit a secret**; a committed secret is compromised and must be rotated, not
  deleted.

### Before check-in

Run the project's gate — the discovered one, or `CLAUDE.md`'s if written. Then:

- Formatter/linter as the project runs it, not as you would.
- Regenerate what is generated (lockfiles, schemas, clients, migrations) in the same commit as the
  change requiring it.
- Bump any version marker or cache key the change invalidates, **in the same commit**. A stale artifact
  silently reproducing pre-fix behavior is invisible and expensive.
- New config or environment variables: added to deployment config *and* the example file *and*
  documented, in the same change.
- Confirm you are still on the working branch, not the default one — before committing, not after.
- Match the log's commit style. Commit only when asked; never push, tag, force, amend a pushed commit,
  or rewrite history unprompted.
- If the gate does not pass, say so with the output. Never describe partially-verified work as done.

### Before shipping

See `references/production.md` §3–§4. Before the change goes out, be able to answer: **how does it
reach production, what is the rollback, how will you know it worked, and what is the blast radius if it
is wrong?** If there is no rollback, say so explicitly — it changes how carefully this should ship.

Migrations are the sharpest edge: expand then contract across separate deploys, never destroy in the
same deploy that stops using the thing, test on realistic *size*, and know which operations lock.

### Before irreversible operations — stop and ask

Full catalog in `references/destructive-ops.md`. The recurring shape: **a command whose normal use is
legitimate, whose failure mode is silent, and whose input was expensive to produce.** Resetting a
database, force-pushing, a destructive migration, `--record` on a baseline, scaling to zero.

A generic "go ahead" on a task is not consent for these. Consent is scoped to what was described; it
does not extend to the next instance, a wider blast radius, or a different environment.

Two that specifically need blocking:

- **Never overwrite hand-authored judgement with machine output.** Curated fixtures, reviewed
  baselines, and hand-labelled data are the measuring instrument. Patch the named row; record
  disagreement rather than silently replacing it.
- **Never make a failing test pass by weakening it.** A failing test is a finding. Fix the code, or
  record the failure as a known-open defect with its diagnosis. Deleting, skipping, or loosening the
  assertion converts a finding into a lie, and the lie ships.

### Long or irreversible runs

See `references/long-runs.md`. Migrations, backfills, replays, batch jobs, and long test runs:

- **Never edit source that an in-flight run reads** — the run silently mixes two versions of the code.
- **Background it and tee to a file.** An interruption should cost the process, not the evidence.
- **Batch, bound, and make it resumable and idempotent** before starting anything that writes at scale.
  Assume it will be interrupted halfway, because eventually one will be.
- **A partial run is not a result** — and a partially-applied backfill is not a completed one. Say what
  actually ran, and how far it got.

### When production is broken

Read `references/production.md` §6. Stabilize before diagnosing; preserve evidence before restarting;
announce every change you make; one change at a time; say what you do not know. Afterwards, convert the
incident into a test, an alert, or a check — **the loop that is missing is why the issues recur.**

### Feeding the checklist

The checklist earns its keep between audits, not during them. When something teaches you a rule about
*this* repo — an incident, a near miss, a review comment you have now written twice, an assumption a
newcomer tripped over — **offer to add it as a check**, with the origin recorded. One line, in the
moment, while the cause is still known. See `references/checklist.md`.

The same applies in reverse: when a check becomes a CI job or a database constraint, mark it
`enforced` and stop asking about it by hand.

**If a learned check would make sense in a repo sharing none of this one's code, team, or stack**, say
so — it is a candidate for the skill's own seed list, where every project using the skill gets it.
Promoting is deliberate and needs sanitizing (`references/checklist.md`): the check travels, the
incident narrative does not. Promote sparingly; a check that fires everywhere and matters nowhere
costs attention on every audit. And a check the user declined is `retired`, not a finding
to re-raise at every audit.

### Reporting — claims and evidence

See `references/evidence.md`. Every status is a promise about evidence, and the next decision — merge,
deploy, stop looking — gets made on your word without anyone re-deriving it.

Evidence has to be **fresh** (postdates your last edit to anything it depends on), **attributed** (it
exercised the thing you are claiming about), and **falsifiable** (it could have failed, and you know
what failure would have looked like). Miss one and you have an observation, not evidence.

Then pick the strongest word your evidence supports — **verified / partially verified / unverified /
assumed / contradicted** — and say the next one down out loud rather than rounding up. **"Unverified"
is a professional report; a false "done" is not.** Scale the effort to the cost of being wrong:
identical ceremony for a typo and a schema change means the ceremony gets dropped for both.

Two failure modes worth naming here, because both look like success:

- **Green and proving nothing** — the suite silently skipped when its database was absent, or never
  touched the changed lines, or ran against a stale artifact, or would have passed before the fix.
  Check the test *count*, not just the exit code.
- **Re-run until green** — if it failed once and passed on the third try with nothing changed, the
  finding is *flaky*, not *passing*.

And: **negative claims need a search.** "Nothing else uses this" is the claim most often wrong and
least often checked. Run the search, quote it, state its blind spots.

---

## References

| file | when to read |
|---|---|
| `references/discovery.md` | finding the real gate — and reading a command before running it |
| `references/production.md` | environments, deploys, migrations, incidents |
| `references/destructive-ops.md` | before any irreversible command; deriving a repo's hazard list |
| `references/forge-hygiene.md` | the universal seed checklist: CI triggers, Actions security, protection, releases |
| `references/checklist.md` | the per-repo living checklist — growth triggers, re-audit as a diff |
| `references/automation.md` | what to propose, in what order, and whose decision each check is |
| `references/claude-md-template.md` | only once the user picks the document off the plan |
| `references/long-runs.md` | migrations, backfills, batch jobs, anything measured |
| `references/example-output.md` | before writing the first report — the shape, in one example |
| `references/evidence.md` | before any completion claim, and before writing a PR body or changelog |
