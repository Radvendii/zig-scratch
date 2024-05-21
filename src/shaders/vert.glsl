#version 330 core
in vec3 aPos;
in vec3 aColor;

uniform vec2 offset;

out vec4 vertColor;
out vec3 vertPos;

void main() {
    gl_Position = vec4(aPos.xy + offset, aPos.z, 1.0);
    vertColor = vec4(aColor, 1.0);
    vertPos = aPos;
}
