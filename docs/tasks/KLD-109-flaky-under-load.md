# KLD-109: network tests flaky under load: root causes and fixes

- **ID:** `KLD-109`
- **Title:** Find and fix why the network / live-UI tests pass alone but fail on a busy machine
- **Milestone:** M3 (quality)
- **Status:** DONE
- **Depends on:** the lost-`bye` fix (commit a97fa7b, "Fix three CI flakes at the root")
- **Touched paths:**
  - `packages/klunki_net/lib/src/awake_clock.dart` (new), `connection.dart`, `guest.dart`, `host.dart`,
    `relay/relay_client.dart`, `channel/platform_io.dart`, `channel/browser_websocket_channel.dart`, `PROTOCOL.md`
  - `packages/klunki_net/test/` (`awake_clock_test.dart` new, `net_test.dart`, `support.dart`, `cli_test.dart`)
  - `klunki/test/support/test_run.dart` (new), `klunki/test/ui/pairing/pairing_test_utils.dart`,
    `klunki/test/e2e/e2e_support.dart`, `klunki/test/e2e/muehle_screens_e2e_test.dart`,
    `klunki/test/ui/games/gostrategy_network_test.dart`, `klunki/test/e2e/live_ui/*`
  - `klunki/tool/pwa_relay_e2e.mjs`, `klunki/tool/browser_live/{live,quartett_trumpf}.mjs`, `README.md`
  - `tool/stress_test.sh` (new), `AGENTS.md`

## Goal

Failures seen over several days only when the machine was busy (several `flutter test` runs, high `-j`):
the live UI Quartett network games, `muehle_screens_e2e_test`, `gostrategy_network_test` (3 in one run),
`relay_test` (4), two in `klunki_net`. Find the root causes, fix them at the root, prove it under load.

## Reproduction: `tool/stress_test.sh`

Plain CPU burners (2× cores of `yes`) were not enough: on a 15-core machine at load 250 the network files
passed. What breaks them is a process that **does not run for seconds** (starved, or a sleeping machine).
`tool/stress_test.sh -f AWAKE:FROZEN` reproduces exactly that: it SIGSTOPs the test processes for FROZEN s
every AWAKE + FROZEN s (and SIGCONTs them; nothing is left stopped, also on Ctrl+C).

## Root causes

1. **Product bug (`klunki_net`): timeouts judged the other side by wall clock, including our own stall.**
   The keepalive (`Connection._tick`) ended a connection when "nothing was heard for `timeout`". After a
   stall (long synchronous frame, no CPU, sleep, app back from the background) the first tick came late and
   saw a long silence, while the other side's pongs were waiting *unread* in our socket: a healthy
   connection was dropped ("disconnected", "Verbindung … unterbrochen" instead of "… hat das Spiel
   verlassen"). The same for the one-shot handshake timeouts (`no welcome`, `no hello`, relay room, WebSocket
   open): "handshake timed out" after a freeze. Fix: `AwakeClock` / `awakeTimer` / `awakeTimeout` count only
   time the isolate was running (a periodic tick that comes late measures a stall, which is left out);
   silence and handshakes use them. A really silent peer is still detected (tested), just not during our
   own stall. No wire change; `PROTOCOL.md` says so.
   Regression tests: `net_test` "a stalled isolate is not a ping timeout (tcp/ws)" (failed before: both
   sides reported "timeout: no message for 150 ms"), "a silent guest is still detected after a stall of the
   host", `awake_clock_test.dart`.
2. **The machine slept during a test run** (the 2026-11-01 night run with 3 gostrategy and 4 relay
   failures): `pmset -g log` shows "Entering Sleep state … 749 secs" at 23:00:43, the run's log a gap from
   03:38 to 16:06. On wake every wall-clock test timeout fired at once. Fix: `stress_test.sh` keeps the Mac
   awake (`caffeinate -i -w`); AGENTS.md recommends `caffeinate -i flutter test …` for long runs; and with
   (1) the connections themselves survive such a pause.
3. **Cascade failures (test harness).** flutter_test does not stop a test body that timed out: its
   pump / runAsync loop keeps going while the next test of the file runs, which then fails with "Guarded
   function conflict" or "Reentrant call to runAsync() denied". So 1 real failure showed up as 3 (gostrategy)
   or 4 (relay). Fix: `testRunGuard` (`klunki/test/support/test_run.dart`) stops a dead test's wait loop
   (verified: a 2 s-timeout test followed by a normal one, the second now passes).
4. **Wall-clock hang guards counted time nothing ran (test bugs).** `until` (5 s), `pumpUntil` (15 s) and
   the live-UI "still running after 6 min" budget failed healthy runs: a 100-round Quartett game took 6+ min
   at load 250. Fix: the polling helpers give up only after their wall time *and* a minimum number of
   polls (each poll is a turn for the sockets); the live UI guards on *progress* (2 min and 300 rounds
   without a new move or reveal) instead of the total, and its network tests get a local 20 min backstop
   (`liveUiTimeout`, with the reason) instead of 8 min.

Checked and not a cause: the TCP linger after the lost-`bye` fix (a guest stalled 3 s, longer than the
2 s linger, still gets the host's `bye`, TCP and WebSocket); fixed ports (all tests use port 0).

## Proof (pass counts, same commands before = d19e0b8 / after)

| Run | Before | After |
|---|---|---|
| `klunki_net` `dart test -j 8`, freeze 3 s of every 9 s | 0/3 (false "disconnected" in random games and the Mühle e2e) | 5/5 |
| 7 Flutter network files (relay, gostrategy, muehle screens + network e2e, quartett network, web join, pairing flow), freeze 12 s of every 15 s | 0/3 (3 failures per run) | 5/5 |
| live UI Quartett + relay + gostrategy + muehle screens + l10n coverage, `-j 8`, 30 CPU burners (machine load 150–290) | 1/3 ("still running after 6 min", slow-guest game) | 2/2 |
| plain CPU burners only, 7 network files | 5/5 (CPU load alone did not break them) | – |

## Also in this card (coordinator request)

The browser scripts were out of date after KLD-098/105/106 and failed for the wrong reasons:
`klunki/tool/pwa_relay_e2e.mjs` (menu "Über WLAN spielen" → host via the "Mit anderen" tile link, guest via
"Raum beitreten", names instead of "(X)") and `klunki/tool/browser_live/` (names instead of X/O, the
"Wer spielt?" dialog, KLD-100 card choice incl. the defender's cover). Flutter web exposes no widget keys
(the app sets no semantics identifiers), so they go by anchored German labels. Verified against the relay
on :8081: pwa_relay_e2e code join + link join + "no relay" check PASS; browser_live hot-seat PASS (88
tricks, 6 card choices, defender covers), network PASS (3 seeds, 200 rounds each).

## Definition of done

Engine and net `dart test`, `flutter analyze`, `flutter test -j 2`, `flutter test test/e2e/live_ui` green.
