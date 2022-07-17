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
        .name = "glfw",
        .source = FileSource{ .path = concat(allocator, relativePath, "/src/main.zig") },
    };
    exe.addPackage(pkg);
    exe.defineCMacro("_GLFW_WIN32", "1");
    exe.defineCMacro("UNICODE", "1");
    exe.defineCMacro("_UNICODE", "1");
    exe.addIncludeDir(concat(allocator, relativePath, "/_external/glfw/include"));
    // exe.addIncludeDir(concat(allocator, relativePath, "/_external/glfw/src"));
    exe.addCSourceFiles(&.{
        concat(allocator, relativePath, "/_external/glfw/src/context.c"),
        concat(allocator, relativePath, "/_external/glfw/src/init.c"),
        concat(allocator, relativePath, "/_external/glfw/src/input.c"),
        concat(allocator, relativePath, "/_external/glfw/src/monitor.c"),
        concat(allocator, relativePath, "/_external/glfw/src/platform.c"),
        concat(allocator, relativePath, "/_external/glfw/src/vulkan.c"),
        concat(allocator, relativePath, "/_external/glfw/src/window.c"),
        concat(allocator, relativePath, "/_external/glfw/src/egl_context.c"),
        concat(allocator, relativePath, "/_external/glfw/src/osmesa_context.c"),
        concat(allocator, relativePath, "/_external/glfw/src/null_init.c"),
        concat(allocator, relativePath, "/_external/glfw/src/null_monitor.c"),
        concat(allocator, relativePath, "/_external/glfw/src/null_window.c"),
        concat(allocator, relativePath, "/_external/glfw/src/null_joystick.c"),
    }, &.{});
    exe.addCSourceFiles(&.{
        concat(allocator, relativePath, "/_external/glfw/src/win32_module.c"),
        concat(allocator, relativePath, "/_external/glfw/src/win32_time.c"),
        concat(allocator, relativePath, "/_external/glfw/src/win32_thread.c"),
        concat(allocator, relativePath, "/_external/glfw/src/win32_init.c"),
        concat(allocator, relativePath, "/_external/glfw/src/win32_joystick.c"),
        concat(allocator, relativePath, "/_external/glfw/src/win32_monitor.c"),
        concat(allocator, relativePath, "/_external/glfw/src/win32_window.c"),
        concat(allocator, relativePath, "/_external/glfw/src/wgl_context.c"),
    }, &.{});
    exe.linkSystemLibrary("gdi32");
    return pkg;
}
