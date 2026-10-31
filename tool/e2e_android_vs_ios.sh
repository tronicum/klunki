#!/usr/bin/env bash
# KLD-038a/038c: the real app on an iOS simulator (host, X) plays Mühle against
# the real app on the Android emulator (guest, O). Prints PASS or FAIL.
#
#   tool/e2e_android_vs_ios.sh                 # iPhone 18 Pro hosts, AVD Medium_Phone_API_37.0 joins 10.0.2.2
#   tool/e2e_android_vs_ios.sh --mdns          # the guest joins via the mDNS list entry (needs KLD-035 multicast)
#   tool/e2e_android_vs_ios.sh --host-sim <udid> --avd <name> --port 47123
#
# NOT RUNNABLE YET (2026-10): needs the 🧑 user steps first (the agent must not do them):
#   1. Android Studio → Settings → Android SDK → SDK Tools → "Android SDK Command-line Tools" installed.
#   2. `flutter doctor --android-licenses`, accepted personally.
#   3. The AVD `Medium_Phone_API_37.0` boots once (Device Manager).
# The script checks these and stops with a message when something is missing.
#
# Same flow as tool/e2e_ios_sims.sh: the iOS host starts first; once it
# listens on the Mac's 127.0.0.1:<port> (iOS simulators share the Mac's
# network), the Android guest is started and connects to 10.0.2.2:<port>
# (the emulator's alias for the Mac's loopback). Swapped roles (Android host)
# would need `adb forward tcp:<port> tcp:<port>` so the iOS guest can use
# 127.0.0.1; not wired up yet (see docs/tasks/KLD-038c-mobile-integration-tests.md).
#
# Logs and screenshots: klunki/build/e2e_android/. Android screenshots land in
# the app's temp directory on the emulator (paths are printed in guest.log).
set -u

if [[ -z "${KLUNKI_CAFFEINATED:-}" ]] && command -v caffeinate >/dev/null; then
  KLUNKI_CAFFEINATED=1 exec caffeinate -i "$0" "$@"
fi

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

HOST_SIM=""
AVD="Medium_Phone_API_37.0"
EMU_ID="emulator-5554"
PORT=47123
SEED=1
JOIN=manual
TIMEOUT=1800

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host-sim) HOST_SIM="$2"; shift 2 ;;
    --avd) AVD="$2"; shift 2 ;;
    --emulator-id) EMU_ID="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --seed) SEED="$2"; shift 2 ;;
    --mdns) JOIN=mdns; shift ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

missing() { echo "BLOCKED: $1"; echo "See the 🧑 steps at the top of $0."; exit 3; }

# --- prerequisites -----------------------------------------------------------
command -v flutter >/dev/null || missing "flutter not on PATH"
xcrun simctl help >/dev/null 2>&1 || missing "xcrun simctl unavailable (Xcode, DEVELOPER_DIR)"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
ADB="$(command -v adb || echo "$SDK/platform-tools/adb")"
[[ -x "$ADB" ]] || missing "adb not found (Android SDK platform-tools in $SDK)"
ls "$SDK"/cmdline-tools/*/bin/sdkmanager >/dev/null 2>&1 || missing "Android SDK Command-line Tools not installed in $SDK"
[[ -d "$SDK/licenses" ]] && ls "$SDK/licenses" | grep -q android-sdk-license || missing "Android SDK licenses not accepted (flutter doctor --android-licenses)"
flutter emulators 2>/dev/null | grep -q "$AVD" || missing "AVD $AVD not found (flutter emulators)"

sim_by_name() {
  xcrun simctl list devices available | grep -E "^ +$1 \(" | grep -oE '[0-9A-F]{8}-[0-9A-F-]{27}' | head -1
}
[[ -n "$HOST_SIM" ]] || HOST_SIM="$(sim_by_name 'iPhone 18 Pro')"
[[ -n "$HOST_SIM" ]] || { echo "FAIL: iOS simulator not found"; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/klunki"
OUT="$APP/build/e2e_android"
mkdir -p "$OUT/screenshots"
rm -f "$OUT/host.log" "$OUT/guest.log"

# --- boot ---------------------------------------------------------------------
xcrun simctl boot "$HOST_SIM" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$HOST_SIM" -b >/dev/null || { echo "FAIL: simulator did not boot"; exit 1; }
if ! "$ADB" devices | grep -q "^$EMU_ID"; then
  echo "== launching emulator $AVD"
  flutter emulators --launch "$AVD" >/dev/null 2>&1
fi
"$ADB" -s "$EMU_ID" wait-for-device
until [[ "$("$ADB" -s "$EMU_ID" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do sleep 2; done

if nc -z 127.0.0.1 "$PORT" 2>/dev/null; then echo "FAIL: port $PORT already in use on this Mac"; exit 1; fi

cd "$APP" || exit 1
DEFINES=(--dart-define=KLUNKI_E2E_PORT="$PORT" --dart-define=KLUNKI_E2E_SEED="$SEED" --dart-define=KLUNKI_E2E_JOIN="$JOIN")

START=$(date +%s)
flutter test integration_test/network_test.dart -d "$HOST_SIM" "${DEFINES[@]}" \
  --dart-define=KLUNKI_E2E_ROLE=host --dart-define=KLUNKI_E2E_HOST=127.0.0.1 \
  --dart-define=KLUNKI_SCREENSHOT_DIR="$OUT/screenshots" --dart-define=KLUNKI_SCREENSHOT_PREFIX=ios_host \
  >"$OUT/host.log" 2>&1 &
HOST_PID=$!
cleanup() { kill "$HOST_PID" ${GUEST_PID:-} 2>/dev/null; }
trap cleanup EXIT INT TERM

echo "== building + starting the iOS host (log: $OUT/host.log)"
until nc -z 127.0.0.1 "$PORT" 2>/dev/null; do
  kill -0 "$HOST_PID" 2>/dev/null || { tail -30 "$OUT/host.log"; echo "FAIL: host ended before listening"; exit 1; }
  (( $(date +%s) - START > TIMEOUT )) && { echo "FAIL: timeout waiting for the host"; exit 1; }
  sleep 2
done
echo "== host listening after $(( $(date +%s) - START ))s; building + starting the Android guest (log: $OUT/guest.log)"

flutter test integration_test/network_test.dart -d "$EMU_ID" "${DEFINES[@]}" \
  --dart-define=KLUNKI_E2E_ROLE=guest --dart-define=KLUNKI_E2E_HOST=10.0.2.2 \
  --dart-define=KLUNKI_SCREENSHOT_PREFIX=android_guest >"$OUT/guest.log" 2>&1 &
GUEST_PID=$!
( sleep "$TIMEOUT" && kill "$HOST_PID" "$GUEST_PID" ) >/dev/null 2>&1 &
WATCHDOG=$!

wait "$GUEST_PID"; GUEST_RC=$?
wait "$HOST_PID"; HOST_RC=$?
pkill -P "$WATCHDOG" 2>/dev/null; kill "$WATCHDOG" 2>/dev/null
trap - EXIT

result() { grep -o 'E2E_RESULT .*' "$1" | head -1 | sed 's/^E2E_RESULT //'; }
HOST_RESULT="$(result "$OUT/host.log")"
GUEST_RESULT="$(result "$OUT/guest.log")"
echo "--- iOS host:      rc=$HOST_RC  $HOST_RESULT"
echo "--- Android guest: rc=$GUEST_RC  $GUEST_RESULT"
echo "--- $(grep -o 'E2E_MDNS .*' "$OUT/guest.log" | head -1)"
echo "--- total $(( $(date +%s) - START ))s"
if [[ $HOST_RC -eq 0 && $GUEST_RC -eq 0 && -n "$HOST_RESULT" && "$HOST_RESULT" == "$GUEST_RESULT" ]]; then
  echo "PASS"; exit 0
fi
echo "FAIL"; exit 1
