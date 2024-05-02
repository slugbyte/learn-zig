const std = @import("std");
const gl = @import("gl");
const glfw = @import("glfw");

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw error code ({}): {s}\n", .{ error_code, description });
}

fn getProcAddress(_: type, symbolName: [:0]const u8) ?gl.binding.FunctionPointer {
    return glfw.getProcAddress(symbolName);
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);

    if (!glfw.init(.{})) {
        std.log.err("failed to init glfw: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    const window_hints: glfw.Window.Hints = .{
        .context_version_major = 4,
        .context_version_minor = 1,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = true,
        .context_debug = true,
    };
    const window = glfw.Window.create(640, 480, "OpenGL Window", null, null, window_hints) orelse {
        std.log.err("failed to create glfw window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    gl.loadExtensions(void, getProcAddress) catch |err| {
        std.log.err("failed to load gl extenstion: {any}", .{err});
        std.process.exit(1);
    };

    while (!window.shouldClose()) {
        window.swapBuffers();
        // input
        // update
        // render
        gl.clearColor(0.92, 0.92, 0.92, 1.0);
        gl.clear(.{ .color = true });
        glfw.pollEvents();
    }
}
