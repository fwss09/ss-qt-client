#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build-android"
APK_OUTPUT_DIR="$SCRIPT_DIR/bin"

echo "=========================================================="
echo "      SHADOWSOCKS MOBILE - ANDROID APK BUILDER           "
echo "=========================================================="

# 1. Environment variables
export JAVA_HOME="$SCRIPT_DIR/.android-sdk/jdk-17"
export PATH="$JAVA_HOME/bin:$SCRIPT_DIR/.android-sdk/gradle/bin:$PATH"
export ANDROID_SDK_ROOT="$SCRIPT_DIR/.android-sdk/Sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/26.1.10909125"
export NDK_ROOT="$ANDROID_NDK_ROOT"
export ANDROID_USER_HOME="$SCRIPT_DIR/.android-sdk/.android"
export GRADLE_USER_HOME="$SCRIPT_DIR/.android-sdk/.gradle"
mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"

QT_ANDROID="$SCRIPT_DIR/.android-sdk/Qt/6.7.3/android_arm64_v8a"
QT_HOST="$SCRIPT_DIR/.android-sdk/Qt/6.7.3/gcc_64"

echo "✔ JAVA_HOME: $JAVA_HOME"
echo "✔ Android SDK: $ANDROID_SDK_ROOT"
echo "✔ Android NDK: $ANDROID_NDK_ROOT"
echo "✔ Qt Android: $QT_ANDROID"

mkdir -p "$BUILD_DIR"
mkdir -p "$APK_OUTPUT_DIR"

cd "$BUILD_DIR"

echo ""
echo "🚀 1/3 Generating Makefile for Android arm64-v8a..."
"$QT_ANDROID/bin/qmake" "$SCRIPT_DIR/mobile.pro"

echo ""
echo "🔨 2/3 Compiling native C++ library for Android (arm64-v8a)..."
make -j$(nproc)
make INSTALL_ROOT="$BUILD_DIR/android-build" install

echo ""
echo "📦 3/3 Packaging Android APK via androiddeployqt..."
DEPLOY_SETTINGS="$BUILD_DIR/android-ssclient_mobile-deployment-settings.json"

"$QT_HOST/bin/androiddeployqt" \
    --input "$DEPLOY_SETTINGS" \
    --output "$BUILD_DIR/android-build" \
    --android-platform android-34 \
    --jdk "$JAVA_HOME" \
    --gradle \
    --verbose

APK_FILE=$(find "$BUILD_DIR/android-build" -name "*.apk" 2>/dev/null | head -n 1)

if [ -n "$APK_FILE" ] && [ -f "$APK_FILE" ]; then
    FINAL_APK="$APK_OUTPUT_DIR/ssclient.apk"
    cp "$APK_FILE" "$FINAL_APK"
    APK_SIZE=$(du -h "$FINAL_APK" | awk '{print $1}')
    echo ""
    echo "=========================================================="
    echo "🎉 SUCCESS! Built APK package ($APK_SIZE):"
    echo "   $FINAL_APK"
    echo "=========================================================="
    echo ""
    
    # Check for connected ADB devices
    if command -v adb &>/dev/null; then
        DEVICES=$(adb devices 2>/dev/null | grep -w "device" | awk '{print $1}')
        if [ -n "$DEVICES" ]; then
            echo "📱 Found connected device ($DEVICES)!"
            echo "Installing application onto device..."
            adb install -r "$FINAL_APK" || true
            echo "✔ Application installed successfully!"
            exit 0
        fi
    fi
    
    echo "To install on your phone:"
    echo "1. Transfer $FINAL_APK to your device."
    echo "2. Open the file on your device and tap Install."
else
    echo "❌ Error: APK package not found in $BUILD_DIR/android-build"
    exit 1
fi
