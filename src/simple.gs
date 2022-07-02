#version 420 core
layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

layout(std140, binding = 0) uniform Global {
  mat4 projection;
  vec2 screenSize;
  vec2 cellSize;
  vec2 atlasSize;
}
global;

struct Glyph {
  vec4 xywh;
  vec4 offset;
};

layout(std140, binding = 1) uniform Glyphs { Glyph glyphs[128]; };

out vec2 TexCoords;

vec2 pixelToUv(float x, float y) {
  return vec2((x + 0.5) / global.atlasSize.x, (y + 0.5) / global.atlasSize.y);
}

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
  int glyphIndex = int(gl_in[0].gl_Position.z);
  vec4 glyph = glyphs[glyphIndex].xywh;
  float l = glyph.x;
  float t = glyph.y;
  float r = glyph.z;
  float b = glyph.w;

  // 0
  gl_Position = global.projection * vec4(topLeft, 0, 1);
  TexCoords = pixelToUv(l, t);
  EmitVertex();

  // 1
  gl_Position = global.projection * vec4(topLeft + vec2(0, cellSize.y), 0.0, 1);
  TexCoords = pixelToUv(l, b);
  EmitVertex();

  // 2
  gl_Position = global.projection * vec4(topLeft + vec2(cellSize.x, 0), 0.0, 1);
  TexCoords = pixelToUv(r, t);
  EmitVertex();

  // 3
  gl_Position = global.projection * vec4(topLeft + cellSize, 0.0, 1);
  TexCoords = pixelToUv(r, b);
  EmitVertex();

  EndPrimitive();
}
