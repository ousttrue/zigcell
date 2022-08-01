const std = @import("std");
const imgui = @import("imgui");
const imutil = @import("imutil");
const ast_context = @import("./ast_context.zig");
const AstNode = @import("./AstNode.zig");
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

fn showTree(self: *Self, ast: *AstContext, idx: u32) void {
    imgui.TableNextRow(.{});

    // 0
    var flags = @enumToInt(imgui.ImGuiTreeNodeFlags._OpenOnArrow) | @enumToInt(imgui.ImGuiTreeNodeFlags._OpenOnDoubleClick)
    // | @enumToInt(imgui.ImGuiTreeNodeFlags._SpanAvailWidth)
    // | @enumToInt(imgui.ImGuiTreeNodeFlags._DefaultOpen)
    ;
    var tmp: [2]std.zig.Ast.Node.Index = undefined;
    var children_array = AstNode.ChildrenArray.init(ast.allocator, idx, AstNode.getChildren(ast.tree, idx, &tmp));
    defer children_array.deinit();
    const children = children_array.array.items;
    if (children.len == 0) {
        flags |= @enumToInt(imgui.ImGuiTreeNodeFlags._Leaf);
    }

    _ = imgui.TableNextColumn();
    imgui.SetNextItemOpen(if (self.selected_node) |selected| ast.findAncestor(selected, idx) else false, .{});
    // imgui.SetNextItemOpen(true, .{ .cond = @enumToInt(imgui.ImGuiCond._FirstUseEver) });
    const opend = imgui.TreeNodeEx(imutil.localFormat("{}", .{idx}), .{ .flags = flags });

    // 1
    _ = imgui.TableNextColumn();
    // imgui.TextUnformatted(@tagName(ast.getNodeTag(idx)), .{});
    if (imgui.Selectable(imutil.localFormat("{s}##{}", .{ @tagName(ast.getNodeTag(idx)), idx }), .{
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
        for (children) |child| {
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
            if (self.screen.layout.current_token) |token_idx| {
                const token = ast.tokens.items[token_idx];
                imgui.TextUnformatted(imutil.localFormat("[{}] {s}: {s}", .{
                    token_idx,
                    @tagName(token.tag),
                    ast.getTokenText(token),
                }), .{});
                self.selected_node = ast.tokens_node[token_idx];
            } else {
                imgui.TextUnformatted(imutil.localFormat("no token", .{}), .{});
            }

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
