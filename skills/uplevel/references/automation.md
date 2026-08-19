# Turning rules into checks

A rule in a document is enforced by whoever remembers it. A rule in CI is enforced by everyone,
forever, including the person onboarding next month and the agent working at 2am. **Every rule worth
writing down is a candidate for deletion from the document and promotion into a check.**

For a team with recurring production issues, this is the highest-leverage work in the whole skill.
Documentation is where process goes when nobody has time to automate it.

## The ladder — prefer the highest rung that fits

1. **Make it impossible.** Types, constraints, a database `NOT NULL`, a required argument, removing the
   dangerous flag. No check needed if the mistake cannot be expressed.
2. **Fail at build/CI time.** Deterministic, blocking, runs on every change.
3. **Fail at commit time** (hook). Fast feedback, but locally bypassable — a hook is a convenience, and
   CI is the enforcement. Never rely on a hook alone.
4. **Fail at deploy time.** Migration checks, config validation, smoke tests, health gates.
5. **Alert at runtime.** For what cannot be caught earlier.
6. **Write it in the document.** Only for what genuinely needs human judgment.

Moving a rule up a rung is a real improvement. Say so when you do it, and delete the prose it replaces.

## What to automate first

Order by *damage prevented per hour of setup*. For a service with production issues, this is usually:

1. **Secret scanning** on every commit and in history. Cheap; the failure mode is unbounded.
2. **A single command that runs the whole gate** (`make check` / `just check` / `npm run check`) — the
   same one CI runs. If humans and CI run different things, the gap is where bugs live.
3. **Branch protection**: no direct pushes to the default branch, required status checks, required
   review. This is configuration, not code, and it prevents the failure the whole branching rule exists
   to prevent.
4. **Dependency and vulnerability audit** in CI, with a documented policy for what blocks.
5. **Migration safety check** — reject unsafe DDL (renames/drops, missing concurrent index, table
   rewrites) in review rather than at 3am.
6. **A deploy smoke test** that exercises one real path and fails the deploy, not just a health check
   that proves the process started.
7. **Config/env validation at boot** — fail fast and loudly on a missing or malformed variable rather
   than at first use, in the request path, in production.
8. **Test coverage of the incident**: for each recent production issue, a test that reproduces it.

**A forge setting often outranks the hook someone was about to write.** The clearest case is commit
text: a `commit-msg` hook is rung 3 and bypassable, while a squash-merge setting that writes only the
pull request title is rung 1 — the long body cannot reach the default branch at all. Check what the
merge actually publishes before building anything to police what precedes it. See
`commit-hygiene.md`.

## Automation changes other people's day — get consent

A check is a policy, not a patch. Before adding or tightening one in a repo you do not own:

- **Branch protection, required status checks, and repo/org settings are never yours to change.**
  They can block every teammate's merge and are usually governed by a team decision. Propose them —
  in writing, with what they prevent — and let a maintainer apply them.
- **Commit hooks run on other people's machines.** A slow or noisy hook is experienced as your bug.
  Prefer CI, which is opt-out-able by nobody but breaks nobody's local loop.
- **CI costs money and minutes.** Say what a new job adds to every run before adding it.
- **A new blocking check will fail somebody's in-flight branch.** Say so, and offer the staged path:
  advisory *with an agreed date* to become blocking, or blocking only on changed files. That is
  different from a permanently-advisory check, which is the thing to avoid.
- **Land one check at a time**, each in its own reviewable change with its rationale. A pull request
  that adds nine checks at once gets closed, and deservedly.

## Rules for the checks you add

- **Fast, or it gets bypassed.** Split fast (seconds, every commit) from slow (integration, nightly).
  A gate over ~10 minutes stops being run locally, and then stops being trusted.
- **Fail with the fix, not just the failure.** `Missing timeout on outbound call at src/x.ts:42 — add
  { timeout: 5000 }` beats `lint error`. The message is the documentation people actually read.
- **No new check may be *permanently* advisory.** A warning that never blocks gets ignored within a
  week, and its presence makes people think the problem is handled. Either it blocks, or it has an
  agreed date on which it starts blocking. "We'll turn it on later" without a date means never.
- **Zero baseline noise.** If it fires on existing code, either fix that code first or explicitly
  baseline it — a check that is already red teaches everyone to ignore red.
- **Add the check in the same change as the fix it enforces**, so the check is proven to catch it.
  Verify it fails before you make it pass.
- **Make sure it cannot match itself.** A check that searches the tree is *in* the tree, so its own
  pattern list, its test fixtures, and the commit that adds it are all inside the search scope. The
  failure is loud and embarrassing rather than silent: the gate goes red for a defect it invented,
  and whoever inherits it deletes it. Keep the patterns in a data file outside the scanned set, or
  exclude the checker's own path — then confirm a clean tree stays clean *before* trusting the first
  failure it reports.
- **Verify the skip path too, not just red and green.** A check that degrades — skipping when an
  interpreter, a library, or a credential is missing — has three outcomes, and the third is the one
  nobody exercises. Run it with the dependency absent and confirm it skips loudly and exits zero,
  rather than erroring, hanging, or reporting a pass. An unexercised skip is how a check becomes
  vacuous on exactly the machines that needed it most, and it will read as green.
- **Prove it on the case that motivated it, not a case you invented.** "Verify it fails before you
  make it pass" is necessary and not sufficient: a synthetic failure proves the check fires on
  *something*. If the check exists because of a specific escape — a bug that shipped, a rule that got
  skipped — reconstruct *that* input and confirm it goes red. A check keyed on a convenient proxy
  passes its synthetic test and misses the real thing: one written to catch new checks keyed on
  section headings, went red on a synthetic new section, and then silently ignored a real check added
  inside an existing one. The synthetic test was green the whole time.
- **Loosening a check is where coverage disappears; re-prove the original case.** Tightening is safe
  and self-announcing — it goes red and someone looks. Loosening to silence a false positive quietly
  removes coverage, and nothing goes red to tell you. Every time you narrow a pattern or add an
  exclusion, re-run the failure the check was built for and confirm it still fires. Do it in the same
  change, and say in the pull request that you did.
- **Measure the gate, not the check.** Each addition looks cheap alone and the budget is shared. Time
  the whole gate before and after; a check that adds three seconds to a one-second gate has
  quadrupled it, however reasonable it looked in isolation. Then **update whatever documents the
  runtime** — a contributor guide claiming "well under a second" for a gate that now takes five is
  wrong in the file people read to learn the process.
- **Make it runnable locally** with the exact command CI uses. "Push and wait for CI" is not a
  development loop.

## Discovering what is already automated

For the full absence checklist — CI triggers, Actions supply chain, branch protection, release gates —
see `forge-hygiene.md`. The quick pass:

Read before adding — most repos have more than they use:

```sh
ls .github/workflows .gitlab-ci.yml .circleci Jenkinsfile 2>/dev/null
cat .pre-commit-config.yaml .husky/* lefthook.yml 2>/dev/null
gh api repos/:owner/:repo/rulesets --jq '.[]|{name,enforcement}'  # rulesets first: readable at READ
gh run list --limit 20                                            # what actually passes, and how often
```

All read-only. Keep it that way: inspect settings, never write them.

**If discovery turns up an exposed secret or a live vulnerability, tell the user directly and
privately.** Do not put it in the document, a commit message, a PR description, or anything published.
A committed secret is compromised and must be rotated — deleting the line does not undo it.

Then ask the two questions that matter:

- **What is red or flaky right now?** A perpetually-failing job is worse than no job: it trains the
  team to merge past red. Fixing or deleting it comes before adding anything new.
- **What is defined but not required?** A workflow that runs and never blocks a merge is decoration.
  Check branch protection, not just the workflow file.

## When you cannot automate it

Some rules need judgment — "confirm the environment", "do not deploy what you cannot watch". Those
stay in `CLAUDE.md`. But be honest about which is which: if a rule *could* be a check and is written as
prose because writing prose is faster, say so and offer to build the check. Then the choice is the
user's, made knowingly.
