pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // CHANGED: Downgraded to 8.3.2 to match a stable Gradle version
    id("com.android.application") version "8.3.2" apply false
    // Kotlin 1.9.24 is generally safe with this setup
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

include(":app")