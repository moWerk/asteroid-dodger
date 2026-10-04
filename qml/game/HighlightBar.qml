/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
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

// Stand-in for HighlightBar of org.asteroid.controls: a press highlight
// that fills its parent and reports clicks.
Item {
    id: bar

    property alias radius: highlight.radius
    signal clicked()

    anchors.fill: parent

    Rectangle {
        id: highlight
        anchors.fill: parent
        color: "#ffffff"
        opacity: mouse.pressed ? 0.2 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        onClicked: bar.clicked()
    }
}
