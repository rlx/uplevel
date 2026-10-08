# Security policy

## Reporting a vulnerability

Report privately, not in a public issue.

Use GitHub's private vulnerability reporting: open the **Security** tab and choose *Report a
vulnerability*. This creates a private advisory visible only to the maintainers, and it is the
channel that reaches us — it raises an email and a GitHub notification directly.

If that option is unavailable, open an issue asking for a private channel without including any
detail of the problem itself.

This is a small project with one active maintainer, so there is no guaranteed response time. Reports
are read as soon as they are seen, usually within a few days. If a week passes with no reply, a
comment on the advisory is a reasonable nudge.

## Scope

This repository contains a Claude Code skill: markdown instructions plus nine executable scripts. Seven
are the project's own; two belong to test fixtures.

| script | what it does |
|---|---|
| `scripts/check-repo.sh` | this repository's gate; runs the checks below |
| `scripts/check-install.sh` | runs the documented install commands against a temporary `HOME` |
| `scripts/check-forge.sh` | reads this repository's GitHub settings through `gh`; writes nothing |
| `scripts/check-behavior.sh` | copies fixture repositories to a temporary directory and runs the skill against them through the `claude` CLI, which calls a model and may run `make` and `python3` there |
| `scripts/install-hooks.sh` | **writes to `.git/hooks/`** — the only one of the project's own scripts that modifies your clone |
| `scripts/hooks/pre-commit` | the tracked source the installer copies into place |
| `plugin/skills/uplevel/selfcheck.sh` | structural checks on the skill itself |
| `tests/fixtures/ledger-api/scripts/fmt.sh` | fixture: rewrites the fixture's Python files in place when run |
| `tests/fixtures/orders-db/scripts/migrate.sh` | fixture: writes `applied.log`; applies nothing, and there is no database |

Relevant reports include anything that would cause the skill to read a secret, run an unsafe command,
write outside the paths above, or mislead a reader about whether a check ran.

The skill inspects repositories it is pointed at. It is designed to enumerate configuration keys
rather than read secret values, and to avoid running commands that need credentials or touch shared
infrastructure. A case where it does either is in scope.

## Out of scope

Findings the skill reports about *your own* repository are not vulnerabilities in this project.
