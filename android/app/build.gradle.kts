import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.furkanages.spookyai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


    defaultConfig {
        applicationId = "com.furkanages.spookyai"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 24
        versionName = "2.0.1"
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Never ship a debug-signed release: Play rejects it, and a wrong
            // key breaks the update chain. The debug fallback is only reachable
            // with ALLOW_DEBUG_SIGNED_RELEASE=true (local testing); otherwise
            // release tasks fail fast below when key.properties is missing.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

gradle.taskGraph.whenReady {
    val shipsRelease = allTasks.any {
        it.name == "bundleRelease" || it.name == "assembleRelease"
    }
    if (shipsRelease && !keystorePropertiesFile.exists() &&
        System.getenv("ALLOW_DEBUG_SIGNED_RELEASE") != "true") {
        throw GradleException(
            "android/key.properties is missing: refusing to build a debug-signed " +
                "release. Add the upload keystore (see SECURITY.md) or set " +
                "ALLOW_DEBUG_SIGNED_RELEASE=true for a local test build."
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
