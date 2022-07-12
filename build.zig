const std = @import("std");
const glfw = @import("./pkgs/glfw/pkg.zig");
const stb = @import("./pkgs/stb/pkg.zig");
const imgui = @import("./pkgs/imgui/pkg.zig");

const gl_pkg = std.build.Pkg{
    .name = "gl",
    .path = std.build.FileSource{ .path = "pkgs/zig-opengl/exports/gl_4v6.zig" },
};

const glo_pkg = std.build.Pkg{
    .name = "glo",
    .path = std.build.FileSource{ .path = "pkgs/glo/src/main.zig" },
    .dependencies = &.{gl_pkg},
};

pub fn build(b: *std.build.Builder) void {
    const allocator = std.testing.allocator;

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zigcell", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    exe.linkLibC();
    exe.linkLibCpp();
    _ = glfw.addTo(allocator, exe, "pkgs/glfw");
    exe.addPackage(gl_pkg);
    exe.addPackage(glo_pkg);
    _ = stb.addTo(allocator, exe, "pkgs/stb");
    const imgui_pkg = imgui.addTo(allocator, exe, "pkgs/imgui");

    const imutil_pkg = std.build.Pkg{
        .name = "imutil",
        .path = std.build.FileSource{ .path = "pkgs/imutil/src/main.zig" },
        .dependencies = &.{gl_pkg, glo_pkg, imgui_pkg},
    };
    exe.addPackage(imutil_pkg);

    const zls_pkg = std.build.Pkg{
        .name = "zls",
        .path = std.build.FileSource{ .path = "pkgs/zls/src/main.zig" },
        .dependencies = &.{},
    };
    exe.addPackage(zls_pkg);

    const tokentree_pkg = std.build.Pkg{
        .name = "tokentree",
        .path = std.build.FileSource{ .path = "pkgs/tokentree/src/main.zig" },
        .dependencies = &.{},
    };
    exe.addPackage(tokentree_pkg);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
