# ASCII Particle Engine

A standalone particle system that uses ASCII characters as particles instead of pixels. Built in Odin with Raylib. Designed to eventually drop into a traditional roguelike as a reusable module.

The idea: fire doesn't need sprites. A `^` rising upward, flickering horizontally, fading from yellow to red — that *is* fire. Same for rain (`|` falling fast), wind (`~` drifting with a sine wobble), blood (`.` splattering with gravity). ASCII characters already carry visual meaning, so lean into it.

## What it does

Ten particle emitter types across six behavior models, with screen effects:

| Key | Type | Characters | Behavior | What it looks like |
|-----|------|-----------|----------|-------------------|
| 1 | Fire | `^ * " '` | Flicker — random horizontal jitter | Flames rising, flickering, yellow → red fade |
| 2 | Sparks | `* . + '` | Gravity — downward acceleration | 360° burst that arcs down, yellow → orange |
| 3 | Rain | `\| / .` | None — pure velocity | Fast downward curtain, blue tint |
| 4 | Wind | `~ . - '` | Wobble — sine wave on vertical vel | Horizontal drift with visible oscillation |
| 5 | Smoke | `. o O *` | Spread — widens over lifetime | Slow rise, gray, expanding cloud |
| 6 | Blood | `. , ' *` | Gravity — short burst, strong pull | Outward splatter, dark red → black |
| 7 | Lightning | `\| / * +` | None — very short-lived | Bright burst along a vertical band + screen flash |
| 8 | Frost | `* + . '` | Drag — exponential deceleration | Particles spread outward and freeze in place, icy blue |
| 9 | Dust | `. , ' :` | Gravity — debris arcs | Wall-hit debris burst, sandy brown |
| 0 | Magic | `. * + '` | Drag — deceleration | LClick: converge inward (charging). RClick: burst outward (release) |

### Screen effects

- **Lightning flash** — full-screen white-blue overlay that decays over ~125ms. Triggered on lightning spawn.
- **Screen shake** — brief render offset on impacts (sparks, dust, blood, lightning). Sells the physicality.

### Special mechanics

- **Inward spawning** — magic converge particles spawn in a wide ring with velocity pointing toward the emitter center, creating a "gathering energy" visual
- **Combo emitters** — compound effects that spawn multiple emitter types together (fire + smoke, sparks + dust). One click, layered result.

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
   2. Behavior — per-type logic (flicker/gravity/wobble/spread/drag)
   3. Move — pos += vel * dt
   4. Draw — color lerp start→end over lifetime, quadratic alpha fade
```

Behaviors are an enum with a switch in the update loop. Adding a new behavior is: add an enum value, add a case to the switch, write a factory proc in `emitters.odin`. The particle struct and pool don't change.

### Behavior types

| Behavior | What it does | Used by |
|----------|-------------|---------|
| None | No per-frame modification, pure velocity | Rain, Lightning |
| Flicker | Random vel_x jitter each frame | Fire |
| Gravity | Constant downward acceleration (300 px/s²) | Sparks, Blood, Dust |
| Wobble | Sine wave applied to vel_y | Wind |
| Spread | Horizontal drift increases over particle lifetime | Smoke |
| Drag | Exponential deceleration (~96%/sec velocity loss) | Frost, Magic |

### File layout

```
particle.odin   — Particle struct, pool (alloc/free), Emitter struct, update, draw, utilities
emitters.odin   — Factory procs for each emitter type, combo spawners, dispatch
main.odin       — Raylib window, input handling, screen effects, demo scene
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
| 1-9, 0 | Select emitter type |
| Left click | Spawn continuous emitter at cursor |
| Right click | One-shot burst at cursor |
| Space | Clear all particles and emitters |
| Tab | Toggle debug overlay (dungeon grid + pool stats) |

## Use cases / why this exists

This is a side project that feeds into a larger roguelike. The plan:

- **Weather systems** — rain, wind, dust storms as visual atmosphere and gameplay pressure
- **Combat feedback** — blood splatter on hits, sparks on metal-on-metal, fire on spell impact
- **Environmental storytelling** — smoke trailing from light sources, wind blowing through corridors, dripping water in caves
- **Dynamic lighting companion** — embers and sparks that interact with a tile-based light map. Fire emitters paired with light sources, smoke dimming nearby tiles.
- **Food clock pressure** — wind blowing through dungeon corridors as an environmental force that pushes the player forward
- **Trap feedback** — sparks flying from triggered traps, dust from pressure plates, frost from ice traps
- **Systemic interactions** — wind pushes gas clouds and feeds fire, fire trails smoke, impacts kick up dust

When integrated into the roguelike, particles convert to tile-space coordinates and get multiplied by the light map. Two draw layers: ground effects (blood, sparks) render between the map and entities, atmospheric effects (smoke, wind, rain) render between entities and UI. Particles update every frame with `GetFrameTime()` regardless of turn state — they're purely visual, never touching game logic.

## What's next

### Near term
- Polish pass on all ten emitter types (tuning velocities, colors, spawn rates, character distributions)
- Brogue-style dancing colors on static tiles (per-frame color randomization — the dungeon floor looks alive with zero particles)
- Combo emitters wired up (fire+smoke, sparks+dust, etc.)

### Integration ideas
- Light source particles — torches/lanterns emit fire particles, smoke trails upward. Tie particle color to light intensity.
- Wind-fire interaction — wind emitters push fire particles in wind direction, fan flames (increase spawn rate)
- Wind-gas interaction — wind pushes poison/confusion gas clouds through corridors toward the player
- Trap VFX — sparks from blade traps, dust from cave-ins, frost spreading from ice traps
- Footstep dust — single `·` particle at previous position when creatures move. Scale by creature size.
- Spell charging — magic converge effect on caster during charge-up, burst on release
- Data-driven emitter definitions (external files instead of hardcoded factory procs)

## References that shaped this

- [Cogmind's particle system](https://www.gridsagegames.com/blog/2014/04/making-particles/) — nearly 1,000 ASCII particle effects, data-driven and hot-reloadable
- [kiedtl's ASCII particle engine](https://tilde.team/~kiedtl/blog/particles/) — ~450 line engine for the roguelike Oathbreaker, excellent architecture writeup
- [BrogueCE source](https://github.com/tmewett/BrogueCE) — the `color` struct with per-channel randomization and `colorDances` flag is genius
- [Bracket Productions roguelike tutorial Ch.18](https://bracketproductions.com/posts/roguetutorial/chapter_18/) — minimal ECS particle system in Rust
- [Caves of Qud systems-driven design](https://unity.com/resources/systems-driven-design-in-caves-of-qud) — "build complex systems, let them collide"

---

## AI Disclosure

This project was built with Claude Code (Anthropic's Claude) handling the implementation while I directed architecture, scope, and design decisions. The plan, structure, and creative direction are mine. The code was generated through an interactive session where I reviewed and approved each step. Research compilation on ASCII particle techniques, roguelike VFX, and wind system design was also AI-assisted.

I'm using AI tooling as part of learning Odin and exploring game systems — not as a replacement for understanding what the code does.
