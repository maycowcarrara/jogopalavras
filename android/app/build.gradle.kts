import java.io.FileInputStream
import java.util.Base64
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
    }
    val dartDefines = providers.gradleProperty("dart-defines").orNull
        ?.split(",")
        ?.mapNotNull { encoded ->
            runCatching {
                String(Base64.getDecoder().decode(encoded)).split("=", limit = 2)
            }.getOrNull()
        }
        ?.filter { it.size == 2 }
        ?.associate { it[0] to it[1] }
        ?: emptyMap()
    val adsEnabledForBuild = dartDefines["ADS_ENABLED"] == "true"
    val admobAndroidAppId = providers.gradleProperty("ADMOB_ANDROID_APP_ID")
        .orElse(providers.environmentVariable("ADMOB_ANDROID_APP_ID"))
        .orNull
        ?.takeIf { it.isNotBlank() }
    val sampleAndroidAppId = "ca-app-pub-3940256099942544~3347511713"
    if (adsEnabledForBuild && admobAndroidAppId == null) {
        throw GradleException(
            "ADS_ENABLED=true exige ADMOB_ANDROID_APP_ID com o App ID real do AdMob."
        )
    }

    namespace = "br.com.mrcdev.entreletras"
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
        applicationId = "br.com.mrcdev.entreletras"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "admob_app_id", admobAndroidAppId ?: sampleAndroidAppId)
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
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
