const std = @import("std");

fn f32_to_u16_be(x: f32) u16 {
    const le: u16 = @intFromFloat(x * @as(f32, @floatFromInt(std.math.maxInt(u16))));
    return ((le & 0xFF00) >> 8) | ((le & 0x00FF) << 8);
}

pub const FFColor = packed struct {
    r: u16,
    g: u16,
    b: u16,
    a: u16,

    fn fromFloat(c: Color) FFColor {
        return .{
            .r = f32_to_u16_be(c.r),
            .g = f32_to_u16_be(c.g),
            .b = f32_to_u16_be(c.b),
            .a = f32_to_u16_be(c.a),
        };
    }
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    pub fn mul(self: Color, x: f32) Color {
        return .{
            .r = self.r * x,
            .g = self.g * x,
            .b = self.b * x,
            .a = self.a,
        };
    }

    pub const white: Color = .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 };
    pub const black: Color = .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 };
};

pub const Image = struct {
    width: u32,
    height: u32,
    buffer: []FFColor,

    pub fn alloc(allocator: std.mem.Allocator, width: u32, height: u32) !Image {
        return .{
            .width = width,
            .height = height,
            .buffer = try allocator.alloc(FFColor, width * height),
        };
    }
    pub fn free(self: Image, allocator: std.mem.Allocator) void {
        allocator.free(self.buffer);
    }
    pub fn write(self: Image, writer: std.io.AnyWriter) !void {
        try writer.writeAll("farbfeld");
        try writer.writeInt(u32, self.width, .big);
        try writer.writeInt(u32, self.height, .big);
        try writer.writeAll(std.mem.sliceAsBytes(self.buffer));
    }
    pub fn set(self: Image, x: usize, y: usize, color: Color) void {
        self.buffer[y * self.width + x] = FFColor.fromFloat(color);
    }
};
