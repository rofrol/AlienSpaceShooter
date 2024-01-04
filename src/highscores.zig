const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const structs = @import("structs.zig");
const main = @import("main.zig");
const defs = @import("defs.zig");
const stage = @import("stage.zig");
const text = @import("text.zig");
const title = @import("title.zig");

var timeout: i32 = 0;

pub fn initHighscoreTable() void {
    for (0..defs.NUM_HIGHSCORES) |i| {
        main.highscores.highscore[i].score = @intCast((defs.NUM_HIGHSCORES - i) * 10);
    }
}

pub fn initHighscores() void {
    main.app.delegate.logic = logic;
    main.app.delegate.draw = draw;

    timeout = defs.FPS * 5;
}

pub fn logic() !void {
    stage.handleBackground();

    stage.handleStarfield();

    timeout -= 1;
    if (timeout <= 0) {
        try title.initTitle();
    }

    if (main.app.keyboard[c.SDL_SCANCODE_F]) {
        try stage.initStage();
    }
}

pub fn draw() !void {
    stage.drawBackground();
    stage.drawStarfield();
    try drawHighscores();
}

fn drawHighscores() !void {
    var y: i32 = 150;

    try text.drawText(525, 70, 255, 255, 255, "HIGHSCORES", .{});

    for (0..defs.NUM_HIGHSCORES) |i| {
        if (main.highscores.highscore[i].recent) {
            try text.drawText(
                435,
                y,
                255,
                255,
                0,
                "#{any} ............. {any}",
                .{ i + 1, main.highscores.highscore[i].score },
            );
        } else {
            try text.drawText(
                435,
                y,
                255,
                255,
                255,
                "#{any} ............. {any}",
                .{ i + 1, main.highscores.highscore[i].score },
            );
        }
        y += 50;
    }

    if (@mod(timeout, 40) > 20) {
        try text.drawText(425, 600, 255, 255, 255, "PRESS FIRE (F) TO PLAY!", .{});
    }
}

pub fn addHighscore(score: i32) void {
    var newHighscores: [defs.NUM_HIGHSCORES + 1]structs.Highscore = undefined;

    for (0..defs.NUM_HIGHSCORES) |i| {
        newHighscores[i] = main.highscores.highscore[i];
        newHighscores[i].recent = false;
    }

    newHighscores[defs.NUM_HIGHSCORES].score = score;
    newHighscores[defs.NUM_HIGHSCORES].recent = true;

    std.sort.insertion(
        comptime structs.Highscore,
        &newHighscores,
        {},
        comptime compareScores,
    );

    for (0..defs.NUM_HIGHSCORES) |i| {
        main.highscores.highscore[i] = newHighscores[i];
    }
}

fn compareScores(context: void, a: structs.Highscore, b: structs.Highscore) bool {
    _ = context; // autofix
    return a.score > b.score;
}
