package ascii_particles

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

pool: Particle_Pool
emitters: [MAX_EMITTERS]Emitter
selected: Emitter_Type
show_debug: bool
screen_flash: f32   // 0-1, decays each frame (lightning)
screen_shake: f32   // 0-1, decays each frame (impacts)
shake_offset: [2]i32

main :: proc() {
	rl.InitWindow(1200, 680, "ASCII Particles")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	init_pool(&pool)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		mouse := rl.GetMousePosition()

		// --- Input: type selection ---

		if rl.IsKeyPressed(.ONE)   do selected = .Fire
		if rl.IsKeyPressed(.TWO)   do selected = .Sparks
		if rl.IsKeyPressed(.THREE) do selected = .Rain
		if rl.IsKeyPressed(.FOUR)  do selected = .Wind
		if rl.IsKeyPressed(.FIVE)  do selected = .Smoke
		if rl.IsKeyPressed(.SIX)   do selected = .Blood
		if rl.IsKeyPressed(.SEVEN) do selected = .Lightning
		if rl.IsKeyPressed(.EIGHT) do selected = .Frost
		if rl.IsKeyPressed(.NINE)  do selected = .Dust
		if rl.IsKeyPressed(.ZERO)  do selected = .Magic

		// Left click: spawn emitter(s)
		if rl.IsMouseButtonPressed(.LEFT) {
			spawn_selected(mouse.x, mouse.y, false)
		}

		// Right click: one-shot burst
		if rl.IsMouseButtonPressed(.RIGHT) {
			spawn_selected(mouse.x, mouse.y, true)
		}

		// Space: clear everything
		if rl.IsKeyPressed(.SPACE) {
			init_pool(&pool)
			emitters = {}
			screen_flash = 0
			screen_shake = 0
		}

		// Tab: toggle debug overlay
		if rl.IsKeyPressed(.TAB) {
			show_debug = !show_debug
		}

		// --- Update ---

		for &e in emitters {
			update_emitter(&e, &pool, dt)
		}
		update_particles(&pool, dt)

		// Decay screen effects
		if screen_flash > 0 {
			screen_flash -= dt * 8
			if screen_flash < 0 do screen_flash = 0
		}
		if screen_shake > 0 {
			screen_shake -= dt * 5 // ~200ms full decay (slower falloff)
			if screen_shake < 0 do screen_shake = 0
			// Random offset that shrinks with decay
			magnitude := i32(screen_shake * 14) // max 14px offset
			shake_offset = {
				i32(rand.int31() % (magnitude * 2 + 1)) - magnitude,
				i32(rand.int31() % (magnitude * 2 + 1)) - magnitude,
			}
		} else {
			shake_offset = {0, 0}
		}

		// --- Draw ---

		rl.BeginDrawing()
		rl.ClearBackground({20, 18, 24, 255})

		// Debug atmosphere grid (with shake)
		if show_debug {
			for ty in 0 ..< 34 {
				for tx in 0 ..< 60 {
					ch: cstring = (tx + ty) % 7 == 0 ? "#" : "."
					rl.DrawText(ch, i32(tx) * 20 + 10 + shake_offset.x, i32(ty) * 20 + 40 + shake_offset.y, 16, {40, 38, 44, 100})
				}
			}
		}

		draw_particles(&pool, shake_offset)

		// Screen flash overlay (drawn outside camera so it doesn't shake)
		if screen_flash > 0 {
			flash_alpha := u8(screen_flash * 100)
			rl.DrawRectangle(0, 0, 1200, 680, {200, 220, 255, flash_alpha})
		}

		// HUD (outside camera — stays steady during shake)
		rl.DrawText(
			fmt.ctprintf("Particles: %d  FPS: %d  [%s]", active_count(&pool), rl.GetFPS(), emitter_type_name(selected)),
			10, 10, 20, rl.RAYWHITE,
		)

		if show_debug {
			rl.DrawText(
				fmt.ctprintf("Free: %d / %d", pool.free_count, MAX_PARTICLES),
				10, 34, 16, {100, 200, 100, 200},
			)
		}

		rl.DrawText(
			"1:Fire 2:Sparks 3:Rain 4:Wind 5:Smoke 6:Blood 7:Lightning 8:Frost 9:Dust 0:Magic",
			10, 646, 14, {150, 150, 150, 200},
		)
		rl.DrawText(
			"LClick:spawn  RClick:burst  Space:clear  Tab:debug",
			10, 662, 14, {150, 150, 150, 200},
		)

		rl.EndDrawing()
	}
}

// Handles spawning, including combo effects and screen triggers
spawn_selected :: proc(x, y: f32, one_shot: bool) {
	switch selected {
	// --- Combo types: spawn multiple emitters ---
	case .Fire:
		// Fire + trailing smoke
		alloc_emitter(spawn_emitter_at(x, y, .Fire, one_shot))
		smoke := make_smoke_emitter(x, y - 10) // smoke origin slightly above fire
		smoke.spawn_rate = 12 // lighter than standalone smoke
		smoke.font_size = 16
		if one_shot {
			smoke.one_shot = true
			smoke.burst_count = 10
			smoke.spawn_rate = 0
		}
		alloc_emitter(smoke)
		screen_shake = 0.5

	case .Sparks:
		// Sparks + dust kick-up
		alloc_emitter(spawn_emitter_at(x, y, .Sparks, one_shot))
		dust := make_dust_emitter(x, y)
		dust.burst_count = 12 // lighter than standalone dust
		alloc_emitter(dust)
		screen_shake = 0.7
		screen_flash = 0.3

	case .Lightning:
		alloc_emitter(spawn_emitter_at(x, y, .Lightning, one_shot))
		// Secondary sparks at base of lightning
		sparks := make_sparks_emitter(x, y + 80)
		sparks.burst_count = 20
		sparks.lifetime_min = 0.2
		sparks.lifetime_max = 0.5
		alloc_emitter(sparks)
		screen_flash = 1.0
		screen_shake = 1.0

	case .Blood:
		alloc_emitter(spawn_emitter_at(x, y, .Blood, one_shot))
		screen_shake = 0.6

	case .Dust:
		alloc_emitter(spawn_emitter_at(x, y, .Dust, one_shot))
		screen_shake = 0.5

	// --- Simple types: single emitter, no combos ---
	case .Rain, .Wind, .Smoke, .Frost, .Magic:
		alloc_emitter(spawn_emitter_at(x, y, selected, one_shot))
	}
}

// Find a free emitter slot and assign
alloc_emitter :: proc(e: Emitter) {
	for &slot in emitters {
		if !slot.active {
			slot = e
			return
		}
	}
}
