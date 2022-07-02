const std = @import("std");
const util = @import("./util.zig");

pub const Document = struct {
    const Self = @This();

    buffer: std.ArrayList(u16),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .buffer = std.ArrayList(u16).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.buffer.deinit();
    }

    pub fn load(self: *Self, src: []const u8) !void {
        try self.buffer.resize(src.len);
        const next = try std.unicode.utf8ToUtf16Le(self.buffer.items, src);
        try self.buffer.resize(next);
        std.log.debug("{}\n", .{next});
    }

    pub fn open(allocator: std.mem.Allocator, path: []const u8) ?Self {
        if (util.readSource(allocator, path)) |src| {
            defer allocator.free(src);
            var self = Self.init(allocator);
            errdefer self.deinit();
            if (self.load(src)) {
                return self;
            } else |err| {
                std.log.err("{s}\n", .{@errorName(err)});
                return null;
            }
        } else |err| {
            std.log.err("{s}\n", .{@errorName(err)});
            return null;
        }
    }
};
