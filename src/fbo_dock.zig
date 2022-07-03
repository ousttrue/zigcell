const std = @import("std");
const glo = @import("glo");
const imgui = @import("imgui");
const TypeEraser = @import("./type_eraser.zig").TypeEraser;

const FLT_MAX: f32 = 3.402823466e+38;

const FboRenderer = struct {
    const Self = @This();

    ptr: *anyopaque,
    callback: fn (ptr: *anyopaque, width: u32, height: u32) void,

    pub fn render(self: *Self, width: u32, height: u32) void {
        self.callback(self.ptr, width, height);
    }

    pub fn create(p: anytype) Self {
        const T = @TypeOf(p.*);
        return .{
            .ptr = p,
            .callback = TypeEraser(T, "render").call,
        };
    }
};

pub const FboDock = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    fbo: glo.FboManager,
    clear_color: [4]f32 = .{ 0, 0, 0, 0 },
    bg: imgui.ImVec4 = .{ .x = 0, .y = 0, .z = 0, .w = 0 },
    tint: imgui.ImVec4 = .{ .x = 1, .y = 1, .z = 1, .w = 1 },
    renderer: FboRenderer,

    pub fn new(allocator: std.mem.Allocator, renderer: anytype) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .allocator = allocator,
            .fbo = glo.FboManager{},
            .renderer = FboRenderer.create(renderer),
        };
        return self;
    }

    pub fn delete(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn showFbo(self: *Self, x: f32, y: f32, size: imgui.ImVec2) void {
        _ = x;
        _ = y;
        // std.debug.assert(size != imgui.ImVec2{.x=0, .y=0});
        if (self.fbo.clear(@floatToInt(c_uint, size.x), @floatToInt(c_uint, size.y), &self.clear_color)) |texture| {
            defer self.fbo.unbind();
            _ = imgui.ImageButton(texture, size, .{
                .uv0 = .{ .x = 0, .y = 1 },
                .uv1 = .{ .x = 1, .y = 0 },
                .frame_padding = 0,
                .bg_col = self.bg,
                .tint_col = self.tint,
            });

            // active right & middle
            imgui.Custom_ButtonBehaviorMiddleRight();

            const io = imgui.GetIO();

            // disable mouse
            // ImVec2(-FLT_MAX,-FLT_MAX)
            if (io.MousePos.x == -FLT_MAX or io.MousePos.y == -FLT_MAX) {
                // skip
            } else {
                // const mouse_input = screen.MouseInput{
                //     .x = @floatToInt(i32, io.MousePos.x - x),
                //     .y = @floatToInt(i32, io.MousePos.y - y),
                //     .width = @floatToInt(i32, size.x),
                //     .height = @floatToInt(i32, size.y),
                //     .left_down = io.MouseDown[0],
                //     .right_down = io.MouseDown[1],
                //     .middle_down = io.MouseDown[2],
                //     .is_active = imgui.IsItemActive(),
                //     .is_hover = imgui.IsItemHovered(.{}),
                //     .wheel = @floatToInt(i32, io.MouseWheel),
                // };
                // // std.debug.print("{}\n", .{mouse_input});
                // const camera = self.mouse_handler.process(mouse_input, true);

                // self.gizmo.render(camera, mouse_input.x, mouse_input.y);
                // self.scene.render(camera);
                self.renderer.render(@floatToInt(u32, size.x), @floatToInt(u32, size.y));
            }
        }
    }

    pub fn show(self: *Self, p_open: *bool) void {
        if (!p_open.*) {
            return;
        }

        imgui.PushStyleVar_2(@enumToInt(imgui.ImGuiStyleVar._WindowPadding), .{ .x = 0, .y = 0 });
        if (imgui.Begin("render target", .{ .p_open = p_open, .flags = (@enumToInt(imgui.ImGuiWindowFlags._NoScrollbar) | @enumToInt(imgui.ImGuiWindowFlags._NoScrollWithMouse)) })) {
            var pos = imgui.GetWindowPos();
            // _ = imgui.InputFloat3("shift", &self.scene.camera.view.shift[0], .{});
            // _ = imgui.InputFloat4("rotation", &self.scene.camera.view.rotation.x, .{});
            // pos.y = 40;
            pos.y += imgui.GetFrameHeight();
            var size = imgui.GetContentRegionAvail();
            self.showFbo(pos.x, pos.y, size);
        }
        imgui.End();
        imgui.PopStyleVar(.{});
    }
};
