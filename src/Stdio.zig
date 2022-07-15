const std = @import("std");
const Self = @This();

reader: std.fs.File.Reader,
buffer: [0x100]u8 = undefined,

pub fn init() Self {
    return Self{
        .reader = std.io.getStdIn().reader(),
    };
}

pub fn readLine(self: *Self) ![]const u8 {
    return try self.reader.readUntilDelimiter(&self.buffer, '\n');
}
