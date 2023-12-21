const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});

const structs = @import("structs.zig");
const draw = @import("draw.zig");
const defs = @import("defs.zig");
const init = @import("init.zig");
const input = @import("input.zig");

pub var app = structs.App{};

var player = structs.Entity{};

var bullet = structs.Entity{};

pub fn main() !void {
    init.initSDL();
    defer init.exitSDL();

    player.x = 100;
    player.y = 100;
    player.texture = try draw.loadTexture("assets/craft.png");

    bullet.texture = try draw.loadTexture("assets/playerBullet.png");

    while (true) {
        draw.prepareScene();
        input.handleInput();

        if (app.up) {
            player.y -= 4;
        }
        if (app.down) {
            player.y += 4;
        }
        if (app.left) {
            player.x -= 4;
        }
        if (app.right) {
            player.x += 4;
        }
        if (app.fire and bullet.health == 0) {
            bullet.x = player.x + 55;
            bullet.y = player.y + 33;
            bullet.dx = 16;
            bullet.dy = 0;
            bullet.health = 1;
        }

        bullet.x += bullet.dx;
        bullet.y += bullet.dy;

        if (bullet.x > defs.SCREEN_WIDTH) {
            bullet.health = 0;
        }

        draw.blit(player.texture, player.x, player.y);

        if (bullet.health > 0) {
            draw.blit(bullet.texture, bullet.x, bullet.y);
        }

        draw.presentScene();
        c.SDL_Delay(16);
    }
}
