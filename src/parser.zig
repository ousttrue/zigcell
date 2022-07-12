const std = @import("std");
const Node = @import("./node.zig").Node;

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
