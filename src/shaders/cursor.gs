#version 420 core
layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

layout(std140, binding = 0) uniform Global {
  mat4 projection;
  vec2 screenSize;
  vec2 cellSize;
  vec2 atlasSize;
  float ascent;
  float descent;
}
global;

// -1+1 +1+1
//  0+----+2
//   |   /|
//   |  / |
//   | /  |
//   |/   |
//  1+----+3
// -1-1 +1-1
void main() {
  vec2 cellSize = global.cellSize;
  vec2 topLeft = gl_in[0].gl_Position.xy * cellSize;

  // 0
  gl_Position = global.projection * vec4(topLeft, 0, 1);
  EmitVertex();

  // 1
  gl_Position =
      global.projection * vec4(topLeft + vec2(0, global.cellSize.y), 0.0, 1);
  EmitVertex();

  // 2
  gl_Position =
      global.projection * vec4(topLeft + vec2(global.cellSize.x, 0), 0.0, 1);
  EmitVertex();

  // 3
  gl_Position =
      global.projection *
      vec4(topLeft + vec2(global.cellSize.x, global.cellSize.y), 0.0, 1);
  EmitVertex();

  EndPrimitive();
}
