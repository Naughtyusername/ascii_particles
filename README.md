# ASCII Particle Engine

A standalone particle system that uses ASCII characters as particles instead of pixels. Built in Odin with Raylib. Designed to eventually drop into a traditional roguelike as a reusable module.

The idea: fire doesn't need sprites. A `^` rising upward, flickering horizontally, fading from yellow to red — that *is* fire. Same for rain (`|` falling fast), wind (`~` drifting with a sine wobble), blood (`.` splattering with gravity). ASCII characters already carry visual meaning, so lean into it.

## What it does

Six particle emitter types, each with distinct movement behaviors, color ramps, and character sets:

| Type | Characters | Behavior | What it looks like |
|------|-----------|----------|-------------------|
| Fire | `^ * " '` | Flicker — random horizontal jitter per frame | Flames rising, flickering, yellow to red fade |
| Sparks | `* . + '` | Gravity — downward acceleration | 360° burst that arcs down, yellow to orange |
| Rain | `\| / .` | None — pure velocity, no per-frame modification | Fast downward curtain, blue tint |
| Wind | `~ . - '` | Wobble — sine wave on vertical velocity | Horizontal drift with visible oscillation |
| Smoke | `. o O *` | Spread — horizontal drift widens over lifetime | Slow rise, gray, expanding cloud |
| Blood | `. , ' *` | Gravity — same as sparks, different tuning | Short burst outward, dark red to black splatter |

## Architecture

### Zero allocation after init

The particle pool is a flat fixed array of 4096 particles with a free list stack. Allocating a particle pops an index off the stack (O(1)). Freeing pushes it back (O(1)). No heap, no allocator, no GC pressure. The emitter array is similarly fixed at 32 slots.

This matters for a roguelike where the particle system runs every frame regardless of turn state — it needs to be invisible to the performance budget.

### How it works

```
Emitter (spawn rate, character set, color ramp, velocity range, behavior type)
   |
   v  spawns N particles per second via fractional accumulator
Particle (position, velocity, lifetime, character, color, behavior)
   |
   v  updated every frame:
   1. Age — decrement lifetime, free if dead
   2. Behavior — per-type logic (flicker/gravity/wobble/spread)
   3. Move — pos += vel * dt
   4. Draw — color lerp start→end over lifetime, quadratic alpha fade
```

Behaviors are an enum with a switch in the update loop. Adding a new behavior is: add an enum value, add a case to the switch, write a factory proc in `emitters.odin`. The particle struct and pool don't change.

### File layout

```
particle.odin   — Particle struct, pool (alloc/free), Emitter struct, update, draw, utilities
emitters.odin   — Factory procs for each emitter type (make_fire_emitter, etc.)
main.odin       — Raylib window, input handling, demo scene
```

All files are `package ascii_particles`. Single build command.

## Building & running

Requires Odin (ships with Raylib bindings in the vendor collection — no external deps).

```sh
odin build . -out:ascii_particles -debug
./ascii_particles
```

Drop `-debug` for a release build. Debug enables bounds checking on all array access, which is worth keeping on while experimenting.

## Controls

| Key | Action |
|-----|--------|
| 1-6 | Select emitter type (Fire, Sparks, Rain, Wind, Smoke, Blood) |
| Left click | Spawn continuous emitter at cursor |
| Right click | One-shot burst at cursor |
| Space | Clear all particles and emitters |
| Tab | Toggle debug overlay (dungeon grid + pool stats) |

## Use cases / why this exists

This is a side project that feeds into a larger roguelike. The plan:

- **Weather systems** — rain, wind, dust storms as visual atmosphere and gameplay pressure
- **Combat feedback** — blood splatter on hits, sparks on metal, fire on spell impact
- **Environmental storytelling** — smoke from a distant fire, wind blowing through a corridor, dripping water in caves
- **Dynamic lighting companion** — embers and sparks that interact with a tile-based light map
- **Food clock pressure** — wind blowing through dungeon corridors as an environmental force that pushes the player forward

When integrated into the roguelike, particles convert to tile-space coordinates and get multiplied by the light map. Two draw layers: ground effects (blood, sparks) render between the map and entities, atmospheric effects (smoke, wind, rain) render between entities and UI. Particles update every frame with `GetFrameTime()` regardless of turn state — they're purely visual, never touching game logic.

## What's next

- Polish pass on all six emitter types (tuning velocities, colors, spawn rates, character distributions)
- More effect types: lightning, frost, magic (converging/diverging particles), dust/debris
- Brogue-style dancing colors on static tiles (color randomization per frame, no particles needed)
- Screen effects (brightness flash on lightning, subtle shake on explosions)
- Data-driven emitter definitions (external files instead of hardcoded factory procs)

## References that shaped this

- [Cogmind's particle system](https://www.gridsagegames.com/blog/2014/04/making-particles/) — nearly 1,000 ASCII particle effects, data-driven and hot-reloadable
- [kiedtl's ASCII particle engine](https://tilde.team/~kiedtl/blog/particles/) — ~450 line engine for the roguelike Oathbreaker, excellent architecture writeup
- [BrogueCE source](https://github.com/tmewett/BrogueCE) — the `color` struct with per-channel randomization and `colorDances` flag is genius
- [Bracket Productions roguelike tutorial Ch.18](https://bracketproductions.com/posts/roguetutorial/chapter_18/) — minimal ECS particle system in Rust

---

## AI Disclosure

This project was built with Claude Code (Anthropic's Claude) handling the implementation while I directed architecture, scope, and design decisions. The plan, structure, and creative direction are mine. The code was generated through an interactive session where I reviewed and approved each step. Research compilation on ASCII particle techniques, roguelike VFX, and wind system design was also AI-assisted.

I'm using AI tooling as part of learning Odin and exploring game systems — not as a replacement for understanding what the code does.
