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
- **Costly but reversible** (a behavior change behind a flag) — run the specific test; quote it.
- **Expensive or irreversible** (migration, deploy, data change, a security control) — verify through
  the path production takes, on realistic data, and state what you could *not* cover. Proportionality
  cuts both ways: over-verifying trivia is how a rule stops being followed.

## Green, and proving nothing

The most common bad evidence is not a lie. It is a check that ran, passed, and established nothing.
Look for these before quoting a pass:

- **Silently skipped.** The suite needed a database, a key, or a container, did not have it, and
  reported success on what remained. Check the *count*, not the exit code — and compare it to last time.
- **The runner's target list is not the set of tests.** `ninja test`, `bazel test`, `go test ./...`
  report on what the build system was *told about*, and tests sit on both sides of that line. A test
  source with no target never runs and never appears in the count. An in-source harness — a
  constructor function, an `#ifdef TEST` block, a doctest — runs on every binary start and is never a
  target at all. Before writing that a file is untested, diff the test sources on disk against the
  registered targets, and grep the source for the project's own test macro. Both directions have been
  observed: two test files with no build entry, so the backend they covered had never run; and 42 unit
  tests firing from a constructor macro that `ninja test` never mentions, which an audit reading only
  the target list called untested code.
- **Not covering the change.** Passing tests that never execute the modified lines.
- **A stale artifact.** You tested a cached build, an old container, a previous binary. If a version
  marker or build tag exists, confirm it matches what you just built; if one does not exist, that
  absence is itself worth reporting.
- **A different configuration than the one that ships.** Not stale — fresh, and the wrong thing. The
  gate builds and tests `Debug` while the package, the image or the store upload is `Release`:
  different optimizer, different `#if` branches, different minification, and on Android a whole
  shrinker pass whose keep rules nobody exercises. Three repositories in one round — a .NET library
  whose CI ran `-c Debug` while its nuspec packaged `bin\Release\`; a C++ service whose CI set
  `CMAKE_BUILD_TYPE=Debug` while its Dockerfile set `Release`; an Android app whose CI ran only
  `assembleVanillaDebug`, its shrinker config still keeping a package deleted long ago, which is what
  proved the release build had not run in a long time. Compare the configuration the gate builds
  against the one the release job packages, and say so when they differ.
- **Would have passed anyway.** A regression test that never saw red proves the suite runs, not that
  the bug is caught. Revert the fix, watch it fail, restore it, watch it pass.
- **Wrong environment.** Correct command, different target.
- **Re-run until green.** If it failed once and passed on the third attempt with no change in between,
  the finding is *flaky*, not *passing*. Sampling until you like the answer is not verification, and
  reporting the third run alone is how intermittent bugs become invisible ones.

## Red, and meaning nothing

The mirror of the section above, and the one that inflates audit findings rather than hiding them. A
failed run is not a finding until you have **read the step that failed**. Several things go red
without saying anything about the repository:

- **The checkout never happened.** A deleted or renamed repo, a revoked token, a submodule the runner
  cannot reach. The gate did not run; there is no result to report either way.
- **Infrastructure.** A runner died, the registry timed out, a network fetch failed. Re-running is the
  diagnosis, not a workaround.
- **Superseded.** A `canceled` run is usually the concurrency group doing its job when a newer commit
  arrived. Counting cancellations as failures makes a healthy repo look broken.
- **A different job than the one you mean.** A "CI is 30% red" figure computed across every workflow
  can be dominated by one always-failing nightly, or diluted by a trigger job that structurally cannot
  fail. Compute the rate over the jobs that actually gate a merge, and say which those are.
- **Stale.** A red run from before the fix, still the newest on that branch because nothing has pushed
  since.

**A failure rate is a number the team will be asked to react to**, so being wrong in the alarming
direction costs the room in the first minute. Before quoting one: name the workflow and job, open at
least the most recent failure and the oldest, and say what the failing step was. If the answer is
"checkout" or "runner", it belongs in a footnote about CI reliability, not in a finding about the
repository's engineering process.

## When the project's gate cannot run

Expect this rather than treating it as a surprise: `discovery.md` §*Toolchain preflight* is where you
find out which case you are in, and it is ordinary for the answer to be that you cannot run it.
Everything below is what to do once you know.

**First, say so plainly and name what is missing.** `— unverified, needs uv 0.11.26` is a complete,
professional report. Never substitute a neighboring command and quote its pass as if it were the
gate: `go build` succeeding is not the test suite, and `node --check` is not a type-check.

**Then you may build a substitute — under one condition: prove it can fail.** A checker you wrote
yourself has no track record, and the failure mode is specific and seductive: it passes, you relay the
pass, and it was never capable of anything else. So break something on purpose and watch it go red
before you trust a single green from it. Revert the source line and see the check fail; feed it a
mutant; assert a value you know is wrong. Then restore, re-run, and quote both states.

**If you cannot make it fail, discard it.** A substitute that stays green on deliberately broken
input is not weak evidence, it is none — and reporting it is worse than reporting nothing, because it
reads as a pass. Throwing it away is the correct outcome. Say you discarded it and why; that sentence
is itself worth more than the check would have been.

**Know what the substitute does and does not attribute to.** It typically exercises your change
against a *different* runtime than production uses — Node's resolver rather than the bundler's, a
hand-rolled harness rather than the project's test framework, one dialect of three. Name that gap in
the same breath. And stop before it becomes fiction: stubbing one absent library to get red/green is
a shim, but stubbing a second and then a third is fabricating an environment, and any green past that
point proves nothing about the real one.

**Always name the command that would settle it**, exactly as someone with a working toolchain would
run it. That single line is what converts your "unverified" from a dead end into the next step.

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
