const std = @import("std");
const zls = @import("zls");

const indent_buffer = " " ** 1024;

fn indent(level: usize) []const u8 {
    return indent_buffer[0..level];
}

fn traverse(tree: std.zig.Ast, node_idx: u32, level: u32) void {
    const tags = tree.nodes.items(.tag);
    const node_tag = tags[node_idx];
    std.debug.print("[{d:0>3}]{s}{s}\n", .{ node_idx, indent(level), @tagName(node_tag) });

    // children
    if (zls.ast.isContainer(tree, node_idx)) {
        var buf: [2]std.zig.Ast.Node.Index = undefined;
        const ast_decls = zls.ast.declMembers(tree, node_idx, &buf);
        for (ast_decls) |decl| {
            traverse(tree, decl, level + 1);
        }
    }
}

pub const Parser = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    tree: std.zig.Ast,

    pub fn new(allocator: std.mem.Allocator, tree: std.zig.Ast) *Self {
        var self = allocator.create(Self) catch unreachable;
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
        const tree: std.zig.Ast = try std.zig.parse(allocator, text);

        // const scope = try zls.analysis.makeDocumentScope(allocator, tree);
        // scope.debugPrint();
        traverse(tree, 0, 0);

        errdefer tree.deinit(allocator);
        return Self.new(allocator, tree);
    }
};
