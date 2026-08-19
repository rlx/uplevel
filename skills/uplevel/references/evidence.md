# Claims and evidence

Every status you give is a promise about evidence: that you checked, that the check was capable of
failing, and that it was about the thing you are describing. Broken promises here are expensive out of
proportion to their size, because the next decision — merge, deploy, close the ticket, stop looking —
is made on your word and nobody re-derives it.

*Prior art: `obra/superpowers` has a `verification-before-completion` skill built on the rule "no
completion claims without fresh verification evidence", and its red-green regression cycle and
check-the-agent's-diff pattern are both kept below. This file departs from it in one way, deliberately:
an absolute rule with no exceptions has no answer for work that genuinely cannot be verified here, and
a rule people cannot follow gets dropped rather than followed. Calibration is the alternative to
silence.*

---

## Three properties, or it isn't evidence

**Fresh** — it postdates your last change to anything it depends on: source, config, dependencies,
generated files, fixtures. The classic loss is verifying, then making one last small fix.

**Attributed** — it exercised *the thing you are claiming about*. A green suite that never touches the
changed code says something true about the repo and nothing about your change.

**Falsifiable** — it could have failed, and you know what failure would have looked like. If you cannot
describe the failing output, you did not run a check; you performed one.

Miss any of the three and what you have is an observation. Observations are worth reporting — as
observations.

## The words to use

Pick the strongest one your evidence actually supports, and say the next one down out loud rather than
rounding up.

| word | what it commits you to |
|---|---|
| **Verified** | I ran it after the last edit, it exercises the change, and it could have failed. The command and its result are in my reply. |
| **Partially verified** | This much passed; *this* was not exercised. Both halves stated. |
| **Unverified** | I changed it and did not check it. Here is the command that would settle it. |
| **Assumed** | I am relying on something I did not check — name it, so someone else can challenge it. |
| **Contradicted** | The evidence disagrees with what I expected. Reported as-is, before I go looking for a reason. |

**"Unverified" is a professional report. A false "done" is not.** Saying *"the migration is written and
tested against an empty database; I have not run it against realistic data, which is where lock
duration would show"* is more useful than either a confident "done" or an anxious silence. The failure
mode this file exists to prevent is not uncertainty — it is uncertainty that has been rounded up.

## Scale the evidence to the cost of being wrong

Identical ceremony for a typo and a schema change gets the ceremony dropped for both. Ask what happens
if the claim is false:

- **Cheap and instantly visible** (a rename, a comment) — the check *is* the compiler; say so briefly.
- **Costly but reversible** (a behaviour change behind a flag) — run the specific test; quote it.
- **Expensive or irreversible** (migration, deploy, data change, a security control) — verify through
  the path production takes, on realistic data, and state what you could *not* cover. Proportionality
  cuts both ways: over-verifying trivia is how a rule stops being followed.

## Green, and proving nothing

The most common bad evidence is not a lie. It is a check that ran, passed, and established nothing.
Look for these before quoting a pass:

- **Silently skipped.** The suite needed a database, a key, or a container, did not have it, and
  reported success on what remained. Check the *count*, not the exit code — and compare it to last time.
- **Not covering the change.** Passing tests that never execute the modified lines.
- **A stale artifact.** You tested a cached build, an old container, a previous binary. If a version
  marker or build tag exists, confirm it matches what you just built; if one does not exist, that
  absence is itself worth reporting.
- **Would have passed anyway.** A regression test that never saw red proves the suite runs, not that
  the bug is caught. Revert the fix, watch it fail, restore it, watch it pass.
- **Wrong environment.** Correct command, different target.
- **Re-run until green.** If it failed once and passed on the third attempt with no change in between,
  the finding is *flaky*, not *passing*. Sampling until you like the answer is not verification, and
  reporting the third run alone is how intermittent bugs become invisible ones.

## Negative claims need a search

"Nothing else uses this", "that was the only call site", "no other callers are affected", "this is
fully removed" — these are the claims most often wrong and least often checked, and no test output
supports them. Memory does not count. **The search is the evidence**: run it, quote it, and state its
blind spots — dynamic dispatch, reflection, string-built identifiers, other repositories, generated
code, a database or config referencing the name.

## Claims made by other people, and by other agents

A subagent, a CI badge, a tool's summary, and a teammate's "should be fine" are all *reports*, not
evidence. Check the artifact: the diff, the log, the actual file. Report what you found, not what you
were told — and say which it was, because "the tests pass" and "CI says the tests pass" fail
differently.

## This applies to durable text too

Commit messages, pull request descriptions, changelogs, status documents, and anything published
outlive the conversation and are read by people who cannot ask you a follow-up question. Apply the
same vocabulary there, and prefer the sentence that would still be defensible if someone re-ran your
commands next month.

## Before you type a completion word

Done, fixed, passing, works, ready, complete, verified — and every synonym and implication.

1. **What claim am I making?** State it as a sentence someone could check.
2. **What would settle it?** Name the command, the query, or the observation.
3. **Did I run that, after my last edit?** If no: run it, or downgrade the word.
4. **Could it have failed, and did it touch my change?** If no: it is not evidence yet.
5. **What is still uncovered?** Say that part in the same breath as the good news.
