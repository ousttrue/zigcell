const std = @import("std");
const imgui = @import("imgui");
// const LineLayout = @import("./LineLayout.zig");
const ast_context = @import("./ast_context.zig");
const AstContext = ast_context.AstContext;
const Screen = @import("./screen.zig").Screen;
const Self = @This();

allocator: std.mem.Allocator,
screen: *Screen,

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

fn showTree(ast: *AstContext, idx: u32) void {
    var buf: [1024]u8 = undefined;
    const label = std.fmt.bufPrint(&buf, "{}", .{idx}) catch unreachable;
    buf[label.len] = 0;
    imgui.TableNextRow(.{});

    // 0
    _ = imgui.TableNextColumn();
    const opend = imgui.TreeNode(@ptrCast([*:0]const u8, &buf[0]));

    // 1
    _ = imgui.TableNextColumn();
    imgui.TextUnformatted(@tagName(ast.getNodeTag(idx)), .{});

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
            showTree(ast, child);
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
            if (imgui.BeginTable("ast table", 3, .{})) {
                // header
                imgui.TableSetupColumn("node idx", .{});
                imgui.TableSetupColumn("node tag", .{});
                imgui.TableSetupColumn("main token", .{});
                imgui.TableHeadersRow();

                // body
                for (ast.tree.rootDecls()) |decl| {
                    showTree(ast, decl);
                }

                imgui.EndTable();
            }
        }
    }
    imgui.End();
}
