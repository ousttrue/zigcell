const std = @import("std");
const Transport = @import("./Transport.zig");
const TypeEraser = @import("util").TypeEraser;
const Self = @This();

reader: std.fs.File.Reader,
writer: std.fs.File.Writer,

pub const Error = error{
    NoCR,
};

pub fn init() Self {
    return Self{
        .reader = std.io.getStdIn().reader(),
        .writer = std.io.getStdOut().writer(),
    };
}

pub fn readUntilCRLF(self: *Self, buffer: []u8) !usize {
    const slice = try self.reader.readUntilDelimiter(buffer, '\n');
    if (slice.len > 0 and slice[slice.len - 1] == '\r') {
        return slice.len - 1;
    } else {
        return Error.NoCR;
    }
}

pub fn read(self: *Self, buffer: []u8) !void {
    try self.reader.readNoEof(buffer);
}

pub fn write(self: *Self, buffer: []const u8) !void {
    const size = try self.writer.write(buffer);
    std.debug.assert(size == buffer.len);
}

pub fn transport(self: *Self) Transport {
    return Transport{
        .ptr = self,
        .readUntilCRLFFn = TypeEraser(Self, "readUntilCRLF").call,
        .readFn = TypeEraser(Self, "read").call,
        .writeFn = TypeEraser(Self, "write").call,
    };
}
