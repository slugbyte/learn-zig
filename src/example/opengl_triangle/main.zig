const std = @import("std");
const gl = @import("gl");
const glfw = @import("glfw");

const SHADER_VERTEX = @embedFile("./shader.vertex.glsl");
const SHADER_FRAGMENT = @embedFile("./shader.fragment.glsl");

var gl_procs: gl.ProcTable = undefined;

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw error code ({}): {s}\n", .{ error_code, description });
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);

    if (!glfw.init(.{})) {
        std.log.err("failed to init glfw: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // init glfw with opengl 4.1
    // use core profile so we only have access to modern functions
    // TODO: what is forward_compat?
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

    // introduce window to current context
    // TODO: whta is a context?
    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    // load opengl functions
    if (!gl_procs.init(glfw.getProcAddress)) {
        std.log.err("failed to load gl functions", .{});
        std.process.exit(1);
    }
    gl.makeProcTableCurrent(&gl_procs);
    defer gl.makeProcTableCurrent(null);

    // set the size of the opengl viewport to the size of the window
    gl.Viewport(0, 0, 648, 480);

    // compile the vertex shader
    std.debug.print("{s}\n", .{SHADER_VERTEX});
    const shader_vertext_id = gl.CreateShader(gl.VERTEX_SHADER);
    gl.ShaderSource(shader_vertext_id, 1, @ptrCast(&SHADER_VERTEX), null);
    gl.CompileShader(shader_vertext_id);

    // compile the fragment shader
    std.debug.print("{s}\n", .{SHADER_FRAGMENT});
    const shader_fragment_id = gl.CreateShader(gl.FRAGMENT_SHADER);
    gl.ShaderSource(shader_fragment_id, 1, @ptrCast(&SHADER_FRAGMENT), null);
    gl.CompileShader(shader_fragment_id);

    // compile the link the shader program shader
    const shader_program_id = gl.CreateProgram();
    gl.AttachShader(shader_program_id, shader_vertext_id);
    gl.AttachShader(shader_program_id, shader_fragment_id);
    gl.LinkProgram(shader_program_id);
    // after program is linked shaders can be deleted
    gl.DeleteShader(shader_vertext_id);
    gl.DeleteShader(shader_fragment_id);
    defer gl.DeleteProgram(shader_program_id);

    const triangle = [9]gl.float{
        -0.5, 0.5,  0.0,
        0.5,  0.5,  0.0,
        0.0,  -0.5, 0.0,
    };

    // create a vao and vbo
    var vao: gl.uint = undefined;
    var vbo: gl.uint = undefined;
    gl.GenVertexArrays(1, @ptrCast(&vao));
    gl.GenBuffers(1, @ptrCast(&vbo));

    // select vao
    gl.BindVertexArray(vao);
    // select vbo
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    // pass triangle data into vbo
    gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(triangle)), &triangle, gl.STATIC_DRAW);

    // confire te vertex attribute so opengl knows how to interperate the vbo
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(gl.float), 0);
    // enable the vertex atrib array
    gl.EnableVertexAttribArray(0);

    // deselectt teh vao and vbo
    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindVertexArray(0);

    while (!window.shouldClose()) {
        // clear backgroudn colors
        gl.ClearColor(0.22, 0.22, 0.22, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT);

        // select shader programe
        gl.UseProgram(shader_program_id);
        // select triangle vertex array
        gl.BindVertexArray(vao);
        // tell gl to draw 3 triangle vertecies
        gl.DrawArrays(gl.TRIANGLES, 0, 3);

        //
        window.swapBuffers();
        glfw.pollEvents();
    }
}
