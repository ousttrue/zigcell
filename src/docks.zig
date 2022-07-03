const std = @import("std");
const imgui = @import("imgui");
const imnodes = @import("imnodes");

pub const DemoDock = struct {
    const Self = @This();

    dummy: i32=0,

    pub fn show(_: *Self, p_open: *bool) void {
        if (!p_open.*) {
            return;
        }
        imgui.ShowDemoWindow(.{ .p_open = p_open });
    }
};

pub const MetricsDock = struct {
    const Self = @This();

    dummy: i32=0,

    pub fn show(_: *Self, p_open: *bool) void {
        if (!p_open.*) {
            return;
        }
        imgui.ShowMetricsWindow(.{ .p_open = p_open });
    }
};

pub const HelloDock = struct {
    const Self = @This();

    show_demo_window: *bool,
    show_another_window: *bool,
    clear_color: imgui.ImVec4 = .{ .x = 0.45, .y = 0.55, .z = 0.60, .w = 1.00 },
    f: f32 = 0.0,
    counter: i32 = 0,

    pub fn show(self: *Self, p_open: *bool) void {
        if (!p_open.*) {
            return;
        }

        // 2. Show a simple window that we create ourselves. We use a Begin/End pair to created a named window.
        if (imgui.Begin("Hello, world!", .{ .p_open = p_open })) { // Create a window called "Hello, world!" and append into it.
            imgui.Text("This is some useful text.", .{}); // Display some text (you can use a format strings too)

            _ = imgui.Checkbox("Demo Window", self.show_demo_window); // Edit bools storing our window open/close state
            _ = imgui.Checkbox("Another Window", self.show_another_window);

            _ = imgui.SliderFloat("float", &self.f, 0.0, 1.0, .{}); // Edit 1 float using a slider from 0.0f to 1.0f
            _ = imgui.ColorEdit3("clear color", &self.clear_color.x, .{}); // Edit 3 floats representing a color

            if (imgui.Button("Button", .{})) // Buttons return true when clicked (most widgets return true when edited/activated)
                self.counter += 1;
            imgui.SameLine(.{});
            imgui.Text("counter = %d", .{self.counter});
            imgui.Text("Application average %.3f ms/frame (%.1f FPS)", .{ 1000.0 / imgui.GetIO().Framerate, imgui.GetIO().Framerate });
        }
        imgui.End();
    }
};

pub const AnotherDock = struct {
    const Self = @This();

    dummy: i32=0,

    pub fn show(_: *Self, p_open: *bool) void {
        if (!p_open.*) {
            return;
        }
        // 3. Show another simple window.
        if (imgui.Begin("Another Window", .{ .p_open = p_open })) { // Pass a pointer to our bool variable (the window will have a closing button that will clear the bool when clicked)
            imgui.Text("Hello from another window!", .{});
            if (imgui.Button("Close Me", .{})) {
                p_open.* = false;
            }
        }
        imgui.End();
    }
};

pub const NodeEditorDock = struct {
    const Self = @This();

    context: ?*imnodes.ImNodesContext = null,

    pub fn show(self: *Self, p_open: *bool) void {
        if (!p_open.*) {
            return;
        }
        if (imgui.Begin("ImNodes", .{ .p_open = p_open })) {
            if (self.context == null) {
                self.context = imnodes.CreateContext();
            }

            imnodes.BeginNodeEditor();
            imnodes.EndNodeEditor();
        }
        imgui.End();
    }
};
