// android/app/build.gradle.kts
import java.util.Properties

// 1) ルートの .env を読み込むユーティリティ
fun loadDotEnv(): Properties {
    val props = Properties()
    val f = rootProject.file(".env")
    if (f.exists()) {
        f.inputStream().use { props.load(it) } // KEY=VALUE を読み込み
    }
    return props
}

// 2) Gradle プロパティ or .env の順で解決するヘルパ
fun resolveSecret(key: String, env: Properties): String {
    // ./gradlew -PKEY=... や gradle.properties の優先
    val fromGradle = findProperty(key)?.toString()
        ?: providers.gradleProperty(key).orNull
    return (fromGradle ?: env.getProperty(key, "")).trim()
}

val envProps = loadDotEnv()
val googleMapsKeyAndroid = resolveSecret("GOOGLE_MAPS_KEY_ANDROID", envProps)

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.toranomon.civictech"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.2.12479018"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.toranomon.civictech"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 30
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ★ Manifest の ${GOOGLE_MAPS_KEY} に注入
        manifestPlaceholders["GOOGLE_MAPS_KEY"] = googleMapsKeyAndroid
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(project(":unityLibrary"))
}
