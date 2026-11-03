import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    signal requestSwitchToServers()

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.height + 96
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: contentCol
            width: parent.width - 28
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Item { height: 4 }

            // 1. Header (PC Style)
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "DASHBOARD"
                    font.pixelSize: 24
                    font.family: Theme.fontHeading
                    color: "#FFFFFF"
                }
            }

            // 2. Hero Card: Tactical Globe + Brutalist Button (PC Style)
            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 330
                glow: appController.isConnected
                glowColor: "#FFFFFF"

                Item {
                    anchors.fill: parent
                    anchors.margins: 14

                    // Globe Viewport centered perfectly
                    TacticalGlobe {
                        id: globe
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(parent.width - 20, 240)
                        height: 200
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

                    // Command & Connection Control (PC Style)
                    Column {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        // Square Brutalist Button
                        Rectangle {
                            id: buttonBox
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 140
                            height: 44
                            radius: 0
                            color: {
                                if (appController.isConnected) {
                                    return connectMouse.containsMouse ? "#E0E0E0" : "#FFFFFF"
                                } else {
                                    return connectMouse.containsMouse ? "#1E1E1E" : "#121212"
                                }
                            }
                            border.color: appController.isConnected ? "#FFFFFF" : (connectMouse.containsMouse ? "#FFFFFF" : "#303030")
                            border.width: 1.5

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.pixelSize: 14
                                    text: appController.isConnecting ? "◌" : (appController.isConnected ? "■" : "▲")
                                    color: appController.isConnected ? "#000000" : "#FFFFFF"
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
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
                                cursorShape: Qt.PointingHandCursor
                                enabled: !appController.isConnecting
                                onClicked: appController.toggleConnect()
                            }
                        }

                        // State Label (PC Heading)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: appController.isConnecting ? "Authorizing Tunnel..." : (appController.isConnected ? "Tunnel Connected" : "Tunnel Offline")
                            font.pixelSize: 16
                            font.family: Theme.fontHeading
                            color: appController.isConnected ? "#FFFFFF" : "#666666"
                        }
                    }
                }
            }

            // 3. Server Card (PC Style)
            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 74

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
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
                                text: (appController.serverCity !== "" ? (appController.serverCity + ", ") : "") + appController.serverCountry
                                font.pixelSize: 10
                                font.family: Theme.fontMono
                                color: "#888888"
                            }
                        }

                        Text {
                            text: appController.activeServerName + " (" + appController.activeServerAddress + ")"
                            font.pixelSize: 13
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
                        Layout.preferredHeight: 28
                        onClicked: root.requestSwitchToServers()
                    }
                }
            }

            // 4. Traffic Card (PC Style)
            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 190

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // Clean Traffic Header
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "TRAFFIC"
                            font.pixelSize: 16
                            font.family: Theme.fontHeading
                            color: "#FFFFFF"
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "↓ " + appController.trafficMeter.downloadSpeedFormatted
                            font.pixelSize: 12
                            font.family: Theme.fontMono
                            color: "#FFFFFF"
                        }

                        Item { width: 12 }

                        Text {
                            text: "↑ " + appController.trafficMeter.uploadSpeedFormatted
                            font.pixelSize: 12
                            font.family: Theme.fontMono
                            color: "#888888"
                        }
                    }

                    // Canvas Speed Chart
                    SpeedGraph {
                        id: graph
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        historyData: appController.trafficMeter.speedHistory
                    }
                }
            }

            Item { height: 86 }
        }
    }
}
