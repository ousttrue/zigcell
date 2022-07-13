const std = @import("std");
const zls = @import("zls");
const token_tree = @import("./token_tree.zig");
const Node = token_tree.Node;
const AstContext = @import("./ast_context.zig").AstContext;
const Decl = @import("./decl.zig").Decl;


pub fn traverse(node: Node, level: u32) void {
    const tree = node.context.tree;
    const data = tree.nodes.items(.data);
    switch (node.tag) {
        .simple_var_decl => {
            const var_decl = tree.simpleVarDecl(node.idx);
            if (var_decl.ast.type_node != 0) {
                traverse(node.child(var_decl.ast.type_node), level + 1);
            }
            if (var_decl.ast.init_node != 0) {
                traverse(node.child(var_decl.ast.init_node), level + 1);
            }
        },
        .builtin_call_two => {
            const b_data = data[node.idx];
            if (b_data.lhs != 0) {
                traverse(node.child(b_data.lhs), level + 1);
                if (b_data.rhs != 0) {
                    traverse(node.child(b_data.rhs), level + 1);
                }
            }
        },
        .fn_decl => {
            var buf: [1]std.zig.Ast.Node.Index = undefined;
            const func = zls.ast.fnProto(tree, node.idx, &buf).?;

            // params
            var it = func.iterate(&tree);
            while (it.next()) |param| {
                traverse(node.child(param.type_expr), level + 1);
            }

            // return
            if (data[node.idx].lhs != 0) {
                traverse(node.child(data[data[node.idx].lhs].rhs), level + 1);
            }

            // body
            traverse(node.child(data[node.idx].rhs), level + 1);
        },
        else => {
            // unknown
        },
    }
}

pub const Parser = struct {
    const Self = @This();

    context: *AstContext,
    decls: std.ArrayList(Decl),

    pub fn new(allocator: std.mem.Allocator, context: *AstContext) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .context = context,
            .decls = std.ArrayList(Decl).init(allocator),
        };
        return self;
    }

    pub fn delete(self: Self) void {
        self.nodes.deinit();
        self.allocator.destroy(self);
    }

    pub fn parse(allocator: std.mem.Allocator, src: [:0]const u8) !*Self {
        const context = AstContext.new(allocator, src);

        var self = Self.new(allocator, context);

        for (context.tree.rootDecls()) |decl| {
            var node = Decl.init(context, decl);
            // traverse(node, 0);
            self.decls.append(node) catch unreachable;

            node.debugPrint();
            std.debug.print("\n", .{});
        }

        return self;
    }
};
