# KLD-053 — Android release signing (keystore)

- **ID:** `KLD-053`
- **Title:** Sign Android release builds with a real upload keystore instead of the debug keys
- **Milestone:** after P4 / before sharing APKs (backlog)
- **Status:** TODO — needs 🧑 (the user creates the keystore and chooses the passwords)
- **Depends on:** KLD-011 (Android toolchain + phone)
- **Touched paths:**
  - `klunki/android/app/build.gradle.kts` (release `signingConfig`)
  - `klunki/android/.gitignore` (make sure `key.properties` and `*.jks`/`*.keystore` are ignored)
  - `docs/DEMO.md` (one line on building a signed release APK), `docs/tasks/KLD-053-android-release-signing.md`

## Goal
`flutter build apk --release` (and `appbundle`) are signed with the user's own key when `klunki/android/key.properties` exists,
and fall back to the debug key otherwise, so CI/agents without the key can still build. No secret ever enters git.

## Repo context
- `klunki/android/app/build.gradle.kts`: release uses `signingConfig = signingConfigs.getByName("debug")` with a TODO (line ~34–36).
- `applicationId` `de.klunki.klunki`; `klunki/android/.gitignore` already warns "never publicly share your keystore".

## 🧑 Steps (the agent must not do these)
1. Create the keystore yourself, outside the repo, e.g.
   `keytool -genkey -v -keystore ~/keys/klunki-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
   and choose the passwords. Back up the file and the passwords.
2. Create `klunki/android/key.properties` (never committed):
   ```
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=/Users/<you>/keys/klunki-upload.jks
   ```

## Acceptance criteria
- [ ] `build.gradle.kts` reads `key.properties` if present (Kotlin `java.util.Properties`), defines `signingConfigs.create("release")`, uses it for
      `release`; without the file it falls back to `debug` and prints a Gradle warning.
- [ ] `.gitignore` covers `key.properties`, `*.jks`, `*.keystore`; `git status` shows no secret after the 🧑 steps.
- [ ] Without `key.properties`: `flutter build apk --release` still succeeds.
- [ ] With it (🧑 runs it): `flutter build apk --release` succeeds and
      `keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk` shows the user's certificate, not "Android Debug".
- [ ] `cd klunki && flutter analyze && flutter test` green.

## Constraints
- Never generate, read, print or commit keys or passwords. Don't publish to any store.

## Definition of done
Both build paths verified (the signed one by the user); card status DONE; BOARD row ✅.
