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
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");

    for (testFiles) |file_name| {
        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = file_name },
            .target = target,
            .optimize = optimize,
        });

        // unit_tests.root_module.addAnonymousImport("util", .{
        //     .root_source_file = .{ .path = "src/util.zig" },
        // });

        // unit_tests.linkLibrary(utilLibrary);

        const run_unit_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_unit_tests.step);
    }
    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
}
