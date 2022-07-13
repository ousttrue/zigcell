const std = @import("std");

// Fixed sized buffer
pub const Document = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    utf8: [65535]u8 = undefined,
    utf8Length: usize = undefined,
    utf16: [65535]u16 = undefined,
    utf16Length: usize = undefined,

    pub fn new(allocator: std.mem.Allocator, src: []const u8) *Self {
        var self = allocator.create(Self) catch unreachable;

        self.* = Self{
            .allocator = allocator,
        };

        // oopy utf8
        std.mem.copy(u8, &self.utf8, src);
        self.utf8Length = src.len;
        self.utf8[self.utf8Length] = 0;

        // copy utf16
        self.utf16Length = std.unicode.utf8ToUtf16Le(&self.utf16, src) catch unreachable;
        self.utf16[self.utf16Length] = 0;

        return self;
    }

    pub fn delete(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn utf8Slice(self: Self) [:0]const u8 {
        return self.utf8[0..self.utf8Length :0];
    }

    pub fn utf16Slice(self: Self) [:0]const u16 {
        return self.utf16[0..self.utf16Length :0];
    }
};
