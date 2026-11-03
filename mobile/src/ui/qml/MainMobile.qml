import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "views"
import "dialogs"

ApplicationWindow {
    id: window
    width: 390
    height: 780
    minimumWidth: 340
    minimumHeight: 600
    visible: true
    title: "Shadowsocks Mobile"
    color: "#080808"

    FontLoader { id: fontSerif; source: "qrc:/src/ui/assets/fonts/InstrumentSerif-Regular.ttf" }
    FontLoader { id: fontSerifItalic; source: "qrc:/src/ui/assets/fonts/InstrumentSerif-Italic.ttf" }
    FontLoader { id: fontSans; source: "qrc:/src/ui/assets/fonts/InstrumentSans-Variable.ttf" }

    property int currentNavIndex: 0 // 0: Radar, 1: Nodes, 2: Config, 3: Logs

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 1. Mobile Top Status Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: "#0D0D0D"
            border.color: "#1A1A1A"
            border.width: 1
            z: 5

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                Rectangle {
                    width: 22
                    height: 22
                    color: "#CCFF00"
                }

                Text {
                    text: "SHADOWSOCKS"
                    font.family: Theme.fontHeading
                    font.pixelSize: 18
                    color: "#FFFFFF"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: appController.isConnected ? "#CCFF00" : (appController.isConnecting ? "#FFB800" : "#444444")
                }

                Text {
                    text: appController.isConnected ? "CONNECTED" : (appController.isConnecting ? "CONNECTING..." : "DISCONNECTED")
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: appController.isConnected ? "#CCFF00" : "#666666"
                }
            }
        }

        // 2. Active Screen View Container
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MobileDashboardView {
                id: dashView
                anchors.fill: parent
                visible: window.currentNavIndex === 0
                onRequestSwitchToServers: window.currentNavIndex = 1
            }

            MobileServersView {
                id: serversView
                anchors.fill: parent
                visible: window.currentNavIndex === 1
                onRequestAddServer: addServerDialog.openDialog()
                onRequestImportUrl: importUrlDialog.openDialog()
            }

            MobileSettingsView {
                id: settingsView
                anchors.fill: parent
                visible: window.currentNavIndex === 2
            }

            MobileLogsView {
                id: logsView
                anchors.fill: parent
                visible: window.currentNavIndex === 3
            }
        }
    }

    // 3. Floating Bottom Navigation Dock
    BottomNavBar {
        id: bottomNavBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 28, 440)
        z: 20
        currentIndex: window.currentNavIndex
        onTabSelected: function(idx) {
            window.currentNavIndex = idx
        }
    }

    // Dialogs
    AddServerDialog {
        id: addServerDialog
        anchors.fill: parent
        z: 30
    }

    ImportUrlDialog {
        id: importUrlDialog
        anchors.fill: parent
        z: 30
    }

    // Toast Notification Banner (floats right above the bottom dock)
    Rectangle {
        id: toastBanner
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomNavBar.top
        anchors.bottomMargin: 10
        width: Math.min(parent.width - 40, toastText.implicitWidth + 32)
        height: 36
        radius: 0
        color: "#141414"
        border.color: "#CCFF00"
        border.width: 1
        opacity: 0.0
        z: 25

        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            id: toastText
            anchors.centerIn: parent
            font.family: Theme.fontMono
            font.pixelSize: 11
            color: "#FFFFFF"
        }

        Timer {
            id: toastTimer
            interval: 2200
            onTriggered: toastBanner.opacity = 0.0
        }
    }

    Connections {
        target: appController
        function onToastRequested(msg) {
            toastText.text = msg
            toastBanner.opacity = 1.0
            toastTimer.restart()
        }
    }
}
