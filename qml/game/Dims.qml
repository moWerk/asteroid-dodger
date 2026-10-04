pragma Singleton
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

// Stand-in for the Dims singleton of org.asteroid.controls.
// On AsteroidOS it scales by the screen. Here the app sets `width` and
// `height` to the size of the play field before the game is loaded.
QtObject {
    property real width: 720
    property real height: 720

    // percent of the shorter side
    function l(number) { return Math.min(width, height) * number / 100 }
    function w(number) { return width * number / 100 }
    function h(number) { return height * number / 100 }
}
