# Template — root CLAUDE.md

**Only reach for this once the user has picked the document off the plan.** Writing it is a proposed
item, not a default outcome — some teams do not want an agent-specific file in their repo at all.
Where an agent-facing document already exists, the usual outcome is a section appended to it rather
than a file of your own: see *New file, or a section in theirs?* below, and settle that before
filling anything in.

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

*Then, in one line each:* confirm you are still on the working branch before committing; and: commit
or push only when asked — never push, tag, force, or rewrite history unprompted.

## Commits and pull requests

*Visibility: `<public | private | internal>`. In a public repository a commit message is a
publication — permanent, unreviewable after the fact, and carried by every clone.*

- **Say what was done.** Concise, accurate, simple. `<quote the form the log actually uses>`
- **Context needs approval.** Reasoning, alternatives, what this supersedes — offer it and wait. Do
  not add it unasked.
- **Never**: how it was found, verification narration, blame for earlier changes, vendor or API
  forensics, `<internal trackers, hostnames, run ids, machine paths>`, `<third parties>`.
- **Trailers**: `<the exact trailer this repo uses, verbatim — or: none>`
- **Merge mode**: `<squash | merge | rebase>` writes `<what actually lands on the default branch>`
- Detail that is worth keeping but not worth publishing goes in `<the untracked working notes>`.

*Delete this section for a private repository with a settled convention. Keep the first two lines
everywhere else — they are the ones that get violated.*

## CI and merging

*What actually validates a change, and at which point. Absences belong here too — an explicit "nothing
runs on pull requests" is more useful than an empty section.*

- **Runs on pull request**: `<workflow + what it covers>` / `<or: nothing — state it>`
- **Required to merge**: `<checks that genuinely block>` / `<or: none — direct pushes are possible>`
- **Review**: `<CODEOWNERS, required approvals, how they are dismissed>`
- **Known trigger gaps**: `<path filters, fork behavior, anything skippable>`
- **Actions hygiene**: `<pinned to SHA? explicit permissions? dependency updates?>`

## Releasing

*Which sections below apply depends on the repository kind. A deployed service keeps Releasing,
Environments, Shipping and When production is broken. **A library keeps this section and deletes the
other three** — there is no environment and no rollback, so this is where its weight goes. Delete
what does not apply rather than leaving a heading with a placeholder under it.*

- **Which commit is released**: `<how anyone can tell — a tag, a lockfile, a deployed SHA>`
- **Gate before release**: `<approval, environment reviewers, manual checklist — or none>`
- **After release**: `<smoke test, the signal watched, who watches it>`

*For a published package, add — this is the part with no undo:*

- **Registry and what it allows**: `<crates.io: permanent · PyPI: version never reusable · npm: 72h>`
- **What runs before the publish job**, and whether anything needs a human
- **What the publish job can reach**: `<token scope, environment gate, OIDC or a long-lived secret>`
- **Version and deprecation policy**: `<semver, what a breaking change requires, how one is announced>`

## Environments

*The single highest-value section for a deployed service, and **not applicable to a library, a
reference repository, or anything you do not deploy yourself**. Delete it there rather than filling it
in with placeholders.*

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
- `<hand-labeled or curated path>` — <why it is the measuring instrument, how to amend it safely>.
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

## New file, or a section in theirs?

**Decide this before writing a line, and from what the existing document contains — not from whether
one exists.** Most repositories already have somewhere this belongs.

| what you found | what to propose |
|---|---|
| a document that names the gate command, the branching rule, and the path to production (or the repo has no deployed environment) | **nothing.** Say it covers the ground and move on |
| a document that covers some of that and is silent on the rest | **a section appended to it**, carrying only the missing parts |
| nothing, or a stub that names none of the project's own commands | **a new file**, placed where they say |

The middle row is the common one, and appending is right there for a reason a new file cannot fix:
two agent-facing documents in one repository will drift, and the reader has no way to know which one
lost. Adding to the weaker document keeps one canonical place.

### Find the canonical file first

`CLAUDE.md` and `AGENTS.md` are frequently the same file, or maintained as copies. Writing to the
wrong one produces the duplication you were trying to avoid:

```sh
ls -l CLAUDE.md AGENTS.md .github/copilot-instructions.md 2>/dev/null
cmp -s CLAUDE.md AGENTS.md && echo "same content"
```

`ls -l` shows a symlink as `CLAUDE.md -> AGENTS.md`; **edit the target, never the link.** `cmp`
catches the copies, which a symlink check alone misses. If both exist independently and differ, ask
which one they maintain — and write to one of them, never to both.

### Appending, without taking the file over

- **Add at the end, or where they say.** Never interleave your material through theirs.
- **Match their headings** — same depth, same style, same vocabulary. A section that reads as though
  a different author bolted it on invites reverting the whole thing.
- **Never rewrite, reorder, retitle, or delete what is already there.** If something in it is wrong,
  say so in your reply; do not fix it as a side effect of adding.
- **Do not restate what the document already says.** A rule written twice drifts, and then the file
  contradicts itself. Reference their existing heading instead.
- **One diff a maintainer can read in a minute.** If your addition is longer than the document it is
  joining, that document is a stub — go back and propose a new file instead, and say why you changed
  your mind.
- Ask whether the result should be committed. Default to uncommitted.

## Before you write it into someone else's repo

- Describe their process in their vocabulary. Anything you think is *missing* goes in a separate
  proposals list, clearly marked — never blended into the description as if it were current practice.

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
