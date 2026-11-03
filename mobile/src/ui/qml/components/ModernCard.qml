import QtQuick

Rectangle {
    id: card
    radius: 0
    color: "#121212"
    border.color: "#262626"
    border.width: 1

    property bool glow: false
    property color glowColor: "#FFFFFF"

    Rectangle {
        visible: card.glow
        anchors.fill: parent
        anchors.margins: -1
        radius: 0
        color: "transparent"
        border.color: card.glowColor
        border.width: 1
        opacity: 0.6
    }
}
