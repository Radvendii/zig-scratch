const std = @import("std");

// const geo = @import("geometry.zig");
const ff = @import("farbfeld.zig");

const Point = struct {
    x: f32,
    y: f32,
};

pub fn dist2(p1: Point, p2: Point) f32 {
    const x = p1.x - p2.x;
    const y = p1.y - p2.y;
    return (x * x + y * y);
}

pub fn dist(p1: Point, p2: Point) f32 {
    return std.math.sqrt(dist2(p1, p2));
}

fn smoothstep(x: f32) f32 {
    if (x <= 0.0) {
        return 0.0;
    } else if (x >= 1.0) {
        return 1.0;
    } else {
        return 3 * x * x - 2 * x * x * x;
    }
}

fn smooth(x: f32, smoothness: f32, center: f32) f32 {
    return smoothstep((x - center - 0.5) / smoothness);
}

pub fn circle(center: Point, r: f32, out: ff.Image) void {
    const h = out.height;
    const w = out.width;
    for (0..h) |y| {
        for (0..w) |x| {
            const p: Point = .{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
            const d = dist(p, center);
            out.set(x, y, ff.Color.white.mul(smooth(d, 2.0, r)));
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};

    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const out = try std.fs.cwd().createFile("out.ff", .{});
    const img = try ff.Image.alloc(allocator, 200, 100);
    defer img.free(allocator);
    circle(
        .{
            .x = 50.0,
            .y = 50.0,
        },
        30.0,
        img,
    );
    try img.write(out.writer().any());
}
