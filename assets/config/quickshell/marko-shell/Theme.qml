pragma Singleton
import QtQuick

// Tokyo Night-derived palette. Lift the shell surface above the wallpaper
// while keeping the bar and its SDF popovers on one exact base color.
QtObject {
    readonly property color fg: "#a9b1d6"
    readonly property color moduleBg: "#30364f"
    readonly property color popupBg: moduleBg
    readonly property color surfaceActive: "#414966"
    readonly property color border: "#565f89"
    readonly property color shellOutline: "#7480a8"

    readonly property color blue: "#7aa2f7"
    readonly property color purple: "#bb9af7"
    readonly property color cyan: "#73daca"
    readonly property color yellow: "#e0af68"
    readonly property color green: "#9ece6a"
    readonly property color orange: "#ff9e64"
    readonly property color red: "#f7768e"


    readonly property string fontFamily: "Terminess Nerd Font"
    readonly property int fontSize: 14
    readonly property int barHeight: 40
    readonly property int barMargin: 4
    readonly property int barRadius: 10
    readonly property int pillInset: 4
    readonly property real shellOutlineWidth: 1
    readonly property int radius: 10
    readonly property int borderWidth: 1
    readonly property int popupWidth: 400
    readonly property int popupMaxHeight: 560
    readonly property int popupGap: 8
    readonly property real sdfSmoothing: 34
    // The shader starts at the anchor pill's bottom and reaches back to the
    // bar's outer edge. Keep this in sync with the pill's vertical inset.
    readonly property real sdfBarOverlap: pillInset
    readonly property int sdfPadding: 44
    readonly property int popupLeaveDelay: 500
    readonly property int popupSettleDuration: 900
    readonly property int motionDuration: 180

    readonly property color controlOff: "#16161e"
    readonly property color controlThumb: "#ffffff"

    readonly property string wifiIcon: ""
    readonly property string bluetoothIcon: ""
    readonly property string audioMutedIcon: ""
    readonly property string audioLowIcon: ""
    readonly property string audioHighIcon: ""
    readonly property string batteryChargingIcon: ""
    readonly property var batteryIcons: ["", "", "", "", ""]
    readonly property string clockIcon: ""
    readonly property string cpuIcon: ""
    readonly property string memoryIcon: ""
    readonly property string workspaceActiveIcon: ""
    readonly property string workspaceDefaultIcon: ""
    readonly property string powerPerfIcon: ""
    readonly property string powerBalancedIcon: ""
    readonly property string powerSaverIcon: ""
}
