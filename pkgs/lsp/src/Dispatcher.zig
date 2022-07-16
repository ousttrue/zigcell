const std = @import("std");
const Self = @This();
const Response = @import("./response.zig").Response;

const RequestProto = fn (id: i64, params: ?std.json.Value) anyerror!Response;
const NotifyProto = fn (params: ?std.json.Value) anyerror!void;

request_map: std.StringHashMap(RequestProto),
notify_map: std.StringHashMap(NotifyProto),
to_json_buffer: std.ArrayList(u8),

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .request_map = std.StringHashMap(RequestProto).init(allocator),
        .notify_map = std.StringHashMap(NotifyProto).init(allocator),
        .to_json_buffer = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.to_json_buffer.deinit();
    self.request_map.deinit();
    self.notify_map.deinit();
}

pub fn dispatchRequest(self: *Self, id: i64, method: []const u8, params: ?std.json.Value) []const u8 {
    self.to_json_buffer.resize(0) catch unreachable;
    var response = self._dispatchRequest(id, method, params);
    std.json.stringify(response, .{}, self.to_json_buffer.writer()) catch @panic("stringify");
    return self.to_json_buffer.items;
}

fn _dispatchRequest(self: *Self, id: i64, method: []const u8, params: ?std.json.Value) Response {
    if (self.request_map.get(method)) |handler| {
        if (handler(id, params)) |res| {
            return res;
        } else |_| {
            return Response.createInternalError(id);
        }
    } else {
        return Response.createMethodNotFound(id);
    }
}

pub fn dispatchNotify(self: *Self, method: []const u8, params: ?std.json.Value) void {
    if (self.notify_map.get(method)) |handler| {
        if (handler(params)) {} else |_| {}
    } else {
        //
    }
}
