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

pub fn main() !void {
    try sdl.init(.{
        .video = true,
        .events = true,
        .audio = true,
    });
    defer sdl.quit();

    const window = try sdl.createWindow(
        "SDL.zig Basic Demo",
        .{ .centered = {} },
        .{ .centered = {} },
        640,
        480,
        .{
            .vis = .shown,
            .context = .opengl,
        },
    );
    defer window.destroy();

    // TODO: make this window.createContext()
    const context = try sdl.gl.createContext(window);

    // TODO: maybe make this context.makeCurrent(). is it sensible to have one context attached to multiple windows?
    try sdl.gl.makeCurrent(context, window);

    c.glMatrixMode(c.GL_PROJECTION);
    c.glLoadIdentity();
    c.glMatrixMode(c.GL_MODELVIEW);
    c.glLoadIdentity();

    c.glClearColor(0.0, 0.0, 0.0, 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT);
    c.glBegin(c.GL_QUADS);
    c.glColor3f(1.0, 1.0, 1.0);
    c.glVertex2f(-0.5, -0.5);
    c.glVertex2f(-0.5, 0.5);
    c.glVertex2f(0.5, 0.5);
    c.glVertex2f(0.5, -0.5);
    c.glEnd();

    // TODO: make window.swap() or window.glSwap() or window.gl.swap()
    sdl.gl.swapWindow(window);

    sdl.delay(2000);
}
