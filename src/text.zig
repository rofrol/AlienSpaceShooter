const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const defs = @import("defs.zig");
const draw = @import("draw.zig");
const allocator = @import("stage.zig").allocator;

const CHAR_HEIGHT = 28;
const CHAR_WIDTH = 18;

var fontTexture: *c.SDL_Texture = undefined;
var drawTextBuffer: [defs.MAX_LINE_LENGTH]u8 = undefined;

pub fn initText() !void {
    fontTexture = try draw.loadTexture("assets/font.png");
}

pub fn drawText(x: i32, y: i32, r: u8, g: u8, b: u8, comptime format: []const u8, args: anytype) !void {
    const string = try stringFormat(format, args);
    defer allocator.free(string);

    var rect = c.SDL_Rect{
        .w = CHAR_WIDTH,
        .h = CHAR_HEIGHT,
        .x = 0,
        .y = 0,
    };

    var x_pos = x;

    _ = c.SDL_SetTextureColorMod(fontTexture, r, g, b);

    for (0..string.len) |i| {
        const char = string[i];
        if (char >= ' ' and char <= 'Z') {
            // std.debug.print("Should be: {} ", .{@as(c_int, (char - ' ')) * CHAR_WIDTH});
            rect.x = @as(c_int, (char - ' ')) * CHAR_WIDTH;
            // std.debug.print("Actually is: {}", .{rect.x});
            draw.blitRect(fontTexture, &rect, x_pos, y);
            x_pos += CHAR_WIDTH;
        }
    }
}

fn stringFormat(
    comptime format: []const u8,
    args: anytype,
) ![]u8 {
    const string = try std.fmt.allocPrint(allocator, format, args);
    return string;
}
