# Finding the real gate

The goal is a short list of commands that **you have run** and that **actually pass** on a clean tree.
Everything else is decoration.

## Order of authority

Search in this order and stop at the first that gives a real answer. Later sources describe intent;
earlier ones describe what is enforced.

**A shallow clone silently answers "nothing has ever gone wrong here."** `git clone --depth 1` — the
default for CI checkouts, container builds, and anyone cloning a large repository quickly — leaves one
commit. Every history question then returns zero: zero reverts, zero hotfixes, zero incidents, no
contributor count, no cadence. It reads exactly like a healthy repository and it is an artifact of how
the clone was made. Check before trusting any of it:

```sh
git rev-list --count HEAD          # 1, or suspiciously round, means shallow
git rev-parse --is-shallow-repository
git fetch --unshallow --filter=blob:none    # or --depth 3000 if the full history is large
```

This is the highest-consequence measurement error available, because *what has already gone wrong
here* is one of the three questions the whole audit is aimed by. Getting a false clean there aims
everything downstream at the wrong thing.

0. **Confirm the gate is even in this repository.** On large projects it frequently is not, and every
   later step is then measuring the wrong thing. Four shapes seen repeatedly:
   - **A sibling repo.** The workflow calls a reusable pipeline, or a bot mirrors PRs elsewhere. Follow
     `uses: <org>/<repo>/.github/workflows/…` and read it — one audit found the sole required check was
     disarmed by a regex in a *different* repository.
   - **A merge bot.** `bors`, `homu`, a merge queue, or an `@bot r+` convention. Then GitHub required
     checks are legitimately **absent as a forge rule** while being strictly enforced elsewhere, and
     GitHub review objects are empty because approval happens in comments.
   - **A second CI system.** `.gitlab-ci.yml`, Buildkite, Jenkins, or an internal mirror. Check whether
     it is namespace- or fork-gated; if it cannot run from this repo, that is **unsupported here**.
   - **A mirroring bot.** Zero `pull_request:` triggers can still mean full PR coverage, if a bot pushes
     PR heads to branches the workflows *do* trigger on. Check before reporting an absence.

   A repository with hundreds of thousands of commits and three workflow files is not under-gated; it
   is gated somewhere you have not looked yet.

1. **CI config** — `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/`,
   `azure-pipelines.yml`.
   Whatever blocks a merge *is* the gate, whatever the README claims.
2. **Hooks** — `.pre-commit-config.yaml`, `.husky/`, `lefthook.yml`, `.git/hooks/` (local, unshared —
   note it, since a teammate will not have it).
3. **Task runner** — `Makefile`, `justfile`, `Taskfile.yml`, `package.json` scripts, `scripts/`, `*.sh`
   at the root. A repo-local `ci.sh`/`check.sh` is usually the intended one-command gate.
4. **Ecosystem default** — only if nothing above exists.
5. **The user** — for anything that needs hardware, credentials, or judgment.

## Ecosystem defaults (verify, do not assume)

| stack | test | lint / format | types | build |
|---|---|---|---|---|
| Node/TS | `npm test`, `pnpm test`, `vitest`, `jest` | `eslint .`, `prettier --check .`, `biome check` | `tsc --noEmit` | `npm run build` |
| Python | `pytest`, `python -m unittest` | `ruff check`, `black --check`, `flake8` | `mypy`, `pyright` | `python -m build` |
| Go | `go test ./...` | `gofmt -l .`, `golangci-lint run` | (compiler) | `go build ./...` |
| Rust | `cargo test` | `cargo fmt --check`, `cargo clippy -- -D warnings` | (compiler) | `cargo build` |
| Java/Kotlin | `./gradlew test`, `mvn test` | `spotless:check`, `ktlint` | (compiler) | `./gradlew build` |
| Ruby | `bundle exec rspec` | `rubocop` | `srb tc` | — |

## Questions the gate must answer

Record the answer to each; the gaps are the valuable part.

- **What is the one command?** If there are five, is there a wrapper — or should there be?
- **How long does it take?** A gate nobody runs because it takes 20 minutes is not a gate. Note the
  fast subset and the slow full run separately.
- **What does it NOT cover?** This is the highest-value line in the whole document. Common holes:
  - unit tests pass but no integration or end-to-end test ran
  - the gate never exercises the code path a real request takes
  - migrations are never applied, or never applied to a realistic dataset
  - generated files (lockfile, schema, client, API spec) are not regenerated or verified
  - it runs on one runtime/OS/architecture and ships on another
  - nothing checks config: a missing environment variable is found in production, at first use
  - nothing scans for secrets, and nothing audits dependencies
- **What does prose require that CI does not run?** Grep the docs for imperatives — "run X after
  every Y", "always Z before committing". A rule that lives only in a document is enforced by nobody;
  it belongs in the gate (or in CI). This gap is usually where the project's real standard hides.
- **Do the documented commands still work?** Paths rot: tool versions move, services get renamed,
  scripts are relocated, endpoints change. Run what the README claims before you copy it forward.
- **What must be regenerated by hand** after certain changes, and after which changes exactly?
- **Is there a version/build marker** — a canary, cache key, schema version, migration id — that must be
  bumped alongside a change so a stale artifact is detectable? These exist precisely because someone
  once shipped a fix that silently did not take effect.
- **What needs credentials, a running dependency, or money**, and therefore cannot be in the automatic
  gate? Write down how to run it and when it is required (before a release, before touching a schema).
- **What does the gate need running to pass?** Database, message broker, cache, third-party sandbox.
  If integration tests need `docker compose up` first, that is part of the gate and belongs in the
  document — a suite that silently skips when its dependency is absent reports green having tested
  nothing. Check explicitly for skip-on-missing-service behavior; it is common and invisible.

## Toolchain preflight — do this before anything else

**Do not assume the machine can build the repository.** Often it cannot, and that is ordinary rather
than a failure on your part: a package manager, a compiler, a vendored toolchain, `node_modules` or a
container runtime is missing, and installing it is rarely what the user asked for. Self-contained
toolchains fare best; anything with an install step usually does not.

Run the preflight **first**, because this decides how much of the audit is verifiable at all. When the
gate cannot run, everything downstream degrades to `unverified` — and a report that does not say so
plainly has quietly stopped being worth reading. `evidence.md` covers what to do once you
know.

**Look in every component, not just the root.** A polyglot or monorepo declares per part, and a
root-only check silently finds nothing: one audited repository had *no root `package.json` at all* —
Go declared in `go.mod`, pnpm in `web/package.json`. Enumerate before reading:

```sh
find . -maxdepth 3 \( -name package.json -o -name go.mod -o -name pyproject.toml \
  -o -name Gemfile -o -name Cargo.toml -o -name '.tool-versions' -o -name '.nvmrc' \) \
  -not -path '*/node_modules/*' -not -path '*/vendor/*'
```

On a monorepo this lists every workspace — twenty or more is common — and most declare nothing.
Only the manifests
carrying `packageManager`, `engines`, or a language version matter — filter to those:

```sh
grep -l '"packageManager"\|"engines"' $(find . -maxdepth 3 -name package.json \
  -not -path '*/node_modules/*') 2>/dev/null
```

Each component can pin a different toolchain, and the gate may need all of them. "No JS toolchain
declared" is a claim about the root directory, not about the repository.

Read the repo's own declarations — never guess a version:

| source | declares |
|---|---|
| `package.json` → `engines`, `packageManager` | node, and the **exact** package manager + version |
| `.nvmrc`, `.node-version`, `.tool-versions`, `mise.toml` | pinned runtimes |
| `go.mod` → `go <version>` | minimum Go |
| `pyproject.toml` → `requires-python`; `.python-version` | Python |
| `rust-toolchain.toml`, `Gemfile` → `ruby`, `.ruby-version` | Rust, Ruby |
| the CI workflow's `setup-*` steps and `env:` version pins | what CI actually uses — the authority |

**A floating toolchain in CI makes the gate non-deterministic, which is a different finding from an
unreproducible artifact.** An action pinned to a moving channel — `rust-toolchain@stable`,
`setup-go@latest`, an unpinned linter — means the lint and type rules change under the project without
a commit. The gate then goes red for a toolchain release rather than for the change, contributors
learn that red is ambient, and the signal is spent. Look for a `rust-toolchain.toml`, `.nvmrc`,
`.python-version` or equivalent alongside the CI step; where CI floats and the repository pins
nothing, say so — it is cheap to fix and it is upstream of trusting any other check.

### Resolve the tool *inside the repository*, or the comparison is meaningless

**Run every version check with the repository root as the working directory.** In the JS ecosystem —
and anywhere mise, asdf, direnv, pyenv, or rbenv is in play — the toolchain is a property of the
directory, not of the machine, and the same shell gives two different answers:

```sh
cd /tmp && yarn --version        # the global install
cd repo && yarn --version        # the version this repo actually uses — often a different major
```

Repos routinely **vendor** their package manager and delegate to it: `.yarnrc.yml` with `yarnPath:`
pointing at a committed `.yarn/releases/yarn-*.cjs`, a corepack shim honoring `packageManager`, a
`.tool-versions` shim. Yarn Classic reads `yarnPath` and hands over to the vendored binary, so a
machine with "only yarn 1" runs yarn 4 inside such a repo without anything being installed. **Check for
these before concluding a tool is missing** — `.yarnrc.yml`, `.yarn/releases/`, `.tool-versions`,
`.mise.toml`, `.envrc`.

**A global package manager reporting itself current is not evidence that it satisfies the project's
pin.** The two can be unrelated: yarn's npm `latest` dist-tag is pinned to the 1.x line and stays
there — yarn 2 and later are published as `@yarnpkg/cli-dist`, a different package — so
`npm view yarn version`,
`npm outdated -g`, and `brew upgrade` all report "up to date" on a machine four majors behind what the
repo pins. Only the project's declaration, and the tool as resolved in the project's directory, count.

Then classify each:

- **satisfied** — proceed; the gate is runnable and the hard rule applies in full.
- **missing** — absent, with no vendored release and no shim to resolve it.
- **mismatched** — resolves in-repo, but to the wrong major. The dangerous one: `yarn install` with
  yarn 1 against a yarn-4 lockfile does not fail cleanly, it produces a wrong tree.

**A missing or mismatched toolchain is a finding, not a silent excuse.** Say it in the report, by
name, with the version the repo wants and the version that resolved — and treat it as one of the
"could not verify" lines, never as grounds for reporting a gate you never ran as though you had.
Equally: **do not report a mismatch you measured from outside the repo.** That is a false alarm about
someone's project, and it is the exact error this section exists to prevent.

### Offer to install, and say what it costs

When something is missing, **suggest the install and give the exact command**, matched to how the repo
pins it. Do not run it unasked — installing a runtime changes the user's machine, is outside the
repository you were pointed at, and is exactly the kind of thing this skill asks permission for.

| missing | suggest |
|---|---|
| a pinned package manager (yarn 2+, pnpm) | `corepack enable` — it reads `packageManager` and installs the exact pinned version. Try this first; it fixes most mismatches. If `corepack` is not found, it is not bundled with that Node (true from Node 25 as of 2026-08); then it is `npm i -g corepack && corepack enable`. |
| node at a pinned version | `nvm install` / `fnm use --install-if-missing` (reads `.nvmrc`), or `mise install` |
| Go | `mise use -g go@<version>`, `brew install go`, or the tarball from go.dev |
| Python | `uv python install <version>`, `pyenv install`, or `mise install` |
| Rust, Ruby | `rustup toolchain install`, `rbenv install` |
| any of the above, uniformly | `mise install` if `.tool-versions`/`mise.toml` exists — one command, repo-pinned versions |
| a local service the gate needs | `docker compose up -d <service>` from the repo's own compose file |

Prefer the version manager the repo already commits config for. Installing a *different* one is a
change to the user's environment they did not ask for, and it will drift from CI.

If the user declines, or the install is not practical, that is a legitimate outcome — continue the
audit, run every check that does not need the missing tool (workflow reading, git archaeology, the
absence audit, and the hazard inventory all work fine without a toolchain), and mark the gate section
`unverified — needs <tool> <version>`. **Say which parts of the report that weakens.** A report whose
static half is verified and whose gate half is explicitly unverified is honest and useful; one that
does not distinguish them is neither.

## Verifying — safely

**Read every command before you run it.** Names lie: a target called `test` or `check` can seed a
database, hit staging, deploy, or call a paid API. Open the script or task definition first and look
for network calls, credential reads, datastore writes, container orchestration, and environment names.

**The sharpest case is a name promising a read while the body writes.** These are common enough to
look for by default, and they are dangerous precisely because you reach for them to be careful:

- A `fmtcheck` target whose script runs the formatter's *write* mode and diffs the result, so
  "checking" reformats your working tree.
- A `check-*` script for a generated file that regenerates it in place on mismatch — a fixer wearing a
  checker's name. Read its logic and compare by hand instead, or you have silently accepted the
  machine's answer to the question you were asking.
- A gate target that downloads its own tooling, or runs a dependency-tidy step that rewrites the
  lockfile as a side effect of "checking".
- An `apply`/`sync` helper that overwrites a config in place, sometimes keyed off an environment
  variable that would point it at the real repository if it were ever exported.

When a target writes, use the read-only form instead — the formatter's list mode, a hand comparison,
the underlying subcommand — and say in your report that you substituted it and why. Then, before the
next thing, `git status` to prove nothing changed.

**And check the inverse: a target that cannot fail.** A generated-file check that silently skips when
its generator is absent, a suite that reports success on the tests it could still collect, a lint step
whose matcher no longer matches anything. These pass, cost nothing, and prove nothing. If a check has
never been observed failing, it is not yet evidence — see `evidence.md`.

Order of attempt, stopping at the first that cannot be run safely:

1. Read-only and local (formatters in check mode, type checks, unit tests) — run these.
2. Needs a local service (`docker compose up` first) — run if the compose file is self-contained and
   the ports are free; note what it starts and stop it afterwards.
3. Needs credentials, a shared environment, or money — **do not run.** Record as
   `— unverified, needs X`. This is not a failure of discovery; it is the correct outcome.
4. The toolchain to run it is missing or mismatched — **do not improvise a substitute.** Offer the
   install (above). Until it is installed, record as `— unverified, needs <tool> <version>`. Never
   swap in a neighboring command because it happens to run: `npm test` in a yarn-4 monorepo, or
   `go test ./...` where CI runs a driver matrix, tests something other than the gate and reports it
   under the gate's name.

Run the gate on a clean tree before writing it down. Then, if cheap, confirm it can **fail**: a gate
that passes on a deliberately broken tree is not measuring anything. Revert the deliberate break
immediately and verify with `git status` that nothing is left behind. Note the runtime you observed.

## Clean up after verifying — and offer, don't assume

**Verifying a gate is not free, and the cost is invisible until someone runs out of disk.** A single
monorepo install can be several gigabytes; a docker-based integration suite leaves images and volumes
behind. Record what you created and hand the user the choice.

1. **Look before you install.** Note whether `node_modules`, `.venv`, `target/`, `vendor/`, a
   package-manager cache, or the relevant containers already existed. This is the only moment the
   distinction is cheap to establish, and everything below depends on it.
2. **Report the cost with the result.** "The gate passes — 4076 tests in 43s. Verifying it created
   3.4 GB of `node_modules` and an 807 MB package-manager cache." One sentence, in the same reply.
3. **Offer to remove it**, and name what you would remove. Regenerable artifacts are the easy yes; say
   roughly what re-creating them would cost so the answer is informed.
4. **Only remove what you created.** A pre-existing install is the user's working environment — deleting
   it is a destructive act against something you did not make. When in doubt, leave it and say so.
5. **Machine-wide caches are reported, not removed.** `~/go/pkg/mod` and the Go build cache, the pip,
   npm, and Cargo registry caches are shared across every project on the machine, so "what you created"
   cannot be separated from what was already there — one audit grew a Go build cache from 929 MB to
   4.0 GB, and `go clean -cache` would have deleted the user's 929 MB too. Say the size you added, note
   that the tool garbage-collects its own cache, and leave it unless asked. Repo-local artifacts
   (`node_modules`, `.venv`, `target/`, a repo-local package-manager cache) are the ones you offer to
   delete, because there the attribution is clean.
6. **Never delete anything the repo tracks.** Vendored package-manager releases (`.yarn/releases/`),
   committed patches, and checked-in fixtures live beside the artifacts and are not artifacts. Confirm
   with `git check-ignore` before removing, and re-check `git status` in the repo afterwards to prove
   nothing tracked moved.
7. **Stop what you started.** Containers, compose stacks, background servers, port-forwards — leaving
   one running is residue that also holds a port.
8. **Clean up last, and measure at that point.** Cleaning and then running one more check puts the
   residue straight back, and your report is wrong the moment it is written — build directories,
   caches and `__pycache__` all reappear from a single verification run. Do it after the final
   command, then measure, then report. One audit tidied 61 cache directories and a later check
   recreated 51 of them, so the reported figure was false on arrival.
