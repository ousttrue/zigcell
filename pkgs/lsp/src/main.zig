const initialize = @import("./initialize.zig");

/// Params of a response (result)
pub const ResponseParams = union(enum) {
    initialize: initialize.InitializeResult,
};

pub const ResponseError = struct {
    code: i32,
    message: []const u8,
};

pub const Response = struct {
    jsonrpc: []const u8 = "2.0",
    id: ?i64,
    result: ?ResponseParams = null,
    @"error": ?ResponseError = null,

    // Defined by JSON-RPC
    pub fn createParseError(id: ?i64) Response {
        return .{ .id = id, .@"error" = .{ .code = -32700, .message = "ParseError" } };
    }
    pub fn createInvalidRequest(id: ?i64) Response {
        return .{ .id = id, .@"error" = .{ .code = -32600, .message = "InvalidRequest" } };
    }
    pub fn createMethodNotFound(id: ?i64) Response {
        return .{ .id = id, .@"error" = .{ .code = -32601, .message = "MethodNotFound" } };
    }
    pub fn createInvalidParams(id: ?i64) Response {
        return .{ .id = id, .@"error" = .{ .code = -32602, .message = "InvalidParams" } };
    }
    pub fn createInternalError(id: ?i64) Response {
        return .{ .id = id, .@"error" = .{ .code = -32603, .message = "InternalError" } };
    }
};
