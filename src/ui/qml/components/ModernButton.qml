import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: root

    property alias text: label.text
    property color buttonColor: "#171717"
    property color hoverColor: "#262626"
    property color textColor: "#FFFFFF"
    property color borderColor: "#333333"
    property int radius: 0
    property bool isPrimary: false
    property bool isDanger: false
    property bool isBold: false

    signal clicked()

    implicitWidth: Math.max(48, label.implicitWidth + 24)
    implicitHeight: 30

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 0
        color: {
            if (root.isPrimary) {
                return mouseArea.containsMouse ? "#E5E5E5" : "#FFFFFF"
            } else if (root.isDanger) {
                return mouseArea.containsMouse ? "#333333" : "#222222"
            } else {
                return mouseArea.containsMouse ? root.hoverColor : root.buttonColor
            }
        }
        border.color: root.isPrimary ? "#FFFFFF" : (mouseArea.containsMouse ? "#666666" : root.borderColor)
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        Text {
            id: label
            anchors.centerIn: parent
            color: root.isPrimary ? "#000000" : root.textColor
            font.pixelSize: 13
            font.bold: root.isBold
            font.family: Theme.fontBody
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
