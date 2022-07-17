const std = @import("std");
const jsonrpc = @import("jsonrpc");

pub fn main() anyerror!void {
    const address = std.net.Address.parseIp("127.0.0.1", 51764) catch unreachable;
    const stream = try std.net.tcpConnectToAddress(address);
    defer stream.close();
    var tcp = jsonrpc.Tcp.init(stream);
    var transport = tcp.transport();
    const data =
        \\{
        \\}
    ;
    try transport.send(data);

    if (transport.readNextAlloc(std.testing.allocator)) |body| {
        _ = body;
    } else |_| {}
}
