import QtQuick

pragma Singleton

QtObject {

    readonly property color bgDark: "#080808"
    readonly property color bgSidebar: "#0F0F0F"
    readonly property color bgCard: "#141414"
    readonly property color bgCardHover: "#1F1F1F"
    readonly property color bgInput: "#0D0D0D"

    readonly property color accentWhite: "#FFFFFF"
    readonly property color accentLight: "#E0E0E0"
    readonly property color accentGray: "#888888"
    readonly property color accentDark: "#262626"
    readonly property color accentLime: "#CCFF00"

    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#A0A0A0"
    readonly property color textMuted: "#606060"

    readonly property color borderSubtle: "#242424"
    readonly property color borderActive: "#FFFFFF"

    readonly property int radiusSmall: 0
    readonly property int radiusMedium: 0
    readonly property int radiusLarge: 0
    readonly property int radiusPill: 0

    readonly property string fontHeading: "Instrument Serif"
    readonly property string fontBody: "Instrument Sans"
    readonly property string fontMono: "Monospace"
}
