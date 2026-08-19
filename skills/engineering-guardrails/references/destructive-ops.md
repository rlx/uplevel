# Irreversible operations — the stop list

## The shape to recognize

Nearly every expensive mistake has the same signature:

> a command whose normal use is legitimate, whose failure mode is **silent**, and whose input was
> **expensive to produce**.

Not `rm -rf` — that one announces itself. It is `--record`, `--force`, `--reset`, `regenerate`,
`--seed`, `--fix`, `--overwrite`: verbs that sound like maintenance and behave like deletion. The
damage shows up as a green test suite measuring nothing.

A generic "go ahead" on a task is not consent for these. Consent is scoped to what was described. It
does not extend to the next instance, a wider blast radius, or a different dataset.

## Categories

**Recorded baselines, goldens, snapshots, approved fixtures.**
`--record`, `--update-snapshots`, `-u`, `--approve`, `--bless`, `--accept`, `RECORD=1`.
Legitimate after an *intentional* behavior change: run record mode, **review the diff line by line**,
then re-run normally to confirm green. Never as a way to clear a red test. If the diff contains
changes you cannot explain, you have found a bug, not a stale golden.

**Hand-authored judgement.** Hand-labelled datasets, curated corpora, reviewed baselines, annotated
ground truth. These are the measuring instrument; machine output must never overwrite them. Patch the
named row only. Where your judgement differs from a recorded label, record the disagreement — a
silent overwrite destroys the disagreement, which was the signal.

**Version control.** `push --force` (use `--force-with-lease` at minimum), `reset --hard`,
`clean -fdx`, `checkout .`, `stash drop`, `branch -D`, `rebase`/`amend` on pushed commits, `filter-branch`,
tag deletion or moving. Check for uncommitted work before any of these; `clean -fdx` deletes
gitignored files, which is often exactly the local state nobody can regenerate.

**Data stores.** Migrations (especially `down`), `db:reset`, `truncate`, `drop`, seed scripts, cache
flushes, and any ad-hoc `UPDATE`/`DELETE`. Confirm the environment before every one — the same command
is routine on a local database and career-defining on production. Prefer additive, reversible
migrations; back up first and verify the backup restores.

**Anything that changes what production is running or serving.** Deploys and rollbacks, scaling
(including to zero), restarts, feature-flag flips, DNS and load-balancer changes, rotating credentials,
draining a node, purging a cache or CDN, replaying or purging a queue. These are reversible in
principle and disruptive in practice, and several of them look like reads until they are not.

**Wrong-environment execution.** Not a category of command but a category of mistake, and the most
expensive one: a correct command against the wrong target. It never looks like an error — valid
command, normal output, damage found later by someone else. Print the resolved environment before any
command that reads credentials or mutates state. See `production.md` §1.

**Infrastructure state.** `terraform apply`/`destroy`, Helm uninstalls, deleting a bucket, volume, or
managed instance. Read the plan; a plan showing a replace where you expected an update is the warning.

**Customer data.** Deleting or exporting it, copying production data to a lower environment or a
laptop, bulk-emailing users. These carry legal consequences the repo cannot see. Never do them on a
generic approval.

**Precious-but-gitignored local state.** Downloaded corpora, recorded HTTP/VCR cassettes, replay
stores, `.env`, local databases, model weights, caches that took hours to warm. Gitignored reads as
"disposable" and is often the opposite: it cannot be restored from the repo, and a cold re-fetch may
not reproduce it (sources change, licenses expire, the web moved on).

**Money and rate limits.** Paid API runs, cloud jobs, large batch inference, anything metered.
State the estimated cost before starting, not after.

**Outward-facing actions.** Deploys, releases, publishing packages, PR/issue/comment creation, sending
mail, posting to any external service. Publishing is not reversible in practice: caches and indexes
outlive deletion.

**Bulk edits.** Repo-wide `sed`/codemods, `--fix` on a linter across everything, mass renames,
auto-formatting a codebase that was not formatted. Do a scoped run first, read the diff, then widen.

**Weakening the safety net.** Deleting or skipping a failing test, loosening an assertion, raising a
threshold, adding a broad ignore/suppression, disabling a check in CI. A failing test is a finding:
fix the code, or record it as a known-open defect with its diagnosis. Never convert a finding into a
green tick. Loosening a check is a behavior change and needs the same evidence as a code change —
"nothing failed after I loosened it" is not evidence, it is the definition of the loosening.

## Discovering this repo's own list

- `grep -rniE -- '--(record|update|approve|bless|accept|force|reset|overwrite|fix)\b'` over scripts, CI
  config, task runners, and test helpers.
- `grep -rniE 'RECORD=|UPDATE_|REGEN|OVERWRITE|SEED|FORCE' -- ` env-var style flags.
- Read `.gitignore` and ask, for each entry: *if this vanished, could we get it back?*
- **Look for source code inside gitignored directories** — `find <ignored-dir> -name '*.py' -o -name
  '*.sh' -o -name '*.rb'`. Generation and analysis scripts written next to their output are common,
  invisible to git, and destroyed by the same `clean -fdx` that was aimed at build artifacts.
- Look for fixture/golden/snapshot/migration/corpus directories and find what writes them.
- Check package scripts and Makefile targets for anything named `reset`, `clean`, `seed`, `regen`,
  `record`, `publish`, `deploy`.

**Then ask the user to confirm the list.** They know which data is irreplaceable and which is
regenerated nightly. Getting this wrong in the safe direction (asking too often) is cheap; getting it
wrong the other way is not recoverable.
