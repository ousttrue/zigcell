const std = @import("std");
const imutil = @import("imutil");
const lsp = @import("lsp");
const Self = @This();
const Transport = @import("./Transport.zig");
const Input = @import("./Input.zig");
const RequestProto = fn (id: i64, params: ?std.json.Value) anyerror!lsp.Response;
const NotifyProto = fn (params: ?std.json.Value) anyerror!void;

const RpcError = error{
    MethodNotFound,
    InternalError,
};

running: bool = true,
allocator: std.mem.Allocator,
thread: std.Thread,
last_input: ?Input = null,
last_err: ?anyerror = null,
request_map: std.StringHashMap(RequestProto),
notify_map: std.StringHashMap(NotifyProto),

pub fn new(allocator: std.mem.Allocator, transport: *Transport) !*Self {
    var self = try allocator.create(Self);
    self.* = Self{
        .allocator = allocator,
        .thread = try std.Thread.spawn(.{}, startReader, .{self, transport}),
        .request_map = std.StringHashMap(RequestProto).init(allocator),
        .notify_map = std.StringHashMap(NotifyProto).init(allocator),
    };

    return self;
}

pub fn delete(self: *Self) void {
    self.running = false;

    // self.thread.join();
    self.request_map.deinit();
    self.notify_map.deinit();
    if (self.last_input) |*input| {
        input.deinit();
    }
    self.allocator.destroy(self);
}

fn startReader(self: *Self, transport: *Transport) void {
    var json_parser = std.json.Parser.init(self.allocator, false);
    defer json_parser.deinit();

    while (self.running) {
        json_parser.reset();
        if (Input.init(self.allocator, transport, &json_parser)) |input| {
            self.dispatch(self.allocator, input, transport);
        } else |err| {
            // shutdown
            self.last_input = null;
            self.last_err = err;
            break;
        }
    }
}

fn dispatch(self: *Self, allocator: std.mem.Allocator, input: Input, transport: *Transport) void {
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
            const response = self.dispatchRequest(id, method, input.getParams());
            transport.sendAlloc(allocator, response);
        } else {
            // response
            @panic("jsonrpc response is not implemented(not send request)");
        }
    } else {
        if (input.getMethod()) |method| {
            // notify
            self.dispatchNotify(method, input.getParams());
        } else {
            // invalid
            // input.send(lsp.Response.createParseError());
        }
    }
}

fn dispatchRequest(self: *Self, id: i64, method: []const u8, params: ?std.json.Value) lsp.Response {
    if (self.request_map.get(method)) |handler| {
        if (handler(id, params)) |res| {
            return res;
        } else |_| {
            return lsp.Response.createInternalError(id);
        }
    } else {
        return lsp.Response.createMethodNotFound(id);
    }
}

fn dispatchNotify(self: *Self, method: []const u8, params: ?std.json.Value) void {
    if (self.notify_map.get(method)) |handler| {
        if (handler(params)) {} else |_| {}
    } else {
        //
    }
}
