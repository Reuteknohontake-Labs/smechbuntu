import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation
    Slide {
        Rectangle { anchors.fill: parent; color: "#1d2a35" }
        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            color: "white"
            font.pixelSize: 26
            text: "Installing Smech Linux\nVanilla KDE Plasma on Ubuntu"
        }
    }
}
