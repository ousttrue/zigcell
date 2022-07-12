const std = @import("std");

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

pub const AstContext = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    text: [:0]const u8,
    tree: std.zig.Ast,
    tokens: std.ArrayList(std.zig.Token),

    pub fn new(allocator: std.mem.Allocator, src: []const u16) *Self {
        const text = std.unicode.utf16leToUtf8AllocZ(allocator, src) catch unreachable;
        const tree: std.zig.Ast = std.zig.parse(allocator, text) catch unreachable;

        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .allocator = allocator,
            .text = text,
            .tree = tree,
            .tokens = getAllTokens(allocator, text),
        };
        return self;
    }

    pub fn delete(self: Self) void {
        self.tokens.deinit();
        self.tree.deinit();
        self.allocator.free(self.text);
        self.allocator.destroy(self);
    }

    pub fn getTokenText(self: Self, token: std.zig.Token) []const u8 {
        return self.text[token.loc.start..token.loc.end];
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
