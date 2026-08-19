# Mode C — enforce during ordinary work

Read this when work is already underway in a repo whose rules are known: before a check-in, before a
deploy or migration, during an incident, or when a long run is about to start.

**Most of this belongs in the repo's own `CLAUDE.md`, not here.** A project document costs a few
hundred tokens and is specific to the repo; loading the skill for a routine commit costs far more and
says less. If you find yourself here for an ordinary commit, the project document is missing or too
thin — and *that* is the finding.

`SKILL.md` already carries the invariants that must hold without reading anything. This file is the
detail behind them.

---

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

