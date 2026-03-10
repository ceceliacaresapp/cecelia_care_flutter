plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cecelia_care_flutter"
    compileSdk = flutter.compileSdkVersion
    // REMOVED: ndkVersion to prevent download hangs in IDX
    // ndkVersion = "27.0.12077973" 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.cecelia_care_flutter"
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// FIX: Force versions that support Stylus features (fixing the crash)
// but don't require the newest AGP (fixing the build error).
configurations.all {
    resolutionStrategy {
        force("androidx.browser:browser:1.8.0")
        
        // Activity 1.9.3 is stable and works with Core 1.13.1
        force("androidx.activity:activity-ktx:1.9.3")
        force("androidx.activity:activity:1.9.3")

        // CRITICAL: 1.13.1 contains 'setStylusHandwritingEnabled' 
        // which prevents the "NoSuchMethodError" crash at startup.
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.core:core:1.13.1")
    }
}