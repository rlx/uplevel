# Production: environments, shipping, and incidents

The commit is the cheap half. Most production damage happens after it — in a deploy, a migration, a
config change, or a command typed against the wrong environment. This file covers that half.

---

## 1. Know which environment you are pointed at

The most expensive backend mistake is a **correct command run against the wrong environment**. It does
not look like a mistake at any point: the command is valid, the output is normal, and the damage is
discovered later by someone else.

**Before any command that reads credentials, connects to a datastore, or mutates state, print where you
are pointed and say it out loud in your reply.** Not "I'll be careful" — the actual resolved value.

```sh
# Whatever this stack uses to resolve a target — run it, do not assume:
echo "${ENVIRONMENT:-unset} / ${NODE_ENV:-unset} / ${APP_ENV:-unset}"
echo "${DATABASE_URL%%\?*}" | sed -E 's#://[^@]*@#://***@#'   # host, credentials masked
kubectl config current-context 2>/dev/null
aws sts get-caller-identity --query 'Account' 2>/dev/null
gcloud config get-value project 2>/dev/null
docker context show 2>/dev/null
```

Rules that follow from this:

- **Production is read-only unless the user explicitly names production in this turn.** Approval to fix
  something is not approval to fix it *in production*.
- **Never run an ad-hoc write against production.** No `UPDATE`/`DELETE` from a console, no "quick"
  script. Changes to production data go through a reviewed, reversible, re-runnable path — a migration
  or a checked-in script — because that is the only version anyone can audit or undo.
- **A shell open on a production host is a hazard even when idle.** Say when you have one and close it.
- **Never copy production data to a local machine or a lower environment** without explicit
  authorization. It is usually the fastest way to turn a bug into a data-protection incident.
- If an environment is ambiguous — the variable is unset, the context is stale, two configs disagree —
  **stop and ask.** Guessing environments is never recoverable by being clever afterwards.

---

## 2. Secrets and sensitive data

- **Never print, log, echo, or paste a secret**, including into a commit message, a test fixture, or an
  error report. Mask when you must show a connection string.
- **Never commit a secret.** If one is already committed, treat it as compromised: it must be rotated,
  not just deleted — git history and every clone still hold it. Say so plainly; do not quietly remove
  the line and move on.
- Check that the repo has secret scanning before you rely on review to catch it (`references/automation.md`).
- **Do not add personal data to logs.** Emails, tokens, full request bodies, and identifiers end up in
  log aggregation, which is usually retained longer and read more widely than the database.
- New environment variables need to be added to the deployment config *and* to the example/`.env.sample`
  *and* documented, in the same change. A service that boots locally and crashes in production on a
  missing variable is the most avoidable outage there is.

---

## 3. Shipping a change

Establish these before writing code, not after:

- **How does this reach production?** Merge-triggered pipeline, manual deploy, tagged release?
- **What is the rollback?** If the answer is "roll forward with a fix," there is no rollback — say so
  explicitly, because it changes how carefully this should ship.
- **How will you know it worked?** Name the log line, metric, dashboard, or query you will look at
  *after* deploying. "The deploy succeeded" means the process started, not that the change works.
- **What is the blast radius if it is wrong?** All users, or one code path? Recoverable, or permanent?

Then:

1. **Ship to a lower environment first** and exercise the actual path — not just a health check.
2. **Prefer progressive exposure**: feature flag, canary, percentage rollout. A flag that can be turned
   off without a deploy is worth more than a fast pipeline.
3. **Watch after deploying.** Errors, latency, saturation, and the specific signal you named. A deploy
   you did not watch is a deploy someone else will discover.
4. **Deploy one change at a time** when it matters. Bundled deploys make attribution impossible exactly
   when you need it most.
5. **Do not deploy what you cannot watch** — end of day, before being away, during a freeze — unless it
   is fixing something already broken.

---

## 4. Schema and data migrations

A migration is code that runs once against data you cannot re-create. Treat it as the most dangerous
thing in the repo.

- **Expand, then contract.** Add the new column/table, write to both, backfill, switch reads, and only
  then remove the old one — as *separate deploys*. A single migration that renames or drops in one step
  breaks every instance still running the old code during the rollout.
- **Never destroy in the same deploy that stops using it.** Leave the old shape in place long enough to
  roll back into.
- **Every migration needs a tested down path**, or an explicit written statement that it is one-way.
- **Test it on a realistic copy** — realistic in size, not just in shape. Migrations that pass on 100
  rows lock a table for 40 minutes on 100 million.
- **Long-running migrations and backfills**: batch them, make them resumable and idempotent, bound each
  batch, and log progress. See `long-runs.md`.
- **Locks are the outage.** Know which operations take an exclusive lock in this engine and for how
  long. Add indexes concurrently where the engine supports it.
- **Back up before anything destructive, and verify the backup is restorable.** An unverified backup is
  a belief, not a backup.

---

## 5. Making the system supportable

Changes that touch production should leave it easier to operate, not harder:

- **Errors must be actionable**: what failed, for which entity, and what the caller should do. An error
  that reaches on-call as `Error: failed` costs an hour of someone's night.
- **Log at boundaries** — inbound request, outbound call, job start/end — with a correlation id, so a
  failure can be traced across services. Not inside loops.
- **Every outbound call needs a timeout**, and a retry policy that is bounded and jittered. Unbounded
  retries turn a slow dependency into an outage.
- **Make write paths idempotent** where a client could reasonably retry. Exactly-once delivery does not
  exist; idempotent handling is the substitute.
- **Bound everything that can grow**: queries without `LIMIT`, unpaginated endpoints, unbounded queues
  and in-memory caches. These are fine until the day the data grows, and then they are an outage.
- **Alert on symptoms users feel** (error rate, latency, queue age), not on causes (CPU). An alert
  nobody acts on should be deleted — a noisy alert trains people to ignore the real one.

---

## 6. When production is already broken

Different rules apply. The goal is to stop the bleeding, not to write good code.

1. **Stabilize first.** Roll back, disable the flag, scale out, shed load. Do not debug forward while
   users are affected, and do not refactor anything.
2. **Preserve the evidence** before restarting or clearing: logs, a stack trace, the failing payload,
   queue depths, the current config. A restart that fixes the symptom usually destroys the cause.
3. **Announce what you changed, when, and what you expect it to do** — during an incident, an
   unannounced change is indistinguishable from a second failure.
4. **One change at a time**, and check the effect before the next. Parallel fixes make it impossible to
   know which one worked.
5. **Say what you do not know.** "The error rate dropped after the rollback; I have not confirmed the
   cause" is an honest and useful status. "Fixed" is not, unless it is.
6. **Never fix a symptom by widening access, disabling a check, or deleting data** unless the user
   explicitly decides to — and record it as debt in the same breath.

**Afterwards — this is the part that compounds.** Every incident is a rule that did not exist. Convert
it: a test that reproduces it, an alert that would have caught it sooner, a check in the gate, or a
line in `CLAUDE.md`. A team with recurring production issues usually has plenty of postmortems and no
enforcement derived from them. Closing that loop is worth more than any new tooling.
