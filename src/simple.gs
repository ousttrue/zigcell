#version 330 core
layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

layout (std140) uniform Font {
  mat4 projection;
  vec2 screenSize;
  vec2 cellSize;
} font;

out vec2 TexCoords;

// -1+1 +1+1
//  0+----+2
//   |   /|
//   |  / |
//   | /  |
//   |/   |
//  1+----+3
// -1-1 +1-1
void main() {
  vec2 cellSize = font.cellSize;
  vec2 topLeft = gl_in[0].gl_Position.xy * cellSize;

  // 0
  gl_Position = font.projection * vec4(topLeft, 0, 1);
  TexCoords = vec2(0, 0);
  EmitVertex();

  // 1
  gl_Position = font.projection * vec4(topLeft + vec2(0, cellSize.y), 0.0, 1);
  TexCoords = vec2(0, 1);
  EmitVertex();

  // 2
  gl_Position = font.projection * vec4(topLeft + vec2(cellSize.x, 0), 0.0, 1);
  TexCoords = vec2(1, 0);
  EmitVertex();

  // 3
  gl_Position = font.projection * vec4(topLeft + cellSize, 0.0, 1);
  TexCoords = vec2(1, 1);
  EmitVertex();

  EndPrimitive();
}
