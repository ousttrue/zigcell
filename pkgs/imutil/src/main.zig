const std = @import("std");
const imgui_app = @import("./imgui_app.zig");
const fbo_dock = @import("./fbo_dock.zig");
const dockspace = @import("./dockspace.zig");

pub const ImGuiApp = imgui_app.ImGuiApp;
pub const FboDock = fbo_dock.FboDock;
pub const MouseInput = fbo_dock.MouseInput;
pub const Dock = dockspace.Dock;

pub fn localFormat(comptime fmt: []const u8, values: anytype) [*:0]const u8 {
    const S = struct {
        var buf: [8192]u8 = undefined;
    };
    const label = std.fmt.bufPrint(&S.buf, fmt, values) catch unreachable;
    S.buf[label.len] = 0;
    return @ptrCast([*:0]const u8, &S.buf[0]);
}
