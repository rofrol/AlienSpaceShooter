const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const defs = @import("defs.zig");

pub const App = struct {
    renderer: *c.SDL_Renderer = undefined,
    window: *c.SDL_Window = undefined,
    up: bool = false,
    // keyboard: [defs.MAX_KEYBOARD_KEYS]i32,
    down: bool = false,
    left: bool = false,
    right: bool = false,
    fire: bool = false,
};

pub var app = App{};

pub const Entity = struct {
    x: i32 = 0,
    y: i32 = 0,
    dx: i32 = 0,
    dy: i32 = 0,
    health: i32 = 0,
    texture: *c.SDL_Texture = undefined,
};
