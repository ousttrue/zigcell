const std = @import("std");
const imutil = @import("imutil");
const Dispatcher = @import("lsp").Dispatcher;
const Self = @This();
const Transport = @import("./Transport.zig");
const Input = @import("./Input.zig");

const RpcError = error{
    MethodNotFound,
    InternalError,
};

running: bool = true,
allocator: std.mem.Allocator,
thread: std.Thread,
last_input: ?Input = null,
last_err: ?anyerror = null,

pub fn new(allocator: std.mem.Allocator, transport: *Transport, dispatcher: *Dispatcher) !*Self {
    var self = try allocator.create(Self);
    self.* = Self{
        .allocator = allocator,
        .thread = try std.Thread.spawn(.{}, startReader, .{ self, transport, dispatcher }),
    };
    return self;
}

pub fn delete(self: *Self) void {
    self.running = false;

    // self.thread.join();
    if (self.last_input) |*input| {
        input.deinit();
    }
    self.allocator.destroy(self);
}

fn startReader(self: *Self, transport: *Transport, dispatcher: *Dispatcher) void {
    var json_parser = std.json.Parser.init(self.allocator, false);
    defer json_parser.deinit();

    while (self.running) {
        json_parser.reset();
        if (Input.init(self.allocator, transport, &json_parser)) |input| {

            // debug
            if (self.last_input) |*last_input| {
                last_input.deinit();
            }
            self.last_err = null;
            self.last_input = input;

            // disptach
            if (input.getId()) |id| {
                if (input.getMethod()) |method| {
                    // request
                    const bytes = dispatcher.dispatchRequest(id, method, input.getParams());
                    transport.send(bytes) catch |err|
                    {
                        self.last_err = err;
                        break;
                    };
                } else {
                    // response
                    @panic("jsonrpc response is not implemented(not send request)");
                }
            } else {
                if (input.getMethod()) |method| {
                    // notify
                    dispatcher.dispatchNotify(method, input.getParams());
                } else {
                    // invalid
                    // input.send(lsp.Response.createParseError());
                }
            }
        } else |err| {
            // shutdown
            self.last_input = null;
            self.last_err = err;
            break;
        }
    }
}
