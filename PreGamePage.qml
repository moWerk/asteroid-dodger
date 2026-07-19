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

// Pre-game flow: title, difficulty selection, calibration countdown and
// the NOW/SURVIVE intro flashes. Display + one decision: the die-now tap
// emits dieNowClicked(name); all difficulty/calibration state transitions
// stay in main.qml. playNow()/playSurvive()/stopIntros() are driven by
// the root intro timers.
Item {
    id: page

    // ── Interface — primitives only ──────────────────────────────────────
    property real dimsFactor: 1
    property real goScale: 1.2
    property bool selectingDifficulty: false
    property bool calibrating: false
    property int  calibrationTimer: 0
    property bool showingNow: false
    property bool showingSurvive: false

    signal dieNowClicked(string difficultyName)

    function playNow()     { nowTransition.start() }
    function playSurvive() { surviveTransition.start() }
    function stopIntros()  { nowTransition.stop(); surviveTransition.stop() }

    Item {
        id: titleText
        anchors {
            top: parent.top
            topMargin: dimsFactor * 10
            horizontalCenter: parent.horizontalCenter
        }
        z: 4
        visible: calibrating || selectingDifficulty

        Text {
            text: "v2.0\nAsteroid Dodger"
            color: "#dddddd"
            font {
                family: "Fyodor"
                pixelSize: dimsFactor * 15
            }
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Item {
        id: calibrationContainer
        anchors.fill: parent
        visible: calibrating || selectingDifficulty

        // ── Difficulty selector — shown on startup ────────────────────
        Column {
            id: difficultySelector
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: parent.height * 0.42
            }
            spacing: dimsFactor * 4
            visible: selectingDifficulty

            ValueCycler {
                id: difficultyCycler
                width: dimsFactor * 54
                height: dimsFactor * 26
                anchors.horizontalCenter: parent.horizontalCenter
                valueArray: ["Cadet Swerver", "Captain Slipstreamer", "Commander Stardust", "Major Roadkill"]
                currentValue: DodgerStorage.difficulty
                onValueChanged: currentValue = value
            }

            Rectangle {
                id: dieNowButton
                width: Math.round(dimsFactor * 42 * goScale)
                height: Math.round(dimsFactor * 14 * goScale)
                color: "green"
                border.color: "white"
                border.width: Math.round(dimsFactor * 1 * goScale)
                radius: Math.round(dimsFactor * 3 * goScale)
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    text: "Die Now"
                    color: "white"
                    font {
                        pixelSize: Math.round(dimsFactor * 6 * goScale)
                        bold: true
                    }
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: page.dieNowClicked(difficultyCycler.currentValue)
                }
            }
        }

        // ── Calibration countdown — shown after Die Now ───────────────
        Column {
            id: calibrationText
            anchors {
                top: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            spacing: dimsFactor * 1
            visible: calibrating
            opacity: showingNow ? 0 : 1
            Behavior on opacity {
                NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
            }

            Text {
                text: "Calibrating"
                color: "white"
                font.pixelSize: dimsFactor * 9
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: "Hold your watch comfy"
                color: "white"
                font.pixelSize: dimsFactor * 6
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: calibrationTimer + "s"
                color: "white"
                font.pixelSize: dimsFactor * 9
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // ── Intro transitions ─────────────────────────────────────────────

    Text {
        id: nowText
        text: "NOW"
        color: "white"
        font {
            pixelSize: dimsFactor * 24
            family: "Fyodor"
        }
        anchors.centerIn: parent
        visible: showingNow
        opacity: 0
        SequentialAnimation {
            id: nowTransition
            running: false
            NumberAnimation { target: nowText; property: "opacity"; from: 0; to: 1; duration: 500 }
            ParallelAnimation {
                NumberAnimation { target: nowText; property: "font.pixelSize"; from: dimsFactor * 24; to: dimsFactor * 48; duration: 1000; easing.type: Easing.OutQuad }
                NumberAnimation { target: nowText; property: "opacity"; from: 1; to: 0; duration: 1000; easing.type: Easing.OutQuad }
            }
        }
    }

    Text {
        id: surviveText
        text: "SURVIVE"
        color: "orange"
        font {
            pixelSize: dimsFactor * 24
            family: "Fyodor"
        }
        anchors.centerIn: parent
        visible: showingSurvive
        opacity: 0
        SequentialAnimation {
            id: surviveTransition
            running: false
            NumberAnimation { target: surviveText; property: "opacity"; from: 0; to: 1; duration: 500 }
            ParallelAnimation {
                NumberAnimation { target: surviveText; property: "font.pixelSize"; from: dimsFactor * 24; to: dimsFactor * 48; duration: 1000; easing.type: Easing.OutQuad }
                NumberAnimation { target: surviveText; property: "opacity"; from: 1; to: 0; duration: 1000; easing.type: Easing.OutQuad }
            }
        }
    }

}
