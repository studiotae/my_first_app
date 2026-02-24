plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ★ここが修正ポイント：道具箱（Import）を明記しました
import java.util.Properties
import java.io.FileInputStream

// 鍵ファイルの読み込み設定
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.studio.tae"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
    }

    defaultConfig {
        // ★デバッグビルドのパッケージ名を明示的に指定
        applicationId = "com.studio.tae"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // ★書き方を変えてエラーを回避しました
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")
            
            // ファイルの場所を指定
            val keyFileName = keystoreProperties.getProperty("storeFile")
            if (keyFileName != null) {
                storeFile = file(keyFileName)
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = null  // デバッグでもパッケージ名を変更しない
        }
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

dependencies {
    implementation("com.google.mlkit:text-recognition-japanese:16.0.0")
}