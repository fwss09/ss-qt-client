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
        anchors.margins: 24
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "SERVERS"
                font.pixelSize: 26
                font.family: Theme.fontHeading
                color: "#FFFFFF"
            }

            Item { Layout.fillWidth: true }

            ModernButton {
                text: "Ping All"
                onClicked: appController.pingAllServers()
            }

            ModernButton {
                text: "Import ss://"
                onClicked: root.requestImportUrl()
            }

            ModernButton {
                text: "+ Add Server"
                isPrimary: true
                onClicked: root.requestAddServer()
            }
        }

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
                height: 70
                color: (appController.activeServerIndex === index) ? "#1A1A1A" : "#121212"
                glow: (appController.activeServerIndex === index && appController.isConnected)
                glowColor: "#FFFFFF"

                readonly property bool hasCustomName: model.name && model.name !== model.formattedAddress && model.name !== model.host

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 0
                        color: {
                            if (appController.activeServerIndex === index) {
                                return appController.isConnected ? "#FFFFFF" : "#888888"
                            }
                            return "#333333"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        RowLayout {
                            spacing: 8
                            Text {
                                text: serverCard.hasCustomName ? model.name : model.formattedAddress
                                font.pixelSize: 13
                                font.bold: false
                                font.family: serverCard.hasCustomName ? Theme.fontBody : Theme.fontMono
                                color: "#FFFFFF"
                            }
                            Rectangle {
                                visible: appController.activeServerIndex === index
                                width: activeText.implicitWidth + 8
                                height: 16
                                radius: 0
                                color: "#222222"
                                border.color: "#FFFFFF"
                                border.width: 1
                                Text {
                                    id: activeText
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.family: "Monospace"
                                    color: "#FFFFFF"
                                }
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Text {
                                visible: serverCard.hasCustomName
                                text: model.formattedAddress
                                font.pixelSize: 11
                                font.family: "Monospace"
                                color: "#888888"
                            }
                            Rectangle {
                                visible: serverCard.hasCustomName
                                width: 3; height: 3; radius: 0; color: "#444444"
                            }
                            Text {
                                text: model.method
                                font.pixelSize: 10
                                font.family: "Monospace"
                                color: serverCard.hasCustomName ? "#CCCCCC" : "#888888"
                            }
                        }
                    }

                    StatusBadge {
                        ping: model.ping
                    }

                    RowLayout {
                        spacing: 6

                        ModernButton {
                            text: (appController.activeServerIndex === index && appController.isConnected) ? "Connected" : "Connect"
                            isPrimary: (appController.activeServerIndex === index && appController.isConnected)
                            Layout.preferredHeight: 28
                            onClicked: {
                                appController.connectToServer(index)
                            }
                        }

                        ModernButton {
                            text: "Ping"
                            Layout.preferredHeight: 28
                            onClicked: appController.pingServer(index)
                        }

                        ModernButton {
                            text: "Copy"
                            Layout.preferredHeight: 28
                            onClicked: {
                                var url = appController.getServerSsUrl(index)
                                appController.copyToClipboard(url)
                            }
                        }
                    }

                    ModernButton {
                        text: "✕"
                        isDanger: true
                        Layout.preferredHeight: 28
                        implicitWidth: 28
                        onClicked: appController.removeServer(index)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: serverList.count === 0
                text: "No servers configured.\nClick '+ Add Server' or 'Import ss://' to add one."
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.family: "Monospace"
                color: "#555555"
            }
        }
    }
}
