/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import QtQuick

// Self-contained expanding ring + glow shader for player death.
// Drive deathProgress 0.0 → 1.0 externally. Size the Item to the
// desired blast radius — ShaderEffect fills it.
// ringColor controls the ring and glow tint.
Item {
    id: root
    
    property real  deathProgress: 0.0
    property color ringColor: "#FF4400"
    
    ShaderEffect {
        anchors.fill: parent
        visible: root.deathProgress > 0.0
        opacity: Math.max(0, 0.85 - root.deathProgress * 1.1)
        
        property real  animTime:  root.deathProgress
        // color uniform maps to vec4 in GLSL — use .rgb in shader
        property color ringColor: root.ringColor
        
        // Qt6: pre-compiled qsb, source in shaders/death.frag. The old
        // custom vertex shader was a plain passthrough — the default
        // vertex shader provides the same qt_TexCoord0.
        fragmentShader: "shaders/death.frag.qsb"
    }
}
