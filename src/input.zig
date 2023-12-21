const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});

const structs = @import("structs.zig");
const draw = @import("draw.zig");
const defs = @import("defs.zig");
const init = @import("init.zig");
var app = &@import("main.zig").app;

pub fn handleInput() void {
    var sdl_event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&sdl_event) != 0) {
        switch (sdl_event.type) {
            c.SDL_KEYDOWN => keyDown(&sdl_event.key),
            c.SDL_KEYUP => keyUp(&sdl_event.key),
            c.SDL_QUIT => {
                init.exitSDL();
                std.os.exit(0);
            },
            else => {},
        }
    }
}

fn keyDown(event: *c.SDL_KeyboardEvent) void {
    if (event.repeat == 0) {
        if (event.keysym.scancode == c.SDL_SCANCODE_RIGHT) {
            app.*.right = true;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_LEFT) {
            app.*.left = true;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_UP) {
            app.*.up = true;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_DOWN) {
            app.*.down = true;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_SPACE) {
            app.*.fire = true;
        }
    }
}

fn keyUp(event: *c.SDL_KeyboardEvent) void {
    if (event.repeat == 0) {
        if (event.keysym.scancode == c.SDL_SCANCODE_RIGHT) {
            app.*.right = false;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_LEFT) {
            app.*.left = false;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_UP) {
            app.*.up = false;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_DOWN) {
            app.*.down = false;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_SPACE) {
            app.*.fire = false;
        }
    }
}
