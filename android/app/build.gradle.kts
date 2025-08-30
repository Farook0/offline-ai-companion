plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.offline_ai_companion"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.offline_ai_companion"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"

        // Only build for ARM64 (same as Llamao)
        ndk {
            abiFilters += listOf("arm64-v8a")
        }

        
        // Include native libraries
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }
    
    // Configure native library packaging
    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/libs")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        resources {
            excludes += setOf("META-INF/*")
        }
    }

    // Support split APKs like Llamao for future model distribution
    bundle {
        abi {
            enableSplit = true
        }
        density {
            enableSplit = false
        }
        language {
            enableSplit = false
        }
    }

    // Enable compression for faster loading
    androidResources {
        ignoreAssetsPattern = "!.svn:!.git:!.ds_store:!*.scc:.*:!CVS:!thumbs.db:!picasa.ini:!*~"
        noCompress += listOf("gguf")
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    
    // JSON parsing for MLC configuration (like Llamao)
    implementation("com.google.code.gson:gson:2.10.1")
    implementation("org.json:json:20230227")
    
    // TVM runtime is bundled as native library (libtvm4j_runtime_packed.so)
    // We'll use direct JNI calls to TVM runtime (same as Llamao)
}