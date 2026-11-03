import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    property bool isShown: false
    signal closed()

    visible: opacity > 0
    opacity: isShown ? 1.0 : 0.0

    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }

    Rectangle {
        anchors.fill: parent
        color: "#CC000000"
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeDialog()
        }
    }

    ModernCard {
        width: Math.min(parent.width - 40, 520)
        height: 280
        anchors.centerIn: parent
        color: "#121212"
        border.color: "#333333"

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Text {
                text: "IMPORT URL"
                font.pixelSize: 22
                font.family: Theme.fontHeading
                color: "#FFFFFF"
            }

            Text {
                text: "Paste a standard Shadowsocks URI (ss://...):"
                font.pixelSize: 13
                font.family: Theme.fontBody
                color: "#888888"
            }

            TextField {
                id: urlField
                Layout.fillWidth: true
                placeholderText: "ss://..."
                color: "#FFFFFF"
                font.family: Theme.fontMono
                background: Rectangle {
                    radius: 0
                    color: "#0A0A0A"
                    border.color: urlField.activeFocus ? "#FFFFFF" : "#282828"
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                ModernButton {
                    text: "Cancel"
                    onClicked: root.closeDialog()
                }

                ModernButton {
                    text: "Import"
                    isPrimary: true
                    onClicked: {
                        if (urlField.text.trim() !== "") {
                            if (appController.importFromUrl(urlField.text.trim())) {
                                root.closeDialog()
                            }
                        }
                    }
                }
            }
        }
    }

    function openDialog() {
        urlField.text = ""
        isShown = true
    }

    function closeDialog() {
        isShown = false
        closed()
    }
}
