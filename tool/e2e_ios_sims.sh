#!/usr/bin/env bash
# KLD-038c: two iOS simulators play Mühle against each other through the real
# app (P3 check: iPhone host <-> iPad guest). Prints PASS or FAIL.
#
#   tool/e2e_ios_sims.sh                      # iPhone 18 Pro hosts, iPad Pro 11-inch (M5) joins by 127.0.0.1
#   tool/e2e_ios_sims.sh --mdns               # the guest joins via the mDNS list entry instead
#   tool/e2e_ios_sims.sh --host-sim <udid> --guest-sim <udid> --port 47123 --seed 1
#
# How: boots both simulators (headless is fine, Simulator.app is not needed),
# starts `flutter test integration_test/network_test.dart` as the host, waits
# until the host app listens on the port (iOS simulators share the Mac's
# network stack, so the Mac sees it on 127.0.0.1), then starts the guest run.
# The guest's build is incremental (same project, only the dart-defines
# differ), and starting it after the host's build avoids two xcodebuilds in
# one build directory. Both runs print `KLUNKI_IT E2E_RESULT {json}`; the
# script compares the two lines.
#
# Logs and screenshots: klunki/build/e2e/ (host.log, guest.log, screenshots/).
set -u

if [[ -z "${KLUNKI_CAFFEINATED:-}" ]] && command -v caffeinate >/dev/null; then
  KLUNKI_CAFFEINATED=1 exec caffeinate -i "$0" "$@"
fi

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

HOST_SIM=""
GUEST_SIM=""
PORT=47123
SEED=1
JOIN=manual
TIMEOUT=1500 # seconds for the whole run (two builds + the game)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host-sim) HOST_SIM="$2"; shift 2 ;;
    --guest-sim) GUEST_SIM="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --seed) SEED="$2"; shift 2 ;;
    --mdns) JOIN=mdns; shift ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

sim_by_name() {
  xcrun simctl list devices available | grep -E "^ +$1 \(" | grep -oE '[0-9A-F]{8}-[0-9A-F-]{27}' | head -1
}

command -v xcrun >/dev/null || { echo "FAIL: xcrun missing (Xcode)"; exit 1; }
command -v flutter >/dev/null || { echo "FAIL: flutter not on PATH"; exit 1; }
xcrun simctl help >/dev/null 2>&1 || { echo "FAIL: xcrun simctl unavailable; set DEVELOPER_DIR to Xcode"; exit 1; }

[[ -n "$HOST_SIM" ]] || HOST_SIM="$(sim_by_name 'iPhone 18 Pro')"
[[ -n "$GUEST_SIM" ]] || GUEST_SIM="$(sim_by_name 'iPad Pro 11-inch \(M5\)')"
[[ -n "$HOST_SIM" && -n "$GUEST_SIM" ]] || { echo "FAIL: simulators not found (xcrun simctl list devices available)"; exit 1; }
[[ "$HOST_SIM" != "$GUEST_SIM" ]] || { echo "FAIL: host and guest must be two simulators"; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/klunki"
OUT="$APP/build/e2e"
mkdir -p "$OUT/screenshots"
rm -f "$OUT/host.log" "$OUT/guest.log"

echo "== host  (X): $HOST_SIM"
echo "== guest (O): $GUEST_SIM   join by: $JOIN   port: $PORT   seed: $SEED"

for sim in "$HOST_SIM" "$GUEST_SIM"; do
  xcrun simctl boot "$sim" >/dev/null 2>&1 || true # already booted is fine
done
for sim in "$HOST_SIM" "$GUEST_SIM"; do
  xcrun simctl bootstatus "$sim" -b >/dev/null || { echo "FAIL: simulator $sim did not boot"; exit 1; }
done

if nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
  echo "FAIL: port $PORT is already in use on this Mac (another Klunki host?)"; exit 1
fi

cd "$APP" || exit 1
DEFINES=(--dart-define=KLUNKI_E2E_PORT="$PORT" --dart-define=KLUNKI_E2E_SEED="$SEED"
  --dart-define=KLUNKI_E2E_HOST=127.0.0.1 --dart-define=KLUNKI_E2E_JOIN="$JOIN"
  --dart-define=KLUNKI_SCREENSHOT_DIR="$OUT/screenshots")

START=$(date +%s)
flutter test integration_test/network_test.dart -d "$HOST_SIM" "${DEFINES[@]}" \
  --dart-define=KLUNKI_E2E_ROLE=host --dart-define=KLUNKI_SCREENSHOT_PREFIX=host >"$OUT/host.log" 2>&1 &
HOST_PID=$!

cleanup() { kill "$HOST_PID" ${GUEST_PID:-} 2>/dev/null; }
trap cleanup EXIT INT TERM

echo "== building + starting the host (log: $OUT/host.log)"
until nc -z 127.0.0.1 "$PORT" 2>/dev/null; do
  if ! kill -0 "$HOST_PID" 2>/dev/null; then
    echo "--- host.log (tail)"; tail -30 "$OUT/host.log"; echo "FAIL: the host run ended before listening"; exit 1
  fi
  if (( $(date +%s) - START > TIMEOUT )); then echo "FAIL: timeout waiting for the host"; exit 1; fi
  sleep 2
done
HOST_UP=$(( $(date +%s) - START ))
echo "== host listening on 127.0.0.1:$PORT after ${HOST_UP}s; building + starting the guest (log: $OUT/guest.log)"

flutter test integration_test/network_test.dart -d "$GUEST_SIM" "${DEFINES[@]}" \
  --dart-define=KLUNKI_E2E_ROLE=guest --dart-define=KLUNKI_SCREENSHOT_PREFIX=guest >"$OUT/guest.log" 2>&1 &
GUEST_PID=$!

# Watchdog for the whole run.
( sleep "$TIMEOUT" && kill "$HOST_PID" "$GUEST_PID" ) >/dev/null 2>&1 &
WATCHDOG=$!

wait "$GUEST_PID"; GUEST_RC=$?
wait "$HOST_PID"; HOST_RC=$?
pkill -P "$WATCHDOG" 2>/dev/null; kill "$WATCHDOG" 2>/dev/null
trap - EXIT
TOTAL=$(( $(date +%s) - START ))

result() { grep -o 'E2E_RESULT .*' "$1" | head -1 | sed 's/^E2E_RESULT //'; }
HOST_RESULT="$(result "$OUT/host.log")"
GUEST_RESULT="$(result "$OUT/guest.log")"

echo "--- host:  rc=$HOST_RC  $(grep -o 'E2E_TIMING .*' "$OUT/host.log" | head -1)"
echo "    $HOST_RESULT"
echo "--- guest: rc=$GUEST_RC  $(grep -o 'E2E_TIMING .*' "$OUT/guest.log" | head -1)"
echo "    $GUEST_RESULT"
echo "--- $(grep -o 'E2E_MDNS .*' "$OUT/guest.log" | head -1)"
echo "--- $(grep -o 'E2E_JOINED .*' "$OUT/guest.log" | head -1)"
echo "--- screenshots: $OUT/screenshots"
echo "--- total ${TOTAL}s (host up after ${HOST_UP}s)"

if [[ $HOST_RC -eq 0 && $GUEST_RC -eq 0 && -n "$HOST_RESULT" && "$HOST_RESULT" == "$GUEST_RESULT" ]]; then
  echo "PASS"
  exit 0
fi
if [[ -n "$HOST_RESULT" && "$HOST_RESULT" != "$GUEST_RESULT" ]]; then
  echo "results differ:"; diff <(echo "$HOST_RESULT" | tr ',' '\n') <(echo "$GUEST_RESULT" | tr ',' '\n')
fi
for side in host guest; do
  echo "--- $side.log (failures)"; grep -E "EXCEPTION|Expected|Actual|timed out|FAILED|Error" "$OUT/$side.log" | head -20
done
echo "FAIL"
exit 1
