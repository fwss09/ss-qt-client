import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(parent.width - 48, 800)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Item { height: 10 }

            Text {
                text: "SETTINGS"
                font.pixelSize: 26
                font.family: Theme.fontHeading
                color: "#FFFFFF"
            }

            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 250

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Tactical Globe Display Style"
                            font.pixelSize: 18
                            font.family: Theme.fontHeading
                            color: "#FFFFFF"
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 6; height: 6; radius: 0
                            color: appController.globeGreenColor ? "#CCFF00" : "#FFFFFF"
                        }
                        Text {
                            text: "LIVE CONFIG"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: "#777777"
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 24

                        Rectangle {
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 160
                            radius: 0
                            color: "#080808"
                            border.color: "#282828"
                            border.width: 1
                            clip: true

                            TacticalGlobe {
                                anchors.centerIn: parent
                                width: 148
                                height: 148
                                active: (typeof window !== "undefined") ? (window.currentNavIndex === 2) : true
                                isConnected: true
                                isGreen: appController.globeGreenColor
                                isFilled: appController.globeFilled
                                showBadges: false
                                showArc: false
                                showTelemetry: false
                                showZoomControls: false
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 4
                                width: previewText.implicitWidth + 8
                                height: 14
                                radius: 0
                                color: "#CC000000"
                                border.color: "#333333"
                                border.width: 1

                                Text {
                                    id: previewText
                                    anchors.centerIn: parent
                                    text: "PREVIEW"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    color: "#888888"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Text {
                                    text: "LAND COLOR PALETTE"
                                    font.pixelSize: 11
                                    font.family: Theme.fontMono
                                    color: "#888888"
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: 0
                                        color: appController.globeGreenColor ? "#CCFF00" : (limeMouse.containsMouse ? "#202020" : "#121212")
                                        border.color: appController.globeGreenColor ? "#CCFF00" : (limeMouse.containsMouse ? "#666666" : "#333333")
                                        border.width: 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            Rectangle {
                                                width: 8; height: 8; radius: 0
                                                color: appController.globeGreenColor ? "#000000" : "#CCFF00"
                                            }
                                            Text {
                                                text: "NEON LIME"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: appController.globeGreenColor ? "#000000" : "#E0E0E0"
                                            }
                                        }

                                        MouseArea {
                                            id: limeMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            preventStealing: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                appController.setGlobeGreenColor(true)
                                                appController.toastRequested("Theme: Neon Lime")
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: 0
                                        color: !appController.globeGreenColor ? "#FFFFFF" : (whiteMouse.containsMouse ? "#202020" : "#121212")
                                        border.color: !appController.globeGreenColor ? "#FFFFFF" : (whiteMouse.containsMouse ? "#666666" : "#333333")
                                        border.width: 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            Rectangle {
                                                width: 8; height: 8; radius: 0
                                                color: !appController.globeGreenColor ? "#000000" : "#FFFFFF"
                                            }
                                            Text {
                                                text: "MONO WHITE"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: !appController.globeGreenColor ? "#000000" : "#E0E0E0"
                                            }
                                        }

                                        MouseArea {
                                            id: whiteMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            preventStealing: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                appController.setGlobeGreenColor(false)
                                                appController.toastRequested("Theme: Mono White")
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Text {
                                    text: "LAND RENDERING GEOMETRY"
                                    font.pixelSize: 11
                                    font.family: Theme.fontMono
                                    color: "#888888"
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: 0
                                        color: appController.globeFilled ? "#FFFFFF" : (solidMouse.containsMouse ? "#202020" : "#121212")
                                        border.color: appController.globeFilled ? "#FFFFFF" : (solidMouse.containsMouse ? "#666666" : "#333333")
                                        border.width: 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            Rectangle {
                                                width: 8; height: 8; radius: 0
                                                color: appController.globeFilled ? "#000000" : (appController.globeGreenColor ? "#CCFF00" : "#FFFFFF")
                                            }
                                            Text {
                                                text: "SOLID FILL"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: appController.globeFilled ? "#000000" : "#E0E0E0"
                                            }
                                        }

                                        MouseArea {
                                            id: solidMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            preventStealing: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                appController.setGlobeFilled(true)
                                                appController.toastRequested("Geometry: Solid Fill")
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: 0
                                        color: !appController.globeFilled ? "#FFFFFF" : (outlineMouse.containsMouse ? "#202020" : "#121212")
                                        border.color: !appController.globeFilled ? "#FFFFFF" : (outlineMouse.containsMouse ? "#666666" : "#333333")
                                        border.width: 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            Rectangle {
                                                width: 8; height: 8; radius: 0
                                                color: "transparent"
                                                border.color: !appController.globeFilled ? "#000000" : (appController.globeGreenColor ? "#CCFF00" : "#FFFFFF")
                                                border.width: 1
                                            }
                                            Text {
                                                text: "OUTLINE ONLY"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: !appController.globeFilled ? "#000000" : "#E0E0E0"
                                            }
                                        }

                                        MouseArea {
                                            id: outlineMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            preventStealing: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                appController.setGlobeFilled(false)
                                                appController.toastRequested("Geometry: Outline Only")
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "ACTIVE STYLE:"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: "#666666"
                                }
                                Text {
                                    text: (appController.globeGreenColor ? "NEON LIME" : "MONOCHROME WHITE") + " • " + (appController.globeFilled ? "SOLID CONTINENTS" : "VECTOR OUTLINES")
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: appController.globeGreenColor ? "#CCFF00" : "#FFFFFF"
                                }
                            }
                        }
                    }
                }
            }

            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 130

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Text {
                        text: "Local Proxy Settings"
                        font.pixelSize: 18
                        font.family: Theme.fontHeading
                        color: "#FFFFFF"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        ColumnLayout {
                            spacing: 4
                            Text {
                                text: "Local Port"; font.pixelSize: 12; font.family: Theme.fontBody; color: "#888888"
                            }
                            TextField {
                                id: portInput
                                text: appController.localSocksPort.toString()
                                Layout.preferredWidth: 120
                                color: "#FFFFFF"
                                font.family: Theme.fontMono
                                background: Rectangle {
                                    radius: 0
                                    color: "#0A0A0A"
                                    border.color: portInput.activeFocus ? "#FFFFFF" : "#333333"
                                    border.width: 1
                                }
                                onEditingFinished: {
                                    var val = parseInt(text)
                                    if (!isNaN(val) && val > 0 && val < 65536) {
                                        appController.setLocalSocksPort(val)
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 4
                            Text {
                                text: "Listen Address"; font.pixelSize: 12; font.family: "Monospace"; color: "#888888"
                            }
                            Text {
                                text: "127.0.0.1 (Local loopback only)"
                                font.pixelSize: 13
                                font.family: "Monospace"
                                color: "#CCCCCC"
                            }
                        }
                    }
                }
            }

            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 150

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Terminal & Shell Proxy Command"
                            font.pixelSize: 18
                            font.family: Theme.fontHeading
                            color: "#FFFFFF"
                        }
                        Item { Layout.fillWidth: true }
                        ModernButton {
                            text: "Copy Command"
                            Layout.preferredHeight: 28
                            onClicked: appController.copyToClipboard(appController.shellExportCommand)
                        }
                    }

                    Text {
                        text: "Command to manually route specific CLI sessions via SOCKS5:"
                        font.pixelSize: 12
                        color: "#888888"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 0
                        color: "#080808"
                        border.color: "#242424"
                        border.width: 1

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            font.family: "Monospace"
                            font.pixelSize: 11
                            color: "#E0E0E0"
                            text: appController.shellExportCommand
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Item { height: 20 }
        }
    }
}
