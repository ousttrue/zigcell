#version 460 core

in vec2 TexCoords;
layout(location = 0) out vec4 FragColor;
uniform sampler2D uTex;

void main() {
  vec4 texcel = texture(uTex, TexCoords);
  FragColor = vec4(1, 1, 1, texcel.x);
  // FragColor = vec4(TexCoords, 0, 1);
}
