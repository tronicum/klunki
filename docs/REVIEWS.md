# Review automation and dependency checks

Three workflows next to CI (`ci.yml`) and the builds (`build.yml`):

| Workflow | Trigger | What it does |
|---|---|---|
| `claude.yml` | `@claude` in an issue, PR comment or PR review, **only by the owner, org members or collaborators** | `@claude review:<persona>[:turns]` on a PR: that persona reviews the PR diff and replies. Any other `@claude …`: Claude does what the comment asks (default action). |
| `review.yml` | pushing a tag `review/<persona>/claude/<note>` | the persona reviews the tagged commit; result in the job summary and as artifact `review-<persona>` |
| `renovate.yml` | manual only (Actions › "Renovate (manual pub check)" › Run workflow) | self-hosted Renovate checks the three `pubspec.yaml` files and opens PRs from `renovate-manual/*` branches |

GitHub Copilot can do the same persona reviews via `@copilot review:<persona>` (`.github/copilot-instructions.md`).
Personas, turn budgets, diff bases and safety notes: [`.github/review-personas/README.md`](../.github/review-personas/README.md).
Every agent (Claude, Copilot, others) reads [`AGENTS.md`](../AGENTS.md) first; `CLAUDE.md` only points there.

## What the maintainer has to set up (one time)

None of this can be done from a pull request; it needs the repository owner.

1. **Claude GitHub App.** Run `claude /install-github-app` in Claude Code inside this repo (or install
   the Claude GitHub App on `tronicum/klunki` by hand). The installer offers to add its own
   `.github/workflows/claude.yml`: **skip that step / don't merge its PR**, this repo already has an
   adapted one (with the owner/collaborator gate and persona routing).
2. **Secret `CLAUDE_CODE_OAUTH_TOKEN`** (Settings › Secrets and variables › Actions). The installer
   creates it; by hand: `claude setup-token`, then add it as a repository secret. It is tied to the
   person who created it. To use an API key instead, add `ANTHROPIC_API_KEY` and switch the `with:`
   input in `claude.yml` and `review.yml` to `anthropic_api_key`.
3. **Secret `RENOVATE_TOKEN`**: a fine-grained personal access token of the repo owner,
   *Repository access: Only select repositories › tronicum/klunki*, with these repository permissions:

   | Permission | Access | Why |
   |---|---|---|
   | Contents | Read and write | push `renovate-manual/*` branches |
   | Pull requests | Read and write | open and update PRs |
   | Issues | Read and write | the Dependency Dashboard issue (`dependencyDashboard: true`) |
   | Metadata | Read | mandatory |
   | Workflows | Read and write | **only** if you enable the Flutter-version custom manager or the github-actions manager (both off; see `.github/renovate-config.js`) |

   A classic PAT works too: scope `repo` (plus `workflow` for the same optional case). Give it an
   expiry date and renew it when the run starts failing with 401.
4. **Copilot code review (optional).** If wanted: enable Copilot for the repository (Settings ›
   Copilot: code review and the Copilot coding agent) so that `@copilot review:<persona>` on a PR gets
   an answer, and/or add Copilot as a reviewer. No secret is involved.
5. **Recommended: tag ruleset.** Settings › Rules › Rulesets › New tag ruleset for `review/**`,
   restricted to maintainers (creation needs write access anyway; the ruleset makes it explicit).
6. **Recommended:** Settings › Actions › General › "Fork pull request workflows from outside
   collaborators": *Require approval for all outside collaborators*.

Without these, nothing breaks: `claude.yml` and `review.yml` fail at the Claude step (missing token),
`renovate.yml` fails at start (missing token); CI and builds are unaffected.

## How to trigger

- **Persona review on a PR:** comment `@claude review:game-rules` (or `security`, `l10n`, `kid-ux`,
  `testing`, `architect`, `docs`, `devops`, `sre`, `quick-sanitycheck`); more turns for one run:
  `@claude review:security:35` (max 50).
- **Free-form Claude:** `@claude please …` in an issue or PR comment (owner/collaborators only).
- **Copilot instead:** `@copilot review:l10n` on a PR.
- **Review any commit:** `git tag review/l10n/claude/try1 <commit> && git push origin review/l10n/claude/try1`;
  delete afterwards with `git push origin :refs/tags/review/l10n/claude/try1 && git tag -d review/l10n/claude/try1`.
- **Dependency check:** Actions › "Renovate (manual pub check)" › Run workflow (log level `debug` if a
  run misbehaves). Major updates wait for a tick in the Dependency Dashboard issue.

## Renovate: pub and Flutter notes

- Manager `pub` only (`enabledManagers: ['pub']`): `klunki/pubspec.yaml`,
  `packages/klunki_engine/pubspec.yaml`, `packages/klunki_net/pubspec.yaml`. Path and SDK
  dependencies are skipped; the `environment:` SDK constraints are disabled on purpose.
- `pubspec.lock` is updated by running `flutter pub upgrade <pkg>` (app) or `dart pub upgrade <pkg>`
  (packages) inside Renovate's container, which installs Flutter/Dart on the GitHub runner for that.
  `constraints` in the config pins them to the CI versions (Flutter 3.47.8, Dart 3.13.7): keep it in
  sync with `FLUTTER_VERSION`. If the lockfile update fails, the PR says "artifact update problem";
  then run `flutter pub get` in the PR branch by hand. Not verified until the first run.
- `rangeStrategy: 'bump'`: caret ranges get a new lower bound together with the lockfile; exact pins
  stay exact.
- The Flutter SDK version itself: Renovate has a `flutter-version` datasource. A regex custom manager
  for `FLUTTER_VERSION` in `ci.yml`/`build.yml` is defined in the config but inactive; enabling it needs
  `'custom.regex'` in `enabledManagers` and a token with the Workflows permission, and
  `docs/BUILDING.md` plus `constraints` still need a hand edit.
- A new **dependency** is never added by Renovate; new packages still need the maintainer's OK
  (AGENTS.md).
