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
import Sailfish.Silica 1.0
import "game" as Game

ApplicationWindow {
    id: app

    allowedOrientations: Orientation.Portrait

    initialPage: Component {
        Page {
            id: page

            // false: the play field fills the screen.
            // true:  a square field as on a watch, centred.
            property bool squareStage: false

            allowedOrientations: Orientation.Portrait
            backNavigation: false
            showNavigationIndicator: false

            Rectangle {
                anchors.fill: parent
                color: "black"
            }

            Item {
                id: stage
                width: page.squareStage ? Math.min(page.width, page.height) : page.width
                height: page.squareStage ? width : page.height
                anchors.centerIn: parent
                clip: true

                Loader {
                    id: gameLoader
                    anchors.fill: parent
                    active: false
                    source: "game/main.qml"
                }
            }

            // The game reads its scale once at start, so the size has to
            // be known before it is loaded.
            onStatusChanged: {
                if (status === PageStatus.Active && !gameLoader.active) {
                    Game.Dims.width = stage.width
                    Game.Dims.height = stage.height
                    gameLoader.active = true
                }
            }
        }
    }

    cover: Component {
        CoverBackground {
            Label {
                anchors.centerIn: parent
                text: "Dodger"
            }
        }
    }
}
