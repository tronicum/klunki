# Persona reviews

Three ways to have one of these personas review a change. All are proofs of concept. One-time setup
for the maintainer: `docs/REVIEWS.md`.

## 1. Mention: `@claude review:<persona>`

Comment on a pull request (or in a PR review comment / review body):

    @claude review:game-rules

`.github/workflows/claude.yml` detects the `review:<persona>` mention, fetches the PR's diff
(`gh pr diff`, capped at 200,000 bytes) and has that persona review it. The result is posted back as
Claude's reply on the PR. An unknown persona name, or an `@claude` mention without `review:`, falls
back to Claude's normal free-form behavior.

**Turn budget**: each persona has a default `--max-turns` (`.github/scripts/detect-persona-mention.sh`),
sized to how much context-reading it typically needs:

| Persona | Default | Persona | Default |
|---|---|---|---|
| `quick-sanitycheck` | 8 | `architect` | 20 |
| `docs` | 15 | `sre` | 20 |
| `devops` | 15 | `l10n` | 20 |
| `kid-ux` | 15 | `game-rules` | 25 |
| `testing` | 20 | `security` | 25 |

Append `:<N>` to override it for one run, e.g. `@claude review:security:35`, capped at 50. A request
outside 1–50 is ignored with a warning in the run's log (the default is used).

## 2. Tag: `review/<persona>/<backend>/<note>`

A tag matching that pattern starts a review of the commit it points at
(`.github/workflows/review.yml`):

    git tag review/quick-sanitycheck/claude/try1
    git push origin review/quick-sanitycheck/claude/try1

The result appears in the workflow run's job summary and as artifact `review-<persona>` (`review.md`
plus `review-meta.json`, kept 30 days). Useful for reviewing an arbitrary commit (not only an open PR).
Tag creation needs write access, so only maintainers can trigger it.

## 3. Mention Copilot: `@copilot review:<persona>`

Comment on a pull request:

    @copilot review:l10n

GitHub Copilot picks this up and reviews the PR as that persona. No workflow or secret is involved:
`.github/copilot-instructions.md` tells Copilot to read `_common.md` plus the persona file and answer in
the same format. Availability depends on the GitHub Copilot settings of the account and repository.

## Personas

| Persona | Looks at |
|---|---|
| `quick-sanitycheck` | fast pass: obvious bugs, missing tests, leftovers, missing ARB keys |
| `architect` | engine/net/app boundaries, determinism, the GameSpec/GameShell patterns, transport contract |
| `security` | hidden-info leaks (cheating), commitments, untrusted network input, relay, secrets, workflows |
| `game-rules` | rule correctness, edge cases, rules version bumps, fairness, secrecy of views |
| `testing` | test coverage for rules, screens and flows, fingerprint goldens, flaky timing |
| `l10n` | 7 locales, placeholders, player names as data, gendered verbs in ar, RTL, fonts |
| `kid-ux` | families and kids: clear German, no jargon, whose turn, touch targets, small phones |
| `docs` | which docs, task cards and BOARD rows need an update; stale facts |
| `devops` | CI and build workflows, store builds, signing, PWA build, reproducibility |
| `sre` | network failure modes, reconnect, version skew, relay operations |

Each is one file here; `_common.md` (output format and rules) applies to all of them. Persona names
(in the tag, or after `review:`) are lowercase letters, digits and `-`, and must match a file name here.
The `customer` persona of the project this setup was ported from became `kid-ux`.

## Backends

| Backend  | Status |
|----------|--------|
| `claude` | Implemented, both flows. Claude Code Action with read-only tools (`Read,Grep,Glob`; the tag flow also allows `Write` for `tmp/review.md`, since there is no PR thread to reply on). |

Any other backend name makes the tag-triggered run fail early with a clear message. The mention flow
has no `<backend>` segment.

## Diff base

**Tag flow:** a commit that is not yet in `main` is compared with `origin/main` (what merging it would
change); a commit already in `main` is compared with its first parent (that one commit, or everything a
merge commit brought in). `pubspec.lock` files, the generated `app_localizations*.dart`, card photos
and fonts are left out of the diff.
**Mention flow:** the PR's diff against its own base branch (`gh pr diff`), no exclusions.
Both cap the diff at 200,000 bytes and say so in the review if it was truncated.

## Delete a trial tag

    git push origin :refs/tags/review/quick-sanitycheck/claude/try1
    git tag -d review/quick-sanitycheck/claude/try1

## Safety notes

**Tag flow:**
- Tag creation needs write access, so only maintainers can trigger a review.
- The diff, commit messages and repository files are untrusted input to the model; every persona is
  told to treat them as data. The model has no shell and no GitHub API access.
- `review/**` cannot match `build.yml`'s `v*` tag filter and `ci.yml` has no tag trigger, so a review
  tag starts no build. (The ported setup also rejected tags containing `snapshot` because of a
  snapshot workflow; Klunki has none, so that guard is gone.)

**Mention flow:**
- `claude.yml`'s job `if:` restricts every `@claude` mention (persona or default) to an
  `author_association` of `OWNER`, `MEMBER` or `COLLABORATOR`. This is a public repository: without
  the gate any GitHub user could comment `@claude ...` and start a run against the maintainer's plan.
- Persona mode is narrowly scoped (`--allowedTools "Read,Grep,Glob"`: no `Bash`, no `Write`), and the
  diff/comment/commit text is treated as data, never instructions.
- `author_association` is evaluated at comment time: a removed collaborator loses access at once. A
  pull request from a fork is evaluated against this repository's association, so a drive-by
  contributor cannot trigger runs.
