const std = @import("std");
const gl = @import("gl");
const imgui = @import("imgui");
const dockspace = @import("./dockspace.zig");
const docks = @import("./docks.zig");

pub const ImGuiApp = struct {
    const Self = @This();

    docks: std.ArrayList(dockspace.Dock),
    metrics: docks.MetricsDock = .{},

    pub fn init(allocator: std.mem.Allocator, window: *anyopaque) Self {
        //
        // init imgui
        //
        _ = imgui.CreateContext(.{});
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
        const glsl_version = "#version 130";
        _ = imgui.ImGui_ImplOpenGL3_Init(.{ .glsl_version = glsl_version });

        var self = Self{
            .docks = std.ArrayList(dockspace.Dock).init(allocator),
        };

        self.docks.append(dockspace.Dock.create(&self.metrics, "metrics")) catch unreachable;

        return self;
    }

    pub fn deinit(self: *Self) void {
        imgui.ImGui_ImplOpenGL3_Shutdown();
        imgui.ImGui_ImplGlfw_Shutdown();
        self.docks.deinit();
        imgui.DestroyContext(.{});
    }

    pub fn frame(self: *Self) void {
        // Start the Dear imgui frame
        _ = imgui.ImGui_ImplOpenGL3_NewFrame();
        imgui.ImGui_ImplGlfw_NewFrame();
        imgui.NewFrame();

        _ = dockspace.dockspace("dockspace", 0);

        // menu
        if (imgui.BeginMainMenuBar()) {
            if (imgui.BeginMenu("File", .{ .enabled = true })) {
                imgui.EndMenu();
            }

            if (imgui.BeginMenu("Views", .{ .enabled = true })) {
                for (self.docks.items) |*dock| {
                    _ = imgui.MenuItem_2(dock.name, "", &dock.is_open, .{});
                }
                imgui.EndMenu();
            }

            imgui.EndMainMenuBar();
        }

        // views
        for (self.docks.items) |*dock| {
            dock.*.show();
        }

        imgui.Render();
        const size = imgui.GetIO().DisplaySize;
        gl.viewport(0, 0, @floatToInt(c_int, size.x), @floatToInt(c_int, size.y));

        // Render here
        // gl.clearColor(self.hello.clear_color.x * self.hello.clear_color.w, self.hello.clear_color.y * self.hello.clear_color.w, self.hello.clear_color.z * self.hello.clear_color.w, self.hello.clear_color.w);
        gl.clear(gl.COLOR_BUFFER_BIT);
        imgui.ImGui_ImplOpenGL3_RenderDrawData(imgui.GetDrawData());
    }
};
