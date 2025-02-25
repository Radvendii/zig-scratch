#version 330 core
in vec3 aPos;
in vec3 aColor;

uniform vec2 offset;
uniform uvec2 wSize;

out vec4 vertColor;
out vec3 vertPos;

void main() {
    vec2 shifted = vec2(aPos.xy + offset);
    vec2 normalized = vec2(shifted.x / wSize.x, shifted.y / wSize.y);
    gl_Position = vec4(normalized, aPos.z, 1.0);
    vertColor = vec4(aColor, 1.0);
    vertPos = aPos;
}
