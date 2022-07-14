#version 420
in vec3 i_Pos;
in vec3 i_Color;
// out vec3 v_Color;
out vData { vec3 color; }
vertex;
void main() {
  gl_Position = vec4(i_Pos, 1);
  vertex.color = i_Color;
}
