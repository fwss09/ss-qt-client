import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    signal requestSwitchToServers()

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(parent.width - 48, 860)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18

            Item { height: 4 }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "DASHBOARD"
                    font.pixelSize: 26
                    font.family: Theme.fontHeading
                    color: "#FFFFFF"
                }
            }

            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 310
                glow: appController.isConnected
                glowColor: "#FFFFFF"

                Item {
                    anchors.fill: parent
                    anchors.margins: 20

                    Rectangle {
                        id: cardDivider
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.topMargin: 10
                        anchors.bottomMargin: 10
                        width: 1
                        color: "#222222"
                    }

                    Item {
                        anchors.left: parent.left
                        anchors.right: cardDivider.left
                        anchors.rightMargin: 20
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        Column {
                            anchors.centerIn: parent
                            spacing: 14

                            Rectangle {
                                id: buttonBox
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 96
                                height: 96
                                radius: 0
                                color: {
                                    if (appController.isConnected) {
                                        return connectMouse.containsMouse ? "#E0E0E0" : "#FFFFFF"
                                    } else {
                                        return connectMouse.containsMouse ? "#1E1E1E" : "#121212"
                                    }
                                }
                                border.color: appController.isConnected ? "#FFFFFF" : (connectMouse.containsMouse ? "#FFFFFF" : "#303030")
                                border.width: 2

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        font.pixelSize: 22
                                        text: appController.isConnecting ? "◌" : (appController.isConnected ? "■" : "▲")
                                        color: appController.isConnected ? "#000000" : "#FFFFFF"
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: appController.isConnecting ? "WAIT..." : (appController.isConnected ? "DISCONNECT" : "CONNECT")
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.family: Theme.fontBody
                                        font.letterSpacing: 1.2
                                        color: appController.isConnected ? "#000000" : "#FFFFFF"
                                    }
                                }

                                MouseArea {
                                    id: connectMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !appController.isConnecting
                                    onClicked: appController.toggleConnect()
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: appController.isConnecting ? "Authorizing Tunnel..." : (appController.isConnected ? "Tunnel Connected" : "Tunnel Offline")
                                font.pixelSize: 18
                                font.family: Theme.fontHeading
                                color: appController.isConnected ? "#FFFFFF" : "#666666"
                            }
                        }
                    }

                    Item {
                        anchors.left: cardDivider.right
                        anchors.leftMargin: 20
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        TacticalGlobe {
                            anchors.centerIn: parent
                            width: 220
                            height: 248
                            active: (typeof window !== "undefined") ? (window.currentNavIndex === 0) : true
                            isConnected: appController.isConnected
                            homeLat: appController.userLat
                            homeLon: appController.userLon
                            homeCity: appController.userCity
                            homeCountry: appController.userCountry
                            targetLat: appController.serverLat
                            targetLon: appController.serverLon
                            targetCity: appController.serverCity
                            targetCountry: appController.serverCountry
                            isGreen: appController.globeGreenColor
                            isFilled: appController.globeFilled
                        }
                    }
                }
            }

            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 76

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            spacing: 6
                            Text {
                                text: "SERVER"
                                font.pixelSize: 10
                                font.family: Theme.fontMono
                                color: "#666666"
                            }
                            Text {
                                text: "•"
                                font.pixelSize: 10
                                color: "#444444"
                            }
                            Text {
                                text: appController.serverCity + ", " + appController.serverCountry
                                font.pixelSize: 10
                                font.family: Theme.fontMono
                                color: "#888888"
                            }
                        }

                        Text {
                            text: appController.activeServerAddress
                            font.pixelSize: 14
                            font.family: Theme.fontMono
                            color: "#FFFFFF"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    StatusBadge {
                        ping: appController.activeServerPing
                    }

                    ModernButton {
                        text: "Change"
                        Layout.preferredHeight: 30
                        onClicked: root.requestSwitchToServers()
                    }
                }
            }

            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 220

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "TRAFFIC"
                            font.pixelSize: 18
                            font.family: Theme.fontHeading
                            color: "#FFFFFF"
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "↓ " + appController.trafficMeter.downloadSpeedFormatted
                            font.pixelSize: 13
                            font.family: Theme.fontMono
                            color: "#FFFFFF"
                        }

                        Item { width: 14 }

                        Text {
                            text: "↑ " + appController.trafficMeter.uploadSpeedFormatted
                            font.pixelSize: 13
                            font.family: Theme.fontMono
                            color: "#888888"
                        }
                    }

                    SpeedGraph {
                        id: graph
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        historyData: appController.trafficMeter.speedHistory
                    }
                }
            }

            Item { height: 16 }
        }
    }
}
