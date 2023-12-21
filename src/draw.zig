const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
var app = &@import("main.zig").app;

pub fn prepareScene() void {
    _ = c.SDL_SetRenderDrawColor(app.*.renderer, 0xff, 0xff, 0xff, 0xff);
    _ = c.SDL_RenderClear(app.*.renderer);
}

pub fn presentScene() void {
    c.SDL_RenderPresent(app.*.renderer);
}

pub fn loadTexture(filename: [*]const u8) !*c.SDL_Texture {
    var texture: *c.SDL_Texture = undefined;
    c.SDL_LogMessage(c.SDL_LOG_CATEGORY_APPLICATION, c.SDL_LOG_PRIORITY_INFO, "Loading %s", filename);
    texture = c.IMG_LoadTexture(app.*.renderer, filename).?;
    return texture;
}

pub fn blit(texture: *c.SDL_Texture, x: i32, y: i32) void {
    var dest = c.SDL_Rect{
        .x = x,
        .y = y,
        .w = 0,
        .h = 0,
    };

    _ = c.SDL_QueryTexture(texture, null, null, &dest.w, &dest.h);
    _ = c.SDL_RenderCopy(app.*.renderer, texture, null, &dest);
}
