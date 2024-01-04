const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const defs = @import("defs.zig");
const stage = @import("stage.zig");

pub const App = struct {
    renderer: *c.SDL_Renderer = undefined,
    window: *c.SDL_Window = undefined,
    delegate: Delegate = Delegate{},
    keyboard: [defs.MAX_KEYBOARD_KEYS]bool = [_]bool{false} ** defs.MAX_KEYBOARD_KEYS,
    textures: std.StringHashMap(*c.SDL_Texture) = undefined,
};

const Delegate = struct {
    logic: *const fn () anyerror!void = stage.logic,
    draw: *const fn () anyerror!void = stage.draw,
};

pub const Entity = struct {
    x: f32 = 0,
    y: f32 = 0,
    w: i32 = undefined,
    h: i32 = undefined,
    dx: f32 = 0,
    dy: f32 = 0,
    health: i32 = 0,
    reload: i32 = 0,
    texture: *c.SDL_Texture = undefined,
    side: u1 = 0,
};

pub const Stage = struct {
    fighters: std.DoublyLinkedList(*Entity) = undefined,
    bullets: std.DoublyLinkedList(*Entity) = undefined,
    explosions: std.DoublyLinkedList(*Explosion) = undefined,
    debris: std.DoublyLinkedList(*Debris) = undefined,
    score: i16 = 0,
};

pub const Explosion = struct {
    x: f32,
    y: f32,
    dx: f32,
    dy: f32,
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8,
};

pub const Debris = struct {
    x: f32,
    y: f32,
    dx: f32,
    dy: f32,
    rect: c.SDL_Rect,
    texture: *c.SDL_Texture,
    life: u32,
};

pub const Star = struct {
    x: i32,
    y: i32,
    speed: u8,
};

pub const Highscore = struct {
    recent: bool = false,
    score: i32,
};

pub const Highscores = struct {
    highscore: [defs.NUM_HIGHSCORES]Highscore = undefined,
};
