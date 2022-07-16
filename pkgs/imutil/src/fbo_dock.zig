const std = @import("std");
const glo = @import("glo");
const imgui = @import("imgui");
const TypeEraser = @import("util").TypeEraser;

const FLT_MAX: f32 = 3.402823466e+38;

pub const MouseInput = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    left_down: bool,
    right_down: bool,
    middle_down: bool,
    is_active: bool,
    is_hover: bool,
    wheel: i32,
};

const FboRenderer = struct {
    const Self = @This();

    ptr: *anyopaque,
    callback: fn (ptr: *anyopaque, mouse_input: MouseInput) void,

    pub fn render(self: *Self, input: MouseInput) void {
        self.callback(self.ptr, input);
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
    bg: imgui.ImVec4 = .{ .x = 1, .y = 1, .z = 1, .w = 1 },
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
            if (io.MousePos.x == -FLT_MAX or io.MousePos.y == -FLT_MAX) {
                // skip
            } else {
                const mouse_input = MouseInput{
                    .x = @floatToInt(i32, io.MousePos.x - x),
                    .y = @floatToInt(i32, io.MousePos.y - y),
                    .width = @floatToInt(u32, size.x),
                    .height = @floatToInt(u32, size.y),
                    .left_down = io.MouseDown[0],
                    .right_down = io.MouseDown[1],
                    .middle_down = io.MouseDown[2],
                    .is_active = imgui.IsItemActive(),
                    .is_hover = imgui.IsItemHovered(.{}),
                    .wheel = @floatToInt(i32, io.MouseWheel),
                };

                self.renderer.render(mouse_input);
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
            pos.y += imgui.GetFrameHeight();
            var size = imgui.GetContentRegionAvail();
            self.showFbo(pos.x, pos.y, size);
        }
        imgui.End();
        imgui.PopStyleVar(.{});
    }
};
