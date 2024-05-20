const std = @import("std");
const sdl = @import("sdl");
const gl = @import("zgl");
const c = @import("c.zig");

var quit = false;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    try sdl.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer sdl.quit();

    // TODO: setAttributes?
    try sdl.gl.setAttribute(.{ .context_major_version = 3 });
    try sdl.gl.setAttribute(.{ .context_minor_version = 3 });
    try sdl.gl.setAttribute(.{ .context_profile_mask = .core });
    try sdl.gl.setAttribute(.{ .doublebuffer = true });

    const window = try sdl.createWindow(
        "SDL.zig Basic Demo",
        .{ .centered = {} },
        .{ .centered = {} },
        640,
        480,
        .{ .vis = .shown, .context = .opengl },
    );
    defer window.destroy();

    // TODO: make this window.createContext()
    const context = try sdl.gl.createContext(window);

    // TODO: maybe make this context.makeCurrent(). is it sensible to have one context attached to multiple windows?
    try sdl.gl.makeCurrent(context, window);

    // must be called after the context is current
    // SEE: https://wiki.libsdl.org/SDL2/SDL_GL_GetProcAddress
    try initGL();

    // TODO: getSize() should probably return the same type that viewport() takes??
    const window_size = window.getSize();
    // Not necessary. It should be created this way by default
    gl.viewport(0, 0, @intCast(window_size.width), @intCast(window_size.height));

    gl.clearColor(0.2, 0.5, 0.3, 1.0);

    // const vertices = [_]f32{
    //     -0.5, -0.5, 0,
    //     0.5,  -0.5, 0,
    //     0.5,  0.5,  0,
    //     -0.5, 0.5,  0,
    // };

    const vertices = [_]f32{
        -0.7, -0.7, 0,
        -0.7, -0.1, 0,
        -0.2, -0.4, 0,
    };

    const indices = [_]u32{
        0, 1, 2,
        0, 3, 2,
    };

    const vao = gl.genVertexArray();
    vao.bind();

    // TODO: in what world would i ever want to take the same array and bind it sometimes as one and sometimes as another type of buffer? should that info not be stored with the buffer?
    const ebo = gl.genBuffer();
    ebo.bind(.element_array_buffer);
    ebo.data(u32, &indices, .static_draw);

    const vbo = gl.genBuffer();
    // TODO: the indirection confuses zls. report bug
    vbo.bind(.array_buffer);
    vbo.data(f32, &vertices, .static_draw);

    // this is nuts. the "0" here refers to the "location = 0" in the vertex shader. talk about magic numbers
    // we can use prog.attribLocation(), but that would require the program to exist, runs at runtime, and technically only makes sense for a single program. then we have to store those somewhere.
    // maybe better to define constants
    gl.vertexAttribPointer(0, 3, .float, false, 3 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(0);

    const prog = createShaderProgram("./shaders/vert.glsl", "./shaders/frag.glsl", allocator);
    prog.use();

    // this is nuts. the "0" here refers to the "location = 0" in the vertex shader. talk about magic numbers
    const aPos = prog.attribLocation("aPos") orelse return error.AttribNotFound;
    gl.vertexAttribPointer(aPos, 3, .float, false, 3 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(aPos);

    while (!quit) {
        pollEvents();
        gl.clear(.{ .color = true });
        try render(vao, prog);
        // TODO: make window.swap() or window.glSwap() or window.gl.swap()
        sdl.gl.swapWindow(window);
    }
}

var polygon_mode: gl.DrawMode = .fill;

fn pollEvents() void {
    while (sdl.pollEvent()) |ev| switch (ev) {
        .window => |wev| switch (wev.type) {
            .resized => |rev| {
                gl.viewport(0, 0, @intCast(rev.width), @intCast(rev.height));
            },
            .close => {
                quit = true;
            },
            else => {},
        },
        .key_down => |kev| switch (kev.keycode) {
            .escape => quit = true,
            .z => {
                switch (polygon_mode) {
                    .point, .line => polygon_mode = .fill,
                    .fill => polygon_mode = .line,
                }
                gl.polygonMode(.front_and_back, polygon_mode);
            },
            else => {},
        },
        else => {},
    };
}

fn render(vao: gl.VertexArray, shader_prog: gl.Program) !void {
    vao.bind();
    shader_prog.use();

    // gl.drawElements(.triangles, 6, .unsigned_int, 0);
    gl.drawArrays(.triangles, 0, 6);
}

// TODO: figure out how big the error messages can be and get rid of the allocator
// TODO: return an error in case of failures
fn createShaderProgram(comptime vert_p: []const u8, comptime frag_p: []const u8, allocator: std.mem.Allocator) gl.Program {
    const vert_f = @embedFile(vert_p);
    const frag_f = @embedFile(frag_p);
    const vert_s = gl.createShader(.vertex);

    vert_s.source(1, &.{vert_f});
    vert_s.compile();
    // TODO: should get checked automatically in .compile()?
    if (vert_s.get(.compile_status) == 0) {
        const log = vert_s.getCompileLog(allocator) catch @panic("OOM!");
        defer allocator.free(log);
        std.debug.print("Error: vertex shader compilation failed {s}", .{log});
    }
    defer vert_s.delete();

    const frag_s = gl.createShader(.fragment);
    frag_s.source(1, &.{frag_f});
    frag_s.compile();
    if (frag_s.get(.compile_status) == 0) {
        const log = frag_s.getCompileLog(allocator) catch @panic("OOM!");
        defer allocator.free(log);
        std.debug.print("Error: vertex shader compilation failed {s}", .{log});
    }
    defer frag_s.delete();

    const prog = gl.createProgram();
    prog.attach(vert_s);
    prog.attach(frag_s);
    prog.link();
    if (prog.get(.link_status) == 0) {
        const log = prog.getCompileLog(allocator) catch @panic("OOM!");
        defer allocator.free(log);
        std.debug.print("Error: shader program could not link {s}", .{log});
    }
    return prog;
}

fn getProcAddressWrapper(comptime _: type, symbolName: [:0]const u8) ?*const anyopaque {
    return sdl.c.SDL_GL_GetProcAddress(symbolName);
}

fn initGL() !void {
    try gl.loadExtensions(void, getProcAddressWrapper);
}
