#version 110
in vec2 TexCoords;

void main() { gl_FragColor = vec4(TexCoords, 0, 1.0); }
