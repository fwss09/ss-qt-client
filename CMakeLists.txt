cmake_minimum_required(VERSION 3.16)
project(ssclient LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Network Widgets)
find_package(OpenSSL REQUIRED)

set(SOURCES
    src/main.cpp
    src/core/Crypto.cpp
    src/core/Socks5Session.cpp
    src/core/ShadowsocksServer.cpp
    src/core/TrafficMeter.cpp
    src/core/PingService.cpp
    src/models/ServerConfig.cpp
    src/models/ServerModel.cpp
    src/models/AppSettings.cpp
    src/controllers/SystemProxy.cpp
    src/controllers/AppController.cpp
    resources.qrc
)

add_executable(ssclient ${SOURCES})

target_include_directories(ssclient PRIVATE src)

target_link_libraries(ssclient PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
    Qt6::Widgets
    OpenSSL::SSL
    OpenSSL::Crypto
)
