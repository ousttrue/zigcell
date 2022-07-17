const std = @import("std");
const Self = @This();

allocator: std.mem.Allocator,
content: []const u8,
tree: std.json.ValueTree,

pub fn init(allocator: std.mem.Allocator, content: []const u8, tree: std.json.ValueTree) Self {
    return Self{
        .allocator = allocator,
        .content = content,
        .tree = tree,
    };
}

pub fn deinit(self: *Self) void {
    self.tree.deinit();
    self.allocator.free(self.content);
}

pub fn getId(self: Self) ?i64 {
    const id = self.tree.root.Object.get("id") orelse return null;
    return switch (id) {
        .Integer => |value| value,
        else => null,
    };
}

pub fn getMethod(self: Self) ?[]const u8 {
    const method = self.tree.root.Object.get("method") orelse return null;
    return switch (method) {
        .String => |value| value,
        else => null,
    };
}

pub fn getParams(self: Self) ?std.json.Value {
    return self.tree.root.Object.get("params");
}
