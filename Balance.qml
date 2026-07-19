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

// ── Game Balance ─────────────────────────────────────────────────────────
// Single source of truth for all gameplay tuning, including the difficulty
// presets. The 6 non-readonly properties are written by apply(); all other
// properties are fixed and readonly. apply() only touches THIS object —
// root-side effects of a difficulty change (scroll speed reset, storage,
// powerup weight table rebuild) stay in main.qml's applyDifficulty().
QtObject {
    id: balance

    // Speed & Movement
    property real initialScrollSpeed: 1.6
    property real scrollSpeedPerLevel: 0.05
    readonly property real playerSensitivity: 1.2
    readonly property real speedBoostMultiplier: 2.0

    // Level Progression
    readonly property int  asteroidsPerLevel: 100
    property real initialAsteroidDensity: 0.20
    property real asteroidDensityPerLevel: 0.10
    readonly property int  initialSpawnCooldown: 200
    readonly property int  spawnCooldownPerLevel: 2
    readonly property int  minSpawnCooldown: 100

    // Power-up Global Density
    property real powerupDensityFactor: 0.001

    // Power-up Relative Weights
    readonly property real weightShield: 1.6
    property real weightInvincibility: 0.4
    readonly property real weightSpeedBoost: 0.8
    readonly property real weightScoreMultiplier: 0.8
    readonly property real weightSlowMo: 1.0
    readonly property real weightShrink: 1.0
    readonly property real weightLaserSwipe: 0.4
    readonly property real weightAutoFire: 0.8

    // Power-up Durations (milliseconds)
    readonly property int gracePeriodMs: 2000
    readonly property int invincibilityMs: 10000
    readonly property int speedBoostMs: 6000
    readonly property int scoreMultiplierMs: 10000
    readonly property int slowMoMs: 6000
    readonly property int shrinkMs: 6000
    readonly property int autoFireMs: 6000
    readonly property int autoFireShots: 30

    // Scoring
    readonly property real scoreMultiplierValue: 2.0
    readonly property int  comboWindowMs: 2000

    // Shield
    readonly property int initialShield: 2
    readonly property int maxShield: 10

    // ── Difficulty Presets ────────────────────────────────────────────────
    // Cadet = baseline. Each step raises scroll speed, asteroid density and
    // density-per-level linearly. Roadkill additionally has no invincibility
    // pickup (weightInvincibility: 0).
    readonly property var difficultyPresets: ({
        "Cadet Swerver": {
            initialScrollSpeed:      1.6,
            scrollSpeedPerLevel:     0.06,
            initialAsteroidDensity:  0.20,
            asteroidDensityPerLevel: 0.10,
            powerupDensityFactor:    0.002,
            weightInvincibility:     0.4
        },
        "Captain Slipstreamer": {
            initialScrollSpeed:      1.9,
            scrollSpeedPerLevel:     0.07,
            initialAsteroidDensity:  0.28,
            asteroidDensityPerLevel: 0.14,
            powerupDensityFactor:    0.0016,
            weightInvincibility:     0.4
        },
        "Commander Stardust": {
            initialScrollSpeed:      2.2,
            scrollSpeedPerLevel:     0.09,
            initialAsteroidDensity:  0.36,
            asteroidDensityPerLevel: 0.18,
            powerupDensityFactor:    0.0014,
            weightInvincibility:     0.25
        },
        "Major Roadkill": {
            initialScrollSpeed:      2.6,
            scrollSpeedPerLevel:     0.1,
            initialAsteroidDensity:  0.44,
            asteroidDensityPerLevel: 0.22,
            powerupDensityFactor:    0.0012,
            weightInvincibility:     0.0
        }
    })

    // Applies a preset to this object's tunables and returns the preset so
    // the caller can perform its own side effects. Unknown names fall back
    // to the baseline.
    function apply(name) {
        var preset = difficultyPresets[name]
        if (!preset) preset = difficultyPresets["Cadet Swerver"]
        initialScrollSpeed      = preset.initialScrollSpeed
        scrollSpeedPerLevel     = preset.scrollSpeedPerLevel
        initialAsteroidDensity  = preset.initialAsteroidDensity
        asteroidDensityPerLevel = preset.asteroidDensityPerLevel
        powerupDensityFactor    = preset.powerupDensityFactor
        weightInvincibility     = preset.weightInvincibility
        return preset
    }
}
