const std = @import("std");
const Self = @This();

pub const Error = error{
    ReadError,
    ParseIntError,
    AllocError,
    UnknownHeader,
    NoContentLength,
};

const CONTENT_LENGTH = "Content-Length: ";
const CONTENT_TYPE = "Content-Type: ";

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

pub fn readNextAlloc(self: Self, allocator: std.mem.Allocator) Error![]const u8 {
    var content_length: u32 = 0;
    while (true) {
        var buffer: [128]u8 = undefined;
        const len = self.readUntilCRLF(buffer[0..buffer.len]) catch {
            return Error.ReadError;
        };
        if (len == 0) {
            break;
        }
        const slice = buffer[0..len];

        if (std.mem.startsWith(u8, slice, CONTENT_LENGTH)) {
            // Content-Length: 1234\r\n
            content_length = std.fmt.parseInt(u32, slice[CONTENT_LENGTH.len..], 10) catch {
                return Error.ParseIntError;
            };
        } else if (std.mem.startsWith(u8, slice, CONTENT_TYPE)) {
            // Content-Type: ...\r\n
        } else {
            return Error.UnknownHeader;
        }
    }

    if (content_length == 0) {
        return Error.NoContentLength;
    }

    var body = allocator.alloc(u8, content_length) catch {
        return Error.AllocError;
    };
    errdefer allocator.free(body);
    self.read(body) catch {
        return Error.ReadError;
    };

    return body;
}

pub fn send(self: Self, buffer: []const u8) !void {
    var tmp: [128]u8 = undefined;
    const slice = try std.fmt.bufPrint(&tmp, "Content-Length: {}\r\n\r\n", .{buffer.len});
    try self.writeFn(self.ptr, slice);
    try self.writeFn(self.ptr, buffer);
}
