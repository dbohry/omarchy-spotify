import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Ui
import qs.Commons
import qs.Commons as Commons

BarWidget {
  id: root
  moduleName: "spotify"

  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("omarchy.media")
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property var sourcePlayers: mediaService ? mediaService.sourcePlayers : []

  readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle || activePlayer.trackArtist)
  readonly property string playIcon: activePlayer && activePlayer.isPlaying ? "󰏤" : "󰐊"
  readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""

  property bool popupOpen: false

  function close() { popupOpen = false }

  visible: true
  implicitWidth: glyph.implicitWidth + Style.space(14)
  implicitHeight: barSize

  Text {
    id: glyph
    textFormat: Text.PlainText
    anchors.centerIn: parent
    text: "󰓇"
    color: root.activePlayer && root.activePlayer.isPlaying ? Commons.Color.accent : root.bar.barForeground
    font.family: root.bar.fontFamily
    font.pixelSize: Style.font.body
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.popupOpen = !root.popupOpen
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.popupOpen
    onActivated: root.close()
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        spacing: Style.space(10)
        width: parent.width

        BorderSurface {
          width: Style.space(64)
          height: Style.space(64)
          radius: Style.spacing.labelGap
          color: Style.normalFillFor(root.bar.foreground, Commons.Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Commons.Color.accent)

          Image {
            anchors.fill: parent
            anchors.margins: Style.space(2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: root.activePlayer && root.activePlayer.trackArtUrl ? root.activePlayer.trackArtUrl : ""
            visible: source !== ""
          }

          Text {
            anchors.centerIn: parent
            visible: !root.activePlayer || !root.activePlayer.trackArtUrl
            text: "󰝚"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
          }
        }

        Column {
          spacing: Style.space(4)
          width: parent.width - Style.space(74)

          Item {
            id: titleClip
            width: parent.width
            height: titleText.implicitHeight
            clip: true

            Text {
              id: titleText
              textFormat: Text.PlainText
              text: root.title || "Nothing playing"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
              x: 0

              property bool needsScroll: implicitWidth > titleClip.width
              onTextChanged: x = 0

              SequentialAnimation on x {
                running: titleText.needsScroll && root.popupOpen
                loops: Animation.Infinite
                PauseAnimation { duration: 1500 }
                NumberAnimation {
                  to: titleClip.width - titleText.implicitWidth - Style.space(8)
                  duration: Math.max(3000, (titleText.implicitWidth - titleClip.width) * 30)
                  easing.type: Easing.Linear
                }
                PauseAnimation { duration: 1500 }
                NumberAnimation { to: 0; duration: 400 }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            text: root.artist
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }

          Text {
            textFormat: Text.PlainText
            text: root.activePlayer && root.activePlayer.trackAlbum ? root.activePlayer.trackAlbum : ""
            color: Qt.darker(root.bar.foreground, 1.6)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }
        }
      }

      Item {
        id: progress
        width: parent.width
        height: Style.space(16)
        visible: root.activePlayer && root.activePlayer.length > 0

        readonly property real pos: root.activePlayer ? root.activePlayer.position : 0
        readonly property real len: root.activePlayer ? root.activePlayer.length : 0
        readonly property real ratio: len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0

        function fmt(t) {
          var s = Math.max(0, Math.floor(t))
          var m = Math.floor(s / 60)
          var r = s % 60
          return m + ":" + (r < 10 ? "0" : "") + r
        }

        Timer {
          interval: 1000
          repeat: true
          running: root.popupOpen && root.activePlayer && root.activePlayer.isPlaying
          onTriggered: root.activePlayer.positionChanged()
        }

        Rectangle {
          id: track
          anchors.left: parent.left
          anchors.right: timeText.left
          anchors.rightMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          height: Style.space(4)
          radius: height / 2
          color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.2)

          Rectangle {
            width: parent.width * progress.ratio
            height: parent.height
            radius: parent.radius
            color: Commons.Color.accent
          }
        }

        MouseArea {
          id: seekArea
          anchors.left: track.left
          anchors.right: track.right
          anchors.verticalCenter: parent.verticalCenter
          height: parent.height
          hoverEnabled: true
          enabled: root.activePlayer && root.activePlayer.canSeek && root.activePlayer.positionSupported
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

          function seekTo(x) {
            var r = Math.max(0, Math.min(1, x / width))
            root.activePlayer.position = r * progress.len
          }
          onPressed: function(mouse) { seekTo(mouse.x) }
          onPositionChanged: function(mouse) { if (pressed) seekTo(mouse.x) }
        }

        Rectangle {
          id: seekHandle
          visible: seekArea.enabled && (seekArea.containsMouse || seekArea.pressed)
          width: Style.space(10)
          height: width
          radius: width / 2
          color: Commons.Color.accent
          x: track.x + track.width * progress.ratio - width / 2
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          id: timeText
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: (seekArea.containsMouse && seekArea.enabled ? progress.fmt(seekArea.mouseX / seekArea.width * progress.len) : progress.fmt(progress.pos)) + "/" + progress.fmt(progress.len)
          color: Qt.darker(root.bar.foreground, 1.3)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)
        visible: root.activePlayer

        Button {
          iconText: "󰒟"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          active: root.activePlayer && root.activePlayer.shuffle
          enabled: root.activePlayer && root.activePlayer.shuffleSupported
          opacity: enabled ? 1.0 : 0.4
          onClicked: root.activePlayer.shuffle = !root.activePlayer.shuffle
        }

        Button {
          iconText: "󰒮"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.activePlayer && root.activePlayer.canGoPrevious
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("previous", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          iconText: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.activePlayer && (root.activePlayer.canTogglePlaying || root.activePlayer.canPlay || root.activePlayer.canPause)
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("playPause", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          iconText: "󰒭"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.activePlayer && root.activePlayer.canGoNext
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("next", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          readonly property int loop: root.activePlayer ? root.activePlayer.loopState : MprisLoopState.None
          iconText: loop === MprisLoopState.Track ? "󰑘" : (loop === MprisLoopState.Playlist ? "󰑖" : "󰑗")
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          active: loop !== MprisLoopState.None
          enabled: root.activePlayer && root.activePlayer.loopSupported
          opacity: enabled ? 1.0 : 0.4
          onClicked: root.activePlayer.loopState = loop === MprisLoopState.None ? MprisLoopState.Playlist
            : (loop === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None)
        }
      }

      Button {
        visible: !root.activePlayer
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Open Spotify"
        iconText: "󰓇"
        foreground: root.bar.foreground
        horizontalPadding: Style.spacing.panelGap
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: {
          Quickshell.execDetached(["uwsm-app", "--", "spotify"])
          root.popupOpen = false
        }
      }

      PanelSeparator {
        visible: root.sourcePlayers.length > 1
        foreground: root.bar.foreground
      }

      Column {
        id: sourceList
        visible: root.sourcePlayers.length > 1
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          model: root.sourcePlayers

          BorderSurface {
            id: sourceRow
            required property var modelData

            readonly property var player: modelData
            readonly property bool selected: root.activePlayer && player
              && root.mediaService.playerKey(root.activePlayer) === root.mediaService.playerKey(player)
            readonly property string sourceTitle: player ? (player.trackTitle || player.identity || player.desktopEntry || "Media source") : "Media source"
            readonly property string sourceDetail: player && player.trackArtist ? player.trackArtist : (player && player.identity ? player.identity : "")

            width: sourceList.width
            height: sourceInner.implicitHeight + Style.space(10)
            radius: Style.spacing.labelGap
            color: selected ? Style.selectedFillFor(root.bar.foreground, Commons.Color.accent) : "transparent"
            borderSpec: selected ? Border.controlSpec("normal", root.bar.foreground, Commons.Color.accent) : Border.none()

            Row {
              id: sourceInner
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: sourceRow.borderLeft + Style.space(8)
              anchors.rightMargin: sourceRow.borderRight + Style.space(8)
              spacing: Style.space(8)

              Text {
                textFormat: Text.PlainText
                text: sourceRow.player && sourceRow.player.isPlaying ? "󰏤" : "󰐊"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
                width: Style.space(18)
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - Style.space(26)
                spacing: Style.space(1)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  textFormat: Text.PlainText
                  text: sourceRow.sourceTitle
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: sourceRow.selected
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  textFormat: Text.PlainText
                  text: sourceRow.sourceDetail
                  color: Qt.darker(root.bar.foreground, 1.5)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  width: parent.width
                  visible: text !== ""
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.mediaService) root.mediaService.selectPlayer(root.mediaService.playerKey(sourceRow.player))
            }
          }
        }
      }
    }
  }
}
