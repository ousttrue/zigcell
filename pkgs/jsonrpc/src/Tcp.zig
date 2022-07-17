const std = @import("std");
const Transport = @import("./Transport.zig");
const Self = @This();

stream: std.net.Stream,
reader: std.net.Stream.Reader,
writer: std.net.Stream.Writer,

pub fn init(stream: std.net.Stream) Self {
    return Self{
        .stream = stream,
        .reader = stream.reader(),
        .writer = stream.writer(),
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
