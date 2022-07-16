const std = @import("std");
const Self = @This();
const response = @import("./response.zig");
const Response = response.Response;
const ResponseResult = response.ResponseResult;
const ResponseError = response.ResponseError;
const TypeEraser = @import("./type_eraser.zig").TypeEraser;

pub const DispatchError = error{
    InvalidParams,
    InternalError,
    NotFound,
};

pub const RequestCall = struct {
    const RequestProto = fn (self: *anyopaque, params: ?std.json.Value) anyerror!ResponseResult;
    ptr: *anyopaque,
    call: RequestProto,
    pub fn create(p: anytype, comptime method: []const u8) RequestCall {
        const T = @TypeOf(p.*);
        return RequestCall{
            .ptr = p,
            .call = TypeEraser(T, method).call,
        };
    }
    pub fn request(self: *RequestCall, params: ?std.json.Value) anyerror!ResponseResult {
        return self.call(self.ptr, params);
    }
};

// const NotifyProto = fn (params: ?std.json.Value) anyerror!void;

request_map: std.StringHashMap(RequestCall),
// notify_map: std.StringHashMap(NotifyProto),
to_json_buffer: std.ArrayList(u8),

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .request_map = std.StringHashMap(RequestCall).init(allocator),
        // .notify_map = std.StringHashMap(NotifyProto).init(allocator),
        .to_json_buffer = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.to_json_buffer.deinit();
    self.request_map.deinit();
    // self.notify_map.deinit();
}

pub fn registerRequest(self: *Self, p: anytype, comptime method: []const u8) void {
    // const T = struct {
    //     pub fn request(id: i64, params: ?std.json.Value) anyerror!Response {
    //         if (params) |req| {
    //             return try callback(id, req);
    //         } else {
    //             return try callback(id, .{});
    //         }
    //     }
    // };
    self.request_map.put(method, RequestCall.create(p, method)) catch @panic("put");
}

// pub fn registerNotify(self: *Self, method: []const u8, comptime ParamType: type, comptime callback: fn (req: ParamType) anyerror!void) void {
//     const T = struct {
//         pub fn notify(params: ?std.json.Value) anyerror!void {
//             if (params) |req| {
//                 try callback(req);
//             } else |_| {
//                 try callback(.{});
//             }
//         }
//     };
//     self.notify_map.put(method, T.notify) catch @panic("put");
// }

pub fn dispatchRequest(self: *Self, id: i64, method: []const u8, params: ?std.json.Value) []const u8 {
    self.to_json_buffer.resize(0) catch unreachable;
    const res = if (self._dispatchRequest(method, params)) |result|
        Response{
            .id = id,
            .result = result,
        }
    else |err|
        Response{
            .id = id,
            .@"error" = switch (err) {
                DispatchError.NotFound => ResponseError.createMethodNotFound(),
                else => ResponseError.createInternalError(),
            },
        };
    std.json.stringify(res, .{}, self.to_json_buffer.writer()) catch @panic("stringify");
    return self.to_json_buffer.items;
}

fn _dispatchRequest(self: *Self, method: []const u8, params: ?std.json.Value) DispatchError!ResponseResult {
    if (self.request_map.get(method)) |*handler| {
        if (handler.request(params)) |res| {
            return res;
        } else |_| {
            return DispatchError.InternalError;
        }
    } else {
        return DispatchError.NotFound;
    }
}

// pub fn dispatchNotify(self: *Self, method: []const u8, params: ?std.json.Value) void {
//     if (self.notify_map.get(method)) |handler| {
//         if (handler(params)) {} else |_| {}
//     } else {
//         //
//     }
// }
