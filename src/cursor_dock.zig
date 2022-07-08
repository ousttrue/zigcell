const std = @import("std");
const imgui = @import("imgui");
const Screen = @import("./screen.zig").Screen;

const Self = @This();

allocator: std.mem.Allocator,
screen: *Screen,

pub fn new(allocator: std.mem.Allocator, screen: *Screen) *Self {
    var self = allocator.create(Self) catch unreachable;
    self.* = Self{
        .allocator = allocator,
        .screen = screen,
    };
    return self;
}

pub fn delete(self: *Self) void {
    self.allocator.destroy(self);
}

pub fn show(self: *Self, p_open: *bool) void {
    if (!p_open.*) {
        return;
    }

    if (imgui.Begin("cursor", .{ .p_open = p_open })) {
        // imgui
        var position = self.screen.layout.cursor_position;
        _ = imgui.InputInt2("row, col", &position.row, .{});
    }
    imgui.End();
}
