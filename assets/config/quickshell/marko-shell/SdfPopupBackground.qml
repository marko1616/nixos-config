import QtQuick

// Renders a panel as a rounded SDF growing out of the full-width bar plane.
// Horizontal padding gives the smooth-union shoulders room to remain visible.
ShaderEffect {
    id: root

    property real revealProgress: 0
    property real viewWidth: width
    property real viewHeight: height
    property real bodyWidth: Math.max(1, width - Theme.sdfPadding * 2)
    property real barOverlap: Theme.sdfBarOverlap
    property real cornerRadius: Theme.radius
    property real smoothing: Theme.sdfSmoothing
    property real gap: Theme.popupGap
    property real progress: revealProgress
    property color fillColor: Theme.moduleBg
    property color outlineColor: Theme.shellOutline
    property real outlineWidth: Theme.shellOutlineWidth

    blending: true
    fragmentShader: Qt.resolvedUrl("SdfPopup.frag.qsb")
}
