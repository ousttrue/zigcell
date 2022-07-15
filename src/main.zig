const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const imgui = @import("imgui");
const imutil = @import("imutil");
const Screen = @import("./screen.zig").Screen;
const CursorDock = @import("./CursorDock.zig");
const AstTreeDock = @import("./AstTreeDock.zig");
const JsonRpc = @import("./JsonRpc.zig");
const Stdio = @import("./Stdio.zig");
const Transport = @import("./Transport.zig");
const LspDock = @import("./LspDock.zig");

fn getProc(_: ?*glfw.GLFWwindow, name: [:0]const u8) ?*const anyopaque {
    return glfw.glfwGetProcAddress(@ptrCast([*:0]const u8, name));
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // defer _ = gpa.detectLeaks();
    defer std.debug.assert(!gpa.deinit());

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
    // std.log.info("OpenGL Version:  {s}", .{std.mem.span(gl.getString(gl.VERSION))});
    // std.log.info("OpenGL Vendor:   {s}", .{std.mem.span(gl.getString(gl.VENDOR))});
    // std.log.info("OpenGL Renderer: {s}", .{std.mem.span(gl.getString(gl.RENDERER))});

    var app = imutil.ImGuiApp.init(allocator, window);
    defer app.deinit();

    const font_size = 30;
    var screen = Screen.new(allocator, font_size);
    defer screen.delete();

    // fbo dock
    var fbo_dock = imutil.FboDock.new(allocator, screen);
    defer fbo_dock.delete();
    try app.docks.append(imutil.Dock.create(fbo_dock, "fbo"));

    // cursor dock
    var cursor_dock = CursorDock.new(allocator, screen.layout);
    defer cursor_dock.delete();
    try app.docks.append(imutil.Dock.create(cursor_dock, "cursor"));

    // ast tree dock
    var ast_tree_dock = AstTreeDock.new(allocator, screen);
    defer ast_tree_dock.delete();
    try app.docks.append(imutil.Dock.create(ast_tree_dock, "ast tree"));

    if (std.os.argv.len > 1) {
        const arg1 = try std.fmt.allocPrint(allocator, "{s}", .{std.os.argv[1]});
        defer allocator.free(arg1);
        try screen.open(arg1);
    }

    try screen.loadFont("C:/Windows/Fonts/consola.ttf", 30, 1024);

    var stdio = Stdio.init();

    var transport = Transport{
        .ptr = &stdio,
        .readLineFn = imutil.TypeEraser(Stdio, "readLine").call,
    };

    var jsonrpc: *JsonRpc = try JsonRpc.new(
        gpa.allocator(),
        &transport,
    );
    defer jsonrpc.delete();

    // lsp dock
    var lsp_dock = LspDock.new(allocator, jsonrpc);
    defer lsp_dock.delete();
    try app.docks.append(imutil.Dock.create(lsp_dock, "lsp"));

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
