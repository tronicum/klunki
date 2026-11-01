/**
 * Self-hosted Renovate config for the manual "check for pub updates" workflow
 * (.github/workflows/renovate.yml). Not the same as a repo's renovate.json:
 * this is the "global" config passed via `configurationFile` to
 * renovatebot/github-action, which is why it lists `repositories` and
 * disables onboarding (no repo-facing renovate.json required).
 *
 * pub and pubspec.lock
 * --------------------
 * Renovate's `pub` manager reads every `pubspec.yaml` (here: klunki/,
 * packages/klunki_engine/, packages/klunki_net/) and looks packages up on
 * pub.dev. Path dependencies (klunki_engine, klunki_net) and SDK packages
 * (flutter, flutter_localizations, flutter_test, integration_test) are
 * skipped by the manager itself.
 *
 * The committed pubspec.lock next to each pubspec is NOT edited by Renovate
 * directly: it runs the real tool (`flutter pub upgrade <pkg>` for a pubspec
 * with `sdk: flutter`, `dart pub upgrade <pkg>` otherwise). So the lockfile
 * can only be updated when Renovate can execute Flutter/Dart. The
 * renovatebot/github-action runs the default (slim) Renovate image, which
 * installs such tools on demand (containerbase, binarySource "install", the
 * default; the "full" image sets "global" instead): it downloads the
 * Flutter SDK inside the Renovate container on the GitHub runner, not on
 * anybody's machine. Without that (e.g. binarySource
 * "global" with no Flutter on PATH) Renovate still opens the PR, but with an
 * "artifact update problem" note and a stale pubspec.lock (CI's
 * `flutter pub get` then resolves anew without committing; fix the branch
 * with a local `flutter pub get`). `constraints` below pins the tool
 * versions to the ones CI uses, so the lockfile is resolved exactly like in
 * ci.yml instead of with whatever newest SDK satisfies `sdk: ^3.13.7`.
 * This path is expected to work but unverified until the first run: check
 * the run log for "artifact" errors.
 *
 * Flutter SDK version
 * -------------------
 * Renovate has a `flutter-version` datasource (Flutter releases from
 * github.com/flutter/flutter). The Flutter version is pinned in
 * ci.yml/build.yml (`FLUTTER_VERSION: '3.47.8'`) and docs/BUILDING.md, so a
 * regex custom manager can bump the two workflows together. It is defined
 * below but NOT enabled: enabling it means adding 'custom.regex' to
 * enabledManagers, and a PR that edits .github/workflows/* needs a token
 * with the "workflow" scope (classic PAT) / "Workflows: read and write"
 * (fine-grained PAT). docs/BUILDING.md then still needs a hand edit.
 * The `dart`/`flutter` SDK constraints in the pubspecs' `environment:` are
 * disabled too: they move together with FLUTTER_VERSION, by hand.
 *
 * The github-actions manager is off for the same token-scope reason (and
 * every action is pinned to a SHA on purpose).
 */
module.exports = {
  platform: 'github',
  repositories: ['tronicum/klunki'],

  // Single-config-file mode: skip the onboarding PR and don't require a
  // repo-level renovate.json; this file is the only config that matters.
  onboarding: false,
  requireConfig: 'optional',

  // Distinct prefix so this doesn't collide with the official Renovate
  // GitHub App if that's ever installed on the repo too.
  branchPrefix: 'renovate-manual/',

  // Only pub (pubspec.yaml + pubspec.lock): a token with contents and pull
  // request write access is enough. Add 'custom.regex' to activate the
  // Flutter version manager below (needs the workflow scope).
  enabledManagers: ['pub'],

  // Resolve pubspec.lock with the toolchain CI uses (ci.yml FLUTTER_VERSION).
  // Keep in sync when FLUTTER_VERSION changes.
  constraints: {
    flutter: '3.47.8',
    dart: '3.13.7',
  },

  // "bump": raise the lower bound of a caret range (^2.5.6 -> ^2.5.7) and
  // update pubspec.lock in the same PR, so pubspec.yaml documents the
  // version actually tested. Exact pins (bonsoir 7.1.5, camera 0.12.1, ...)
  // stay exact pins. ("update-lockfile" is not offered by the pub manager.)
  rangeStrategy: 'bump',

  // Lockfile-only refreshes (`flutter pub upgrade` of everything) are off:
  // they would change many transitive packages at once. Turn on for a
  // deliberate refresh run.
  lockFileMaintenance: { enabled: false },

  packageRules: [
    {
      // environment: sdk / flutter constraints in the pubspecs move by hand
      // together with FLUTTER_VERSION in the workflows.
      matchManagers: ['pub'],
      matchDepNames: ['dart', 'flutter'],
      enabled: false,
    },
    {
      // Major updates wait for a tick on the Dependency Dashboard issue
      // instead of opening a PR right away: they usually need code changes.
      matchUpdateTypes: ['major'],
      dependencyDashboardApproval: true,
    },
  ],

  // Proposed, inactive until 'custom.regex' is in enabledManagers.
  customManagers: [
    {
      customType: 'regex',
      description: 'Flutter version pinned in the CI workflows',
      managerFilePatterns: ['/^\\.github/workflows/(ci|build)\\.ya?ml$/'],
      matchStrings: ["FLUTTER_VERSION:\\s*'(?<currentValue>\\d+\\.\\d+\\.\\d+)'"],
      depNameTemplate: 'flutter',
      datasourceTemplate: 'flutter-version',
    },
  ],

  dependencyDashboard: true,
};
