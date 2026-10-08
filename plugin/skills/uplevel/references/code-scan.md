# The security read — yours to do

Read this before check-in on a change that touches code, and during a full audit of a repository
where no model reads pull requests for security problems.

**This file is newer than the rest.** Its first blind audits traced a fetch to a caller-chosen address
and a credential sent to a caller-named host; that is too few to know what it misses. Follow it, and
report where it was wrong or thin.

**Why this is yours.** A forge can run a model over every pull request to look for the security
problems pattern-based scanning does not cover. It is billed each time it runs, and
`forge-hygiene.md` §1b recommends leaving it off. That leaves the read undone unless someone does it
— and you are already here, with the change loaded and the repository's conventions in context. Do it
as part of the run, and say that you did.

**It does not replace a scanner.** Deterministic scanning — the forge's default code scanning, a
workflow analyzer — finds what it finds on every change, for nothing on a public repository, and
without anyone remembering. Propose those through `automation.md`. This read covers what they do not:
logic that is wrong for this codebase rather than wrong in general.

---

## Scope it to the change

In Mode C the scope is the diff, and nothing wider:

```sh
default=$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')
git diff --name-only "origin/$default...HEAD"    # what the branch changed
git diff --name-only HEAD                        # plus what is not committed yet
```

If the first line prints nothing the clone has no record of the remote's default branch; ask the
forge for it, or ask the user, before diffing against a guess.

In Mode A there is no diff. Bound the read to where untrusted input arrives — request handlers,
message consumers, file and archive parsers, anything a workflow interpolates from an event — and
**name what you read**. A whole-repository security review is a different engagement; offer it, do
not imply it.

## What to look for

Read the changed code *and what calls it*. The finding is rarely on the changed line.

- **A check its siblings have and it does not.** A new route, handler or job with no authentication
  or authorization where every neighbor has one. Compare against the neighbors, not against a
  standard.
- **Input reaching an interpreter.** A shell, a query, a template, an `eval`, a deserializer, a path
  joined from a parameter. Trace it from where it enters to where it is used.
- **A request to an address the caller chose.** A URL, host or webhook target taken from input and
  fetched from inside the network.
- **A safe default switched off.** Certificate verification disabled, debug mode on, a wildcard
  origin with credentials, a permission widened to make a test pass.
- **Something trusted that was never verified.** A download, an update or a plugin executed without
  a signature or digest check; a token compared with an ordinary equality.
- **An event field interpolated into a workflow's `run:` step.** The title of a pull request is
  attacker-controlled text.
- **A secret.** Its presence is the finding. `SKILL.md` already says never to read or print the value.

## What makes it a finding

- **A match is a lead; a trace is a finding.** Name the file and line, the input, and the path from
  one to the other. If you cannot draw the path, report it as unverified and say what would settle
  it. This is the count-then-confirm rule from `mode-a-investigate.md`, applied to code.
- **Never prove it against something deployed.** Reproduce locally if it is cheap and touches
  nothing shared. Otherwise the trace is the evidence.
- **Raise it first, and privately.** A real finding goes in the first paragraph of your reply, to the
  user — never in a commit message, a pull request body, the process document, or anything published.
- **Fix only what is yours.** A problem in the change you are making, you fix and say so. A problem
  in code you did not touch is reported and left: the posture is advisory here as everywhere.

## How to report it

A read by a model is not a scan. It is not repeatable, it has no coverage guarantee, and two runs
over one diff will not notice the same things. So the report says exactly what was done:

- **The scope**: which files, and that the rest were not read.
- **The word**: use `evidence.md`. "I read these six files and found nothing" is a complete report.
  "The change is secure" is a claim no read supports — it is a negative claim, and those need a
  search you did not run.
- **Whose word it is.** If the harness you are running in offers its own security review of pending
  changes, run it as well and report its output as a report from another agent, not as your evidence.
