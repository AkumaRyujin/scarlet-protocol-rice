import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "sergio.active-window"

  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property string rawClass: toplevel ? String(toplevel.appId || "") : ""
  readonly property string rawTitle: toplevel ? String(toplevel.title || "") : ""

  function cleanAppName(c, t) {
    var title = String(t || "").trim()
    var id = String(c || "").trim()

    // If it's a Steam game or wine app, title is much better
    if (id.indexOf("steam_app_") === 0 || id === "wine" || id === "proton") {
      if (title !== "") {
        if (title.indexOf(" - ") !== -1) {
          var segs = title.split(" - ")
          return segs[segs.length - 1].trim()
        }
        if (title.indexOf(" (C)") !== -1) {
          var segs3 = title.split(" (C)")
          return segs3[0].trim()
        }
        if (title.length > 22) return title.substring(0, 19) + "..."
        return title
      }
    }

    if (id !== "") {
      var map = {
        "google-chrome": "Google Chrome",
        "google-chrome-stable": "Google Chrome",
        "chromium": "Chromium",
        "chromium-browser": "Chromium",
        "firefox": "Firefox",
        "vesktop": "Discord",
        "discord": "Discord",
        "foot": "Foot",
        "alacritty": "Alacritty",
        "kitty": "Kitty",
        "ghostty": "Ghostty",
        "code": "VS Code",
        "code-oss": "VS Code",
        "codium": "VSCodium",
        "antigravity": "Antigravity",
        "audioviewer": "AudioViewer",
        "thunar": "Files",
        "nautilus": "Files",
        "org.gnome.nautilus": "Files",
        "spotify": "Spotify",
        "obsidian": "Obsidian",
        "steam": "Steam",
        "btop": "Btop",
        "neovim": "Neovim",
        "nvim": "Neovim",
        "aether": "Aether"
      }
      var lower = id.toLowerCase()
      if (map[lower]) return map[lower]
      if (id.indexOf(".") !== -1) {
        var parts = id.split(".")
        var last = parts[parts.length - 1]
        if (last.length > 0) return last.charAt(0).toUpperCase() + last.slice(1)
      }
      return id.charAt(0).toUpperCase() + id.slice(1)
    }

    if (title !== "") {
      if (title.indexOf(" - ") !== -1) {
        var segs2 = title.split(" - ")
        return segs2[segs2.length - 1].trim()
      }
      if (title.length > 22) return title.substring(0, 19) + "..."
      return title
    }

    return ""
  }

  readonly property string appName: cleanAppName(rawClass, rawTitle)
  visible: appName !== "" && !vertical

  implicitWidth: visible ? Math.max(30, pillRect.width + 6) : 0
  implicitHeight: barSize

  Behavior on implicitWidth {
    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
  }

  Rectangle {
    id: pillRect
    anchors.centerIn: parent
    height: 22
    width: contentRow.implicitWidth + 20
    radius: height / 2

    // Dark scarlet background with glowing electric cyan border
    color: "#1c030b"
    border.width: 1
    border.color: "#00f0ff"

    Row {
      id: contentRow
      anchors.centerIn: parent
      spacing: 6

      // Glowing cyan indicator dot
      Rectangle {
        width: 6
        height: 6
        radius: 3
        anchors.verticalCenter: parent.verticalCenter
        color: "#00f0ff"
      }

      Text {
        id: nameLabel
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: root.appName
        color: "#ffffff"
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: 11
        font.bold: true
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.toplevel) root.toplevel.activate()
    }
  }
}
