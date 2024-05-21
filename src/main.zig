const std = @import("std");
const sdl = @import("sdl");
const gl = @import("zgl");
const c = @import("c.zig");
const ShaderProg = @import("shader_prog.zig");

var quit = false;

pub fn main() !void {
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

    const vertices = [_]f32{
        // positions   // colors
        -0.7, -0.7, 0, 1.0, 0.0, 0.0,
        0,    0.6,  0, 0.0, 1.0, 0.0,
        0.7,  -0.7, 0, 0.0, 0.0, 1.0,
    };

    const vao = gl.genVertexArray();
    vao.bind();

    // TODO: in what world would i ever want to take the same array and bind it sometimes as one and sometimes as another type of buffer? should that info not be stored with the buffer?
    const vbo = gl.genBuffer();
    // TODO: the indirection confuses zls. report bug
    vbo.bind(.array_buffer);
    vbo.data(f32, &vertices, .static_draw);

    // this is nuts. the "0" here refers to the "location = 0" in the vertex shader. talk about magic numbers
    // we can use prog.attribLocation(), but that would require the program to exist, runs at runtime, and technically only makes sense for a single program. then we have to store those somewhere.
    // maybe better to define constants
    gl.vertexAttribPointer(0, 3, .float, false, 3 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(0);

    const prog = try ShaderProg.init("./shaders/vert.glsl", "./shaders/frag.glsl");
    prog.use();

    // this is nuts. the "0" here refers to the "location = 0" in the vertex shader. talk about magic numbers
    const aPos = prog.prog.attribLocation("aPos") orelse return error.AttribNotFound;
    gl.vertexAttribPointer(aPos, 3, .float, false, 6 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(aPos);

    if (prog.prog.attribLocation("aColor")) |aColor| {
        gl.vertexAttribPointer(aColor, 3, .float, false, 6 * @sizeOf(f32), 3 * @sizeOf(f32));
        gl.enableVertexAttribArray(aColor);
    } else {
        // return error.AttribNotFound;
    }

    // TODO: wrap uniforms in their own enum datatype?
    const offset = prog.prog.uniformLocation("offset");
    gl.uniform2f(offset, 0.2, 0.0);

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

fn render(vao: gl.VertexArray, shader_prog: ShaderProg) !void {
    vao.bind();
    shader_prog.use();

    // gl.drawElements(.triangles, 6, .unsigned_int, 0);
    gl.drawArrays(.triangles, 0, 3);
}

fn getProcAddressWrapper(comptime _: type, symbolName: [:0]const u8) ?*const anyopaque {
    return sdl.c.SDL_GL_GetProcAddress(symbolName);
}

fn initGL() !void {
    try gl.loadExtensions(void, getProcAddressWrapper);
}
