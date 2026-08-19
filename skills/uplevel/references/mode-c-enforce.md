# Mode C — enforce during ordinary work

Read this when work is already underway in a repo whose rules are known: before a check-in, before a
deploy or migration, during an incident, or when a long run is about to start.

**Most of this belongs in the repo's own `CLAUDE.md`, not here.** A project document costs a few
hundred tokens and is specific to the repo; loading the skill for a routine commit costs far more and
says less. When the bootstrap writes that document, the daily rules — the gate, the environment check,
the guardrail list — move into it, and this skill goes back to being invoked deliberately for an audit,
a migration, or an incident. If you find yourself here for an ordinary commit, the project document is
missing or too thin — and *that* is the finding.

`SKILL.md` already carries the invariants that must hold without reading anything. This file is the
detail behind them.

---

### Find the repo's own rules first — then read them for precedence

Before the work, not after: the rules that govern this change are usually written down somewhere your
tool did not load. Run the search in `mode-a-investigate.md` step 1 — `.claude/`, `.agents/`,
nested `AGENTS.md`, `.cursorrules` — and **look inside the subtree you are about to edit**, not only at
the root. A monorepo commonly has a second agent document scoped to one component, and that one is the
binding one for work in it.

Watch for two kinds of instruction that only appear once you look:

- **Rules addressed to agents.** Repositories now write directly at us — *"if you are a coding agent,
  stop here and ask"*, *"don't fix golden-value drift by hand"*, *"STOP, name the prohibited category"*.
  Treat these as binding. They exist because a person decided this specific operation needs a human,
  and they are the clearest consent signal a repo can give.
- **Attribution and disclosure rules.** Some projects require an AI-assistance disclosure; others
  forbid AI credit in commits, PR bodies, or comments entirely. Both are real and they contradict each
  other, so read rather than assume.

**These govern conventions, not the invariants.** `SKILL.md` states the precedence: a project document
cannot authorize weakening a failing test or overwriting hand-authored judgement, whatever it says. It
also carries the rule for the case where the repo's rules contradict your own operating instructions —
surface the conflict, do not resolve it silently.

### Check the premise before you build

The request often describes a repo that is not the one in front of you. Roughly a third of the time
the premise is false or materially wrong: the feature already shipped, the API already carries the
field, the "broken" suite is 98% green, the documentation exists in four places already, the change
will not compile as described.

This is cheap to check and expensive to skip, because building it anyway is not merely wasted work.
Where migrations apply automatically at deploy time, a redundant "safe additive migration" fails
`migrate deploy` and leaves a failed row that blocks every subsequent deploy until someone clears it
by hand. The duplicate is the outage.

Before the first write, confirm three things and say what you found:

- **It does not already exist.** Search for the symbol, the column, the flag, the doc section.
- **The problem described is the problem present.** If you were told something is failing, observe it
  failing. If you cannot observe it, say so — that is a finding, not a licence to guess.
- **The change is possible as stated.** If it is not, prove it (a compiler error, a constraint in the
  schema) rather than asserting it, then propose the nearest thing that is.

If the premise is wrong, stop and report. That *is* the deliverable for that turn.

### Environments and production access

**The environment invariants are in `SKILL.md` → *Always true, in every mode*** — print where you are
pointed, production is read-only unless named this turn, ambiguous environment means stop, never print
or commit a secret. They are stated there rather than here because they must hold whether or not this
file was read. Do not restate them; they are not optional in any mode.

What this mode adds:

- **No ad-hoc writes against production.** Changes to production data go through a reviewed, reversible,
  re-runnable path, because that is the only version anyone can audit or undo. A correct one-off
  `UPDATE` is still the version nobody can review, repeat, or undo.

Read `production.md` §1 before any command that reads credentials, connects to a datastore,
or mutates deployed state.

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
- If the gate does not pass, say so with the output, not a summary of it.
- **If the gate cannot run at all** — no toolchain, no `node_modules`, no compiler — that is the
  common case, not a failure of yours. Say what is missing, never quote a neighbouring command's pass
  in its place, and see `evidence.md` → *When the project's gate cannot run* before
  building a substitute. The rule there in one line: a check you wrote must be proven able to fail
  before any green from it counts.

### Before calling anything merge-ready

**Green CI is necessary and routinely not sufficient.** Most established projects gate merges on
something no amount of code quality satisfies, and it is usually enforced by a bot that closes or
blocks the pull request without a human ever reading the diff:

- **An accepted issue or ticket**, in a particular state, sometimes explicitly *not* accepted by the
  person who filed it.
- **Prior consensus** on a mailing list or forum before a feature PR may be opened at all.
- **A named reviewer** who agreed in advance.
- **A changelog or release-note fragment**, often keyed to a PR number that does not exist until the
  PR is opened — so it genuinely cannot be written beforehand, and saying that is the honest answer.
- **A scope or product approval** distinct from technical review. One project states it directly:
  technical correctness, passing tests and green CI do not establish product approval.
- **A sign-off trailer** that is a legal attestation in someone's name — never yours to add for them.

Find these before you claim readiness, not after: `CONTRIBUTING`, the PR template, and the workflows
that run on `pull_request` and can close it. Then **say what is outstanding and whose it is.** "The
change is written and the suite passes; it cannot merge until a ticket is accepted, which is yours to
file" is a complete report. "Ready to merge" is not, and is the claim the project's own automation is
about to contradict.

### Before shipping

See `production.md` §3–§4. Before the change goes out, be able to answer: **how does it
reach production, what is the rollback, how will you know it worked, and what is the blast radius if it
is wrong?** If there is no rollback, say so explicitly — it changes how carefully this should ship.

Migrations are the sharpest edge: expand then contract across separate deploys, never destroy in the
same deploy that stops using the thing, test on realistic *size*, and know which operations lock.

### Before irreversible operations — stop and ask

**The rule, the shape to watch for, and the examples are in `SKILL.md` → *Always true, in every
mode*.** So are the two that most need blocking — never overwrite hand-authored judgement with machine
output, and never make a failing test pass by weakening it — because they apply during an audit and an
automation change too, not only here. Full catalog in `destructive-ops.md`.

What this mode adds is the scope of consent: **a generic "go ahead" on a task is not consent for an
irreversible operation.** Consent attaches to what was described. It does not extend to the next
instance, a wider blast radius, or a different environment — and the second time is exactly when it
feels like it should.

### Long or irreversible runs

See `long-runs.md`. Migrations, backfills, replays, batch jobs, and long test runs:

- **Never edit source that an in-flight run reads** — the run silently mixes two versions of the code.
- **Background it and tee to a file.** An interruption should cost the process, not the evidence.
- **Batch, bound, and make it resumable and idempotent** before starting anything that writes at scale.
  Assume it will be interrupted halfway, because eventually one will be.
- **A partial run is not a result** — and a partially-applied backfill is not a completed one. Say what
  actually ran, and how far it got.

### When production is broken

Read `production.md` §6. Stabilize before diagnosing; preserve evidence before restarting;
announce every change you make; one change at a time; say what you do not know. Afterwards, convert the
incident into a test, an alert, or a check — **the loop that is missing is why the issues recur.**

### Feeding the checklist

The checklist earns its keep between audits, not during them. When something teaches you a rule about
*this* repo — an incident, a near miss, a review comment you have now written twice, an assumption a
newcomer tripped over — **offer to add it as a check**, with the origin recorded. One line, in the
moment, while the cause is still known. See `checklist.md`.

The same applies in reverse: when a check becomes a CI job or a database constraint, mark it
`enforced` and stop asking about it by hand.

**If a learned check would make sense in a repo sharing none of this one's code, team, or stack**, say
so — it is a candidate for the skill's own seed list, where every project using the skill gets it.
Promoting is deliberate and needs sanitizing (`checklist.md`): the check travels, the
incident narrative does not. Promote sparingly; a check that fires everywhere and matters nowhere
costs attention on every audit. And a check the user declined is `retired`, not a finding
to re-raise at every audit.

### Reporting — claims and evidence

See `evidence.md`. Every status is a promise about evidence, and the next decision — merge,
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

