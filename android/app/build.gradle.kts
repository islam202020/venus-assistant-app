plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

// --- بداية الكود المضاف ---
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = java.util.Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(java.io.FileInputStream(keyPropertiesFile))
}
// --- نهاية الكود المضاف ---

// هذا القسم مهم جدًا لفلاتر، تأكد من وجوده
flutter {
    source = "../.."
}

android {
    namespace = "com.example.venus_assistant_app"
    compileSdk = 34

    // --- بداية قسم التوقيع المضاف ---
    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
            storeFile = keyProperties["storeFile"]?.let { file(it) }
            storePassword = keyProperties["storePassword"] as String?
        }
    }
    // --- نهاية قسم التوقيع المضاف ---

    defaultConfig {
        applicationId = "com.example.venus_assistant_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // --- بداية السطر المعدل ---
            signingConfig = signingConfigs.getByName("release")
            // --- نهاية السطر المعدل ---
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core.core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("com.google.firebase:firebase-analytics:21.5.1")
}