package ascii_particles

import "core:fmt"
import rl "vendor:raylib"

pool: Particle_Pool
emitters: [MAX_EMITTERS]Emitter
selected: Emitter_Type
show_debug: bool
screen_flash: f32 // 0-1, decays each frame (lightning effect)

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

		// Left click: spawn continuous emitter
		if rl.IsMouseButtonPressed(.LEFT) {
			for &e in emitters {
				if !e.active {
					e = spawn_emitter_at(mouse.x, mouse.y, selected, false)
					if selected == .Lightning do screen_flash = 1.0
					break
				}
			}
		}

		// Right click: one-shot burst
		if rl.IsMouseButtonPressed(.RIGHT) {
			for &e in emitters {
				if !e.active {
					e = spawn_emitter_at(mouse.x, mouse.y, selected, true)
					if selected == .Lightning do screen_flash = 1.0
					break
				}
			}
		}

		// Space: clear everything
		if rl.IsKeyPressed(.SPACE) {
			init_pool(&pool)
			emitters = {}
			screen_flash = 0
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

		// Decay screen flash
		if screen_flash > 0 {
			screen_flash -= dt * 8 // ~125ms full decay
			if screen_flash < 0 do screen_flash = 0
		}

		// --- Draw ---

		rl.BeginDrawing()
		rl.ClearBackground({20, 18, 24, 255})

		// Debug atmosphere grid
		if show_debug {
			for ty in 0 ..< 34 {
				for tx in 0 ..< 60 {
					ch: cstring = (tx + ty) % 7 == 0 ? "#" : "."
					rl.DrawText(ch, i32(tx) * 20 + 10, i32(ty) * 20 + 40, 16, {40, 38, 44, 100})
				}
			}
		}

		draw_particles(&pool)

		// Screen flash overlay (lightning)
		if screen_flash > 0 {
			flash_alpha := u8(screen_flash * 100) // max 100 alpha — bright but not blinding
			rl.DrawRectangle(0, 0, 1200, 680, {200, 220, 255, flash_alpha})
		}

		// HUD - top
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

		// HUD - bottom controls
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
