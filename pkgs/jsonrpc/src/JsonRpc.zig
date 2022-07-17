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
last_err: ?Transport.Error = null,

pub fn new(allocator: std.mem.Allocator, transport: Transport, dispatcher: *Dispatcher) *Self {
    var self = allocator.create(Self) catch unreachable;
    self.* = Self{
        .allocator = allocator,
        .thread = std.Thread.spawn(.{}, startReader, .{ self, transport, dispatcher }) catch unreachable,
    };
    return self;
}

pub fn delete(self: *Self) void {
    self.running = false;

    // self.thread.join();
    if (self.last_input) |*last_input| {
        last_input.deinit();
    }
    self.allocator.destroy(self);
}

fn setInput(self: *Self, input: Input) void {
    if (self.last_input) |*last_input| {
        last_input.deinit();
    }
    self.last_input = input;
    self.last_err = null;
}

fn setError(self: *Self, err: Transport.Error) void {
    if (self.last_input) |*last_input| {
        last_input.deinit();
    }
    self.last_input = null;
    self.last_err = err;
}

fn startReader(self: *Self, transport: Transport, dispatcher: *Dispatcher) void {
    var json_parser = std.json.Parser.init(self.allocator, false);
    defer json_parser.deinit();

    std.log.info("start...", .{});

    while (self.running) {
        if (transport.readNextAlloc(self.allocator)) |body| {
            json_parser.reset();
            if (json_parser.parse(body)) |tree| {
                self.processInput(transport, dispatcher, Input.init(self.allocator, body, tree));
            } else |err| {
                std.log.err("{s}", .{@errorName(err)});
                self.allocator.free(body);
            }
        } else |err| {
            // shutdown
            self.last_input = null;
            self.last_err = err;
            break;
        }
    }

    std.log.info("end", .{});
}

fn processInput(self: *Self, transport: Transport, dispatcher: *Dispatcher, input: Input) void {
    self.setInput(input);

    // disptach
    if (input.getId()) |id| {
        if (input.getMethod()) |method| {
            // request
            const bytes = dispatcher.dispatchRequest(id, method, input.getParams());
            transport.send(bytes) catch |err| {
                std.log.err("{s}", .{@errorName(err)});
            };
        } else {
            // response
            @panic("jsonrpc response is not implemented(not send request)");
        }
    } else {
        if (input.getMethod()) |method| {
            // notify
            _ = method;
            // dispatcher.dispatchNotify(method, input.getParams());
        } else {
            // invalid
            // input.send(lsp.Response.createParseError());
        }
    }
}
