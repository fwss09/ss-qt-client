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

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: "#CC000000"
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeDialog()
        }
    }

    // Modal Card
    ModernCard {
        width: Math.min(parent.width - 40, 480)
        height: 470
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
                text: "ADD SERVER"
                font.pixelSize: 22
                font.family: Theme.fontHeading
                color: "#FFFFFF"
            }

            // Server Name
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "Server Name / Tag"; font.pixelSize: 12; font.family: Theme.fontBody; color: "#888888" }
                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    placeholderText: "e.g. Node-1"
                    color: "#FFFFFF"
                    font.family: Theme.fontMono
                    background: Rectangle { radius: 0; color: "#0A0A0A"; border.color: nameField.activeFocus ? "#FFFFFF" : "#282828" }
                }
            }

            // Host & Port Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Server Address"; font.pixelSize: 12; font.family: Theme.fontBody; color: "#888888" }
                    TextField {
                        id: hostField
                        Layout.fillWidth: true
                        placeholderText: "IP or domain"
                        color: "#FFFFFF"
                        font.family: Theme.fontMono
                        background: Rectangle { radius: 0; color: "#0A0A0A"; border.color: hostField.activeFocus ? "#FFFFFF" : "#282828" }
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 100
                    spacing: 4
                    Text { text: "Port"; font.pixelSize: 12; font.family: Theme.fontBody; color: "#888888" }
                    TextField {
                        id: portField
                        Layout.fillWidth: true
                        text: "8388"
                        color: "#FFFFFF"
                        font.family: Theme.fontMono
                        background: Rectangle { radius: 0; color: "#0A0A0A"; border.color: portField.activeFocus ? "#FFFFFF" : "#282828" }
                    }
                }
            }

            // Password
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "Password / Key"; font.pixelSize: 12; font.family: Theme.fontBody; color: "#888888" }
                TextField {
                    id: passField
                    Layout.fillWidth: true
                    placeholderText: "Encryption secret"
                    echoMode: showPassCheck.checked ? TextInput.Normal : TextInput.Password
                    color: "#FFFFFF"
                    font.family: Theme.fontMono
                    background: Rectangle { radius: 0; color: "#0A0A0A"; border.color: passField.activeFocus ? "#FFFFFF" : "#282828" }
                }
                CheckBox {
                    id: showPassCheck
                    text: "Show password"
                }
            }

            // Encryption Method
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: "Encryption Cipher"; font.pixelSize: 12; font.family: Theme.fontBody; color: "#888888" }
                ComboBox {
                    id: cipherCombo
                    Layout.fillWidth: true
                    model: ["chacha20-poly1305", "aes-256-gcm", "aes-128-gcm"]
                }
            }

            Item { Layout.fillHeight: true }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                ModernButton {
                    text: "Cancel"
                    onClicked: root.closeDialog()
                }

                ModernButton {
                    text: "Save Server"
                    isPrimary: true
                    onClicked: {
                        var p = parseInt(portField.text)
                        if (hostField.text.trim() === "" || isNaN(p) || passField.text.trim() === "") {
                            return
                        }
                        appController.addServer(nameField.text, hostField.text, p, passField.text, cipherCombo.currentText)
                        root.closeDialog()
                    }
                }
            }
        }
    }

    function openDialog() {
        nameField.text = ""
        hostField.text = ""
        portField.text = "8388"
        passField.text = ""
        cipherCombo.currentIndex = 0
        isShown = true
    }

    function closeDialog() {
        isShown = false
        closed()
    }
}
