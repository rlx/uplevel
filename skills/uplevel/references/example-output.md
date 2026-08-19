# What good output looks like

One worked example, invented. Read it for **shape and tone**, not content: findings before
recommendations, their numbers rather than our standards, absences named, uncertainty marked, and a
plan short enough to act on. Do not reuse its items — they belong to a repo that does not exist.

---

## Report — `acme/billing-api`

**What validates a change before it reaches `main`:** nothing. `.github/workflows/test.yml` triggers
on `push` to `main` only, so pull requests run no checks; the branch is where breakage is found.
*(Evidence: the workflow's `on:` block.)*

**What validates a change before it reaches production:** a manual deploy from a laptop
(`scripts/deploy.sh`). No approval gate, no smoke test. Which commit is live is not recorded anywhere
I could find — I asked, and nobody was certain. *(Evidence: the script; confirmed in conversation.)*

**The gate as it exists:** `make test` — 218 tests, 41s, green on a clean tree. It does **not** cover:
integration tests (they need Postgres and skip silently when it is absent — 34 of the 218 skipped on
my run and the suite still reported success), migrations, or any config validation.

**Their numbers, last 50 merges:** 14 reached `main` with no approving review; `main`'s own CI was red
on 6 of the last 30 days, twice for more than 24h; 4 commits since March are reverts, 3 of them
touching `app/billing/invoice.py`. *(Evidence: `gh pr list`, `gh run list`, `git log`.)*

**Absences** — present / absent / unknown:

| | |
|---|---|
| CI on pull requests | **absent** |
| Required status checks, required review | **absent** — direct pushes to `main` are permitted |
| Actions pinned to SHA | **absent** — 6 of 9 use a mutable tag |
| Explicit `permissions:` block | **absent** — default token is write-scoped |
| Secret scanning, Dependabot | **absent** |
| Rollback | **unknown** — a procedure exists in `docs/`; nobody I asked has run it |
| `CODEOWNERS`, PR template, `SECURITY.md` | **absent** |
| Newcomer to passing tests in one command | **absent** — needs 4 undocumented steps |

**Inference, not evidence:** `invoice.py` appearing in 3 of 4 reverts suggests it is the fragile spot,
but four data points is not a pattern I would bet on.

**Could not verify:** branch protection (the API needs admin rights — 404 for me); whether the deploy
script has ever been run by anyone but its author.

---

## Plan

Ordered by damage prevented per unit of effort.

**1. Run the existing tests on pull requests.** *(~15 min · affects: everyone who merges · reversible:
delete 3 lines)*
Add `pull_request` to the existing workflow's triggers. The tests already exist and already pass —
today nothing runs them before a merge. This is the whole of the gap between "we have tests" and "our
tests protect `main`".

**2. Fail the build when integration tests cannot run.** *(~30 min · affects: everyone who merges ·
reversible)*
34 tests skipped silently on my run and the suite reported success. A green suite that tested nothing
is worse than a red one. Either start Postgres in CI or make the absence an error.

**3. Pin the six mutable action references to SHAs, and add `permissions: contents: read`.**
*(~20 min · affects: nobody until an action is updated · reversible)*
A tag can be re-pointed at new code, and the default token currently grants repository write to every
third-party action in the pipeline.

**4. Record which commit is deployed.** *(~1h · affects: whoever deploys · reversible)*
Write the SHA to a file or endpoint at deploy time. Nothing else in this list can be verified in
production until "what is running?" has an answer.

**5. Ask a maintainer to require the test check and one review on `main`.** *(configuration, not code ·
affects: everyone who merges — a maintainer decision, not mine)*
14 of the last 50 merges had no approving review. This is the item I would expect disagreement on; it
is a team norm, not a defect, and it should follow items 1 and 2 so the required check is one that
actually runs.

**If only one:** item 1. Everything else assumes a change gets checked before it lands.

**Appendix — worth doing, not yet worth interrupting for:** `CODEOWNERS`; a PR template asking for a
rollback note; Dependabot; a documented one-command setup; a smoke test after deploy; retiring the
laptop deploy in favour of a pipeline.

**Not proposed:** SBOM, provenance attestation, chaos testing. All real; none of them the thing
standing between this repo and its next incident.
