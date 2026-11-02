#!/usr/bin/env bash
# Tests tool/build_number.sh (KLD-116) on a throw-away git repository in a
# temp directory: dates in UTC, the per-day counter, merges, monotony, the
# limits. Needs only git and bash; changes nothing outside the temp dir.
#
#   tool/build_number_test.sh
set -euo pipefail

script="$(cd "$(dirname "$0")" && pwd)/build_number.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
git init -q -b main "$repo"
cd "$repo"
git config user.name test
git config user.email test@example.invalid
git config commit.gpgsign false

fails=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected $2, got $3"; fails=$((fails + 1)); fi
}
commit() { # date message
  GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit -q --allow-empty -m "$2"
}

commit '2026-11-01T10:00:00+00:00' a
check 'first commit of a day is 01' 2026110101 "$("$script")"

commit '2026-11-02T08:00:00+00:00' b
check 'next day starts at 01' 2026110201 "$("$script")"
first="$(git rev-parse HEAD)"

# 01:30 at +01:00 (Berlin in winter) is 00:30 UTC on 2 November.
commit '2026-11-02T01:30:00+01:00' c
check 'local time zones count in UTC (00:30 UTC, same day)' 2026110202 "$("$script")"

# 23:30 UTC on 2 Nov is 00:30 on 3 Nov in Berlin: still the 2nd.
commit '2026-11-03T00:30:00+01:00' d
check 'a commit after midnight local time but before UTC midnight' 2026110203 "$("$script")"

check 'an older commit keeps its number' 2026110201 "$("$script" "$first")"

# A side branch with commits of the same day, merged into main: only the
# merge counts (first-parent line).
git checkout -q -b side
commit '2026-11-02T23:40:00+00:00' side1
commit '2026-11-02T23:41:00+00:00' side2
git checkout -q main
GIT_AUTHOR_DATE='2026-11-02T23:50:00+00:00' GIT_COMMITTER_DATE='2026-11-02T23:50:00+00:00' \
  git merge -q --no-ff -m merge side
check 'a merge counts once, its branch commits not' 2026110204 "$("$script")"

# Monotonic over a whole sequence of days and commits.
prev=0
mono=ok
for day in 03 03 03 04 10 10; do
  commit "2026-11-${day}T12:00:00+00:00" "m$day"
  n="$("$script")"
  if [ "$n" -le "$prev" ]; then mono="not increasing: $prev then $n"; fi
  prev="$n"
done
check 'increasing along main' ok "$mono"
check 'last of the sequence' 2026111002 "$prev"
check 'below the Android versionCode maximum' yes "$([ "$prev" -lt 2100000000 ] && echo yes || echo no)"

# More than 99 commits on one day: refuse.
for i in $(seq 1 99); do commit "2026-11-20T00:00:$(printf '%02d' $((i % 60)))+00:00" "x$i"; done
check '99 commits on one day is still fine' 2026112099 "$("$script")"
commit '2026-11-20T23:00:00+00:00' x100
if "$script" > /dev/null 2>&1; then r=ran; else r=refused; fi
check 'the 100th commit of a day is refused' refused "$r"

# A shallow clone cannot count: refuse.
git clone -q --depth 1 "file://$repo" "$tmp/shallow"
if (cd "$tmp/shallow" && "$script" > /dev/null 2>&1); then r=ran; else r=refused; fi
check 'a shallow clone is refused' refused "$r"

if [ "$fails" -ne 0 ]; then
  echo "$fails check(s) failed"
  exit 1
fi
echo "all build number checks passed"
