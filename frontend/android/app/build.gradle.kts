import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 키스토어 설정 로드
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.simlog.app"
    compileSdk = 35  // Android 15 (API 35) - url_launcher_android 호환성
    ndkVersion = "27.0.12077973"

    // SDK 버전 관계 검증: minSdk <= targetSdk <= compileSdk
    // minSdk: 23 (Android 6.0) - 최소 지원 버전
    // targetSdk: 33 (Android 13) - 타겟 버전  
    // compileSdk: 35 (Android 15) - 컴파일 버전 (최신 플러그인 호환성)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // SimLog 앱용 고유 Application ID
        applicationId = "com.simlog.app"
        // 앱 이름과 설명
        resValue("string", "app_name", "SimLog")
        // SDK 버전 설정 (minSdk <= targetSdk <= compileSdk)
        minSdk = 23        // Android 6.0 (API 23) - 최소 지원 버전
        targetSdk = 33     // Android 13 (API 33) - 타겟 버전
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // 멀티덱스 지원 (APK 크기 제한 우회)
        multiDexEnabled = true
        
        // 네이티브 라이브러리 ABI 설정 제거 (범용 APK 생성)
        // ndk.abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
        
        // 앱 안정성을 위한 추가 설정
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        
        // 크래시 방지를 위한 설정
        vectorDrawables.useSupportLibrary = true
    }

            signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it.toString()) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }

    buildTypes {
        release {
            // 릴리즈 빌드에 서명 설정 적용 (키스토어가 있을 때만)
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            // 코드 최적화 비활성화 (APK 파싱 오류 방지)
            isMinifyEnabled = false
            isShrinkResources = false
            // ProGuard 규칙은 유지하되 최적화는 비활성화
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            // 디버그 빌드 설정
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 멀티덱스 지원 (APK 크기 제한 우회)
    implementation("androidx.multidex:multidex:2.0.1")
}
