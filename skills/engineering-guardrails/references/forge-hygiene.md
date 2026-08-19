# Repository, CI, and release hygiene

Written GitHub-first because that is the common case; GitLab/Bitbucket/Forgejo have equivalents for
nearly all of it. **Everything here is read-only to discover and a proposal to change.** Settings that
affect other people are never yours to apply.

**This is the seed, not the whole list.** What follows applies to nearly any repository. A given repo
then grows its own checks from its own incidents — see `checklist.md` for how that list is stored,
extended, and re-audited as a diff. Never write repo-specific checks back into this file: it is shared
by every project the skill is used on.

**Absence is a finding.** Most of this file is a list of things that should exist. In a repo with
recurring production issues, the highest-value findings are usually the missing ones — no CI on pull
requests, no required checks, no rollback, no dependency updates. Say so explicitly, by name. "There is
no workflow that runs on `pull_request`, so nothing validates a change before it reaches `main`" is a
finding. Silence about it reads as approval.

---

## 1. What runs, and when — trigger correctness

A pipeline that exists is not a pipeline that protects you. Read every workflow's `on:` block and
answer: **what change could reach the default branch without this running?**

Failure modes to check for by name, each of which produces a green repo that validates nothing:

- **`on: push` to `main` only.** Nothing validates a *pull request*; the branch is where you discover
  breakage, and by then it is merged. This is the single most common CI defect.
- **`pull_request_target` used with a checkout of the PR's head.** This runs untrusted code with
  repository secrets and write permissions. It is a remote-code-execution footgun, not a style issue —
  flag it as security, urgently.
- **`paths:` / `paths-ignore:` filters** that skip the job for exactly the change that breaks things
  (a workflow file, a lockfile, a migration). Worse: if a *required* check is skipped by a path filter
  it may never report, and the PR is blocked or waved through depending on configuration.
- **`continue-on-error: true`, `|| true`, `set +e`, `if: always()` on a check step.** The job is green
  while the step failed. Grep for these before believing any status badge.
- **No `timeout-minutes`.** A hung job consumes the runner for hours and teaches people to ignore
  pending checks.
- **No `concurrency:` group.** Superseded runs keep executing — wasted minutes, and racing deploys if
  the workflow deploys.
- **No `workflow_dispatch`.** Nothing can be re-run without pushing an empty commit.
- **Fork pull requests get no secrets**, so integration tests silently skip and report success. Decide
  deliberately what runs for forks.
- **Scheduled workflows are disabled after ~60 days of repository inactivity** on GitHub. A nightly
  security scan that quietly stopped months ago is worse than none, because everyone believes it runs.
- **Matrix covers one runtime version while production runs another.**
- **Caches that never invalidate**, so CI passes against dependencies nobody has locally.

## 2. Actions supply chain and permissions

- **Third-party actions pinned to a mutable tag** (`@v4`, `@main`). A tag can be re-pointed at new
  code; pin to a full commit SHA with the version in a trailing comment. This is the cheapest real
  security improvement most repos can make.
- **No `permissions:` block.** The default `GITHUB_TOKEN` may carry write scope to the whole
  repository, handed to every action including third-party ones. Set `permissions: contents: read` at
  workflow level and widen per-job only where needed.
- **Long-lived cloud credentials in secrets** where the provider supports OIDC federation. Prefer
  short-lived tokens minted per run.
- **Secrets reachable by untrusted code**, printed into logs, or passed wholesale to an action that
  only needs one value.
- **No dependency update automation** (Dependabot/Renovate), or one that opens PRs nobody merges — a
  wall of ignored update PRs is its own finding, because it hides the security ones.
- **No vulnerability scanning**, no secret scanning, no push protection. Check whether they are
  enabled, not merely available.

## 3. Getting to `main` safely

Read the protection on the default branch — note that this API needs admin rights and may 404 for you;
if so, say it is unknown rather than assuming:

```sh
gh api repos/{owner}/{repo}/branches/{branch}/protection 2>/dev/null
gh api repos/{owner}/{repo}/rulesets 2>/dev/null
```

What to look for, and to call out when absent:

- **Direct pushes to the default branch allowed** — the whole review process is optional.
- **No required status checks**, or checks that are required but no longer exist (name drift after a
  job rename blocks every PR, or silently requires nothing).
- **No required review**, or reviews not dismissed when new commits land.
- **"Require branches to be up to date" off** — two individually-green PRs can merge into a broken
  `main`. A merge queue solves this properly if the volume justifies it.
- **Force-push and branch deletion permitted** on the default branch.
- **Admins exempt.** Common, and it means the rule does not apply to the people who merge most.
- **No `CODEOWNERS`**, so review lands on whoever is nearby rather than whoever knows.

Evidence beats opinion here — measure their own history rather than asserting a standard:

```sh
gh pr list --state merged --limit 50 --json number,reviews,mergedAt,additions
gh run list --branch main --limit 50 --json conclusion,name,createdAt
git log --oneline --first-parent main -50        # merges vs direct commits
```

From that you can state, factually: how many merges reached `main` with no pull request, how many PRs
merged with zero approvals, how often `main`'s own CI is red and for how long, and how often changes
are reverted. **A team that argues with a recommendation rarely argues with its own numbers.**

## 4. Release and production gates

- **Is the deployed commit knowable?** If nobody can say which SHA is in production, nothing else in
  this section can be verified. Fix that first.
- **Deploy approval**: GitHub Environments support required reviewers, wait timers, and restricted
  branches. If deploys run straight off a merge with no gate, say so — that is a choice worth making
  deliberately rather than by default.
- **No rollback, or an untested one.** Ask when it was last exercised. A rollback path that has never
  been run is a belief.
- **Migrations ordered against deploys** (see `production.md` §4). Ask which runs first and whether
  anything enforces it.
- **No smoke test after deploy** — a pipeline that reports success when the process started, not when
  the change works.
- **No tag, release, or changelog**, so "what shipped" is reconstructed from memory during an incident.
- **Release built from a dirty or unpinned toolchain**, so the artifact cannot be reproduced.
- **No freeze or ownership convention** for risky periods, if the team wants one.

## 5. Deploy-time risk — what is true *right now*

Distinct from everything above: those ask whether the pipeline is sound, these ask whether **this
change, at this moment** should go out. Cheap to check, and the ecosystem's incident tooling covers
them precisely because they keep causing outages.

- **Is an incident open on this service?** Shipping during an ongoing incident adds a variable to a
  system somebody is already debugging, and muddles the timeline they will use to diagnose it.
- **Is anyone watching?** An on-call handoff minutes away, or a gap in the rotation, means the change
  lands with nobody who knows about it looking. Deploying into that is a choice, not a default.
- **Has this code hurt before?** The revert and hotfix history already tells you which files are
  incident-prone; a change touching them deserves more care than its diff size suggests. This is the
  highest-value warning available from data every repo already has.
- **Can you see it work?** Not "is there a dashboard" — is there a signal that would *change* if this
  specific thing broke, and does anyone know where it is? Watching after a deploy is worthless if
  nothing observable moves.
- **Does the service shed load and drain gracefully?** Requests dropped mid-deploy are invisible,
  constant, and fixable — and almost nobody checks until a customer reports it.

## 6. Tests, and what they are actually measuring

- **Coverage on changed lines, not global percentage.** A repo-wide number is a bad gate: it barely
  moves, so it never blocks anything, and it punishes people who touch large old files. Coverage of
  *new and modified* code is the version that changes behaviour.
- **Do the tests exercise the path a real request takes**, or only units around it?
- **Flaky-test policy**: quarantine with an owner and a deadline. Blanket retries convert real
  intermittent bugs into invisible ones.
- **Load and chaos testing** — usually absent, and often reasonably so. Name it as a deliberate
  decision rather than leave it unmentioned, so nobody assumes it happened.
- **A structured security lens** (OWASP Top 10, STRIDE) beats ad-hoc "check security", especially for
  a first pass on unfamiliar code.

## 7. Repository basics

Cheap, and their absence is usually a symptom rather than the disease:

- **SLOs and an error budget**, if reliability is contested. It is the mechanism that decides whether
  the next sprint is features or fixes, and its absence is why that argument recurs monthly.
- **Conventional commits** — only where the repo already trends that way; it automates changelog and
  version selection. Never impose it on a log that reads otherwise.
- `CONTRIBUTING.md` (how to propose a change), `CODEOWNERS`, a PR template that asks for test evidence
  and a rollback note, `SECURITY.md` (where to report a vulnerability), `LICENSE`.
- `.gitignore` gaps — committed build output, `.env` files, credentials, large binaries in history.
- Long-lived and abandoned branches; branch naming that makes ownership unclear.
- **Can a newcomer get to a passing test run in one command?** Try it. If setup takes an afternoon of
  tribal knowledge, that is upstream of every other process problem and worth naming first.
- **Are the checks trusted?** A permanently red `main`, or a job everyone re-runs until it passes,
  means the team has already learned to ignore signal. Adding another check to that repo makes things
  worse, not better — restoring trust in the existing ones comes first.
- **Flaky-test policy.** Blanket retries convert real intermittent bugs into invisible ones. Quarantine
  with an owner and a deadline beats `retries: 3`.

---

## Reporting this well

You are describing someone's repository, often to people who inherited it and already know it is
imperfect. A list of forty deficiencies is socially expensive and gets ignored.

- **Lead with their own data**, not with a standard: "eleven of the last fifty merges to `main` had no
  approving review" lands where "you should require reviews" does not.
- **Name the constraint you can see.** Missing CI on a small internal tool is a reasonable trade-off;
  missing CI on a service with weekly incidents is not. Say which you think this is, and why.
- **Separate security-urgent from everything else.** `pull_request_target` with a head checkout, a
  committed secret, or an unpinned action with write permissions are not "nice to fix" — raise them
  first, and directly to the user rather than in a document.
- **Cap the plan.** Five to seven items someone might actually do; the rest as an appendix. A
  forty-item plan is a way of not being acted on.
- **Make the first item small, obviously safe, and clearly valuable** — pinning actions to SHAs, adding
  `permissions: contents: read`, adding a `pull_request` trigger. Earning the second change matters
  more than the first change being the biggest.
