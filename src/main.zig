const std = @import("std");
const SDL = @import("SDL.zig");
const gl = @import("zgl");

const c = SDL.c;

const VERTEX_SHADER =
    \\#version 430 core
    \\layout(location = 0) in vec2 v2VertexPos2D;
    \\void main() {
    \\  gl_Position = vec4(v2VertexPos2D, 0.0f, 1.0f);    
    \\}
;

// fn loadShader(shaderType: c.GLenum, shaderText: [*:0]const u8) !c.GLuint {
//     const shader = c.glCreateShader(shaderType);
//     c.glShaderSource(shader, 1, )
// }

pub fn main() !void {
    try SDL.init(.{ .video = true });

    const window = try SDL.createWindow(
        "hello".ptr,
        SDL.UNDEFINED_POS,
        SDL.UNDEFINED_POS,
        1000,
        1000,
        .{ .opengl = true },
    );

    const context = window.glCreateContext();
    context.makeCurrent();

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
    // c.glCullFace(c.GL_BACK);
    // c.glEnable(c.GL_CULL_FACE);
    // c.glEnable(c.GL_DEPTH_TEST);
    // c.glEnable(c.GL_STENCIL_TEST);

    window.glSwap();

    // const renderer = try SDL.createRenderer(window, 0, .{ .accelerated = true });
    // renderer.setDrawColor(.{ .r = 96, .g = 128, .b = 255, .a = 255 });
    // renderer.clear();
    // renderer.present();

    SDL.sleep(2000);
}
