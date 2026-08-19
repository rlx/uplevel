# The living checklist

`forge-hygiene.md` is the **universal seed** — the checks that apply to more or less any repository. It
ships with the skill and changes only when the skill itself is updated.

This file describes the **per-repo checklist**: a small state file that lives in the repository, starts
as the seed, and then grows from that repo's own history. It is what makes the second audit more useful
than the first, and the twentieth more useful than the second.

**It never lives in the skill.** Repo-specific checks written back into `forge-hygiene.md` would
pollute a shared, portable skill with one project's specifics, and would be wrong for the next repo.
The skill stays generic; the knowledge stays with the codebase that produced it.

---

## The file

Proposed location `.claude/guardrails.yml`, or alongside whatever process document the team accepted —
their call, same as the document itself. Committed is usually right: the point is that it outlives the
person who learned the lesson, and reaches the contributor who has not yet made the mistake. Local-only
and gitignored is a legitimate choice for a repo where an agent-specific file is unwelcome.

**In a public repository, split the file.** A committed checklist should record what is **in place**;
what is absent, unverified, or still being argued about belongs in an untracked companion the team
works from. The reasoning is not secrecy about the controls — it is that a published list of a
project's own gaps, ranked and dated, is a starting point for anyone who wants to use them, and it
ages into an accusation the moment the work is done and the file is not updated. Say this out loud
when you propose the file; it is the team's call, and a private repo has no such problem.

```yaml
version: 1
generated_by: uplevel
last_audit: 2026-03-04

profile:                      # what makes this repo's risk shape specific
  deploys: continuous-on-merge
  data: postgres, one-way migrations
  contributors: 12, mostly first-time

checks:
  - id: ci-runs-on-pull-request
    source: universal
    status: enforced          # present | absent | unknown | enforced | retired
    severity: high
    evidence: ".github/workflows/test.yml triggers on pull_request"
    enforced_by: "required status check 'test' on main"
    last_checked: 2026-03-04

  - id: actions-pinned-to-sha
    source: universal
    status: absent
    severity: high
    evidence: "6 of 9 third-party action references use a mutable tag"
    last_checked: 2026-03-04

  - id: no-raw-sql-in-request-path
    source: derived           # learned here, not from the seed
    origin: "incident 2026-02-11 — unbounded query in /reports timed out the pool; fixed in 4f21a9c"
    status: absent
    severity: high
    evidence: "3 call sites still build SQL inline"
    proposed_enforcement: "lint rule; would have caught the 2026-02-11 query"
    added: 2026-02-12
    last_checked: 2026-03-04
```

Field rules:

- **`source: derived` requires `origin`** — the incident, PR, commit, or observed behavior that
  produced it. A derived check with no origin is an opinion that has smuggled itself into a list of
  facts, and the list stops being trustworthy the moment it contains one.
- **`status: enforced` means stop asking.** Once a check is a CI job or a database constraint, the
  entry records what enforces it and the audit no longer treats it as a manual item. This is the
  automation ladder in `automation.md`, made stateful.
- **`retired` rather than deleted.** Keep the entry with a reason. A check that was removed because it
  became irrelevant reads very differently from one removed because it was annoying, and only the file
  can tell you which happened.
- **`unknown` is a real status**, not a synonym for absent. Branch-protection APIs need admin rights;
  record that you could not see, and say so in the report.

---

## Where new checks come from

Every audit after the first should propose additions. Sources, in rough order of value:

1. **A new incident.** The strongest source. Something broke; the check is whatever would have caught
   it earlier. Cite the incident in `origin`.
2. **A revert or hotfix** in the log since the last audit — an incident whose write-up is missing.
3. **A near miss.** Caught in review, or by someone noticing. These are free lessons and are almost
   never written down anywhere.
4. **A new contributor's first pull request.** It reveals the unwritten assumptions of the codebase
   more reliably than any audit — whatever a reviewer had to explain by hand is a candidate check, and
   the same explanation will otherwise be given to the next newcomer.
5. **A repeated review comment.** If the same note is written twice, it is a rule; if written three
   times, it should have been a check.
6. **Drift** — something recorded `present` that is now `absent`. Protections get relaxed under
   deadline pressure and rarely get restored.
7. **New capability in the repo** (below).

## Growth triggers

A repo's risk shape changes when it gains something it did not have. When the audit notices one of
these for the first time, propose the checks that come with it:

| when the repo gains… | propose checks for |
|---|---|
| its first schema migration | expand/contract ordering, a tested down path, lock duration, realistic-size testing |
| its first background job or queue | idempotency, retry bounds, dead-letter handling, queue-age alerting |
| its first public endpoint | authn/authz coverage, input validation, rate limiting, pagination bounds |
| its first external dependency call | timeouts, retry with jitter, circuit-breaking, failure-mode test |
| its first paid API or cloud resource | cost bounds, a budget alert, a non-production sandbox |
| user data of any sensitivity | PII out of logs, retention, export/delete paths, access audit |
| a second deployable | version compatibility across the rollout window, contract tests |
| a second team or many contributors | `CODEOWNERS`, PR template, review requirements, onboarding command |
| a scheduled job | failure alerting, and the fact that idle repos have schedules auto-disabled |

## Re-auditing

When a checklist already exists, the audit is a **diff, not a fresh survey**. The report leads with
what changed:

- **Resolved** — `absent` → `present`/`enforced` since last audit. Say it; a list that only ever grows
  is demoralising and stops being read.
- **Regressed** — `present` → `absent`. The most valuable line in a re-audit.
- **New checks proposed**, each with its origin.
- **Still open**, aged. A check absent for eleven months is either not actually important or genuinely
  blocked — say which, and consider retiring it. Permanent red entries teach people to skim.
- **Unknown**, and why it stayed unknown.

Update `last_checked` on everything you actually verified, and nothing you did not. A stale date is
information; a falsely fresh one is a lie about coverage.

---

## Sharing a lesson with other repos

A check learned in one repo is sometimes a check every repo needs. Moving it is deliberate, not
automatic — and the direction matters. Seed → repo happens on every audit and is just the seed doing
its job. **Repo → seed is promotion, and it needs a gate.**

### The generality test

> Would this check make sense in a repo that shares **none** of this one's code, team, or stack?

If yes, it is a candidate for the skill's seed list and every project that uses the skill benefits. If
no, it stays local — most learned checks do, and that is the design working. The failure mode here is
enthusiasm: promoting everything recreates exactly the bloated generic checklist the per-repo file
exists to avoid. **A check that fires everywhere and matters nowhere is worse than no check**, because
it costs attention on every audit and teaches people to skim the list.

Three questions that catch most bad promotions:

- **Is it a property of the tooling, or of this team's choices?** "Actions pinned to SHAs" is general.
  "PRs need two approvals" is a team norm.
- **Would it be actionable in a repo with a different architecture?** If it names a service, a table,
  or an internal convention, it is local.
- **Is it already covered by a more general check?** Prefer strengthening the existing entry.

### Sanitize before promoting

The value of a derived check is its `origin`, and origin is exactly the field that leaks. Promote the
**check**, never the incident narrative. Strip internal detail — customer names, incident IDs, internal
hostnames and URLs, colleague names, revenue or user numbers, and any description specific enough to
identify the outage. Replace it with the abstracted lesson:

```yaml
# local
origin: "incident 2026-02-11 — unbounded query in /reports timed out the pool for 40 min"
# promoted
origin: "learned in a service with continuous deploy; unbounded query exhausted a connection pool"
```

If the skill is shared outside your organization, treat promotion as **publishing**: apply the same
care you would to a public postmortem, and ask the user before it leaves the building.

### Where it goes

The skill has no privileged storage of its own, so "shared learning" means one of these:

| approach | who it reaches | cost |
|---|---|---|
| **Personal skill** (`~/.claude/skills/`) | every repo you work on, on this machine | none — this already happens |
| **Skill in a git repo, installed as a plugin** | everyone who installs it; updates propagate on pull | a repo and a release habit |
| **Shared org checklist** the repo file inherits from | every repo in the org, centrally curated | somewhere to host it, and a merge rule |

**There is no built-in mechanism that syncs learning between repositories.** Cross-repo sharing is
achieved by moving a check into something that is itself shared — the skill package, or a checklist
the repos deliberately inherit from. Anything else is copy-paste, and copy-paste drifts.

If a shared org checklist is used, the local file names it and the local entries win on conflict:

```yaml
extends: git@internal:platform/guardrails-baseline.yml   # fetched read-only, never written back
```

Inheritance is not automatic obedience: an inherited check that does not apply to this repo is marked
`retired` locally with a reason, not silently ignored. And the org baseline is someone's
responsibility — an unowned shared checklist rots faster than a local one, because nobody feels the
cost of a stale entry.

---

**The checklist is proposed, like everything else.** Creating it, adding to it, and committing it are
plan items the user picks. Do not write it unasked, and do not treat a check the user declined as a
finding to re-raise every audit — record it `retired` with `reason: declined by owner`, and let it go.
