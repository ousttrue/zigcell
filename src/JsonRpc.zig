const std = @import("std");
const Self = @This();
const Transport = @import("./Transport.zig");

running: bool = true,
allocator: std.mem.Allocator,
transport: *Transport,
thread: std.Thread,
status: [1024 * 8]u8 = undefined,
status_len: usize = 0,

pub fn new(allocator: std.mem.Allocator, transport: *Transport) !*Self {
    var self = try allocator.create(Self);
    self.* = Self{
        .allocator = allocator,
        .transport = transport,
        .thread = try std.Thread.spawn(.{}, startReader, .{self}),
    };
    self.status[0] = 0;

    return self;
}

pub fn delete(self: *Self) void {
    self.running = false;
    // self.thread.join();
    self.allocator.destroy(self);
}

pub fn getStatusText(self: *Self) []const u8 {
    self.status[self.status_len] = 0;
    return self.status[0..self.status_len :0];
}

fn startReader(self: *Self) void {
    var arena = std.heap.ArenaAllocator.init(self.allocator);

    while (self.running) {
        // const allocator = arena.allocator();
        defer arena.deinit();

        // read or timeout
        const line = self.transport.readLine() catch unreachable;
        _ = line;

        std.mem.copy(u8, &self.status, line);
        self.status_len = line.len;

        // Content-Type: ...\r\n
        // Content-Length: 1234\r\n

        // receive message

        // dispatch
    }
}
