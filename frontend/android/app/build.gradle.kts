import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release-signing config — values come from `android/key.properties`
// (git-ignored). See `docs/play-store-release.md` for keystore setup +
// Play Console upload steps. If the file is missing the release build
// falls back to the debug keys so a contributor's `flutter run --release`
// still works locally; the Play Console will reject that build because
// it is debug-signed, which is the loud failure mode we want.
val keyPropsFile = rootProject.file("key.properties")
val keyProps = Properties()
if (keyPropsFile.exists()) {
    keyProps.load(FileInputStream(keyPropsFile))
}
val hasReleaseKeys = keyPropsFile.exists() &&
    keyProps.containsKey("storeFile") &&
    keyProps.containsKey("storePassword") &&
    keyProps.containsKey("keyAlias") &&
    keyProps.containsKey("keyPassword")

android {
    namespace = "com.majksquare.bike_news_room"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.majksquare.bike_news_room"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Patrol uses its own JUnit runner to bridge Flutter's
        // integration_test harness to Android's instrumentation
        // framework. Required for `patrol test` / the MCP
        // `run_patrol_test` driver.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    signingConfigs {
        if (hasReleaseKeys) {
            create("release") {
                storeFile = rootProject.file(keyProps["storeFile"] as String)
                storePassword = keyProps["storePassword"] as String
                keyAlias = keyProps["keyAlias"] as String
                keyPassword = keyProps["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeys) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Shrink + obfuscate via R8 in release builds — saves ~2 MB
            // on the AAB and makes reverse-engineering the bundle a tiny
            // bit harder. Keep proguard-rules.pro empty for now; Flutter
            // doesn't ship code that needs custom keep rules out of the
            // box, and adding rules without a real symptom is cargo-cult.
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

flutter {
    source = "../.."
}
