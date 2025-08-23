// android/app/build.gradle.kts
import java.util.Properties

// 1) ルートの .env を読み込むユーティリティ
fun loadDotEnv(): Properties {
    val props = Properties()
    
    // 複数のパスで.envファイルを探す
    val possiblePaths = listOf(
        rootProject.file(".env"),
        project.file("../.env"),
        project.file("../../.env")
    )
    
    var envFile = possiblePaths.find { it.exists() }
    
    if (envFile != null) {
        envFile.inputStream().use { props.load(it) } // KEY=VALUE を読み込み
        println("Android Build - .env file loaded successfully from: ${envFile.absolutePath}")
    } else {
        println("Android Build - .env file not found in any of the following paths:")
        possiblePaths.forEach { path ->
            println("  - ${path.absolutePath}")
        }
    }
    return props
}

// 2) Gradle プロパティ or .env の順で解決するヘルパ
fun resolveSecret(key: String, env: Properties): String {
    // ./gradlew -PKEY=... や gradle.properties の優先
    val fromGradle = findProperty(key)?.toString()
        ?: providers.gradleProperty(key).orNull
    val result = (fromGradle ?: env.getProperty(key, "")).trim()
    
    // APIキーの読み取り状況をログ出力
    if (key == "GOOGLE_MAPS_KEY_ANDROID") {
        if (result.isNotEmpty()) {
            println("Android Build - Google Maps API Key loaded: ${result.substring(0, 10)}...")
            println("Android Build - Google Maps API Key length: ${result.length} characters")
        } else {
            println("Android Build - Google Maps API Key is empty or not found")
        }
    }
    
    return result
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
