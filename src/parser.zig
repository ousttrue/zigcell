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

    tree: *std.zig.Ast,
    parent: u32,
    idx: u32,
    token_start: u32,
    token_last: u32,
    tag: std.zig.Ast.Node.Tag,

    pub fn init(parent: u32, tree: *std.zig.Ast, idx: u32) Self {
        const tags = tree.nodes.items(.tag);
        const node_tag = tags[idx];
        return Self{
            .tree = tree,
            .parent = parent,
            .idx = idx,
            .token_start = tree.firstToken(idx),
            .token_last = tree.lastToken(idx),
            .tag = node_tag,
        };
    }

    pub fn child(self: *Self, idx: u32) Self {
        const tags = self.tree.nodes.items(.tag);
        const node_tag = tags[idx];
        return Self{
            .tree = self.tree,
            .parent = self.idx,
            .idx = idx,
            .token_start = self.tree.firstToken(idx),
            .token_last = self.tree.lastToken(idx),
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

    fn traverse(self: *Self, level: u32) void {
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
        const data = self.tree.nodes.items(.data);
        // const token_tags = self.tree.tokens.items(.tag);

        switch (self.tag) {
            .simple_var_decl => {
                const var_decl = self.tree.simpleVarDecl(self.idx);
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
                const func = zls.ast.fnProto(self.tree.*, self.idx, &buf).?;

                // params
                var it = func.iterate(self.tree);
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

        self.traverse();

        return self;
    }

    fn traverse(self: *Self) void {
        for (self.tree.rootDecls()) |decl| {
            Node.init(0, &self.tree, decl).traverse(0);
        }
        std.debug.print("\n", .{});
    }

    fn getTokens(self: Self, start: usize, last: usize) []const std.zig.Token {
        var end = last;
        if (end < self.tokens.items.len) {
            end += 1;
        }
        return self.tokens.items[start..end];
    }
};
