#version 330 core
#extension GL_ARB_explicit_uniform_location : require
layout (location=0) in vec3 aPos;

layout (location=2) uniform ivec2 offset;
layout (location=3) uniform uvec2 wSize;

out vec4 vertColor;
out vec3 vertPos;

void main() {
    vec2 shifted = vec2(aPos.xy + offset);
    vec2 normalized = vec2(shifted.x / wSize.x * 2, shifted.y / wSize.y * 2);
    gl_Position = vec4(normalized, aPos.z, 1.0);
    vertColor = vec4(0.0, 0.0, 0.0, 1.0);
    vertPos = aPos;
}
