const std = @import("std");
const zls = @import("zls");

const indent_buffer = " " ** 1024;

fn indent(level: usize) []const u8 {
    return indent_buffer[0 .. level * 2];
}

/// Token location inside source
pub fn getToken(tree: std.zig.Ast, token_index: std.zig.Ast.TokenIndex) std.zig.Token {
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
    return token;
}

const SourceRange = struct {
    const Self = @This();
    start: usize,
    end: usize,
    source: []const u8,

    fn init(tree: std.zig.Ast, node: std.zig.Ast.Node.Index) Self {
        const start = getToken(tree, tree.firstToken(node));
        const end = getToken(tree, zls.ast.lastToken(tree, node));
        return Self{
            .start = start.loc.start,
            .end = end.loc.end,
            .source = tree.source[start.loc.start..end.loc.end],
        };
    }
};

fn line(src: []const u8) []const u8 {
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        if (src[i] == '\n') {
            break;
        }
    }
    return src[0..i];
}

pub const Parser = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    tree: std.zig.Ast,
    node_stack: std.ArrayList(u32),
    tokens: std.ArrayList(std.zig.Token),

    pub fn new(allocator: std.mem.Allocator, tree: std.zig.Ast) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .allocator = allocator,
            .tree = tree,
            .node_stack = std.ArrayList(u32).init(allocator),
            .tokens = std.ArrayList(std.zig.Token).init(allocator),
        };

        // For some tokens, re-tokenization is needed to find the end.
        var tokenizer: std.zig.Tokenizer = .{
            .buffer = tree.source,
            .index = 0,
            .pending_invalid_token = null,
        };

        while (true) {
            const token = tokenizer.next();
            if (token.tag == .eof) {
                break;
            }
            self.tokens.append(token) catch unreachable;
        }

        return self;
    }

    pub fn delete(self: Self) void {
        self.tokens.deinit();
        self.node_stack.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn parse(allocator: std.mem.Allocator, src: []const u16) !*Self {
        const text = try std.unicode.utf16leToUtf8AllocZ(allocator, src);
        defer allocator.free(text);
        const tree: std.zig.Ast = try std.zig.parse(allocator, text);

        errdefer tree.deinit(allocator);
        var self = Self.new(allocator, tree);

        self.traverse(tree, 0, "");

        return self;
    }

    fn traverse(self: *Self, tree: std.zig.Ast, node_idx: u32, prefix: []const u8) void {
        self.node_stack.append(node_idx) catch unreachable;
        defer _ = self.node_stack.pop();

        const tags = tree.nodes.items(.tag);
        const data = tree.nodes.items(.data);

        const node_tag = tags[node_idx];
        const range = SourceRange.init(tree, node_idx);

        const start = tree.firstToken(node_idx);
        var end = zls.ast.lastToken(tree, node_idx);
        if (end < self.tokens.items.len) {
            end += 1;
        }
        const tokens = self.tokens.items[start..end];

        std.debug.print(
            "\n[{d:0>3}]{s}{s}{s}: {}..{}=> {s}",
            .{
                node_idx,
                indent(self.node_stack.items.len),
                prefix,
                @tagName(node_tag),
                start,
                end,
                line(range.source),
            },
        );
        for (tokens) |*token| {
            std.debug.print(", {s}", .{tree.source[token.loc.start..token.loc.end]});
        }

        if (zls.ast.isContainer(tree, node_idx)) {
            // children
            var buf: [2]std.zig.Ast.Node.Index = undefined;
            const ast_decls = zls.ast.declMembers(tree, node_idx, &buf);
            for (ast_decls) |decl| {
                self.traverse(tree, decl, "");
            }
        } else {
            // detail
            switch (node_tag) {
                .simple_var_decl => {
                    const var_decl = tree.simpleVarDecl(node_idx);
                    if (var_decl.ast.type_node != 0) {
                        self.traverse(tree, var_decl.ast.type_node, "[type_node]");
                    }
                    if (var_decl.ast.init_node != 0) {
                        self.traverse(tree, var_decl.ast.init_node, "[init_node]");
                    }
                },
                .builtin_call_two => {
                    const b_data = data[node_idx];
                    if (b_data.lhs != 0) {
                        self.traverse(tree, b_data.lhs, "[lhs]");
                        if (b_data.rhs != 0) {
                            self.traverse(tree, b_data.rhs, "[rhs]");
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
};
