# Contributing

The deliverable is markdown that changes how an agent behaves, so an inaccurate sentence is a defect
in the same way a wrong line of code is. Most of what follows exists to keep that true.

## Before you open a pull request

```sh
./scripts/install-hooks.sh   # once, after cloning
./scripts/check-repo.sh      # the gate; runs on every commit and in CI
./scripts/check-install.sh   # only if you touched README.md's install section
./scripts/check-forge.sh     # only if you touched what .claude/guardrails.yml says about GitHub
```

`check-install.sh` extracts the install commands from `README.md` and runs them against a clean
`HOME`. It clones this repository four times, so it runs about five seconds — CI runs it on every
change and the commit hook does not.

`check-forge.sh` diffs what the checklist records about GitHub — the rules protecting `main`, whether
the declared version was released, the repository's description and topics, and the languages code
scanning analyzes — against GitHub itself. It needs the network and an
authenticated `gh`, so it skips on a machine without them and CI is what gates it.

The gate runs in about a second. If it fails it names what to fix. Bypass it with
`git commit --no-verify` only when you know why, and say so in the pull request.

## The rules the gate enforces

- **`SKILL.md` has a token budget**, currently 6000. It loads on every trigger; `references/` load
  only when read. New detail belongs in a reference by default — but **the budget is a visibility
  mechanism, not a quality cap.** If something genuinely belongs in the always-loaded file, put it
  there and raise the number in the same change, saying why. Never cut something worth saying to fit
  a figure.
- **Bump `version:` in `SKILL.md`** in the same commit as any change to `SKILL.md` or `references/`.
  **And `version` in `.claude-plugin/plugin.json` with it** — that is the number a plugin install
  reports, and the gate fails while the two disagree.
- **Write the `CHANGELOG.md` entry in the same change**, not in a follow-up. A release was published
  once from a commit that documented every version except the one it released.
- **Every reference must be linked from `SKILL.md`, and every link must resolve.** Both directions.
- **References cite each other by bare filename** — `evidence.md`, not `references/evidence.md`, which
  would mean `references/references/`.
- **No GNU-only constructs in gate scripts.** CI is ubuntu-latest; a maintainer may be on bash 3.2
  with BSD tools. The list is `scripts/gnu-only-constructs.txt` — add to it rather than working
  around it.
- **No machine- or project-specific strings.** Patterns in `skills/uplevel/leak-patterns.txt`.
- **Every invariant is stated in `SKILL.md`.** List in `skills/uplevel/invariants.txt`. Adding one
  means adding it to both — a rule that lives only in a reference has been demoted behind a read.

Two rules the gate does not yet enforce: prose is **en-US** (behavior, license, judgment, labeled),
and nothing absent or unverified about this repository's own posture goes in a tracked file — that
belongs in the untracked `.claude/improvement-plan.md`.

## The rule the gate cannot enforce

**Every command the skill prints must have been run, here, and observed to work.** The gate checks
that a shipped command parses and that its regex compiles; it cannot check that the command does what
the sentence claims. That one is on you.

This matters more than it sounds. A gate command that does not exist is worse than no gate — it
manufactures confidence, and the next session reports green having run nothing.

## Adding a check

Anything you add to the gate must be **proven able to fail**. Break the thing it checks, watch it go
red, restore, watch it go green, and say in the pull request that you did. If the check has a skip
path — it degrades when a tool is absent — exercise that too: an unexercised skip is how a check
becomes vacuous on exactly the machines that needed it, while still reading as green.

A check that searches the tree is *in* the tree. Keep its patterns in a data file, or it will match
itself and report a defect it invented. This is not hypothetical and it is not only about the tree:
the rule that counts *added checks* was first written with its patterns inline, and counted its own
source lines as two new checks.

**One leak the gate cannot catch, so review has to.** `leak-patterns.txt` matches shapes — home
directories, drive letters, machine paths. Another project's file paths have no shape to match, and a
denylist of names only catches the leak already found. The worked example once shipped with its
subject repository's package paths and script line numbers still in it, and no pattern would have
seen them. When editing `references/example-output.md`, or adding any example drawn from a real
repository, check by hand that nothing identifies it.

The pull request template asks for the parts of this the gate cannot see. It is a prompt, not a
check — nothing enforces the answers, which is why they are worth reading.

## Commits and pull requests

**Say what was done.** Concise, accurate, simple. Most changes need only a subject line. No AI
attribution.

**Anything beyond what was done needs approval first.** Reasoning, alternatives, what a change
supersedes — that is context. Offer it and wait; do not add it unasked.

Never include how you found it: which command surfaced the bug, which API returned what, what a past
commit got wrong, how a check was proven able to fail. That is working-notes material, and this
repository is public.

Squash merge writes only the pull request title into `main`. Pull request bodies follow the same rule
and can be edited after merge; a commit message cannot.

## Does the skill say what this repository does?

Periodically, diff the two. This project learns things by running its own gate, and those lessons
have repeatedly stayed in a commit message or a research note instead of reaching the file that
ships. The shallow-clone trap sat in the validation notes for the length of the project before the
skill said it; a later sweep found five more practices followed here and taught nowhere.

The pass is cheap: list what this repository *does* — its workflow settings, its gate's guards, the
conventions in this file — and for each, grep `skills/uplevel/` for whether it is taught. Anything
followed here and absent there is either a lesson worth shipping or a habit worth dropping, and both
answers are useful.

## Scope

Repository-specific checks belong in that repository's own checklist, never in the shipped skill —
`references/checklist.md` explains the split. A check that fires everywhere and matters nowhere costs
attention on every audit.
