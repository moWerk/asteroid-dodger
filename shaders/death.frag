#version 440

// Expanding ring + glow for player death (Qt6 RHI dialect).
// Source for death.frag.qsb — recompile with:
// qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o death.frag.qsb death.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float animTime;
    vec4 ringColor;
} ubuf;

void main() {
    vec2 uv = qt_TexCoord0 - vec2(0.5);
    float dist = length(uv);
    vec3 col = ubuf.ringColor.rgb;

    float ring = ubuf.animTime * 0.48;
    float width = 0.06 + ubuf.animTime * 0.04;
    float d = abs(dist - ring);
    float ring_a = max(0.0, 1.0 - d / width);

    float glow = max(0.0, 0.3 - dist * 1.8) * (1.0 - ubuf.animTime * 0.8);

    float alpha = (ring_a * 0.9 + glow) * ubuf.qt_Opacity;
    fragColor = vec4(col * (ring_a + glow * 2.0), alpha);
}
