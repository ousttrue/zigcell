const std = @import("std");
const TypeEraser = @import("util").TypeEraser;
const Self = @This();

pub const Error = error{
    NoCR,
    ReadError,
    ParseIntError,
    AllocError,
    UnknownHeader,
    NoContentLength,
};

const CONTENT_LENGTH = "Content-Length: ";
const CONTENT_TYPE = "Content-Type: ";

allocator: std.mem.Allocator,
ptr: *anyopaque,
readByteFn: fn (ptr: *anyopaque) anyerror!u8,
readFn: fn (ptr: *anyopaque, buffer: []u8) anyerror!void,
writeFn: fn (ptr: *anyopaque, buffer: []const u8) anyerror!void,

pub fn new(
    allocator: std.mem.Allocator,
    comptime T: type,
    ptr: *T,
    comptime readByteFn: []const u8,
    comptime readFn: []const u8,
    comptime writeFn: []const u8,
) *Self {
    var self = allocator.create(Self) catch unreachable;
    self.* = Self{
        .allocator = allocator,
        .ptr = ptr,
        .readByteFn = TypeEraser(T, readByteFn).call,
        .readFn = TypeEraser(T, readFn).call,
        .writeFn = TypeEraser(T, writeFn).call,
    };
    return self;
}

pub fn delete(self: *Self) void {
    self.allocator.destroy(self);
}

pub fn readByte(self: *Self) !u8 {
    return try self.readByteFn(self.ptr);
}

pub fn read(self: *Self, buffer: []u8) !void {
    try self.readFn(self.ptr, buffer);
}

pub fn readNextAlloc(self: *Self, allocator: std.mem.Allocator) Error![]const u8 {
    var content_length: u32 = 0;
    while (true) {
        var line: [128]u8 = undefined;
        var pos: usize = 0;
        while (true) : (pos += 1) {
            line[pos] = self.readByte() catch |err|
                {
                std.log.err("{s}", .{@errorName(err)});
                return Error.ReadError;
            };
            if (line[pos] == '\n') {
                if (pos > 0 and line[pos - 1] == '\r') {
                    break;
                } else {
                    return Error.NoCR;
                }
            }
        }
        const len = pos - 1;
        if (len == 0) {
            break;
        }
        const slice = line[0..len];

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
