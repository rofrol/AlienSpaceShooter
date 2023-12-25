const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const main = @import("main.zig");
const drawer = @import("draw.zig");
const structs = @import("structs.zig");
const defs = @import("defs.zig");

var player: *structs.Entity = undefined;
var bulletTexture: *c.SDL_Texture = undefined;
const bulletsList = std.DoublyLinkedList(*structs.Entity);

pub fn initStage() !void {
    const stage_p = try allocator.create(structs.Stage);
    main.stage = stage_p.*;

    main.stage.fighterTail = &main.stage.fighterHead;
    main.stage.bullets = bulletsList{};

    try initPlayer();

    bulletTexture = try drawer.loadTexture("assets/playerBullet.png");
}

fn initPlayer() !void {
    player = try allocator.create(structs.Entity);
    main.stage.fighterTail.next = player;
    main.stage.fighterTail = player;

    player.x = 100;
    player.y = 100;
    player.reload = 0;
    player.texture = try drawer.loadTexture("assets/craft.png");
    _ = c.SDL_QueryTexture(
        player.texture,
        null,
        null,
        &player.w,
        &player.h,
    );
}

pub fn logic() !void {
    try handlePlayer();
    handleBullets();
}

fn handlePlayer() !void {
    player.dx = 0;
    player.dy = 0;
    if (player.reload > 0) {
        player.reload -= 1;
    }

    if (main.app.keyboard[c.SDL_SCANCODE_UP]) {
        player.dy = -defs.PLAYER_SPEED;
    }
    if (main.app.keyboard[c.SDL_SCANCODE_DOWN]) {
        player.dy = defs.PLAYER_SPEED;
    }
    if (main.app.keyboard[c.SDL_SCANCODE_RIGHT]) {
        player.dx = defs.PLAYER_SPEED;
    }
    if (main.app.keyboard[c.SDL_SCANCODE_LEFT]) {
        player.dx = -defs.PLAYER_SPEED;
    }

    if (main.app.keyboard[c.SDL_SCANCODE_LCTRL] and player.reload == 0) {
        try fireBullet();
    }

    player.x += player.dx;
    player.y += player.dy;
}

fn fireBullet() !void {
    var bullet = try allocator.create(structs.Entity);
    bullet.x = player.x;
    bullet.y = player.y;
    bullet.dx = defs.PLAYER_BULLET_SPEED;
    bullet.health = 1;
    bullet.texture = bulletTexture;
    _ = c.SDL_QueryTexture(
        bullet.texture,
        null,
        null,
        &bullet.w,
        &bullet.h,
    );
    var node = try allocator.create(std.DoublyLinkedList(*structs.Entity).Node);
    node.data = bullet;
    main.stage.bullets.append(node);
    player.reload = 8;
}

fn handleBullets() void {
    var it = main.stage.bullets.first;
    while (it) |node| : (it = node.next) {
        const bullet = node.data;
        bullet.*.x += bullet.*.dx;
        bullet.*.y += bullet.*.dy;

        if (bullet.x > defs.SCREEN_WIDTH) {
            main.stage.bullets.remove(node);
            allocator.destroy(node.data);
        }
    }
}

pub fn draw() void {
    drawPlayer();

    drawBullets();
}

fn drawPlayer() void {
    drawer.blit(player.texture, player.x, player.y);
}

fn drawBullets() void {
    var it = main.stage.bullets.last;
    while (it) |node| : (it = node.prev) {
        const bullet = node.data;
        drawer.blit(bulletTexture, bullet.x, bullet.y);
    }
}
