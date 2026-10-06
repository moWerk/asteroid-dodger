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

pragma Singleton
import QtQuick 2.6
import Nemo.Configuration 1.0

// SailfishOS: replaces the C++ DodgerStorage (QSettings, game.ini) so the
// app is pure QML and one noarch package. Same API; the values live in
// dconf under /apps/harbour-asteroid-dodger. Records are never lowered.
QtObject {
    id: store

    property QtObject _cfg: ConfigurationGroup { path: "/apps/harbour-asteroid-dodger" }
    property bool _ready: false

    property string difficulty: "Cadet Swerver"
    onDifficultyChanged: if (_ready) _cfg.setValue("difficulty", difficulty)

    // "Cadet Swerver" + "highScore" -> "cadet_swerver/highScore"
    function _key(diff, field) { return diff.toLowerCase().replace(/ /g, "_") + "/" + field }

    function highScore(diff) { return Number(_cfg.value(_key(diff, "highScore"), 0)) }
    function setHighScore(diff, v) {
        if (v > highScore(diff)) _cfg.setValue(_key(diff, "highScore"), v)
    }
    function highLevel(diff) { return Number(_cfg.value(_key(diff, "highLevel"), 1)) }
    function setHighLevel(diff, v) {
        if (v > highLevel(diff)) _cfg.setValue(_key(diff, "highLevel"), v)
    }

    Component.onCompleted: {
        difficulty = _cfg.value("difficulty", "Cadet Swerver")
        _ready = true
    }
}
