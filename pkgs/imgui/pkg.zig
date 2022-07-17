const std = @import("std");
const Pkg = std.build.Pkg;
const FileSource = std.build.FileSource;
const LibExeObjStep = std.build.LibExeObjStep;

fn concat(allocator: std.mem.Allocator, lhs: []const u8, rhs: []const u8) []const u8 {
    if (allocator.alloc(u8, lhs.len + rhs.len)) |buf| {
        for (lhs) |c, i| {
            buf[i] = c;
        }
        for (rhs) |c, i| {
            buf[i + lhs.len] = c;
        }
        return buf;
    } else |_| {
        @panic("alloc");
    }
}

const SOURCES = [_][]const u8{
    "/_external/imgui/imgui.cpp",
    "/_external/imgui/imgui_draw.cpp",
    "/_external/imgui/imgui_widgets.cpp",
    "/_external/imgui/imgui_tables.cpp",
    "/_external/imgui/imgui_demo.cpp",
    "/_external/imgui/backends/imgui_impl_glfw.cpp",
    "/_external/imgui/backends/imgui_impl_opengl3.cpp",
    "/src/imvec2_byvalue.cpp",
    "/src/internal.cpp",
};

pub fn addTo(allocator: std.mem.Allocator, exe: *LibExeObjStep, relativePath: []const u8) Pkg {
    const pkg = Pkg{
        .name = "imgui",
        .source = FileSource{ .path = concat(allocator, relativePath, "/src/main.zig") },
    };
    exe.addPackage(pkg);
    exe.addIncludeDir(concat(allocator, relativePath, "/_external/imgui"));
    for (SOURCES) |src| {
        exe.addCSourceFiles(&.{
            concat(allocator, relativePath, src),
        }, &.{});
    }
    return pkg;
}
