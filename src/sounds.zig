const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
    @cInclude("SDL2/SDL_mixer.h");
});
const defs = @import("defs.zig");
const allocator = @import("stage.zig").allocator;

// var music: c.Mix_Music = c.Mix_LoadMUS("music/alienSpaceShooter.ogg");
var music: ?*c.Mix_Music = null;
var sounds: []*c.Mix_Chunk = undefined;

pub fn initSounds() !void {
    music = null;
    try loadSounds();
}

pub fn loadMusic(filename: [*]const u8) void {
    // std.debug.print("trying to load music\n", .{});
    if (music != null) {
        _ = c.Mix_HaltMusic();
        _ = c.Mix_FreeMusic(music);
        music = null;
    }

    music = c.Mix_LoadMUS(filename);
    if (music == null) {
        std.debug.print("music is null\n", .{});
    }
    // std.debug.print("Music: {any}", .{music});
}

pub fn playMusic(loop: bool) void {
    _ = c.Mix_PlayMusic(music, if (loop) -1 else 0);
}

pub fn playSound(id: defs.Sound, channel: defs.Channel) void {
    _ = c.Mix_PlayChannel(@intFromEnum(channel), sounds[@intFromEnum(id)], 0);
}

fn loadSounds() !void {
    const soundsList = try allocator.alloc(*c.Mix_Chunk, defs.MAX_SND_CHANNELS);

    soundsList[@intFromEnum(defs.Sound.playerFire)] = c.Mix_LoadWAV("sounds/playerFire.ogg");
    soundsList[@intFromEnum(defs.Sound.alienFire)] = c.Mix_LoadWAV("sounds/alienFire.ogg");
    soundsList[@intFromEnum(defs.Sound.PlayerDies)] = c.Mix_LoadWAV("sounds/playerDies.ogg");
    soundsList[@intFromEnum(defs.Sound.alienDies)] = c.Mix_LoadWAV("sounds/alienDies.ogg");
    sounds = soundsList;
}
