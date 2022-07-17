const std = @import("std");
const imgui = @import("imgui");
const imutil = @import("imutil");
const Self = @This();
const JsonRpc = @import("jsonrpc").JsonRpc;

allocator: std.mem.Allocator,
rpc: ?*JsonRpc = null,

pub fn new(allocator: std.mem.Allocator) *Self {
    var self = allocator.create(Self) catch unreachable;
    self.* = Self{
        .allocator = allocator,
    };
    return self;
}

pub fn delete(self: *Self) void {
    self.allocator.destroy(self);
}

fn show_json(self: Self, name: [*:0]const u8, json: std.json.Value) void {
    const is_open = imgui.TreeNode(name);

    switch (json) {
        .Null => {
            imgui.SameLine(.{});
            imgui.TextUnformatted("null", .{});
        },
        .Bool => |value| {
            imgui.SameLine(.{});
            imgui.TextUnformatted(imutil.localFormat("{}", .{value}), .{});
        },
        .Integer => |value| {
            imgui.SameLine(.{});
            imgui.TextUnformatted(imutil.localFormat("{}", .{value}), .{});
        },
        .Float => |value| {
            imgui.SameLine(.{});
            imgui.TextUnformatted(imutil.localFormat("{}", .{value}), .{});
        },
        .NumberString, .String => |value| {
            imgui.SameLine(.{});
            imgui.TextUnformatted(imutil.localFormat("{s}", .{value}), .{});
        },
        .Array => |array| {
            if (is_open) {
                for (array.items) |child, i| {
                    self.show_json(imutil.localFormat("{}", .{i}), child);
                }
            }
        },
        .Object => |object| {
            if (is_open) {
                for (object.keys()) |key| {
                    const child = object.get(key) orelse unreachable;
                    self.show_json(imutil.localFormat("{s}", .{key}), child);
                }
            }
        },
    }

    if (is_open) {
        imgui.TreePop();
    }
}

pub fn show(self: *Self, p_open: *bool) void {
    if (!p_open.*) {
        return;
    }

    if (imgui.Begin("jsonrpc", .{ .p_open = p_open })) {
        if (self.rpc) |rpc| {
            if (rpc.last_err) |err| {
                imgui.TextUnformatted(imutil.localFormat("{s}.{s}", .{ @typeName(@TypeOf(err)), @errorName(err) }), .{});
            }
            if (rpc.last_input) |input| {
                imgui.TextUnformatted(imutil.localFormat("{}", .{input.content.len}), .{});
                self.show_json("root", input.tree.root);
            }
        }
    }
    imgui.End();
}
