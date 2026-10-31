#!/usr/bin/env bash
# PWA i18n smoke check (I18N-06): headless screenshots of every locale and a
# PASS/FAIL per locale. FAIL = the app did not boot, or (offline modes) a
# request went to an external host such as fonts.gstatic.com.
#
# Usage: klunki/tool/pwa_i18n_check.sh [URL] [OUT_DIR] [MODE] [extra args]
#   URL      running PWA server (default http://localhost:8080/)
#   OUT_DIR  screenshots + report.json (default ./pwa-i18n-screens)
#   MODE     offline-warm (default): one online visit, then no internet
#                         (installed PWA used offline later)
#            offline:     no internet from the start, app server reachable
#            online:      everything allowed; external requests are listed
#   extra args go to pwa_i18n_check.mjs (e.g. --locales zh-Hans,ar --screens menu)
#
# Needs Node >= 22 and Firefox (WebDriver BiDi; set KLUNKI_FIREFOX or pass
# --browser if it is not in /Applications). Nothing is installed.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
url="${1:-http://localhost:8080/}"
out="${2:-$PWD/pwa-i18n-screens}"
mode="${3:-offline-warm}"
shift $(( $# < 3 ? $# : 3 ))

case "$mode" in
  offline-warm) flags=(--offline --warmup) ;;
  offline) flags=(--offline) ;;
  online) flags=() ;;
  *) echo "unknown mode: $mode (offline-warm | offline | online)" >&2; exit 2 ;;
esac

if ! curl -fsS -m 5 -o /dev/null "$url"; then
  echo "FAIL: $url is not reachable (start the server first)" >&2
  exit 1
fi

exec node "$here/pwa_i18n_check.mjs" --url "$url" --out "$out" "${flags[@]+"${flags[@]}"}" "$@"
