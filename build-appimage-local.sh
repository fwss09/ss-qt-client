#!/usr/bin/env bash
set -e

APP_DIR="AppDir_Local"
rm -rf "$APP_DIR" skugg-x86_64.AppImage
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/lib"
mkdir -p "$APP_DIR/usr/qml"
mkdir -p "$APP_DIR/usr/plugins"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/scalable/apps"
mkdir -p "$APP_DIR/usr/share/skugg/scripts"

echo "==> 1. Copying binaries and assets..."
cp bin/ssclient "$APP_DIR/usr/bin/skugg"
if [ -f bin/tun2socks ]; then
  cp bin/tun2socks "$APP_DIR/usr/bin/tun2socks"
fi
if [ -d scripts ]; then
  cp -r scripts/* "$APP_DIR/usr/share/skugg/scripts/"
fi

cp skugg.desktop "$APP_DIR/"
cp skugg.desktop "$APP_DIR/usr/share/applications/"
cp skugg.svg "$APP_DIR/"
cp skugg.svg "$APP_DIR/usr/share/icons/hicolor/scalable/apps/"
cp skugg.png "$APP_DIR/"
cp skugg.png "$APP_DIR/.DirIcon"

echo "==> 2. Copying dynamic library dependencies..."
for lib in $(ldd bin/ssclient | awk '{if ($3 ~ /^\//) print $3}'); do
  # Skip essential glibc system libraries to maximize portability
  case "$(basename "$lib")" in
    libc.so*|libm.so*|libpthread.so*|libdl.so*|librt.so*|ld-linux*.so*|libresolv.so*)
      continue
      ;;
  esac
  cp -u -L "$lib" "$APP_DIR/usr/lib/" 2>/dev/null || true
done

echo "==> 3. Copying Qt6 QML modules..."
# Copy QtQuick, QtQml and core components
QT_QML="/usr/lib/qt6/qml"
if [ -d "$QT_QML" ]; then
  for mod in QtQuick QtQml QtCore; do
    if [ -d "$QT_QML/$mod" ]; then
      cp -r -L "$QT_QML/$mod" "$APP_DIR/usr/qml/"
    fi
  done
fi

echo "==> 4. Copying Qt6 plugins..."
QT_PLUGINS="/usr/lib/qt6/plugins"
if [ -d "$QT_PLUGINS" ]; then
  for p in platforms platformthemes styles xcbglintegrations imageformats; do
    if [ -d "$QT_PLUGINS/$p" ]; then
      cp -r -L "$QT_PLUGINS/$p" "$APP_DIR/usr/plugins/"
    fi
  done
fi

# Ensure dependencies of plugins are also in usr/lib
for so in $(find "$APP_DIR/usr/plugins" "$APP_DIR/usr/qml" -name "*.so" 2>/dev/null); do
  for lib in $(ldd "$so" 2>/dev/null | awk '{if ($3 ~ /^\//) print $3}'); do
    case "$(basename "$lib")" in
      libc.so*|libm.so*|libpthread.so*|libdl.so*|librt.so*|ld-linux*.so*)
        continue
        ;;
    esac
    cp -u -L "$lib" "$APP_DIR/usr/lib/" 2>/dev/null || true
  done
done

echo "==> 5. Creating custom AppRun launcher..."
cat << 'EOF' > "$APP_DIR/AppRun"
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export QML2_IMPORT_PATH="${HERE}/usr/qml:${QML2_IMPORT_PATH}"
export QT_PLUGIN_PATH="${HERE}/usr/plugins:${QT_PLUGIN_PATH}"
export QT_QPA_PLATFORM_PLUGIN_PATH="${HERE}/usr/plugins/platforms"
exec "${HERE}/usr/bin/skugg" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

echo "==> 6. Packaging AppImage with appimagetool..."
ARCH=x86_64 /tmp/appimagetool-extracted/AppRun --runtime-file /tmp/runtime-x86_64 "$APP_DIR" skugg-x86_64.AppImage

echo "==> Done! Output: skugg-x86_64.AppImage"
ls -lh skugg-x86_64.AppImage
