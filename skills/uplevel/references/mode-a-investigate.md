# Mode A — investigate, then propose

Read this when the task is an audit, a bootstrap, or any "set up guardrails here" request. It ends in
**a report and a numbered plan** — never in changed files. `SKILL.md` carries the posture and the
safety rules that apply regardless of mode; this file is the procedure.

---

**Nothing is written in this mode.** It ends with a report and a plan. If the user asks you to "set it
up", that still means: investigate, propose, and wait — then build what they choose.

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
   "272 matches" is an artefact. Check `git log --merges` first: if the count is ~0 the project
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
     `grep -rl workflow_call .github/workflows/` and `grep -rh 'uses: *\./\.github/workflows/' .github/workflows/`.
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
   - **Check for an existing checklist first** (`checklist.md`). If one exists this is a
     **re-audit**: lead with the diff — resolved, **regressed**, still open and for how long. A list
     that only ever grows stops being read.
   - **Every proposed addition cites what produced it** — an incident, a revert, a near miss, a review
     comment written twice, a capability the repo has just gained. A check with no origin is an opinion
     smuggled into a list of facts, and one of those makes the whole list untrustworthy.

   **Say the absences out loud, by name.** "There is no workflow triggered by `pull_request`, so
   nothing validates a change before it reaches `main`" is a finding; saying nothing reads as approval.

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

**Read `example-output.md` before writing your first report** — one worked example conveys
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

- **Rank every finding by blast radius, never by tally.** This is not a rule about action pinning; it
  applies to all of them. The question is always *what can the thing reach* — which credentials, which
  branch, whose machine, how many users downstream. Ninety mutable refs in comment bots matter less
  than one on the release path. A hundred workflows missing a timeout matter less than one missing
  permission check on a job holding a key. A count tells you how much work a fix is, not how much
  damage it prevents, and reporting the count as the severity inverts the answer often enough to be a
  habit worth breaking.
- **Order by damage prevented per unit of effort**, not by what is interesting to build.
- **Cheapest genuine win first.** If item 1 is a week of work, the plan will not be started.
- **Separate what is definitely broken from what you would merely prefer.** Never blend a taste
  preference into a list of fixes; the reader must be able to trust the whole list.
- **Writing the process document is a plan item only when nothing already fills the role**, and
  usually something does — an `AGENTS.md`, a `CLAUDE.md`, or a substantial `CONTRIBUTING.md`.
  Proposing another competes with a better document. It is the right proposal only where what exists
  is a stub that names none of the project's own commands. Read what
  exists first; if it covers the ground, say so and propose nothing. When it *is* right, say where the
  file would live and whether it would be committed.
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

When the user picks items: branch first (`SKILL.md` → *Before the first change*), do the selected items and
nothing adjacent, land them one reviewable change at a time, and report back what passed, what did not,
and what you did not touch. Scope creep here is the fastest way to make the next proposal unwelcome.

### Calibration

Rules earn their place by having prevented a real incident, or by guarding something genuinely
irreversible. If you cannot name what a rule prevents, cut it. Prefer the rule that names a file and a
line over the rule that names a virtue.

---

