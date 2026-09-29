import QtQuick

// Renders a panel as a rounded SDF growing out of the full-width bar plane.
// Horizontal padding gives the smooth-union shoulders room to remain visible.
ShaderEffect {
    id: root

    property real revealProgress: 0
    property real viewWidth: width
    property real viewHeight: height
    property real bodyWidth: Math.max(1, width - Theme.sdfPadding * 2)
    // Independent of surface height: the surface also reserves overshoot space.
    property real bodyHeight: Math.max(1, height - gap)
    property real barOverlap: Theme.sdfBarOverlap
    property real cornerRadius: Theme.radius
    property real smoothing: Theme.sdfSmoothing
    property real gap: Theme.popupGap
    readonly property real progress: Math.max(0, Math.min(Theme.motionMaxProgress, revealProgress))
    // Share these exact bounds with content clipping and pointer hit regions.
    readonly property real bodyTop: (barOverlap - smoothing - 2)
        + (gap - (barOverlap - smoothing - 2)) * Math.min(1, progress)
    readonly property real animatedBodyWidth: bodyWidth * (0.60 + 0.40 * progress)
    readonly property real animatedBodyHeight: Math.max(1, bodyHeight * progress)
    readonly property real bodyBottom: bodyTop + animatedBodyHeight
    property color fillColor: Theme.moduleBg
    property color outlineColor: Theme.shellOutline
    property real outlineWidth: Theme.shellOutlineWidth

    blending: true
    fragmentShader: Qt.resolvedUrl("SdfPopup.frag.qsb")
}
