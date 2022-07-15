const std = @import("std");
const Self = @This();

ptr: *anyopaque,
readUntilCRLFFn: fn (ptr: *anyopaque, buffer: []u8) anyerror!usize = undefined,
readFn: fn (ptr: *anyopaque, buffer: []u8) anyerror!void = undefined,

pub fn readUntilCRLF(self: Self, buffer: []u8) !usize {
    return try self.readUntilCRLFFn(self.ptr, buffer);
}

pub fn read(self: Self, buffer: []u8) !void {
    try self.readFn(self.ptr, buffer);
}
