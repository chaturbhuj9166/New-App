
plugins {
    id("com.android.application")
    id("kotlin-android")

    // Flutter Plugin
    id("dev.flutter.flutter-gradle-plugin")

    // Firebase
    id("com.google.gms.google-services")
}

android {

    namespace = "com.example.firstapp"

    compileSdk = flutter.compileSdkVersion

    ndkVersion = flutter.ndkVersion

    // =========================
    // JAVA 17 + DESUGARING
    // =========================

    compileOptions {

        sourceCompatibility = JavaVersion.VERSION_17

        targetCompatibility = JavaVersion.VERSION_17

        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {

        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {

        applicationId = "com.example.firstapp"

        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode

        versionName = flutter.versionName
    }

    buildTypes {

        release {

            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {

    source = "../.."
}

// =========================
// DEPENDENCIES
// =========================

dependencies {

    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.4"
    )
}

