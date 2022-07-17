const std = @import("std");
const tcp_server = @import("./tcp_server.zig");
const jsonrpc = @import("jsonrpc");

fn connect(allocator: std.mem.Allocator, src: jsonrpc.Transport, dst: jsonrpc.Transport) void {
    _ = dst;
    var json_parser = std.json.Parser.init(allocator, false);
    defer json_parser.deinit();

    while (true) {
        if (src.readNextAlloc(allocator)) |content| {
            json_parser.reset();
            if (json_parser.parse(content)) |tree| {
                var input = jsonrpc.Input.init(allocator, content, tree);
                defer input.deinit();
                std.log.err("input: {}", .{input.content.len});
                dst.send(input.content) catch @panic("send");
            } else |err| {
                std.log.err("{s}", .{@errorName(err)});
                allocator.free(content);
            }
        } else |err| {
            std.log.err("{s}", .{@errorName(err)});
            @panic("input");
        }
    }
}

pub fn main() anyerror!void {
    var gpa0 = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa0.deinit());
    var gpa1 = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa1.deinit());

    // stdio
    var stdio = jsonrpc.Stdio.init();

    // connect to server
    const stream = try std.net.tcpConnectToAddress(tcp_server.address);
    defer stream.close();
    var tcp = jsonrpc.Tcp.init(stream);

    // bind stdio with tcp socket
    var cs = try std.Thread.spawn(.{}, connect, .{ gpa0.allocator(), stdio.transport(), tcp.transport() });
    var sc = try std.Thread.spawn(.{}, connect, .{ gpa1.allocator(), tcp.transport(), stdio.transport() });
    cs.join();
    sc.join();
}
