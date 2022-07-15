const std = @import("std");
const zls = @import("zls");
const AstContext = @import("./ast_context.zig").AstContext;

pub const AstPath = struct {};

pub const Parser = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    context: *AstContext,

    pub fn new(allocator: std.mem.Allocator, context: *AstContext) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .allocator = allocator,
            .context = context,
        };
        return self;
    }

    pub fn delete(self: *Self) void {
        self.context.delete();
        self.allocator.destroy(self);
    }

    pub fn parse(allocator: std.mem.Allocator, src: [:0]const u8) !*Self {
        const context = AstContext.new(allocator, src);
        var self = Self.new(allocator, context);
        return self;
    }

    pub fn getAstPath(self: Self, token_idx: usize) ?AstPath {
        const tag = self.context.tree.nodes.items(.tag);
        var idx = self.context.tokens_node[token_idx];
        while (self.context.getParentNode(idx)) |parent| : (idx = parent) {
            std.debug.print(", {}[{s}]", .{ idx, @tagName(tag[idx]) });
        }
        std.debug.print("\n", .{});

        return null;
    }
};
