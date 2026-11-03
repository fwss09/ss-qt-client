import QtQuick

Rectangle {
    id: badge

    property int ping: -1

    implicitWidth: contentRow.implicitWidth + 14
    implicitHeight: 22
    radius: 0

    color: ping < 0 ? "#111111" : "#181818"
    border.color: ping < 0 ? "#262626" : (ping < 150 ? "#666666" : "#444444")
    border.width: 1

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            width: 6
            height: 6
            radius: 0
            anchors.verticalCenter: parent.verticalCenter
            color: ping < 0 ? "#444444" : (ping < 150 ? "#FFFFFF" : "#888888")
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 11
            font.bold: true
            font.family: "Monospace"
            color: ping < 0 ? "#666666" : (ping < 150 ? "#FFFFFF" : "#AAAAAA")
            text: ping < 0 ? "N/A" : (ping + " ms")
        }
    }
}
