package ascii_particles

import "core:math"
import "core:math/rand"
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

make_sparks_emitter :: proc(x, y: f32) -> Emitter {
	return Emitter {
		pos           = {x, y},
		area          = {2, 2},
		spawn_rate    = 0,  // one-shot by default
		char_variants = {"*", ".", "+", "'"},
		char_count    = 4,
		color_start   = {255, 240, 80, 255},   // bright yellow
		color_end     = {230, 120, 20, 200},    // orange
		lifetime_min  = 0.3,
		lifetime_max  = 0.8,
		vel_min       = {-200, -200},
		vel_max       = {200, 200},
		font_size     = 16,
		behavior      = .Gravity,
		active        = true,
		one_shot      = true,
		burst_count   = 50,
	}
}

make_rain_emitter :: proc(x, y: f32) -> Emitter {
	return Emitter {
		pos           = {x, y},
		area          = {400, 4},  // wide horizontal band
		spawn_rate    = 120,
		char_variants = {"|", "/", ".", "|"},
		char_count    = 3,         // 3 unique, weighted toward |
		color_start   = {100, 140, 220, 180},   // blue tint
		color_end     = {60, 100, 180, 100},     // darker blue, more transparent
		lifetime_min  = 0.4,
		lifetime_max  = 0.8,
		vel_min       = {-30, 200},
		vel_max       = {-10, 300},
		font_size     = 18,
		behavior      = .None,
		active        = true,
	}
}

make_wind_emitter :: proc(x, y: f32) -> Emitter {
	return Emitter {
		pos           = {x, y},
		area          = {10, 80},  // tall vertical band
		spawn_rate    = 40,
		char_variants = {"~", ".", "-", "'"},
		char_count    = 4,
		color_start   = {180, 180, 190, 160},  // light gray
		color_end     = {120, 120, 130, 0},    // fades to transparent
		lifetime_min  = 0.8,
		lifetime_max  = 1.6,
		vel_min       = {40, -10},
		vel_max       = {80, 10},
		font_size     = 16,
		behavior      = .Wobble,
		active        = true,
	}
}

make_smoke_emitter :: proc(x, y: f32) -> Emitter {
	return Emitter {
		pos           = {x, y},
		area          = {12, 4},
		spawn_rate    = 25,
		char_variants = {".", "o", "O", "*"},
		char_count    = 4,
		color_start   = {120, 120, 120, 200},  // medium gray
		color_end     = {60, 60, 60, 60},       // dark gray, fading
		lifetime_min  = 1.0,
		lifetime_max  = 2.5,
		vel_min       = {-5, -20},
		vel_max       = {5, -10},
		font_size     = 22,
		behavior      = .Spread,
		active        = true,
	}
}

make_blood_emitter :: proc(x, y: f32) -> Emitter {
	return Emitter {
		pos           = {x, y},
		area          = {2, 2},
		spawn_rate    = 0,  // one-shot
		char_variants = {".", ",", "'", "*"},
		char_count    = 4,
		color_start   = {160, 10, 10, 255},    // dark red
		color_end     = {40, 0, 0, 180},        // near black
		lifetime_min  = 0.4,
		lifetime_max  = 1.0,
		vel_min       = {-80, -80},
		vel_max       = {80, 30},
		font_size     = 16,
		behavior      = .Gravity,
		active        = true,
		one_shot      = true,
		burst_count   = 35,
	}
}

// Spawns the correct emitter type at position, with optional one-shot override
spawn_emitter_at :: proc(x, y: f32, typ: Emitter_Type, one_shot: bool) -> Emitter {
	e: Emitter
	switch typ {
	case .Fire:   e = make_fire_emitter(x, y)
	case .Sparks: e = make_sparks_emitter(x, y)
	case .Rain:   e = make_rain_emitter(x, y)
	case .Wind:   e = make_wind_emitter(x, y)
	case .Smoke:  e = make_smoke_emitter(x, y)
	case .Blood:  e = make_blood_emitter(x, y)
	}

	if one_shot && !e.one_shot {
		e.one_shot = true
		e.burst_count = 40
		e.spawn_rate = 0
	}

	return e
}

// Display names for HUD
emitter_type_name :: proc(typ: Emitter_Type) -> cstring {
	switch typ {
	case .Fire:   return "Fire"
	case .Sparks: return "Sparks"
	case .Rain:   return "Rain"
	case .Wind:   return "Wind"
	case .Smoke:  return "Smoke"
	case .Blood:  return "Blood"
	}
	return "?"
}
