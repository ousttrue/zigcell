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

    pub fn child(self: Self, idx: u32) Self {
        return Self.init(self.idx, self.context, idx);
    }

    pub fn getTokens(self: Self) []const std.zig.Token {
        return self.context.getTokens(self.token_start, self.token_last);
    }

    pub fn getTokenText(self: Self, token: std.zig.Token) []const u8 {
        return self.context.text[token.loc.start..token.loc.end];
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

        const tokens = self.getTokens();
        const tree = self.context.tree;
        switch (self.tag) {
            .simple_var_decl => {
                // const name: <type_node> = <init_node>;
                const var_decl = tree.simpleVarDecl(self.idx);
                // var next_token: u32 = 0;
                var i: u32 = 0;
                if (var_decl.ast.type_node != 0) {
                    const type_node = self.child(var_decl.ast.type_node);
                    const next_token = type_node.token_start - self.token_start;
                    while (i < next_token) : (i += 1) {
                        std.debug.print(" {s}", .{self.getTokenText(tokens[i])});
                    }
                    // <type_node>
                    i = type_node.token_last + 1;
                }
                if (var_decl.ast.init_node != 0) {
                    const init_node = self.child(var_decl.ast.init_node);
                    const next_token = init_node.token_start - self.token_start;
                    while (i < next_token) : (i += 1) {
                        std.debug.print(" {s}", .{self.getTokenText(tokens[i])});
                    }
                    // <init_node>
                    init_node.debugPrint(level + 1);
                }
            },
            else => {},
        }
    }
};
