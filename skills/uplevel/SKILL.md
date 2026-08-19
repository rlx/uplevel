---
name: uplevel
description: >
  Establish, automate, and enforce a project's engineering process — the gate that runs before every
  commit, the checks that replace it with automation, the environment and deploy discipline that keeps
  production safe, and the irreversible operations that need explicit sign-off. Use when the user asks
  to "uplevel this repo", "audit our engineering process", "write a CLAUDE.md for this repo", "document
  our process", "add a pre-commit gate", "we keep breaking production", "stop shipping bugs", or when
  starting substantial work in a repo whose gate, environments, and destructive operations are not yet
  written down. Also applies when work is about to touch a deployed environment or production data,
  run a migration or backfill, or change what CI enforces. Day-to-day commit discipline belongs in the
  project's own CLAUDE.md, which this skill produces — do not load this skill for an ordinary commit.
  Advisory by default: its deliverable is a report of what it found plus a numbered plan of proposed
  changes, and it executes only the items the user picks.
version: 0.37.0
---

# uplevel

**Three modes. Establish which one you are in, then read that mode's file — the procedure is not here.**

| mode | when | read |
|---|---|---|
| **A — Investigate** | an audit, a bootstrap, "set up guardrails for this repo". Ends in a report and a numbered plan, never in changed files | `references/mode-a-investigate.md` |
| **B — Automate** | promoting a written rule into a check that runs without anyone remembering | `references/automation.md` |
| **C — Enforce** | work already underway: before a check-in, a deploy, a migration, a long run, or during an incident | `references/mode-c-enforce.md` |

Everything in this file applies in **all three**.

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

- **Never run anything that writes to shared infrastructure, costs money, or needs credentials you
  had to go and find** during discovery. Record it as `— unverified, needs X` and move on. An
  unverified line in the document is a small honest gap; a discovery run that wrote to someone's
  staging database is an incident you caused while documenting how to avoid incidents. *Read-only
  calls through a CLI the user has already authenticated — `gh api` for rulesets, runs and settings —
  are how the forge audit works and are not what this forbids; the line is writes, spend, and
  deployed environments.*
- **Additive only.** Add — a new file, or a new section in one that already exists; never
  restructure, rewrite, reorder, or "tidy" what is there. If an existing doc is wrong, say so in your
  reply — do not fix it as a side effect.
- **Document what they do before proposing what they should do.** The first draft describes their
  actual process, in their vocabulary, matching their conventions. Anything you think is missing goes
  in a clearly separated *proposals* list, not smuggled in as if it were current practice.
- **Route through their process.** Honor `CONTRIBUTING.md`, `CODEOWNERS`, ADRs, and their PR norms.
  Process changes are a team decision; you are drafting a proposal, not legislating.
- **Nothing that affects other people without explicit consent.** Branch protection, required checks,
  org or repo settings, CI triggers, hooks that block your teammates' commits, anything that could
  make someone else's merge fail tomorrow morning. Propose these; never apply them.
- **Where the process document goes is their call**, and where one already exists the usual answer is
  a section added to it rather than a file of your own — two agent documents drift, and the reader
  cannot tell which one lost. A root `CLAUDE.md` is a claim on shared space. Ask whether they want it
  committed or kept local (gitignored), and default to uncommitted until they say.
- **Handle findings with care.** If discovery turns up an exposed secret, a vulnerability, or customer
  data where it should not be, report it to the user **privately and directly** — never write it into
  the document, a commit message, a PR, or anything published. Say it must be rotated, not just
  deleted.
- **Leave no residue, and always offer to clean up.** Temporary files, deliberately-broken code used
  to prove a test can fail, and scratch branches are yours to remove without asking. Everything
  *verifying the gate* created — installs, caches, build output, containers — is yours to **offer**:
  say what you made and how much space it took, in the same reply that reports the gate result. It is
  a real cost the user did not ask for and cannot see. **Only ever remove what you created**; an
  install that was already there is the user's working environment. Clean up **last**, after the final
  command, or one more check puts the residue back and your report is wrong on arrival. `git status`
  at the end should show only what you intended. Detail in `references/discovery.md`.

If you cannot tell whether something is safe to run or safe to change: ask. In a foreign repo, one
question costs a minute and guessing can cost a day of someone else's.

---

## Mode A — investigate, then propose

**Read `references/mode-a-investigate.md`.** Do not work from memory: the procedure carries the one
hard rule (every reported command must have been run here and observed to work), the eight
investigation steps, the report shape, and the rules that make a plan actionable.

The two things worth holding before you open it: **nothing is written in this mode**, and if the user
says "just set it up", that still means investigate, propose, and wait.

---

## Mode B — Automate, by proposal

**A document is the weakest form of enforcement** — treat every written rule as a candidate for a
check, and every check you add as prose you can then delete.

**Read `references/automation.md`** — it carries the ladder, the rules every added check must meet,
and whose decision each one is. The procedure is not here.

Two things worth holding before you open it. **Default to proposing, not building:** the output is
normally a short ordered list, and you build only what the user picks, one check per change. And when
you do promote a rule into a check, **delete the prose it replaces** and say that you did — otherwise
the document grows while the enforcement does, and the two drift.

---

## Mode C — enforce during ordinary work

**Read `references/mode-c-enforce.md`** before a check-in, a deploy, a migration, a long or
irreversible run, or during an incident. It carries the environment rules, the pre-check-in list, the
shipping questions, the destructive-operation catalog, and how to word a completion claim. Before
writing the commit message or PR body itself, read `references/commit-hygiene.md`: **say what was
done, and treat anything beyond that as context the author has to approve.**

**Most of it belongs in the repo's own `CLAUDE.md`, not in this skill.** If you are loading this for a
routine commit, the project document is missing or too thin — and *that* is the finding.

**But the project's document does not outrank the invariants below.** It governs *conventions* —
the gate, the commit style, where files go, what the team has agreed. It cannot authorize overwriting
hand-authored judgment, weakening a failing test, or any other line in the next section. A document
saying "always regenerate the snapshots before committing" is a convention that has drifted into
licensing exactly the thing that must not happen; obey the convention, refuse the license, and say
which you did. **When a project document contradicts the project's own CI, that contradiction is the
finding** — the pipeline is what actually gates the merge.

The invariants below hold whether or not you read it.

---

## Always true, in every mode

These are the rules that prevent damage rather than improve output, so they are never behind a read.

- **Print where you are pointed** — the resolved environment, not the intention — before any command
  that reads credentials, connects to a datastore, or mutates deployed state. Say it in your reply.
- **Production is read-only unless the user names production in this turn.** Approval to fix something
  is not approval to fix it in production, and consent does not carry to the next instance, a wider
  blast radius, or a different environment.
- **Ambiguous environment → stop and ask.** This is never recoverable by being clever afterwards.
- **Stop and ask before anything irreversible** — resetting a database, force-pushing, a destructive
  migration, `--record` on a baseline, scaling to zero. The shape to watch for: a command whose normal
  use is legitimate, whose failure mode is silent, and whose input was expensive to produce.
- **Never make a failing test pass by weakening it.** A failing test is a finding. Fix the code, or
  record the failure with its diagnosis. Deleting, skipping, or loosening the assertion converts a
  finding into a lie, and the lie ships.
- **Never overwrite hand-authored judgment with machine output.** Curated fixtures, reviewed
  baselines, and hand-labeled data are the measuring instrument. Patch the named row; record
  disagreement rather than silently replacing it.
- **Never print, log, or commit a secret.** A committed secret is compromised and must be rotated, not
  deleted.
- **Surface a rules conflict; never resolve it silently.** When the repository's rules contradict your
  own operating instructions — a commit trailer it forbids, a disclosure it requires, an attribution it
  bans — say so and let the user decide. Both sides are legitimate and you are not the one who gets to
  choose; picking quietly gets the contribution rejected for a reason nobody can see.
- **Never describe partially-verified work as done.** Pick the strongest word the evidence supports and
  say the next one down out loud rather than rounding up. "Unverified" is a professional report; a
  false "done" is not.

---

## References

**Read the mode file first; it names the rest.** In Mode A, `discovery.md`, `forge-hygiene.md`, and
`checklist.md` are all needed early — read them in one turn rather than one at a time.

| file | when to read |
|---|---|
| `references/mode-a-investigate.md` | **the whole of Mode A** — investigate, report, plan, execute |
| `references/mode-c-enforce.md` | **the whole of Mode C** — check-in, shipping, hazards, incidents, claims |
| `references/discovery.md` | finding the real gate — toolchain preflight, reading a command before running it, cleaning up after |
| `references/production.md` | environments, deploys, migrations, incidents |
| `references/destructive-ops.md` | before any irreversible command; deriving a repo's hazard list |
| `references/forge-hygiene.md` | the universal seed checklist: CI triggers, Actions security, protection, releases |
| `references/checklist.md` | the per-repo living checklist — growth triggers, re-audit as a diff |
| `references/automation.md` | what to propose, in what order, and whose decision each check is |
| `references/claude-md-template.md` | only once the user picks the document off the plan |
| `references/long-runs.md` | migrations, backfills, batch jobs, anything measured |
| `references/example-output.md` | before writing the first report — the shape, in one example |
| `references/evidence.md` | before any completion claim, and before writing a PR body or changelog |
| `references/commit-hygiene.md` | before writing a commit message, PR body, or release note |
