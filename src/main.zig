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

    while (true) {
        draw.prepareScene();
        input.handleInput();

        try app.delegate.logic();
        app.delegate.draw();

        draw.presentScene();
        c.SDL_Delay(16);
    }
}
