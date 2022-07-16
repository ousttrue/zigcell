const std = @import("std");
const Transport = @import("./Transport.zig");
const Self = @This();
const CONTENT_LENGTH = "Content-Length: ";
const CONTENT_TYPE = "Content-Type: ";

allocator: std.mem.Allocator,
content_length: u32,
content_type: [64]u8 = undefined,
body: []const u8,
tree: std.json.ValueTree = null,

pub const MessageError = error{
    UnknownHeader,
    NoContentLength,
};

/// read or timeout
pub fn init(allocator: std.mem.Allocator, transport: *Transport, json_parser: *std.json.Parser) !Self {
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

    var body = try allocator.alloc(u8, content_length);
    errdefer allocator.free(body);
    try transport.read(body);

    const tree = try json_parser.parse(body);

    return Self{
        .allocator = allocator,
        .content_length = content_length,
        .body = body,
        .tree = tree,
    };
}

pub fn deinit(self: *Self) void {
    self.tree.deinit();
    self.allocator.free(self.body);
}

pub fn getId(self: Self) ?i64 {
    const id = self.tree.root.Object.get("id") orelse return null;
    return switch (id) {
        .Integer => |value| value,
        else => null,
    };
}

pub fn getMethod(self: Self) ?[]const u8 {
    const method = self.tree.root.Object.get("method") orelse return null;
    return switch (method) {
        .String => |value| value,
        else => null,
    };
}

pub fn getParams(self: Self) ?std.json.Value {
    return self.tree.root.Object.get("params");
}
