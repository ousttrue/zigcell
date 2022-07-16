const std = @import("std");
const Self = @This();

server: std.net.StreamServer,

pub fn init() Self {
    return Self{
        .server = std.net.StreamServer.init(.{}),
    };
}

pub fn deinit(self: *Self) void {
    self.server.deinit();
}
