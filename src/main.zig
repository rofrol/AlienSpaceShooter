//test comment

const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_image.h");
});
const tester = 1234;
const SCREEN_WIDTH = 1280;
const SCREEN_HEIGHT = 720;

const App = struct {
    renderer: *c.SDL_Renderer,
    window: *c.SDL_Window,
    up: bool,
    down: bool,
    left: bool,
    right: bool,
    fire: bool,
};

var app = App{
    .renderer = undefined,
    .window = undefined,
    .up = false,
    .down = false,
    .left = false,
    .right = false,
    .fire = false,
};

const Entity = struct {
    x: i32 = 0,
    y: i32 = 0,
    dx: i32 = 0,
    dy: i32 = 0,
    health: i32 = 0,
    texture: *c.SDL_Texture = undefined,
};

var player = Entity{};

var bullet = Entity{};

pub fn main() !void {
    initSDL();
    defer exitSDL();

    player.x = 100;
    player.y = 100;
    player.texture = try loadTexture("assets/craft.png");

    bullet.texture = try loadTexture("assets/playerBullet.png");

    while (true) {
        prepareScene();
        handleInput();

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

        if (bullet.x > SCREEN_WIDTH) {
            bullet.health = 0;
        }

        blit(player.texture, player.x, player.y);

        if (bullet.health > 0) {
            blit(bullet.texture, bullet.x, bullet.y);
        }

        presentScene();
        c.SDL_Delay(16);
    }
}

fn blit(texture: *c.SDL_Texture, x: i32, y: i32) void {
    var dest = c.SDL_Rect{
        .x = x,
        .y = y,
        .w = 0,
        .h = 0,
    };

    _ = c.SDL_QueryTexture(texture, null, null, &dest.w, &dest.h);
    _ = c.SDL_RenderCopy(app.renderer, texture, null, &dest);
}

fn initSDL() void {
    _ = c.SDL_Init(c.SDL_INIT_VIDEO);
    app.window = c.SDL_CreateWindow(
        "Alien Space Shooter",
        c.SDL_WINDOWPOS_CENTERED,
        c.SDL_WINDOWPOS_CENTERED,
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        0,
    ).?;
    app.renderer = c.SDL_CreateRenderer(app.window, 0, c.SDL_RENDERER_PRESENTVSYNC).?;
    _ = c.IMG_Init(c.IMG_INIT_PNG);
}

fn exitSDL() void {
    c.SDL_Quit();
    c.SDL_DestroyWindow(app.window);
    c.SDL_DestroyRenderer(app.renderer);
}

fn handleInput() void {
    var sdl_event: c.SDL_Event = undefined;
    while (c.SDL_PollEvent(&sdl_event) != 0) {
        switch (sdl_event.type) {
            c.SDL_KEYDOWN => keyDown(&sdl_event.key),
            c.SDL_KEYUP => keyUp(&sdl_event.key),
            c.SDL_QUIT => {
                exitSDL();
                std.os.exit(0);
            },
            else => {},
        }
    }
}

fn keyDown(event: *c.SDL_KeyboardEvent) void {
    if (event.repeat == 0) {
        if (event.keysym.scancode == c.SDL_SCANCODE_RIGHT) {
            app.right = true;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_LEFT) {
            app.left = true;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_UP) {
            app.up = true;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_DOWN) {
            app.down = true;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_SPACE) {
            app.fire = true;
        }
    }
}

fn keyUp(event: *c.SDL_KeyboardEvent) void {
    if (event.repeat == 0) {
        if (event.keysym.scancode == c.SDL_SCANCODE_RIGHT) {
            app.right = false;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_LEFT) {
            app.left = false;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_UP) {
            app.up = false;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_DOWN) {
            app.down = false;
        }
        if (event.keysym.scancode == c.SDL_SCANCODE_SPACE) {
            app.fire = false;
        }
    }
}

fn loadTexture(filename: [*]const u8) !*c.SDL_Texture {
    var texture: *c.SDL_Texture = undefined;
    c.SDL_LogMessage(c.SDL_LOG_CATEGORY_APPLICATION, c.SDL_LOG_PRIORITY_INFO, "Loading %s", filename);
    texture = c.IMG_LoadTexture(app.renderer, filename).?;
    return texture;
}

fn prepareScene() void {
    _ = c.SDL_SetRenderDrawColor(app.renderer, 0xff, 0xff, 0xff, 0xff);
    _ = c.SDL_RenderClear(app.renderer);
}

fn presentScene() void {
    c.SDL_RenderPresent(app.renderer);
}
