const std = @import("std");
const AstContext = @import("./ast_context.zig").AstContext;

pub const SimpleVar = struct {
    const Self = @This();

    var_const: []const u8,
    name: []const u8,

    pub fn init(var_const: []const u8, name: []const u8) Self {
        return Self{
            .var_const = var_const,
            .name = name,
        };
    }

    pub fn debugPrint(self: Self) void {
        std.debug.print("{s} {s} = ", .{ self.var_const, self.name });
    }
};

pub const Function = struct {
    const Self = @This();
    pub fn debugPrint(self: Self) void {
        _ = self;
        std.debug.print("function", .{});
    }
};

pub const Decl = union(enum) {
    const Self = @This();
    simple_var: SimpleVar,
    function: Function,

    pub fn init(context: *AstContext, idx: u32) Self {
        const tree = context.tree;
        // const data = tree.nodes.items(.data);
        const tag = tree.nodes.items(.tag);
        const node_tag = tag[idx];
        switch (node_tag) {
            .simple_var_decl => {
                const tokens = context.getNodeTokens(idx);
                return Self{ .simple_var = SimpleVar.init(
                    context.getTokenText(tokens[0]),
                    context.getTokenText(tokens[1]),
                ) };
            },
            .fn_decl => {
                return Self{ .function = .{} };
            },
            else => unreachable,
        }
    }

    pub fn debugPrint(self: Self) void {
        switch (self) {
            .simple_var => |simple_var| simple_var.debugPrint(),
            .function => |function| function.debugPrint(),
        }
    }
};
