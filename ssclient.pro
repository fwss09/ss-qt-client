QT += core gui qml quick network widgets
CONFIG += c++17

TARGET = ssclient
TEMPLATE = app

# Output directories
DESTDIR = $$PWD/bin
OBJECTS_DIR = $$PWD/build/.obj
MOC_DIR = $$PWD/build/.moc
RCC_DIR = $$PWD/build/.rcc
UI_DIR = $$PWD/build/.ui

INCLUDEPATH += $$PWD/src

# OpenSSL dependency
PKGCONFIG += openssl
CONFIG += link_pkgconfig

# Source files
SOURCES += \
    src/main.cpp \
    src/core/Crypto.cpp \
    src/core/Socks5Session.cpp \
    src/core/ShadowsocksServer.cpp \
    src/core/TrafficMeter.cpp \
    src/core/PingService.cpp \
    src/models/ServerConfig.cpp \
    src/models/ServerModel.cpp \
    src/models/AppSettings.cpp \
    src/controllers/SystemProxy.cpp \
    src/controllers/AppController.cpp

# Header files
HEADERS += \
    src/core/Crypto.h \
    src/core/Socks5Session.h \
    src/core/ShadowsocksServer.h \
    src/core/TrafficMeter.h \
    src/core/PingService.h \
    src/models/ServerConfig.h \
    src/models/ServerModel.h \
    src/models/AppSettings.h \
    src/controllers/SystemProxy.h \
    src/controllers/AppController.h

# Resources
RESOURCES += \
    resources.qrc
