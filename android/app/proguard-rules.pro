# Flutter 관련 규칙 (필수)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 앱 관련 클래스 보존 (필수)
-keep class com.simlog.app.** { *; }
-keep class com.simlog.app.MainActivity { *; }
-keep class com.simlog.app.MainApplication { *; }

# HTTP 관련 규칙
-keep class com.simlog.app.** { *; }

# 음성 녹음 관련 규칙
-keep class com.llfbandit.record.** { *; }

# 권한 관련 규칙
-keep class com.baseflow.permissionhandler.** { *; }

# Google Play Core 관련 규칙 (Release 빌드 오류 방지)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter Deferred Components 관련 규칙
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# 앱 크래시 방지를 위한 추가 규칙
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions,InnerClasses

# 네이티브 메서드 보존
-keepclasseswithmembernames class * {
    native <methods>;
}

# Parcelable 구현체 보존
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Serializable 구현체 보존
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Missing classes warning suppression (자동 생성된 규칙)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# 일반적인 경고 억제
-dontwarn android.**
-dontwarn androidx.**
-dontwarn com.google.**
