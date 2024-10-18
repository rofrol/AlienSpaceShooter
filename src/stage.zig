const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();
const main = @import("main.zig");
const drawer = @import("draw.zig");
const structs = @import("structs.zig");
const defs = @import("defs.zig");
const utils = @import("utils.zig");
const sounds = @import("sounds.zig");
const text = @import("text.zig");
const highscores = @import("highscores.zig");

var player: *structs.Entity = undefined;

var playerTexture: *c.SDL_Texture = undefined;
var alienTexture: *c.SDL_Texture = undefined;
var bulletTexture: *c.SDL_Texture = undefined;
var alienBulletTexture: *c.SDL_Texture = undefined;
var explosionsTexture: *c.SDL_Texture = undefined;
var backgroundTexture: *c.SDL_Texture = undefined;

const bulletsList = std.DoublyLinkedList(*structs.Entity);
const fightersList = std.DoublyLinkedList(*structs.Entity);
const explosionsList = std.DoublyLinkedList(*structs.Explosion);
const debrisList = std.DoublyLinkedList(*structs.Debris);

var stars: []structs.Star = undefined;

var alienSpawnTimer: i32 = 0;
var stageResetTimer: i32 = 0;

var backgroundX: i32 = 0;

var highscore: i32 = 0;

pub var prng: std.Random.Xoshiro256 = undefined;
const rand = prng.random();

pub fn initStage() !void {
    main.app.delegate.logic = logic;
    main.app.delegate.draw = draw;

    const stage_p = try allocator.create(structs.Stage);
    main.stage = stage_p.*;

    main.stage.fighters = fightersList{};
    main.stage.bullets = bulletsList{};
    main.stage.explosions = explosionsList{};
    main.stage.debris = debrisList{};

    bulletTexture = try drawer.loadTexture("assets/playerBullet.png");
    alienTexture = try drawer.loadTexture("assets/alien.png");
    playerTexture = try drawer.loadTexture("assets/craft.png");
    alienBulletTexture = try drawer.loadTexture("assets/alienBullet.png");
    explosionsTexture = try drawer.loadTexture("assets/explosion.png");

    try resetStage();

    try initPlayer();
}

pub fn initBackground() !void {
    backgroundTexture = try drawer.loadTexture("assets/background4.png");

    backgroundX = 0;
}

fn resetStage() !void {
    var f = main.stage.fighters.first;

    while (f) |node| {
        allocator.destroy(node.data);
        f = node.next;
        main.stage.fighters.remove(node);
        allocator.destroy(node);
    }

    var b = main.stage.bullets.first;

    while (b) |node| {
        allocator.destroy(node.data);
        b = node.next;
        main.stage.bullets.remove(node);
        allocator.destroy(node);
    }

    var e = main.stage.explosions.first;

    while (e) |node| {
        allocator.destroy(node.data);
        e = node.next;
        main.stage.explosions.remove(node);
        allocator.destroy(node);
    }

    var d = main.stage.debris.first;

    while (d) |node| {
        allocator.destroy(node.data);
        d = node.next;
        main.stage.debris.remove(node);
        allocator.destroy(node);
    }

    alienSpawnTimer = 0;

    main.stage.score = 0;

    stageResetTimer = defs.FPS * 3;
}

fn initPlayer() !void {
    player = try allocator.create(structs.Entity);
    var node = try allocator.create(std.DoublyLinkedList(*structs.Entity).Node);
    node.data = player;
    main.stage.fighters.append(node);

    player.x = 100;
    player.y = 100;
    player.reload = 0;
    player.side = defs.SIDE_PLAYER;
    player.texture = playerTexture;
    player.health = 1;
    _ = c.SDL_QueryTexture(
        player.texture,
        null,
        null,
        &player.w,
        &player.h,
    );
}

pub fn initStarfield() !void {
    // stars = [_]structs.Star{makeStar()} ** defs.MAX_STARS;
    const starsList = try allocator.alloc(structs.Star, defs.MAX_STARS);
    for (0..defs.MAX_STARS) |i| {
        starsList[i] = makeStar();
    }
    stars = starsList;
}

fn makeStar() structs.Star {
    return structs.Star{
        .x = @mod(rand.int(i32), defs.SCREEN_WIDTH),
        .y = @mod(rand.int(i32), defs.SCREEN_HEIGHT),
        .speed = 1 + @mod(rand.int(u8), 8),
    };
}

pub fn logic() !void {
    handleBackground();
    handleStarfield();
    try handlePlayer();
    try handleAliens();
    handleFighters();
    try handleBullets();
    handleExplosions();
    handleDebris();
    try spawnAliens();

    clipPlayer();

    if (player.health == 0) {
        stageResetTimer -= 1;
        if (stageResetTimer == 0) {
            // try resetStage();
            highscores.addHighscore(main.stage.score);
            highscores.initHighscores();
        }
    }
}

pub fn handleBackground() void {
    backgroundX -= 1;

    if (backgroundX < -defs.SCREEN_WIDTH) {
        backgroundX = 0;
    }
}

pub fn handleStarfield() void {
    for (0..stars.len) |i| {
        var x = stars[i].x - stars[i].speed;
        if (x < 0) {
            x = defs.SCREEN_WIDTH + x;
        }
        const star = structs.Star{
            .speed = stars[i].speed,
            .x = x,
            .y = stars[i].y,
        };
        stars[i] = star;
    }
}

fn handlePlayer() !void {
    if (player.health > 0) {
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

        if (main.app.keyboard[c.SDL_SCANCODE_F] and player.reload == 0) {
            sounds.playSound(defs.Sound.playerFire, defs.Channel.player);
            try fireBullet();
        }

        // player.x += player.dx;
        // player.y += player.dy;
    }
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
    bullet.y += (@as(f32, @floatFromInt(player.h)) / 2) - (@as(f32, @floatFromInt(bullet.h)) / 2);
    bullet.x += (@as(f32, @floatFromInt(player.w)) / 2) - (@as(f32, @floatFromInt(bullet.w)) / 2);
    bullet.side = defs.SIDE_PLAYER;
    var node = try allocator.create(std.DoublyLinkedList(*structs.Entity).Node);
    node.data = bullet;
    main.stage.bullets.append(node);
    player.reload = 8;
}

fn handleAliens() !void {
    var f = main.stage.fighters.first;

    while (f) |node| : (f = node.next) {
        var fighter = node.data;
        if (fighter != player) {
            fighter.reload -= 1;
            if (fighter.reload == 0 and player.health > 0) {
                sounds.playSound(defs.Sound.alienFire, defs.Channel.alien);
                try fireAlienBullet(fighter);
            }
        }
    }
}

fn fireAlienBullet(fighter: *structs.Entity) !void {
    var bullet = try allocator.create(structs.Entity);
    var node = try allocator.create(std.DoublyLinkedList(*structs.Entity).Node);
    node.data = bullet;
    main.stage.bullets.append(node);
    bullet.x = fighter.x;
    bullet.y = fighter.y;
    bullet.health = 1;
    bullet.texture = alienBulletTexture;
    bullet.side = defs.SIDE_ALIEN;
    _ = c.SDL_QueryTexture(
        bullet.texture,
        null,
        null,
        &bullet.w,
        &bullet.h,
    );
    bullet.x += (@as(f32, @floatFromInt(fighter.w)) / 2) - (@as(f32, @floatFromInt(bullet.w)) / 2);
    bullet.y += (@as(f32, @floatFromInt(fighter.h)) / 2) - (@as(f32, @floatFromInt(bullet.h)) / 2);

    utils.calcSlope(
        player.x + (@as(f32, @floatFromInt(player.w)) / 2),
        player.y + (@as(f32, @floatFromInt(player.h)) / 2),
        fighter.x,
        fighter.y,
        &bullet.dx,
        &bullet.dy,
    );

    bullet.dx *= defs.ALIEN_BULLET_SPEED;
    bullet.dy *= defs.ALIEN_BULLET_SPEED;

    fighter.reload = @mod(rand.int(i32), defs.FPS) * 2;
}

fn handleFighters() void {
    var f = main.stage.fighters.first;
    while (f) |node| : (f = f.?.next) {
        const fighter = node.data;
        fighter.x += fighter.dx;
        fighter.y += fighter.dy;
        if (fighter != player and (fighter.x < @as(f32, @floatFromInt(-fighter.w)) or fighter.health == 0)) {
            main.stage.fighters.remove(node);
            allocator.destroy(fighter);
            if (node.prev != null) {
                node.prev.?.next = node.next;
                f = node.prev;
                allocator.destroy(node);
            } else if (node.next != null) {
                node.next.?.data.x += node.next.?.data.dx;
                node.next.?.data.y += node.next.?.data.dy;
                f = node.next;
                allocator.destroy(node);
            } else {
                allocator.destroy(node);
                break;
            }
        }
    }
}

fn handleBullets() !void {
    var b = main.stage.bullets.first;
    while (b) |node| : (b = b.?.next) {
        const bullet = node.data;
        bullet.*.x += bullet.*.dx;
        bullet.*.y += bullet.*.dy;

        if (try bulletHitFighter(bullet) or bullet.x < @as(f32, @floatFromInt(-bullet.w)) or bullet.y < @as(f32, @floatFromInt(-bullet.h)) or bullet.y > @as(f32, @floatFromInt(defs.SCREEN_HEIGHT)) or bullet.x > @as(f32, @floatFromInt(defs.SCREEN_WIDTH))) {
            main.stage.bullets.remove(node);
            allocator.destroy(node.data);
            if (node.prev != null) {
                node.prev.?.next = node.next;
                b = node.prev;
                allocator.destroy(node);
            } else if (node.next != null) {
                node.next.?.data.x += node.next.?.data.dx;
                node.next.?.data.y += node.next.?.data.dy;
                b = node.next;
                allocator.destroy(node);
            } else {
                allocator.destroy(node);
                break;
            }
        }
    }
}

fn bulletHitFighter(bullet: *structs.Entity) !bool {
    var f = main.stage.fighters.first;
    while (f) |node| : (f = node.next) {
        var fighter = node.data;
        if (fighter.health > 0 and fighter.side != bullet.side and utils.collision(
            bullet.x,
            bullet.y,
            bullet.w,
            bullet.h,
            fighter.x,
            fighter.y,
            fighter.w,
            fighter.h,
        )) {
            bullet.health = 0;
            fighter.health = 0;

            if (fighter == player) {
                sounds.playSound(defs.Sound.playerDies, defs.Channel.player);
            } else {
                sounds.playSound(defs.Sound.alienDies, defs.Channel.any);
                main.stage.score += 1;

                highscore = @max(highscore, main.stage.score);
            }

            try addExplosions(
                @as(i32, @intFromFloat(bullet.x)),
                @as(i32, @intFromFloat(bullet.y)),
                32,
            );

            try addDebris(fighter.*);

            return true;
        }
    }
    return false;
}

fn addExplosions(x: i32, y: i32, num: u8) !void {
    for (0..num) |_| {
        var e = try allocator.create(structs.Explosion);
        var node = try allocator.create(std.DoublyLinkedList(*structs.Explosion).Node);
        node.data = e;
        main.stage.explosions.append(node);

        e.x = @as(f32, @floatFromInt(
            @as(
                u32,
                @intCast(x),
            ) +% @mod(
                rand.int(u32),
                32,
            ) -% @mod(
                rand.int(u32),
                32,
            ),
        ));
        e.y = @as(f32, @floatFromInt(
            @as(
                u32,
                @intCast(y),
            ) +% @mod(
                rand.int(u32),
                32,
            ) -% @mod(
                rand.int(u32),
                32,
            ),
        ));

        e.dx = @as(
            f32,
            @floatFromInt(@mod(
                rand.int(u32),
                10,
            ) -% @mod(
                rand.int(u32),
                10,
            )),
        );
        e.dy = @as(
            f32,
            @floatFromInt(@mod(
                rand.int(u32),
                10,
            ) -% @mod(
                rand.int(u32),
                10,
            )),
        );

        e.dx /= 10;
        e.dy /= 10;

        switch (rand.int(u2)) {
            0 => e.r = 255,
            1 => {
                e.r = 255;
                e.g = 128;
            },
            2 => {
                e.r = 255;
                e.g = 255;
            },
            else => {
                e.r = 255;
                e.g = 255;
                e.b = 255;
            },
        }
        e.a = @mod(rand.int(u8), defs.FPS * 3);
    }
}

fn addDebris(entity: structs.Entity) !void {
    var x: i32 = 0;
    var y: i32 = 0;
    const w = @divFloor(entity.w, 2);
    const h = @divFloor(entity.h, 2);

    while (y <= h) : (y += h) {
        while (x <= w) : (x += w) {
            var debris = try allocator.create(structs.Debris);
            var node = try allocator.create(std.DoublyLinkedList(*structs.Debris).Node);
            node.data = debris;
            main.stage.debris.append(node);

            debris.x = entity.x + @as(f32, @floatFromInt(@divFloor(entity.w, 2)));
            debris.y = entity.y + @as(f32, @floatFromInt(@divFloor(entity.w, 2)));
            debris.dx = @as(f32, @floatFromInt(@mod(rand.int(i32), 5) - @mod(rand.int(i32), 5)));
            debris.dy = @as(f32, @floatFromInt(-(5 + @mod(rand.int(i32), 12))));
            debris.life = defs.FPS * 2;
            debris.texture = entity.texture;

            debris.rect.x = x;
            debris.rect.y = y;
            debris.rect.w = w;
            debris.rect.h = h;
        }
    }
}

fn spawnAliens() !void {
    alienSpawnTimer -= 1;

    if (alienSpawnTimer <= 0) {
        var alien = try allocator.create(structs.Entity);
        alien.x = defs.SCREEN_WIDTH;
        alien.texture = alienTexture;
        _ = c.SDL_QueryTexture(
            alien.texture,
            null,
            null,
            &alien.w,
            &alien.h,
        );
        alien.y = rand.float(f32) * (defs.SCREEN_HEIGHT - (@as(f32, @floatFromInt(alien.h)) / 2));
        alien.dx = -((rand.float(f32) + 4));
        alien.health = 1;
        alien.side = defs.SIDE_ALIEN;
        alien.reload = defs.FPS * (1 + @mod(rand.int(i32), 3));
        var node = try allocator.create(std.DoublyLinkedList(*structs.Entity).Node);
        node.data = alien;
        main.stage.fighters.append(node);

        alienSpawnTimer = @intFromFloat(30 + (rand.float(f32) * 60));
    }
}

fn handleExplosions() void {
    var e = main.stage.explosions.first;

    while (e) |node| : (e = e.?.next) {
        var explosion = node.data;

        explosion.x += explosion.dx;
        explosion.y += explosion.dy;

        if (explosion.a > 0) {
            explosion.a -= 1;
        }
        if (explosion.a <= 0) {
            allocator.destroy(node.data);
            main.stage.explosions.remove(node);
            if (node.prev != null) {
                node.prev.?.next = node.next;
                e = node.prev;
            } else if (node.next != null) {
                node.next.?.data.x += node.next.?.data.dx;
                node.next.?.data.y += node.next.?.data.dy;
                e = node.next;
            } else {
                allocator.destroy(node);
                break;
            }
            allocator.destroy(node);
        }
    }
}

fn handleDebris() void {
    var d = main.stage.debris.first;

    while (d) |node| : (d = d.?.next) {
        var debris = node.data;
        debris.x += debris.dx;
        debris.y += debris.dy;

        debris.dy += 0.5;
        debris.life -= 1;
        if (debris.life <= 0) {
            main.stage.debris.remove(node);
            allocator.destroy(node.data);
            if (node.prev != null) {
                node.prev.?.next = node.next;
                d = node.prev;
            } else if (node.next != null) {
                node.next.?.data.x += node.next.?.data.dx;
                node.next.?.data.y += node.next.?.data.dy;
                d = node.next;
            } else {
                allocator.destroy(node);
                break;
            }
            allocator.destroy(node);
        }
    }
}

pub fn draw() !void {
    drawBackground();

    drawStarfield();

    drawFighters();

    drawDebris();

    drawExplosions();

    drawBullets();

    try drawHUD();
}

pub fn drawBackground() void {
    var dest: c.SDL_Rect = c.SDL_Rect{};
    var x = backgroundX;
    while (x < defs.SCREEN_WIDTH) : (x += defs.SCREEN_WIDTH) {
        dest.x = x;
        dest.y = 0;
        dest.w = defs.SCREEN_WIDTH;
        dest.h = defs.SCREEN_HEIGHT;

        _ = c.SDL_RenderCopy(main.app.renderer, backgroundTexture, null, &dest);
    }
}

pub fn drawStarfield() void {
    for (stars) |star| {
        const color: u8 = @as(u8, 30 * star.speed);

        _ = c.SDL_SetRenderDrawColor(main.app.renderer, color, color, color, 255);

        _ = c.SDL_RenderDrawLine(main.app.renderer, star.x, star.y, star.x, star.y + 3);
    }
}

fn drawDebris() void {
    var d = main.stage.debris.first;

    while (d) |node| : (d = node.next) {
        const debris = node.data;
        drawer.blitRect(
            debris.texture,
            &debris.rect,
            @as(i32, @intFromFloat(debris.x)),
            @as(i32, @intFromFloat(debris.y)),
        );
    }
}

fn drawExplosions() void {
    var e = main.stage.explosions.first;

    _ = c.SDL_SetRenderDrawBlendMode(main.app.renderer, c.SDL_BLENDMODE_ADD);
    _ = c.SDL_SetTextureBlendMode(explosionsTexture, c.SDL_BLENDMODE_ADD);

    while (e) |node| : (e = node.next) {
        const explosion = node.data;
        _ = c.SDL_SetTextureColorMod(explosionsTexture, explosion.r, explosion.g, explosion.b);
        _ = c.SDL_SetTextureAlphaMod(explosionsTexture, explosion.a);

        drawer.blit(explosionsTexture, explosion.x, explosion.y);
    }

    _ = c.SDL_SetRenderDrawBlendMode(main.app.renderer, c.SDL_BLENDMODE_NONE);
}

fn drawFighters() void {
    var f = main.stage.fighters.last;
    while (f) |node| : (f = node.prev) {
        const fighter = node.data;
        if (fighter.health > 0) {
            drawer.blit(fighter.texture, fighter.x, fighter.y);
        }
    }
}

fn drawBullets() void {
    var b = main.stage.bullets.last;
    while (b) |node| : (b = node.prev) {
        const bullet = node.data;
        drawer.blit(bullet.texture, bullet.x, bullet.y);
    }
}

fn clipPlayer() void {
    if (player.x < 0) {
        player.x = 0;
    }
    if (player.y < 0) {
        player.y = 0;
    }
    if (player.x > @as(f32, @floatFromInt(defs.SCREEN_WIDTH / 2))) {
        player.x = @as(f32, @floatFromInt(defs.SCREEN_WIDTH / 2));
    }
    if (player.y > @as(f32, @floatFromInt(defs.SCREEN_HEIGHT - player.h))) {
        player.y = @as(f32, @floatFromInt(defs.SCREEN_HEIGHT - player.h));
    }
}

fn drawHUD() !void {
    try text.drawText(
        10,
        10,
        255,
        255,
        255,
        comptime "SCORE: {any}",
        .{main.stage.score},
    );
    if (main.stage.score > 0 and main.stage.score == highscore) {
        try text.drawText(
            1020,
            10,
            0,
            255,
            0,
            comptime "HIGHSCORE: {any}",
            .{highscore},
        );
    } else {
        try text.drawText(
            1020,
            10,
            255,
            255,
            255,
            comptime "HIGHSCORE: {any}",
            .{highscore},
        );
    }
}
