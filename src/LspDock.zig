const std = @import("std");
const imgui = @import("imgui");
const imutil = @import("imutil");
const Self = @This();
const JsonRpc = @import("./JsonRpc.zig");

allocator: std.mem.Allocator,
jsonrpc: *JsonRpc,

pub fn new(allocator: std.mem.Allocator, jsonrpc: *JsonRpc) *Self {
    var self = allocator.create(Self) catch unreachable;
    self.* = Self{
        .allocator = allocator,
        .jsonrpc = jsonrpc,
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

    if (imgui.Begin("jsonrpc", .{ .p_open = p_open })) {
        imgui.TextUnformatted(imutil.localFormat("{s}", .{self.jsonrpc.getStatusText()}), .{});
    }
    imgui.End();
}
