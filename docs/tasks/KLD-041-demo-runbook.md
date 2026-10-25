# KLD-041 — Demo runbook `docs/DEMO.md`

- **ID:** `KLD-041`
- **Title:** Demo runbook: exact steps for the final demos (text, hot-seat, iPhone ↔ iPad, Android ↔ iOS, PWA), device checklist, Wi-Fi pitfalls
- **Milestone:** P4 (end of PoC); a living document, updated whenever a task lands
- **Status:** IN_PROGRESS
- **Depends on:** none to start; it is **updated as tasks land** (KLD-010, 011, 012, 020–026, 030–036, 040)
- **Touched paths:**
  - `docs/DEMO.md`
  - `docs/tasks/KLD-041-demo-runbook.md` (status only)

## Goal
Anyone can run each demo from `docs/DEMO.md` alone: prerequisites (with the 🧑 steps marked), exact commands, what the audience
should see, and troubleshooting for the usual failures (Wi-Fi client isolation, guest networks, hotspot fallback, iOS
local-network prompt, macOS firewall, USB authorization, expired free-ID profiles). It includes a one-page pre-demo checklist.

## Device plan (user, 2026-10-25)
One Mac, **one Android phone, one iPhone, one iPad**. **No Android ↔ Android demo.** The first two-device demo is **iPhone ↔ iPad**;
the end of PoC is **Android phone ↔ iPhone or iPad**. iOS has priority. Xcode 27.1 is installed; the user must run
`sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`. Android Studio is approved for KLD-011 (no emulator).

## Acceptance criteria
- [x] `docs/DEMO.md` exists with sections: 1 Text demo, 2 Hot-seat, 3 iPhone ↔ iPad, 4 Android ↔ iOS, 5 PWA, a pre-demo checklist,
      and a general troubleshooting table.
- [x] Section 1 (text) is complete and verified: `cd packages/klunki_engine && dart run bin/klunki.dart demo` plus per-game demos,
      interactive commands, move syntax and the in-app Debug-Konsole.
- [ ] Section 2 (hot-seat) is filled in after KLD-021…026: real menu labels, cover text, result dialog, a suggested demo order. Remove its TODO markers.
- [ ] Section 3 is verified on the real iPhone + iPad after KLD-034 + KLD-040: labels, the exact prompt text, timings. KLD-031's CLI name is confirmed in the warm-up.
- [ ] Section 4 is verified after KLD-011 + KLD-035: each platform hosting once, every game played to the end.
- [ ] Section 5 is verified after KLD-010: the serve command and offline check as KLD-010 documents them.
- [ ] The status table at the top of `DEMO.md` matches the board.
- [ ] Status → DONE when all five sections are verified on the devices (the end-of-PoC demo has run once from the runbook).

## Constraints
- Board rules: never install toolchains, download SDK components, accept licenses, sign up for accounts or publish anything without the user's OK.
  The runbook *describes* the 🧑 steps; it never performs them.
- Only edit `docs/DEMO.md` and this card. Don't commit unless asked.
- Commands in the runbook must be copy-pasteable and verified. Mark anything unverified with `TODO`.

## Hints / context
- When updating after a task lands: read that task's card + code, run its demo path once, replace the matching `⏳`/`TODO` with what you saw,
  and update the status table.
- Text-demo results are deterministic (fixed seeds). If an engine change alters them, update the expected outcomes in section 1.

## Definition of done
`docs/DEMO.md` has no `TODO`/`⏳` left, every section has been run once from the document on the real devices, and card status is set to DONE.
