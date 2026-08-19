# Security policy

## Reporting a vulnerability

Report privately, not in a public issue.

Use GitHub's private vulnerability reporting: open the **Security** tab and choose *Report a
vulnerability*. This creates a private advisory visible only to the maintainers.

If that option is unavailable, open an issue asking for a private channel without including any
detail of the problem itself.

Expect an acknowledgement within seven days.

## Scope

This repository contains a Claude Code skill: markdown instructions plus two shell scripts
(`skills/uplevel/selfcheck.sh` and `scripts/check-repo.sh`). Relevant reports include anything that
would cause the skill to read a secret, run an unsafe command, or mislead a reader about whether a
check ran.

The skill inspects repositories it is pointed at. It is designed to enumerate configuration keys
rather than read secret values, and to avoid running commands that need credentials or touch shared
infrastructure. A case where it does either is in scope.

## Out of scope

Findings the skill reports about *your own* repository are not vulnerabilities in this project.
