/*
 * Copyright (C) 2025 - Timo Könnecke <github.com/eLtMosen>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import QtSensors 5.15
import Nemo.Ngf 1.0
import QtQuick.Shapes 1.15
import org.asteroid.controls 1.0
import org.asteroid.dodger 1.0
import Nemo.KeepAlive 1.1

Item {
    id: root
    anchors.fill: parent
    visible: true

    // --- Game Mechanics ---
    property bool calibrating: false
    property int  calibrationTimer: 2
    property bool comboActive: false
    property int  comboCount: 0
    property bool debugMode: false
    property bool gameOver: false
    property bool invincible: false
    property bool isGraceActive: false
    property bool isInvincibleActive: false
    property bool isShrinkActive: false
    property bool isSlowMoActive: false
    property bool isSpeedBoostActive: false
    property real lastDodgeTime: 0
    property int  level: 1
    property bool paused: false
    property int  score: 0
    property real scoreMultiplier: 1.0
    property int  shield: balance.initialShield
    property bool showingNow: false
    property bool showingSurvive: false
    property bool isAutoFireActive: false

    // --- Difficulty & Persistence ---
    property string currentDifficulty: "Cadet Swerver"
    property bool   selectingDifficulty: true
    // true whenever we are on any pre-game screen (not yet in active play)
    readonly property bool inPreGame: selectingDifficulty || calibrating || showingNow || showingSurvive

    // --- Game Over Screen Model ---
    property var goModel: []

    // --- Object Spawning and Pools ---
    property var  activeLaser: null
    property var  activeParticles: []
    property var  activePowerups: []
    property var  activeShots: []
    property int  asteroidCount: 0
    property real asteroidDensity: balance.initialAsteroidDensity + (level - 1) * balance.asteroidDensityPerLevel
    property var  asteroidPool: []
    property int  asteroidPoolSize: 40
    property int  asteroidsPerLevel: balance.asteroidsPerLevel
    property real largeAsteroidDensity: asteroidDensity / 3
    property var  largeAsteroidPool: []
    property int  largeAsteroidPoolSize: 10
    property real lastAsteroidSpawn: 0
    property real lastLargeAsteroidSpawn: 0
    property real lastObjectSpawn: 0
    property int  spawnCooldown: Math.max(balance.minSpawnCooldown, balance.initialSpawnCooldown - (level - 1) * balance.spawnCooldownPerLevel)

    // --- Visual and Timing Settings ---
    property real   baselineX: 0
    property real   dimsFactor: Dims.l(100) / 100
    property real   goScale: 1.2
    property string flashColor: ""
    property real   lastFrameTime: 0
    property real   playerSpeed: balance.playerSensitivity
    property real   basePlayerSpeed: balance.playerSensitivity
    property real   preSlowSpeed: 0
    property real   savedScrollSpeed: 0
    property real   scrollSpeed: balance.initialScrollSpeed

    // Spawn config — built once at root level, rebuilt by applyDifficulty
    // when weightInvincibility changes between difficulties.
    property var powerupTypes: [
        { type: "shield",          weight: balance.weightShield },
        { type: "invincibility",   weight: balance.weightInvincibility },
        { type: "speedBoost",      weight: balance.weightSpeedBoost },
        { type: "scoreMultiplier", weight: balance.weightScoreMultiplier },
        { type: "slowMo",          weight: balance.weightSlowMo },
        { type: "shrink",          weight: balance.weightShrink },
        { type: "laserSwipe",      weight: balance.weightLaserSwipe },
        { type: "autoFire",        weight: balance.weightAutoFire },
    ]

    // ── Difficulty Presets ────────────────────────────────────────────────────
    // Cadet = current baseline. Each step raises scroll speed, asteroid density
    // and density-per-level linearly. Roadkill additionally has no invincibility
    // pickup (weightInvincibility: 0).
    property var difficultyPresets: ({
        "Cadet Swerver": {
            initialScrollSpeed:      1.6,
            scrollSpeedPerLevel:     0.05,
            initialAsteroidDensity:  0.20,
            asteroidDensityPerLevel: 0.10,
            powerupDensityFactor:    0.001,
            weightInvincibility:     0.4
        },
        "Captain Slipstreamer": {
            initialScrollSpeed:      1.9,
            scrollSpeedPerLevel:     0.07,
            initialAsteroidDensity:  0.28,
            asteroidDensityPerLevel: 0.14,
            powerupDensityFactor:    0.0008,
            weightInvincibility:     0.4
        },
        "Commander Stardust": {
            initialScrollSpeed:      2.2,
            scrollSpeedPerLevel:     0.09,
            initialAsteroidDensity:  0.36,
            asteroidDensityPerLevel: 0.18,
            powerupDensityFactor:    0.0006,
            weightInvincibility:     0.25
        },
        "Major Roadkill": {
            initialScrollSpeed:      2.5,
            scrollSpeedPerLevel:     0.11,
            initialAsteroidDensity:  0.44,
            asteroidDensityPerLevel: 0.22,
            powerupDensityFactor:    0.0005,
            weightInvincibility:     0.0
        }
    })

    // ── Game Balance ─────────────────────────────────────────────────────────
    // Single source of truth for all gameplay tuning.
    // The 6 non-readonly properties are written by applyDifficulty().
    // All other properties are fixed and readonly.
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
    }

    onPausedChanged: {
        if (paused) {
            savedScrollSpeed = scrollSpeed
            scrollSpeed = 0
            if (comboActive) {
                comboMeterAnimation.pause()
            }
            comboHitboxAnimation.pause()
        } else {
            scrollSpeed = savedScrollSpeed
            if (comboActive) {
                comboMeterAnimation.resume()
            }
            if (scoreMultiplierTimer.running) {
                comboHitboxAnimation.resume()
            }
        }
    }

    onGameOverChanged: {
        if (gameOver) {
            DodgerStorage.setHighScore(currentDifficulty, score)
            DodgerStorage.setHighLevel(currentDifficulty, level)
            clearPowerupBars()

            // Build sorted leaderboard for the game over screen
            var diffs = ["Cadet Swerver", "Captain Slipstreamer", "Commander Stardust", "Major Roadkill"]
            var entries = []
            for (var i = 0; i < diffs.length; i++) {
                entries.push({
                    name:  diffs[i],
                    score: DodgerStorage.highScore(diffs[i]),
                    level: DodgerStorage.highLevel(diffs[i])
                })
            }
            entries.sort(function(a, b) { return b.score - a.score })

            var model = []
            model.push({ rowType: "current", name: currentDifficulty, score: score, level: level })
            model.push({ rowType: "header" })
            for (var j = 0; j < entries.length; j++) {
                model.push({ rowType: "history", name: entries[j].name, score: entries[j].score, level: entries[j].level })
            }
            goModel = model
        }
    }

    NonGraphicalFeedback {
        id: feedback
        event: "press"
    }

    Binding {
        target: DisplayBlanking
        property: "preventBlanking"
        value: !gameOver
    }

    Component {
        id: progressBarComponent
        Item {
            id: progressBar
            property real   progress: 1.0
            property string fillColor: "#FFD700"
            property string bgColor: "#45220A"
            property int    duration: 0
            width: dimsFactor * 28
            height: dimsFactor * 2

            Rectangle {
                width: parent.width
                height: parent.height
                radius: dimsFactor * 1
                color: bgColor
            }

            Rectangle {
                id: fill
                width: parent.width * progress
                height: parent.height
                color: fillColor
                radius: dimsFactor * 1
            }

            Timer {
                id: progressTimer
                interval: 16
                repeat: true
                property real elapsed: 0
                onTriggered: {
                    elapsed += interval
                    progress = Math.max(0, 1 - elapsed / duration)
                    if (progress <= 0) {
                        progressBar.destroy()
                    }
                }
            }

            function startTimer() {
                progressTimer.elapsed = 0
                progressTimer.restart()
            }
        }
    }

    Timer {
        id: gameTimer
        interval: 16
        running: !gameOver && !inPreGame
        repeat: true
        property real lastFps: 60
        property var  fpsHistory: []
        property real lastFpsUpdate: 0
        property real lastGraphUpdate: 0
        property real smoothedX: 0
        property real smoothingFactor: 0.5

        onTriggered: {
            var currentTime = Date.now()
            var deltaTime = lastFrameTime > 0 ? (currentTime - lastFrameTime) / 1000 : 0.016
            if (deltaTime > 0.033) deltaTime = 0.033
            lastFrameTime = currentTime
            updateGame(deltaTime)

            if (!paused) {
                var rawX = accelerometer.reading.x
                smoothedX = smoothedX + smoothingFactor * (rawX - smoothedX)
                var deltaX = (smoothedX - baselineX) * -2
                var newX = playerContainer.x + deltaX * playerSpeed
                playerContainer.x = Math.max(player.width / 2, Math.min(root.width - player.width / 2, newX))
            }

            if (debugMode) {
                var currentFps = deltaTime > 0 ? 1 / deltaTime : 60
                lastFps = currentFps
                if (currentTime - lastFpsUpdate >= 500) {
                    lastFpsUpdate = currentTime
                    fpsDisplay.text = "FPS: " + Math.round(currentFps)
                }
                if (currentTime - lastGraphUpdate >= 500) {
                    lastGraphUpdate = currentTime
                    var tempHistory = fpsHistory.slice()
                    tempHistory.push(currentFps)
                    if (tempHistory.length > 10) tempHistory.shift()
                    fpsHistory = tempHistory
                }
            }
        }
    }

    Timer {
        id: graceTimer
        interval: balance.gracePeriodMs
        running: isGraceActive && !paused
        repeat: false
        onTriggered: {
            isGraceActive = false
            if (!isInvincibleActive) {
                invincible = false
            }
            removePowerup("grace")
        }
        onRunningChanged: {
            if (running && !paused) {
                addPowerupBar("grace", balance.gracePeriodMs, "#FF69B4", "#8B374F")
            }
        }
    }

    Timer {
        id: invincibilityTimer
        interval: balance.invincibilityMs
        running: isInvincibleActive && !paused
        repeat: false
        onTriggered: {
            isInvincibleActive = false
            if (!isGraceActive) {
                invincible = false
            }
            removePowerup("invincibility")
        }
    }

    Timer {
        id: speedBoostTimer
        interval: balance.speedBoostMs
        running: isSpeedBoostActive && !paused
        repeat: false
        onTriggered: {
            playerSpeed = balance.playerSensitivity
            isSpeedBoostActive = false
            removePowerup("speedBoost")
        }
        onRunningChanged: {
            if (running && !paused) {
                addPowerupBar("speedBoost", balance.speedBoostMs, "#FFFF00", "#8B8B00")
            }
        }
    }

    Timer {
        id: scoreMultiplierTimer
        interval: balance.scoreMultiplierMs
        running: scoreMultiplier > 1.0 && !paused
        repeat: false
        onTriggered: {
            scoreMultiplier = 1.0
            removePowerup("scoreMultiplier")
        }
        onRunningChanged: {
            if (running && !paused) {
                addPowerupBar("scoreMultiplier", balance.scoreMultiplierMs, "#00CC00", "#006600")
            }
        }
    }

    Timer {
        id: slowMoTimer
        interval: balance.slowMoMs
        running: isSlowMoActive && !paused
        repeat: false
        onTriggered: {
            scrollSpeed = preSlowSpeed
            savedScrollSpeed = preSlowSpeed
            isSlowMoActive = false
            removePowerup("slowMo")
        }
        onRunningChanged: {
            if (running && !paused) {
                addPowerupBar("slowMo", balance.slowMoMs, "#00FFFF", "#008B8B")
            }
        }
    }

    Timer {
        id: shrinkTimer
        interval: 100
        running: isShrinkActive && !paused
        repeat: true
        property real elapsed: 0
        onTriggered: {
            elapsed += interval
            var progress = Math.min(1.0, elapsed / balance.shrinkMs)
            player.width = dimsFactor * 5 + (dimsFactor * 10 - dimsFactor * 5) * progress
            player.height = dimsFactor * 5 + (dimsFactor * 10 - dimsFactor * 5) * progress
            playerHitbox.width = dimsFactor * 7 + (dimsFactor * 14 - dimsFactor * 7) * progress
            playerHitbox.height = dimsFactor * 7 + (dimsFactor * 14 - dimsFactor * 7) * progress
            if (elapsed >= balance.shrinkMs) {
                isShrinkActive = false
                elapsed = 0
                removePowerup("shrink")
                stop()
            }
        }
        onRunningChanged: {
            if (!running && !paused) {
                elapsed = 0
            }
            if (running && !paused) {
                addPowerupBar("shrink", balance.shrinkMs, "#FFA500", "#8B5A00")
            }
        }
    }

    Timer {
        id: calibrationCountdownTimer
        interval: 1000
        running: calibrating
        repeat: true
        property bool initializationDone: false
        onTriggered: {
            calibrationTimer--
            if (calibrationTimer <= 0 && initializationDone) {
                baselineX = accelerometer.reading.x
                calibrating = false
                showingNow = true
                feedback.play()
                nowTransition.start()
                introTimer.phase = 1
                introTimer.start()
            }
        }
    }

    Timer {
        id: introTimer
        interval: 1000
        running: showingNow || showingSurvive
        repeat: true
        property int phase: showingNow ? 1 : showingSurvive ? 2 : 0
        onTriggered: {
            if (phase === 1) {
                showingNow = false
                showingSurvive = true
                surviveTransition.start()
                phase = 2
            } else if (phase === 2) {
                showingSurvive = false
                phase = 0
                stop()
            }
        }
        onRunningChanged: {
            if (!running) {
                phase = 0
            }
        }
    }

    Timer {
        id: comboTimer
        interval: balance.comboWindowMs
        running: comboActive && !paused
        repeat: false
        onTriggered: {
            comboCount = 0
            comboActive = false
        }
    }

    Timer {
        id: autoFireTimer
        interval: balance.autoFireMs / balance.autoFireShots
        running: isAutoFireActive && !paused
        repeat: true
        property int shotCount: 0
        onTriggered: {
            if (shotCount < balance.autoFireShots) {
                var shot = autoFireShotComponent.createObject(gameArea, {
                    "x": playerContainer.x + playerHitbox.x + playerHitbox.width / 2 - dimsFactor * 0.5,
                    "y": playerContainer.y + playerHitbox.y
                })
                activeShots.push(shot)
                shotCount++
            }
            if (shotCount >= balance.autoFireShots) {
                isAutoFireActive = false
                shotCount = 0
                stop()
                removePowerup("autoFire")
            }
        }
        onRunningChanged: {
            if (running && !paused) {
                addPowerupBar("autoFire", balance.autoFireMs, "#800080", "#4B004B")
                shotCount = 0
            }
        }
    }

    Component {
        id: comboParticleComponent
        Text {
            id: particleText
            property int points: 1
            text: "+" + points
            color: {
                if (points <= 10) return "#00CC00"
                if (points <= 20) {
                    var t1 = (points - 10) / 10
                    var r = Math.round(0x00 + t1 * (0xFF - 0x00))
                    var g = Math.round(0xCC + t1 * (0xD7 - 0xCC))
                    var b = Math.round(0x00 + t1 * (0x00 - 0x00))
                    return Qt.rgba(r / 255, g / 255, b / 255, 1)
                }
                if (points <= 40) {
                    var t2 = (points - 20) / 20
                    var r = Math.round(0xFF + t2 * (0xFF - 0xFF))
                    var g = Math.round(0xD7 + t2 * (0x69 - 0xD7))
                    var b = Math.round(0x00 + t2 * (0xB4 - 0x00))
                    return Qt.rgba(r / 255, g / 255, b / 255, 1)
                }
                return "#FF69B4"
            }
            font.pixelSize: {
                if (points <= 10) return dimsFactor * 4
                if (points <= 20) {
                    var t1 = (points - 10) / 10
                    return (dimsFactor * 4 + t1 * (dimsFactor * 5 - dimsFactor * 4))
                }
                if (points <= 40) {
                    var t2 = (points - 20) / 20
                    return (dimsFactor * 5 + t2 * (dimsFactor * 6 - dimsFactor * 5))
                }
                if (points <= 100) {
                    var t3 = (points - 40) / 60
                    return (dimsFactor * 6 + t3 * (dimsFactor * 7 - dimsFactor * 6))
                }
                return dimsFactor * 7
            }
            z: 3
            opacity: 1

            SequentialAnimation {
                id: particleAnimation
                running: true
                ParallelAnimation {
                    NumberAnimation {
                        target: particleText
                        property: "x"
                        to: x + (x < playerContainer.x ? -dimsFactor * 8 : dimsFactor * 8)
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: particleText
                        property: "y"
                        to: y - dimsFactor * 7
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: particleText
                        property: "y"
                        to: y + dimsFactor * 11
                        duration: 600
                        easing.type: Easing.Linear
                    }
                    NumberAnimation {
                        target: particleText
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 600
                        easing.type: Easing.Linear
                    }
                }
                onStopped: {
                    var index = activeParticles.indexOf(particleText)
                    if (index !== -1) {
                        activeParticles.splice(index, 1)
                    }
                    particleText.destroy()
                }
            }
            Component.onCompleted: {
                activeParticles.push(particleText)
                if (activeParticles.length > 4) {
                    var oldestParticle = activeParticles.shift()
                    if (oldestParticle) {
                        oldestParticle.destroy()
                    }
                }
            }
        }
    }

    Component {
        id: laserSwipeComponent
        Rectangle {
            id: laserRect
            width: root.width
            height: dimsFactor * 1
            color: "red"
            x: 0
            y: playerContainer ? playerContainer.y : root.height * 0.75
            z: 2
            visible: true

            PropertyAnimation {
                id: laserAnimation
                target: laserRect
                property: "y"
                from: laserRect.y
                to: -laserRect.height
                duration: 1000
                running: true
                onStopped: {
                    if (root.activeLaser === laserRect) {
                        root.activeLaser = null
                    }
                    destroyTimer.start()
                }
            }

            Timer {
                id: destroyTimer
                interval: 1
                repeat: false
                onTriggered: {
                    parent.destroy()
                }
            }
        }
    }

    Component {
        id: autoFireShotComponent
        Rectangle {
            width: dimsFactor * 1
            height: dimsFactor * 5
            color: "#800080"
            z: 2
            visible: true
            property real speed: scrollSpeed * 5
        }
    }

    Item {
        id: gameArea
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: "black"
        }

        Rectangle {
            id: flashOverlay
            anchors.fill: parent
            color: flashColor ? flashColor : "transparent"
            opacity: 0
            visible: opacity > 0
            property string flashColor: ""

            function triggerFlash(color) {
                flashColor = color
                opacity = 0
                flashAnimation.stop()
                flashAnimation.start()
            }

            NumberAnimation {
                id: flashAnimation
                target: flashOverlay
                property: "opacity"
                from: 0.5
                to: 0
                duration: flashOverlay.flashColor === "#8B6914" || flashOverlay.flashColor === "#00FFFF" ? 6000 : 500
                easing.type: Easing.OutQuad
            }
        }

        Item {
            id: gameContent
            anchors.fill: parent

            Item {
                id: largeAsteroidContainer
                width: parent.width
                height: parent.height
                z: 0
                visible: !inPreGame
            }

            Item {
                id: objectContainer
                width: parent.width
                height: parent.height
                z: 0
                visible: !inPreGame
            }

            Item {
                id: playerContainer
                x: root.width / 2
                y: root.height * 0.75
                z: 1
                visible: !inPreGame

                Image {
                    id: player
                    width: dimsFactor * 10
                    height: dimsFactor * 10
                    source: "file:///usr/share/asteroid-launcher/watchfaces-img/asteroid-logo.svg"
                    anchors.centerIn: parent

                    SequentialAnimation on opacity {
                        running: (isGraceActive || isInvincibleActive) && !root.paused
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.2; duration: 500; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.2; to: 1.0; duration: 500; easing.type: Easing.InOutSine }
                        onStopped: {
                            player.opacity = 1.0
                        }
                    }
                    opacity: 1.0

                    SequentialAnimation on rotation {
                        running: speedBoostTimer.running && !root.paused
                        loops: Animation.Infinite
                        NumberAnimation { from: -5; to: 5; duration: 200; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 5; to: -5; duration: 200; easing.type: Easing.InOutSine }
                        onStopped: {
                            player.rotation = 0
                        }
                    }
                }

                Shape {
                    id: playerHitbox
                    width: dimsFactor * 14
                    height: dimsFactor * 14
                    anchors.centerIn: parent
                    visible: false

                    ShapePath {
                        strokeWidth: -1
                        fillColor: "transparent"
                        startX: dimsFactor * 7; startY: 0
                        PathLine { x: dimsFactor * 14; y: dimsFactor * 7 }
                        PathLine { x: dimsFactor * 7;  y: dimsFactor * 14 }
                        PathLine { x: 0;               y: dimsFactor * 7 }
                        PathLine { x: dimsFactor * 7;  y: 0 }
                    }
                }

                Shape {
                    id: comboHitbox
                    width: dimsFactor * 40
                    height: dimsFactor * 40
                    anchors.centerIn: parent
                    visible: comboActive
                    opacity: 0.2

                    ShapePath {
                        strokeWidth: dimsFactor * 1
                        strokeColor: "#00CC00"
                        fillColor: "transparent"
                        startX: dimsFactor * 20; startY: dimsFactor * 10
                        PathLine { x: dimsFactor * 30; y: dimsFactor * 20 }
                        PathLine { x: dimsFactor * 20; y: dimsFactor * 30 }
                        PathLine { x: dimsFactor * 10; y: dimsFactor * 20 }
                        PathLine { x: dimsFactor * 20; y: dimsFactor * 10 }
                    }

                    SequentialAnimation on opacity {
                        id: comboHitboxAnimation
                        running: scoreMultiplierTimer.running && !root.paused
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.2; to: 0.4; duration: 500; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.4; to: 0.2; duration: 500; easing.type: Easing.InOutSine }
                        onStopped: {
                            comboHitbox.opacity = 0.2
                        }
                    }
                }
            }

            Item {
                id: progressBarsContainer
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: dimsFactor * 6
                }
                z: 4
                visible: !gameOver && !inPreGame

                Item {
                    id: levelProgressBar
                    width: dimsFactor * 28
                    height: dimsFactor * 2
                    anchors.horizontalCenter: parent.horizontalCenter

                    Rectangle {
                        width: parent.width
                        height: parent.height
                        radius: dimsFactor * 1
                        color: "#45220A"
                    }

                    Rectangle {
                        id: progressFill
                        width: (asteroidCount / asteroidsPerLevel) * parent.width
                        height: parent.height
                        color: "#FFD700"
                        radius: dimsFactor * 1
                    }
                }

                Column {
                    id: powerupBars
                    anchors {
                        top: levelProgressBar.bottom
                        topMargin: dimsFactor * 1
                        horizontalCenter: parent.horizontalCenter
                    }
                    spacing: dimsFactor * 1
                }
            }

            Text {
                id: levelNumber
                text: level
                color: "#dddddd"
                font {
                    pixelSize: dimsFactor * 9
                    family: "Fyodor"
                }
                anchors {
                    top: root.top
                    horizontalCenter: parent.horizontalCenter
                }
                z: 4
                visible: !gameOver && !inPreGame
            }

            Item {
                id: shieldProgressBar
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: dimsFactor * 4
                }
                width: dimsFactor * 28
                height: dimsFactor * 2
                visible: !gameOver && !inPreGame
                z: 4

                Rectangle {
                    width: parent.width
                    height: parent.height
                    radius: dimsFactor * 1
                    color: "#002346"
                }

                Rectangle {
                    id: shieldFill
                    width: (shield / balance.maxShield) * parent.width
                    height: parent.height
                    color: "#0087FF"
                    radius: dimsFactor * 1
                }
            }

            Text {
                id: shieldText
                text: shield === 1 ? "❤️" : shield
                color: shield === 1 ? "red" : "#FFFFFF"
                font {
                    pixelSize: dimsFactor * 8
                    family: "Fyodor"
                }
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
                z: 4
                visible: !gameOver && !inPreGame
            }

            Item {
                id: scoreArea
                z: 2
                visible: !gameOver && !inPreGame
                x: playerContainer.x + playerContainer.width / 2 - scoreText.width / 2
                y: playerContainer.y + playerContainer.height + dimsFactor * 6

                Rectangle {
                    id: comboMeter
                    property int maxWidth: dimsFactor * 13
                    height: dimsFactor * 1
                    width: 0
                    color: "green"
                    radius: height / 2
                    x: (scoreText.width - width) / 2
                    y: -height + dimsFactor * 1
                    SequentialAnimation {
                        id: comboMeterAnimation
                        running: comboActive && !root.paused
                        NumberAnimation {
                            target: comboMeter
                            property: "width"
                            from: 0
                            to: comboMeter.maxWidth
                            duration: 50
                            easing.type: Easing.Linear
                        }
                        NumberAnimation {
                            target: comboMeter
                            property: "width"
                            from: comboMeter.maxWidth
                            to: 0
                            duration: balance.comboWindowMs - 50
                            easing.type: Easing.Linear
                        }
                        onStopped: {
                            comboMeter.width = 0
                        }
                    }
                }

                Text {
                    id: scoreText
                    text: score
                    color: scoreMultiplierTimer.running ? "#00CC00" : "#dddddd"
                    font {
                        pixelSize: dimsFactor * 5
                        bold: scoreMultiplierTimer.running
                    }
                }
            }

            // ── Pre-game screens (difficulty selection + calibration) ──────────

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
                            onClicked: {
                                applyDifficulty(difficultyCycler.currentValue)
                                calibrationTimer = 2
                                selectingDifficulty = false
                                calibrating = true
                            }
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

            // ── Pause & Debug ─────────────────────────────────────────────────
            
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: paused && !gameOver ? 0.65 : 0
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
            }
            
            Text {
                id: pauseText
                text: "Paused"
                color: "white"
                font {
                    pixelSize: dimsFactor * 22
                    family: "Fyodor"
                }
                anchors.centerIn: parent
                opacity: 0
                visible: !gameOver && !inPreGame
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !gameOver && !inPreGame
                    onClicked: {
                        paused = !paused
                        pauseText.opacity = paused ? 1.0 : 0.0
                    }
                }
            }

            Text {
                id: fpsDisplay
                text: "FPS: 60"
                color: "white"
                opacity: 0.5
                font.pixelSize: dimsFactor * 10
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: fpsGraph.top
                }
                visible: debugMode && !gameOver && !inPreGame
            }

            Rectangle {
                id: fpsGraph
                width: dimsFactor * 30
                height: dimsFactor * 10
                color: "#00000000"
                opacity: 0.5
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: debugToggle.top
                    topMargin: dimsFactor * 3
                }
                visible: debugMode && !gameOver && !inPreGame

                Row {
                    anchors.fill: parent
                    spacing: 0
                    Repeater {
                        model: 10
                        Rectangle {
                            width: fpsGraph.width / 10
                            height: {
                                var fps = index < gameTimer.fpsHistory.length ? gameTimer.fpsHistory[index] : 0
                                return Math.min(dimsFactor * 10, Math.max(0, (fps / 60) * dimsFactor * 10))
                            }
                            color: {
                                var fps = index < gameTimer.fpsHistory.length ? gameTimer.fpsHistory[index] : 0
                                if (fps > 60) return "green"
                                else if (fps >= 50) return "orange"
                                else return "red"
                            }
                        }
                    }
                }
            }

            Text {
                id: debugToggle
                text: "Debug"
                color: "white"
                opacity: debugMode ? 1 : 0.5
                font {
                    pixelSize: dimsFactor * 10
                    bold: debugMode
                }
                anchors {
                    bottom: pauseText.top
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: dimsFactor * 4
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                }
                visible: paused && !gameOver && !inPreGame
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        debugMode = !debugMode
                    }
                }
            }
        }

        // ── Game Over Screen ──────────────────────────────────────────────────
        // ListView declared first (lowest paint order) so "Game Over!" text
        // and "Die Again" button float above it without a z: hack.

        Item {
            id: gameOverScreen
            anchors.fill: parent
            z: 5
            visible: gameOver
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
                    leftMargin: dimsFactor * 15
                    rightMargin: dimsFactor * 15
                    topMargin: dimsFactor * 22
                    bottomMargin: dimsFactor * 28
                }
                model: goModel
                spacing: 0

                delegate: Item {
                    width: ListView.view ? ListView.view.width : 0
                    height: !modelData ? 0 :
                            modelData.rowType === "header" ? dimsFactor * 12 : dimsFactor * 24

                    // Current run row
                    Column {
                        visible: modelData && modelData.rowType === "current"
                        anchors.centerIn: parent
                        spacing: dimsFactor * 1

                        Text {
                            text: modelData ? modelData.name : ""
                            color: "#dddddd"
                            font { pixelSize: dimsFactor * 8; bold: true; family: "Fyodor" }
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: dimsFactor * 7
                            Text {
                                text: "Score  " + (modelData ? modelData.score : 0)
                                color: "white"
                                font.pixelSize: dimsFactor * 6
                                font.bold: true
                            }
                            Text {
                                text: "Level  " + (modelData ? modelData.level : 0)
                                color: "white"
                                font.pixelSize: dimsFactor * 6
                                font.bold: true
                            }
                        }
                    }

                    // Highscore header row
                    Text {
                        visible: modelData && modelData.rowType === "header"
                        text: "Highscore"
                        color: "#888888"
                        font { pixelSize: dimsFactor * 8; family: "Fyodor" }
                        anchors.centerIn: parent
                    }

                    // Historical difficulty row
                    Column {
                        visible: modelData && modelData.rowType === "history"
                        anchors.centerIn: parent
                        spacing: dimsFactor * 1
                        
                        Text {
                            text: modelData ? modelData.name : ""
                            color: "#cccccc"
                            font.pixelSize: dimsFactor * 6
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: dimsFactor * 7
                            Text {
                                text: "Score  " + (modelData ? modelData.score : 0)
                                color: "white"
                                font.pixelSize: dimsFactor * 6
                            }
                            Text {
                                text: "Level  " + (modelData ? modelData.level : 0)
                                color: "white"
                                font.pixelSize: dimsFactor * 6
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
                    pixelSize: Math.round(dimsFactor * 8 * goScale)
                    bold: true
                }
                anchors {
                    top: parent.top
                    topMargin: dimsFactor * 6
                    horizontalCenter: parent.horizontalCenter
                }
            }

            // "Die Again" button — declared last, MouseArea never covered
            Rectangle {
                id: tryAgainButton
                width: Math.round(dimsFactor * 42 * goScale)
                height: Math.round(dimsFactor * 14 * goScale)
                color: "green"
                border.color: "white"
                border.width: Math.round(dimsFactor * 1 * goScale)
                radius: Math.round(dimsFactor * 3 * goScale)
                anchors {
                    bottom: parent.bottom
                    bottomMargin: dimsFactor * 6
                    horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Die Again"
                    color: "white"
                    font {
                        pixelSize: Math.round(dimsFactor * 6 * goScale)
                        bold: true
                    }
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: gameOver
                    onClicked: {
                        restartGame()
                    }
                }
            }
        }

        Component {
            id: largeAsteroidComponent
            Rectangle {
                width: dimsFactor * (8 + Math.random() * 12)
                height: width
                x: Math.random() * (root.width - width)
                y: -height - (Math.random() * dimsFactor * 28)
                color: {
                    var t = Math.random()
                    var r = Math.round((0x0e + t * (0x2a - 0x0e)) * 0.42)
                    var g = Math.round((0x00 + t * (0x00 - 0x00)) * 0.42)
                    var b = Math.round((0x3d + t * (0x9b - 0x3d)) * 0.42)
                    return Qt.rgba(r / 255, g / 255, b / 255, 1)
                }
                radius: dimsFactor * 50
                visible: false
            }
        }

        Component {
            id: objectComponent
            Item {
                property string type: "asteroid"
                property bool passed: false
                property bool dodged: false
                width: type === "asteroid" ? dimsFactor * 3 : dimsFactor * 6
                height: type === "asteroid" ? dimsFactor * 3 : dimsFactor * 6
                x: Math.random() * (root.width - width)
                y: -height - (Math.random() * dimsFactor * 28)
                visible: false

                Shape {
                    id: asteroidShape
                    visible: type === "asteroid" && !dodged
                    property real sizeFactor: 0.8 + Math.random() * 0.4
                    width: dimsFactor * 3 * sizeFactor
                    height: dimsFactor * 3 * sizeFactor
                    anchors.centerIn: parent

                    ShapePath {
                        strokeWidth: -1
                        fillColor: {
                            var base = 230
                            var delta = Math.round(base * 0.22)
                            var rand = Math.round(base - delta + Math.random() * (2 * delta))
                            rand = Math.max(179, Math.min(255, rand))
                            var hex = rand.toString(16).padStart(2, '0')
                            return "#" + hex + hex + hex + "ff"
                        }
                        startX: asteroidShape.width * 0.5; startY: 0
                        PathLine { x: asteroidShape.width;       y: asteroidShape.height * 0.5 }
                        PathLine { x: asteroidShape.width * 0.5; y: asteroidShape.height }
                        PathLine { x: 0;                         y: asteroidShape.height * 0.5 }
                        PathLine { x: asteroidShape.width * 0.5; y: 0 }
                    }
                }

                Text {
                    id: scoreText
                    visible: type === "asteroid" && dodged
                    text: "+1"
                    color: "#00CC00"
                    font.pixelSize: dimsFactor * 4
                    anchors.centerIn: parent
                    Behavior on opacity {
                        NumberAnimation {
                            from: 1
                            to: 0
                            duration: 900
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Text {
                    visible: type !== "asteroid"
                    text: "!"
                    color: {
                        if (type === "invincibility")   return "#FF69B4"
                        if (type === "speedBoost")      return "#FFFF00"
                        if (type === "scoreMultiplier") return "#00CC00"
                        if (type === "shrink")          return "#FFA500"
                        if (type === "slowMo")          return "#00FFFF"
                        if (type === "laserSwipe")      return "red"
                        if (type === "autoFire")        return "#800080"
                        return "#0087ff"
                    }
                    font {
                        pixelSize: dimsFactor * 6
                        bold: true
                    }
                    anchors.centerIn: parent
                }
            }
        }

        Accelerometer {
            id: accelerometer
            active: gameTimer.running
        }
    }

    // ── Functions ─────────────────────────────────────────────────────────────

    function applyDifficulty(name) {
        var preset = difficultyPresets[name]
        if (!preset) preset = difficultyPresets["Cadet Swerver"]
        balance.initialScrollSpeed      = preset.initialScrollSpeed
        balance.scrollSpeedPerLevel     = preset.scrollSpeedPerLevel
        balance.initialAsteroidDensity  = preset.initialAsteroidDensity
        balance.asteroidDensityPerLevel = preset.asteroidDensityPerLevel
        balance.powerupDensityFactor    = preset.powerupDensityFactor
        balance.weightInvincibility     = preset.weightInvincibility
        scrollSpeed      = preset.initialScrollSpeed
        savedScrollSpeed = preset.initialScrollSpeed
        currentDifficulty = name
        DodgerStorage.difficulty = name
        // Rebuild powerupTypes so the new weightInvincibility value takes effect
        powerupTypes = [
            { type: "shield",          weight: balance.weightShield },
            { type: "invincibility",   weight: balance.weightInvincibility },
            { type: "speedBoost",      weight: balance.weightSpeedBoost },
            { type: "scoreMultiplier", weight: balance.weightScoreMultiplier },
            { type: "slowMo",          weight: balance.weightSlowMo },
            { type: "shrink",          weight: balance.weightShrink },
            { type: "laserSwipe",      weight: balance.weightLaserSwipe },
            { type: "autoFire",        weight: balance.weightAutoFire },
        ]
    }

    function addPowerupBar(type, duration, color, bgColor) {
        var existingIndex = activePowerups.findIndex(function(p) { return p.type === type })
        if (existingIndex !== -1) {
            var existing = activePowerups[existingIndex]
            if (existing.bar && existing.bar.parent) {
                existing.bar.progress = 1.0
                existing.bar.duration = duration
                existing.bar.fillColor = color
                existing.bar.bgColor = bgColor
                existing.bar.startTimer()
                return
            }
            activePowerups.splice(existingIndex, 1)
        }
        var bar = progressBarComponent.createObject(powerupBars, {
            "fillColor": color,
            "bgColor":   bgColor,
            "duration":  duration,
            "progress":  1.0
        })
        bar.startTimer()
        activePowerups.push({ type: type, bar: bar })
    }

    function removePowerup(type) {
        var index = activePowerups.findIndex(function(p) { return p.type === type })
        if (index !== -1) {
            var powerup = activePowerups[index]
            if (powerup.bar) {
                powerup.bar.destroy()
            }
            activePowerups.splice(index, 1)
        }
    }

    function clearPowerupBars() {
        for (var i = 0; i < activePowerups.length; i++) {
            if (activePowerups[i].bar) {
                activePowerups[i].bar.destroy()
            }
        }
        activePowerups = []
    }

    function updateGame(deltaTime) {
        if (!playerContainer || !playerHitbox || !gameArea) return

        var adjustedScrollSpeed = scrollSpeed * deltaTime * 60
        var largeAsteroidSpeed = adjustedScrollSpeed / 3
        var currentTime = Date.now()
        var effectiveSpawnCooldown = isSlowMoActive ? spawnCooldown * 2 : spawnCooldown
        var coarseRange = root.height

        var playerCenterX = playerContainer.x + playerHitbox.x + playerHitbox.width / 2
        var playerCenterY = playerContainer.y + playerHitbox.y + playerHitbox.height / 2
        var comboCenterX = playerContainer.x + comboHitbox.x + comboHitbox.width / 2
        var comboCenterY = playerContainer.y + comboHitbox.y + comboHitbox.height / 2
        var maxDistanceSquared = (playerHitbox.width + dimsFactor * 5) * (playerHitbox.width + dimsFactor * 5)
        var comboDetectionSize = dimsFactor * 12
        var comboDistanceSquared = (comboDetectionSize + dimsFactor * 5) * (comboDetectionSize + dimsFactor * 5)

        // Update shots
        for (var i = activeShots.length - 1; i >= 0; i--) {
            var shot = activeShots[i]
            if (shot) {
                shot.y -= shot.speed * deltaTime * 60
                if (shot.y <= -shot.height) {
                    shot.destroy()
                    activeShots.splice(i, 1)
                }
            }
        }

        // Move large asteroids (single pass)
        for (i = largeAsteroidPool.length - 1; i >= 0; i--) {
            var largeObj = largeAsteroidPool[i]
            if (largeObj.visible) {
                largeObj.y += largeAsteroidSpeed
                if (largeObj.y >= root.height) largeObj.visible = false
            }
        }

        // Move and check asteroids/power-ups (single pass)
        for (i = asteroidPool.length - 1; i >= 0; i--) {
            var obj = asteroidPool[i]
            if (!obj.visible) continue

            obj.y += adjustedScrollSpeed
            if (obj.y >= root.height) {
                obj.visible = false
                continue
            }
            if (obj.y + obj.height < -coarseRange || obj.y > root.height + coarseRange) continue

            var objCenterX = obj.x + obj.width / 2
            var objCenterY = obj.y + obj.height / 2
            var dx = objCenterX - playerCenterX
            var dy = objCenterY - playerCenterY
            var distanceSquared = dx * dx + dy * dy

            if (distanceSquared < maxDistanceSquared &&
                obj.x + obj.width >= playerContainer.x - dimsFactor * 5 &&
                obj.x <= playerContainer.x + playerHitbox.width + dimsFactor * 5 &&
                obj.y + obj.height >= playerContainer.y - dimsFactor * 5 &&
                obj.y <= playerContainer.y + playerHitbox.height + dimsFactor * 5) {
                if (obj.type === "asteroid" && isColliding(playerHitbox, obj) && !invincible) {
                    shield--
                    if (shield <= 0) {
                        gameOver = true
                        shield = 0
                        flashOverlay.triggerFlash("red")
                        comboCount = 0
                        comboActive = false
                        comboTimer.stop()
                        comboMeterAnimation.stop()
                        obj.visible = false
                        feedback.play()
                        continue
                    }
                    flashOverlay.triggerFlash("red")
                    comboCount = 0
                    comboActive = false
                    comboTimer.stop()
                    comboMeterAnimation.stop()
                    invincible = true
                    isGraceActive = true
                    graceTimer.restart()
                    obj.visible = false
                    feedback.play()
                    continue
                }
                if (obj.type === "shield" && isColliding(playerHitbox, obj)) {
                    shield = Math.min(balance.maxShield, shield + 1)
                    flashOverlay.triggerFlash("blue")
                    obj.visible = false
                    continue
                }
                if (obj.type === "invincibility" && isColliding(playerHitbox, obj)) {
                    invincible = true
                    isInvincibleActive = true
                    invincibilityTimer.restart()
                    flashOverlay.triggerFlash("#FF69B4")
                    addPowerupBar("invincibility", balance.invincibilityMs, "#FF69B4", "#8B374F")
                    obj.visible = false
                    continue
                }
                if (obj.type === "speedBoost" && isColliding(playerHitbox, obj)) {
                    playerSpeed = balance.playerSensitivity * balance.speedBoostMultiplier
                    isSpeedBoostActive = true
                    speedBoostTimer.restart()
                    flashOverlay.triggerFlash("#FFFF00")
                    addPowerupBar("speedBoost", balance.speedBoostMs, "#FFFF00", "#8B8B00")
                    obj.visible = false
                    continue
                }
                if (obj.type === "scoreMultiplier" && isColliding(playerHitbox, obj)) {
                    scoreMultiplier = balance.scoreMultiplierValue
                    scoreMultiplierTimer.restart()
                    flashOverlay.triggerFlash("#00CC00")
                    addPowerupBar("scoreMultiplier", balance.scoreMultiplierMs, "#00CC00", "#006600")
                    obj.visible = false
                    continue
                }
                if (obj.type === "shrink" && isColliding(playerHitbox, obj)) {
                    player.width = dimsFactor * 5
                    player.height = dimsFactor * 5
                    playerHitbox.width = dimsFactor * 7
                    playerHitbox.height = dimsFactor * 7
                    isShrinkActive = true
                    shrinkTimer.restart()
                    flashOverlay.triggerFlash("#FFA500")
                    addPowerupBar("shrink", balance.shrinkMs, "#FFA500", "#8B5A00")
                    obj.visible = false
                    continue
                }
                if (obj.type === "slowMo" && isColliding(playerHitbox, obj)) {
                    if (!isSlowMoActive) {
                        preSlowSpeed = scrollSpeed
                        scrollSpeed = preSlowSpeed / 2
                    }
                    savedScrollSpeed = scrollSpeed
                    isSlowMoActive = true
                    slowMoTimer.restart()
                    flashOverlay.triggerFlash("#00FFFF")
                    addPowerupBar("slowMo", balance.slowMoMs, "#00FFFF", "#008B8B")
                    obj.visible = false
                    continue
                }
                if (obj.type === "laserSwipe" && isColliding(playerHitbox, obj)) {
                    flashOverlay.triggerFlash("red")
                    if (!activeLaser) {
                        activeLaser = laserSwipeComponent.createObject(gameArea)
                    }
                    obj.visible = false
                    continue
                }
                if (obj.type === "autoFire" && isColliding(playerHitbox, obj)) {
                    flashOverlay.triggerFlash("#800080")
                    if (!isAutoFireActive) {
                        var shot = autoFireShotComponent.createObject(gameArea, {
                            "x": playerContainer.x + playerHitbox.x + playerHitbox.width / 2 - dimsFactor * 0.5,
                            "y": playerContainer.y + playerHitbox.y
                        })
                        activeShots.push(shot)
                        isAutoFireActive = true
                        autoFireTimer.start()
                    } else {
                        autoFireTimer.restart()
                    }
                    obj.visible = false
                    continue
                }
            }

            if (obj.type === "asteroid" && (obj.y + obj.height / 2) > playerCenterY && !obj.passed) {
                asteroidCount++
                obj.passed = true
                if (obj.x + obj.width >= playerContainer.x - comboDetectionSize / 2 - dimsFactor * 5 &&
                    obj.x <= playerContainer.x + comboDetectionSize / 2 + dimsFactor * 5 &&
                    obj.y + obj.height >= playerContainer.y - comboDetectionSize / 2 - dimsFactor * 5 &&
                    obj.y <= playerContainer.y + comboDetectionSize / 2 + dimsFactor * 5) {
                    var comboDx = objCenterX - comboCenterX
                    var comboDy = objCenterY - comboCenterY
                    var comboDistSquared = comboDx * comboDx + comboDy * comboDy
                    var isCombo = comboDistSquared < comboDistanceSquared && isColliding(comboHitbox, obj)
                    var basePoints = isCombo ? 2 : 1

                    if (isCombo) {
                        if (currentTime - lastDodgeTime <= balance.comboWindowMs) {
                            comboCount++
                        } else {
                            comboCount = 1
                        }
                        lastDodgeTime = currentTime
                        comboActive = true
                        comboTimer.restart()
                        comboMeterAnimation.restart()
                        score += basePoints * comboCount * scoreMultiplier
                        var particle = comboParticleComponent.createObject(gameArea, {
                            "x": obj.x,
                            "y": obj.y,
                            "points": basePoints * comboCount * scoreMultiplier
                        })
                    } else {
                        score += basePoints * scoreMultiplier
                        obj.dodged = true
                    }
                } else {
                    score += 1 * scoreMultiplier
                    obj.dodged = true
                }

                if (asteroidCount >= asteroidsPerLevel) {
                    levelUp()
                }
            }
        }

        // Check shot collisions with asteroids and power-ups
        for (var s = activeShots.length - 1; s >= 0; s--) {
            var shot = activeShots[s]
            if (!shot || !shot.visible) continue

            var buffer = dimsFactor * 2.5
            for (var j = asteroidPool.length - 1; j >= 0; j--) {
                var obj = asteroidPool[j]
                if (obj && obj.visible) {
                    if (shot.x - buffer < obj.x + obj.width &&
                        shot.x + shot.width + buffer > obj.x &&
                        shot.y < obj.y + obj.height &&
                        shot.y + shot.height > obj.y) {
                        if (obj.type === "asteroid") {
                            score += 100 * scoreMultiplier
                            var objX = obj.x
                            var objY = obj.y
                            obj.visible = false
                            var particle = comboParticleComponent.createObject(gameArea, {
                                "x": objX,
                                "y": objY,
                                "points": 100 * scoreMultiplier
                            })
                            activeParticles.push(particle)
                        } else {
                            obj.visible = false
                        }
                        shot.destroy()
                        activeShots.splice(s, 1)
                        break
                    }
                }
            }
        }

        // Laser swipe effect
        if (activeLaser && activeLaser.visible) {
            for (i = asteroidPool.length - 1; i >= 0; i--) {
                obj = asteroidPool[i]
                if (obj && obj.visible && obj !== activeLaser &&
                    obj.y <= activeLaser.y + activeLaser.height && obj.y + obj.height >= activeLaser.y &&
                    obj.x + obj.width >= 0 && obj.x <= root.width) {
                    if (obj.type === "asteroid") {
                        score += 10 * scoreMultiplier
                        objX = obj.x
                        objY = obj.y
                        obj.visible = false
                        particle = comboParticleComponent.createObject(gameArea, {
                            "x": objX,
                            "y": objY,
                            "points": 10 * scoreMultiplier
                        })
                    } else {
                        obj.visible = false
                    }
                }
            }
        }

        // Spawning logic
        var powerupBaseChance = asteroidDensity * balance.powerupDensityFactor
        if (!paused && currentTime - lastLargeAsteroidSpawn >= effectiveSpawnCooldown && Math.random() < largeAsteroidDensity / 3) {
            spawnLargeAsteroid()
            lastLargeAsteroidSpawn = currentTime
        }
        if (!paused && currentTime - lastAsteroidSpawn >= effectiveSpawnCooldown && Math.random() < asteroidDensity) {
            spawnObject("asteroid")
            lastAsteroidSpawn = currentTime
        }
        for (var p = 0; p < powerupTypes.length; p++) {
            if (!paused && currentTime - lastObjectSpawn >= effectiveSpawnCooldown && Math.random() < powerupBaseChance * powerupTypes[p].weight) {
                spawnObject(powerupTypes[p].type)
                lastObjectSpawn = currentTime
            }
        }
    }

    function spawnLargeAsteroid() {
        for (var i = 0; i < largeAsteroidPool.length; i++) {
            var obj = largeAsteroidPool[i]
            if (!obj.visible) {
                obj.x = Math.random() * (root.width - obj.width)
                obj.y = -obj.height - (Math.random() * dimsFactor * 28)
                obj.visible = true
                return
            }
        }
    }

    function spawnObject(type) {
        for (var i = 0; i < asteroidPool.length; i++) {
            var obj = asteroidPool[i]
            if (!obj.visible) {
                if (obj.type !== type) {
                    obj.type = type
                }
                obj.x = Math.random() * (root.width - obj.width)
                obj.y = -obj.height - (Math.random() * dimsFactor * 28)
                obj.visible = true
                if (obj.passed) obj.passed = false
                if (obj.dodged) obj.dodged = false
                return
            }
        }
    }

    function isColliding(hitbox, obj) {
        var hitboxCenterX = hitbox.x + playerContainer.x + hitbox.width / 2
        var hitboxCenterY = hitbox.y + playerContainer.y + hitbox.height / 2
        var halfWidth = hitbox.width / 2
        var halfHeight = hitbox.height / 2

        var objCenterX = obj.x + obj.width / 2
        var objCenterY = obj.y + obj.height / 2

        var dx = Math.abs(objCenterX - hitboxCenterX)
        var dy = Math.abs(objCenterY - hitboxCenterY)

        return (dx / halfWidth + dy / halfHeight) <= 1
    }

    function levelUp() {
        asteroidCount = 0
        level++
        scrollSpeed += balance.scrollSpeedPerLevel
        savedScrollSpeed = scrollSpeed
        flashOverlay.triggerFlash("#8B6914")
    }

    function restartGame() {
        score = 0
        shield = balance.initialShield
        level = 1
        asteroidCount = 0
        scrollSpeed = balance.initialScrollSpeed
        savedScrollSpeed = scrollSpeed
        // asteroidDensity is a binding on level — resetting level above is sufficient
        gameOver = false
        paused = false
        invincible = false
        playerSpeed = basePlayerSpeed
        calibrating = false
        showingNow = false
        showingSurvive = false
        comboCount = 0
        comboActive = false
        lastDodgeTime = 0
        scoreMultiplier = 1.0
        preSlowSpeed = 0
        isSlowMoActive = false
        isSpeedBoostActive = false
        isShrinkActive = false
        isAutoFireActive = false
        player.width = dimsFactor * 10
        player.height = dimsFactor * 10
        playerHitbox.width = dimsFactor * 14
        playerHitbox.height = dimsFactor * 14
        clearPowerupBars()
        nowTransition.stop()
        nowText.font.pixelSize = dimsFactor * 13
        nowText.opacity = 0
        surviveTransition.stop()
        surviveText.font.pixelSize = dimsFactor * 13
        surviveText.opacity = 0
        playerContainer.x = root.width / 2 - player.width / 2
        gameOverScreen.opacity = 0
        lastFrameTime = 0
        flashOverlay.opacity = 0
        flashOverlay.flashColor = ""
        flashAnimation.stop()

        autoFireTimer.stop()
        autoFireTimer.shotCount = 0

        // Clear active shots
        for (var i = 0; i < activeShots.length; i++) {
            if (activeShots[i]) {
                activeShots[i].destroy()
            }
        }
        activeShots = []

        // Clear active laser
        if (activeLaser) {
            activeLaser.destroy()
            activeLaser = null
        }

        // Clear asteroid pool and move off-screen
        for (i = 0; i < asteroidPool.length; i++) {
            asteroidPool[i].visible = false
            asteroidPool[i].y = -asteroidPool[i].height - dimsFactor * 28
            asteroidPool[i].x = Math.random() * (root.width - asteroidPool[i].width)
            asteroidPool[i].passed = false
            asteroidPool[i].dodged = false
        }

        // Clear large asteroid pool and move off-screen
        for (i = 0; i < largeAsteroidPool.length; i++) {
            largeAsteroidPool[i].visible = false
            largeAsteroidPool[i].y = -largeAsteroidPool[i].height - dimsFactor * 28
            largeAsteroidPool[i].x = Math.random() * (root.width - largeAsteroidPool[i].width)
        }

        initialSpawnTimer.interval = 50
        initialSpawnTimer.count = 0
        initialSpawnTimer.start()
    }

    Timer {
        id: asteroidPoolTimer
        interval: 10
        repeat: true
        property int index: 0
        onTriggered: {
            if (index < asteroidPoolSize) {
                var obj = objectComponent.createObject(objectContainer)
                obj.visible = false
                obj.y = -obj.height
                asteroidPool.push(obj)
                index++
            } else {
                stop()
                index = 0
                initializeLargeAsteroids()
            }
        }
    }

    Timer {
        id: largeAsteroidPoolTimer
        interval: 10
        repeat: true
        property int index: 0
        onTriggered: {
            if (index < largeAsteroidPoolSize) {
                var largeObj = largeAsteroidComponent.createObject(largeAsteroidContainer)
                largeObj.visible = false
                largeObj.y = -largeObj.height
                largeAsteroidPool.push(largeObj)
                index++
            } else {
                stop()
                index = 0
                finishInitialization()
            }
        }
    }

    Timer {
        id: initialSpawnTimer
        repeat: true
        property int count: 0
        onTriggered: {
            if (count < 3) {
                spawnObject("asteroid")
            }
            if (count < 2) {
                spawnLargeAsteroid()
            }
            count++
            if (count >= 3) {
                stop()
                count = 0
            }
        }
    }

    function initializeGame() {
        asteroidPoolTimer.index = 0
        asteroidPoolTimer.start()
    }

    function initializeLargeAsteroids() {
        largeAsteroidPoolTimer.index = 0
        largeAsteroidPoolTimer.start()
    }

    function finishInitialization() {
        calibrationCountdownTimer.initializationDone = true

        // Preload a combo particle
        var preloadParticle = comboParticleComponent.createObject(gameArea, {
            "x": -dimsFactor * 10,
            "y": -dimsFactor * 10,
            "points": 1
        })
        preloadParticle.destroy(100)

        // Preload a power-up bar
        addPowerupBar("preload", 100, "#FF69B4", "#8B374F")
        removePowerup("preload")

        initialSpawnTimer.interval = 200
        initialSpawnTimer.count = 0
        initialSpawnTimer.start()
    }

    // Apply stored difficulty preset and begin async pool initialisation.
    // selectingDifficulty remains true until the user taps "Die Now".
    Component.onCompleted: {
        applyDifficulty(DodgerStorage.difficulty)
        selectingDifficulty = true
        initializeGame()
    }
}
