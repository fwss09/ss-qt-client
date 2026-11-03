import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    signal requestAddServer()
    signal requestImportUrl()

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 16
        anchors.bottomMargin: 84
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "SERVERS"
                font.pixelSize: 22
                font.family: Theme.fontHeading
                color: "#FFFFFF"
            }

            Item { Layout.fillWidth: true }

            ModernButton {
                text: "Ping"
                onClicked: appController.pingAllServers()
            }

            ModernButton {
                text: "Import"
                onClicked: root.requestImportUrl()
            }

            ModernButton {
                text: "+ Add"
                isPrimary: true
                onClicked: root.requestAddServer()
            }
        }

        // List
        ListView {
            id: serverList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            clip: true
            model: appController.serverModel

            delegate: ModernCard {
                id: serverCard
                width: serverList.width
                height: 72
                color: (appController.activeServerIndex === index) ? "#1C1C1C" : "#111111"
                glow: (appController.activeServerIndex === index && appController.isConnected)
                glowColor: "#CCFF00"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        appController.connectToServer(index)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Active Indicator dot
                        Rectangle {
                            width: 6
                            height: 6
                            color: {
                                if (appController.activeServerIndex === index) {
                                    return appController.isConnected ? "#CCFF00" : "#FFFFFF"
                                }
                                return "#333333"
                            }
                        }

                        // Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: model.name ? model.name : model.formattedAddress
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                font.family: Theme.fontBody
                                color: "#FFFFFF"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: model.formattedAddress + " • " + model.method
                                font.pixelSize: 10
                                font.family: Theme.fontMono
                                color: "#666666"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Ping badge
                        StatusBadge {
                            status: {
                                var ping = model.ping;
                                if (ping < 0) return "UNKNOWN";
                                if (ping < 120) return "EXCELLENT";
                                if (ping < 250) return "GOOD";
                                return "SLOW";
                            }
                            customText: model.ping > 0 ? (model.ping + " ms") : "--"
                            MouseArea {
                                anchors.fill: parent
                                onClicked: appController.pingServer(index)
                            }
                        }

                        // Options popup / delete
                        Text {
                            text: "✕"
                            font.pixelSize: 11
                            color: "#555555"
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                onClicked: appController.removeServer(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
