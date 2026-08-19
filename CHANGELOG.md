# Changelog

Versions match `version:` in `skills/uplevel/SKILL.md`.

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
