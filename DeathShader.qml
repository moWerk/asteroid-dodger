/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import QtQuick 2.9

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
        
        vertexShader: "
        uniform   highp mat4 qt_Matrix;
        attribute highp vec4 qt_Vertex;
        attribute highp vec2 qt_MultiTexCoord0;
        varying   highp vec2 coord;
        void main() {
        coord       = qt_MultiTexCoord0;
        gl_Position = qt_Matrix * qt_Vertex;
    }
    "
    
    fragmentShader: "
    varying highp vec2  coord;
    uniform highp float animTime;
    uniform highp vec4  ringColor;
    uniform highp float qt_Opacity;
    
    void main() {
    highp vec2  uv   = coord - vec2(0.5);
    highp float dist = length(uv);
    highp vec3  col  = ringColor.rgb;
    
    highp float ring  = animTime * 0.48;
    highp float width = 0.06 + animTime * 0.04;
    highp float d     = abs(dist - ring);
    highp float ring_a = max(0.0, 1.0 - d / width);
    
    highp float glow = max(0.0, 0.3 - dist * 1.8) * (1.0 - animTime * 0.8);
    
    highp float alpha = (ring_a * 0.9 + glow) * qt_Opacity;
    gl_FragColor = vec4(col * (ring_a + glow * 2.0), alpha);
    }
    "
    }
}
