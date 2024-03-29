const std = @import("std");
const Ast = std.zig.Ast;
const AstNodeIterator = @import("./AstNodeIterator.zig");

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

pub fn traverse(context: *AstContext, stack: *std.ArrayList(u32), idx: Ast.Node.Index) void {
    const tree = context.tree;
    context.nodes_parent[idx] = stack.items[stack.items.len - 1];
    stack.append(idx) catch unreachable;

    const token_start = tree.firstToken(idx);
    const token_last = tree.lastToken(idx);
    var token_idx = token_start;
    while (token_idx <= token_last) : (token_idx += 1) {
        context.tokens_node[token_idx] = idx;
    }

    var it = AstNodeIterator.init(idx);
    _ = async it.iterateAsync(tree);
    while (it.value) |child| : (it.next()) {
        traverse(context, stack, child);
    }
    _ = stack.pop();
}

pub const AstPath = struct {};

pub const AstContext = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    tree: std.zig.Ast,
    nodes_parent: []u32,
    tokens: std.ArrayList(std.zig.Token),
    tokens_node: []u32,

    pub fn new(allocator: std.mem.Allocator, src: [:0]const u8) *Self {
        const tree: std.zig.Ast = std.zig.parse(allocator, src) catch unreachable;
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .allocator = allocator,
            .tree = tree,
            .nodes_parent = allocator.alloc(u32, tree.nodes.len) catch unreachable,
            .tokens = getAllTokens(allocator, tree.source),
            .tokens_node = allocator.alloc(u32, tree.tokens.len) catch unreachable,
        };
        for (self.nodes_parent) |*x| {
            x.* = 0;
        }
        for (self.tokens_node) |*x| {
            x.* = 0;
        }

        var stack = std.ArrayList(u32).init(allocator);
        defer stack.deinit();

        // root
        stack.append(0) catch unreachable;
        for (tree.rootDecls()) |decl| {
            // top level
            traverse(self, &stack, decl);
        }

        return self;
    }

    pub fn delete(self: *Self) void {
        self.allocator.free(self.tokens_node);
        self.tokens.deinit();
        self.allocator.free(self.nodes_parent);
        self.tree.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn getTokenText(self: Self, token: std.zig.Token) []const u8 {
        return self.tree.source[token.loc.start..token.loc.end];
    }

    pub fn getTokens(self: Self, start: usize, last: usize) []const std.zig.Token {
        var end = last;
        if (end < self.tokens.items.len) {
            end += 1;
        }
        return self.tokens.items[start..end];
    }

    pub fn getNodeTokens(self: Self, idx: u32) []const std.zig.Token {
        return self.getTokens(self.tree.firstToken(idx), self.tree.lastToken(idx));
    }

    pub fn getParentNode(self: Self, idx: u32) ?u32 {
        if (idx == 0) {
            return null;
        }
        return self.nodes_parent[idx];
    }

    pub fn getNodeTag(self: Self, idx: u32) std.zig.Ast.Node.Tag {
        const tag = self.tree.nodes.items(.tag);
        return tag[idx];
    }

    pub fn getMainToken(self: Self, idx: u32) std.zig.Token {
        const main_token = self.tree.nodes.items(.main_token);
        const token_idx = main_token[idx];
        return self.tokens.items[token_idx];
    }

    pub fn getAstPath(self: Self, token_idx: usize) ?AstPath {
        const tag = self.tree.nodes.items(.tag);
        var idx = self.tokens_node[token_idx];
        while (self.getParentNode(idx)) |parent| : (idx = parent) {
            std.debug.print(", {}[{s}]", .{ idx, @tagName(tag[idx]) });
        }
        std.debug.print("\n", .{});

        return null;
    }

    pub fn findAncestor(self: Self, idx: u32, target: u32) bool {
        var current = self.nodes_parent[idx];
        while (current != 0) : (current = self.nodes_parent[current]) {
            if (current == target) {
                return true;
            }
        }
        return false;
    }
};
