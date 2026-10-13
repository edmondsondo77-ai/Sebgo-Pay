 plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    buildToolsVersion = "36.0.0"
    namespace = "com.example.sebgo_new"
    
    compileSdk = 36
    ndkVersion = "25.1.8937393"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    flavorDimensions += "default"

   defaultConfig {
        applicationId = "com.example.sebgo_new"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // RE-AJOUTEZ CECI pour forcer l'inclusion des architectures courantes
        ndk {
            abiFilters.addAll(setOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
      // Ajoutez ceci juste en dessous pour bloquer le plantage du strip
    buildFeatures {
        prefab = false
    }
    
      buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false // Ajoutez ceci pour désactiver le shrinking de ressources si minify est à false
            isDebuggable = false
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false // Assurez-vous qu'il est aussi à false en debug
            isDebuggable = true
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

tasks.withType<com.android.build.gradle.internal.tasks.StripDebugSymbolsTask>().configureEach {
    enabled = false
}

tasks.withType<com.android.build.gradle.internal.tasks.StripDebugSymbolsTask>().configureEach {
    enabled = false
}

tasks.withType<com.android.build.gradle.internal.tasks.ExtractNativeDebugMetadataTask>().configureEach {
    enabled = false
}