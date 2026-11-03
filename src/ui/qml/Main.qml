import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "views"
import "dialogs"

ApplicationWindow {
    id: window
    width: 980
    height: 660
    minimumWidth: 840
    minimumHeight: 560
    visible: true
    title: "Shadowsocks VPN"
    color: "#080808"

    FontLoader { id: fontSerif; source: "../assets/fonts/InstrumentSerif-Regular.ttf" }
    FontLoader { id: fontSerifItalic; source: "../assets/fonts/InstrumentSerif-Italic.ttf" }
    FontLoader { id: fontSans; source: "../assets/fonts/InstrumentSans-Variable.ttf" }

    property int currentNavIndex: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 230
            Layout.fillHeight: true
            color: "#0F0F0F"
            border.color: "#222222"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    spacing: 12
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 0
                        color: "#CCFF00"
                    }

                    Column {
                        spacing: 1
                        Text {
                            text: "Shadowsocks"
                            font.pixelSize: 21
                            font.family: Theme.fontHeading
                            color: "#FFFFFF"
                        }
                        Text {
                            text: "v1.0.0"
                            font.pixelSize: 10
                            font.family: Theme.fontMono
                            color: "#555555"
                        }
                    }
                }

                Item { height: 20 }

                Text {
                    text: "NAVIGATION"
                    font.pixelSize: 9
                    font.family: Theme.fontMono
                    color: "#444444"
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 2
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 0
                        color: window.currentNavIndex === 0 ? "#1C1C1C" : (navMouse0.containsMouse ? "#141414" : "transparent")
                        border.color: window.currentNavIndex === 0 ? "#333333" : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10
                            Text {
                                text: window.currentNavIndex === 0 ? "■" : "·"
                                font.pixelSize: window.currentNavIndex === 0 ? 8 : 12
                                color: window.currentNavIndex === 0 ? "#FFFFFF" : "#444444"
                            }
                            Text {
                                text: "Dashboard"
                                font.pixelSize: 12
                                font.family: Theme.fontBody
                                color: window.currentNavIndex === 0 ? "#FFFFFF" : "#777777"
                            }
                        }

                        MouseArea {
                            id: navMouse0
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentNavIndex = 0
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 0
                        color: window.currentNavIndex === 1 ? "#1C1C1C" : (navMouse1.containsMouse ? "#141414" : "transparent")
                        border.color: window.currentNavIndex === 1 ? "#333333" : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10
                            Text {
                                text: window.currentNavIndex === 1 ? "■" : "·"
                                font.pixelSize: window.currentNavIndex === 1 ? 8 : 12
                                color: window.currentNavIndex === 1 ? "#FFFFFF" : "#444444"
                            }
                            Text {
                                text: "Servers"
                                font.pixelSize: 12
                                font.family: Theme.fontBody
                                color: window.currentNavIndex === 1 ? "#FFFFFF" : "#777777"
                            }
                        }

                        MouseArea {
                            id: navMouse1
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentNavIndex = 1
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 0
                        color: window.currentNavIndex === 2 ? "#1C1C1C" : (navMouse2.containsMouse ? "#141414" : "transparent")
                        border.color: window.currentNavIndex === 2 ? "#333333" : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10
                            Text {
                                text: window.currentNavIndex === 2 ? "■" : "·"
                                font.pixelSize: window.currentNavIndex === 2 ? 8 : 12
                                color: window.currentNavIndex === 2 ? "#FFFFFF" : "#444444"
                            }
                            Text {
                                text: "Settings"
                                font.pixelSize: 12
                                font.family: Theme.fontBody
                                color: window.currentNavIndex === 2 ? "#FFFFFF" : "#777777"
                            }
                        }

                        MouseArea {
                            id: navMouse2
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentNavIndex = 2
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 0
                        color: window.currentNavIndex === 3 ? "#1C1C1C" : (navMouse3.containsMouse ? "#141414" : "transparent")
                        border.color: window.currentNavIndex === 3 ? "#333333" : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10
                            Text {
                                text: window.currentNavIndex === 3 ? "■" : "·"
                                font.pixelSize: window.currentNavIndex === 3 ? 8 : 12
                                color: window.currentNavIndex === 3 ? "#FFFFFF" : "#444444"
                            }
                            Text {
                                text: "Activity Logs"
                                font.pixelSize: 12
                                font.family: Theme.fontBody
                                color: window.currentNavIndex === 3 ? "#FFFFFF" : "#777777"
                            }
                        }

                        MouseArea {
                            id: navMouse3
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentNavIndex = 3
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        StackLayout {
            id: mainStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: window.currentNavIndex

            DashboardView {
                onRequestSwitchToServers: window.currentNavIndex = 1
            }

            ServersView {
                onRequestAddServer: addServerDialog.openDialog()
                onRequestImportUrl: importUrlDialog.openDialog()
            }

            SettingsView {}

            LogsView {}
        }
    }

    AddServerDialog {
        id: addServerDialog
        anchors.fill: parent
    }

    ImportUrlDialog {
        id: importUrlDialog
        anchors.fill: parent
    }

    Rectangle {
        id: toast
        property alias message: toastText.text
        width: toastText.implicitWidth + 32
        height: 36
        radius: 0
        color: "#181818"
        border.color: "#FFFFFF"
        border.width: 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        opacity: 0.0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Text {
            id: toastText
            anchors.centerIn: parent
            font.pixelSize: 12
            font.bold: true
            font.family: "Monospace"
            color: "#FFFFFF"
        }

        Timer {
            id: toastTimer
            interval: 2200
            onTriggered: toast.opacity = 0.0
        }
    }

    Connections {
        target: appController
        function onToastRequested(msg) {
            toast.message = msg
            toast.opacity = 1.0
            toastTimer.restart()
        }
    }
}
