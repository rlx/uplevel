# Commit messages, PR bodies, and release notes

Read this before writing durable text in a repository anyone outside the team can read. `evidence.md`
governs whether that text is *true*; this file governs how long it is and what must not be in it.

**In a public repository a commit message is a publication.** It is permanent, it is not reviewable
after the fact, it is indexed and mirrored within minutes, and it is read by people who cannot ask a
follow-up question. Every clone carries it. That makes two ordinary habits expensive.

**Length is a tax on every future reader.** Someone scanning `git log` to find when a behavior changed
is paying attention per commit. A body that explains the investigation costs them the thing they came
for.

**Derivation is a disclosure.** *How you found it* is the part that cannot be unpublished — the
internal tool you ran, the vendor response you got, the private repository you compared against, the
prior incident, the project's earlier name. None of it is secret in the sense a credential is, which
is exactly why it ships without anyone stopping to think.

---

## The shape

**State what was done. Nothing else.** Concise, accurate, simple. Most changes need only a subject
line; a body earns its place when the subject cannot carry the whole of what was done.

**Context is a separate decision, and it is not yours.** Reasoning, alternatives considered, what this
supersedes, why now — that is context, not what was done. When you think a change is unreadable
without some of it, **say what you would add and ask before adding it.** Add only what is approved.
The default is the shorter message, and an author who wants the reasoning recorded will say so.

The line is easy to test: a sentence describing *the change* stays; a sentence describing *the
thinking, the search, or the session* goes. "Adds a timeout to the health check" is what was done.
"Adds a timeout to the health check because the p95 doubled after the pool change" is context — offer
it, do not assume it.

Match the repository, not this file: read the log before writing (`git log -30 --format='%s'`) and
follow the prevailing form for tense, capitalization, prefixes and length. A convention the log
actually uses outranks any convention you would prefer.

## What does not go in

- **How it was found.** The command that surfaced it, the search, the tool, the agent, the review that
  prompted it. "Found by X" is never load-bearing.
- **Verification narration.** *Proven able to fail, verified against a clean environment, checked
  red-then-green.* Do the work; the record belongs in the working notes.
- **Archaeology.** *This shipped broken because a previous change did Y.* It reads as blame, it dates
  badly, and it tells a reader something they cannot act on.
- **Vendor and API forensics.** *The endpoint returns 200 and silently discards the field.* Useful,
  and it belongs in the notes that stay behind the wall.
- **Internal identifiers.** Ticket keys from a private tracker, internal hostnames, run and resource
  ids, machine paths, the names of people who are not authors.
- **Third parties.** A repository you used as a test subject, and anything you concluded about it.
  Findings about someone else's project are theirs to publish, not yours.

Two tests, in order. **Is this what was done?** If not, it is context — offer it and wait. **Would it
still earn its place if the reader had no idea who wrote it?** If it only makes sense as an account of
your session, it does not go in at all, approved or otherwise.

## Where the detail goes instead

Working notes that are not published — the untracked plan or checklist described in `checklist.md`.
That is where verification records, vendor behavior, and the history of what was wrong belong. Nothing
is lost; it stops being permanent and public.

**A pull request body is held to the same rule** — what was done, as a short list when there are
several things. It is not a place to spend the reviewer's attention on how the work went. Its one
advantage over a commit message is that it stays editable after merge, so it is where approved
context can be added later without rewriting history — and only if the forge is not configured to
copy it into the commit.

## Write the body to a file, not through the shell

A pull request body is prose full of backticks, and a backtick is command substitution. Passing one as
a shell argument runs the contents and publishes the wreckage — the words vanish and what is left
still reads as a sentence, so nothing looks wrong:

```sh
cat > /tmp/body.md <<'BODY'
A field that is `null` inside a `200` is unknown, not absent.
BODY
gh pr create --body-file /tmp/body.md
```

Written as `--body "... `null` inside a `200` ..."` that sentence publishes as *"A field that is
inside a is unknown"*, and the shell reports `command not found: null` after the pull request has
already been created. **Read back what you published**, whatever route you used; the failure is
silent by construction, and a body is durable text held to the same standard as the commit.

## The forge settings that undo all of it

Per-commit discipline is worthless if the merge writes something else into history. Establish what
your forge does *before* trusting the convention:

```sh
gh api repos/{owner}/{repo} --jq '{squash_merge_commit_title, squash_merge_commit_message}'
gh api repos/{owner}/{repo} --jq '{merge_commit_title, merge_commit_message}'
```

- `squash_merge_commit_message: COMMIT_MESSAGES` **concatenates every branch commit body** into one
  commit on the default branch. Ten careful commits become one long one, and the discipline you
  applied per commit bought nothing.
- `PR_BODY` publishes the pull request description verbatim, including anything written for reviewers
  rather than for history.
- `PR_TITLE` with `BLANK` is the tight combination: only the title becomes permanent, and the pull
  request stays a separate, editable surface. **The forge restricts which pairs are valid** — the API
  rejects an unsupported combination rather than silently ignoring it, so read the error.

This is a rung above a hook, in the sense `automation.md` means: it makes the long body *impossible to
publish* rather than *discouraged*. Propose it; never apply it — merge behavior is a team decision.

Auto-generated release notes concatenate pull request titles, so the same discipline applies to titles
whether or not anyone reads them at the time.

## Attribution and trailers

Use the trailer this repository uses, verbatim, and no other. Check what the log actually carries:

```sh
git log -50 --format='%(trailers:only)' | sort -u
```

Git treats any trailing `Token: value` paragraph as trailers, so that list can include a subject-shaped
line from a squashed commit. Read it for which trailers are in use, not as an exact set.

Where a repository forbids a trailer that your own operating instructions require, **say so and let
the maintainer decide** — that conflict is already an invariant in `SKILL.md`. Choosing quietly gets
the contribution rejected for a reason nobody can see.

## When it is already published

Rewriting history is almost never the answer. A force-push is usually blocked by branch protection,
it invalidates every SHA anyone has cited, and it breaks every existing clone. Fix forward:

1. **Edit what is still editable** — pull request bodies and release notes, both mutable after merge.
2. **Change the setting** that will do it again.
3. **Write the convention down** where the next contributor will read it.
4. **If an actual credential was published, rotate it.** It is compromised regardless of what you do
   to the history, and deleting the commit is not remediation.

Only rewrite when the content is genuinely unpublishable — a secret, personal data, a third party's
confidential material — and even then, treat the rewrite as damage control on top of rotation, not
instead of it.

## Automating it

A `commit-msg` hook can reject an over-long body, and like every hook it is bypassable and therefore a
convenience rather than enforcement. The pattern, counting neither the subject, nor comments, nor
trailers:

```sh
n=$(sed '1,2d' "$1" | grep -v '^#' | grep -vE '^[A-Za-z][A-Za-z-]*: ' | grep -c '[^[:space:]]')
[ "$n" -le 6 ] || { echo "commit body is $n lines; the convention is 6 or fewer" >&2; exit 1; }
```

**Prefer the merge setting to the hook.** With squash merge writing only the title, branch commit
bodies never reach the default branch at all, and the hook is guarding a door that no longer opens.
Reach for the hook where every commit lands on the default branch as written — merge commits, or a
rebase workflow.
