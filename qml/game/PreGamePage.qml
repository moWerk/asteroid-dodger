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

import QtQuick 2.6
import "."

// Pre-game flow: cover art, title, difficulty selection, calibration countdown and
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
    property string version: ""

    signal dieNowClicked(string difficultyName)

    function playNow()     { nowTransition.start() }
    function playSurvive() { surviveTransition.start() }
    function stopIntros()  { nowTransition.stop(); surviveTransition.stop() }

    readonly property bool shown: calibrating || selectingDifficulty

    // SailfishOS: cover art (AI-generated with Grok from the author's prompt;
    // see img/README). Its trail runs through the middle, so the title keeps
    // to the top and the controls to the bottom. It fades with the NOW flash.
    Image {
        anchors.fill: parent
        source: "img/title-art.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: opacity > 0
        opacity: shown && !showingNow ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    }

    Text {
        id: titleText
        text: "Asteroid\nDodger"
        color: "#dddddd"
        visible: shown
        opacity: showingNow ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
        lineHeightMode: Text.ProportionalHeight
        lineHeight: 0.8
        font { family: "Fyodor"; pixelSize: dimsFactor * 22 }
        anchors { top: parent.top; topMargin: parent.height * 0.06; horizontalCenter: parent.horizontalCenter }
        horizontalAlignment: Text.AlignHCenter
        z: 4
    }

    // Difficulty selection or calibration, start button: one block at the bottom.
    Column {
        id: startBlock
        anchors { bottom: parent.bottom; bottomMargin: parent.height * 0.08; horizontalCenter: parent.horizontalCenter }
        width: parent.width
        spacing: dimsFactor * 10
        z: 4
        visible: shown

        Column {
            id: difficultySelector
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: dimsFactor * 10
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
                border.width: Math.round(dimsFactor * 0.7 * goScale)
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

        Column {
            id: calibrationText
            anchors.horizontalCenter: parent.horizontalCenter
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
                text: "Hold your phone comfy"
                color: "white"
                font.pixelSize: dimsFactor * 6
                width: page.width - dimsFactor * 8
                wrapMode: Text.WordWrap
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

    Text {
        text: version
        color: "#888888"
        font.pixelSize: dimsFactor * 3.5
        visible: shown
        opacity: showingNow ? 0 : 1
        anchors { left: parent.left; leftMargin: dimsFactor * 3; bottom: parent.bottom; bottomMargin: dimsFactor * 2 }
        z: 4
    }
    Text {
        text: "by moWerk"
        color: "#888888"
        font.pixelSize: dimsFactor * 3.5
        visible: shown
        opacity: showingNow ? 0 : 1
        anchors { right: parent.right; rightMargin: dimsFactor * 3; bottom: parent.bottom; bottomMargin: dimsFactor * 2 }
        z: 4
    }

    Text {
        id: nowText
        text: "NOW"
        color: "white"
        font {
            pixelSize: dimsFactor * 24
            family: "Fyodor"
        }
        // grows past the screen edges on purpose
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
        // grows past the screen edges on purpose
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
