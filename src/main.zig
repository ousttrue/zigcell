const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const Screen = @import("./screen.zig").Screen;

fn getProc(_: ?*glfw.GLFWwindow, name: [:0]const u8) ?*const anyopaque {
    return glfw.glfwGetProcAddress(@ptrCast([*:0]const u8, name));
}

pub fn main() anyerror!void {
    const allocator = std.testing.allocator;

    // Initialize the library
    if (glfw.glfwInit() == 0)
        return;
    defer glfw.glfwTerminate();

    // Create a windowed mode window and its OpenGL context
    const window = glfw.glfwCreateWindow(1280, 1024, "ZigCell", null, null) orelse {
        return;
    };

    // Make the window's context current
    glfw.glfwMakeContextCurrent(window);
    glfw.glfwSwapInterval(1);

    try gl.load(window, getProc);
    std.log.info("OpenGL Version:  {s}", .{std.mem.span(gl.getString(gl.VERSION))});
    std.log.info("OpenGL Vendor:   {s}", .{std.mem.span(gl.getString(gl.VENDOR))});
    std.log.info("OpenGL Renderer: {s}", .{std.mem.span(gl.getString(gl.RENDERER))});

    var screen = Screen.new(allocator, 30);
    defer screen.delete();

    if (std.os.argv.len > 1) {
        const arg1 = try std.fmt.allocPrint(allocator, "{s}", .{std.os.argv[1]});
        try screen.open(arg1);
    }

    try screen.loadFont("C:/Windows/Fonts/consola.ttf", 30, 1024);

    // Loop until the user closes the window
    while (glfw.glfwWindowShouldClose(window) == 0) {
        // Poll for and process events
        glfw.glfwPollEvents();

        var width: i32 = undefined;
        var height: i32 = undefined;
        glfw.glfwGetWindowSize(window, &width, &height);

        screen.render(@intCast(u32, width), @intCast(u32, height));

        // Swap front and back buffers
        glfw.glfwSwapBuffers(window);
    }
}
