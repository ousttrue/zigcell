const std = @import("std");
const Node = @import("./node.zig").Node;
const AstContext = @import("./ast_context.zig").AstContext;

pub const Parser = struct {
    const Self = @This();

    context: *AstContext,
    nodes: std.ArrayList(Node),

    pub fn new(allocator: std.mem.Allocator, context: *AstContext) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .context = context,
            .nodes = std.ArrayList(Node).init(allocator),
        };
        return self;
    }

    pub fn delete(self: Self) void {
        self.nodes.deinit();
        self.allocator.destroy(self);
    }

    pub fn parse(allocator: std.mem.Allocator, src: []const u16) !*Self {
        const context = AstContext.new(allocator, src);

        var self = Self.new(allocator, context);

        for (context.tree.rootDecls()) |decl| {
            var node = Node.init(0, &context.tree, decl);
            node.traverse(0);
            self.nodes.append(node) catch unreachable;
        }
        std.debug.print("\n", .{});

        return self;
    }
};
