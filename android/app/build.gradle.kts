plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Lee key.properties (generado por CI) como mapa de strings
// En desarrollo local (sin key.properties) usa debug signing como fallback
fun readKeystoreProperties(file: File): Map<String, String> {
    val props = mutableMapOf<String, String>()
    if (file.exists()) {
        file.readLines().forEach { line ->
            val trimmed = line.trim()
            if (trimmed.isNotEmpty() && trimmed.contains("=")) {
                val (key, value) = trimmed.split("=", limit = 2)
                props[key.trim()] = value.trim()
            }
        }
    }
    return props
}

android {
    namespace = "com.mundolimpio.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    val keystoreProperties = readKeystoreProperties(rootProject.file("key.properties"))

    if (keystoreProperties.isNotEmpty()) {
        signingConfigs {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"]!!)
                storePassword = keystoreProperties["storePassword"]
                keyPassword = keystoreProperties["keyPassword"]
                keyAlias = keystoreProperties["keyAlias"]
            }
        }
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
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
