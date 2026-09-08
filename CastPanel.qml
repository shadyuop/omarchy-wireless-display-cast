import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

Panel {
  id: root
  moduleName: "shady.wireless-display-cast"
  ipcTarget: moduleName
  manageIpc: false
  readonly property string helper: decodeURIComponent(String(Qt.resolvedUrl("cast-helper")).replace(/^file:\/\//, ""))
  property var state: ({backend: false, network: false, p2p: false})
  property string error: ""
  property bool checked: false
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!check.running) check.running = true
  }
  function launch() {
    if (!root.state.backend) return
    // Detach so panel/shell reloads do not terminate an ongoing cast.
    Quickshell.execDetached(["bash", root.helper, "open"])
    root.close()
  }
  Component.onCompleted: refresh()
  onOpenedChanged: if (opened) refresh()

  Process {
    id: check
    command: ["bash", root.helper, "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.state = JSON.parse(text)
          root.checked = true
          root.error = ""
        } catch (e) {
          root.checked = false
          root.error = "Unable to check prerequisites. Try Refresh."
        }
      }
    }
  }

  BarIconButton {
    id: button
    bar: root.bar
    text: "󰄘"
    tooltipText: "Wireless Display Cast"
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: content
    contentWidth: popup.fittedContentWidth(Style.space(370))
    contentHeight: popup.fittedContentHeight(content.implicitHeight, Style.space(650))

    Column {
      id: content
      width: parent.width
      spacing: Style.space(12)
      Keys.onEscapePressed: root.close()

      Text {
        width: parent.width
        text: "Wireless Display Cast"
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.heading
        font.bold: true
        wrapMode: Text.WordWrap
      }
      Text {
        width: parent.width
        text: "Put your TV or receiver in Miracast / Screen Mirroring mode. Open the picker, choose the receiver, then approve the screen to share."
        color: Color.foreground
        font.family: Style.font.family
        wrapMode: Text.WordWrap
      }
      Text {
        width: parent.width
        text: !root.checked ? (root.error || "Checking prerequisites…") :
          "Casting app: " + (root.state.backend ? "Installed" : "Missing") +
          "\nNetworkManager: " + (root.state.network ? "Running" : "Unavailable") +
          "\nWi-Fi Direct device: " + (root.state.p2p ? "Detected" : "Not detected")
        color: Color.foreground
        font.family: Style.font.family
        wrapMode: Text.WordWrap
      }
      Controls.Button {
        width: parent.width
        text: "Open wireless display picker"
        enabled: root.checked && root.state.backend
        onClicked: root.launch()
      }
      Text {
        width: parent.width
        visible: root.checked && !root.state.backend
        text: "Install the casting app in a terminal:"
        color: Color.foreground
        wrapMode: Text.WordWrap
      }
      Controls.TextArea {
        width: parent.width
        visible: root.checked && !root.state.backend
        text: "omarchy pkg aur add gnome-network-displays"
        readOnly: true
        selectByMouse: true
        wrapMode: TextEdit.Wrap
      }
      Controls.Button {
        width: parent.width
        text: "Refresh prerequisites"
        enabled: !check.running
        onClicked: root.refresh()
      }
    }
  }
}
