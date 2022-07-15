const std = @import("std");
const Self = @This();

ptr: *anyopaque,
readLineFn: fn (*anyopaque) anyerror![]const u8 = undefined,

pub fn readLine(self: Self) ![]const u8 {
    return try self.readLineFn(self.ptr);
}
