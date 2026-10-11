import QtQuick
import QtQuick.Layouts

// Volume control popover. The slider and the bar pill both accept wheel input.
PopoverBase {
    id: root
    popHeight: AudioService.errorText !== "" ? 174 : 132

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Volume"
                color: Theme.audioTitle
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: AudioService.available ? AudioService.volume + "%" : "No output"
                color: Theme.audioValue
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        ModernSlider {
            Layout.fillWidth: true
            enabled: AudioService.available
            backendValue: AudioService.volume
            Accessible.name: "Volume"
            onValueRequested: function(nextValue) { AudioService.setVolume(nextValue) }
        }

        Text {
            Layout.fillWidth: true
            visible: AudioService.errorText !== ""
            text: AudioService.errorText
            color: Theme.audioError
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            TextButton {
                enabled: AudioService.available
                text: AudioService.muted ? "Unmute" : "Mute"
                textColor: AudioService.muted ? Theme.audioUnmuteAction : Theme.audioMuteAction
                onClicked: AudioService.toggleMute()
            }
            Item { Layout.fillWidth: true }
        }
    }
}
