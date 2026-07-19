/*
 * Copyright (C) 2026 Timo Könnecke <github.com/moWerk>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick

// Game-over overlay: dimmed backdrop, current-run summary, sorted
// per-difficulty leaderboard, restart button. Display-only — all state
// arrives through the four properties; the single write-back is the
// restartClicked signal.
Item {
    id: page

    // ── Interface — primitives only ──────────────────────────────────────
    property var  model: []
    property real dimsFactor: 1
    property real goScale: 1.2
    property bool active: false

    signal restartClicked()

    visible: active
    opacity: 0
    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }
    onVisibleChanged: {
        if (visible) {
            opacity = 1
        } else {
            opacity = 0
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.72
    }

    // Scrollable results list
    ListView {
        id: goList
        anchors {
            fill: parent
            leftMargin: page.dimsFactor * 15
            rightMargin: page.dimsFactor * 15
            topMargin: page.dimsFactor * 22
            bottomMargin: page.dimsFactor * 28
        }
        model: page.model
        spacing: 0

        delegate: Item {
            width: ListView.view ? ListView.view.width : 0
            height: !modelData ? 0 :
                    modelData.rowType === "header" ? page.dimsFactor * 12 : page.dimsFactor * 24

            // Current run row
            Column {
                visible: modelData && modelData.rowType === "current"
                anchors.centerIn: parent
                spacing: page.dimsFactor * 1

                Text {
                    text: modelData ? modelData.name : ""
                    color: "#dddddd"
                    font { pixelSize: page.dimsFactor * 8; bold: true; family: "Fyodor" }
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: page.dimsFactor * 7
                    Text {
                        text: "Score  " + (modelData ? modelData.score : 0)
                        color: "white"
                        font.pixelSize: page.dimsFactor * 6
                        font.bold: true
                    }
                    Text {
                        text: "Level  " + (modelData ? modelData.level : 0)
                        color: "white"
                        font.pixelSize: page.dimsFactor * 6
                        font.bold: true
                    }
                }
            }

            // Highscore header row
            Text {
                visible: modelData && modelData.rowType === "header"
                text: "Highscore"
                color: "#888888"
                font { pixelSize: page.dimsFactor * 8; family: "Fyodor" }
                anchors.centerIn: parent
            }

            // Historical difficulty row
            Column {
                visible: modelData && modelData.rowType === "history"
                anchors.centerIn: parent
                spacing: page.dimsFactor * 1

                Text {
                    text: modelData ? modelData.name : ""
                    color: "#cccccc"
                    font.pixelSize: page.dimsFactor * 6
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: page.dimsFactor * 7
                    Text {
                        text: "Score  " + (modelData ? modelData.score : 0)
                        color: "white"
                        font.pixelSize: page.dimsFactor * 6
                    }
                    Text {
                        text: "Level  " + (modelData ? modelData.level : 0)
                        color: "white"
                        font.pixelSize: page.dimsFactor * 6
                    }
                }
            }
        }
    }

    // "Game Over!" floats above the list — declared after ListView
    Text {
        text: "Game Over!"
        color: "red"
        font {
            pixelSize: Math.round(page.dimsFactor * 8 * page.goScale)
            bold: true
        }
        anchors {
            top: parent.top
            topMargin: page.dimsFactor * 6
            horizontalCenter: parent.horizontalCenter
        }
    }

    // "Die Again" button — declared last, MouseArea never covered
    Rectangle {
        id: tryAgainButton
        width: Math.round(page.dimsFactor * 42 * page.goScale)
        height: Math.round(page.dimsFactor * 14 * page.goScale)
        color: "green"
        border.color: "white"
        border.width: Math.round(page.dimsFactor * 1 * page.goScale)
        radius: Math.round(page.dimsFactor * 3 * page.goScale)
        anchors {
            bottom: parent.bottom
            bottomMargin: page.dimsFactor * 8
            horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Die Again"
            color: "white"
            font {
                pixelSize: Math.round(page.dimsFactor * 6 * page.goScale)
                bold: true
            }
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            enabled: page.active
            onClicked: page.restartClicked()
        }
    }
}
