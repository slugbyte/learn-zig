const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var test_file_list = std.ArrayList([]const u8).init(allocator);
    defer test_file_list.deinit();

    // language experiments
    test_file_list.append("src/test/lang/comptime_enum.zig") catch unreachable;
    test_file_list.append("src/test/lang/comptime_union.zig") catch unreachable;
    test_file_list.append("src/test/lang/defer_ref_vs_val.zig") catch unreachable;

    // data structures
    test_file_list.append("src/test/data_structure/linked_list.zig") catch unreachable;
    test_file_list.append("src/test/data_structure/iterator.zig") catch unreachable;
    test_file_list.append("src/test/data_structure/auto_destory_stack.zig") catch unreachable;
    test_file_list.append("src/test/data_structure/auto_destroy_queue.zig") catch unreachable;
    test_file_list.append("src/test/data_structure/auto_destroy_array_list.zig") catch unreachable;

    // sorting algorithms
    test_file_list.append("src/test/sort/bubble_sort.zig") catch unreachable;

    // array code challenges
    test_file_list.append("src/test/array/contains_duplicate.zig") catch unreachable;
    test_file_list.append("src/test/array/binary_search.zig") catch unreachable;
    test_file_list.append("src/test/array/freq_k_elements.zig") catch unreachable;
    test_file_list.append("src/test/array/two_sum.zig") catch unreachable;
    test_file_list.append("src/test/array/product_except_self.zig") catch unreachable;
    test_file_list.append("src/test/array/string_list_encode_decode.zig") catch unreachable;
    test_file_list.append("src/test/array/crystal_ball_drop.zig") catch unreachable;
    test_file_list.append("src/test/array/is_valid_anagram.zig") catch unreachable;

    // file system
    test_file_list.append("src/test/file/read_file_data.zig") catch unreachable;
    test_file_list.append("src/test/file/read_file_lines.zig") catch unreachable;
    test_file_list.append("src/test/file/file_crud.zig") catch unreachable;

    // const testFiles: [][]const u8 = .{
    //     // "src/test/array_00_contains_duplicate.zig",
    //     // "src/test/array_01_is_anagram.zig",
    //     // "src/test/array_02_two_sum.zig",
    //     // "src/test/array_04_freq_k_elements.zig",
    //     // "src/test/array_05_product_except_self.zig",
    //     // "src/test/array_07_encode_decode_string_list.zig",
    //     // "src/test/array_08_binary_search.zig",
    //     // "src/test/array_09_crystal_ball_drop.zig",
    //     "src/fs_read_file.zig",
    //     "src/fs_read_file_lines.zig",
    //     "src/sort_00_bubble.zig",
    //     "src/defer.zig",
    //     "src/comptime_enum.zig",
    //     "src/comptime_union.zig",
    // };
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const util = b.addSharedLibrary(.{
        .name = "test-util",
        .root_source_file = .{ .path = "src/test/util.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    for (test_file_list.items) |file_name| {
        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = file_name },
            .target = target,
            .optimize = optimize,
        });
        unit_tests.root_module.addImport("util", &util.root_module);
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

    // clean
    const clean_step = b.step("clean", "remove zig-out and zig-cache");
    const clean_cmd = b.addSystemCommand(&.{ "rm", "-rf", "zig-cache", "zig-out" });
    clean_step.dependOn(&clean_cmd.step);
}
