const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const main = @import("main.zig");

pub fn prepareScene() void {
    _ = c.SDL_SetRenderDrawColor(main.app.renderer, 32, 32, 32, 0xff);
    _ = c.SDL_RenderClear(main.app.renderer);
}

pub fn presentScene() void {
    c.SDL_RenderPresent(main.app.renderer);
}

pub fn loadTexture(filename: []const u8) !*c.SDL_Texture {
    var texture: *c.SDL_Texture = undefined;
    const v = try main.app.textures.getOrPut(filename);
    if (!v.found_existing) {
        v.value_ptr.* = c.IMG_LoadTexture(main.app.renderer, filename.ptr).?;
        c.SDL_LogMessage(
            c.SDL_LOG_CATEGORY_APPLICATION,
            c.SDL_LOG_PRIORITY_INFO,
            "Loading %s",
            filename.ptr,
        );
    }
    texture = v.value_ptr.*;

    return texture;
}

pub fn blit(texture: *c.SDL_Texture, x: f32, y: f32) void {
    if (x < std.math.maxInt(c_int) and y < std.math.maxInt(c_int)) {
        var dest = c.SDL_Rect{
            .x = @intFromFloat(x),
            .y = @intFromFloat(y),
            .w = 0,
            .h = 0,
        };

        _ = c.SDL_QueryTexture(
            texture,
            null,
            null,
            &dest.w,
            &dest.h,
        );
        _ = c.SDL_RenderCopy(
            main.app.renderer,
            texture,
            null,
            &dest,
        );
    }
}

pub fn blitRect(texture: *c.SDL_Texture, src: *c.SDL_Rect, x: i32, y: i32) void {
    var dest = c.SDL_Rect{
        .x = x,
        .y = y,
        .w = src.w,
        .h = src.h,
    };
    _ = c.SDL_RenderCopy(
        main.app.renderer,
        texture,
        src,
        &dest,
    );
}
