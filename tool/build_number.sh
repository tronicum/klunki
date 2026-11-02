#!/usr/bin/env bash
# Prints the build number of a commit (KLD-116): YYYYMMDDNN.
#
#   tool/build_number.sh [REV]     (default HEAD; run anywhere in the repo)
#
# YYYYMMDD is the commit's committer date in UTC. NN (01..99) counts the
# commits of that UTC day on the first-parent line up to and including REV:
# the first merge to main on a day is 01, the next 02, and so on. So the
# number is
#   - deterministic: the same commit always gets the same number (a re-run
#     of CI, or the tag build of a commit main already built, gives the
#     same number for the same app);
#   - increasing along main: a later commit on main has a later date or the
#     same date and a higher NN (as long as committer dates on main do not
#     go backwards, which merges and fast-forwards made now never do).
# It is the iOS CFBundleVersion and the Android versionCode
# (`flutter build … --build-number`). Android's maximum versionCode is
# 2100000000; 2099123199 is the largest this scheme makes.
#
# Builds of other branches (manual workflow runs) count their own
# first-parent line and can repeat a number of main: upload only builds of
# main or of a release tag to the stores (docs/RELEASING.md).
#
# Needs the full history of that day: fails in a shallow clone (CI checks
# out with fetch-depth: 0). Fails with more than 99 commits on one day
# (two builds must never share a number). Read-only: changes nothing.
set -euo pipefail

rev="${1:-HEAD}"

if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  echo "build_number.sh: shallow clone; fetch the full history (actions/checkout: fetch-depth: 0)" >&2
  exit 1
fi

day="$(TZ=UTC git log -1 --format=%cd --date=format-local:%Y%m%d "$rev")"

n=0
while read -r d; do
  [ "$d" = "$day" ] || break
  n=$((n + 1))
done < <(TZ=UTC git log --first-parent --format=%cd --date=format-local:%Y%m%d "$rev")

if [ "$n" -lt 1 ] || [ "$n" -gt 99 ]; then
  echo "build_number.sh: $n commits on $day on the first-parent line (allowed: 1..99)" >&2
  exit 1
fi

printf '%s%02d\n' "$day" "$n"
