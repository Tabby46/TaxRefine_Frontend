import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val localProperties = Properties().apply {
    val localFile = rootProject.file("local.properties")
    if (localFile.exists()) {
        localFile.inputStream().use { stream -> load(stream) }
    }
}

val customStoreFile = localProperties.getProperty("taxrefine.storeFile")
    ?: System.getenv("TAXREFINE_STORE_FILE")
val customStorePassword = localProperties.getProperty("taxrefine.storePassword")
    ?: System.getenv("TAXREFINE_STORE_PASSWORD")
val customKeyAlias = localProperties.getProperty("taxrefine.keyAlias")
    ?: System.getenv("TAXREFINE_KEY_ALIAS")
val customKeyPassword = localProperties.getProperty("taxrefine.keyPassword")
    ?: System.getenv("TAXREFINE_KEY_PASSWORD")

val hasCustomSigning = !customStoreFile.isNullOrBlank() &&
    !customStorePassword.isNullOrBlank() &&
    !customKeyAlias.isNullOrBlank() &&
    !customKeyPassword.isNullOrBlank()

android {
    namespace = "com.zultanite.taxrefine"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.zultanite.taxrefine"
        // Google Sign-In Android requires minSdk 21+.
        minSdk = maxOf(flutter.minSdkVersion, 21)
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasCustomSigning) {
            create("taxrefine") {
                storeFile = file(customStoreFile!!)
                storePassword = customStorePassword
                keyAlias = customKeyAlias
                keyPassword = customKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            if (hasCustomSigning) {
                signingConfig = signingConfigs.getByName("taxrefine")
            }
        }

        release {
            signingConfig = if (hasCustomSigning) {
                signingConfigs.getByName("taxrefine")
            } else {
                // Signing with the debug keys for now, so `flutter run --release` works.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
