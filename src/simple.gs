#version 330 core
layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

// -1+1 +1+1
//   +----+
//   |   /|
//   |  / |
//   | /  |
//   |/   |
//   +----+
// -1-1 +1-1
void main() {
  gl_Position = gl_in[0].gl_Position + vec4(0.5, -0.5, 0.0, 0.0);
  EmitVertex();

  gl_Position = gl_in[0].gl_Position + vec4(0.5, 0.5, 0.0, 0.0);
  EmitVertex();

  gl_Position = gl_in[0].gl_Position + vec4(-0.5, -0.5, 0.0, 0.0);
  EmitVertex();

  gl_Position = gl_in[0].gl_Position + vec4(-0.5, 0.5, 0.0, 0.0);
  EmitVertex();

  EndPrimitive();
}
