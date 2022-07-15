const std = @import("std");
const imutil = @import("imutil");
const Self = @This();
const Transport = @import("./Transport.zig");

running: bool = true,
allocator: std.mem.Allocator,
transport: *Transport,
thread: std.Thread,
status: std.ArrayList(u8),

pub fn new(allocator: std.mem.Allocator, transport: *Transport) !*Self {
    var self = try allocator.create(Self);
    self.* = Self{
        .allocator = allocator,
        .transport = transport,
        .thread = try std.Thread.spawn(.{}, startReader, .{self}),
        .status = std.ArrayList(u8).init(allocator),
    };

    return self;
}

pub fn delete(self: *Self) void {
    self.status.deinit();
    self.running = false;
    // self.thread.join();
    self.allocator.destroy(self);
}

pub fn getStatusText(self: *Self) []const u8 {
    return self.status.items;
}

fn pushStatus(self: *Self, buffer: []const u8) void {
    self.status.appendSlice(buffer) catch unreachable;
}

const CONTENT_LENGTH = "Content-Length: ";

fn startReader(self: *Self) void {

    while (self.running) {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();

        const allocator = arena.allocator();

        // read or timeout
        var content_length: usize = 0;
        var i: u32 = 0;
        var buffer: [1024]u8 = undefined;
        while (true) : (i += 1) {
            const len = self.transport.readUntilCRLF(&buffer) catch unreachable;
            if (len == 0) {
                break;
            }
            if (i == 0) {
                // clear
                self.status.resize(0) catch unreachable;
            }
            const slice = buffer[0..len];
            self.pushStatus(slice);

            // Content-Type: ...\r\n
            // Content-Length: 1234\r\n
            if (std.mem.startsWith(u8, slice, CONTENT_LENGTH)) {
                content_length = std.fmt.parseInt(usize, slice[CONTENT_LENGTH.len..], 10) catch unreachable;
            }
        }

        // receive message
        var body = allocator.alloc(u8, content_length) catch unreachable;
        self.transport.read(body) catch unreachable;

        self.pushStatus(body);
        // dispatch
    }
}
