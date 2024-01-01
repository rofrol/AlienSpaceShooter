pub const SCREEN_WIDTH = 1280;
pub const SCREEN_HEIGHT = 720;
pub const FPS = 60;

pub const SIDE_PLAYER = 0;
pub const SIDE_ALIEN = 1;

pub const PLAYER_SPEED = 4;
pub const PLAYER_BULLET_SPEED = 20;
pub const ALIEN_BULLET_SPEED = 8;

pub const MAX_KEYBOARD_KEYS = 350;

pub const MAX_STARS = 500;

pub const MAX_SND_CHANNELS = 8;

pub const Channel = enum(i8) {
    any = -1,
    player,
    alien,
};

pub const Sound = enum(usize) {
    playerFire,
    alienFire,
    PlayerDies,
    alienDies,
    max,
};
