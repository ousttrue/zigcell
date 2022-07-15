const std = @import("std");
const token_tree = @import("./token_tree.zig");
const Node = token_tree.Node;

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

pub fn getChildren(tree: std.zig.Ast, idx: u32) []const u32 {
    const tag = tree.nodes.items(.tag);
    const node_tag = tag[idx];
    const data = tree.nodes.items(.data);
    const node_data = data[idx];
    var children: [2]u32 = undefined;
    var count: u32 = 0;

    return switch (node_tag) {
        .simple_var_decl => blk: {
            const var_decl = tree.simpleVarDecl(idx);
            if (var_decl.ast.type_node != 0) {
                children[count] = var_decl.ast.type_node;
                count += 1;
            }
            if (var_decl.ast.init_node != 0) {
                children[count] = var_decl.ast.init_node;
                count += 1;
            }
            break :blk children[0..count];
        },
        .builtin_call_two => blk: {
            if (node_data.lhs != 0) {
                children[count] = node_data.lhs;
                count += 1;
            }
            if (node_data.rhs != 0) {
                children[count] = node_data.lhs;
                count += 1;
            }
            break :blk children[0..count];
        },
        .field_access => blk: {
            children[0] = node_data.lhs;
            break :blk children[0..1];
        },
        .string_literal => children[0..0],
        else => blk: {
            std.debug.print("unknown {s}\n", .{@tagName(node_tag)});
            break :blk &.{};
        },
    };
}

pub fn traverse(context: *AstContext, stack: *std.ArrayList(u32)) void {
    const tree = context.tree;
    const tag = tree.nodes.items(.tag);
    const idx = stack.items[stack.items.len - 1];

    for (stack.items) |x, i| {
        if (i > 0) {
            std.debug.print(", ", .{});
        }
        std.debug.print("{}", .{x});
    }
    const node = Node.init(context, idx);
    std.debug.print("=>{s} {}..{}", .{ @tagName(tag[idx]), node.token_start, node.token_last });
    std.debug.print("\n", .{});

    for (getChildren(context.tree, idx)) |child| {
        stack.append(child) catch unreachable;
        traverse(context, stack);
        _ = stack.pop();
    }
}

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
        for (tree.rootDecls()) |decl| {
            stack.append(decl) catch unreachable;
            traverse(self, &stack);
            _ = stack.pop();
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
};
