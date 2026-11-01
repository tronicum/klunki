# KLD-104 — AGENTS.md and persona review automation

- **ID:** `KLD-104`
- **Title:** One reference file for every coding agent; `@claude review:<persona>` reviews, review tags, manual Renovate
- **Milestone:** infrastructure
- **Status:** DONE (🧑 maintainer setup pending: Claude GitHub App, secrets; see `docs/REVIEWS.md`)
- **Depends on:** KLD-070 (CI)
- **Touched paths:**
  - `AGENTS.md`, `CLAUDE.md` (points to AGENTS.md), `.github/copilot-instructions.md`
  - `.github/review-personas/**` (architect, security, testing, docs, quick-sanitycheck, devops, sre,
    game-rules, l10n, kid-ux; `_common.md`, `README.md`)
  - `.github/scripts/{detect-persona-mention,review-prepare}.sh`
  - `.github/workflows/{claude,review,renovate}.yml`, `.github/renovate-config.js`
  - `docs/REVIEWS.md`, `docs/BUILDING.md`, `.gitignore`

## Goal
Any agent (Claude Code, Copilot, others) gets the repo's conventions from one file, and the maintainer
can ask for a focused review by a persona on a pull request or on any commit.

## What it does
- **`AGENTS.md`:** what Klunki is, game ids and titles, repo layout, build/test/screenshot commands,
  conventions (task cards, rules versions, hidden information, l10n, player names, German wording,
  commits) and agent rules. `CLAUDE.md` only points to it.
- **`claude.yml`:** `@claude` in an issue, PR comment or review, only by the owner, org members or
  collaborators. `@claude review:<persona>[:turns]` runs that persona on the PR diff; anything else is
  a free-form request.
- **`review.yml`:** pushing a tag `review/<persona>/claude/<note>` reviews the tagged commit (job
  summary + artifact).
- **`renovate.yml`:** manual only (`workflow_dispatch`), self-hosted Renovate for the `pub` manager on
  the three `pubspec.yaml` files.
- None of the three runs on a branch push; CI (`ci.yml`) and builds (`build.yml`) are unchanged.

## Acceptance criteria
- [x] AGENTS.md matches the build/test commands after the batch 2 merge (checked 2026-11-01).
- [x] Workflows trigger only on comments, review tags or a manual run.
- [ ] 🧑 Claude GitHub App installed, `CLAUDE_CODE_OAUTH_TOKEN` and `RENOVATE_TOKEN` set
      (steps in `docs/REVIEWS.md`); until then the Claude and Renovate jobs fail at start, nothing else breaks.
- [ ] First real `@claude review:<persona>` run and first Renovate run checked.
