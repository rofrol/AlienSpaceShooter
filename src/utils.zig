const std = @import("std");

pub fn collision(x1: f32, y1: f32, w1: i32, h1: i32, x2: f32, y2: f32, w2: i32, h2: i32) bool {
    const x = @max(x1, x2) < @min(
        x1 + @as(f32, @floatFromInt(w1)),
        x2 + @as(f32, @floatFromInt(w2)),
    );
    const y = @max(y1, y2) < @min(
        y1 + @as(f32, @floatFromInt(h1)),
        y2 + @as(f32, @floatFromInt(h2)),
    );
    return x and y;
}

pub fn calcSlope(
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,
    dx: *f32,
    dy: *f32,
) void {
    const steps = @max(@abs(x1 - x2), @abs(y1 - y2));

    if (steps == 0) {
        dx.* = 0;
        dy.* = 0;
        return;
    }
    dx.* = x1 - x2;
    dx.* /= steps;

    dy.* = y1 - y2;
    dy.* /= steps;
}
