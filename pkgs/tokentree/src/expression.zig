const std = @import("std");
const AstContext = @import("./ast_context.zig").AstContext;
const token_tree = @import("./token_tree.zig");
const Node = token_tree.Node;

pub const BuiltinCallTwo = struct {
    const Self = @This();

    name: []const u8,
    lhs: ?Node,
    rhs: ?Node,

    pub fn init(parent: u32, name: []const u8, context: *AstContext, lhs: u32, rhs: u32) Self {
        const l: ?Node = if (lhs != 0)
            Node.init(parent, context, lhs)
        else
            null;

        const r: ?Node = if (rhs != 0)
            Node.init(parent, context, rhs)
        else
            null;

        return Self{
            .name = name,
            .lhs = l,
            .rhs = r,
        };
    }

    pub fn debugPrint(self: Self) void {
        _ = self;
        if (self.lhs) |lhs| {
            if (self.rhs) |rhs| {
                std.debug.print("{s}({}, {})", .{ self.name, lhs.tag, rhs.tag });
            } else {
                std.debug.print("{s}({})", .{ self.name, lhs.tag });
            }
        } else {
            std.debug.print("{s}()", .{self.name});
        }
    }
};

pub const FieldAccess = struct {
    const Self = @This();

    pub fn debugPrint(self: Self) void {
        _ = self;
        std.debug.print("filed_access", .{});
    }
};

pub const Expression = union(enum) {
    const Self = @This();
    builtin_call_two: BuiltinCallTwo,
    field_access: FieldAccess,

    pub fn init(context: *AstContext, idx: u32) Self {
        const tag = context.tree.nodes.items(.tag);
        const node_tag = tag[idx];
        const data = context.tree.nodes.items(.data);
        const tokens = context.getNodeTokens(idx);
        const b_data = data[idx];
        switch (node_tag) {
            .builtin_call_two => {
                return .{ .builtin_call_two = BuiltinCallTwo.init(
                    idx,
                    context.getTokenText(tokens[0]),
                    context,
                    b_data.lhs,
                    b_data.rhs,
                ) };
            },
            .field_access => {
                return .{ .field_access = .{} };
            },
            else => {
                unreachable;
            },
        }
    }

    pub fn debugPrint(self: Self) void {
        switch (self) {
            .builtin_call_two => |bultin_call_two| {
                bultin_call_two.debugPrint();
            },
            .field_access => |field_access| {
                field_access.debugPrint();
            },
        }
    }
};
