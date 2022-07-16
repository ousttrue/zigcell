const std = @import("std");
const Self = @This();

ptr: *anyopaque,
readUntilCRLFFn: fn (ptr: *anyopaque, buffer: []u8) anyerror!usize,
readFn: fn (ptr: *anyopaque, buffer: []u8) anyerror!void,
writer: std.io.BufferedWriter(4096, std.fs.File.Writer),

pub fn readUntilCRLF(self: Self, buffer: []u8) !usize {
    return try self.readUntilCRLFFn(self.ptr, buffer);
}

pub fn read(self: Self, buffer: []u8) !void {
    try self.readFn(self.ptr, buffer);
}

pub fn sendAlloc(self: *Self, allocator: std.mem.Allocator, reqOrRes: anytype) void {
    var arr = std.ArrayList(u8).init(allocator);
    defer arr.deinit();
    std.json.stringify(reqOrRes, .{}, arr.writer()) catch @panic("stringify");

    const stdout_stream = self.writer.writer();
    stdout_stream.print("Content-Length: {}\r\n\r\n", .{arr.items.len}) catch @panic("send");
    stdout_stream.writeAll(arr.items) catch @panic("send");
    self.writer.flush() catch @panic("send");
}
