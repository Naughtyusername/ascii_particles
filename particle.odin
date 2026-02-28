package ascii_particles

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

// --- Types ---

Particle_Behavior :: enum {
	None,
	Flicker, // fire: random vel_x jitter each frame
	Gravity, // sparks/blood: downward acceleration
	Wobble,  // wind: sine wave on vel_y
	Spread,  // smoke: widens horizontal drift over lifetime
}

Particle :: struct {
	pos:       [2]f32,
	vel:       [2]f32,
	lifetime:  f32,
	max_life:  f32,
	char:      cstring,
	color:     rl.Color,
	color_end: rl.Color,
	font_size: i32,
	alive:     bool,
	behavior:  Particle_Behavior,
}

Emitter_Type :: enum {
	Fire,
	Sparks,
	Rain,
	Wind,
	Smoke,
	Blood,
}

// --- Pool ---

MAX_PARTICLES :: 4096

Particle_Pool :: struct {
	particles:  [MAX_PARTICLES]Particle,
	free_list:  [MAX_PARTICLES]i32,
	free_count: i32,
}

init_pool :: proc(pool: ^Particle_Pool) {
	// Push all indices onto the free list (reverse order so index 0 is popped first)
	for i in 0 ..< MAX_PARTICLES {
		pool.free_list[i] = i32(MAX_PARTICLES - 1 - i)
	}
	pool.free_count = MAX_PARTICLES
}

alloc_particle :: proc(pool: ^Particle_Pool) -> (^Particle, i32, bool) {
	if pool.free_count <= 0 {
		return nil, -1, false
	}
	pool.free_count -= 1
	idx := pool.free_list[pool.free_count]
	p := &pool.particles[idx]
	p.alive = true
	return p, idx, true
}

free_particle :: proc(pool: ^Particle_Pool, idx: i32) {
	pool.particles[idx] = {} // zero out
	pool.free_list[pool.free_count] = idx
	pool.free_count += 1
}

// --- Utilities ---

rand_range :: proc(lo, hi: f32) -> f32 {
	return lo + rand.float32() * (hi - lo)
}

lerp_color :: proc(a, b: rl.Color, t: f32) -> rl.Color {
	t_clamped := clamp(t, 0, 1)
	inv := 1.0 - t_clamped
	return {
		u8(f32(a.r) * inv + f32(b.r) * t_clamped),
		u8(f32(a.g) * inv + f32(b.g) * t_clamped),
		u8(f32(a.b) * inv + f32(b.b) * t_clamped),
		u8(f32(a.a) * inv + f32(b.a) * t_clamped),
	}
}

// --- Emitter ---

MAX_EMITTERS :: 32
MAX_CHAR_VARIANTS :: 4

Emitter :: struct {
	pos:           [2]f32,
	area:          [2]f32, // spawn area width/height
	spawn_rate:    f32,    // particles per second
	spawn_accum:   f32,    // fractional accumulator
	char_variants: [MAX_CHAR_VARIANTS]cstring,
	char_count:    i32,
	color_start:   rl.Color,
	color_end:     rl.Color,
	lifetime_min:  f32,
	lifetime_max:  f32,
	vel_min:       [2]f32,
	vel_max:       [2]f32,
	font_size:     i32,
	behavior:      Particle_Behavior,
	active:        bool,
	one_shot:      bool, // deactivate after first burst
	burst_count:   i32,  // how many to spawn in a one-shot burst
}

update_emitter :: proc(emitter: ^Emitter, pool: ^Particle_Pool, dt: f32) {
	if !emitter.active do return

	if emitter.one_shot {
		for _ in 0 ..< emitter.burst_count {
			spawn_from_emitter(emitter, pool)
		}
		emitter.active = false
		return
	}

	emitter.spawn_accum += emitter.spawn_rate * dt
	for emitter.spawn_accum >= 1.0 {
		spawn_from_emitter(emitter, pool)
		emitter.spawn_accum -= 1.0
	}
}

spawn_from_emitter :: proc(emitter: ^Emitter, pool: ^Particle_Pool) {
	p, _, ok := alloc_particle(pool)
	if !ok do return

	p.pos.x = emitter.pos.x + rand_range(-emitter.area.x * 0.5, emitter.area.x * 0.5)
	p.pos.y = emitter.pos.y + rand_range(-emitter.area.y * 0.5, emitter.area.y * 0.5)
	p.vel.x = rand_range(emitter.vel_min.x, emitter.vel_max.x)
	p.vel.y = rand_range(emitter.vel_min.y, emitter.vel_max.y)
	p.lifetime = rand_range(emitter.lifetime_min, emitter.lifetime_max)
	p.max_life = p.lifetime
	p.char = emitter.char_variants[rand.int31() % emitter.char_count]
	p.color = emitter.color_start
	p.color_end = emitter.color_end
	p.font_size = emitter.font_size
	p.behavior = emitter.behavior
}

// --- Update & Draw ---

update_particles :: proc(pool: ^Particle_Pool, dt: f32) {
	for i in 0 ..< MAX_PARTICLES {
		p := &pool.particles[i]
		if !p.alive do continue

		// Age
		p.lifetime -= dt
		if p.lifetime <= 0 {
			free_particle(pool, i32(i))
			continue
		}

		// Behavior-specific updates
		switch p.behavior {
		case .Flicker:
			p.vel.x += rand_range(-120, 120) * dt
		case .Gravity:
			p.vel.y += 300 * dt
		case .Wobble:
			age := 1.0 - (p.lifetime / p.max_life)
			p.vel.y += math.sin(age * 12) * 30 * dt
		case .Spread:
			age := 1.0 - (p.lifetime / p.max_life)
			p.vel.x += rand_range(-60, 60) * age * dt // wider drift as particle ages
		case .None:
		// nothing
		}

		// Move
		p.pos += p.vel * dt
	}
}

draw_particles :: proc(pool: ^Particle_Pool) {
	for i in 0 ..< MAX_PARTICLES {
		p := &pool.particles[i]
		if !p.alive do continue

		// Color lerp + alpha fade over lifetime
		age_ratio := 1.0 - (p.lifetime / p.max_life)
		col := lerp_color(p.color, p.color_end, age_ratio)
		col.a = u8(f32(col.a) * (1.0 - age_ratio * age_ratio)) // quadratic fade on top

		rl.DrawText(p.char, i32(p.pos.x), i32(p.pos.y), p.font_size, col)
	}
}

active_count :: proc(pool: ^Particle_Pool) -> i32 {
	return MAX_PARTICLES - pool.free_count
}
