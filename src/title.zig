const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});

const main = @import("main.zig");
const drawer = @import("draw.zig");
const structs = @import("structs.zig");
const defs = @import("defs.zig");
const stage = @import("stage.zig");
const utils = @import("utils.zig");
const sounds = @import("sounds.zig");
const text = @import("text.zig");
const highscores = @import("highscores.zig");

var titleImg: *c.SDL_Texture = undefined;

var timeout: i32 = 0;

var reveal: i32 = 0;

pub fn initTitle() !void {
    main.app.delegate.logic = logic;
    main.app.delegate.draw = draw;

    titleImg = try drawer.loadTexture("assets/titleText.png");

    timeout = defs.FPS * 5;
}

pub fn logic() !void {
    stage.handleBackground();

    stage.handleStarfield();

    if (reveal < defs.SCREEN_HEIGHT) {
        reveal += 10;
    }

    timeout -= 1;
    if (timeout <= 0) {
        highscores.initHighscores();
    }

    if (main.app.keyboard[c.SDL_SCANCODE_F]) {
        try stage.initStage();
    }
}

pub fn draw() !void {
    stage.drawBackground();

    stage.drawStarfield();

    drawLogo();

    if (@mod(timeout, 40) < 20) {
        try text.drawText(
            425,
            600,
            255,
            255,
            255,
            "PRESS FIRE (F) TO PLAY!",
            .{},
        );
    }
}

fn drawLogo() void {
    var rect: c.SDL_Rect = undefined;

    rect.x = 0;
    rect.y = 0;

    _ = c.SDL_QueryTexture(titleImg, null, null, &rect.w, &rect.h);

    rect.h = @min(reveal, rect.h);

    drawer.blitRect(
        titleImg,
        &rect,
        @divFloor(defs.SCREEN_WIDTH, 2) - @divFloor(rect.w, 2),
        80,
    );
}
