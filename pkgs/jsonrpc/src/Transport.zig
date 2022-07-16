const std = @import("std");
const Self = @This();

ptr: *anyopaque,
readUntilCRLFFn: fn (ptr: *anyopaque, buffer: []u8) anyerror!usize,
readFn: fn (ptr: *anyopaque, buffer: []u8) anyerror!void,
writeFn: fn (ptr: *anyopaque, buffer: []const u8) anyerror!void,

pub fn readUntilCRLF(self: Self, buffer: []u8) !usize {
    return try self.readUntilCRLFFn(self.ptr, buffer);
}

pub fn read(self: Self, buffer: []u8) !void {
    try self.readFn(self.ptr, buffer);
}

pub fn send(self: *Self, buffer: []const u8) !void {
    var tmp: [128]u8 = undefined;
    const slice = try std.fmt.bufPrint(&tmp, "Content-Length: {}\r\n\r\n", .{buffer.len});
    try self.writeFn(self.ptr, slice);
    try self.writeFn(self.ptr, buffer);
}
