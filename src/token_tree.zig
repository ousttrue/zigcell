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
};
