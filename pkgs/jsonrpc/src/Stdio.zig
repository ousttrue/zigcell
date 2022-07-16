const std = @import("std");
const Self = @This();

reader: std.fs.File.Reader,
writer: std.io.BufferedWriter(4096, std.fs.File.Writer),

pub const Error = error{
    NoCR,
};

pub fn init() Self {
    return Self{
        .reader = std.io.getStdIn().reader(),
        .writer = std.io.bufferedWriter(std.io.getStdOut().writer()),
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
