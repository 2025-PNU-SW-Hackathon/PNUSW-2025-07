@echo off
echo SimLog Keystore 생성 중...
echo.

REM Android SDK의 keytool 경로 찾기
set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
set "JAVA_HOME=%ANDROID_HOME%\jbr"

REM keytool 실행
"%JAVA_HOME%\bin\keytool.exe" -genkey -v -keystore simlog-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias simlog-key -storepass simlog123 -keypass simlog123 -dname "CN=SimLog, OU=Development, O=SimLog, L=Seoul, S=Seoul, C=KR"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Keystore 생성 완료: simlog-key.jks
    echo.
    echo 📝 다음 단계:
    echo 1. key.properties 파일의 비밀번호를 실제 값으로 변경
    echo 2. flutter build apk --release 실행
) else (
    echo.
    echo ❌ Keystore 생성 실패
    echo Android Studio의 Java 경로를 확인해주세요
)

pause
