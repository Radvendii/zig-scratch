// TODO: get rid of this layer of wrapping. maybe just rewrap the original enum

const std = @import("std");
const sdl = @import("sdl");
const gl = @import("zgl");

const Self = @This();

const ERR_BUF_LEN = 512;

prog: gl.Program,

// TODO: vary behaviour based on zgl error handling
// TODO: should this get checked automatically in .compile()?
// TODO: upstream allocator-less checking to zgl (take buffer length in a comptime parameter?)
fn shaderCheckErr(shader: gl.Shader) !void {
    if (shader.get(.compile_status) == gl.binding.FALSE) {
        var buf: [ERR_BUF_LEN]u8 = undefined;
        var buf_len: i32 = 0;
        const log_len = shader.get(.info_log_length);
        if (log_len > ERR_BUF_LEN) {
            std.log.warn("Shader error too long! It had to be truncated. Consider increasing MAX_ERR_LEN ({})", .{ERR_BUF_LEN});
            gl.binding.getShaderInfoLog(@intFromEnum(shader), ERR_BUF_LEN, &buf_len, &buf);
            std.log.warn("Error: shader compilation failed:\n {s}", .{buf});
        }
        return error.ShaderCompile;
    }
}

fn progCheckErr(prog: gl.Program) !void {
    // TODO: have return type of get() depend on arg
    if (prog.get(.link_status) == gl.binding.FALSE) {
        var buf: [ERR_BUF_LEN]u8 = undefined;
        var buf_len: i32 = 0;
        const log_len = prog.get(.info_log_length);
        if (log_len > ERR_BUF_LEN) {
            std.log.warn("Program error too long! It had to be truncated. Consider increasing MAX_ERR_LEN ({})", .{ERR_BUF_LEN});
            gl.binding.getShaderInfoLog(@intFromEnum(prog), ERR_BUF_LEN, &buf_len, &buf);
            std.log.warn("Error: program linking failed:\n {s}", .{buf});
        }
        return error.ProgramLink;
    }
}

// TODO: take either a path or a string or an already compiled shader
pub fn init(comptime vert_p: []const u8, comptime frag_p: []const u8) !Self {
    const vert_f = @embedFile(vert_p);
    const frag_f = @embedFile(frag_p);

    const vert_s = gl.createShader(.vertex);
    defer vert_s.delete();
    vert_s.source(1, &.{vert_f});
    vert_s.compile();
    try shaderCheckErr(vert_s);

    const frag_s = gl.createShader(.fragment);
    defer frag_s.delete();
    frag_s.source(1, &.{frag_f});
    frag_s.compile();
    try shaderCheckErr(frag_s);

    const prog = gl.createProgram();
    prog.attach(vert_s);
    prog.attach(frag_s);
    prog.link();
    try progCheckErr(prog);

    return Self{ .prog = prog };
}
pub fn use(self: Self) void {
    self.prog.use();
}
