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

pub fn addTo(allocator: std.mem.Allocator, exe: *LibExeObjStep, relativePath: []const u8) Pkg {
    // _external/glfw/_external/glfw/src/CMakeLists.txt
    const pkg = Pkg{
        .name = "stb",
        .source = FileSource{ .path = concat(allocator, relativePath, "/src/main.zig") },
    };
    exe.addPackage(pkg);
    exe.addIncludeDir(concat(allocator, relativePath, "/_external"));
    exe.addCSourceFiles(&.{
        concat(allocator, relativePath, "/src/main.cpp"),
    }, &.{});
    return pkg;
}
