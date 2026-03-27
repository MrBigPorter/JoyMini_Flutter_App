import java.util.Properties
import java.io.FileInputStream
import java.util.Base64

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.gms.google-services")
    id("com.google.firebase.firebase-perf")
}

// 1. 获取并解码 Flutter 传入的 --dart-define-from-file 参数 (Kotlin DSL 版)
val dartEnvironmentVariables = if (project.hasProperty("dart-defines")) {
    project.property("dart-defines").toString().split(",").associate {
        val pair = String(Base64.getDecoder().decode(it)).split("=")
        pair[0] to (if (pair.size > 1) pair[1] else "")
    }
} else {
    emptyMap()
}

// 2. 提取我们在 JSON 里定义的变量
val appIdSuffix = dartEnvironmentVariables["APP_ID_SUFFIX"] ?: ""
val appNameSuffix = dartEnvironmentVariables["APP_NAME_SUFFIX"] ?: ""

// 3. 读取 key.properties 的逻辑
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// 4. 读取 local.properties 里的 Facebook 配置 (新增)
val localProperties = Properties()
// 优先找 Flutter 根目录的 local.properties，找不到再找 android/ 目录下的
var localPropertiesFile = rootProject.file("../local.properties")
if (!localPropertiesFile.exists()) {
    localPropertiesFile = rootProject.file("local.properties")
}
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

// 提取变量，如果文件里没配，默认给个 000000 防报错
val fbAppId = localProperties.getProperty("facebook_app_id") ?: "000000"
val fbClientToken = localProperties.getProperty("facebook_client_token") ?: "000000"
val fbProtocolScheme = localProperties.getProperty("fb_login_protocol_scheme") ?: "fb000000"


android {
    namespace = "com.porter.joyminis"
    compileSdk = 36  //  满足 webview 等插件的要求
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // 动态拼接包名
        applicationId = "com.porter.joyminis$appIdSuffix"

        // 动态修改 App 显示名称
        resValue("string", "app_name", "JoyMini$appNameSuffix")

        //  动态注入 Facebook 相关资源定义 (不再明文写死)
        resValue("string", "facebook_app_id", fbAppId)
        resValue("string", "facebook_client_token", fbClientToken)
        resValue("string", "fb_login_protocol_scheme", fbProtocolScheme)

        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        compose = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")
            val stFile = keystoreProperties.getProperty("storeFile")
            if (stFile != null) {
                storeFile = project.file(stFile)
            }
        }
       getByName("debug") {
           storeFile = project.file("debug.keystore")
           storePassword = "android"
           keyAlias = "androiddebugkey"
           keyPassword = "android"
       }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        //  新增：让所有测试运行都使用刚才定义的固定签名
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

configurations.all {
    resolutionStrategy {
        force("androidx.browser:browser:1.8.0")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.core:core:1.13.1")
        force("androidx.activity:activity:1.8.2")
        force("androidx.activity:activity-ktx:1.8.2")
        force("androidx.activity:activity-compose:1.8.2")
    }
}

dependencies {
    // Amplify
    implementation(platform("com.amplifyframework:core:2.19.1"))
    implementation(platform("com.amplifyframework:aws-auth-cognito:2.19.1"))
    implementation("com.amplifyframework:aws-auth-cognito")
    implementation("com.amplifyframework:core")
    implementation("com.amplifyframework.ui:liveness:1.3.0")

    // Compose
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.appcompat:appcompat:1.6.1")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ML Kit
    implementation("com.google.android.gms:play-services-mlkit-document-scanner:16.0.0")
    implementation("com.google.android.gms:play-services-mlkit-text-recognition:19.0.0")
    implementation("com.google.mlkit:text-recognition-chinese:16.0.0")
    implementation("com.google.android.gms:play-services-mlkit-face-detection:17.1.0")

    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
}