# KLD-038b — Device e2e: iPhone/iPad ↔ Android phone over Wi-Fi

- **ID:** `KLD-038b`
- **Title:** Run the KLD-038a Mühle e2e on real devices over the local Wi-Fi, PASS/FAIL
- **Milestone:** P4 — Android ↔ iOS (end of PoC, e2e test plan)
- **Status:** TODO
- **Depends on:** KLD-038a (test mode + integration test + script), KLD-011 (Android phone), KLD-012 (iPhone/iPad on device),
  KLD-040 (iOS local network permission), KLD-035 (Android networking/release check)
- **Touched paths:**
  - `tool/e2e_*` (a device variant, e.g. `tool/e2e_devices.sh`, or a `--devices` flag in `tool/e2e_android_vs_ios.sh`)
  - `klunki/integration_test/**` (only if the device run needs a small change, e.g. a host-IP print)
  - `docs/tasks/KLD-038b-device-e2e.md`, `docs/DEMO.md` (add the e2e check to the Android ↔ iOS demo prep)

## Goal
Before the end-of-PoC demo, one command proves the real devices can play: the iPhone (or iPad) hosts Mühle in test mode,
the Android phone joins via the host's Wi-Fi IP, both play the script, and the script prints PASS/FAIL. Then roles are swapped
(Android hosts, iOS joins), so each platform hosts once.

## Acceptance criteria
- [ ] The script takes device ids (`flutter devices`) and the host's Wi-Fi IP (or reads it from the host's log line
      `E2E_HOST_IP <ip>` printed by the test mode). Guest connects with `--dart-define=KLUNKI_E2E_HOST=<ip>`.
- [ ] Run 1: iOS hosts, Android joins → PASS. Run 2: Android hosts, iOS joins → PASS. Paste both outputs into the report.
- [ ] Failure output names the likely cause: no route (client isolation / guest Wi-Fi), iOS local-network permission denied,
      Android firewall/VPN, timeout.
- [ ] `docs/DEMO.md` Android ↔ iOS section gets a "pre-flight: run `tool/e2e_…`" step.

## 🧑 Steps
1. iPhone/iPad: Developer Mode on, trusted Mac, Apple ID/signing team in Xcode (KLD-012). Allow "Local Network" when iOS asks (KLD-040).
2. Android phone: USB debugging on, Mac authorized (KLD-011).
3. All devices on the same Wi-Fi without client isolation (a phone hotspot works as a fallback).
4. Keep the devices unlocked during the run.

## Constraints
- No new dependencies, no signing changes beyond what KLD-011/012 set up. Don't publish anything.

## Definition of done
Both runs PASS on the real devices; DEMO.md updated; card status DONE; BOARD row ✅.
