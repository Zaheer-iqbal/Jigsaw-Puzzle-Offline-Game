import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.alwaystech.jigsawpro"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.alwaystech.jigsawpro"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 4
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias", "upload")
            keyPassword = keystoreProperties.getProperty("keyPassword", "J1g5aw#Pr0_99xK7qL2026M9zXwVkQ4")
            val storeFilePath = keystoreProperties.getProperty("storeFile", "upload-keystore.jks")
            storeFile = file(storeFilePath)
            storePassword = keystoreProperties.getProperty("storePassword", "J1g5aw#Pr0_99xK7qL2026M9zXwVkQ4")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
