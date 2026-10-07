# Release and deploy gates

Sections 4 and 5 of the forge audit, kept apart from `forge-hygiene.md` so an audit of a repository
that publishes and deploys nothing does not load them. The numbering continues from that file, and
`forge-hygiene.md` §0b says which kinds need which half. **Everything here is read-only to discover
and a proposal to change**, the same as there.

## 4. Release and production gates

- **Is the deployed commit knowable?** If nobody can say which SHA is in production, nothing else in
  this section can be verified. Fix that first.
- **Deploy approval**: GitHub Environments support required reviewers, wait timers, and restricted
  branches. If deploys run straight off a merge with no gate, say so — that is a choice worth making
  deliberately rather than by default.
- **No rollback, or an untested one.** Ask when it was last exercised. A rollback path that has never
  been run is a belief.
- **Migrations ordered against deploys** (see `production.md` §4). Ask which runs first and whether
  anything enforces it.
- **No smoke test after deploy** — a pipeline that reports success when the process started, not when
  the change works.
- **Nothing orders the deploy after the gate.** Two workflows on the same trigger are concurrent, not
  sequential, and the deploy is usually the shorter one — so the change is live before the suite that
  validates it has finished. Measured on two repositories: one published a median twenty-two seconds
  ahead of its own CI across every commit that ran both, the other about twenty-five. Neither is a
  race that *sometimes* loses; the ordering is structural. `needs:` in one workflow, or a deploy that
  is a job rather than a second trigger, is the fix — and *"CI runs on every push"* is not the answer
  to *"what runs before users see it?"*
- **The publish never asks whether the commit it is shipping is green.** Distinct from the bullet
  above: there the deploy races the gate, here the gate has already finished and *failed*, and
  nothing reads the result. It appears wherever the tests live in a different workflow from the
  release, because then the release job's `needs:` covers only its own build steps and a red commit
  publishes normally. Four measured in one round: a WebSocket service whose production build fires on
  `push: main` with no reference to its test workflow, whose own `Tests` on `main` ran 14 failure to
  9 success while 12 of 30 merged pull requests carried a failing check; a library shipping wheels to
  a registry on every tag while its default branch had been red for weeks; an image published from a
  failed-CI commit six times in sixty pushes; and a plugin whose release workflow reads no status at
  all. **`needs:` cannot fix this** when the gate is a separate workflow — query the commit's
  check-runs before publishing, or make the check required so the red commit never reaches the branch
  you release from.
- **A publish step that tolerates a version already in the registry.** `--skip-duplicate`,
  `skip-existing: true` and their equivalents turn "this version is already published" from an error
  into a success, so a release where somebody forgot the version bump is a green run that shipped
  nothing, and nobody finds out until a user asks why the fix is missing. Measured on two registries:
  one repository sat six commits past its last tag with its version constant still naming that tag;
  another takes the published version from a literal in the workflow, and a tag with **zero check
  runs** had already diverged from it. The flag exists to make a re-run idempotent, which is worth
  keeping — pair it with an assertion that the version being published is the one the tag names.
- **No tag, release, or changelog**, so "what shipped" is reconstructed from memory during an incident.
- **A tag that exists and does not identify what shipped.** Absence is the easy case; the tag that is
  present and wrong is the one an audit calls fine. Four ways it lies, each measured on a real
  repository: a **version published with no tag at all** — ten of forty-one releases on one registry,
  so the code for those versions is not in the history; **two tags per release** (`1.2.3` and `v1.2.3`)
  that silently diverged, leaving consumers of one pinned to a commit **reachable from no branch**;
  **tags the registry ignores** because they are not valid semver, so "latest" is not the newest tag;
  and a **floating major tag force-pushed before the release is known good**, handing consumers new
  code against an old artifact. Compare the registry's version list against `git tag`, in both
  directions — neither is authoritative alone.
- **A version marker in the tree that disagrees with what shipped.** A tag misidentifies a release
  from outside; this one is read by the software itself, so being wrong changes what users get. Check
  the `VERSION` file, the version constant and the manifest field against the newest tag *and* the
  registry — all three, because the build often takes its version from a fourth place. Measured: a
  constant three releases stale, because the packaging step derived the version from `git describe`
  and ignored the constant it required; and a `VERSION` file containing the literal string `dev`,
  which the project's own installer reads — so every user of the documented one-command install got
  the untagged tip of the default branch, and the upgrade check, guarded by `if VERSION != "dev"`,
  never fired for anyone for twenty-seven months.
- **Release built from a dirty or unpinned toolchain**, so the artifact cannot be reproduced.
- **No freeze or ownership convention** for risky periods, if the team wants one.

## 5. Deploy-time risk — what is true *right now*

Distinct from everything above: those ask whether the pipeline is sound, these ask whether **this
change, at this moment** should go out. Cheap to check, and the ecosystem's incident tooling covers
them precisely because they keep causing outages.

- **Is an incident open on this service?** Shipping during an ongoing incident adds a variable to a
  system somebody is already debugging, and muddles the timeline they will use to diagnose it.
- **Is anyone watching?** An on-call handoff minutes away, or a gap in the rotation, means the change
  lands with nobody who knows about it looking. Deploying into that is a choice, not a default.
- **Has this code hurt before?** The revert and hotfix history already tells you which files are
  incident-prone; a change touching them deserves more care than its diff size suggests. This is the
  highest-value warning available from data every repo already has.
- **Can you see it work?** Not "is there a dashboard" — is there a signal that would *change* if this
  specific thing broke, and does anyone know where it is? Watching after a deploy is worthless if
  nothing observable moves.
- **Does the service shed load and drain gracefully?** Requests dropped mid-deploy are invisible,
  constant, and fixable — and almost nobody checks until a customer reports it.
