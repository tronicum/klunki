#!/usr/bin/env bash
# Plays complete games of the PWA in real headless Firefox (KLD-089), see
# README.md next to this script. Starts a relay serving klunki/build/web on
# a free port, runs live.mjs (hot-seat in one browser, network host + guest
# by room code in two), stops the relay. Nothing is installed.
#
# Usage (from anywhere): klunki/tool/browser_live/run.sh [--build] [--port N] [--out DIR] [live.mjs args]
#   --build   flutter build web --release + pwa_finalize.py first
#   --port N  relay port (default 8775)
#   --out DIR report.json, tricks.log, screenshots (default ./browser-live)
#   other args go to live.mjs, e.g. --mode network --deck Raketen --seed 7 --verbose
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
app="$(cd "$here/../.." && pwd)"
port=8775
out="$PWD/browser-live"
build=0
extra=()
while [ $# -gt 0 ]; do
  case "$1" in
    --build) build=1 ;;
    --port) port="$2"; shift ;;
    --out) out="$2"; shift ;;
    *) extra+=("$1") ;;
  esac
  shift
done
mkdir -p "$out"
out="$(cd "$out" && pwd)"

if [ "$build" = 1 ]; then
  (cd "$app" && flutter build web --release && python3 build/web/pwa_finalize.py)
fi
if [ ! -f "$app/build/web/index.html" ]; then
  echo "FAIL: $app/build/web is missing (run with --build)" >&2
  exit 2
fi
if curl -s -m 2 -o /dev/null "http://127.0.0.1:$port/"; then
  echo "FAIL: port $port is in use (pick another with --port)" >&2
  exit 2
fi

relay=""
cleanup() { [ -n "$relay" ] && kill "$relay" 2>/dev/null || true; }
trap cleanup EXIT

(cd "$app" && exec dart run klunki_net:klunki relay --port "$port" --web build/web) >"$out/relay.log" 2>&1 &
relay=$!
for _ in $(seq 1 60); do
  curl -fs -m 2 -o /dev/null "http://127.0.0.1:$port/" && break
  sleep 1
done
if ! curl -fsS -m 2 -o /dev/null "http://127.0.0.1:$port/"; then
  echo "FAIL: the relay did not start, see $out/relay.log" >&2
  exit 2
fi

node "$here/live.mjs" --url "http://127.0.0.1:$port/" --out "$out" "${extra[@]+"${extra[@]}"}"
