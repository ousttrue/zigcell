const std = @import("std");
const Self = @This();
const response = @import("./response.zig");
const Response = response.Response;

const RequestProto = fn (id: i64, params: ?std.json.Value) anyerror!Response;
const NotifyProto = fn (params: ?std.json.Value) anyerror!void;

request_map: std.StringHashMap(RequestProto),
notify_map: std.StringHashMap(NotifyProto),

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .request_map = std.StringHashMap(RequestProto).init(allocator),
        .notify_map = std.StringHashMap(NotifyProto).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.request_map.deinit();
    self.notify_map.deinit();
}

pub fn dispatchRequest(self: *Self, id: i64, method: []const u8, params: ?std.json.Value) Response {
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
