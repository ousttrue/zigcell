const std = @import("std");
pub const LISTEN_PORT: u16 = 51764;

pub fn startServer(alive: *bool, server: *std.net.StreamServer, queue: *std.atomic.Queue(std.net.StreamServer.Connection)) void {
    const addr = std.net.Address.parseIp("127.0.0.1", LISTEN_PORT) catch unreachable;
    server.listen(addr) catch unreachable;

    const STATIC = struct {
        var node: std.atomic.Queue(std.net.StreamServer.Connection).Node = undefined;
    };

    while (alive.*) {
        if (server.accept()) |conn| {
            STATIC.node = .{
                .data = conn,
                .next = undefined,
                .prev = undefined,
            };
            queue.put(&STATIC.node);
        } else |_| {
            // std.log.err("{s}", @errorName(err));
            break;
        }
    }
}
