pragma Singleton
import QtQuick

// Tokyo Night-derived palette. Lift the shell surface above the wallpaper
// while keeping the bar and its SDF popovers on one exact base color.
QtObject {
    readonly property color barWindowBackground: Colors.barWindowBackground
    readonly property color barBackground: Colors.barBackground
    readonly property color barOutline: Colors.barOutline
    readonly property color workspaceContainerBackground: Colors.workspaceContainerBackground
    readonly property color workspaceFocused: Colors.workspaceFocused
    readonly property color workspaceActive: Colors.workspaceActive
    readonly property color workspaceInactive: Colors.workspaceInactive
    readonly property color workspaceUrgent: Colors.workspaceUrgent
    readonly property color workspaceSeparator: Colors.workspaceSeparator
    readonly property color statusContainerBackground: Colors.statusContainerBackground
    readonly property color cpuAccent: Colors.cpuAccent
    readonly property color memoryAccent: Colors.memoryAccent
    readonly property color clockAccent: Colors.clockAccent
    readonly property color wifiAccent: Colors.wifiAccent
    readonly property color bluetoothAccent: Colors.bluetoothAccent
    readonly property color audioAccent: Colors.audioAccent
    readonly property color batteryCritical: Colors.batteryCritical
    readonly property color batteryLow: Colors.batteryLow
    readonly property color batteryNormal: Colors.batteryNormal
    readonly property color powerAccent: Colors.powerAccent
    readonly property color pillDefaultAccent: Colors.pillDefaultAccent
    readonly property color pillBackground: Colors.pillBackground
    readonly property color audioTitle: Colors.audioTitle
    readonly property color audioValue: Colors.audioValue
    readonly property color audioError: Colors.audioError
    readonly property color audioUnmuteAction: Colors.audioUnmuteAction
    readonly property color audioMuteAction: Colors.audioMuteAction
    readonly property color bluetoothTitle: Colors.bluetoothTitle
    readonly property color bluetoothAdapterStatus: Colors.bluetoothAdapterStatus
    readonly property color bluetoothScanningLabel: Colors.bluetoothScanningLabel
    readonly property color bluetoothConnectedRowBackground: Colors.bluetoothConnectedRowBackground
    readonly property color bluetoothDisconnectedRowBackground: Colors.bluetoothDisconnectedRowBackground
    readonly property color bluetoothDeviceName: Colors.bluetoothDeviceName
    readonly property color bluetoothDeviceDetails: Colors.bluetoothDeviceDetails
    readonly property color bluetoothPairingAction: Colors.bluetoothPairingAction
    readonly property color bluetoothDisconnectAction: Colors.bluetoothDisconnectAction
    readonly property color bluetoothConnectAction: Colors.bluetoothConnectAction
    readonly property color tooltipWindowBackground: Colors.tooltipWindowBackground
    readonly property color tooltipBackground: Colors.tooltipBackground
    readonly property color tooltipOutline: Colors.tooltipOutline
    readonly property color tooltipText: Colors.tooltipText
    readonly property color sliderTrack: Colors.sliderTrack
    readonly property color sliderFill: Colors.sliderFill
    readonly property color sliderThumb: Colors.sliderThumb
    readonly property color sliderFocusBorder: Colors.sliderFocusBorder
    readonly property color switchCheckedBackground: Colors.switchCheckedBackground
    readonly property color switchUncheckedBackground: Colors.switchUncheckedBackground
    readonly property color switchFocusBorder: Colors.switchFocusBorder
    readonly property color switchCheckedBorder: Colors.switchCheckedBorder
    readonly property color switchUncheckedBorder: Colors.switchUncheckedBorder
    readonly property color switchThumb: Colors.switchThumb
    readonly property color networkTitle: Colors.networkTitle
    readonly property color networkError: Colors.networkError
    readonly property color networkWarning: Colors.networkWarning
    readonly property color networkConnectedRowBackground: Colors.networkConnectedRowBackground
    readonly property color networkDisconnectedRowBackground: Colors.networkDisconnectedRowBackground
    readonly property color networkIcon: Colors.networkIcon
    readonly property color networkName: Colors.networkName
    readonly property color networkDetails: Colors.networkDetails
    readonly property color networkAccessPointDetails: Colors.networkAccessPointDetails
    readonly property color passwordText: Colors.passwordText
    readonly property color passwordPlaceholder: Colors.passwordPlaceholder
    readonly property color passwordSelectionBackground: Colors.passwordSelectionBackground
    readonly property color passwordSelectedText: Colors.passwordSelectedText
    readonly property color passwordFocusedBackground: Colors.passwordFocusedBackground
    readonly property color passwordUnfocusedBackground: Colors.passwordUnfocusedBackground
    readonly property color popoverWindowBackground: Colors.popoverWindowBackground
    readonly property color popoverBackground: Colors.popoverBackground
    readonly property color popoverOutline: Colors.popoverOutline
    readonly property color powerTitle: Colors.powerTitle
    readonly property color powerSelectedBackground: Colors.powerSelectedBackground
    readonly property color powerHoverBackground: Colors.powerHoverBackground
    readonly property color powerIdleBackground: Colors.powerIdleBackground
    readonly property color powerIcon: Colors.powerIcon
    readonly property color powerLabel: Colors.powerLabel
    readonly property color textButtonDefaultText: Colors.textButtonDefaultText
    readonly property color textButtonPressedBackground: Colors.textButtonPressedBackground
    readonly property color textButtonHoverBackground: Colors.textButtonHoverBackground
    readonly property color textButtonIdleBackground: Colors.textButtonIdleBackground
    readonly property color textButtonFocusBorder: Colors.textButtonFocusBorder

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
    // Bottom AA and smooth-union reach for even a short, empty tooltip.
    readonly property int sdfEdgePadding: 4
    readonly property int popupLeaveDelay: 500
    // Same 200 ms attack / single rebound as the niri window-open curve.
    // Set false for a non-overshooting fallback; interactions stay unchanged.
    readonly property bool motionOvershoot: true
    readonly property int motionDuration: 200
    readonly property int motionCloseDuration: 160
    // Qt BezierSpline needs two control points AND the endpoint (1, 1).
    readonly property list<real> motionCurve: [0.23, 1.23, 0.61, 1.08, 1, 1]
    readonly property list<real> motionCloseCurve: [1 / 3, 1, 2 / 3, 1, 1, 1]
    // The opening curve peaks at 1.05191. Reserve space, including AA, for it.
    readonly property real motionMaxProgress: motionOvershoot ? 1.06 : 1.0
    readonly property int popupSettleDuration: motionDuration + motionCloseDuration + 100


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
