const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

fn getProc(_: ?*glfw.GLFWwindow, name: [:0]const u8) ?*const anyopaque {
    return glfw.glfwGetProcAddress(@ptrCast([*:0]const u8, name));
}

pub fn main() anyerror!void {
    // Initialize the library
    if (glfw.glfwInit() == 0)
        return;
    defer glfw.glfwTerminate();

    // Create a windowed mode window and its OpenGL context
    const window = glfw.glfwCreateWindow(640, 480, "Hello World", null, null) orelse {
        return;
    };

    // Make the window's context current
    glfw.glfwMakeContextCurrent(window);

    try gl.load(window, getProc);
    std.log.info("OpenGL Version:  {s}", .{std.mem.span(gl.getString(gl.VERSION))});
    std.log.info("OpenGL Vendor:   {s}", .{std.mem.span(gl.getString(gl.VENDOR))});
    std.log.info("OpenGL Renderer: {s}", .{std.mem.span(gl.getString(gl.RENDERER))});

    // Loop until the user closes the window
    gl.clearColor(0.3, 0.6, 0.3, 1.0);
    while (glfw.glfwWindowShouldClose(window) == 0) {
        // Render here
        gl.clear(gl.COLOR_BUFFER_BIT);

        // Swap front and back buffers
        glfw.glfwSwapBuffers(window);

        // Poll for and process events
        glfw.glfwPollEvents();
    }
}
