const std = @import("std");
const Transport = @import("./Transport.zig");
const TypeEraser = @import("util").TypeEraser;
const Self = @This();

pub const Error = error{
    NoCR,
};
reader: std.fs.File.Reader,
writer: std.fs.File.Writer,

pub fn init() Self {
    return Self{
        .reader = std.io.getStdIn().reader(),
        .writer = std.io.getStdOut().writer(),
    };
}

pub fn readByte(self: *Self) !u8 {
    return try self.reader.readByte();
}

pub fn read(self: *Self, buffer: []u8) !void {
    try self.reader.readNoEof(buffer);
}

pub fn write(self: *Self, buffer: []const u8) !void {
    const size = try self.writer.write(buffer);
    std.debug.assert(size == buffer.len);
}

pub fn newTransport(self: *Self, allocator: std.mem.Allocator) *Transport {
    return Transport.new(allocator, Self, self, "readByte", "read", "write");
}
