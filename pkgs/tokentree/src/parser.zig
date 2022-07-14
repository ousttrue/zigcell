const std = @import("std");
const zls = @import("zls");
const token_tree = @import("./token_tree.zig");
const Node = token_tree.Node;
const AstContext = @import("./ast_context.zig").AstContext;

pub fn getChildren(tree: std.zig.Ast, idx: u32) []const u32 {
    const tag = tree.nodes.items(.tag);
    const data = tree.nodes.items(.data);
    var children: [2]u32 = undefined;
    var count: u32 = 0;

    return switch (tag[idx]) {
        .root => tree.rootDecls(),
        .simple_var_decl => blk: {
            const var_decl = tree.simpleVarDecl(idx);
            if (var_decl.ast.type_node != 0) {
                children[count] = var_decl.ast.type_node;
                count += 1;
            }
            if (var_decl.ast.init_node != 0) {
                children[count] = var_decl.ast.init_node;
                count += 1;
            }
            break :blk children[0..count];
        },
        .builtin_call_two => blk: {
            const b_data = data[idx];
            if (b_data.lhs != 0) {
                children[count] = b_data.lhs;
                count += 1;
            }
            if (b_data.rhs != 0) {
                children[count] = b_data.lhs;
                count += 1;
            }
            break :blk children[0..count];
        },
        else => &.{},
    };
}

pub fn traverse(context: *AstContext, stack: *std.ArrayList(u32)) void {
    const tree = context.tree;
    const tag = tree.nodes.items(.tag);
    const idx = stack.items[stack.items.len - 1];

    for (stack.items) |x, i| {
        if (i > 0) {
            std.debug.print(", ", .{});
        }
        std.debug.print("{}", .{x});
    }
    const node = Node.init(context, idx);
    std.debug.print("=>{s} {}..{}", .{ @tagName(tag[idx]), node.token_start, node.token_last });
    std.debug.print("\n", .{});

    for (getChildren(context.tree, idx)) |child| {
        stack.append(child) catch unreachable;
        traverse(context, stack);
        _ = stack.pop();
    }
}

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

        var stack = std.ArrayList(u32).init(allocator);
        defer stack.deinit();
        try stack.append(0);
        traverse(context, &stack);
        return self;
    }

    pub fn getAstPath(self: Self, token_index: usize) ?AstPath {
        _ = self;
        _ = token_index;
        return null;
    }
};
