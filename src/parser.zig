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

fn line(src: []const u8) []const u8 {
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        if (src[i] == '\n') {
            break;
        }
    }
    return src[0..i];
}

pub const Node = struct {
    const Self = @This();

    parent: u32,
    idx: u32,
    token_start: u32,
    token_last: u32,
    tag: std.zig.Ast.Node.Tag,

    pub fn init(parent: u32, tree: std.zig.Ast, idx: u32) Self {
        const tags = tree.nodes.items(.tag);
        const node_tag = tags[idx];
        return Self{
            .parent = parent,
            .idx = idx,
            .token_start = tree.firstToken(idx),
            .token_last = tree.lastToken(idx),
            .tag = node_tag,
        };
    }

    pub fn child(self: Self, tree: std.zig.Ast, idx: u32) Self {
        const tags = tree.nodes.items(.tag);
        const node_tag = tags[idx];
        return Self{
            .parent = self.idx,
            .idx = idx,
            .token_start = tree.firstToken(idx),
            .token_last = tree.lastToken(idx),
            .tag = node_tag,
        };
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

fn getAllTokens(allocator: std.mem.Allocator, source: [:0]const u8) std.ArrayList(std.zig.Token) {
    var tokens = std.ArrayList(std.zig.Token).init(allocator);
    var tokenizer: std.zig.Tokenizer = .{
        .buffer = source,
        .index = 0,
        .pending_invalid_token = null,
    };

    while (true) {
        const token = tokenizer.next();
        if (token.tag == .eof) {
            break;
        }
        tokens.append(token) catch unreachable;
    }

    return tokens;
}

pub const Parser = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    tree: std.zig.Ast,
    tokens: std.ArrayList(std.zig.Token),
    nodes: std.ArrayList(Node),
    node_stack: std.ArrayList(u32),

    pub fn new(allocator: std.mem.Allocator, tree: std.zig.Ast) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .allocator = allocator,
            .tree = tree,
            .tokens = getAllTokens(allocator, tree.source),
            .nodes = std.ArrayList(Node).init(allocator),
            .node_stack = std.ArrayList(u32).init(allocator),
        };

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

        for (tree.rootDecls()) |decl| {
            self.traverse(Node.init(0, tree, decl));
        }

        return self;
    }

    fn getTokens(self: Self, start: usize, last: usize) []const std.zig.Token {
        var end = last;
        if (end < self.tokens.items.len) {
            end += 1;
        }
        return self.tokens.items[start..end];
    }

    fn traverse(self: *Self, node: Node) void {
        self.node_stack.append(node.idx) catch unreachable;
        defer _ = self.node_stack.pop();

        node.debugPrint(self.node_stack.items.len);
        const tokens = self.getTokens(node.token_start, node.token_last);
        for (tokens) |*token, i| {
            if (i > 0) {
                std.debug.print(", ", .{});
            }
            std.debug.print("{s}", .{self.tree.source[token.loc.start..token.loc.end]});
        }

        if (zls.ast.isContainer(self.tree, node.idx)) {
            // children
            var buf: [2]std.zig.Ast.Node.Index = undefined;
            const ast_decls = zls.ast.declMembers(self.tree, node.idx, &buf);
            for (ast_decls) |decl| {
                self.traverse(node.child(self.tree, decl));
            }
        } else {
            // detail
            const data = self.tree.nodes.items(.data);
            switch (node.tag) {
                .simple_var_decl => {
                    const var_decl = self.tree.simpleVarDecl(node.idx);
                    if (var_decl.ast.type_node != 0) {
                        self.traverse(node.child(self.tree, var_decl.ast.type_node));
                    }
                    if (var_decl.ast.init_node != 0) {
                        self.traverse(node.child(self.tree, var_decl.ast.init_node));
                    }
                },
                .builtin_call_two => {
                    const b_data = data[node.idx];
                    if (b_data.lhs != 0) {
                        self.traverse(node.child(self.tree, b_data.lhs));
                        if (b_data.rhs != 0) {
                            self.traverse(node.child(self.tree, b_data.rhs));
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
