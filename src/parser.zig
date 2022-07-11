const std = @import("std");
const zls = @import("zls");
pub const SourceRange = std.zig.Token.Loc;

const indent_buffer = " " ** 1024;

fn indent(level: usize) []const u8 {
    return indent_buffer[0 .. level * 2];
}

/// Token location inside source
pub const Loc = struct {
    start: usize,
    end: usize,
};

pub fn tokenLocation(tree: std.zig.Ast, token_index: std.zig.Ast.TokenIndex) Loc {
    const start = tree.tokens.items(.start)[token_index];
    const tag = tree.tokens.items(.tag)[token_index];

    // For some tokens, re-tokenization is needed to find the end.
    var tokenizer: std.zig.Tokenizer = .{
        .buffer = tree.source,
        .index = start,
        .pending_invalid_token = null,
    };

    const token = tokenizer.next();
    std.debug.assert(token.tag == tag);
    return .{ .start = token.loc.start, .end = token.loc.end };
}

fn nodeSourceRange(tree: std.zig.Ast, node: std.zig.Ast.Node.Index) SourceRange {
    const loc_start = tokenLocation(tree, tree.firstToken(node));
    const loc_end = tokenLocation(tree, zls.ast.lastToken(tree, node));

    return SourceRange{
        .start = loc_start.start,
        .end = loc_end.end,
    };
}

fn traverse(tree: std.zig.Ast, node_idx: u32, level: u32, prefix: []const u8) void {
    const tags = tree.nodes.items(.tag);
    const data = tree.nodes.items(.data);

    const node_tag = tags[node_idx];
    const range = nodeSourceRange(tree, node_idx);
    std.debug.print("\n[{d:0>3}]{s}{s}{s}: {}..{}", .{ node_idx, indent(level), prefix, @tagName(node_tag), range.start, range.end });

    if (zls.ast.isContainer(tree, node_idx)) {
        // children
        var buf: [2]std.zig.Ast.Node.Index = undefined;
        const ast_decls = zls.ast.declMembers(tree, node_idx, &buf);
        for (ast_decls) |decl| {
            traverse(tree, decl, level + 1, "");
        }
    } else {
        // detail
        switch (node_tag) {
            .simple_var_decl => {
                const var_decl = tree.simpleVarDecl(node_idx);
                if (var_decl.ast.type_node != 0) {
                    traverse(tree, var_decl.ast.type_node, level + 1, "[type_node]");
                }
                if (var_decl.ast.init_node != 0) {
                    traverse(tree, var_decl.ast.init_node, level + 1, "[init_node]");
                }
            },
            .builtin_call_two => {
                const b_data = data[node_idx];
                if (b_data.lhs != 0) {
                    traverse(tree, b_data.lhs, level + 1, "[lhs]");
                    if (b_data.rhs != 0) {
                        traverse(tree, b_data.rhs, level + 1, "[rhs]");
                    }
                }
            },
            .fn_decl => {},
            else => {
                // unknown
            },
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
        traverse(tree, 0, 0, "");

        errdefer tree.deinit(allocator);
        return Self.new(allocator, tree);
    }
};
