package ascii_particles

import rl "vendor:raylib"

make_fire_emitter :: proc(x, y: f32) -> Emitter {
	return Emitter {
		pos           = {x, y},
		area          = {20, 4},
		spawn_rate    = 60,
		char_variants = {"^", "*", "\"", "'"},
		char_count    = 4,
		color_start   = {255, 220, 50, 255},  // bright yellow
		color_end     = {180, 30, 10, 180},    // dark red, semi-transparent
		lifetime_min  = 0.6,
		lifetime_max  = 1.4,
		vel_min       = {-15, -60},
		vel_max       = {15, -30},
		font_size     = 20,
		behavior      = .Flicker,
		active        = true,
	}
}
