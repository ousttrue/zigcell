const std = @import("std");
const zls = @import("zls");
const AstContext = @import("./ast_context.zig").AstContext;

const indent_buffer = " " ** 1024;

fn indent(level: usize) []const u8 {
    return indent_buffer[0 .. level * 2];
}

pub const Node = struct {
    const Self = @This();

    context: *AstContext,
    parent: u32,
    idx: u32,
    token_start: u32,
    token_last: u32,
    tag: std.zig.Ast.Node.Tag,

    pub fn init(parent: u32, context: *AstContext, idx: u32) Self {
        const tree = context.tree;
        const tags = tree.nodes.items(.tag);
        const node_tag = tags[idx];
        return Self{
            .context = context,
            .parent = parent,
            .idx = idx,
            .token_start = tree.firstToken(idx),
            .token_last = tree.lastToken(idx),
            .tag = node_tag,
        };
    }

    pub fn child(self: *Self, idx: u32) Self {
        return Self.init(self.idx, self.context, idx);
    }

    pub fn debugPrint(self: Self, level: usize) void {
        std.debug.print(
            "\n[{d:0>3}]{s}{s}: {}..{}=> ",
            .{
                self.idx,
                indent(level),
                @tagName(self.tag),
                self.token_start,
                self.token_last,
            },
        );
    }

    pub fn traverse(self: *Self, level: u32) void {
        const tree = self.context.tree;
        // self.node_stack.append(node.idx) catch unreachable;
        // defer _ = self.node_stack.pop();

        self.debugPrint(level);
        // const tokens = self.getTokens(node.token_start, node.token_last);
        // for (tokens) |*token, i| {
        //     if (i > 0) {
        //         std.debug.print(", ", .{});
        //     }
        //     std.debug.print("{s}", .{self.tree.source[token.loc.start..token.loc.end]});
        // }

        // detail
        const data = tree.nodes.items(.data);
        // const token_tags = tree.tokens.items(.tag);

        switch (self.tag) {
            .simple_var_decl => {
                const var_decl = tree.simpleVarDecl(self.idx);
                if (var_decl.ast.type_node != 0) {
                    self.child(var_decl.ast.type_node).traverse(level + 1);
                }
                if (var_decl.ast.init_node != 0) {
                    self.child(var_decl.ast.init_node).traverse(level + 1);
                }
            },
            .builtin_call_two => {
                const b_data = data[self.idx];
                if (b_data.lhs != 0) {
                    self.child(b_data.lhs).traverse(level + 1);
                    if (b_data.rhs != 0) {
                        self.child(b_data.rhs).traverse(level + 1);
                    }
                }
            },
            .fn_decl => {
                var buf: [1]std.zig.Ast.Node.Index = undefined;
                const func = zls.ast.fnProto(tree, self.idx, &buf).?;

                // params
                var it = func.iterate(&tree);
                while (it.next()) |param| {
                    self.child(param.type_expr).traverse(level + 1);
                }

                // return
                if (data[self.idx].lhs != 0) {
                    self.child(data[data[self.idx].lhs].rhs).traverse(level + 1);
                }

                // body
                self.child(data[self.idx].rhs).traverse(level + 1);
            },
            else => {
                // unknown
            },
        }
    }
};
