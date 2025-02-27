const std = @import("std");

const gl = @import("zgl");
const sdl = @import("sdl");

const c = @import("c.zig");
const ShaderProg = @import("shader_prog.zig");

var x_offset: i32 = 0;
var y_offset: i32 = 0;
var offset_prog_location: u32 = undefined;

var window: sdl.Window = undefined;
var window_w: u32 = 640;
var window_h: u32 = 480;
var wSize_prog_location: u32 = undefined;

// TODO: define the data using structs and automatically calculate strides and such
var vertices = [_]f32{
    // positions   // colors
    -200, -200, 0, 1.0, 0.0, 0.0,
    200,  -200, 0, 0.0, 1.0, 0.0,
    200,  200,  0, 0.0, 0.0, 1.0,
    -200, 200,  0, 1.0, 1.0, 1.0,
};
var vao: gl.VertexArray = undefined;

var selection: ?u8 = null;

const selection_square = [_]f32{
    -20, -20, 0,
    20,  -20, 0,
    20,  20,  0,
    -20, 20,  0,
};
var selection_vao: gl.VertexArray = undefined;

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

    window = try sdl.createWindow(
        "SDL.zig Basic Demo",
        .{ .centered = {} },
        .{ .centered = {} },
        window_w,
        window_h,
        .{ .vis = .shown, .context = .opengl },
    );
    defer window.destroy();

    // TODO: make this window.createContext()
    const context = try sdl.gl.createContext(window);

    try context.makeCurrent(window);

    // must be called after the context is current
    // SEE: https://wiki.libsdl.org/SDL2/SDL_GL_GetProcAddress
    try initGL();

    const prog = try ShaderProg.init("./shaders/vert.glsl", "./shaders/frag.glsl");
    const find_vertex_prog = try ShaderProg.init("./shaders/find_vertex.glsl", "./shaders/frag.glsl");
    const selection_prog = try ShaderProg.init("./shaders/selection.glsl", "./shaders/frag.glsl");

    prog.use();
    // we use the same location in all the shaders
    const aPos = prog.attribLocation("aPos") orelse return error.AttribNotFound;

    selection_vao = gl.genVertexArray();
    selection_vao.bind();

    const selection_vbo = gl.genBuffer();
    selection_vbo.bind(.array_buffer);
    selection_vbo.data(f32, &selection_square, .static_draw);

    gl.vertexAttribPointer(aPos, 3, .float, false, 0, 0);
    gl.enableVertexAttribArray(aPos);

    // TODO: getSize() should probably return the same type that viewport() takes??
    // const window_size = window.getSize();
    // Not necessary. It should be created this way by default
    gl.viewport(0, 0, window_w, window_h);

    const indices = [_]u32{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
    };

    vao = gl.genVertexArray();
    vao.bind();

    // TODO: in what world would i ever want to take the same array and bind it sometimes as one and sometimes as another type of buffer? should that info not be stored with the buffer?
    const vbo = gl.genBuffer();
    // TODO: the indirection confuses zls. report bug
    vbo.bind(.array_buffer);
    vbo.data(f32, &vertices, .static_draw);

    const ebo = gl.genBuffer();
    ebo.bind(.element_array_buffer);
    ebo.data(u32, &indices, .static_draw);

    // this is nuts. the "0" here refers to the "location = 0" in the vertex shader. talk about magic numbers
    // we can use prog.attribLocation(), but that would require the program to exist, runs at runtime, and technically only makes sense for a single program. then we have to store those somewhere.
    // maybe better to define constants
    // gl.vertexAttribPointer(0, 3, .float, false, 3 * @sizeOf(f32), 0);
    // gl.enableVertexAttribArray(0);

    gl.vertexAttribPointer(aPos, 3, .float, false, 6 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(aPos);

    if (prog.attribLocation("aColor")) |aColor| {
        gl.vertexAttribPointer(aColor, 3, .float, false, 6 * @sizeOf(f32), 3 * @sizeOf(f32));
        gl.enableVertexAttribArray(aColor);
    } else {
        // return error.AttribNotFound;
    }

    // TODO: wrap uniforms in their own enum datatype?
    offset_prog_location = prog.uniformLocation("offset") orelse undefined;
    wSize_prog_location = prog.uniformLocation("wSize") orelse undefined;
    gl.uniform2ui(wSize_prog_location, window_w, window_h);

    while (!quit) {
        pollEvents(find_vertex_prog);
        gl.clearColor(0.2, 0.5, 0.3, 1.0);
        gl.clear(.{ .color = true });
        try render(prog, selection_prog);
        // TODO: make window.swap() or window.glSwap() or window.gl.swap()
        sdl.gl.swapWindow(window);
    }
}

var polygon_mode: gl.DrawMode = .fill;

fn pollEvents(find_vertex: gl.Program) void {
    while (sdl.pollEvent()) |ev| switch (ev) {
        .window => |wev| switch (wev.type) {
            .size_changed => |size| {
                window_w = @intCast(size.width);
                window_h = @intCast(size.height);
                gl.viewport(0, 0, window_w, window_h);
                gl.uniform2ui(wSize_prog_location, window_w, window_h);
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
        .mouse_motion => |mev| {
            if (mev.button_state.getPressed(.left)) {
                // +/- is trial and error
                x_offset += mev.delta_x;
                y_offset -= mev.delta_y;
            }
        },
        .mouse_button_down => |mev| {
            if (mev.button == .left) {
                find_vertex.use();
                vao.bind();

                // I have to set uniforms PER PROGRAM? Why???
                // shhh don't tell anyone i'm hardcoding magic numbers i'm soo tired please just work
                gl.uniform2i(2, x_offset, y_offset);
                gl.uniform2ui(3, window_w, window_h);

                // draw = false;
                // figure out which vertex was clicked (if any)
                // SEE: https://stackoverflow.com/questions/4040616/opengl-gl-select-or-manual-collision-detection
                gl.clearColor(1, 1, 1, 1);
                gl.clear(.{ .color = true });
                gl.pointSize(100);

                gl.enable(.scissor_test);
                std.debug.assert(0 <= mev.y and mev.y <= window_h);
                std.debug.assert(0 <= mev.x and mev.x <= window_w);
                const x: u32 = @intCast(mev.x);
                const y: u32 = @intCast(@as(i32, @intCast(window_h)) - mev.y);

                gl.scissor(@intCast(x), @intCast(y), 1, 1);

                gl.drawArrays(.points, 0, 4);
                var data: packed struct { r: u8, g: u8, b: u8 } = undefined;
                gl.readPixels(x, y, 1, 1, .rgb, .unsigned_byte, @ptrCast(&data));
                gl.disable(.scissor_test);

                // for now, we only use the red value to store the index
                selection = if (data.g == 0) data.r else null;
                std.debug.print("{any}\n", .{data});
                // sdl.gl.swapWindow(window);
            }
        },
        .mouse_button_up => |mev| {
            _ = mev;
        },
        else => {},
    };
}

fn render(shader_prog: gl.Program, selection_prog: gl.Program) !void {
    vao.bind();
    shader_prog.use();
    gl.uniform2i(offset_prog_location, x_offset, y_offset);
    gl.drawElements(.triangles, 6, .unsigned_int, 0);

    if (selection) |index| {
        selection_prog.use();
        gl.uniform2ui(wSize_prog_location, window_w, window_h);
        gl.uniform2i(
            offset_prog_location,
            x_offset + @as(i32, @intFromFloat(vertices[index * 6])),
            y_offset + @as(i32, @intFromFloat(vertices[index * 6 + 1])),
        );
        selection_vao.bind();
        gl.lineWidth(5);
        gl.drawArrays(.line_loop, 0, 4);
    }
}

fn getProcAddressWrapper(comptime _: type, symbolName: [:0]const u8) ?*const anyopaque {
    return sdl.c.SDL_GL_GetProcAddress(symbolName);
}

fn initGL() !void {
    try gl.loadExtensions(void, getProcAddressWrapper);
}
