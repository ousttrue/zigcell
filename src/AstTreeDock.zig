const std = @import("std");
const imgui = @import("imgui");
const ast_context = @import("./ast_context.zig");
const AstContext = ast_context.AstContext;
const Screen = @import("./screen.zig").Screen;
const Self = @This();

allocator: std.mem.Allocator,
screen: *Screen,
selected_node: ?u32 = null,

pub fn new(allocator: std.mem.Allocator, screen: *Screen) *Self {
    var self = allocator.create(Self) catch unreachable;
    self.* = Self{
        .allocator = allocator,
        .screen = screen,
    };
    return self;
}

pub fn delete(self: *Self) void {
    self.allocator.destroy(self);
}

fn localFormat(comptime fmt: []const u8, values: anytype) [*:0]const u8 {
    const S = struct {
        var buf: [1024]u8 = undefined;
    };
    const label = std.fmt.bufPrint(&S.buf, fmt, values) catch unreachable;
    S.buf[label.len] = 0;
    return @ptrCast([*:0]const u8, &S.buf[0]);
}

fn showTree(self: *Self, ast: *AstContext, idx: u32) void {
    imgui.TableNextRow(.{});

    // 0
    var flags = @enumToInt(imgui.ImGuiTreeNodeFlags._OpenOnArrow) | @enumToInt(imgui.ImGuiTreeNodeFlags._OpenOnDoubleClick)
    // | @enumToInt(imgui.ImGuiTreeNodeFlags._SpanAvailWidth)
    ;
    if (ast_context.getChildren(ast.tree, idx).len == 0) {
        flags |= @enumToInt(imgui.ImGuiTreeNodeFlags._Leaf);
    }

    _ = imgui.TableNextColumn();
    const opend = imgui.TreeNodeEx(localFormat("{}", .{idx}), .{ .flags = flags });

    // 1
    _ = imgui.TableNextColumn();
    // imgui.TextUnformatted(@tagName(ast.getNodeTag(idx)), .{});
    if (imgui.Selectable(localFormat("{s}##{}", .{ @tagName(ast.getNodeTag(idx)), idx }), .{
        .selected = if (self.selected_node) |selected_node| selected_node == idx else false,
        .flags = @enumToInt(imgui.ImGuiSelectableFlags._SpanAllColumns) | @enumToInt(imgui.ImGuiSelectableFlags._AllowItemOverlap),
    })) {
        self.selected_node = idx;
    }

    // 2
    _ = imgui.TableNextColumn();
    const token = ast.getMainToken(idx);
    const token_text = ast.getTokenText(token);
    var buffer: [64]u8 = undefined;
    std.mem.copy(u8, &buffer, token_text);
    buffer[token_text.len] = 0;
    imgui.TextUnformatted(@ptrCast([*:0]const u8, &buffer[0]), .{});

    // children
    if (opend) {
        for (ast_context.getChildren(ast.tree, idx)) |child| {
            self.showTree(ast, child);
        }
        imgui.TreePop();
    }
}

pub fn show(self: *Self, p_open: *bool) void {
    if (!p_open.*) {
        return;
    }

    if (imgui.Begin("ast tree", .{ .p_open = p_open })) {
        if (self.screen.ast) |ast| {
            const flags = @enumToInt(imgui.ImGuiTableFlags._Resizable) | @enumToInt(imgui.ImGuiTableFlags._RowBg);
            if (imgui.BeginTable("ast table", 3, .{ .flags = flags })) {
                // header
                imgui.TableSetupColumn("node idx", .{});
                imgui.TableSetupColumn("node tag", .{});
                imgui.TableSetupColumn("main token", .{});
                imgui.TableHeadersRow();

                // body
                for (ast.tree.rootDecls()) |decl| {
                    self.showTree(ast, decl);
                }

                imgui.EndTable();
            }
        }
    }
    imgui.End();
}
