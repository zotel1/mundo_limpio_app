import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.mundolimpio.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Signing config para release — lee key.properties generado por CI
    // En desarrollo local (sin key.properties) usa debug signing como fallback
    val keyPropertiesFile = rootProject.file("key.properties")
    val keyProperties = java.util.Properties()
    if (keyPropertiesFile.exists()) {
        keyProperties.load(keyPropertiesFile.inputStream())
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.mundolimpio.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (keyPropertiesFile.exists()) {
                signingConfigs.create("release") {
                    storeFile = file(keyProperties.getProperty("storeFile"))
                    storePassword = keyProperties.getProperty("storePassword")
                    keyPassword = keyProperties.getProperty("keyPassword")
                    keyAlias = keyProperties.getProperty("keyAlias")
                }
            } else {
                signingConfigs.getByName("debug") // fallback para desarrollo local
            }
        }
    }
}

flutter {
    source = "../.."
}
