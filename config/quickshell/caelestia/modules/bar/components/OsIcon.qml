// User override of caelestia OsIcon.qml — repurposes the launcher button as a
// "connect to remote PC via Moonlight" button. /usr/local/bin/pc-connect handles
// switching the PC into single-monitor mode, streaming, and restoring on exit.
import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: Math.round(Tokens.font.size.large * 1.2)
    implicitHeight: Math.round(Tokens.font.size.large * 1.2)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["/usr/local/bin/pc-connect"])
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: "desktop_windows"
        color: Colours.palette.m3tertiary
        font.pointSize: Tokens.font.size.large
    }
}
