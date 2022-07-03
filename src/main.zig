const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const imgui = @import("imgui");
const imgui_app = @import("./imgui_app.zig");
const Screen = @import("./screen.zig").Screen;

fn getProc(_: ?*glfw.GLFWwindow, name: [:0]const u8) ?*const anyopaque {
    return glfw.glfwGetProcAddress(@ptrCast([*:0]const u8, name));
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

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

    var app = imgui_app.ImGuiApp.init(allocator, window);
    defer app.deinit();

    // scene
    // var screen = Screen.new(allocator, 30);
    // defer screen.delete();

    // if (std.os.argv.len > 1) {
    //     const arg1 = try std.fmt.allocPrint(allocator, "{s}", .{std.os.argv[1]});
    //     try screen.open(arg1);
    // }

    // try screen.loadFont("C:/Windows/Fonts/consola.ttf", 30, 1024);

    // Loop until the user closes the window
    const io = imgui.GetIO();
    while (glfw.glfwWindowShouldClose(window) == 0) {
        // Poll for and process events
        glfw.glfwPollEvents();

        app.frame();

        // Update and Render additional Platform Windows
        // (Platform functions may change the current OpenGL context, so we save/restore it to make it easier to paste this code elsewhere.
        //  For this specific demo app we could also call glfwMakeContextCurrent(window) directly)
        if ((io.ConfigFlags & @enumToInt(imgui.ImGuiConfigFlags._ViewportsEnable)) != 0) {
            const backup_current_context = glfw.glfwGetCurrentContext();
            imgui.UpdatePlatformWindows();
            imgui.RenderPlatformWindowsDefault(.{});
            glfw.glfwMakeContextCurrent(backup_current_context);
        }

        // Swap front and back buffers
        glfw.glfwSwapBuffers(window);
    }
}
