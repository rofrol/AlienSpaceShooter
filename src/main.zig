const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});

const structs = @import("structs.zig");
const draw = @import("draw.zig");
const defs = @import("defs.zig");
const init = @import("init.zig");
const input = @import("input.zig");
const stager = @import("stage.zig");

pub var app = structs.App{};
pub var stage = structs.Stage{};

pub fn main() !void {
    init.initSDL();
    defer init.exitSDL();

    try stager.initStage();

    // var then = c.SDL_GetTicks();
    // var remainder: f32 = 0;

    while (true) {
        draw.prepareScene();
        input.handleInput();

        try app.delegate.logic();
        app.delegate.draw();

        draw.presentScene();
        // capFrameRate(&then, &remainder);
        c.SDL_Delay(16);
    }
}

fn capFrameRate(then: *u32, remainder: *f32) void {
    var wait: u32 = @as(u32, 16.0 + remainder.*);
    remainder.* -= @mod(1.0, remainder.*);
    const frameTime: u32 = c.SDL_GetTicks() - then.*;
    wait -= frameTime;

    if (wait < 1) {
        wait = 1;
    }

    c.SDL_Delay(wait);
    remainder.* += 0.667;

    then.* = c.SDL_GetTicks();
}
