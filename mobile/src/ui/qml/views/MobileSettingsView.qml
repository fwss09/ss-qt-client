import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: settingsCol.height + 96
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: settingsCol
            width: parent.width - 28
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Item { height: 4 }

            // 1. Title (PC Style)
            Text {
                text: "SETTINGS"
                font.pixelSize: 24
                font.family: Theme.fontHeading
                color: "#FFFFFF"
            }

            // 2. Tactical Radar Globe Customization with Live Preview (PC Style)
            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 410

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Card Header
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Tactical Globe Display Style"
                            font.pixelSize: 17
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

                    // Rotating Live Mini Radar Globe (Transparent seamless background)
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 150

                        TacticalGlobe {
                            anchors.centerIn: parent
                            width: 140
                            height: 140
                            active: (typeof window !== "undefined") ? (window.currentNavIndex === 2) : true
                            isConnected: true
                            isGreen: appController.globeGreenColor
                            isFilled: appController.globeFilled
                            showBadges: false
                            showArc: false
                            showTelemetry: false
                            showZoomControls: false
                        }
                    }

                    // Interactive Selectors (PC Style)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // 1. Color Palette Selector
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Text {
                                text: "LAND COLOR PALETTE"
                                font.pixelSize: 10
                                font.family: Theme.fontMono
                                color: "#888888"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Neon Lime Button
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
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            appController.setGlobeGreenColor(true)
                                            appController.toastRequested("Theme: Neon Lime")
                                        }
                                    }
                                }

                                // Mono White Button
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
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            appController.setGlobeGreenColor(false)
                                            appController.toastRequested("Theme: Mono White")
                                        }
                                    }
                                }
                            }
                        }

                        // 2. Geometry Fill Selector
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Text {
                                text: "LAND RENDERING GEOMETRY"
                                font.pixelSize: 10
                                font.family: Theme.fontMono
                                color: "#888888"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Solid Fill Button
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
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            appController.setGlobeFilled(true)
                                            appController.toastRequested("Geometry: Solid Fill")
                                        }
                                    }
                                }

                                // Outline Only Button
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
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            appController.setGlobeFilled(false)
                                            appController.toastRequested("Geometry: Outline Only")
                                        }
                                    }
                                }
                            }
                        }

                        // Status Summary
                        RowLayout {
                            spacing: 6
                            Text {
                                text: "ACTIVE:"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: "#666666"
                            }
                            Text {
                                text: (appController.globeGreenColor ? "NEON LIME" : "MONO WHITE") + " • " + (appController.globeFilled ? "SOLID CONTINENTS" : "VECTOR OUTLINES")
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: appController.globeGreenColor ? "#CCFF00" : "#FFFFFF"
                            }
                        }
                    }
                }
            }

            // 3. Local SOCKS5 Proxy Configuration (PC Style)
            ModernCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 115

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Text {
                        text: "Local Proxy Settings"
                        font.pixelSize: 17
                        font.family: Theme.fontHeading
                        color: "#FFFFFF"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Local SOCKS5 Port"
                                font.family: Theme.fontBody
                                font.pixelSize: 13
                                color: "#FFFFFF"
                            }
                            Text {
                                text: "Local proxy port on loopback interface"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: "#666666"
                            }
                        }

                        Rectangle {
                            width: 76
                            height: 32
                            radius: 0
                            color: "#181818"
                            border.color: portInput.activeFocus ? "#FFFFFF" : "#333333"
                            border.width: 1

                            TextInput {
                                id: portInput
                                anchors.centerIn: parent
                                text: appController.localSocksPort.toString()
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: "#CCFF00"
                                onEditingFinished: appController.setLocalSocksPort(parseInt(text))
                            }
                        }
                    }
                }
            }

            Item { height: 86 }
        }
    }
}
