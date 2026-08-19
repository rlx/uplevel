# What good output looks like

One worked example, drawn from a real audit by an agent with no prior context, trimmed to the parts
that teach the shape and with identifying details removed. Every claim in the original was verified
against the file or API response it rested on. **Read this for shape and tone**, never as a finding to
reuse — the point is the form, and the findings belong to the repository in front of you.

The shape: findings before recommendations, their numbers rather than your standards, absences named
with the right word, uncertainty marked, deliberate design recognised as such, and a plan short enough
to be acted on.

---

## Report

**Security: nothing urgent.** What I checked, and what I could not, is under *Could not verify*.

**The premise needs correcting.** The request said the process "isn't written down anywhere." Most of
it is — this repo has a mature, genuinely enforced process. What is *not* written down is the one
command a contributor needs, and it is hiding inside a CI file.

**Toolchain preflight.** Declared `1.26.4` (`.go-version`, `go.mod`); resolved `go1.26.6` **in the
repository directory** — same minor, patch ahead, **satisfied**. The gate is runnable here, so the
commands below were actually run.

**The gate as it exists.** `.github/workflows/checks.yml`, on `pull_request` and `push`: Unit Tests,
Race Tests, End-to-end Tests, Code Consistency Checks. What I ran and observed:

- `go build ./...` → **exit 0, 69s** (whole tree, both modules)
- `go test -cover ./internal/addrs/... ./internal/tfdiags/...` → **ok, 2.6s**, 54.6% / 69.8%
- `gofmt -l .` → clean apart from a `testdata/` file the Go tool ignores anyway. Not a defect.
- Full `go test ./...` — **not run, unverified.** Tens of minutes on this machine; I judged the cost
  not worth it for an audit, and I will not report a runtime I did not observe.

**What validates a change before `main`.** One ruleset at `enforcement: active`, requiring all four
check suites plus the contributor-agreement check, with `current_user_can_bypass: never`. An org
ruleset adds a required PR, one approving review and code-owner review.

**Their own numbers.** 0 of the last 40 merged PRs merged without an approving review. `Quick Checks`
13/13 green on `main` over the last week. **5 subject-line reverts in the last 1000 commits — 0.5%.**
This is not a repo that keeps breaking things through process failure.

### Findings

**1. The local gate exists as exactly one line, in a CI file, and no contributor doc names it.**
`checks.yml:154` runs an eight-target `make` line, and the suite it belongs to is a **required**
status check. I grepped `CONTRIBUTING.md`, `BUILDING.md`, `README.md` and `docs/`: none of those
target names appears in any of them. The single check most likely to bounce a PR is transcribed
nowhere a human would look.

**2. `make fmtcheck` is not a check — it rewrites your working tree.** `scripts/gofmtcheck.sh:8` is
`gofmt_files=$(go fmt ./...)`, and `go fmt` is `gofmt -l -w`: it *writes*. In CI this is harmless on an
ephemeral checkout, which is exactly why it has survived. *Evidence, from reading the file — I did not
run it, because it would modify the clone.*

**3. Two rules that look enforced and are not.** Two further rulesets are both
`enforcement: evaluate` — they log and never block. One is redundant with an active org ruleset; the
other asserts that only core team members may create version branches, and **no active ruleset enforces
that**.

**Absences — present / absent / unsupported here / unknown**

**Present (5)** — verified: CI on pull requests, required status checks, required review (all three via
the rulesets API), actions pinned to SHA (48 references, 18 distinct actions, zero mutable tags), and
`SECURITY.md` **via the org** — checked before calling it missing.

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

`go fmt ./...` → `gofmt -l $(go list -f '{{.Dir}}' ./...)`. CI behaviour unchanged; local behaviour
stops being destructive. Promoted above item 2, which has the larger effect, because it is cheap, safe,
and item 2 is unsafe without it.

**2. Write the local pre-PR gate down.**
prevents: contributors discovering the required check only when CI bounces the PR · if skipped: every
newcomer reads a workflow file to find out how to test, or doesn't
effort: 1–2 h, mostly review of the wording · affects: everyone who commits
undo: `git revert` — it is a doc · needs: 1

Copy the exact line from `checks.yml:154` into `CONTRIBUTING.md` beside the existing `go test ./...`
guidance, noting which targets rewrite the tree.

**3. Add `timeout-minutes` to `checks.yml` and `pr.yml`.**
prevents: a hung job holding a runner for the six-hour default · if skipped: occasional silent capacity
loss, visible as "pending" rather than "failed"
effort: 30 min, incl. picking the value from run history · affects: everyone who merges
undo: `git revert` · needs: —

Set it above the observed p95; PR runs land in 6–13 minutes.

**4. Resolve the two `evaluate`-mode rulesets.**
prevents: a rule that reads as enforced and blocks nothing · if skipped: the "only core team may create
version branches" rule stays decorative, and a reader believes it
effort: 30 min to decide, plus a maintainer's judgement — **their decision, not mine**
affects: everyone who merges · undo: set `enforcement` back · needs: —

Promote or delete. As written, one of them is a name, not a rule.

**If only one:** item 1. Fifteen minutes, and it makes item 2 safe to act on.

**Not proposed:** a `CLAUDE.md` — `CONTRIBUTING.md` already fills the role and is good; a second
document would compete with it. Also not proposed: SBOM, chaos testing, coverage gates — all
worthwhile, none of them this repo's binding constraint.

**Could not verify:** the full test suite (cost); `make generate`/`protobuf` (they write to the tree);
the external release pipeline (lives in another repository, driven by an internal tool). Repo Actions
policy and legacy branch protection — permission-limited, **unknown, not absent**.
