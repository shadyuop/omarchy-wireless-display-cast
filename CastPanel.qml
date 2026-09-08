import QtQuick
import QtQuick.Layouts
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
      spacing: Style.space(18)
      Keys.onEscapePressed: root.close()

      RowLayout {
        width: parent.width
        spacing: Style.space(12)

        Rectangle {
          Layout.preferredWidth: Style.space(44)
          Layout.preferredHeight: Style.space(44)
          radius: Style.space(12)
          color: Util.alpha(Color.accent, 0.12)
          Text {
            anchors.centerIn: parent
            text: "󰄘"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.heading * 1.5
          }
        }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(3)
          Text {
            Layout.fillWidth: true
            text: "Wireless display"
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
            font.bold: true
            wrapMode: Text.WordWrap
          }
          Text {
            Layout.fillWidth: true
            text: "Share your screen, wirelessly"
            color: Util.alpha(Color.popups.text, 0.65)
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }
        }
        PanelActionButton {
          iconText: "󰑓"
          tooltipText: check.running ? "Checking prerequisites…" : "Refresh prerequisites"
          size: Style.space(32)
          radius: Style.space(8)
          focusable: true
          enabled: !check.running
          foreground: Color.popups.text
          hoverColor: Color.accent
          Accessible.role: Accessible.Button
          Accessible.name: "Refresh prerequisites"
          onClicked: root.refresh()
        }
      }

      Rectangle {
        width: parent.width
        implicitHeight: statusRows.implicitHeight + Style.space(24)
        radius: Style.space(12)
        color: Util.alpha(Color.popups.text, 0.04)
        border.width: 1
        border.color: Util.alpha(Color.popups.text, 0.09)

        Column {
          id: statusRows
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.space(12) }
          spacing: Style.space(14)

          Repeater {
            model: [
              {label: "Casting app", ready: root.state.backend, yes: "Installed", no: "Missing"},
              {label: "NetworkManager", ready: root.state.network, yes: "Running", no: "Unavailable"},
              {label: "Wi-Fi Direct", ready: root.state.p2p, yes: "Detected", no: "Not detected"}
            ]
            delegate: RowLayout {
              required property var modelData
              readonly property bool pending: check.running || !root.checked
              readonly property color statusColor: pending ? Color.muted : (modelData.ready ? Color.accent : Color.urgent)
              width: statusRows.width
              spacing: Style.space(10)
              Rectangle {
                Layout.preferredWidth: Style.space(7)
                Layout.preferredHeight: Style.space(7)
                radius: width / 2
                color: statusColor
                Behavior on color { ColorAnimation { duration: 120 } }
              }
              Text {
                Layout.fillWidth: true
                text: modelData.label
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                wrapMode: Text.WordWrap
              }
              Text {
                Layout.maximumWidth: statusRows.width * 0.43
                text: pending ? (root.error ? "Unknown" : "Checking…") : (modelData.ready ? modelData.yes : modelData.no)
                color: statusColor
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignRight
              }
            }
          }
        }
      }

      Text {
        width: parent.width
        visible: root.error !== ""
        text: root.error
        color: Color.urgent
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      Controls.Button {
        id: chooseButton
        width: parent.width
        implicitHeight: Math.max(Style.space(46), label.implicitHeight + Style.space(24))
        text: "Choose display"
        enabled: root.checked && root.state.backend && !check.running
        hoverEnabled: true
        Accessible.name: text
        onClicked: root.launch()
        contentItem: Text {
          id: label
          text: chooseButton.text
          color: chooseButton.enabled ? Color.background : Util.alpha(Color.popups.text, 0.45)
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          wrapMode: Text.WordWrap
        }
        background: Rectangle {
          radius: Style.space(10)
          color: !chooseButton.enabled ? Util.alpha(Color.popups.text, 0.08)
            : chooseButton.down ? Qt.darker(Color.accent, 1.18)
            : chooseButton.hovered ? Qt.lighter(Color.accent, 1.12) : Color.accent
          border.width: chooseButton.activeFocus ? 2 : 0
          border.color: Color.popups.text
          Behavior on color { ColorAnimation { duration: 120 } }
        }
      }

      Text {
        width: parent.width
        visible: !root.checked || root.state.backend
        text: "Set your TV to Miracast or Screen Mirroring."
        color: Util.alpha(Color.popups.text, 0.65)
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
      }
      Column {
        width: parent.width
        visible: root.checked && !root.state.backend
        spacing: Style.space(8)
        Text {
          width: parent.width
          text: "Install the casting app to get started:"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
        Controls.TextArea {
          width: parent.width
          text: "omarchy pkg aur add gnome-network-displays"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          readOnly: true
          selectByMouse: true
          wrapMode: TextEdit.Wrap
          padding: Style.space(10)
          background: Rectangle {
            radius: Style.space(8)
            color: Util.alpha(Color.popups.text, 0.06)
            border.color: Util.alpha(Color.popups.text, 0.12)
          }
        }
      }
    }
  }
}
