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

make_lightning_emitter :: proc(x, y: f32) -> Emitter {
	// Narrow tall band — particles appear along a vertical stripe and die fast
	return Emitter {
		pos           = {x, y},
		area          = {6, 180},
		spawn_rate    = 0,
		char_variants = {"|", "/", "*", "+"},
		char_count    = 4,
		color_start   = {220, 240, 255, 255},  // near-white with blue tint
		color_end     = {100, 160, 255, 120},   // fading cyan
		lifetime_min  = 0.04,
		lifetime_max  = 0.18,
		vel_min       = {-20, -10},
		vel_max       = {20, 10},
		font_size     = 20,
		behavior      = .None,
		active        = true,
		one_shot      = true,
		burst_count   = 60,
	}
}

make_frost_emitter :: proc(x, y: f32) -> Emitter {
	// Particles spread outward from center and decelerate to a stop — crystallizing frost
	return Emitter {
		pos           = {x, y},
		area          = {4, 4},
		spawn_rate    = 30,
		char_variants = {"*", "+", ".", "'"},
		char_count    = 4,
		color_start   = {200, 230, 255, 230},  // icy white-blue
		color_end     = {120, 180, 220, 80},    // faded cyan
		lifetime_min  = 1.2,
		lifetime_max  = 2.5,
		vel_min       = {-80, -80},
		vel_max       = {80, 80},
		font_size     = 16,
		behavior      = .Drag,
		active        = true,
	}
}

make_dust_emitter :: proc(x, y: f32) -> Emitter {
	// Debris burst — like a wall getting hit
	return Emitter {
		pos           = {x, y},
		area          = {4, 4},
		spawn_rate    = 0,
		char_variants = {".", ",", "'", ":"},
		char_count    = 4,
		color_start   = {180, 150, 100, 220},  // sandy brown
		color_end     = {100, 80, 50, 60},      // dark brown, fading
		lifetime_min  = 0.3,
		lifetime_max  = 0.9,
		vel_min       = {-100, -120},
		vel_max       = {100, 40},
		font_size     = 14,
		behavior      = .Gravity,
		active        = true,
		one_shot      = true,
		burst_count   = 30,
	}
}

make_magic_converge_emitter :: proc(x, y: f32) -> Emitter {
	// Particles spawn in a wide ring and rush inward, decelerating at center
	// The "charging up" effect — continuous, feels like gathering energy
	return Emitter {
		pos           = {x, y},
		area          = {160, 160},  // wide spawn ring
		spawn_rate    = 50,
		char_variants = {".", "*", "+", "'"},
		char_count    = 4,
		color_start   = {180, 80, 255, 200},   // purple
		color_end     = {255, 200, 255, 255},   // bright magenta-white at end
		lifetime_min  = 0.4,
		lifetime_max  = 0.8,
		vel_min       = {-200, -200},
		vel_max       = {200, 200},
		font_size     = 16,
		behavior      = .Drag,
		active        = true,
		inward        = true,  // particles rush toward center
	}
}

make_magic_burst_emitter :: proc(x, y: f32) -> Emitter {
	// Radial burst outward — the "release" effect
	return Emitter {
		pos           = {x, y},
		area          = {4, 4},
		spawn_rate    = 0,
		char_variants = {"*", "+", ".", "'"},
		char_count    = 4,
		color_start   = {255, 200, 255, 255},  // bright magenta-white
		color_end     = {120, 40, 200, 80},     // dark purple, fading
		lifetime_min  = 0.3,
		lifetime_max  = 0.7,
		vel_min       = {-180, -180},
		vel_max       = {180, 180},
		font_size     = 18,
		behavior      = .Drag,
		active        = true,
		one_shot      = true,
		burst_count   = 45,
	}
}

// Spawns the correct emitter type at position, with optional one-shot override
spawn_emitter_at :: proc(x, y: f32, typ: Emitter_Type, one_shot: bool) -> Emitter {
	e: Emitter
	switch typ {
	case .Fire:      e = make_fire_emitter(x, y)
	case .Sparks:    e = make_sparks_emitter(x, y)
	case .Rain:      e = make_rain_emitter(x, y)
	case .Wind:      e = make_wind_emitter(x, y)
	case .Smoke:     e = make_smoke_emitter(x, y)
	case .Blood:     e = make_blood_emitter(x, y)
	case .Lightning: e = make_lightning_emitter(x, y)
	case .Frost:     e = make_frost_emitter(x, y)
	case .Dust:      e = make_dust_emitter(x, y)
	case .Magic:     e = make_magic_converge_emitter(x, y)
	}

	// Magic: right-click uses the burst (release) variant instead
	if one_shot && typ == .Magic {
		e = make_magic_burst_emitter(x, y)
		return e
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
	case .Fire:      return "Fire"
	case .Sparks:    return "Sparks"
	case .Rain:      return "Rain"
	case .Wind:      return "Wind"
	case .Smoke:     return "Smoke"
	case .Blood:     return "Blood"
	case .Lightning: return "Lightning"
	case .Frost:     return "Frost"
	case .Dust:      return "Dust"
	case .Magic:     return "Magic"
	}
	return "?"
}
