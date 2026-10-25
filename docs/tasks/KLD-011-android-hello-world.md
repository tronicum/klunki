# KLD-011 — Android hello world (debug build on the one Android phone)

- **ID:** `KLD-011`
- **Title:** Android: debug build + run on the user's Android phone; app label "Klunki"; `INTERNET` in the main manifest
- **Milestone:** Platform hello world (side quest, de-risks the final Android ↔ iOS demo)
- **Status:** BLOCKED (🧑 user steps: install Android cmdline-tools in Android Studio, accept the SDK licenses, enable USB debugging on the phone and authorize the Mac)
- **Depends on:** Android audit (done, facts below); 🧑 the user has approved installing **Android Studio**; 🧑 the phone must be connected and authorized by the user
- **Touched paths:**
  - `klunki/android/**`
  - `docs/tasks/KLD-011-android-hello-world.md` (status only)

## Goal
`flutter run` installs and starts the Klunki app on the user's **one physical
Android phone** (there is no emulator in this plan, and no second Android
phone). The launcher shows "Klunki" (capital K), and the main manifest
declares `INTERNET`, so a release build can open sockets later (KLD-035).

## Context (read-only audit, 2026-10-25)
- Mac: Apple Silicon. Flutter 3.47.8 via Homebrew at `/opt/homebrew/share/flutter`.
- **Not installed:** Android SDK, JDK, Android Studio.
- Project: `applicationId` / `namespace` = `de.klunki.klunki`; compileSdk/targetSdk 36, minSdk 24
  (via `flutter.*` in `klunki/android/app/build.gradle.kts`); AGP 9.1.0, Kotlin 2.4.0,
  Gradle wrapper 9.3.1 (`-all` distribution).
- `INTERNET` permission is only in `src/debug/AndroidManifest.xml` and `src/profile/AndroidManifest.xml`.
- Release build is signed with the **debug keys** (`signingConfig = signingConfigs.getByName("debug")`).
- `android:label="klunki"` (lowercase) in `src/main/AndroidManifest.xml`.
- `gradlew`, `gradlew.bat` and `gradle/wrapper/gradle-wrapper.jar` are **gitignored**: Flutter
  regenerates them on the first Android build. Don't commit them.

## Acceptance criteria
- [ ] `klunki/android/app/src/main/AndroidManifest.xml`: `android:label="Klunki"` and
      `<uses-permission android:name="android.permission.INTERNET"/>` (a direct child of `<manifest>`).
      The debug/profile manifests can keep their copy (duplicates merge harmlessly).
- [ ] `flutter doctor -v` shows a ✓ for the Android toolchain (SDK found, licenses accepted). Paste the relevant lines into your report.
- [ ] `cd klunki && flutter build apk --debug` succeeds.
- [ ] 🧑 `flutter devices` lists the user's phone; `flutter run -d <phone-id>` starts the app; the
      menu ("Wähle ein Spiel") shows; the Debug-Konsole plays `demo connect4`.
- [ ] The launcher icon label on the phone reads "Klunki".
- [ ] `cd klunki && flutter analyze && flutter test` are green (no Dart changes are expected).
- [ ] No emulator, AVD or system image is installed (not part of this plan).

## Constraints
- **Board rule:** never install toolchains, download SDK components, accept licenses, sign up for accounts
  or publish anything without the user's explicit OK. The user approved **Android Studio** for this
  task. Anything beyond the steps below (e.g. extra SDK packages, NDK versions Gradle asks for)
  → stop and ask first; say what it is and how big it is.
- Only edit `klunki/android/**`. No Dart changes. Don't commit the generated `gradlew*` / wrapper jar / `local.properties`.
- Keep `applicationId` `de.klunki.klunki`. Don't set up release signing here (KLD-035 / later).
- Don't commit unless asked.

## 🧑 Steps the user does personally
1. **Install Android Studio** (approved): `brew install --cask android-studio` (~1.3 GB), then open it once
   and run the **setup wizard** → "Standard" install. It downloads the SDK (~1–2 GB) into
   `~/Library/Android/sdk`. **Untick / skip** the emulator and virtual-device steps if offered.
   - Alternative if they prefer no IDE (A′): `brew install --cask temurin@21` +
     `brew install --cask android-commandlinetools`, then
     `flutter config --android-sdk <sdk-path>` and `flutter config --jdk-dir <jdk-path>`.
2. Make sure these SDK packages exist (Android Studio → Settings → Languages & Frameworks → Android SDK,
   or `sdkmanager`): `"platform-tools" "platforms;android-36" "build-tools;36.0.0" "cmdline-tools;latest"`.
   (`cmdline-tools` is required for `flutter doctor --android-licenses`.)
3. **Accept the licenses personally:** `flutter doctor --android-licenses` (the agent must not answer `y` for them).
4. If Flutter doesn't find Studio's JDK: `flutter config --jdk-dir "/Applications/Android Studio.app/Contents/jbr/Contents/Home"`.
5. **Phone:** Settings → About phone → tap "Build number" 7× → Developer options → enable
   **USB debugging**. Connect by USB, unlock the phone and accept **"Allow USB debugging?"**
   (tick "Always allow from this computer").
   Optional: Wireless debugging (Android 11+) via `adb pair` if no cable.

## Hints / context
- Agent flow once the user finished the steps above:
  ```bash
  flutter doctor -v                 # Android toolchain must be ✓
  adb devices                       # phone shows as "device", not "unauthorized"
  cd klunki
  flutter build apk --debug         # first build downloads Gradle 9.3.1 + AGP deps (~hundreds of MB) — tell the user before running
  flutter devices
  flutter run -d <phone-id>
  ```
- The first Gradle build downloads the Gradle distribution and Maven dependencies. That counts as a
  download: tell the user the size before running it, and wait for their OK.
- `unauthorized` in `adb devices` → the user must unlock the phone and accept the RSA prompt; if it
  never shows, `adb kill-server && adb start-server`, re-plug, revoke USB debugging authorizations on the phone.
- Gradle/JDK mismatch errors (AGP 9 needs JDK 17+; Studio ships 21) → check `flutter doctor -v` "Java binary at:".
- The app's Debug-Konsole is in `klunki/lib/ui/debug_console_screen.dart` (non-release builds only).

## Definition of done
```bash
cd klunki
flutter analyze && flutter test
flutter build apk --debug
flutter run -d <phone-id>   # app starts on the phone, label "Klunki"
```
Acceptance criteria ticked, report includes `flutter doctor -v` Android section, card status set to DONE.
