const std = @import("std");
const Transport = @import("./Transport.zig");
const Self = @This();
const CONTENT_LENGTH = "Content-Length: ";
const CONTENT_TYPE = "Content-Type: ";

content_length: u32,
content_type: [64]u8 = undefined,
body: std.ArrayList(u8),

pub const MessageError = error{
    UnknownHeader,
    NoContentLength,
};

/// read or timeout
pub fn init(allocator: std.mem.Allocator, transport: *Transport) !Self {
    var content_length: u32 = 0;
    var content_type: [128]u8 = undefined;
    while (true) {
        var buffer: [128]u8 = undefined;
        const len = try transport.readUntilCRLF(&buffer);
        if (len == 0) {
            break;
        }
        const slice = buffer[0..len];

        if (std.mem.startsWith(u8, slice, CONTENT_LENGTH)) {
            // Content-Length: 1234\r\n
            content_length = try std.fmt.parseInt(u32, slice[CONTENT_LENGTH.len..], 10);
        } else if (std.mem.startsWith(u8, slice, CONTENT_TYPE)) {
            // Content-Type: ...\r\n
            std.mem.copy(u8, &content_type, slice);
            content_type[slice.len] = 0;
        } else {
            return MessageError.UnknownHeader;
        }
    }

    if (content_length == 0) {
        return MessageError.NoContentLength;
    }

    var self = Self{
        .content_length = content_length,
        .body = std.ArrayList(u8).init(allocator),
    };
    errdefer self.deinit();

    try self.body.resize(content_length);
    try transport.read(self.body.items);
    return self;
}

pub fn deinit(self: *Self) void {
    self.body.deinit();
}
