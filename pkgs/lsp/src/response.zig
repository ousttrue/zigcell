const initialize = @import("./initialize.zig");

/// Params of a response (result)
pub const ResponseResult = union(enum) {
    initialize: initialize.InitializeResult,
};

pub const ResponseError = struct {
    code: i32,
    message: []const u8,

    // Defined by JSON-RPC
    pub fn createParseError() ResponseError {
        return .{ .code = -32700, .message = "ParseError" };
    }
    pub fn createInvalidRequest() ResponseError {
        return .{ .code = -32600, .message = "InvalidRequest" };
    }
    pub fn createMethodNotFound() ResponseError {
        return .{ .code = -32601, .message = "MethodNotFound" };
    }
    pub fn createInvalidParams() ResponseError {
        return .{ .code = -32602, .message = "InvalidParams" };
    }
    pub fn createInternalError() ResponseError {
        return .{ .code = -32603, .message = "InternalError" };
    }
};

pub const Response = struct {
    jsonrpc: []const u8 = "2.0",
    id: ?i64,
    result: ?ResponseResult = null,
    @"error": ?ResponseError = null,
};
