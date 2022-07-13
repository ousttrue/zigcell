const std = @import("std");
const Self = @This();

src: []const u8,
pos: usize = 0,

pub fn init(src: []const u8) Self {
    return Self{
        .src = src,
    };
}

pub fn next(self: *Self) ?[]const u8 {
    if (self.pos >= self.src.len) {
        return null;
    }

    const len = std.unicode.utf8ByteSequenceLength(self.src[self.pos]) catch {
        return null;
    };
    const slice = self.src[self.pos .. self.pos + len];
    self.pos += len;
    return slice;
}

test "ascii" {
    var it = Self.init("abc");
    try std.testing.expectEqualSlices(u8, it.next().?, "a");
    try std.testing.expectEqualSlices(u8, it.next().?, "b");
    try std.testing.expectEqualSlices(u8, it.next().?, "c");
    try std.testing.expect(it.next() == null);
}

test "multibyte" {
    var it = Self.init("日本語");
    try std.testing.expectEqualSlices(u8, it.next().?, "日");
    try std.testing.expectEqualSlices(u8, it.next().?, "本");
    try std.testing.expectEqualSlices(u8, it.next().?, "語");
    try std.testing.expect(it.next() == null);
}
