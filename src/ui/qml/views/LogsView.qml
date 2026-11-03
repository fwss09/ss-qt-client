import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "ACTIVITY LOGS"
                font.pixelSize: 26
                font.family: Theme.fontHeading
                color: "#FFFFFF"
            }

            Item { Layout.fillWidth: true }

            ModernButton {
                text: "Copy All"
                onClicked: {
                    var all = appController.logs.join("\n")
                    appController.copyToClipboard(all)
                }
            }

            ModernButton {
                text: "Clear"
                isDanger: true
                onClicked: appController.clearLogs()
            }
        }

        ModernCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#080808"
            border.color: "#222222"

            ScrollView {
                id: scrollView
                anchors.fill: parent
                anchors.margins: 12
                clip: true

                ListView {
                    id: logList
                    width: scrollView.width
                    model: appController.logs
                    spacing: 4

                    onCountChanged: {
                        Qt.callLater(function() {
                            logList.positionViewAtEnd()
                        })
                    }

                    delegate: Text {
                        width: logList.width
                        font.family: "Monospace"
                        font.pixelSize: 12
                        wrapMode: Text.WrapAnywhere
                        text: modelData
                        color: {
                            if (modelData.indexOf("[ERROR]") !== -1) return "#FFFFFF";
                            if (modelData.indexOf("[VPN]") !== -1) return "#FFFFFF";
                            if (modelData.indexOf("[SOCKS5]") !== -1) return "#E0E0E0";
                            if (modelData.indexOf("[CORE]") !== -1) return "#CCCCCC";
                            return "#888888";
                        }
                    }
                }
            }
        }
    }
}
