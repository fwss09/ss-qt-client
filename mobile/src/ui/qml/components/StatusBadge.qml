import QtQuick

Rectangle {
    id: badge

    property int ping: -1
    property string status: ""
    property string customText: ""

    readonly property color statusColor: {
        if (status === "EXCELLENT") return "#CCFF00";
        if (status === "GOOD") return "#00FF66";
        if (status === "SLOW") return "#FFAA00";
        if (status === "ERROR") return "#FF3333";
        if (ping > 0 && ping < 150) return "#FFFFFF";
        if (ping >= 150) return "#888888";
        return "#444444";
    }

    implicitWidth: contentRow.implicitWidth + 14
    implicitHeight: 22
    radius: 0

    color: (ping < 0 && status === "") ? "#111111" : "#181818"
    border.color: (ping < 0 && status === "") ? "#262626" : (ping < 150 || status === "EXCELLENT" || status === "GOOD" ? "#666666" : "#444444")
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
            color: badge.statusColor
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 11
            font.bold: true
            font.family: "Monospace"
            color: badge.statusColor === "#444444" ? "#666666" : (badge.statusColor === "#CCFF00" ? "#CCFF00" : "#DDDDDD")
            text: {
                if (badge.customText !== "") return badge.customText;
                if (badge.ping < 0) return "N/A";
                return badge.ping + " ms";
            }
        }
    }
}
