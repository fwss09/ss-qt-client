# Shadowsocks Mobile Client (Android & Mobile Preview)

A mobile client port of the Shadowsocks application, preserving 100% of the native cryptographic core and brutalist tactical UI design.

---

## Architecture

* **Native Core**: 
  * C++17 + OpenSSL 3 + Qt 6 Network.
  * Direct re-use of the root SIP004 cryptographic engine (`Crypto.cpp`), SOCKS5 sessions (`Socks5Session.cpp`), and data models from `../src`.
* **Android VPN Subsystem**:
  * Implementation of `android.net.VpnService` in `android/src/org/shadowsocks/client/ShadowsocksVpnService.java`.
  * Bi-directional JNI bridge `src/controllers/AndroidVpnBridge.cpp` (`QJniObject`):
    * Requests system VPN permissions (`VpnService.prepare()`).
    * Captures TUN file descriptor (`pfd.detachFd()`).
    * Implements package routing rules and socket protection via `VpnService.protect(fd)` to prevent routing loops.
* **Mobile UI (QML)**:
  * Compact vertical layout optimized for smartphone screens (390x800).
  * Bottom navigation bar (Radar, Nodes, Config, Logs).
  * Interactive 3D Tactical Radar Globe (`TacticalGlobe.qml`) adapted for touch interaction.
  * Real-time network speed graphs and node status indicators.

---

## Desktop Mobile Preview

You can test and run the mobile layout directly on a Linux desktop:

```bash
./mobile/preview-linux.sh
```

Hot-Reload is active during preview mode: edit any file in `mobile/src/ui/qml/` and press `F5` (or save) to refresh instantly.

---

## Building Android APK

### Prerequisites
1. **Qt 6 for Android** (Qt 6.5+ arm64-v8a).
2. **Android NDK** (r25b or r26).
3. **Android SDK** (API level 33 or 34).
4. **OpenSSL for Android** (`libcrypto.so`, `libssl.so` for arm64-v8a).

### Build Script:
```bash
cd mobile
./build-apk.sh
```

The resulting package will be output to `mobile/bin/ssclient.apk`.
