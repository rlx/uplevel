# Long runs, interruptions, and comparability

Applies to anything that takes long enough to be interrupted, or that produces a number you will act
on: migrations, backfills, replays, batch and cron jobs, long test suites, benchmarks, crawls, large
refactors.

**Two different risks.** A long *read* (a test suite, a benchmark) risks producing a number you cannot
trust. A long *write* (a migration, a backfill, a replay) risks leaving the system in a state no code
expects — half-migrated, partly backfilled, some rows new-shape and some old. The second is the one
that pages someone.

## Before starting

- **Clean tree, or a known tree.** Record the commit. A result that cannot be attributed to a revision
  is not a result.
- **Pin everything random**: seed, input list, sample, model/dependency version, date window. Two runs
  that sampled differently cannot be compared, and the difference will be read as your change.
- **Run it in the background and tee to a file** under a scratch directory. An interruption should cost
  the process, not the evidence.
- **Decide the metric first.** Choosing which number to quote after seeing the numbers is how a null
  result becomes a claimed win.

## While running

- **Never edit source that the run reads.** Harnesses that rebuild or re-import per item will silently
  mix two versions of the code. Finish or kill the run first. This is the single most common way a
  measurement is quietly invalidated.
- Do not start a second run competing for the same resource (port, database, test schema, rate
  limit, CI runner)
  unless you have confirmed it is isolated.
- Leave the working tree alone generally — a git operation mid-run can change files under it.

## After

- **A partial run is not a result.** Interrupted, killed, timed out, rate-limited, or crashed partway:
  say so and re-run. Never present the completed subset as the whole, and never silently drop failed
  items from a denominator.
- **Quote the log file, not scrollback.** Scrollback is lossy and gets truncated.
- **Know the noise floor before claiming a win.** If you have not measured run-to-run variance on
  identical code, you cannot tell a real improvement from noise. Re-run the baseline; a difference
  inside the spread is not a result. Sources of noise: network, cache warmth, machine load, noisy
  neighbors,
  non-determinism in the system under test.
- **Compare pairs, not totals.** A new failure appearing in a re-run is not automatically a regression,
  and an equal count is not evidence of no change. Diff the item-level results.
- **Attribute honestly.** Say what is measured effect and what could be noise, environment, or a
  changed input set.

## Long writes: migrations, backfills, replays

Assume it will be interrupted halfway, because eventually one will be.

- **Batch it.** Bounded chunks with a committed checkpoint after each, so a kill costs one batch.
- **Make it idempotent.** Re-running the whole thing must be safe; that is what someone will do when
  they cannot tell how far it got.
- **Make it resumable**, and record progress somewhere durable — a cursor table, not a log line.
- **Bound the blast radius per batch**: a `LIMIT`, a rate limit, a sleep between batches. A backfill
  that saturates the database is an outage caused by a maintenance task.
- **Dry-run first** and print what *would* change, with counts. Compare the count against what you
  expected before running for real.
- **Know how to stop it** without corrupting state, and say so before starting.
- **Watch the system while it runs**, not just the job: replication lag, lock waits, error rate,
  queue depth. The job succeeding while the service degrades is the common failure.
- **Never start one you will not be present for**, unless it is designed to be abandoned safely.

## Resumability

For anything expensive, prefer a harness that writes per-item results incrementally so an interrupted
run can resume or at least be salvaged. If you are about to run something expensive that has no such
checkpointing, say so up front — that is a design decision the user should make, not a surprise after
an hour is lost.
