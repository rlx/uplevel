# Remedies — what each finding turns into

**Read this when writing the plan, not before.** The audit decides *what is true*; this file decides
*what that turns into*, so two audits of the same repository produce the same plan item rather than
two differently-worded inventions.

Four of the six plan fields — **prevents**, **effort**, **affects**, **undo** — are properties of the
remedy and are given here. Two are properties of the repository and are yours to fill: **`if skipped`**
(what leaving it costs *here*) and **`needs`** (which other item this one depends on *here*).

**Effort is maintainer-hours including review and consent**, not keystrokes. Where a figure is marked
*(measured)* it came from doing the work, not from estimating it.

**A remedy is not automatically a proposal.** Ordering, the five-to-seven cap, and whether an item
earns its place at all are decided by the plan rules in `mode-a-investigate.md`. This file only
prevents the same fix being described three different ways.

---

## Nothing validates a change before the default branch

**Add a workflow that runs the existing gate on `pull_request`.**
prevents: a change reaching the default branch with nothing having run
effort: 1–2 h · affects: everyone who commits · undo: delete the workflow
*Only propose the gate you found and ran. Inventing a suite here is how a green check that tests
nothing gets created.*

**Require that check on the default branch.**
prevents: a check that runs and never blocks · effort: 30 min, plus a maintainer's decision
affects: everyone who merges · undo: remove it from the ruleset
**Never apply this yourself.** It can fail every teammate's merge tomorrow morning.

## A control exists and does not bite

**Promote the ruleset from `evaluate` to `active`, or delete it.**
prevents: a rule that reads as enforced and stops nothing · effort: 30 min, plus their decision
affects: everyone who merges · undo: set `enforcement` back
*As written it is a name, not a rule. Promote or remove — leaving it is the worst of both.*

**Make a check that rewrites the tree check instead.**
prevents: a target named `check` silently editing a contributor's working tree
effort: 15 min *(measured)* · affects: everyone who commits · undo: `git revert`
*Swap the formatting command for the check-only form of the same tool. CI behavior is unchanged.*

## Supply chain

**Pin third-party actions to a full commit SHA, version in a trailing comment.**
prevents: a tag re-pointed at new code running with your token
effort: 1 h for a repository's worth · affects: everyone who merges · undo: `git revert`
*Rank by blast radius, not count: start with the jobs holding write permissions or registry
credentials. A SHA can still be an impostor commit — necessary, not sufficient.*

**Set `permissions: contents: read` at workflow level, widen per job.**
prevents: every action in every job holding repository write
effort: 30 min · affects: everyone who merges · undo: `git revert`

**Set `persist-credentials: false` on checkout where the token is not needed after it.**
prevents: a credential left on disk and packaged into an artifact
effort: 20 min · affects: everyone who merges · undo: `git revert`

**Do not hand-check what a tool checks better — add `zizmor` or Scorecard to CI.**
prevents: thirty workflow vulnerability classes going unexamined between audits
effort: 1 h · affects: everyone who merges · undo: delete the job
*This replaces a recurring manual pass. Propose it before proposing the individual findings it
would have caught.*

## Release, for anything published

**Gate the publish job behind a named environment with a required reviewer.**
prevents: an unreviewed publish of a version that can never be withdrawn
effort: 1 h, plus their decision · affects: everyone who merges · undo: remove the environment
*For a library this is the highest-value item on the list, because there is no rollback behind it.*

**Mint the publish credential with OIDC rather than a long-lived token.**
prevents: a registry token in repository secrets outliving the person who added it
effort: 2 h · affects: everyone who merges · undo: revert to the secret

**Turn on provenance or attestation for the published artifact.**
prevents: no way to tie a published version to the commit it came from
effort: 1 h · affects: consumers · undo: remove the flag
*npm provenance, PyPI attestations, sigstore. Absent on most packages; cheap.*

**Tag releases, and write the changelog entry in the same change.**
prevents: "what shipped" being reconstructed from memory during an incident
effort: 1 h · affects: anyone installing · undo: delete the tag
*A tag published before its changelog entry documents every version except the one it released
— observed here.*

## The gate itself

**Write the gate command where a contributor will look.**
prevents: newcomers discovering the required check only when CI bounces the pull request
effort: 1–2 h, mostly wording · affects: everyone who commits · undo: `git revert`
*Copy the exact line out of the CI file. Note which of its targets rewrite the tree.*

**Add `timeout-minutes` to every job.**
prevents: a hung job holding a runner for the six-hour default
effort: 30 min, including reading run history for the value · affects: everyone who merges
undo: `git revert` · *Set it above the observed p95, per job — it is a job-level key.*

**Pin the CI toolchain instead of tracking a moving channel.**
prevents: the gate going red for a toolchain release rather than for the change
effort: 30 min · affects: everyone who commits · undo: `git revert`
*A `rust-toolchain.toml`, `.nvmrc` or equivalent alongside the CI step. Ambient red is how a team
learns to ignore red.*

## Repository posture

**Enable secret scanning and push protection.**
prevents: a committed credential going unnoticed, and the next one being committable at all
effort: 5 min, in the browser · affects: everyone who commits · undo: same toggles
*Some sub-settings are UI-only; the API accepts and discards them.*

**Add a `SECURITY.md` naming a channel that actually notifies someone.**
prevents: a vulnerability report arriving somewhere nobody reads
effort: 30 min · affects: reporters · undo: delete the file
*Do not promise a response time the project cannot keep.*
