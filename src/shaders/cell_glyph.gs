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

struct Glyph {
  vec4 xywh;
  vec4 offset;
};

layout(std140, binding = 1) uniform Glyphs { Glyph glyphs[128]; };

in vData { vec3 color; }
vertices[];
out vec2 g_TexCoords;
out vec3 g_Color;

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
  vec2 topLeft = gl_in[0].gl_Position.xy * cellSize + vec2(0, global.ascent);
  int glyphIndex = int(gl_in[0].gl_Position.z);
  Glyph glyph = glyphs[glyphIndex];
  float l = glyph.xywh.x;
  float t = glyph.xywh.y;
  float r = glyph.xywh.z;
  float b = glyph.xywh.w;

  // 0
  gl_Position = global.projection * vec4(topLeft + glyph.offset.xy, 0, 1);
  g_TexCoords = pixelToUv(l, t);
  g_Color = vertices[0].color;
  EmitVertex();

  // 1
  gl_Position = global.projection *
                vec4(topLeft + glyph.offset.xy + vec2(0, b - t), 0.0, 1);
  g_TexCoords = pixelToUv(l, b);
  g_Color = vertices[0].color;
  EmitVertex();

  // 2
  gl_Position = global.projection *
                vec4(topLeft + glyph.offset.xy + vec2(r - l, 0), 0.0, 1);
  g_TexCoords = pixelToUv(r, t);
  g_Color = vertices[0].color;
  EmitVertex();

  // 3
  gl_Position = global.projection *
                vec4(topLeft + glyph.offset.xy + vec2(r - l, b - t), 0.0, 1);
  g_TexCoords = pixelToUv(r, b);
  g_Color = vertices[0].color;
  EmitVertex();

  EndPrimitive();
}
