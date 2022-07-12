const std = @import("std");
const AstContext = @import("./ast_context.zig").AstContext;
const Expression = @import("./expression.zig").Expression;

pub const SimpleVar = struct {
    const Self = @This();

    var_const: []const u8,
    name: []const u8,
    initialize: ?Expression,

    pub fn init(var_const: []const u8, name: []const u8, initialize: ?Expression) Self {
        return Self{
            .var_const = var_const,
            .name = name,
            .initialize = initialize,
        };
    }

    pub fn debugPrint(self: Self) void {
        std.debug.print("{s} {s}", .{ self.var_const, self.name });
        if (self.initialize) |initialize| {
            std.debug.print(" = ", .{});
            initialize.debugPrint();
        }
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
        const tag = tree.nodes.items(.tag);
        const node_tag = tag[idx];
        switch (node_tag) {
            .simple_var_decl => {
                const tokens = context.getNodeTokens(idx);
                const var_decl = tree.simpleVarDecl(idx);
                return Self{ .simple_var = SimpleVar.init(
                    context.getTokenText(tokens[0]),
                    context.getTokenText(tokens[1]),
                    if (var_decl.ast.init_node != 0) Expression.init(context, var_decl.ast.init_node) else null,
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
