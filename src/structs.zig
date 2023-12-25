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
};

const Delegate = struct {
    logic: *const fn () anyerror!void = stage.logic,
    draw: *const fn () void = stage.draw,
};

pub const Entity = struct {
    x: f32 = 0,
    y: f32 = 0,
    w: i32 = 0,
    h: i32 = 0,
    dx: f32 = 0,
    dy: f32 = 0,
    health: i32 = 0,
    reload: i32 = 0,
    texture: *c.SDL_Texture = undefined,
    next: *Entity = undefined,
};

pub const Stage = struct {
    fighterHead: Entity = undefined,
    fighterTail: *Entity = undefined,
    bullets: std.DoublyLinkedList(*Entity) = undefined,
};
