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

## 0. What this environment can even do — establish before auditing anything

**Run this first.** Every check below assumes a forge that offers the feature and an account permitted
to use it. That assumption is often false, and when it is, the whole audit misreads: a repo with no
Actions workflows because Actions are *unavailable here* is a completely different finding from one
that simply never set them up, and proposing "add a `pull_request` workflow" to the first is advice
that cannot be taken.

Discover, read-only:

```sh
command -v gh                                  # absent? see the first row of the table below
git remote -v                                  # is there a remote at all?
gh auth status                                 # authenticated? which host? which scopes?
gh repo view --json viewerPermission,isPrivate,visibility,defaultBranchRef
gh api repos/{owner}/{repo}/actions/permissions          # 403 here means unknown, not disabled
gh api repos/{owner}/{repo}/rulesets                     # readable at READ — start here
gh api repos/{owner}/{repo}/branches/{default}/protection # admin-only; 404 is ambiguous
```

**Resolve the default branch first** — `defaultBranchRef.name`. Querying `main` on a repo whose default
is `master` returns a 404 that looks exactly like "unprotected", and you will report a control missing
on a branch that does not exist.

**Query rulesets before branch protection.** Rulesets are the current mechanism and, unlike the legacy
protection endpoint, `GET /repos/{o}/{r}/rulesets` and the per-ruleset detail are **readable with plain
READ access**. That single call often converts the audit's most consequential line from *unknown* to a
verified answer. Then check two things beyond existence:

- **`enforcement`** — `active` or `disabled`. A ruleset with `enforcement: disabled` is a control that
  looks real in the settings UI and stops nothing. That is a finding, and it is invisible if you only
  check whether a ruleset exists.
- **`bypass_actors`** — a required check that an admin, app, or team can bypass is a different
  guarantee from one nobody can. An empty list is worth stating.

Cross-reference the required check *names* against the workflows you read. A ruleset requiring a check
called `ci` proves nothing until you find the job that produces that exact name — and a required check
that no workflow ever emits blocks every merge or none, depending on configuration.

Read the failures as data — they are the answer, not an error:

| observation | what it means | how to report it |
|---|---|---|
| `gh` not installed | the **CLI** is absent, not the controls. `gh auth status` fails as "command not found", which is not the unauthenticated case below | everything settings-derived is **unknown**. Offer the install, audit what is on disk, and never report a control missing because you could not look |
| no remote at all | local-only repo; **no forge CI is possible** | not a gap the team can close by configuring; say so |
| host is not github.com | GitLab / Gitea / Forgejo / Bitbucket / GHES — different CI system, different feature set | audit their equivalent; do not propose Actions |
| `gh auth status` unauthenticated | you cannot see settings, protection, or runs | everything settings-derived is **unknown**, never *absent* |
| Actions `disabled` at repo or org level | workflows will not run even if written | **missing support**, not missing configuration |
| `actions/permissions` returns a permissions error | you are not an admin | **unknown** — *not* "Actions are disabled" |
| `viewerPermission` is `READ` | no settings or org policy; **rulesets are still readable** | query rulesets anyway before recording *unknown* |
| `rulesets` returns `[]` | readable and genuinely empty | **absent** — real evidence, though legacy branch protection may still exist unseen |
| ruleset present with `enforcement: disabled` | a control that enforces nothing | **absent in effect** — say it plainly; the settings page implies otherwise |
| a settings field is `null` inside a `200` | the response succeeded and the field is withheld — `security_and_analysis` and `delete_branch_on_merge` do this without admin | **unknown**, exactly like a 403. A successful response is not a complete one |
| protection endpoint 403 | needs admin | **unknown** |
| protection endpoint 404 | **ambiguous** — GitHub returns 404 rather than 403 to avoid disclosing existence, and also returns it for a branch that does not exist | **unknown**, unless `viewerPermission` is `ADMIN` *and* the branch exists — only then is it *absent* |
| self-hosted forge with no runners registered | CI is defined and never executes | worse than absent; the badge lies |

**Without `gh`, most of this file still works.** The distinction is *on disk* versus *settings*, and
it is worth stating in the report rather than abandoning the section:

- **Still auditable** — everything in `.github/workflows/`: triggers, `permissions:` blocks, action
  pinning and mutable tags, `timeout-minutes`, `concurrency`, fork-PR trigger choice. That is
  sections 1 and 2 nearly in full, and it is where most workflow findings live anyway.
- **Needs `gh`** — rulesets and branch protection, repository and Actions settings, secret scanning,
  code scanning, run history and review statistics. Sections 1b and 3, and the *their own numbers*
  evidence throughout.

Say which half you ran. A report that covers the workflows and marks the settings **unknown** is a
useful half; one that says nothing because the first command failed is not.

### Check what is configured against what is enforced

**The most common real finding on a mature repo is a control that exists and does nothing.** It is not
an absence — the settings page shows it, a reviewer would swear it is on — so an audit that only asks
"is it there?" reports it as present. Ask separately whether it *bites*. Four shapes, all seen in the
field:

| shape | how to catch it |
|---|---|
| A ruleset or branch rule at `enforcement: disabled` or `evaluate` | read the `enforcement` field, never just the name |
| Documentation naming required checks that the ruleset does not contain | diff the documented list against `required_status_checks` |
| A check that is published but not required | cross-reference emitted job names against the required contexts |
| A migration left half-done — the rule exists but the default branch is excluded, or the line is commented out pending a rollout | read `conditions.ref_name.include`/`exclude`, and grep config-as-code for commented-out rules |
| A `SECURITY.md` naming a reporting channel that is switched off | ask the API whether the channel exists, below |

**The security policy is the one document whose accuracy is load-bearing for a stranger.** A
`SECURITY.md` that says "use the Security tab and choose *Report a vulnerability*" is wrong if private
reporting is disabled: the researcher finds no such button, and the policy's own fallback then sends
them to a public issue — publishing the vulnerability, which is the single outcome the file exists to
prevent. Check it rather than reading it:

```sh
gh api repos/OWNER/REPO/private-vulnerability-reporting --jq '.enabled'
```

`true` or `false`, and a repo with no `SECURITY.md` at all is a smaller problem than one with a policy
that misdirects. If the file names an email address or a form instead, say that you could not verify
it — an address is not checkable from here, and claiming otherwise is the shape of finding this
section exists to catch.

The tell is a **mismatch between two sources that should agree**: a doc and a ruleset, a comment and a
condition, a job name and a required context. Whenever a repo states a control in prose *and*
configures it, compare them — that gap is where the finding is, and it is invisible to any check that
reads only one side.

Report these as **absent in effect**, and say which two sources disagree. Where a comment shows the
maintainers already reasoned about it — a staged rollout, a bootstrapping order — it is a **question
for them, not an accusation**: the loop was left open, which is different from nobody having thought
about it.

**Then classify every absence in this file into one of four buckets, and use the words:**

- **absent** — the forge supports it, the account can use it, nobody set it up. *A gap the team owns.*
- **unsupported here** — the platform, plan, or org policy does not offer it. **Still say it.** Name it
  as *best practice with no support in this environment*, say what protection is therefore missing, and
  point at the nearest thing that is available. It is not the team's failing, and it is not the team's
  fix either — but a reader deciding whether this repo is safe needs to know the control does not exist.
- **unknown** — you lacked the permission or the tool to check. Never round this to *absent*; inferring
  a missing control from a 403 is how a report acquires a false accusation.
- **present** — verified, with what you ran to verify it.

**Classify all of them; give a table row only to what needs attention.** This list is long, and a
row per item buries the few that matter. Tabulate *absent*, *unsupported here* and *unknown*;
report *present* as a count plus a one-line list. `mode-a-investigate.md` states the same rule for
the report, and the two must not drift.

A plan item aimed at an *unsupported* control is not actionable and should not be numbered as though
it were. Put it in the report as a stated limitation of the environment, and — where one exists —
propose the substitute that does work: a pre-push hook where there are no required checks, a
`CODEOWNERS` convention where review cannot be enforced, a local gate where there is no CI at all.

---

## 1. What runs, and when — trigger correctness

**`on:` is a YAML 1.1 boolean, and most parsers turn it into `True`.** A workflow's trigger key is
written bare, and `yaml.safe_load` returns `{'name': ..., True: {...}, 'jobs': ...}` — so `doc["on"]`
finds nothing on nearly every workflow in existence. An audit that parses workflows in Python and
looks for `"on"` counts **zero triggers in every file** and reports that nothing validates a change
before the default branch, on a repository that gates every pull request. Read `doc.get("on",
doc.get(True))`, or match text and skip the parser. This was reached first-hand: a naive parse
returned zero pull-request triggers on a repository with eight, and only an independent measurement
caught it.

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
- **A `concurrency:` group too coarse for the event — the inverse defect, and the more damaging one.**
  `group: ${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true` is correct for pull
  requests and wrong for pushes to the default branch: there the ref is constant, so **every merge
  cancels the previous merge's validation run.** Post-merge CI then exists on paper and almost never
  completes. One audited repo finished 3 of 60 runs this way.
  ```sh
  grep -A2 '^concurrency:' .github/workflows/*.y*ml        # is the key constant for push events?
  gh run list --branch <default> --limit 60 --json conclusion \
    --jq '[.[].conclusion]|group_by(.)|map("\(.[0])=\(length)")|join(" ")'
  ```
  **A high `canceled` count on the default branch is the symptom**, and it reads as green in any
  aggregate that only counts failures. The fix is to key on something unique per run for non-PR events
  — `github.event.pull_request.number || github.sha` — or to set `cancel-in-progress: false` there.
  Check the repo's other workflows first: a project that has hit this usually has one file with the
  correct pattern and a comment explaining it, which makes the broken one an oversight rather than a
  decision.
- **No `workflow_dispatch`.** Nothing can be re-run without pushing an empty commit.
- **Fork pull requests get no secrets**, so integration tests silently skip and report success. Decide
  deliberately what runs for forks.
- **Scheduled workflows are disabled after ~60 days of repository inactivity** on GitHub. A nightly
  security scan that quietly stopped months ago is worse than none, because everyone believes it runs.
- **Matrix covers one runtime version while production runs another.**
- **Caches that never invalidate**, so CI passes against dependencies nobody has locally.

### The trigger census, in commands

**Count what triggers a workflow, not what mentions it.** A file matching `pull_request` anywhere may
be triggered by `pull_request_target`, may reference the event in an `if:`, or may just name it in a
comment. The two triggers are not interchangeable — `pull_request` gets a read-only token and no
secrets, `pull_request_target` gets neither restriction — so counting them together hides the finding
that matters. Measured on ten large repositories, `grep -l pull_request` over-reports triggers on
eight of them, and on one it reports 7 where the reality is 2 gated and 4 on the dangerous trigger.

```sh
ls .github/workflows/ >/dev/null 2>&1 || echo "no workflows directory — the finding is absence"
ls .github/workflows/*.y*ml 2>/dev/null | wc -l   # FILES; `ls dir | wc -l` counts README and scripts/
grep -lE '^[[:space:]]+pull_request:|^[[:space:]]*-[[:space:]]*pull_request$|^on:.*[[,][[:space:]]*pull_request[],]' .github/workflows/*.y*ml 2>/dev/null
grep -lE '^[[:space:]]+pull_request_target:|^[[:space:]]*-[[:space:]]*pull_request_target$|^on:.*[[,][[:space:]]*pull_request_target[],]' .github/workflows/*.y*ml 2>/dev/null
grep -lE '^permissions:' .github/workflows/*.y*ml 2>/dev/null | wc -l   # TOP-LEVEL only
```

**Anchor `permissions:` to column zero.** Indented, it also matches every job-level block, and the
question here is whether the *workflow* sets a restrictive default: one audited repository shows a
`permissions:` line in all seventeen workflows and a top-level default in thirteen.

**Run the first line first.** A repository with no `.github/workflows` is the case this whole section
exists to find, and without the redirections every command below it fails with `No such file or
directory` instead of returning zero — noise at exactly the moment the answer is *"nothing runs on a
pull request, because nothing runs at all"*. Observed on a repository with six figures of stars and no
CI whatsoever.

The three alternatives cover the block form, the sequence form, and the inline list `on: [push,
pull_request]` — the last is what a naive indent-anchored pattern misses, and it cost two repositories
their correct count before it was added. **List the files, do not only count them**; the names are
what let you say which suite gates what.

## 1b. Repository settings, not just workflow files

**Half of what governs Actions is not in `.github/`.** A workflow can be flawless and still run with a
write-scoped default token, or accept any action from anywhere. These are separate API surfaces and a
file-only audit never sees them.

```sh
gh api repos/{o}/{r}/actions/permissions           # enabled, allowed_actions
gh api repos/{o}/{r}/actions/permissions/workflow  # default token scope, PR-approval ability
gh api repos/{o}/{r}/actions/permissions/fork-pr-contributor-approval
gh api repos/{o}/{r}/actions/runners               # self-hosted?
gh api repos/{o}/{r}/actions/secrets               # how much is there to steal
gh api repos/{o}/{r}/code-scanning/default-setup
gh api repos/{o}/{r} --jq '{delete_branch_on_merge, allow_auto_merge}'
```

| setting | what to look for |
|---|---|
| `default_workflow_permissions` | `write` hands repo-write to every action in every job, including third-party ones. `read` is the safe default and costs nothing to set. |
| `can_approve_pull_request_reviews` | if true, a workflow can approve a PR — which defeats required review |
| `allowed_actions` | `all` permits any action from any owner. Restricting is the highest rung available, at the cost of friction whenever a new action is wanted |
| fork-PR approval policy | on a public repo anyone can open a PR that runs CI. Confirm the policy is at least `first_time_contributors` |
| self-hosted runners + secret count | **these set the blast radius of a fork PR.** Zero runners and zero secrets means the worst case is stolen compute; a self-hosted runner with secrets means something else entirely |
| `code-scanning/default-setup` | free on public repositories, and it lints workflows themselves. `not-configured` on a public repo is a cheap gap |
| `delete_branch_on_merge` | off means merged branches accumulate and someone tidies them by hand forever |

**Judge a fork PR by what it can reach, not by whether it runs your code.** Any repository whose CI
runs a checked-in script executes the PR author's version of that script — that is inherent, not a
defect. What decides severity is the trigger (`pull_request` gets a read-only token and no secrets;
`pull_request_target` does not), the secret count, and whether a self-hosted runner is involved. Say
the blast radius out loud rather than reporting the mechanism as though it were a finding.

**Some of these need scopes an audit may not hold.** The code-scanning endpoints require
`security_events`; a token without it returns `404`, which is indistinguishable from *not configured*.
Record **unknown** and name the scope — do not report a control as missing because you could not see it.

**And some settings the API reports are simply wrong.** `security_and_analysis` carries
`secret_scanning_non_provider_patterns` and `secret_scanning_validity_checks`, and both are
**write-discarded and read-unreliable** on the repository endpoint: `PATCH` returns `200` while
dropping the field, and `GET` can report `disabled` for a control the settings page shows enabled.
Observed on a repository where the same token successfully changed an unrelated field on that same
endpoint, so it is not a permissions problem.

The rule that follows generalizes past these two fields: **a `200` is not a write, and a read is only
evidence if a write through the same surface would have been honored.** Re-read after every settings
change you make, and where a control is UI-only, say that the settings page is the source of truth and
name the path. Reporting `disabled` here would be reporting a control as absent when it is present —
the inverse of the error this file spends most of its length preventing, and just as wrong.

## 2. Actions supply chain and permissions

- **Third-party actions pinned to a mutable tag** (`@v4`, `@main`). A tag can be re-pointed at new
  code; pin to a full commit SHA with the version in a trailing comment. This is the cheapest real
  security improvement most repos can make.
  ```sh
  grep -hoE 'uses:[[:space:]]*[^[:space:]@]+@[0-9a-fA-F]{40}' .github/workflows/*.y*ml 2>/dev/null | wc -l
  mut=$(grep -hoE 'uses:[[:space:]]*[^[:space:]@#]+@[^[:space:]#]+' .github/workflows/*.y*ml 2>/dev/null \
    | grep -vE '@[0-9a-fA-F]{40}' | grep -vE 'uses:[[:space:]]*\.')
  printf '%s\n' "$mut" | grep -cE  'uses:[[:space:]]*(actions|github)/'   # first-party
  printf '%s\n' "$mut" | grep -vcE 'uses:[[:space:]]*(actions|github)/'   # third-party — rank these
  printf '%s\n' "$mut" | grep -vE  'uses:[[:space:]]*(actions|github)/' | sort | uniq -c | sort -rn
  ```

  **Match the workflow files, not the directory.** `grep -r` over `.github/workflows/` reads whatever
  else lives there. One audited repository keeps markdown sources beside the YAML they compile to, and
  two of them carry `uses:` references — inflating its pinned count by four. It is the same trap as
  counting directory entries instead of files, one measurement further down.

  **Report the third-party number, not the total.** They differ by more than the rounding: on one
  audited repository the combined figure was 66 and the third-party figure 28, and it is the 28 that
  the finding is about. A first-party `actions/checkout@v5` on a mutable tag is a different risk from
  a third-party action on one, and quoting the total inflates the finding while burying it.

  The listing gives counts per reference rather than a total, because the total is the number least
  worth reporting — see the blast-radius rule below. A local `uses: ./` is not
  third-party and is excluded. **Do not anchor the SHA filter to end-of-line**: `uses:` values are
  often quoted, so `@<sha>'` does not end at the hex and every quoted pinned action is then reported
  as mutable. That single character was the difference between a clean answer and a false finding on
  a repository that pins everything.

- **Audit every executable fetch, not just `uses:`.** A `uses:`-only check reports a clean bill of
  health on repos that download and run unpinned third-party code at build time — a false *clean*,
  which is worse than a false alarm. A repository can score 100% SHA-pinned on `uses:` and still
  execute unpinned code — `go install …@latest`, or `curl … | bash` off a third party's default
  branch, sometimes inside a production workflow. Grep the `run:` steps too:
  ```sh
  grep -rnE 'curl[^|]*\|[[:space:]]*(ba)?sh|bash <\(curl' .github/workflows/
  grep -rnE '(go|cargo|pipx|uv tool) install[^|&;]*@(latest|main|master)' .github/workflows/
  grep -rnE 'npm i(nstall)? -g|pipx? install ' .github/workflows/   # ignore the -r requirements hits
  ```
  Rank what you find by what the job can reach, not by count: a fetch in a release or deploy job
  holding registry credentials outranks twenty in a comment bot.
- **Rank pinning findings by blast radius, never by tally.** Separate first-party (`actions/*`,
  `github/*`) from third-party, then order by the permissions of the job the action runs in. A raw
  count inverts the answer: ninety mutable refs that are all PR-comment bots holding
  `pull-requests: write` matter less than a handful on the release path holding registry credentials.
- **Count `timeout-minutes` per job, not per file.** It is a job-level key, and a file count
  misreports in both directions: one repository has it in 7 of 17 files but only 7 of 57 jobs, another
  in 6 of 7 files but 14 of 15 jobs. The first looks half-covered and is not; the second looks patchy
  and is nearly complete.
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
  *new and modified* code is the version that changes behavior.
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

---

## Reporting this well

You are describing someone's repository, often to people who inherited it and already know it is
imperfect. The rules for the report and the plan live in `mode-a-investigate.md` — lead with their
own data, cap the plan, name the constraint you can see, and raise anything security-urgent directly
rather than as a numbered item. They are stated there so they cannot drift from the schema they
describe.

