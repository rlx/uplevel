# Mode A — investigate, then propose

Read this when the task is an audit, a bootstrap, or any "set up guardrails here" request. It ends in
**a report and a numbered plan** — never in changed files. `SKILL.md` carries the posture and the
safety rules that apply regardless of mode; this file is the procedure.

---

**Nothing is written while you are investigating.** The mode ends with a report and a plan; if the
user asks you to "set it up", that still means investigate, propose, and wait. Writing begins only
once they have picked, which is what *Execute* below covers — and at that point you are no longer
investigating, so branch first and build only what was chosen.

### Establish what kind of repository this is

**Before anything else, and in one line.** This skill is weighted toward services that run somewhere
and can page someone. Most repositories are not that, and the same finding means different things
depending on which one you are looking at. Decide early, say it in the report, and let it set the
weighting — deciding late means writing a report and then discovering it was aimed wrong.

| kind | tell | what changes |
|---|---|---|
| **service** | deploy config, migrations, environments, an on-call anything | the default. Weight deploys, rollback, migrations, environment safety |
| **library** | published to a registry, semver, consumers you cannot see | weight release integrity and backwards compatibility; deploys are irrelevant |
| **reference or teaching** | the artifact is the code being read, forks are the point | weight reproducibility and cost-to-run. Missing CI may be entirely defensible |
| **tooling or config** | CI definitions, infrastructure, dotfiles, prompts | the repository *is* the process; its own gate is the product |
| **application, not deployed by you** | shipped as source or an image someone else runs | **you cannot roll back.** Weight upgrade and migration safety hardest |

**The kind decides whether an absence is a finding.** Missing CI on a teaching repository whose test
suite needs rented GPUs is a defensible trade-off; missing CI on a service with weekly incidents is
not. Both are *absent*; only one is a *problem*. Saying which you think it is — and why — is the
difference between an audit and a checklist read aloud.

**Reading the tells, from running them against real repositories:**

- **A repository can be two kinds, and then it inherits both weightings.** One audited project
  publishes to PyPI *and* ships `docker run` self-host instructions: it has a permanent published
  version *and* an upgrade path running on other people's data, and an audit that picks one misses
  half of what can hurt it. Say both, and weight both.
- **Find the release path before describing it, rather than inferring one from a manifest.** A
  `pyproject.toml` can exist to make code installable for reproduction and never reach a registry. And
  no publish job does not mean no publishing — it often means someone runs `npm publish` from a
  laptop, which is a finding rather than the absence of one: the release path exists and nothing
  guards it. Look for the publish job, or the package on the registry, and say which you found.
- **A CLI shipped as binaries through releases** has no registry and no image, and is still something
  other people run and you cannot roll back. Weight it as *application others run*, whatever the
  distribution channel is.

**When it is not obvious, ask.** One line, before you spend the context.

### Scope it first

**A full audit is not the only shape, and it is not always the right one.** Someone asking whether
their CI is sound does not need the hazard catalog; someone about to run a migration does not need
the release-tagging section. The full sweep reads most of `references/` before touching the
repository, which on a large one competes with the repository for context.

Ask what they want to know, and read only what answers it. `selfcheck.sh` prints what each costs.

| scope | when | read, beyond this file |
|---|---|---|
| **forge** | "is our CI sound?", "are we exposed through Actions?" | `forge-hygiene.md` |
| **gate** | "what actually validates a change?", "why did this reach main?" | `discovery.md`, `evidence.md` |
| **hazards** | before a migration or a deploy; "what here is irreversible?" | `destructive-ops.md`, `production.md` |
| **full** | an audit, a bootstrap, "set up guardrails here" | everything below |

A scope costs between a third and half of the full audit — `selfcheck.sh` prints the current figures,
which is where that range comes from. Take one when the question is narrow, and **offer the rest**:
"I looked at the forge; the gate and the hazards are unexamined, and either is another pass."

**Say the scope in the report, in the first line.** This is the same rule as naming absences, pointed
at yourself: a reader who does not know you skipped the hazards will read your silence about them as
approval. A scoped audit that announces its scope is a useful answer; one that does not is a misleading
one, and the misleading version looks identical.

**Two things are never scoped away.** Anything security-urgent you happen to see gets raised whatever
you were looking for. And if the scope you were given is the wrong one for what the repository is —
a forge audit on a service that deploys unattended to machines nobody owns — say so, then do the scope
they asked for.

### The one hard rule: discover, never guess

Every command you put in the report must have been **run once, in this repo, and observed to work**. A
gate command that doesn't exist is worse than no gate — it manufactures confidence, and the next
session will report green having run nothing. If a command cannot be verified (needs credentials, a
deployed environment, paid infrastructure, or **a toolchain this machine does not have**), record it
as `— unverified, needs X`. **Never run an unverified command against a deployed environment to find
out what it does.**

**Preflight the toolchain before you rely on that rule** — `discovery.md` §*Toolchain
preflight*. Do not assume the machine can build the repo — often it cannot, and when it cannot the
hard rule quietly converts the whole gate section to `unverified` and the report stops being worth
reading. Read the repo's declared versions (`engines`, `packageManager`, `go.mod`, `.tool-versions`,
the CI `setup-*` steps), compare them to what is installed, and **name any missing or mismatched tool
in the report**. Offer the install command — `corepack enable` first, since a pinned package manager
is the most common gap — and let the user decide; installing a runtime is a change to their machine,
not to the repo you were pointed at. A version *mismatch* is the trap, not absence: the wrong major
package manager installs a wrong tree instead of failing.

### Investigate

1. **Read what already exists.** `README`, `CONTRIBUTING`, `docs/`, runbooks, CI config,
   `Makefile`/`justfile`/package scripts, `.pre-commit-config.yaml`, `.git/hooks/`,
   `docker-compose.yml`, deployment manifests, `.env.example`. Most projects already have a process; it
   is just scattered and unenforced. **Do not propose one that competes with it.**

   **Look wider than the file your own tool loads.** Agent-facing process turns up in `CLAUDE.md`,
   `AGENTS.md`, `.claude/`, `.agents/`, `.agent/`, `.cursorrules`, and
   `.github/copilot-instructions.md`, and projects pick different ones. Search for all of them before
   concluding anything is missing:
   ```sh
   ls -d .claude .agents .agent .cursor 2>/dev/null
   find . -maxdepth 4 \( -iname 'AGENTS.md' -o -iname 'CLAUDE.md' -o -iname 'SKILL.md' \
     -o -iname '*instructions.md' -o -iname '.cursorrules' \) -not -path '*/node_modules/*'
   ```

   **If substantial process exists somewhere your tool will not load automatically, that is a finding
   — and it is not "absent".** Classify it **present, not auto-loaded**: a person who already knows it
   is there can point at it, so nothing is missing, but nothing surfaces it either. One audited
   repository kept eight skills and over a thousand lines of review standards in a directory its
   contributors' agent never reads; the process was thorough, committed, actively maintained, and
   invisible by default.

   The cost is onboarding, and it falls on exactly the people least able to notice: a newcomer, or a
   fresh session, does not know to ask for a document whose existence is undocumented. Say so plainly,
   name the path, and say which readers do and do not pick it up.

   **Search the subtree, not only the root.** Large repositories commonly carry a second agent
   document scoped to one component — a monorepo with a root `AGENTS.md` and another governing its
   storage layer, with different and stricter rules. For work inside that subtree, the nested one is
   the binding document, and a root-only search reports it as absent.

   **Note what is addressed to agents specifically.** A growing number of projects now write rules at
   automated contributors rather than about them: *"if you are a coding agent, stop here and ask"* above
   a golden-file regeneration command, *"don't fix golden-value drift by hand"*, or an explicit list of
   prohibited output categories with an instruction to stop and name the category. Report these as
   present and binding — they are a repository consenting in advance to some operations and refusing
   others, which is exactly the signal this audit is looking for, and they belong in the process
   document you propose.

   The same search turns up **attribution and disclosure rules**, which cut both ways and are worth
   reporting separately: some projects require an AI-assistance disclosure on every PR, others forbid
   AI credit in commit messages, PR bodies, and comments outright. A contribution can be bounced on
   either. Never infer one from the other.

   **Do not prescribe a layout.** Which file wins is the project's call and the conventions move;
   asserting that some tool reads some path will be wrong within months, and wrong in a shipped skill
   is worse than silent. Report the gap and note that several projects solve it by symlinking one
   canonical file to the others — then let them choose.
2. **Read the git log — especially the failures.** Reverts and hotfixes are incidents with the
   write-up missing. **Rules derived from what actually broke here are the only ones certain to earn
   their place** — and they are what makes the plan persuasive rather than generic.

   **Match the subject, never the whole message.** `--grep` searches the body too, and squash-merge
   bodies quote the PR description, so any commit whose discussion mentions "revert" is counted as
   one. The over-count is not marginal — it can exceed the real figure by an order of magnitude. A
   revert rate is a number the team will be asked to react to, and being wrong in the alarming
   direction loses the room in the first minute.

   ```sh
   git log --oneline -50                       # shape, style, cadence
   git log --format=%s | grep -icE '^(revert|"?Revert|[a-z]+(\(.+\))?: revert)'
   git log --format=%s | grep -iE  '^(revert|"?Revert|[a-z]+(\(.+\))?: revert)' | head -20
   git log --format='%h %s' --grep='hotfix\|rollback\|incident\|outage' -i -30
   ```

   Say the window and the rate, not the raw count — "41 reverts in 3000 commits, 1.4%" is a finding;
   "272 matches" is an artifact. Check `git log --merges` first: if the count is ~0 the project
   squash-merges, so every commit on the default branch is a PR and subject matching is reliable.
3. **Find the real gate.** See `discovery.md`, including its rules on reading a command
   before running it. Record what passes, its runtime, and what it does *not* cover.
4. **Map the environments and the path to production.** See `production.md` §1 and §3. Read
   config and ask; **never probe a deployed environment.**
5. **Find the hazards.** See `destructive-ops.md`. Migrations, seed/reset scripts, `--force`
   and `--record` flags, precious-but-gitignored state, anything that spends money or touches customer
   data.

   **Match on shape, not on a word.** Directory names vary and bare keywords hit prose and identifiers:
   `find -type d -name migrations` returns nothing in a tree whose directory is `migration`, and a
   bare `truncate` grep matches string helpers far more often than SQL.
   ```sh
   find . -ipath '*migrat*' \( -name '*.sql' -o -name '*.go' -o -name '*.py' -o -name '*.rb' \) \
     -not -path '*/node_modules/*' -not -path '*/vendor/*'
   grep -rnE '\b(DROP TABLE|DROP COLUMN|TRUNCATE TABLE|DELETE FROM|ALTER TABLE)\b' \
     --include='*.sql' --include='*.go' --include='*.py' .
   ```
   Word boundaries and an uppercase SQL context, scoped to datastore code — then read each hit before
   it becomes a finding.
6. **Audit what is already automated**, and what is defined but not enforced — a job that never blocks
   a merge, and one that is permanently red, are both worse than nothing.
   See `automation.md`.
7. **Run the absence audit.** Discovery describes what exists; this step names what is **missing**,
   which in a repo with recurring incidents is usually where the value is. The seed list, the
   environment-capability check that must precede it, and how to report each item live in
   `forge-hygiene.md` — read it here rather than working from memory.

   **Count, then confirm — and never report an absence you have only counted.** Mechanical counting
   is how this step starts, not how it ends. A low `pull_request:` count reads as a repo with no
   gate, while an orchestrator may fan out to reusable workflows that converge on a single required
   check. Reported as an absence that is the headline of the report, and wrong about its most
   important question. Before any absence is written down, resolve:

   - **Fan-out.** Does an orchestrator reach the checks indirectly?
     `grep -rl workflow_call .github/workflows/` and
     `grep -rh 'uses: *\./\.github/workflows/' .github/workflows/`.
     A low `pull_request:` count next to a high `workflow_call` count means the gate is one level down.
   - **Aliasing.** Is the same suite running under a different workflow name? Compare the *commands*,
     not the filenames — one repo runs its full test suite on PRs from a workflow whose name mentions
     only coverage, so "tests don't run on PRs" was true of the file and false of the repo.
   - **Deliberate design.** Does the file carry a comment, a gate job, or an aggregate check showing
     the maintainers already reasoned about this? If so the finding is a question, never a headline.

   A count is a lead. Only a read is a finding — and **a security-urgent claim may reach the first
   paragraph only after the file has been read end to end.**

   Three rules that decide whether the output is trustworthy:

   - **Classify, never omit.** Every item is **present / absent / unsupported here / unknown**.
     *Unsupported* still gets said, as best practice with no support in this environment plus whatever
     substitute does work. *Unknown* is never rounded down to *absent* — a 403 is a missing permission,
     not a missing control, and treating it as one puts a false accusation in the report.
   - **Classify everything; tabulate only what needs attention.** The seed list runs to dozens of
     items, and a table with a row per item buries the four that matter. Give a table row to each
     **absent**, **unsupported here**, and **unknown**; report **present** as a count with a one-line
     list. Nothing is omitted — a reader can still see that a control was checked and passed — but the
     rows that remain are the ones a decision hangs on.
   - **Check for an existing checklist first** (`checklist.md`). If one exists this is a
     **re-audit**: lead with the diff — resolved, **regressed**, still open and for how long. A list
     that only ever grows stops being read.
   - **If none exists, propose creating one as a plan item.** Everything else this mode produces
     arrives as a chat message and is gone; the checklist is the only durable artifact, and it is what
     makes the second audit a diff instead of a fresh survey of the same ground. Propose it with the
     statuses you just determined already filled in — the work is done, and an empty template is a
     chore nobody completes. Where the file lives, and whether it is committed, is the user's call.
   - **Every proposed addition cites what produced it** — an incident, a revert, a near miss, a review
     comment written twice, a capability the repo has just gained. A check with no origin is an opinion
     smuggled into a list of facts, and one of those makes the whole list untrustworthy.

   **Say the absences out loud, by name.** "There is no workflow triggered by `pull_request`, so
   nothing validates a change before it reaches `main`" is a finding; saying nothing reads as approval.

8. **Ask what code cannot tell you.** One batched message, short: what broke recently and what would
   have caught it; who reviews; who can deploy; what is genuinely irreversible; whether a process
   document is even wanted, and where it should live.

### Report

**Read `example-output.md` first** — one worked example conveys the shape faster than these rules do,
and reading it after the report is written is too late to help.

**Budget: about a screen of findings, plus the table, plus the plan.** There is no length at which a
process report becomes more persuasive; past a screen it becomes a document to be skimmed and filed.
If you cannot fit it, you are reporting things you did not verify, or reporting the same gap more than
once — say each fact exactly once and cross-reference rather than restate.

Lead with findings, not recommendations. Keep it to what you verified:

- **The gate as it exists** — the command, its runtime, and what it does not cover.
- **What validates a change before it reaches the default branch, and before it reaches whatever this
  repository's *downstream* is.** If the answer to either is "nothing", that is the headline, not a
  footnote. **The second half is not always production** — name the one that matches the kind you
  established, because a report that asks a service's question of a library reads as boilerplate and
  gets treated as such:

  | kind | the second gate is | and behind it |
  |---|---|---|
  | service | production | rollback, if it has been exercised |
  | library | the registry | **nothing.** A published version is permanent; see `destructive-ops.md` |
  | reference or teaching | readers and forks | nothing to roll back, and nothing to gate |
  | tooling or config | the repositories it governs | their gates, which yours now sets |
  | application others run | other people's machines | **nothing you control** |

  For three of those five, *there is no rollback at all*, and the release gate is the last reversible
  moment. Say that in the report rather than proposing a rollback that cannot exist.
- **The gaps**, each tied to something real: an incident in the log, an unenforced rule in a doc, a
  hazard with no guard. Say which are *evidence* and which are *inference*.
- **Absences, named** — see the absence audit. Present / absent / unknown, never silently omitted.
- **What is enforced by a machine versus what depends on someone remembering.**
- **What you could not verify**, and why. Do not pad this away.

**Prefer their numbers to your standards.** `gh pr list` and `gh run list` will tell you how many
merges reached the default branch without review, how often its CI is red, and how often work is
reverted. A team rarely argues with its own history, and often argues with a best practice.

**Check that pull requests are how work actually arrives, before computing statistics about them.**
On a repository where they are not, review statistics are meaningless rather than merely wrong: one
audited project had **one merged pull request against sixty-one closed unmerged**, because
contributions arrive as pull requests and the maintainer then applies the work by pushing directly.
"0 of 1 merged PRs had an approving review" is a number dressed as evidence.

The signal is the ratio of closed-unmerged to merged, which does not care how the repository merges:

```sh
gh pr list --state all --limit 100 --json state,mergedAt \
  --jq '{merged: ([.[]|select(.mergedAt)]|length), closed_unmerged: ([.[]|select(.state=="CLOSED" and .mergedAt==null)]|length)}'
```

Around **0.2–0.3** is a project where pull requests are the way in. Above **1** most of them are not
landing, and that — not the review rate — is the finding: contribution friction, an unstated bar, or a
maintainer who applies patches by hand.

**Do not try to measure this by counting merge commits.** A squash merge produces none, so
`grep -c 'Merge pull request'` reports zero on a repository with seventy-five merged pull requests and
reads as a catastrophic disagreement. This was the first version of this rule, and one repository in
the corpus falsified it immediately.

**Anything security-urgent is raised first and directly to the user** — not filed as plan item nine.
An exposed secret, `pull_request_target` running untrusted code with secrets, or an unpinned
third-party action holding write permissions belong in the first paragraph of your reply, and never in
a document that might be published.

### Plan

Then a numbered list the user can pick from — `1, 3, 5` should be a sufficient reply. **Every item
carries all six fields, every time**, in this order:

```
**N. <the concrete change, one line>**
prevents: <the consequence it removes> · if skipped: <what leaving it costs>
effort: <maintainer-hours, including review and consent> · affects: <one of the four values below>
undo: <the exact command, or "not reversible"> · needs: <other item numbers, or "—">
```

`affects` takes exactly one of: **this repo's agents** / **everyone who commits** / **everyone who
merges** / **production**. Do not invent a fifth; the value is what makes the list sortable and
skimmable, and a phrase like "nobody's correctness" tells the reader nothing about who to consult.

Two of these fields exist because a chooser cannot proceed without them:

- **`if skipped`** is the cost of inaction, and it is what makes an item declinable on purpose rather
  than by omission. "Nothing yet, but the next contributor pays" is a legitimate answer.
- **`needs`** is what keeps the pick-list contract honest. If item 1 is unsafe without item 2, then
  `1, 3, 5` is not a sufficient reply and the numbering was a lie. Say `needs: 2` and let the user
  pick both.

Rules for the plan itself:

- **Sort by damage prevented per maintainer-hour.** One rule, not four. *Damage prevented* means blast
  radius — what the thing can reach: which credentials, which branch, whose machine, how many users
  downstream. Ninety mutable refs in comment bots matter less than one on the release path; a hundred
  workflows missing a timeout matter less than one missing permission check on a job holding a key. A
  count tells you how much work a fix is, not how much damage it prevents, and reporting the count as
  the severity inverts the answer often enough to be a habit worth breaking.
- **One adjustment to that sort, and only one.** If the top item would take more than an hour or needs
  someone else's consent, promote the cheapest safe item above it **and say that you did, and why**.
  A plan whose first item is a week of work does not get started. Anything beyond this one move means
  you are sorting by taste.
- **Effort is the maintainer's cost, not your keystrokes.** Count review, the consent you need, and
  the time to land it. A five-minute edit that requires a maintainer to reason about branch protection
  is not a five-minute item. Put a figure on *every* item including the ones you flag as someone
  else's decision — those are precisely the ones where the denominator decides the order.
- **Separate what is definitely broken from what you would merely prefer.** Never blend a taste
  preference into a list of fixes; the reader must be able to trust the whole list.
- **A process document is three different plan items, and reading what exists decides which.** Most
  repositories have something — an `AGENTS.md`, a `CLAUDE.md`, a substantial `CONTRIBUTING.md`. If it
  names the gate command, the branching rule and the path to production, **propose nothing** and say
  it covers the ground. If it covers part of that, **propose appending the missing sections to it**;
  a second document competes with the first and the two will drift. Only where nothing exists, or
  what exists is a stub naming none of the project's own commands, **propose a new file** — and say
  where it would live and whether it would be committed. `claude-md-template.md` carries the test and
  the rules for adding to a file you do not own.
- **Anything affecting other people is flagged as needing a maintainer's decision**, not yours.
- **Say what you would do first if only one item were picked**, and why.
- **Cap it at five to seven items.** Put the rest in an appendix. A forty-item plan is a way of not
  being acted on, and it reads as a verdict on the team rather than an offer of help. Earning the
  right to propose a second change matters more than the first being the biggest — which is what the
  one permitted adjustment above is for.
- **Name the constraint you can see**, and weigh it against the repository kind you established at the
  start. The same absence is a trade-off in one kind and a defect in another; say which you think this
  is, and why.

### Execute — only what was chosen

When the user picks items: branch first (`SKILL.md` → *Before the first change*), do the selected
items and
nothing adjacent, land them one reviewable change at a time, and report back what passed, what did not,
and what you did not touch. Scope creep here is the fastest way to make the next proposal unwelcome.

### Calibration

Rules earn their place by having prevented a real incident, or by guarding something genuinely
irreversible. If you cannot name what a rule prevents, cut it. Prefer the rule that names a file and a
line over the rule that names a virtue.

---

