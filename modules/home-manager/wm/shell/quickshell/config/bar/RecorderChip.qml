import QtQuick
import qs.services
import qs.widgets

// custom/recorder: a blinking outlined timer, shown only while recording.
Pill {
    id: root

    visible: Recorder.recording
    text: Icons.recording + " " + Recorder.elapsed
    tooltip: "Stop recording"
    border.color: Theme.accent
    border.width: 1
    onClicked: Recorder.stop()

    SequentialAnimation on opacity {
        running: root.visible
        loops: Animation.Infinite
        NumberAnimation { to: 0.5; duration: 500 }
        NumberAnimation { to: 1; duration: 500 }
        onStopped: root.opacity = 1
    }
}
