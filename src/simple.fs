#version 460 core

in vec2 TexCoords;
uniform sampler2D uTex;

void main() {
  vec4 texcel = texture(uTex, TexCoords);
  gl_FragColor = vec4(1, 1, 1, texcel.x);
}
