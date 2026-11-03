import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 16
        anchors.bottomMargin: 84
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "LOGS"
                font.pixelSize: 22
                font.family: Theme.fontHeading
                color: "#FFFFFF"
            }

            Item { Layout.fillWidth: true }

            ModernButton {
                text: "Clear"
                onClicked: appController.clearLogs()
            }
        }

        ModernCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                anchors.fill: parent
                anchors.margins: 12
                clip: true
                model: appController.logs

                delegate: Text {
                    width: parent.width
                    text: modelData
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    wrapMode: Text.WrapAnywhere
                    color: {
                        if (modelData.indexOf("[ERROR]") !== -1) return "#FF3B30"
                        if (modelData.indexOf("[VPN]") !== -1) return "#CCFF00"
                        if (modelData.indexOf("[APP]") !== -1) return "#00F0FF"
                        return "#888888"
                    }
                    padding: 2
                }
            }
        }
    }
}
