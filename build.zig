const std = @import("std");

const BuildContext = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    zigglegen: *std.Build.Module,
    mach_glfw: *std.Build.Dependency,
    zigimg: *std.Build.Dependency,
};

const Example = struct {
    name: []const u8,
    description: []const u8,
    root_source_path: []const u8,
};

const TestLoader = struct {
    source_list: std.ArrayList([]const u8),

    pub fn init(allocator: std.mem.Allocator) TestLoader {
        const source_list = std.ArrayList([]const u8).init(allocator);
        return .{
            .source_list = source_list,
        };
    }

    pub fn deinit(self: *TestLoader) void {
        self.source_list.deinit();
    }

    pub fn addTest(self: *TestLoader, comptime root_source_path: []const u8) void {
        self.source_list.append(root_source_path) catch unreachable;
    }
};

// fn createExample(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, comptime example: Example) void {
fn createExample(ctx: BuildContext, comptime example: Example) void {
    const exe = ctx.b.addExecutable(.{
        .name = example.name,
        .root_source_file = .{ .path = example.root_source_path },
        .target = ctx.target,
        .optimize = ctx.optimize,
    });
    ctx.b.installArtifact(exe);
    const run_artifact = ctx.b.addRunArtifact(exe);
    run_artifact.step.dependOn(ctx.b.getInstallStep());
    if (ctx.b.args) |args| {
        run_artifact.addArgs(args);
    }
    const step = ctx.b.step(example.name, example.description);
    step.dependOn(&run_artifact.step);
}

fn createExampleOpenGl(ctx: BuildContext, comptime example: Example) void {
    const exe = ctx.b.addExecutable(.{
        .name = example.name,
        .root_source_file = .{ .path = example.root_source_path },
        .target = ctx.target,
        .optimize = ctx.optimize,
    });
    exe.root_module.addImport("gl", ctx.zigglegen);
    exe.root_module.addImport("glfw", ctx.mach_glfw.module("mach-glfw"));
    exe.root_module.addImport("zigimg", ctx.zigimg.module("zigimg"));
    exe.linkFramework("OpenGL");
    exe.addIncludePath(.{ .path = "/opt/homebrew/include" });
    exe.addLibraryPath(.{ .path = "/opt/homebrew/lib" });
    ctx.b.installArtifact(exe);
    const run_artifact = ctx.b.addRunArtifact(exe);
    run_artifact.step.dependOn(ctx.b.getInstallStep());
    if (ctx.b.args) |args| {
        run_artifact.addArgs(args);
    }
    const step = ctx.b.step(example.name, example.description);
    step.dependOn(&run_artifact.step);
}

pub fn build(b: *std.Build) void {
    // std lib stuff
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // clean step
    const clean_step = b.step("clean", "remove zig-out and zig-cache");
    const clean_cmd = b.addSystemCommand(&.{ "rm", "-rf", "zig-cache", "zig-out" });
    clean_step.dependOn(&clean_cmd.step);

    // deps
    const mach_glfw = b.dependency("mach-glfw", .{
        .target = target,
        .optimize = optimize,
    });

    const zigimg = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });

    const zigglegen = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.1",
        .profile = .core,
        .extensions = &.{ .ARB_clip_control, .NV_scissor_exclusive },
    });

    const ctx: BuildContext = .{
        .b = b,
        .target = target,
        .optimize = optimize,
        .zigglegen = zigglegen,
        .mach_glfw = mach_glfw,
        .zigimg = zigimg,
    };

    // example
    createExample(ctx, .{
        .name = "signal_catch",
        .description = "example exe: catch sigint demo",
        .root_source_path = "./src/example/signal_catch/main.zig",
    });

    createExampleOpenGl(ctx, .{
        .name = "glfw_window",
        .description = "example exe: create a window with glfw",
        .root_source_path = "./src/example/glfw_window/main.zig",
    });

    createExampleOpenGl(ctx, .{
        .name = "opengl_triangle",
        .description = "example exe: create a triagle with opengl",
        .root_source_path = "./src/example/opengl_triangle/main.zig",
    });

    // load tests
    var t = TestLoader.init(allocator);
    defer t.deinit();

    // test language experiments
    t.addTest("src/test/comptime_enum.zig");
    t.addTest("src/test/comptime_union.zig");
    t.addTest("src/test/defer_ref_vs_val.zig");
    t.addTest("src/test/interface_anyopaque.zig");

    // test data structures
    t.addTest("src/test/linked_list.zig");
    t.addTest("src/test/iterator.zig");
    t.addTest("src/test/throttle.zig");
    t.addTest("src/test/debounce.zig");
    t.addTest("src/test/auto_destory_stack.zig");
    t.addTest("src/test/auto_destroy_queue.zig");
    t.addTest("src/test/auto_destroy_array_list.zig");

    // test sorting algorithms
    t.addTest("src/test/bubble_sort.zig");

    // test array code challenges
    t.addTest("src/test/contains_duplicate.zig");
    t.addTest("src/test/binary_search.zig");
    t.addTest("src/test/freq_k_elements.zig");
    t.addTest("src/test/two_sum.zig");
    t.addTest("src/test/product_except_self.zig");
    t.addTest("src/test/string_list_encode_decode.zig");
    t.addTest("src/test/crystal_ball_drop.zig");
    t.addTest("src/test/is_valid_anagram.zig");

    // test file system
    t.addTest("src/test/read_file_data.zig");
    t.addTest("src/test/read_file_lines.zig");
    t.addTest("src/test/file_crud.zig");

    // test librarys
    t.addTest("src/test/zigimg.zig");

    const test_step = b.step("test", "run tests");
    for (t.source_list.items) |file_name| {
        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = file_name },
            .target = target,
            .optimize = optimize,
        });
        unit_tests.root_module.addImport("zigimg", zigimg.module("zigimg"));
        const run_unit_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_unit_tests.step);
    }
}
