import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property int currentIndex: 0
    signal tabSelected(int index)

    height: 64
    radius: 32
    color: "#E60A0A0A"
    border.color: "#282828"
    border.width: 1

    // Neon ambient glow when connected
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: root.radius + 1
        color: "transparent"
        border.color: (typeof appController !== "undefined" && appController && appController.isConnected) ? "#33CCFF00" : "#11FFFFFF"
        border.width: 1
        z: -1
    }

    // Active tab sliding pill
    Rectangle {
        id: activePill
        width: (root.width - 20) / 4
        height: root.height - 16
        y: 8
        x: 10 + (root.currentIndex * width)
        radius: 24
        color: "#1A1A1A"
        border.color: "#333333"
        border.width: 1

        Behavior on x {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        // Tiny indicator dot
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            width: 14
            height: 2
            radius: 1
            color: "#CCFF00"
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 0

        // 0. Dashboard
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "▲"
                    font.pixelSize: 13
                    color: root.currentIndex === 0 ? "#CCFF00" : "#666666"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Dashboard"
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                    font.weight: root.currentIndex === 0 ? Font.DemiBold : Font.Normal
                    color: root.currentIndex === 0 ? "#FFFFFF" : "#666666"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.tabSelected(0)
            }
        }

        // 1. Servers
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "≡"
                    font.pixelSize: 15
                    color: root.currentIndex === 1 ? "#CCFF00" : "#666666"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Servers"
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                    font.weight: root.currentIndex === 1 ? Font.DemiBold : Font.Normal
                    color: root.currentIndex === 1 ? "#FFFFFF" : "#666666"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.tabSelected(1)
            }
        }

        // 2. Settings
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "⚙"
                    font.pixelSize: 14
                    color: root.currentIndex === 2 ? "#CCFF00" : "#666666"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Settings"
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                    font.weight: root.currentIndex === 2 ? Font.DemiBold : Font.Normal
                    color: root.currentIndex === 2 ? "#FFFFFF" : "#666666"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.tabSelected(2)
            }
        }

        // 3. Logs
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "▤"
                    font.pixelSize: 13
                    color: root.currentIndex === 3 ? "#CCFF00" : "#666666"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Logs"
                    font.family: Theme.fontBody
                    font.pixelSize: 11
                    font.weight: root.currentIndex === 3 ? Font.DemiBold : Font.Normal
                    color: root.currentIndex === 3 ? "#FFFFFF" : "#666666"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.tabSelected(3)
            }
        }
    }
}
