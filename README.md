# EIGHT

Game development project for YTU, built with Godot. Most programming will be AI-assisted; game direction and asset creation remain human-led.

## Open the project

1. Install **Godot 4.7.2 Standard** (not .NET) and [Git LFS](https://git-lfs.com/).
2. Clone the repository:

   ```sh
   git lfs install
   git clone https://github.com/slyim/EIGHT.git
   cd EIGHT
   git lfs pull
   ```

3. In Godot's Project Manager, import `eight/project.godot` and open it.

The existing project uses Forward Plus, Direct3D 12 on Windows, and Jolt Physics. Keep these settings unless a deliberate engine/platform change requires otherwise. The original Steam editor reports `4.7.2.stable.steam.ed1daf0bf`.

## Survival run (main scene)

Press **F5 / Run Project** to open `eight/scenes/run.tscn`.

The first map is a heavily corrupted plain. The run opens with the angel, fully robed in purple and riding a black ox, descending from the sky in a beam of light and landing on a scorched sigil; enemies only start spawning after touchdown. Hordes then spawn just off-screen and grow denser over time.

- **Light spear combo:** hold attack to chain thrust, thrust, and a sweeping finisher. The finisher swings the light trident through a 140-degree arc, hitting every enemy inside it for double damage (walls still block it). Pausing longer than the combo window restarts the chain. Spear hits land with a brief hit-stop and camera shake (stronger on the finisher) and knock enemies back.
- **Bow:** press Q or turn the mouse wheel to switch between spear and bow; switching cancels a draw. Hold attack to draw and release to fire one arrow at the mouse. A longer draw (full charge after 0.75 s) gives more damage, range, and pierce; a quick tap still fires a weak, short arrow. Arrows are unlimited and stop at walls and pillars. The bow, its draw, and the arrows are drawn PLACEHOLDER shapes, and the shot reuses the placeholder thrust sound.
- **Input buffer:** a dash, jump, or attack pressed up to 0.15 s before it is ready still fires when it becomes available.
- **Jump:** Space triggers a short leap independently of the spear attack. While high in the air the angel clears enemies and projectiles; landing kicks up dust.
- **Dash:** a fast burst with brief invulnerability.
- **Flying enemies:** after about a minute some horde spawns are flying enemies (PLACEHOLDER imp art, tinted violet). They hover above the plain with a ground shadow and a gentle bob, keep a preferred distance instead of piling on, and fire an aimed shot after a short wind-up glint. Their shots hurt a grounded or airborne angel and pass over walls and pillars, and touching one hurts from the air. The bow hits them anywhere; the spear reaches them only while the angel is airborne. They do not collide with walls, pillars, or each other.

- **Life:** 100 health to start, shown as a bottom-filled orb. Enemy and boss contact costs 8-25 health depending on the enemy, and boss projectiles cost 12, followed by a short invulnerability blink. Dashing also grants invulnerability and passes through projectiles. Boss projectiles stop at world walls and pillars, and check their entire movement each physics tick so fast shots cannot skip through the player. Flying-enemy shots cost 10 and reach an airborne angel, while ground enemies and boss contact and shots miss one. Running out of health ends the run.
- **Experience:** slain enemies drop experience gems, which are pulled in when you come near. Filling the bar at the top raises your level, pauses the game, and offers three upgrades; pick one by clicking or pressing 1-3.
- **Life pickups:** enemies sometimes drop life, and each boss drops two. Life stays on the ground while you are at full health.
- **Items:** enemies rarely drop an item, and every sin boss drops one. Walk over it to collect it. The top-right list appears after collecting an item and shows the latest six, with a total count. Every collected bonus remains active for the run.
- **Bosses:** a boss arrives after each 60 seconds of survival with no boss active, in order: Pride, Greed, Lust, Envy, Gluttony, Wrath, Sloth, then Satan. Horde spawning slows while a boss is up. Defeating Satan wins the run.

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move |
| Mouse | Aim the spear or bow |
| Hold left mouse button or J | Spear combo (thrust, thrust, finisher); with the bow, hold to draw and release to fire |
| Q or mouse wheel | Switch between spear and bow |
| Space | Jump |
| Shift or right mouse button | Dash |
| 1 / 2 / 3 or click | Choose a level-up upgrade |
| F3 | Show or hide the stats overlay |
| R | Restart the run |

The HUD shows life and experience numerically as well as with a health orb and a bar, the next boss countdown or active boss health at the top centre, and dash/jump readiness gauges at the bottom, next to a weapon gauge showing the active weapon and the bow's draw charge. The **stats overlay** starts hidden; press F3 to open it at the top left. It shows FPS and frame time, CPU and physics time, draw calls, node count, and memory; live enemy count, boss health, boss projectiles, and pickups on the ground; kills and level; and the hero's current damage, attack rate, reach, pierce, speed, pickup radius, combo step, and dash/jump readiness.

The owner's EIGHT logo appears at the top right as a transparent pixel-art adaptation of the supplied `Eight.pdf`, recolored in the game's mint, steel, and purple palette. This specific AI-assisted adaptation was requested by the owner; its provenance and generation prompt are recorded in `eight/assets/art/CREDITS.md` and `eight_logo_pixel.md`. The original design and other authored assets are preserved.

The map is deliberately calm: the floor is low-contrast and every prop (dead trees, thorns, ooze pools, bones, red crystals, growths, rocks, dead grass, mushrooms) is static, so only enemies, pickups, and attacks move.

The world art and gameplay content in the run are **PLACEHOLDER**: the character sprites and animations, the sounds and music, the arena layout, enemy types, upgrade and item names, every number, and the boss attack patterns (charge, projectile burst, aimed spread, summon minions). The patterns exist only so the eight bosses can be told apart during testing; they are not boss designs. The owner-requested logo adaptation is documented separately from these temporary assets. Rosters and values live in constants at the top of `eight/scripts/run.gd`; spawning, boss interval, and drop chances can be tuned on the `Run` node in the Inspector.

### Placeholder art and audio

The sprites and sounds are generated by code from the owner's palette and mood board. They give the prototype a consistent look and sound until hand-made assets replace them; they are not production content (see the credit files in `eight/assets/art/placeholder/` and `eight/assets/audio/placeholder/`).

- **Sprites** are real `.aseprite` files (32x32 characters and enemies, 64x64 bosses, 16x16 pickups) using the 21-color palette, drawn at 2x in game with nearest-neighbor filtering. Animation names are Aseprite tags.
- **Aseprite Wizard** (`eight/addons/AsepriteWizard`, MIT) imports each `.aseprite` file as a Godot `SpriteFrames` resource automatically, and reimports whenever the file is saved. Open a placeholder in Aseprite, draw over it, keep the tag names, and save: the game updates.
- To import `.aseprite` files, Godot needs the Aseprite executable: in Godot, open **Editor Settings > Aseprite > General > Command Path** and point it at `Aseprite.exe` (the Steam install is `C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe`). Without Aseprite, Godot falls back to the committed `.ase_bake.res` files, so the project still opens and runs.
- **Regenerating** (overwrites the placeholder files, never hand-made ones):

  ```sh
  "C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe" -b --script-param out=eight/assets/art/placeholder --script tools/placeholder_art.lua
  python tools/placeholder_audio.py eight/assets/audio/placeholder
  ```

## Spear test space

`eight/scenes/prototype.tscn` is the original graybox for mounted movement and the spear against a stationary practice target (R resets it). Open it in the editor and press **F6** to run it.

### Confirmed game direction

A top-down 2D game about an unnamed angel, fully robed in purple and riding a black ox, wielding a trident-shaped spear of blue-white light, who comes to destroy the seven sins and then Satan. The reference games are *Hyper Light Drifter*, *Vampire Survivors*, and *20 Minutes Till Dawn*. The survival run is a graybox of that loop, not the finished campaign.

## Layout

- `eight/` — Godot project; this is `res://` in the editor.
- `eight/assets/` — game assets and their source/credit information.
- `eight/scenes/` — the survival run, enemy and boss scenes, the mounted player, and the spear test space.
- `eight/scripts/` — player, enemies, bosses, pickups, run director, HUD, and test-space behavior.
- `eight/tests/` — native Godot behavior checks, with no test framework.
- `eight/addons/AsepriteWizard/` — third-party Aseprite importer (MIT, license included).
- `tools/` — placeholder art and audio generators.
- `AGENTS.md` — instructions for AI coding agents.

## Asset workflow

Production creative assets must be **human-created**. Clearly identified temporary placeholders, including audio, are permitted for prototyping; their temporary status, source, and redistribution rights must be documented. AI-assisted code is allowed.

Add assets under `eight/assets/`; see its README for organization, attribution, and placeholder-labeling requirements. Common binary art, model, audio, and video formats use Git LFS automatically. LFS has storage and bandwidth quotas: avoid committing renders, exports, or duplicate source files.

Commit Godot `.import` settings and `.uid` files alongside their source files. Do not commit `.godot/`, build exports, credentials, or local editor state. Never hand-edit LFS pointer files.

The GitHub repository is public. Upload only material you have permission to publish; do not commit purchased asset packs or private credentials.

## Checks

With the Godot executable available as `godot`, run this from the repository root:

```sh
godot --headless --path eight --editor --import --quit
```

This checks project loading and asset imports, not gameplay. Run the native behavior smoke checks separately:

```sh
godot --headless --path eight --script res://tests/prototype_smoke.gd
godot --headless --path eight --script res://tests/run_smoke.gd
godot --headless --path eight --script res://tests/player_controls_smoke.gd
godot --headless --path eight --script res://tests/projectile_smoke.gd
godot --headless --path eight --script res://tests/flying_enemy_smoke.gd
godot --headless --path eight --script res://tests/hud_smoke.gd
godot --headless --path eight --script res://tests/weapon_smoke.gd
```

`prototype_smoke.gd` exercises movement, normalized diagonals, wall collision, mouse aiming, one hit per thrust, spear range, wall-blocked attacks, held attacks, target clearing, and reset. `run_smoke.gd` covers kills, experience pickup, piercing, level-up, damage and invulnerability, life pickups, dash, items, boss order, Satan victory, defeat, horde spawning, and the boss timer. `player_controls_smoke.gd` checks the physical Space/J/LMB bindings and the dash movement/invulnerability boundary. `projectile_smoke.gd` checks swept hits, wall blocking, invulnerable pass-through, expiry without a final hit, and spawning, travel, and facing under transformed parents. `flying_enemy_smoke.gd` checks the flying enemy's layer 5 collision and pillar pass-over, its preferred-distance hover, its wind-up and interval shot, from-air shot damage against grounded and airborne players, ground-shot and husk-touch misses against an airborne player, wall blocking for ground shots, kill experience and enemy count, and the 60-second roster gate. Also run the game with a visible window to judge control feel and readability; automated checks do not establish that the movement feels good.

`weapon_smoke.gd` checks Q and mouse-wheel weapon switching, draw cancelling, the HUD weapon gauge, charged and tap arrow damage, an arrow stopped by a pillar, arrows expiring at their range, a buffered dash press (and that a stale press is dropped), and that a spear hit starts hit-stop and shake and time recovers afterwards.

`hud_smoke.gd` checks the visible logo, placeholder notice, physical F3 toggle, ability readiness, life/XP text and orb fill, boss status, item list limit, level-up text, and HUD bounds and overlap at the default viewport size.

## Performance benchmark

Run `godot --path eight --script res://tests/performance_benchmark.gd --disable-vsync --max-fps 0`
for a windowed Forward Plus sample; add `--headless` for CPU-only diagnostics.
The fixed-seed fixture creates the configured enemy cap, 600 pickups, and eight
poofs per frame, warms up for 120 frames, then measures 600 frames. It prints
median/p95 wall frame time and mean process/physics seconds, draw calls, objects,
and nodes. The player is stationary and invulnerable; normal spawning is disabled.
This is an allocation stress fixture, not a simulation of normal drop frequency.
Uncapped modes advance different amounts of physics time, so compare like modes;
headless draw counts are meaningless. Monitor values can lag the sampled frame.

Initial Windows / RTX 3060 / D3D12 Forward Plus sample: median 1.665 ms,
p95 2.968 ms; process 7.884 ms, physics 2.154 ms, 45 draw calls,
4625 objects, 2586 nodes (means). Headless: median 6.901 ms, p95 15.984 ms;
process 1.795 ms, physics 25.812 ms, 3699 objects, 1646 nodes.
No runtime optimization has been applied: these aggregate samples do not isolate
movement, pickup processing, or poof allocation costs. Further controlled ablations
and repeated samples are required before attributing a hotspot.
