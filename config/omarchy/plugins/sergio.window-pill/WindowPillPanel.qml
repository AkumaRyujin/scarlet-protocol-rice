import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

Item {
  id: root

  // Cached map of screenName -> list of window objects
  property var screenWindows: ({})
  property string focusedAddr: ""

  function appNameForClassAndTitle(rawClass, rawTitle) {
    var id = String(rawClass || "").trim()
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

    var t = String(rawTitle || "").trim()
    if (t !== "") {
      if (t.indexOf(" - ") !== -1) {
        var segs = t.split(" - ")
        return segs[segs.length - 1].trim()
      }
      if (t.length > 22) return t.substring(0, 19) + "..."
      return t
    }

    return "App"
  }

  function recomputeWindows() {
    var activeT = null
    try { activeT = Hyprland.activeToplevel } catch (e0) {}
    root.focusedAddr = activeT ? String(activeT.address || "") : ""

    var mons = []
    try { mons = (Hyprland.monitors && Hyprland.monitors.values) ? Hyprland.monitors.values : [] } catch (e1) {}

    var toplevels = []
    try { toplevels = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : [] } catch (e2) {}

    var screens = Quickshell.screens || []
    var newMap = {}

    for (var s = 0; s < screens.length; s++) {
      var scr = screens[s]
      var sName = String(scr.name || "")
      if (!sName) continue

      // Find monitor info
      var monObj = null
      for (var m = 0; m < mons.length; m++) {
        if (mons[m] && String(mons[m].name) === sName) {
          monObj = mons[m]
          break
        }
      }

      var activeWsId = (monObj && monObj.activeWorkspace) ? monObj.activeWorkspace.id : -999
      var monId = monObj ? monObj.id : -999

      var winList = []
      for (var i = 0; i < toplevels.length; i++) {
        var top = toplevels[i]
        if (!top) continue
        var ipc = top.lastIpcObject || {}

        // Validate geometry
        if (!Array.isArray(ipc.at) || !Array.isArray(ipc.size)) continue
        if (ipc.at.length < 2 || ipc.size.length < 2) continue

        // Skip hidden or fullscreen windows
        if (ipc.hidden === true) continue
        if (ipc.fullscreen !== undefined && ipc.fullscreen !== null && Number(ipc.fullscreen) > 0) continue

        // Check workspace
        var wsId = (ipc.workspace && ipc.workspace.id !== undefined) ? ipc.workspace.id : -1
        if (wsId !== activeWsId) continue

        // Check monitor
        var wMon = ipc.monitor
        var matchesMon = (wMon === monId || String(wMon) === sName || String(wMon) === String(monId))
        if (!matchesMon) continue

        var rawClass = String(ipc["class"] || ipc["initialClass"] || top.className || "")
        var rawTitle = String(ipc.title || top.title || "")
        var addr = String(ipc.address || top.address || "")

        // Screen-relative coordinates:
        // Positioned sitting on the top-left border of the window
        var relX = Number(ipc.at[0]) - Number(scr.x) + 14
        var relY = Number(ipc.at[1]) - Number(scr.y) - 11

        winList.push({
          address: addr,
          x: relX,
          y: relY,
          width: Number(ipc.size[0]),
          height: Number(ipc.size[1]),
          appName: root.appNameForClassAndTitle(rawClass, rawTitle),
          title: rawTitle,
          focused: (addr !== "" && addr === root.focusedAddr)
        })
      }

      newMap[sName] = winList
    }

    root.screenWindows = newMap
  }

  Timer {
    id: updateDebounce
    interval: 25
    repeat: false
    onTriggered: root.recomputeWindows()
  }

  function triggerRefresh() {
    updateDebounce.restart()
  }

  Component.onCompleted: {
    try { Hyprland.refreshToplevels() } catch (e) {}
    root.recomputeWindows()
  }

  Connections {
    target: Hyprland
    function onActiveToplevelChanged() {
      root.triggerRefresh()
    }
    function onRawEvent(e) {
      if (!e || !e.name) return
      var n = String(e.name)
      if (["activewindow", "activewindowv2", "movewindow", "movewindowv2", "openwindow", "closewindow", "windowtitle", "windowtitlev2", "fullscreen", "workspace", "focusedmon"].indexOf(n) >= 0) {
        try { Hyprland.refreshToplevels() } catch (err) {}
        root.triggerRefresh()
      }
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: overlayWindow
        required property var modelData
        readonly property var scr: modelData

        screen: scr
        WlrLayershell.namespace: "sergio-window-pill"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        anchors { top: true; bottom: true; left: true; right: true }

        readonly property var windowsList: {
          var sName = String(scr.name || "")
          return (root.screenWindows && root.screenWindows[sName]) ? root.screenWindows[sName] : []
        }

        Repeater {
          model: overlayWindow.windowsList

          Item {
            id: pillWrapper
            required property var modelData

            x: modelData.x
            y: modelData.y
            z: modelData.focused ? 100 : 10

            Behavior on x {
              NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
            Behavior on y {
              NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            Rectangle {
              id: pillBadge
              height: 22
              width: contentRow.implicitWidth + 20
              radius: height / 2

              // Cyberpunk scarlet background
              color: "#1c030b"

              // Electric Cyan for active window, Neon Scarlet for inactive windows
              border.width: 1
              border.color: modelData.focused ? "#00f0ff" : "#ff0055"

              Behavior on border.color {
                ColorAnimation { duration: 150 }
              }

              Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: 6

                // Glowing indicator dot
                Rectangle {
                  width: 6
                  height: 6
                  radius: 3
                  anchors.verticalCenter: parent.verticalCenter
                  color: modelData.focused ? "#00f0ff" : "#ff0055"

                  Behavior on color {
                    ColorAnimation { duration: 150 }
                  }
                }

                Text {
                  textFormat: Text.PlainText
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.appName
                  color: modelData.focused ? "#ffffff" : "#ff8da5"
                  font.family: Style.font.family
                  font.pixelSize: 11
                  font.bold: true
                }
              }
            }
          }
        }
      }
    }
  }
}
