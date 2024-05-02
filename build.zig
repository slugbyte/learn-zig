const std = @import("std");

const testFiles: [14][]const u8 = .{
    "src/array_00_contains_duplicate.zig",
    "src/array_01_is_anagram.zig",
    "src/array_02_two_sum.zig",
    "src/array_04_freq_k_elements.zig",
    "src/array_05_product_except_self.zig",
    "src/array_07_encode_decode_string_list.zig",
    "src/array_08_binary_search.zig",
    "src/array_09_crystal_ball_drop.zig",
    "src/fs_read_file.zig",
    "src/fs_read_file_lines.zig",
    "src/sort_00_bubble.zig",
    "src/defer.zig",
    "src/comptime_enum.zig",
    "src/comptime_union.zig",
};

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_step = b.step("test", "Run unit tests");
    for (testFiles) |file_name| {
        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = file_name },
            .target = target,
            .optimize = optimize,
        });
        const run_unit_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_unit_tests.step);
    }

    // deps
    const zgl = b.dependency("zgl", .{
        .target = target,
        .optimize = optimize,
    });
    const glfw = b.dependency("mach-glfw", .{
        .target = target,
        .optimize = optimize,
    });

    // window
    const exe_window = b.addExecutable(.{
        .name = "window",
        .root_source_file = .{ .path = "./src/window.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe_window.root_module.addImport("gl", zgl.module("zgl"));
    exe_window.root_module.addImport("glfw", glfw.module("mach-glfw"));
    exe_window.linkFramework("OpenGL");
    exe_window.addIncludePath(.{ .path = "/opt/homebrew/include" });
    exe_window.addLibraryPath(.{ .path = "/opt/homebrew/lib" });
    b.installArtifact(exe_window);
    const window_run_cmd = b.addRunArtifact(exe_window);
    window_run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        window_run_cmd.addArgs(args);
    }
    const run_step = b.step("run_window", "Run window example");
    run_step.dependOn(&window_run_cmd.step);
}
