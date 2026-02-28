package ascii_particles

import "core:fmt"
import rl "vendor:raylib"

pool: Particle_Pool
emitters: [MAX_EMITTERS]Emitter
show_debug: bool

main :: proc() {
	rl.InitWindow(1200, 680, "ASCII Particles")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	init_pool(&pool)

	for !rl.WindowShouldClose() {
		dt := rl.GetFrameTime()
		mouse := rl.GetMousePosition()

		// --- Input ---

		// Left click: spawn continuous fire emitter in next free slot
		if rl.IsMouseButtonPressed(.LEFT) {
			for &e in emitters {
				if !e.active {
					e = make_fire_emitter(mouse.x, mouse.y)
					break
				}
			}
		}

		// Right click: one-shot fire burst
		if rl.IsMouseButtonPressed(.RIGHT) {
			for &e in emitters {
				if !e.active {
					e = make_fire_emitter(mouse.x, mouse.y)
					e.one_shot = true
					e.burst_count = 40
					e.spawn_rate = 0 // irrelevant for one-shot
					break
				}
			}
		}

		// Space: kill all particles and emitters
		if rl.IsKeyPressed(.SPACE) {
			init_pool(&pool)
			emitters = {}
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

		// --- Draw ---

		rl.BeginDrawing()
		rl.ClearBackground({20, 18, 24, 255})

		// Optional atmosphere grid
		if show_debug {
			for ty in 0 ..< 34 {
				for tx in 0 ..< 60 {
					ch: cstring = (tx + ty) % 7 == 0 ? "#" : "."
					rl.DrawText(
						ch,
						i32(tx) * 20 + 10, i32(ty) * 20 + 40,
						16,
						{40, 38, 44, 100},
					)
				}
			}
		}

		draw_particles(&pool)

		// HUD
		rl.DrawText(
			fmt.ctprintf("Particles: %d  FPS: %d", active_count(&pool), rl.GetFPS()),
			10, 10, 20, rl.RAYWHITE,
		)
		rl.DrawText("LClick: fire  RClick: burst  Space: clear  Tab: grid", 10, 656, 16, {150, 150, 150, 200})

		if show_debug {
			rl.DrawText(
				fmt.ctprintf("Free: %d / %d", pool.free_count, MAX_PARTICLES),
				10, 34, 16, {100, 200, 100, 200},
			)
		}

		rl.EndDrawing()
	}
}
