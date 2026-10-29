import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.pos_product"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.pos_product"
        // Prefer the environment variable (CI), then android/local.properties for local development.
        // Use fully qualified Java names so Kotlin DSL does not resolve java.util as a Gradle extension.
        val mapsProperties = Properties()
        val mapsPropertiesFile = rootProject.file("local.properties")
        if (mapsPropertiesFile.exists()) {
            mapsPropertiesFile.inputStream().use { input ->
                mapsProperties.load(input)
            }
        }
        val mapsApiKey = System.getenv("MAPS_API_KEY")?.takeIf { it.isNotBlank() }
            ?: mapsProperties.getProperty("maps.api.key")?.trim().orEmpty()
        if (mapsApiKey.isBlank()) {
            logger.warn("MAPS_API_KEY is empty. Google Maps will render a blank/grey map until a valid Android Maps SDK key is configured.")
        }
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

tasks.register<Copy>("copyDebugApkToFlutterOutput") {
    dependsOn("assembleDebug")

    from(layout.buildDirectory.file("outputs/apk/debug/app-debug.apk"))
    into(rootProject.layout.projectDirectory.dir("../build/app/outputs/flutter-apk"))
    rename { "app-debug.apk" }
}


val flutterApkSource = layout.buildDirectory.dir("outputs/flutter-apk")
val flutterApkDestination =
    rootProject.layout.projectDirectory.dir("../build/app/outputs/flutter-apk")

tasks.register<Copy>("syncFlutterApksToFlutterCli") {
    from(flutterApkSource)
    into(flutterApkDestination)
}

tasks.matching {
    it.name == "assembleDebug" || it.name == "assembleRelease"
}.configureEach {
    finalizedBy("syncFlutterApksToFlutterCli")
}
