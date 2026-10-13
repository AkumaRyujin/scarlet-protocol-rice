import QtQuick
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "sergio.menu"

  implicitWidth: 32
  implicitHeight: barSize

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: " "
    hasVisualContent: true
    labelVisible: false
    fixedWidth: 32
    fixedHeight: root.barSize
    tooltipText: "Omarchy Menu"
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-menu toggle root")
    }

    Image {
      anchors.centerIn: parent
      width: 18
      height: 18
      source: Qt.resolvedUrl("assets/skull_cyan.png")
      fillMode: Image.PreserveAspectFit
      smooth: true
      mipmap: true
    }
  }
}
