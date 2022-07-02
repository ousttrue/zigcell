const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const imgui = @import("imgui");
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

    //
    // init imgui
    //
    _ = imgui.CreateContext(.{});
    defer imgui.DestroyContext(.{});
    const io = imgui.GetIO();
    io.ConfigFlags |= @enumToInt(imgui.ImGuiConfigFlags._NavEnableKeyboard); // Enable Keyboard Controls
    //io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls
    io.ConfigFlags |= @enumToInt(imgui.ImGuiConfigFlags._DockingEnable); // Enable Docking
    io.ConfigFlags |= @enumToInt(imgui.ImGuiConfigFlags._ViewportsEnable); // Enable Multi-Viewport / Platform Windows
    //io.ConfigViewportsNoAutoMerge = true;
    //io.ConfigViewportsNoTaskBarIcon = true;
    // Setup Dear ImGui style
    imgui.StyleColorsDark(.{});
    // When viewports are enabled we tweak WindowRounding/WindowBg so platform windows can look identical to regular ones.
    var style = imgui.GetStyle();
    if ((io.ConfigFlags & @enumToInt(imgui.ImGuiConfigFlags._ViewportsEnable)) != 0) {
        style.WindowRounding = 0.0;
        style.Colors[@enumToInt(imgui.ImGuiCol._WindowBg)].w = 1.0;
    }

    //
    // Setup Platform/Renderer backends
    //
    _ = imgui.ImGui_ImplGlfw_InitForOpenGL(@ptrCast(*imgui.GLFWwindow, window), true);
    defer imgui.ImGui_ImplGlfw_Shutdown();
    const glsl_version = "#version 130";
    _ = imgui.ImGui_ImplOpenGL3_Init(.{ .glsl_version = glsl_version });
    defer imgui.ImGui_ImplOpenGL3_Shutdown();

    // scene
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

        // Start the Dear imgui frame
        _ = imgui.ImGui_ImplOpenGL3_NewFrame();
        imgui.ImGui_ImplGlfw_NewFrame();
        imgui.NewFrame();

        var width: i32 = undefined;
        var height: i32 = undefined;
        glfw.glfwGetWindowSize(window, &width, &height);

        imgui.ShowDemoWindow(.{});
        // screen.render(@intCast(u32, width), @intCast(u32, height));

        imgui.Render();
        gl.viewport(0, 0, width, height);

        // Render here
        // gl.clearColor(self.hello.clear_color.x * self.hello.clear_color.w, self.hello.clear_color.y * self.hello.clear_color.w, self.hello.clear_color.z * self.hello.clear_color.w, self.hello.clear_color.w);
        gl.clear(gl.COLOR_BUFFER_BIT);
        imgui.ImGui_ImplOpenGL3_RenderDrawData(imgui.GetDrawData());

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
