#!/usr/bin/env bash
# Prepares a persona review from a tag named review/<persona>/<backend>/<note>.
#
# Reads GITHUB_REF_NAME, validates it, picks the diff base, and writes the diff
# to tmp/diff.patch (tmp/ is gitignored). Writes persona/backend/base/etc. to
# $GITHUB_OUTPUT. Used by .github/workflows/review.yml; also runnable locally:
#
#   GITHUB_REF_NAME=review/quick-sanitycheck/claude/try1 bash .github/scripts/review-prepare.sh
#
# The tag name is attacker-controllable text, so everything parsed from it is
# validated against a strict pattern before it is used anywhere.
#
# Unlike the project this was ported from, Klunki has no snapshot workflow, so
# there is no "tag must not contain snapshot" guard. `review/**` cannot match
# build.yml's `v*` tag filter, and ci.yml has no tag trigger at all.
set -euo pipefail

TAG="${GITHUB_REF_NAME:?GITHUB_REF_NAME is required}"
OUT="${GITHUB_OUTPUT:-/dev/stdout}"
PERSONAS_DIR=".github/review-personas"
IMPLEMENTED_BACKENDS="claude"        # other backends are ideas, not built
MAX_DIFF_BYTES="${REVIEW_MAX_DIFF_BYTES:-200000}"
BASE_BRANCH="main"

fail() { echo "::error::$*" >&2; exit 1; }

# review/<persona>/<backend>/<note...> ; <note> may contain further slashes
IFS=/ read -r prefix persona backend note <<<"$TAG"
[ "$prefix" = "review" ] || fail "tag must start with review/ (got '$TAG')"
[[ "$persona" =~ ^[a-z][a-z0-9-]{1,31}$ ]] || fail "invalid persona in tag: '$persona'"
[[ "$backend" =~ ^[a-z][a-z0-9-]{1,31}$ ]] || fail "invalid backend in tag: '$backend' (expected review/<persona>/<backend>/<note>)"
[ -n "${note:-}" ] || fail "missing <note> in tag (expected review/<persona>/<backend>/<note>)"
[ -f "$PERSONAS_DIR/$persona.md" ] || fail "unknown persona '$persona' (no $PERSONAS_DIR/$persona.md)"

case " $IMPLEMENTED_BACKENDS " in
  *" $backend "*) ;;
  *) fail "backend '$backend' is not implemented in the proof of concept (implemented: $IMPLEMENTED_BACKENDS)" ;;
esac

# Diff base: a commit on a feature branch is compared with origin/main (what
# merging it would change). A commit already contained in main is compared
# with its first parent, so the tag reviews that one commit (for a merge
# commit: everything the merge brought in).
git rev-parse --verify -q "origin/$BASE_BRANCH" >/dev/null || fail "origin/$BASE_BRANCH not found (checkout needs fetch-depth: 0)"
if git merge-base --is-ancestor HEAD "origin/$BASE_BRANCH"; then
  git rev-parse --verify -q 'HEAD^' >/dev/null || fail "HEAD has no parent to compare with"
  base="$(git rev-parse 'HEAD^')"
  range="$base..HEAD"
else
  base="origin/$BASE_BRANCH"
  range="$base...HEAD"
fi

mkdir -p tmp
# Lockfiles, generated l10n Dart files and binary assets (card photos, fonts) are noise; the
# reviewer can still read the sources (pubspec.yaml, ARB files) as files.
git diff --no-color "$range" -- . \
  ':(exclude,glob)**/pubspec.lock' \
  ':(exclude,glob)klunki/lib/l10n/app_localizations*.dart' \
  ':(exclude)klunki/assets/quartett' \
  ':(exclude)klunki/assets/fonts' \
  > tmp/diff.full
full_bytes=$(wc -c < tmp/diff.full | tr -d ' ')
head -c "$MAX_DIFF_BYTES" tmp/diff.full > tmp/diff.patch
rm -f tmp/diff.full

truncated=false; if [ "$full_bytes" -gt "$MAX_DIFF_BYTES" ]; then truncated=true; fi
empty=false;     if [ "$full_bytes" -eq 0 ]; then empty=true; fi

{
  echo "persona=$persona"
  echo "backend=$backend"
  echo "base=$base"
  echo "diff_bytes=$full_bytes"
  echo "truncated=$truncated"
  echo "empty=$empty"
} >> "$OUT"

echo "review: persona=$persona backend=$backend base=$base diff_bytes=$full_bytes truncated=$truncated empty=$empty" >&2
