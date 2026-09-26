pragma Singleton
import QtQuick

// Tokyo Night (Storm) palette, matching the Wofi / Mako / SDDM theme.
QtObject {
    readonly property color fg: "#a9b1d6"
    readonly property color moduleBg: "#24283b"
    readonly property color popupBg: "#1a1b26"
    readonly property color border: "#565f89"

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
    readonly property int radius: 10
    readonly property int borderWidth: 2
    readonly property int popupWidth: 400
    readonly property int popupMaxHeight: 560
    readonly property int popupGap: 8
    readonly property int motionDuration: 180

    // Popups are mapped without a Wayland pointer grab, so a click is never
    // intercepted. Dismissal happens by hover instead: once the pointer has left
    // both the bar and the popup for this long, the popup closes.
    readonly property int popupLeaveDelay: 300

    // Fall back to a grabbed popup (Qt::Popup), which the compositor dismisses on
    // the first click outside. That click is then the compositor's to handle, and
    // the popup cannot animate out.
    readonly property bool popupGrabFocus: false

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
