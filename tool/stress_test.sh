#!/usr/bin/env bash
# Runs a test command repeatedly under load and counts passes (KLD-109).
# Reproduces the "passes alone, fails on a busy machine" network/live-UI
# flakes, and proves a fix.
#
#   tool/stress_test.sh [-n LOOPS] [-b BURNERS] [-f AWAKE:FROZEN] [-l LOGDIR] -- <command...>
#
#   -n  runs (default 10)
#   -b  CPU burners, `yes > /dev/null` (default 2x the core count; 0 for none)
#   -f  let the command's processes run AWAKE s, then freeze them (SIGSTOP)
#       for FROZEN s, then continue them (SIGCONT), and so on: like a machine
#       that sleeps or a process that gets no CPU, every timer fires late and
#       every unread message waits. Plain CPU burners rarely break the
#       network tests; this does (KLD-109: -f 3:12 for the Flutter files,
#       -f 6:3 for klunki_net)
#   -l  where the logs of failing runs are kept (default: a fresh mktemp dir)
#
# Examples (from the repo root; the command runs in the current directory):
#   tool/stress_test.sh -n 10 -- bash -c 'cd packages/klunki_net && dart test -j 8'
#   tool/stress_test.sh -n 5 -b 0 -f 3:12 -- bash -c 'cd klunki && flutter test -j 8 test/ui/pairing/relay_test.dart'
#
# Everything it starts is stopped on exit, also on Ctrl+C (frozen processes
# are continued first). Nothing is installed. On macOS `caffeinate` keeps the
# machine awake meanwhile: a real sleep freezes everything for minutes.
set -u

loops=10
burners=""
freeze=""
logdir=""
while [ $# -gt 0 ]; do
  case "$1" in
    -n) loops="$2"; shift 2 ;;
    -b) burners="$2"; shift 2 ;;
    -f) freeze="$2"; shift 2 ;;
    -l) logdir="$2"; shift 2 ;;
    --) shift; break ;;
    *) echo "usage: $0 [-n LOOPS] [-b BURNERS] [-f AWAKE:FROZEN] [-l LOGDIR] -- <command...>" >&2; exit 2 ;;
  esac
done
[ $# -gt 0 ] || { echo "no command given" >&2; exit 2; }

cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
[ -n "$burners" ] || burners=$((cores * 2))
[ -n "$logdir" ] || logdir=$(mktemp -d "${TMPDIR:-/tmp}/klunki-stress.XXXXXX")
mkdir -p "$logdir"

# The process tree below $1 (without $1).
descendants() {
  local c
  for c in $(pgrep -P "$1" 2>/dev/null); do
    echo "$c"
    descendants "$c"
  done
}

# Freezes $1 and the processes below it now and then (see -f) while $1 runs.
freezer() {
  local root=$1 awake=${freeze%%:*} frozen_s=${freeze##*:} frozen=""
  trap 'for p in $frozen; do kill -CONT "$p" 2>/dev/null; done; exit 0' TERM INT
  while kill -0 "$root" 2>/dev/null; do
    sleep "$awake"
    frozen="$root $(descendants "$root")"
    for p in $frozen; do kill -STOP "$p" 2>/dev/null; done
    sleep "$frozen_s"
    for p in $frozen; do kill -CONT "$p" 2>/dev/null; done
    frozen=""
  done
}

pids=()
cmd=""
freezer_pid=""
cleanup() {
  trap - EXIT INT TERM
  [ -n "$freezer_pid" ] && kill "$freezer_pid" 2>/dev/null && wait "$freezer_pid" 2>/dev/null
  if [ -n "$cmd" ]; then
    for p in $(descendants "$cmd"); do kill -CONT "$p" 2>/dev/null; kill "$p" 2>/dev/null; done
    kill -CONT "$cmd" 2>/dev/null
    kill "$cmd" 2>/dev/null
  fi
  for p in "${pids[@]:-}"; do [ -n "$p" ] && kill "$p" 2>/dev/null; done
  wait 2>/dev/null
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM

b=0
while [ "$b" -lt "$burners" ]; do
  yes > /dev/null &
  pids+=($!)
  b=$((b + 1))
done
if command -v caffeinate > /dev/null 2>&1; then
  caffeinate -i -w $$ &
  pids+=($!)
fi
echo "stress: $burners CPU burners on $cores cores${freeze:+, freeze $freeze}, $loops loops, logs in $logdir"

pass=0
i=0
while [ "$i" -lt "$loops" ]; do
  i=$((i + 1))
  log="$logdir/run-$i.log"
  # In the background + wait, so Ctrl+C / kill stops it and the burners at once.
  "$@" > "$log" 2>&1 &
  cmd=$!
  if [ -n "$freeze" ]; then
    freezer "$cmd" &
    freezer_pid=$!
  fi
  if wait "$cmd"; then
    pass=$((pass + 1))
    echo "run $i: pass"
    rm -f "$log"
  else
    echo "run $i: FAIL ($log)"
    grep -E '\[E\]|^  (Expected|Actual|Which):|TimeoutException|Bad state' "$log" | head -8 | sed 's/^/    /'
  fi
  if [ -n "$freezer_pid" ]; then
    kill "$freezer_pid" 2>/dev/null
    wait "$freezer_pid" 2>/dev/null
    freezer_pid=""
  fi
  cmd=""
done
echo "stress: $pass/$loops passed"
[ "$pass" -eq "$loops" ]
