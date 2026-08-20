# Changelog

Versions match `version:` in `skills/uplevel/SKILL.md`.

## v0.62.0 — 2026-08-20

- `mode-a-investigate.md`: find the repository's conventions before writing, not after the gate
  rejects the change. The recurring set is a version marker, a changelog entry in the same commit, a
  wrap width, a spelling variant, and a trailer — match them rather than improve them.

## v0.61.0 — 2026-08-20

- `mode-a-investigate.md`: "teaching" is a weighting, never a reason to look less hard. No rollback is
  not the same as nothing to gate, and a teaching repository that serves a page or ships a package
  inherits that kind's gate in full.
- `forge-hygiene.md`: `allow_failure: true` is GitLab's `continue-on-error`, and the map named every
  other translation but that one. It is the highest-value grep on a GitLab repository.
- `forge-hygiene.md`: fork merge requests get the same blast-radius question as fork pull requests.

## v0.60.0 — 2026-08-20

- `forge-hygiene.md`: a GitLab map — the same questions under different names, and `include: remote:`
  with an unpinned `component:` as the supply-chain finding there. "Audit their equivalent" stranded
  anyone who had not seen one.
- `discovery.md`: a repository that teaches CI contains CI files that are not its CI. Exclude the
  obvious homes, and read the path of a match rather than only its count.
- `discovery.md`: no history has two causes. A shallow clone is fixed by fetching; a repository that
  publishes squashed snapshots is a finding, and they look identical until you check.

## v0.59.0 — 2026-08-19

- `mode-a-investigate.md`: hazard discovery no longer names four languages. An extension list returned
  zero on a repository with thirty-two Elixir migrations, and destructive schema change is spelled in
  each ORM's own vocabulary rather than in SQL.

## v0.58.0 — 2026-08-19

- `automation.md`: four rules this project follows and the skill never taught — a committed hook is
  inert until installed, `--no-verify` needs a convention rather than a pretence, local-only checks
  must skip in CI, and a gate script runs on more than one machine's tooling.
- `forge-hygiene.md`: `permissions: {}` is the floor worth proposing, not `contents: read`.

## v0.57.0 — 2026-08-19

- `SKILL.md`, `discovery.md`: check the clone is not shallow before answering what has already gone
  wrong. `--depth 1` makes every history question return zero, which reads exactly like a healthy
  repository.

## v0.56.0 — 2026-08-19

- `SKILL.md`: the three orienting questions are asked before the mode file is opened, not after. They
  decide what the audit is for, and answering them late means aiming a report wrong.

## v0.55.0 — 2026-08-19

- `selfcheck.sh`: the `SKILL.md` budget is 6000 rather than 4000, and is documented as a visibility
  mechanism rather than a quality cap — raise it deliberately when something belongs in the
  always-loaded file.

## v0.54.0 — 2026-08-19

- New `references/remedies.md`: what each finding turns into, so the four remedy-shaped plan fields are
  looked up rather than authored. Read at plan time only.
- `SKILL.md`: states the shape — judgment at the entry, determinism after. Two audits of the same
  repository should differ in what they noticed, never in what a finding costs.

## v0.53.0 — 2026-08-19

- `mode-a-investigate.md`: form a hypothesis before walking the eight steps — who is exposed, what has
  already gone wrong, and what would have to be true for this repository to be fine. Then walk the
  list looking for what contradicts you.
- `mode-a-investigate.md`: the kind is settled by one question — when this changes, who is exposed and
  can anyone take it back — rather than by a list of signals to match. Signals are ambiguous and the
  README is not.

## v0.52.0 — 2026-08-19

- `mode-a-investigate.md`: how to read the kind tells, from running them against ten repositories. A
  repository can be two kinds; packaging metadata is not publishing; a missing publish job is a
  finding rather than an absence; a CLI shipped as binaries is still something others run.

## v0.51.0 — 2026-08-19

- `automation.md`: propose a workflow analyzer rather than reimplementing one. Names `zizmor`,
  OpenSSF Scorecard and `actionlint`, and what this skill adds that they cannot.
- `forge-hygiene.md`: a pinned SHA can still be an impostor commit; `actions/checkout` persists a
  credential on disk by default; restoring a cache in a release job is a supply-chain path.

## v0.50.0 — 2026-08-19

- `mode-a-investigate.md`: the report's second gate is named by repository kind — production, the
  registry, readers, the repositories it governs, or other people's machines. For three of the five
  there is no rollback behind it.
- `forge-hygiene.md`: which sections apply, per kind, plus the two checks that exist only for a
  published package — provenance and a version policy.
- `automation.md`: what to automate first depends on the kind; the existing order is a service's.
- `claude-md-template.md`: which sections apply is decided by kind. `Releasing` gains the
  published-package fields; `Environments` says plainly it does not apply to a library.

## v0.49.0 — 2026-08-19

- `destructive-ops.md`: a package registry publish named as the irreversible operation for a library,
  with the per-registry rules and what they leave you able to propose.
- `discovery.md`: a floating toolchain in CI makes the gate non-deterministic, which is distinct from
  an unreproducible release artifact.

## v0.48.0 — 2026-08-19

- `forge-hygiene.md`: the pinning census matches workflow files rather than recursing the directory,
  which counted `uses:` references in markdown living beside the YAML.
- `forge-hygiene.md`: `permissions:` anchored to the top level; indented it also matched every
  job-level block.
- `forge-hygiene.md`: count `timeout-minutes` per job, not per file.

## v0.47.0 — 2026-08-19

- `commit-hygiene.md`: write a pull request body to a file. Passed as a shell argument, backticked
  text is run as command substitution and the words are silently published as nothing.

## v0.46.0 — 2026-08-19

- `mode-a-investigate.md`: establish what kind of repository this is before the audit is weighted —
  service, library, reference, tooling, or an application someone else runs. The kind decides whether
  an absence is a finding.
- `mode-a-investigate.md`: cross-check the pull request API against the git log; where they disagree,
  how work reaches the default branch is the finding.
- `forge-hygiene.md`: a settings field that is `null` inside a `200` is unknown, not absent.

## v0.45.0 — 2026-08-19

- `forge-hygiene.md`: the forge measurements degrade cleanly on a repository with no workflows
  directory, which is the case the section exists to find.

## v0.44.0 — 2026-08-19

- `automation.md`: three rules for adding a check — prove it on the case that motivated it, re-prove
  the original case whenever you loosen it, and time the whole gate rather than the check.

## v0.43.0 — 2026-08-19

- `mode-a-investigate.md`: a scope table — forge, gate, hazards, full — with the rule that a scoped
  audit states its scope in the first line of the report.
- `selfcheck.sh`: prints what each scope costs, and no longer flags prose that names the
  `references/` directory as a miscitation.

## v0.42.0 — 2026-08-19

- `forge-hygiene.md`: the pinning census splits first-party from third-party, which the same section
  already told the reader to do and the command did not.

## v0.41.0 — 2026-08-19

- `forge-hygiene.md`: commands for the trigger census, the pinning census and the workflow file
  count, calibrated against ten large repositories.
- `forge-hygiene.md`: `on:` parses as a YAML boolean, so a parser looking for `"on"` reports zero
  triggers everywhere.

## v0.40.0 — 2026-08-19

- `forge-hygiene.md`: `gh` not being installed, and which half of the forge audit still works without it.
- `selfcheck.sh`: prints what each mode costs to load, not only `SKILL.md`.
- `selfcheck.sh`: all eleven invariants must be stated in `SKILL.md`, from `invariants.txt`.
- `check-repo.sh`: a new gate check must be recorded in `.claude/guardrails.yml` in the same commit.

## v0.37.0 — 2026-08-19

- `check-repo.sh`: en-US spelling and a 105-character markdown wrap ceiling.
- `README.md`: names Claude Code in the first line; install caveats collapsed.
- `discovery.md`, `checklist.md`: pinned tool versions and sample dates that would date.
- `CONTRIBUTING.md`: the leak scan cannot see third-party fingerprints; review must.
- `CLAUDE.md`: tagging is printed, not gated.
- `CHANGELOG.md` added.

## v0.35.0 — 2026-08-19

- `forge-hygiene.md`: the two secret-scanning fields the GitHub API discards on write and misreports
  on read.

## v0.34.0 — 2026-08-19

- `skills/uplevel/README.md`: install runs from a clone, is repeatable, and states the GitHub-first
  limit of the forge audit.
- `check-install.sh`: covers the shipped README.
- `check-repo.sh`: version bump required for every file under `skills/uplevel/`.

## v0.33.0 — 2026-08-19

- New `references/commit-hygiene.md`.
- Template: "Commits and pull requests" section, and a three-way test for where a process document
  goes when one already exists.
- New `check-install.sh` in CI; fixes two defects in the documented install.
- `CONTRIBUTING.md`, `CLAUDE.md`: commit and PR convention.

## v0.31.0 — 2026-08-19

- `example-output.md`: subject repository removed; framed as a format example.
- Prose is en-US.
- `check-repo.sh`: checklist audit date, and every tag must declare its version.
- `SECURITY.md`: no guaranteed response time.
- `guardrails.yml`: records only controls in place.
- `README.md`: shortened.

## v0.29.0 — 2026-08-19

First tagged release. Tag and `version:` carry the same number.

---

`0.30.0` and `0.32.0` were never tagged; their changes are in v0.31.0 and v0.33.0.
