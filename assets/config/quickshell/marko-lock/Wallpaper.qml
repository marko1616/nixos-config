import QtQuick
import QtMultimedia

Item {
    id: root
    property string path: ""
    property string fallbackPath: ""
    readonly property bool video: /\.(mp4|m4v|mkv|webm|mov|avi)$/i.test(path)
    property bool failed: false
    function fileUrl(path) {
        return path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : "";
    }

    // All outputs keep an opaque fallback even while the decoder is warming up.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(LockColors.surfaceBackground.r, LockColors.surfaceBackground.g, LockColors.surfaceBackground.b, 1)
    }
    Image {
        anchors.fill: parent
        source: root.fileUrl(root.fallbackPath)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }
    Image {
        anchors.fill: parent
        visible: !root.video && status === Image.Ready
        source: !root.video ? root.fileUrl(root.path) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }
    VideoOutput {
        id: output
        objectName: "wallpaperOutput"
        anchors.fill: parent
        visible: root.video && !root.failed
        fillMode: VideoOutput.PreserveAspectCrop
    }
    MediaPlayer {
        id: player
        source: root.video ? root.fileUrl(root.path) : ""
        videoOutput: output
        // No AudioOutput: a video wallpaper must never emit sound.
        loops: MediaPlayer.Infinite
        onErrorOccurred: { root.failed = true; stop(); }
        Component.onCompleted: { if (root.video) play(); }
    }
}
