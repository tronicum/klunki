#!/usr/bin/env bash
# Browser vs browser through the relay (KLD-057b), end to end in two headless
# Firefox instances (WebDriver BiDi, see pwa_relay_e2e.mjs). PASS/FAIL plus
# screenshots of every step.
#
# Usage (from anywhere): klunki/tool/pwa_relay_e2e.sh [--build] [--port N] [--out DIR] [extra args]
#   --build   flutter build web --release + pwa_finalize.py first (otherwise
#             the existing klunki/build/web is served)
#   --port N  relay port (default 8765; N+1 is used for the "no relay" check)
#   --out DIR screenshots + report.json (default ./pwa-relay-e2e)
#   extra args go to pwa_relay_e2e.mjs (e.g. --verbose, --browser PATH)
#
# Runs two games: B types the room code (after checking that a page served by
# a plain python http.server explains how to start a relay), then B opens the
# host's ?room= link. Starts and stops the relay
# (`dart run klunki_net:klunki relay --web build/web`) and the python server
# itself. Needs Node >= 22, Firefox (KLUNKI_FIREFOX or --browser if it is not
# in /Applications), python3. Nothing is installed.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
app="$(cd "$here/.." && pwd)"
port=8765
out="$PWD/pwa-relay-e2e"
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
plain=$((port + 1))
mkdir -p "$out"
out="$(cd "$out" && pwd)"

if [ "$build" = 1 ]; then
  (cd "$app" && flutter build web --release && python3 build/web/pwa_finalize.py)
fi
if [ ! -f "$app/build/web/index.html" ]; then
  echo "FAIL: $app/build/web is missing (run with --build)" >&2
  exit 2
fi
for p in "$port" "$plain"; do
  if curl -s -m 2 -o /dev/null "http://127.0.0.1:$p/"; then
    echo "FAIL: port $p is in use (pick another with --port)" >&2
    exit 2
  fi
done

pids=()
cleanup() { for p in "${pids[@]+"${pids[@]}"}"; do kill "$p" 2>/dev/null || true; done; }
trap cleanup EXIT

(cd "$app" && exec dart run klunki_net:klunki relay --port "$port" --web build/web) >"$out/relay.log" 2>&1 &
pids+=($!)
python3 -m http.server "$plain" --bind 127.0.0.1 --directory "$app/build/web" >"$out/http-server.log" 2>&1 &
pids+=($!)

for _ in $(seq 1 60); do
  if curl -fs -m 2 -o /dev/null "http://127.0.0.1:$port/" && curl -fs -m 2 -o /dev/null "http://127.0.0.1:$plain/"; then
    break
  fi
  sleep 1
done
if ! curl -fsS -m 2 -o /dev/null "http://127.0.0.1:$port/"; then
  echo "FAIL: the relay did not start, see $out/relay.log" >&2
  exit 2
fi

status=0
echo "== B types the room code (plus the \"no relay\" check on :$plain)"
node "$here/pwa_relay_e2e.mjs" --url "http://127.0.0.1:$port/" --out "$out/code" --join code \
  --no-relay "http://127.0.0.1:$plain/" "${extra[@]+"${extra[@]}"}" || status=1
echo "== B opens the host's ?room= link"
node "$here/pwa_relay_e2e.mjs" --url "http://127.0.0.1:$port/" --out "$out/link" --join link \
  "${extra[@]+"${extra[@]}"}" || status=1

echo "pwa_relay_e2e: $([ $status = 0 ] && echo PASS || echo FAIL), screenshots in $out/{code,link}"
exit $status
