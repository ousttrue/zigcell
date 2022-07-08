const std = @import("std");

pub const Ast = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    tree: std.zig.Ast,

    pub fn new(allocator: std.mem.Allocator, tree: std.zig.Ast) *Self {
        var self = allocator.create(Ast) catch unreachable;
        self.* = Self{
            .allocator = allocator,
            .tree = tree,
        };
        return self;
    }

    pub fn delete(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn parse(allocator: std.mem.Allocator, src: []const u16) !*Self {
        const text = try std.unicode.utf16leToUtf8AllocZ(allocator, src);
        defer allocator.free(text);
        var tree = try std.zig.parse(allocator, text);
        errdefer tree.deinit(allocator);
        return Self.new(allocator, tree);
    }
};
