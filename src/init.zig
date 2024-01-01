const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
    // @cInclude("SDL2/SDL_mixer.h");
});

const mixer = @cImport({
    // @cInclude("SDL2/SDL.h");
    // @cInclude("SDL2/SDL_image.h");
    @cInclude("SDL2/SDL_mixer.h");
});

const defs = @import("defs.zig");
const main = @import("main.zig");
const stage = @import("stage.zig");

pub fn initSDL() void {
    _ = c.SDL_Init(c.SDL_INIT_VIDEO);
    main.app.window = c.SDL_CreateWindow(
        "Alien Space Shooter",
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        defs.SCREEN_WIDTH,
        defs.SCREEN_HEIGHT,
        0,
    ).?;
    main.app.renderer = c.SDL_CreateRenderer(main.app.window, 0, c.SDL_RENDERER_PRESENTVSYNC).?;
    _ = mixer.Mix_OpenAudio(44100, mixer.MIX_DEFAULT_FORMAT, 2, 1024);
    _ = mixer.Mix_AllocateChannels(defs.MAX_SND_CHANNELS);
    _ = c.IMG_Init(c.IMG_INIT_PNG);
}

pub fn exitSDL() void {
    var f = main.stage.fighters.first;

    while (f) |node| {
        stage.allocator.destroy(node.data);
        f = node.next;
        main.stage.fighters.remove(node);
        stage.allocator.destroy(node);
    }

    var b = main.stage.bullets.first;

    while (b) |node| {
        stage.allocator.destroy(node.data);
        b = node.next;
        main.stage.bullets.remove(node);
        stage.allocator.destroy(node);
    }

    var e = main.stage.explosions.first;

    while (e) |node| {
        stage.allocator.destroy(node.data);
        e = node.next;
        main.stage.explosions.remove(node);
        stage.allocator.destroy(node);
    }

    var d = main.stage.debris.first;

    while (d) |node| {
        stage.allocator.destroy(node.data);
        d = node.next;
        main.stage.debris.remove(node);
        stage.allocator.destroy(node);
    }

    c.SDL_DestroyWindow(main.app.window);
    c.SDL_DestroyRenderer(main.app.renderer);
    mixer.Mix_Quit();
    c.IMG_Quit();
    c.SDL_Quit();
}
