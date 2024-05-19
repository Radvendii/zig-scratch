const std = @import("std");
const sdl = @import("sdl");
const gl = @import("zgl");
const c = @import("c.zig");

const VERTEX_SHADER =
    \\#version 430 core
    \\layout(location = 0) in vec2 v2VertexPos2D;
    \\void main() {
    \\  gl_Position = vec4(v2VertexPos2D, 0.0f, 1.0f);    
    \\}
;

var quit = false;

pub fn main() !void {
    try sdl.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer sdl.quit();

    // TODO: setAttributes?
    try sdl.gl.setAttribute(.{ .context_major_version = 4 });
    try sdl.gl.setAttribute(.{ .context_minor_version = 6 });
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

    try initGL();

    // TODO: getSize() should probably return the same type that viewport() takes??
    const window_size = window.getSize();
    gl.viewport(0, 0, @intCast(window_size.width), @intCast(window_size.height));

    while (!quit) {
        pollEvents();
        render();
        // TODO: make window.swap() or window.glSwap() or window.gl.swap()
        sdl.gl.swapWindow(window);
    }
}

fn pollEvents() void {
    while (sdl.pollEvent()) |ev| switch (ev) {
        .window => |wev| switch (wev.type) {
            .resized => |rev| {
                gl.viewport(0, 0, @intCast(rev.width), @intCast(rev.height));
            },
            else => {},
        },
        .key_down => |kev| {
            if (kev.keycode == .q) {
                quit = true;
            }
        },
        else => {},
    };
}

fn render() void {}

// TODO: figure out wtf this is doing
fn getProcAddressWrapper(comptime _: type, symbolName: [:0]const u8) ?*const anyopaque {
    return sdl.c.SDL_GL_GetProcAddress(symbolName);
}

fn initGL() !void {
    try gl.loadExtensions(void, getProcAddressWrapper);
}
