import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

Item {
    id: root
    required property QtObject controller
    property string wallpaperPath: ""
    property string fallbackPath: ""
    property string snapshotPath: ""
    property date now: new Date()
    readonly property real progress: controller.reveal
    readonly property real overviewScale: 0.70
    readonly property real tileTravel: width * overviewScale + 32
    readonly property real zoomOut: smoothStage(progress)
    readonly property real scrollAcross: smoothStage(progress - 1)
    readonly property real zoomIn: smoothStage(progress - 2)
    readonly property real fit: Math.max(0.1, Math.min(1, (height - 48) / card.implicitHeight))

    function smoothStage(value) {
        const t = Math.max(0, Math.min(1, value));
        return t * t * (3 - 2 * t);
    }

    function fileUrl(path) {
        return path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : "";
    }
    // Security invariant: this opaque base covers any gap between moving layers.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(LockColors.surfaceBackground.r, LockColors.surfaceBackground.g,
                       LockColors.surfaceBackground.b, 1)
    }
    Image {
        id: frozenDesktop
        objectName: "frozenDesktop"
        width: root.width
        height: root.height
        x: -root.tileTravel * root.scrollAcross
        y: 0
        scale: 1 - (1 - root.overviewScale) * root.zoomOut
        transformOrigin: Item.Center
        source: root.fileUrl(root.snapshotPath)
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
        // Reuse the pre-lock frame on exit; a live desktop cannot be exposed
        // until the compositor releases the session lock.
        visible: status === Image.Ready && root.controller.requested
            && root.progress < 2
        opacity: 1 - root.smoothStage((root.scrollAcross - 0.85) / 0.15)
    }
    // The lock scene is a real ext-session-lock surface child, never the desktop.
    Item {
        id: lockScene
        objectName: "lockScene"
        width: root.width
        height: root.height
        x: root.tileTravel * (1 - root.scrollAcross)
        y: 0
        scale: root.overviewScale + (1 - root.overviewScale) * root.zoomIn
        transformOrigin: Item.Center
        opacity: root.smoothStage(root.scrollAcross * 8)

    Wallpaper {
        objectName: "lockWallpaper"
        anchors.fill: parent
        path: root.wallpaperPath
        fallbackPath: root.fallbackPath
    }
    Rectangle {
        anchors.fill: parent
        color: LockColors.overlay
        opacity: 0.45 * Math.max(0, Math.min(1, root.progress))
    }
    MouseArea {
        anchors.fill: parent
        onClicked: input.forceActiveFocus()
    }
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }
    Connections {
        target: root.controller
        function onClearInput() { input.clear(); }
        function onFocusInput() { input.forceActiveFocus(); }
    }
    Rectangle {
        id: card
        width: Math.max(1, Math.min(420, (root.width - 48) / Theme.motionMaxProgress))
        implicitHeight: contents.implicitHeight + 48
        height: implicitHeight
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        // Fit the card within shorter displays, including overshoot frames.
        scale: root.fit
        transformOrigin: Item.Center
        radius: Theme.radius * 2
        color: LockColors.cardBackground
        border.color: root.controller.statusError ? LockColors.error : LockColors.cardBorder
        border.width: Theme.shellOutlineWidth
        enabled: root.controller.secure && !root.controller.authenticated

        ColumnLayout {
            id: contents
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
            spacing: 16

            Text {
                Layout.fillWidth: true
                text: Qt.formatDateTime(root.now, "HH:mm")
                color: LockColors.clock
                font { family: Theme.fontFamily; pixelSize: 48 }
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.fillWidth: true
                text: Qt.formatDateTime(root.now, "dddd, MMMM d")
                color: LockColors.secondaryText
                font { family: Theme.fontFamily; pixelSize: Theme.fontSize }
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.fillWidth: true
                text: "Session locked"
                color: LockColors.title
                font { family: Theme.fontFamily; pixelSize: 22; bold: true }
                horizontalAlignment: Text.AlignHCenter
            }
            T.TextField {
                id: input
                objectName: "lockResponse"
                Layout.fillWidth: true
                implicitHeight: 48
                padding: 12
                focus: true
                readOnly: !root.controller.canRespond
                echoMode: root.controller.responseVisible ? TextInput.Normal : TextInput.Password
                passwordMaskDelay: 0
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    | (root.controller.responseVisible ? 0 : Qt.ImhHiddenText)
                selectByMouse: false
                placeholderText: root.controller.responseVisible ? "Response" : "Password"
                placeholderTextColor: LockColors.inputPlaceholder
                color: LockColors.inputText
                selectionColor: LockColors.inputSelection
                selectedTextColor: LockColors.inputSelectedText
                font { family: Theme.fontFamily; pixelSize: 18 }
                verticalAlignment: TextInput.AlignVCenter
                Accessible.name: root.controller.responseVisible ? "Authentication response" : "Password"
                background: Rectangle {
                    radius: Theme.radius
                    color: input.activeFocus ? LockColors.inputFocusedBackground : LockColors.inputUnfocusedBackground
                    border.width: 1
                    border.color: input.activeFocus ? LockColors.inputFocusBorder : LockColors.cardBorder
                }
                Text {
                    x: input.leftPadding
                    y: input.topPadding
                    width: input.availableWidth
                    height: input.availableHeight
                    text: input.placeholderText
                    color: input.placeholderTextColor
                    font: input.font
                    verticalAlignment: Text.AlignVCenter
                    visible: input.text.length === 0 && input.preeditText.length === 0
                }
                onAccepted: root.controller.respond(text)
                Keys.onEscapePressed: clear()
                Component.onCompleted: forceActiveFocus()
            }
            Text {
                Layout.fillWidth: true
                Layout.minimumHeight: 36
                text: root.controller.status
                textFormat: Text.PlainText
                color: root.controller.statusError ? LockColors.error : LockColors.secondaryText
                font { family: Theme.fontFamily; pixelSize: Theme.fontSize }
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
            T.Button {
                id: submit
                objectName: "lockSubmit"
                Layout.fillWidth: true
                implicitHeight: 42
                enabled: root.controller.canRespond || root.controller.canRetry
                text: root.controller.canRetry ? "Retry authentication" : "Unlock"
                Accessible.name: text
                background: Rectangle {
                    radius: Theme.radius
                    color: submit.down ? LockColors.buttonPressedBackground : LockColors.buttonBackground
                    border.width: 1
                    border.color: submit.activeFocus ? LockColors.buttonFocusBorder : LockColors.cardBorder
                    opacity: submit.enabled ? 1 : 0.5
                }
                contentItem: Text {
                    text: submit.text
                    color: LockColors.buttonText
                    font { family: Theme.fontFamily; pixelSize: Theme.fontSize }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (root.controller.canRetry) root.controller.beginAuthentication();
                    else root.controller.respond(input.text);
                    input.forceActiveFocus();
                }
            }
        }
    }
    } // lockScene
}
