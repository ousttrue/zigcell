const std = @import("std");

pub fn getChildren(children: *std.ArrayList(u32), tree: *const std.zig.Ast, idx: u32) void {
    const tag = tree.nodes.items(.tag);
    const node_tag = tag[idx];
    const data = tree.nodes.items(.data);
    const node_data = data[idx];

    switch (node_tag) {
        .simple_var_decl => {
            const var_decl = tree.simpleVarDecl(idx);
            if (var_decl.ast.type_node != 0) {
                children.append(var_decl.ast.type_node) catch unreachable;
            }
            if (var_decl.ast.init_node != 0) {
                children.append(var_decl.ast.init_node) catch unreachable;
            }
        },
        .fn_decl => {
            // fn_proto
            children.append(node_data.lhs) catch unreachable;

            // body
            children.append(node_data.rhs) catch unreachable;
        },
        .builtin_call_two => {
            if (node_data.lhs != 0) {
                children.append(node_data.lhs) catch unreachable;
            }
            if (node_data.rhs != 0) {
                children.append(node_data.rhs) catch unreachable;
            }
        },
        .field_access => {
            children.append(node_data.lhs) catch unreachable;
        },
        .string_literal => {
            // leaf. no children
        },
        .block, .block_semicolon => {
            for (tree.extra_data[node_data.lhs..node_data.rhs]) |child| {
                children.append(child) catch unreachable;
            }
        },
        .block_two, .block_two_semicolon => {
            if (node_data.lhs != 0) {
                children.append(node_data.lhs) catch unreachable;
            }
            if (node_data.rhs != 0) {
                children.append(node_data.rhs) catch unreachable;
            }
        },
        else => {
            // std.debug.print("unknown node: {s}\n", .{@tagName(node_tag)});
        },
    }
}
