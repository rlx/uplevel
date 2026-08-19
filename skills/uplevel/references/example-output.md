# What good output looks like

One worked example, **real**: an audit of `hashicorp/terraform` run on 2026-08-19 by an agent with no
prior context, trimmed to the parts that teach the shape. Every claim was verified against the file or
API response it rests on. The repository may well have changed since — **read this for shape and tone,
not as current fact about that project**, and never reuse its items.

The shape: findings before recommendations, their numbers rather than your standards, absences named
with the right word, uncertainty marked, deliberate design recognised as such, and a plan short enough
to be acted on.

---

## Report — `hashicorp/terraform`

**Nothing security-urgent.** I looked specifically: no `pull_request_target` with a head checkout, no
unpinned third-party action, no `curl | bash`, no `@latest` installs, no secret values read.

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

**What validates a change before `main`.** Ruleset 2007970, `enforcement: active`, requiring Code
Consistency Checks, End-to-end Tests, Race Tests, Unit Tests and `license/cla`, with
`current_user_can_bypass: never`. An org ruleset adds a required PR, one approving review and code-owner
review.

**Their own numbers.** 0 of the last 40 merged PRs merged without an approving review. `Quick Checks`
13/13 green on `main` over the last week. **5 subject-line reverts in the last 1000 commits — 0.5%.**
*This is not a repo that keeps breaking things through process failure*, and that is the most important
caveat in this report.

### Findings

**1. The local gate exists as exactly one line, in a CI file, and no contributor doc names it.**
`checks.yml:154` runs `make fmtcheck importscheck vetcheck copyright generate staticcheck exhaustive
protobuf`, and "Code Consistency Checks" is a **required** status check. I grepped `CONTRIBUTING.md`,
`BUILDING.md`, `README.md` and `docs/`: none of those target names appears in any of them. The single
check most likely to bounce a PR is transcribed nowhere a human would look.

**2. `make fmtcheck` is not a check — it rewrites your working tree.** `scripts/gofmtcheck.sh:8` is
`gofmt_files=$(go fmt ./...)`, and `go fmt` is `gofmt -l -w`: it *writes*. In CI this is harmless on an
ephemeral checkout, which is exactly why it has survived. *Evidence, from reading the file — I did not
run it, because it would modify the clone.*

**3. Two rules that look enforced and are not.** Rulesets 2045004 and 2044810 are both
`enforcement: evaluate` — they log and never block. One is redundant with an active org ruleset; the
other asserts that only core team members may create version branches, and **no active ruleset enforces
that**.

**Absences — present / absent / unsupported here / unknown**

| | |
|---|---|
| CI on pull requests, required checks, required review | **present** — verified via the rulesets API |
| Actions pinned to SHA | **present** — 48 references across 18 distinct actions, **zero mutable tags** |
| `timeout-minutes` | **absent** — every job, every workflow |
| Local gate command in any contributor doc | **absent** — finding 1 |
| `SECURITY.md` | **present via the org** — checked before calling it missing |
| Repo Actions permissions policy | **unknown** — 403 at READ. *Not* "disabled" |
| Legacy branch protection | **unknown** — 404, which is ambiguous by design |

---

## Plan

**1. Write the local pre-PR gate down.** *(~30 min · affects: every contributor · reversible: it's a doc)*
Copy the exact line from `checks.yml:154` into `CONTRIBUTING.md` beside the existing `go test ./...`
guidance, noting that two of those targets rewrite the tree. **If only one item is picked, pick this
one** — everything else assumes people can reproduce CI locally, and today they cannot without reading
a workflow file.

**2. Make `make fmtcheck` actually check.** *(~5 min · affects: everyone running it locally · reversible: one line)*
`go fmt ./...` → `gofmt -l $(go list -f '{{.Dir}}' ./...)`. CI behaviour is unchanged; local behaviour
stops being destructive. Do this **with** item 1, not after — item 1 tells people to run a command that
currently edits their files.

**3. Add `timeout-minutes` to `checks.yml` and `pr.yml`.** *(~10 min · affects: nobody's correctness · reversible)*
Set it above the observed p95; PR runs land in 6–13 minutes. Today a hung Go job holds a runner for six
hours.

**4. Resolve the two `evaluate`-mode rulesets.** *(config · affects: release branch creation · **maintainer decision**)*
Promote or delete. As written, one of them is a name, not a rule.

**If only one:** item 1.

**Not proposed:** a `CLAUDE.md` — `CONTRIBUTING.md` already fills the role and is good; a second
document would compete with it. Also not proposed: SBOM, chaos testing, coverage gates. All real; none
of them what stands between this repo and its next bad day.

**Could not verify:** the full test suite (cost); `make generate`/`protobuf` (they write to the tree);
the external release pipeline (lives in another repository, driven by an internal tool). Repo Actions
policy and legacy branch protection — permission-limited, **unknown, not absent**.
