# Template — root CLAUDE.md

**Only reach for this once the user has picked the document off the plan.** Writing it is a proposed
item, not a default outcome — some teams do not want an agent-specific file in their repo at all.

Fill in from what you discovered and **delete every section that does not apply**. Target 60–120 lines;
this loads into every session, so length is a tax paid on every future turn. Every command must be one
you ran. Mark anything unverified explicitly.

Replace `<…>` placeholders. Prose in *italics* is instruction to you and must not survive into the
output.

---

```markdown
# <Project> — engineering process

<One or two lines: what this is, what language/stack, and where the important code lives. Enough that a
fresh session knows which directory to open first.>

## Read before you change <the risky area>

*Only if the repo already has design/verification/decision docs worth routing to. A table of paths with
one line each on what each governs. If there are no such docs, delete this section — do not invent it.*

| file | what it governs |
|---|---|
| `<path>` | <what it governs> |

## Branching

Branch before the first change, not before the commit — `git switch -c <name>` off `<default branch>`.
*<The repo's naming convention, quoted from its actual branches.>* If already on a working branch, stay
on it. Uncommitted work you did not create is authoritative: `switch -c` carries it; never `stash`,
`reset`, `checkout .`, or `clean` a tree you did not dirty.

## The check-in gate

Before every commit that touches `<area>`:

1. `<the one command>` — must be GREEN. *(<runtime you observed>)*
2. `<what the gate needs running first, e.g. docker compose up — and how a suite that skips without
   it reports green having tested nothing>`
3. `<regeneration step, and exactly which changes trigger it>`
4. `<the step the automatic gate does NOT cover, and when it is required>`
5. `<version/cache-key/schema-version bump, naming the file — in the SAME commit as the change>`
6. `<new env vars: deployment config + example file + docs, same change>`

*Then, in one line each:* commit message style (quote the convention the log actually uses); the PR
norm; confirm you are still on the working branch before committing; and: commit or push only when
asked — never push, tag, force, or rewrite history unprompted.

## CI and merging

*What actually validates a change, and at which point. Absences belong here too — an explicit "nothing
runs on pull requests" is more useful than an empty section.*

- **Runs on pull request**: `<workflow + what it covers>` / `<or: nothing — state it>`
- **Required to merge**: `<checks that genuinely block>` / `<or: none — direct pushes are possible>`
- **Review**: `<CODEOWNERS, required approvals, how they are dismissed>`
- **Known trigger gaps**: `<path filters, fork behaviour, anything skippable>`
- **Actions hygiene**: `<pinned to SHA? explicit permissions? dependency updates?>`

## Releasing

- **Which commit is in production**: `<how anyone can tell>`
- **Gate before release**: `<approval, environment reviewers, manual checklist — or none>`
- **After release**: `<smoke test, the signal watched, who watches it>`

## Environments

*The single highest-value section for a deployed service. Delete only if nothing is deployed.*

| environment | how to tell you are pointed at it | who can write | how a change gets here |
|---|---|---|---|
| `<local>` | `<the command that resolves it>` | — | — |
| `<staging>` | `<…>` | `<…>` | `<…>` |
| `<production>` | `<…>` | `<…>` | `<…>` |

- Production is read-only unless the user names production in this turn.
- `<the ad-hoc-write policy, and the reviewed path that replaces it>`
- `<where secrets come from; what must never be printed or committed>`

## Shipping

- **Path to production**: `<merge → pipeline → …>`
- **Rollback**: `<the exact command or control — or state plainly that there is none>`
- **Verify after deploy**: `<the log line, metric, dashboard, or query — named>`
- **Migrations**: `<the tool, the expand/contract convention, what locks in this engine>`
- `<deploy freeze / no-deploy windows, if any>`

## When production is broken

*Only if there is a real runbook or on-call rotation to point at; otherwise delete.*

- `<where the dashboards, logs, and alerts are>`
- `<who to tell, and how>`
- Stabilize first (roll back / flag off), preserve evidence before restarting, one change at a time.
- `<where incidents get written up — and the rule that each one becomes a test, an alert, or a check>`

## Guardrails — confirm with the user first

*The repo-specific list from `destructive-ops.md`, confirmed with the user. For each: the command, what
it destroys, and what legitimate use looks like. Keep to what is genuinely irreversible here.*

- `<command>` — <what it overwrites>. <When it is legitimate; what to review before and after.>
- `<hand-labelled or curated path>` — <why it is the measuring instrument, how to amend it safely>.
- `<gitignored-but-precious path>` — <why a re-fetch does not restore it>.
- `<anything that costs money or touches production>` — <estimate cost / confirm environment first>.
- Weakening a check to make it pass. A failing test is a finding: record it with its diagnosis.

## Long runs and interruptions

*Only for repos with runs long enough to be interrupted or numbers worth trusting. Otherwise delete.*

- `<the long run and its typical duration>`
- Never edit source while a run is in flight — `<why: rebuilds per item / re-imports / etc.>`
- Background it and tee to `<scratch path>`; quote the file, not scrollback.
- `<the noise floor you measured>` — differences inside it are not results.
- An interrupted run is not a result: say so and re-run.

## Automated vs. remembered

*What is enforced by a machine, and what still depends on someone reading this file. Keeping this
honest is what stops the document from being mistaken for a safety net.*

- Enforced in CI: `<checks that actually block a merge — verify branch protection, not just the file>`
- Enforced at commit: `<hooks — locally bypassable, so CI must repeat them>`
- **Not enforced, relies on this document**: `<the list>` — `<the next one worth automating>`

## <Measurement / correctness>

*Only for projects steered by a metric — ML, evals, benchmarks, performance work. Delete otherwise.*

- <which number is the real one, and which misleading one is easy to quote instead>
- <what the ground truth is and how it is allowed to change>
- <the verification rule this project learned the hard way>
```

---

## Before you write it into someone else's repo

- Ask where it should live and whether it should be committed: root `CLAUDE.md`, alongside their
  existing agent/contributor docs, or local-only and gitignored. Default to uncommitted.
- Describe their process in their vocabulary. Anything you think is *missing* goes in a separate
  proposals list, clearly marked — never blended into the description as if it were current practice.
- Additive only. Do not restructure or rewrite their existing docs to make room for this one.

## Checks before you hand it over

- Could this be pasted into an unrelated repo unchanged? If yes, it is too generic — cut or specialize.
- Does every command appear because you ran it?
- Does every rule name what it prevents? If you cannot say, cut it.
- Does it contradict the git log, the CI config, or an existing doc? Match the repo, do not overrule it.
- Is anything in it already enforced automatically? Enforced things belong in CI, not in a document —
  the document is for what a human or an agent must choose to do.
- For a deployed service: does it answer *how do I know which environment I am pointed at*, *what is
  the rollback*, and *how do I know the change worked*? If not, the riskiest part of the work is the
  part still undocumented.
- Did you end by naming what should be a check rather than a sentence? A document that never shrinks
  is a process that never improves.
