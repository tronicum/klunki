import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (KLD-053 / KLD-070). Values come from android/key.properties
// (local builds, see docs/BUILDING.md) or from KLUNKI_KEYSTORE_* environment
// variables (CI). When any value is missing, the release build falls back to
// the debug key, so `flutter build apk --release` and CI work without secrets.
val keystoreProperties = Properties().apply {
    val keyFile = rootProject.file("key.properties")
    if (keyFile.exists()) keyFile.inputStream().use { load(it) }
}

fun signingValue(property: String, env: String): String? =
    (keystoreProperties.getProperty(property) ?: System.getenv(env))?.takeIf { it.isNotBlank() }

val releaseStoreFile = signingValue("storeFile", "KLUNKI_KEYSTORE_FILE")?.let { file(it) }
val releaseStorePassword = signingValue("storePassword", "KLUNKI_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "KLUNKI_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "KLUNKI_KEY_PASSWORD")
val hasReleaseSigning = releaseStoreFile?.exists() == true &&
    releaseStorePassword != null && releaseKeyAlias != null && releaseKeyPassword != null
if (!hasReleaseSigning) {
    logger.warn("Klunki: no complete release keystore (android/key.properties or KLUNKI_KEYSTORE_*): " +
        "release builds are signed with the debug key.")
}

android {
    namespace = "de.klunki.klunki"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "de.klunki.klunki"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Own key when configured (see above), otherwise the debug key so
            // `flutter run --release` and unsigned CI builds still work.
            signingConfig = signingConfigs.getByName(if (hasReleaseSigning) "release" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
