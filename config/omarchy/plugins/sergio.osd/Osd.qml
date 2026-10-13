import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "OsdModel.js" as OsdModel

Item {
  id: root

  property bool opened: false
  property string icon: ""
  property string message: ""
  property string iconKey: ""
  property int value: 0
  property int maxValue: 100
  property bool hasProgress: true
  property int duration: 1200

  readonly property bool mediaOsd: iconKey.indexOf("media") === 0 || iconKey.indexOf("player") === 0

  // The card is built out of measured columns instead of fixed widths, so it
  // keeps exactly `pad` between border and content on every side whatever
  // glyph or message it carries. Messages grow with their text up to
  // `maxMessageWidth` and elide beyond it.
  readonly property int pad: Style.space(16)
  readonly property int gap: Style.space(16)
  // A glyph next to a message reads airier than it measures: the icon outline
  // and the letterforms both fall away from their ink extremes, so the space
  // between them opens up well past the nominal gap. Text takes two thirds of
  // it; the progress bar's hard edge keeps the full gap.
  readonly property int messageGap: Math.round(root.gap * 2 / 3)
  readonly property int barWidth: Style.space(142)
  readonly property int maxMessageWidth: root.mediaOsd ? Style.space(325) : Style.space(190)

  // Nerd Font glyphs draw well outside their monospace cell, so the icon
  // column is measured by ink rather than by advance width. Progress OSDs pin
  // it to the widest glyph the model can return, so the bar doesn't shift when
  // volume crosses an icon threshold.
  readonly property int iconInkWidth: Math.ceil(iconMetrics.tightBoundingRect.width)
  readonly property int iconWidth: root.hasProgress
    ? Math.max(root.iconInkWidth, Math.ceil(widestIconMetrics.tightBoundingRect.width))
    : root.iconInkWidth
  // Same idea for the readout: it is as wide as the longest percentage so the
  // digits don't jitter between 9% and 100%.
  readonly property int valueWidth: Math.ceil(Math.max(valueMetrics.advanceWidth, messageMetrics.advanceWidth))
  readonly property int messageWidth: Math.min(Math.ceil(messageMetrics.advanceWidth), root.maxMessageWidth)
  readonly property int contentWidth: root.hasProgress
    ? root.iconWidth + root.gap + root.barWidth + root.gap + root.valueWidth
    : (root.message === "" ? root.iconWidth : root.iconWidth + root.messageGap + root.messageWidth)

  function iconFor(name, percent) {
    return OsdModel.iconFor(name, percent)
  }

  // ---------------------------------------------------------- Omacale
  //
  // omacale:osd-handover v4 -- patched by Omacale (scripts/osd-handover).
  //
  // Omacale draws Caelestia's OSD for the speaker volume, the microphone and
  // the display brightness -- vertical sliders that slide out of the edge of
  // its frame -- and every other OSD as one of Caelestia's toasts. What it
  // takes is passed on through a file in the runtime directory, whole: the
  // brightness level only exists in it, a key press that changes nothing
  // (volume up at 100%) should still show the sliders, and a toast needs the
  // message. What it doesn't take is drawn here, as stock.
  //
  // Only while Omacale's bar is running in this very shell process (its
  // claim names this process), its OSD is on and nothing is fullscreen
  // (Omacale's frame is on the `top` layer, under a fullscreen window), and
  // only for what Omacale is set to draw. With any of those gone this is
  // Omarchy's OSD again, without a restart: a bar that failed to load, a
  // claim left by a crashed shell, Omacale switched off or uninstalled.
  //
  // Both files are read when a payload arrives rather than watched: a watch
  // on a file that doesn't exist yet (settings.json is only written once a
  // setting changes) never sees it appear. They are a few hundred bytes.
  readonly property string omacaleRuntime: Quickshell.env("XDG_RUNTIME_DIR") || ""
  property int omacaleSeq: 0

  function omacaleRead(view) {
    if (view.path === "") return null
    try {
      view.reload()
      view.waitForJob()
      var value = JSON.parse(view.text())
      return value && typeof value === "object" ? value : null
    } catch (e) {
      return null
    }
  }

  function omacaleSetting(settings, path, fallback) {
    var node = settings
    var keys = path.split(".")
    for (var i = 0; i < keys.length; i++) {
      if (!node || typeof node !== "object" || !(keys[i] in node)) return fallback
      node = node[keys[i]]
    }
    return typeof node === typeof fallback ? node : fallback
  }

  function omacaleFullscreen() {
    var monitor = Hyprland.focusedMonitor
    var workspace = monitor ? monitor.activeWorkspace : null
    if (!workspace || !workspace.toplevels) return false
    var windows = workspace.toplevels.values
    for (var i = 0; i < windows.length; i++) {
      var ipc = windows[i] ? windows[i].lastIpcObject : null
      if (ipc && ipc.fullscreen > 1) return true
    }
    return false
  }

  // What Omacale draws of this payload, or "" when it stays Omarchy's:
  // a slider ("volume", "brightness", "microphone"), "toast", or "output"
  // (the output switcher, left to the toast Omacale raises on the device
  // change itself).
  function omacaleKind(next, settings) {
    var key = String(next.iconKey || "")
    var toasts = root.omacaleSetting(settings, "osd.toasts", true)
    if (key.indexOf("volume") === 0 && next.hasProgress) return "volume"
    if ((key === "brightness" || key === "display") && next.hasProgress
        && root.omacaleSetting(settings, "osd.enableBrightness", true)) return "brightness"
    if (key.indexOf("microphone") === 0 && root.omacaleSetting(settings, "osd.enableMicrophone", false)) return "microphone"
    if (key.indexOf("volume") === 0)
      return toasts ? "toast" : root.omacaleSetting(settings, "utilities.toasts.audioOutputChanged", true) ? "output" : ""
    // An icon alone has nothing a toast could say; Omarchy draws it.
    if (toasts && (next.message !== "" || next.hasProgress)) return "toast"
    return ""
  }

  function omacaleSend(payload) {
    if (omacaleForward.path === "") return
    root.omacaleSeq++
    payload.seq = root.omacaleSeq
    payload.at = Date.now()
    omacaleForward.setText(JSON.stringify(payload))
  }

  // True when Omacale draws this payload instead.
  function omacaleTakes(next) {
    var claim = root.omacaleRead(omacaleClaim)
    if (!claim || claim.pid !== Quickshell.processId) return false
    var settings = root.omacaleRead(omacaleSettingsFile) || ({})
    if (!root.omacaleSetting(settings, "osd.enabled", true) || root.omacaleFullscreen()) return false
    var kind = root.omacaleKind(next, settings)
    if (kind === "") return false
    root.omacaleSend({
      kind: kind,
      iconKey: String(next.iconKey || ""),
      message: String(next.message || ""),
      hasProgress: !!next.hasProgress,
      value: next.value,
      max: next.maxValue,
      duration: next.duration
    })
    return true
  }

  FileView {
    id: omacaleForward
    path: root.omacaleRuntime === "" ? "" : root.omacaleRuntime + "/omacale-osd.json"
    atomicWrites: true
    printErrors: false
  }

  // Written by Omacale's bar as it loads ({ pid }), released as it unloads.
  FileView {
    id: omacaleClaim
    path: root.omacaleRuntime === "" ? "" : root.omacaleRuntime + "/omacale-osd-claim.json"
    blockLoading: true
    printErrors: false
  }

  FileView {
    id: omacaleSettingsFile
    path: Quickshell.env("HOME") + "/.config/omacale/settings.json"
    blockLoading: true
    printErrors: false
  }

  function show(iconName, rawMessage, rawValue, rawMax, rawProgressText, rawDuration) {
    var next = OsdModel.stateForShow(iconName, rawMessage, rawValue, rawMax, rawProgressText, rawDuration)
    if (root.omacaleTakes(next)) return
    // Update before opening so a fresh OSD starts at its new value; only
    // subsequent updates while it remains open animate the progress bar.
    iconKey = next.iconKey
    maxValue = next.maxValue
    hasProgress = next.hasProgress
    value = next.value
    message = next.message
    icon = next.icon
    duration = next.duration
    opened = true
    if (duration > 0) hideTimer.restart()
    else hideTimer.stop()
  }

  function open(payloadJson) {
    try {
      var p = JSON.parse(payloadJson || "{}")
      show(p.icon || "", p.message || "", p.value === undefined ? "" : String(p.value), p.max === undefined ? "100" : String(p.max), p.progressText || "", p.duration === undefined ? "1200" : String(p.duration))
    } catch (e) {}
  }

  function close() { opened = false; root.omacaleSend({ kind: "close" }) }

  Timer {
    id: hideTimer
    interval: root.duration
    onTriggered: root.opened = false
  }

  TextMetrics {
    id: messageMetrics
    font.family: Style.font.family
    font.bold: true
    font.pixelSize: Style.font.title
    text: root.message
  }

  TextMetrics {
    id: valueMetrics
    font: messageMetrics.font
    text: "100%"
  }

  TextMetrics {
    id: iconMetrics
    font.family: Style.font.family
    font.pixelSize: Style.font.displayLarge
    text: root.icon
  }

  TextMetrics {
    id: widestIconMetrics
    font: iconMetrics.font
    text: OsdModel.widestIcon
  }

  IpcHandler {
    target: "osd"
    function show(payloadJson: string): string {
      root.open(payloadJson)
      return "ok"
    }
    function close(): string { root.close(); return "ok" }
    function state(): string { return root.opened ? "open" : "closed" }
    // The health check's sign that this is the patched OSD, and which patch.
    function omacaleOsd(): string { return "omacale:osd-handover v4" }
    function ping(): string { return "ok" }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    // Visual-only surface: keep the layer-shell input region empty so the OSD
    // never blocks clicks to the desktop below it.
    mask: Region {}

    BorderSurface {
      id: card
      width: card.borderLeft + root.pad + root.contentWidth + root.pad + card.borderRight
      height: card.borderTop + root.pad + Style.font.displayLarge + root.pad + card.borderBottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(67)
      color: Util.alpha(Color.background, 0.97)
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius
      opacity: root.opened ? 1 : 0

      Row {
        anchors.fill: parent
        anchors.topMargin: card.borderTop + root.pad
        anchors.rightMargin: card.borderRight + root.pad
        anchors.bottomMargin: card.borderBottom + root.pad
        anchors.leftMargin: card.borderLeft + root.pad
        spacing: root.hasProgress ? root.gap : root.messageGap
        Item {
          width: root.iconWidth
          height: parent.height
          Text {
            textFormat: Text.PlainText
            // Sit the glyph's ink flush in the column, centered when the
            // column is wider than this particular glyph.
            x: Math.round((root.iconWidth - root.iconInkWidth) / 2 - iconMetrics.tightBoundingRect.x)
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            font: iconMetrics.font
            color: Color.popups.text
          }
        }
        Rectangle {
          visible: root.hasProgress
          width: root.barWidth
          height: Math.max(Style.space(6), Style.spacing.sm)
          anchors.verticalCenter: parent.verticalCenter
          color: Util.alpha(Color.popups.text, 0.45)
          Rectangle {
            height: parent.height
            width: parent.width * (root.hasProgress ? root.value / root.maxValue : 0)
            color: Color.accent

            Behavior on width {
              enabled: root.opened
              NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
          }
        }
        Text {
          textFormat: Text.PlainText
          visible: root.message !== ""
          width: root.hasProgress ? root.valueWidth : root.messageWidth
          // The readout hugs the card edge so a short percentage doesn't leave
          // a hole in the padding; the slack lands in the gap after the bar.
          horizontalAlignment: root.hasProgress ? Text.AlignRight : Text.AlignLeft
          anchors.verticalCenter: parent.verticalCenter
          text: root.message
          font: messageMetrics.font
          color: Color.popups.text
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }
    }
  }
}
