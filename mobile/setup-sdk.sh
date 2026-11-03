#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_BASE="$SCRIPT_DIR/.android-sdk"
SDK_DIR="$ANDROID_BASE/Sdk"
JDK_DIR="$ANDROID_BASE/jdk-17"
GRADLE_DIR="$ANDROID_BASE/gradle"

mkdir -p "$ANDROID_BASE"

echo "=== Setting up Android SDK environment in $ANDROID_BASE ==="

# 1. Check / install Java 17
if command -v java &>/dev/null && java -version 2>&1 | grep -q "17"; then
    echo "✔ System Java 17 detected"
elif [ -x "$JDK_DIR/bin/java" ]; then
    echo "✔ Portable Java 17 detected in $JDK_DIR"
    export JAVA_HOME="$JDK_DIR"
    export PATH="$JDK_DIR/bin:$PATH"
else
    echo "⬇ Downloading portable OpenJDK 17 (Adoptium Temurin)..."
    JDK_TAR="/tmp/temurin17.tar.gz"
    curl -L -o "$JDK_TAR" "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz"
    mkdir -p "$JDK_DIR"
    tar -xzf "$JDK_TAR" -C "$JDK_DIR" --strip-components=1
    rm -f "$JDK_TAR"
    export JAVA_HOME="$JDK_DIR"
    export PATH="$JDK_DIR/bin:$PATH"
    echo "✔ Java 17 installed in $JDK_DIR"
fi

if [ -z "$JAVA_HOME" ]; then
    export JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"
fi
echo "JAVA_HOME: $JAVA_HOME"

# 2. Check / install Gradle
if command -v gradle &>/dev/null; then
    echo "✔ System Gradle found: $(gradle -v 2>&1 | head -n1)"
elif [ -x "$GRADLE_DIR/bin/gradle" ]; then
    echo "✔ Portable Gradle found in $GRADLE_DIR"
    export PATH="$GRADLE_DIR/bin:$PATH"
else
    echo "⬇ Downloading Gradle 8.7..."
    GRADLE_ZIP="/tmp/gradle.zip"
    curl -L -o "$GRADLE_ZIP" "https://services.gradle.org/distributions/gradle-8.7-bin.zip"
    mkdir -p "$GRADLE_DIR"
    unzip -q "$GRADLE_ZIP" -d "/tmp/gradle-temp"
    mv /tmp/gradle-temp/gradle-*/* "$GRADLE_DIR/"
    rm -f "$GRADLE_ZIP"
    rm -rf "/tmp/gradle-temp"
    export PATH="$GRADLE_DIR/bin:$PATH"
    echo "✔ Gradle 8.7 installed in $GRADLE_DIR"
fi

# 3. Android SDK Command-line Tools
mkdir -p "$SDK_DIR/cmdline-tools"

if [ ! -d "$SDK_DIR/cmdline-tools/latest" ]; then
    echo "⬇ Downloading official Android Command-line Tools..."
    CMDLINE_ZIP="/tmp/cmdline-tools.zip"
    curl -L -o "$CMDLINE_ZIP" "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    unzip -q "$CMDLINE_ZIP" -d "/tmp/cmdline-temp"
    mv "/tmp/cmdline-temp/cmdline-tools" "$SDK_DIR/cmdline-tools/latest"
    rm -f "$CMDLINE_ZIP"
    rm -rf "/tmp/cmdline-temp"
    echo "✔ Command-line tools installed in $SDK_DIR/cmdline-tools/latest"
fi

SDKMANAGER="$SDK_DIR/cmdline-tools/latest/bin/sdkmanager"
if [ -f "$SDKMANAGER" ]; then
    echo "⚡ Accepting licenses and installing Android SDK packages..."
    yes | "$SDKMANAGER" --licenses > /dev/null 2>&1 || true
    "$SDKMANAGER" "platform-tools" "platforms;android-34" "build-tools;34.0.0"
    echo "✔ Android 34 platform and build tools installed!"
fi

# 4. OpenSSL 3 for Android
OPENSSL_ARM64_DIR="$SCRIPT_DIR/android/libs/arm64-v8a"
mkdir -p "$OPENSSL_ARM64_DIR"

if [ ! -f "$OPENSSL_ARM64_DIR/libcrypto.so" ] || [ ! -f "$OPENSSL_ARM64_DIR/libssl.so" ]; then
    echo "⚡ Downloading OpenSSL 3 for Android arm64..."
    curl -L -s -o "$OPENSSL_ARM64_DIR/libcrypto.so" "https://raw.githubusercontent.com/KDAB/android_openssl/master/ssl_3/arm64-v8a/libcrypto_3.so" || true
    curl -L -s -o "$OPENSSL_ARM64_DIR/libssl.so" "https://raw.githubusercontent.com/KDAB/android_openssl/master/ssl_3/arm64-v8a/libssl_3.so" || true
    echo "✔ OpenSSL 3 libraries configured"
fi

echo ""
echo "🎉 Android environment setup completed in $ANDROID_BASE!"
