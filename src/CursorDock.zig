const std = @import("std");
const imgui = @import("imgui");
const LineLayout = @import("./LineLayout.zig");

const Self = @This();

allocator: std.mem.Allocator,
layout: *LineLayout,

pub fn new(allocator: std.mem.Allocator, layout: *LineLayout) *Self {
    var self = allocator.create(Self) catch unreachable;
    self.* = Self{
        .allocator = allocator,
        .layout = layout,
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
        var position = self.layout.cursor_position;
        _ = imgui.InputInt2("row, col", &position.row, .{});
    }
    imgui.End();
}
