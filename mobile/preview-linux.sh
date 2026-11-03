#!/usr/bin/env bash
# Quick launcher for Mobile Shadowsocks Linux Desktop Preview
# Supports real-time QML Hot-Reloading: modify any QML file and see changes immediately!

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_PATH="$SCRIPT_DIR/bin/ssclient_mobile"

if [ ! -f "$BIN_PATH" ]; then
    echo "🔨 Compiling mobile application for Linux..."
    make -C "$SCRIPT_DIR" -f Makefile_linux -j$(nproc)
fi

echo "🚀 Starting Shadowsocks Mobile Preview on Linux..."
echo "💡 Hot-reload is active: edit files in mobile/src/ui/qml/ to update the interface automatically (or press F5)."
exec "$BIN_PATH" "$@"
