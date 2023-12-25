const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const defs = @import("defs.zig");
const main = @import("main.zig");

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
    _ = c.IMG_Init(c.IMG_INIT_PNG);
}

pub fn exitSDL() void {
    c.SDL_Quit();
    c.SDL_DestroyWindow(main.app.window);
    c.SDL_DestroyRenderer(main.app.renderer);
}
