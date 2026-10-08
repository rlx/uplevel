# What good output looks like

**This is a format example, not a finding.** It is modeled on a real audit run by an agent with no
prior context, with the subject repository and its details generalized away. Read it for shape and
tone; the findings belong to the repository in front of you, never to this page.

**Every figure in it is frozen at the moment it was written** — tool versions, coverage, run counts,
revert rates. They are here to show what a verified number looks like once it reaches a report, and
they are stale by construction. Yours come from the repository you are auditing, on the day you audit
it.

The shape: findings before recommendations, their numbers rather than your standards, absences named
with the right word, uncertainty marked, deliberate design recognized as such, and a plan short enough
to be acted on.

---

## Report

**Security: nothing urgent.** What I checked, and what I could not, is under *Could not verify*.

**The premise needs correcting.** The request said the process "isn't written down anywhere." Most of
it is — this repo has a mature, genuinely enforced process. What is *not* written down is the one
command a contributor needs, and it is hiding inside a CI file.

**Toolchain preflight.** The declared version, pinned in two files, resolved **in the repository
directory** to the same minor one patch ahead — **satisfied**. The gate is runnable here, so the
commands below were actually run. *Name the files that declared it and the version that resolved;
both are specific to the day you ran it.*

**The gate as it exists.** `.github/workflows/checks.yml`, on `pull_request` and `push`: Unit Tests,
Race Tests, End-to-end Tests, Code Consistency Checks. What I ran and observed:

- the build, whole tree → **exit 0**, about a minute
- a two-package test subset with coverage → **ok**, seconds, coverage reported per package
- the formatter in check mode → clean apart from a fixtures directory the tool ignores anyway. Not a
  defect.
- the full test suite — **not run, unverified.** Tens of minutes on this machine; I judged the cost
  not worth it for an audit, and I will not report a runtime I did not observe.

*In a real report each line is the literal command and the literal number it printed.*

**What validates a change before `main`.** One ruleset at `enforcement: active`, requiring all four
check suites plus the contributor-agreement check, with `current_user_can_bypass: never`. An org
ruleset adds a required PR, one approving review and code-owner review.

**Their own numbers, as of the day of the audit.** 0 of the last 40 merged pull requests merged
without an approving review. The fast check suite green on every run on `main` over the preceding
week. **Subject-line reverts in the last 1000 commits: well under one percent.** This is not a repo
that keeps breaking things through process failure. *State the window with the number — a rate with no
window is not a finding, and the window is what tells a later reader the figure has expired.*

### Findings

**1. The local gate exists as exactly one line, in a CI file, and no contributor doc names it.**
A single line deep in a workflow file runs an eight-target build command, and the suite it belongs to
is a **required** status check. I grepped every contributor-facing document in the repository: none of
those target names appears in any of them. The single check most likely to bounce a pull request is
transcribed nowhere a human would look. *In a real report, cite the file and line — that is what makes
the finding checkable.*

**2. The `fmtcheck` target is not a check — it rewrites your working tree.** Line 8 of the script it
calls invokes the language's *format* command rather than its *check* command, and that command writes
in place. In CI this is harmless on an ephemeral checkout, which is exactly why it has survived.
*Evidence, from reading the file — I did not run it, because it would modify the clone.*

**3. Two rules that look enforced and are not.** Two further rulesets are both
`enforcement: evaluate` — they log and never block. One is redundant with an active org ruleset; the
other asserts that only core team members may create version branches, and **no active ruleset enforces
that**.

**Absences — present / absent / unsupported here / unknown**

**Present (5)** — verified: CI on pull requests, required status checks, required review (all three via
the rulesets API), actions pinned to SHA (every reference, across every distinct action, zero mutable
tags — count both), and `SECURITY.md` **via the org** — checked before calling it missing.

Rows only for what needs a decision:

| | |
|---|---|
| `timeout-minutes` | **absent** — every job, every workflow |
| Local gate command in any contributor doc | **absent** — finding 1 |
| Repo Actions permissions policy | **unknown** — 403 at READ. *Not* "disabled" |
| Legacy branch protection | **unknown** — 404, which is ambiguous by design |

---

## Plan

**1. Make `make fmtcheck` actually check.**
prevents: a target named "check" silently rewriting a contributor's working tree · if skipped: item 2
tells people to run a command that edits their files
effort: 15 min, incl. review · affects: everyone who commits
undo: `git revert` — one line · needs: —

Swap the formatting command for the check-only form of the same tool. CI behavior unchanged; local
behavior stops being destructive. Promoted above item 2, which has the larger effect, because it is
cheap, safe, and item 2 is unsafe without it.

**2. Write the local pre-PR gate down.**
prevents: contributors discovering the required check only when CI bounces the PR · if skipped: every
newcomer reads a workflow file to find out how to test, or doesn't
effort: 1–2 h, mostly review of the wording · affects: everyone who commits
undo: `git revert` — it is a doc · needs: 1

Copy the exact line out of the workflow file into `CONTRIBUTING.md`, beside the test guidance already
there, noting which of its targets rewrite the tree.

**3. Add `timeout-minutes` to both workflow files.**
prevents: a hung job holding a runner for the six-hour default · if skipped: occasional silent capacity
loss, visible as "pending" rather than "failed"
effort: 30 min, incl. picking the value from run history · affects: everyone who merges
undo: `git revert` · needs: —

Set it above the observed p95, read from this repo's own run history rather than from a default.

**4. Resolve the two `evaluate`-mode rulesets.**
prevents: a rule that reads as enforced and blocks nothing · if skipped: the "only core team may create
version branches" rule stays decorative, and a reader believes it
effort: 30 min to decide, plus a maintainer's judgment — **their decision, not mine**
affects: everyone who merges · undo: set `enforcement` back · needs: —

Promote or delete. As written, one of them is a name, not a rule.

**If only one:** item 1. Fifteen minutes, and it makes item 2 safe to act on.

**Not proposed:** a `CLAUDE.md` — `CONTRIBUTING.md` already fills the role and is good; a second
document would compete with it. Also not proposed: SBOM, chaos testing, coverage gates — all
worthwhile, none of them this repo's binding constraint.

**Could not verify:** the full test suite (cost); the code-generation targets (they write to the
tree); the release pipeline (lives in another repository, driven by an internal tool). Repo Actions
policy and legacy branch protection — permission-limited, **unknown, not absent**.
