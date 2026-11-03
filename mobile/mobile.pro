QT += core gui qml quick network
CONFIG += c++17

TARGET = ssclient_mobile
TEMPLATE = app

!android {
    DESTDIR = $$PWD/bin
}

android {
    OBJECTS_DIR = $$OUT_PWD/.obj_android
    MOC_DIR = $$OUT_PWD/.moc_android
    RCC_DIR = $$OUT_PWD/.rcc_android
    UI_DIR = $$OUT_PWD/.ui_android
} else {
    OBJECTS_DIR = $$PWD/build/.obj
    MOC_DIR = $$PWD/build/.moc
    RCC_DIR = $$PWD/build/.rcc
    UI_DIR = $$PWD/build/.ui
}

INCLUDEPATH += $$PWD/src $$PWD/../src

# OpenSSL dependency
!android {
    PKGCONFIG += openssl
    CONFIG += link_pkgconfig
}

android {
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
    INCLUDEPATH += $$PWD/android/openssl/include $$PWD/3rdparty/hev-socks5-tunnel/src
    LIBS += -L$$PWD/android/libs/arm64-v8a -lssl_3 -lcrypto_3 -lhev-socks5-tunnel
    ANDROID_EXTRA_LIBS += \
        $$PWD/android/libs/arm64-v8a/libcrypto_3.so \
        $$PWD/android/libs/arm64-v8a/libssl_3.so \
        $$PWD/android/libs/arm64-v8a/libhev-socks5-tunnel.so
    DISTFILES += \
        android/AndroidManifest.xml \
        android/src/org/shadowsocks/client/ShadowsocksVpnService.java \
        android/src/hev/htproxy/TProxyService.java
}
SOURCES += \
    src/main_mobile.cpp \
    src/controllers/AndroidVpnBridge.cpp \
    src/controllers/MobileAppController.cpp \
    ../src/core/Crypto.cpp \
    ../src/core/Socks5Session.cpp \
    ../src/core/ShadowsocksServer.cpp \
    ../src/core/TrafficMeter.cpp \
    ../src/core/PingService.cpp \
    ../src/models/ServerConfig.cpp \
    ../src/models/ServerModel.cpp \
    ../src/models/AppSettings.cpp

# Header files
HEADERS += \
    src/controllers/AndroidVpnBridge.h \
    src/controllers/MobileAppController.h \
    ../src/core/Crypto.h \
    ../src/core/Socks5Session.h \
    ../src/core/ShadowsocksServer.h \
    ../src/core/TrafficMeter.h \
    ../src/core/PingService.h \
    ../src/models/ServerConfig.h \
    ../src/models/ServerModel.h \
    ../src/models/AppSettings.h

# Resources
RESOURCES += \
    resources_mobile.qrc

# Android specifics
android {
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
    DISTFILES += \
        android/AndroidManifest.xml \
        android/src/org/shadowsocks/client/ShadowsocksVpnService.java \
        android/src/hev/htproxy/TProxyService.java
}
