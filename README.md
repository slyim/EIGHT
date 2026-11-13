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

## The pentagram (main scene)

Press **F5 / Run Project** to open the pentagram hub (`eight/scenes/hub.tscn`): the seven sins sit evenly on a glowing outer ring around a pentagram, with Satan at the center. Click a sin or press **1-7** to enter its realm. Winning a realm seals that sin: its relic glows on its pedestal with a gold chord to the center, and the hub plays a sealing ripple the first time. With all seven relics in place Satan unlocks; click the center or press **S** to summon him. Progress (sealed sins, and whether Satan has fallen) is saved to `user://progress.cfg` the moment a realm is won; a missing or damaged file starts fresh. The hub is crisp vector UI drawn from the shared theme; its pentagram, pedestals and relics are code-drawn shapes.

Each sin has its own map scene in `eight/scenes/sins/` (`pride.tscn` ... `sloth.tscn`, and `satan.tscn`). Each inherits `eight/scenes/run.tscn` and sets its `sin_index`; its obstacles and Satan's shrines are real `Breakable` nodes under `Obstacles` that you can move, add, or delete in the editor (a sin map left with no shrines summons its sin right after landing), and its lava pools are the `lava_layout` array on the root (one entry per pool, each a list of `[center, radius]` blobs). The layouts are PLACEHOLDER, generated once by `godot --headless --path eight --script res://tools/bake_sin_maps.gd`, which never overwrites an existing map scene (delete one to regenerate it). Decoration is still scattered from the map's seed. `eight/scenes/game.tscn` hosts the chosen map in the pixel-perfect view described under [Pixel-perfect rendering](#pixel-perfect-rendering); opening a map scene directly (F6) plays it without the hub or the pixel view.

- **Feathers and the shop:** a run earns feathers (the shop's currency; PLACEHOLDER amounts): 1 per kill, 10 per guard, 15 per shrine, 50 for the sin (100 for Satan), and 5 per feather gem that horde enemies sometimes drop (3% chance, scaled by luck; pale-gold PLACEHOLDER gems pulled in like experience). The HUD counts them. When a hub-launched run ends they are banked: all of them on a win, half (rounded down) on a defeat, and the end card says how many. R waits until the defeat card is up, so retrying never skips banking; very large counters on the HUD shorten to thousands (12.3K). Press **B** or click **SHOP** on the pentagram (which shows the banked total) to spend them on permanent ranks: Vitality (+10 max health), Might (+5% damage), Armor (hits 1 less), Haste (cooldowns 4% shorter), Luck (+10% drops), Swiftness (+10 speed), Pull (+15 pickup radius), and Wings (+0.3 s of flight), five ranks each at rising prices (`Progress.UPGRADES` in `eight/scripts/progress.gd`; names, values, and prices are PLACEHOLDER). Rows show their rank as filled and empty diamonds; a purchase saves at once, and one that cannot be saved is undone and reported. Every realm entered from the pentagram starts with the bought ranks; maps played directly (F6) and the tests do not.
- **Endings:** leaving a realm through its portal (or slaying Satan) wins it: the horde vanishes, the angel rises back into the sky in its beam while the whole realm heals beneath it, the win is saved, and the game returns to the pentagram (R does nothing during the ascension or a hosted win, so the ascension and save always finish; a map played directly with F6 can be restarted with R once the ascension ends). If the save cannot be written, the end card says so and offers **Try saving again** or **Return without saving**; it never returns as if it had saved, and only a successful save is called "saved". If the angel dies, it falls, the world dims, and a card offers **Retry** (or R) and **Return to the pentagram**.
- **Horde mix per sin (PLACEHOLDER):** each realm weights the four horde types (husk, imp, brute, flyer) differently among the ones its clock has unlocked: Pride balanced, Greed imps, Lust imps and flyers, Envy flyers, Gluttony brutes, Wrath imps and brutes, Sloth husks only and 40% slower spawns, Satan everything. The table is `SIN_ENEMY_WEIGHTS` / `SIN_SPAWN_PACE` in `eight/scripts/run.gd`.
- **Satan's realm:** no shrines and no countdown. It stays calm for a short ritual after landing (3 s, PLACEHOLDER; the HUD counts it down), then Satan arrives with the horde; his fall wins at once, with no portal.

## Survival run

The first map is a heavily corrupted plain. The run opens with the angel, fully robed in purple and riding a black ox, descending from the sky in a beam of light and landing on a scorched sigil; enemies only start spawning after touchdown. Hordes then spawn just off-screen and grow denser over time.

- **Light spear combo:** hold attack to chain thrust, thrust, and a sweeping finisher. The finisher swings the light trident through a 140-degree arc, hitting every enemy inside it for double damage (walls and obstacles still block it). Pausing longer than the combo window restarts the chain. Spear hits land with a brief hit-stop and camera shake (stronger on the finisher) and knock enemies back.
- **Bow combo:** press Q or turn the mouse wheel to switch between spear and bow; switching cancels the combo in progress. The bow follows the spear's rhythm: press or hold attack to chain shot, quicker shot, and finisher, each firing one arrow at the mouse; pausing longer than the combo window restarts the chain. Until the bow evolves (see **Weapon evolution**), the finisher is a plain arrow too. Every arrow deals the same PLACEHOLDER damage, range, and pierce (tunable in the player's **Bow** export group). Arrows are unlimited and stop at walls and obstacles. The bow and the arrows are drawn PLACEHOLDER shapes, and the shot reuses the placeholder thrust sound.
- **Weapon evolution:** every shrine guard drops an evolution item when slain, and horde enemies very rarely do (`evolution_drop_chance` on the `Run` node). Each item is for one weapon (PLACEHOLDER item art tinted mint for the spear, violet for the bow) and must be walked over. Collecting it pauses on a choice of that weapon's two paths (click or press 1-2, with a flash); a level-up that arrives meanwhile waits until after. Each path replaces the weapon's finisher for the rest of the run, and each weapon evolves once per run (a spare item gives 10 experience, and drops stop for an evolved weapon). The weapon gauge then shows the path's name. Spear: **Whirlwind** (the finisher spins a full circle, striking all around) or **Chain Light** (lightning jumps from the finisher's first hit to up to 3 more enemies within 200 px, each taking the finisher's damage). Bow: **Ricochet** (the finishing arrow bounces on to up to 4 more enemies within 280 px) or **Rain of Light** (the finishing shot marks a 110 px circle at the aim, within bow range; after 0.35 s light falls and every enemy inside, on the ground or in the air, takes double bow damage). Names, wording, numbers, and the lightning, telegraph, and streak visuals are PLACEHOLDER (tunable in the player's **Evolution** export group and `EVOLUTIONS` in `eight/scripts/run.gd`).
- **Side weapons:** four auto-firing side weapons strike ground and flying enemies alike, never through walls or standing obstacles, and rest while the angel descends or has fallen; when a run ends, anything still in flight (arrows, feathers, falling light) is removed and chests stay shut. **Orbiting halos** (2-4 light orbs circling the angel; each target struck at most twice a second), **Seeking feathers** (every 1.6 s, 1-3 gold feathers at the nearest enemies within 420 px; they wait for a target), **Holy pulse** (every 3 s, a ring of 120-180 px that strikes and pushes back), and **Judgment bolt** (light strikes a random enemy within 560 px every 2.4-1.5 s). They come from relics: walk up to one of the realm's chests (three per map, placed from the map's seed on open ground away from the landing site, unless the map scene authors its own under `Chests`; portals and spawns keep clear of them) to open it, or slay a shrine guard; a gold relic spills out (PLACEHOLDER item art). Collecting a relic finds a random side weapon the angel lacks or levels one it has (up to level III, more orbs, feathers, damage, reach, or speed); once all four are at III, a relic gives 10 experience. The HUD lists them at the bottom left and announces each find. Every number and the orbs, ring, bolt, and chest are PLACEHOLDER (constants at the top of `eight/scripts/side_weapons.gd`).
- **Stats from level-ups:** besides the spear, bow, speed, health, pull, and dash upgrades, level-ups offer **Might** (+10% damage from every weapon, side weapons and evolutions included), **Armor** (enemy hits deal 1 less, never below 1; lava burns are not hits), **Haste** (every attack and side-weapon cooldown 8% shorter, down to a floor of 40%; at the floor it is no longer offered), and **Luck** (+20% heart, item, and evolution drop chances). The base values are in the player's **Stats** export group; amounts are PLACEHOLDER.
- **Input buffer:** a dash, take-off, or attack pressed up to 0.15 s before it is ready still fires when it becomes available.
- **Flight:** hold Space to take off. The angel climbs to a hover about 80 px above its ground shadow in 0.2 s, bobs gently while Space is held, and glides back down in 0.25 s when it is released; landing kicks up dust. The climb always finishes, so a tap of Space is a short hop. Flight stamina (2.5 s when full) drains whenever the angel is off the ground and refills only after landing (0.6 s of flight per second, so about 4 s from empty). Taking off needs at least 0.5 s of stamina, so tapping cannot dodge the meter; running dry forces a landing even with Space held, and taking off again needs a fresh press. Pressing Space while gliding down climbs again if stamina allows. Walls and obstacles still block flight; enemies never block the angel's movement, in the air or on the ground. All of this is tunable in the player's **Flight** export group.
- **Air and ground:** while airborne, ground attacks miss the angel: enemy and boss contact and boss projectiles. Attacks from the air (`take_damage(amount, true)`) land at any height. The spear (thrusts and finisher) hits flying enemies only while airborne, and ground enemies and practice targets only on the ground. Arrows hit both from any height, and fly at the height of the bow.
- **Dash:** a fast burst with brief invulnerability. It works the same in the air: the angel bursts along at its current height while flight and stamina drain continue, and take-off is allowed mid-dash.
- **Flying enemies:** after about a minute some horde spawns are flying enemies (PLACEHOLDER imp art, tinted violet). They hover above the plain with a ground shadow and a gentle bob, keep a preferred distance instead of piling on, and fire an aimed shot after a short wind-up glint. Their shots hurt a grounded or airborne angel and pass over walls and pillars, and touching one hurts from the air. The bow hits them anywhere; the spear reaches them only while the angel is airborne. They do not collide with walls, pillars, or each other.
- **Lava pools:** every sin map scatters a handful of irregular molten pools on the floor, drawn under actors and pickups with bright hot colors (PLACEHOLDER colors: orange molten rock with over-bright bubbles that bloom under the HDR glow) and a slow shimmer. The layout is deterministic per sin map, kept clear of the landing site, walls, and obstacles, and spaced apart. Standing in one burns 8 health every 0.5 s after a 0.4 s grace (PLACEHOLDER balance, tunable on the Lava node), with an orange flash, the hurt sound, and a BURNING callout as feedback. Flying over lava and dashing through it are safe and reset the burn timer, and the hurt-blink from an enemy hit delays a burn tick instead of being ignored — burn ticks never start or extend the invulnerability window, so lava cannot shield from enemies. Only the angel burns: ground enemies, bosses, and projectiles are unharmed and unslowed, and lava never blocks movement. `run.point_in_lava(point, inset)` answers "is this point in lava?" for placement, e.g. keeping the exit portal clear.

- **Breakable obstacles:** every sin map has wall segments, structures (where the old pillars stood), and trees, each with PLACEHOLDER toughness: a tree takes 3 damage, a wall segment 6, a structure 10. Spear thrusts deal 1, the finisher 2, arrows 1 (plus upgrades and items), so a tree falls to three thrusts or three arrows and a structure to ten thrusts. A weapon that hits an obstacle spends itself on it: a thrust or arrow stops there whatever its pierce, and the finisher strikes enemies in its arc only where no obstacle stands between, so nothing behind an obstacle is hit until it breaks (the blow that breaks it included). Spear blows on obstacles give the same hit-stop and shake as on enemies. A blow flashes and shakes the obstacle and plays the enemy hit sound; glowing cracks and darkening show three damage stages, and a dark hairline marks every obstacle as breakable before the first blow. At zero it bursts into debris with a poof and a thud (the placeholder landing sound), and it stops blocking at once. While standing, obstacles block like walls: the angel on the ground and in flight, ground enemies and bosses, and ground shots. Flying enemies and their shots pass over them, and nothing but the player's weapons damages them. The arena's boundary walls cannot be broken. Each sin map builds its own layout from a fixed seed (Satan's 5 shrines, 6 structures, 8 wall segments, 40 trees) and keeps the landing site clear and 140 px lanes between obstacles and from the arena walls. Portals, horde spawns, bosses, and summoned minions are placed clear of standing obstacles. Kinds and toughness live in `eight/scripts/breakable.gd`; counts and lanes at the top of `eight/scripts/run.gd`. The obstacle visuals are PLACEHOLDER: structures reuse the pillar art, walls and trees are drawn shapes.
- **Life:** 100 health to start, shown as a bottom-filled orb. Enemy and boss contact costs 8-25 health depending on the enemy, and boss projectiles cost 12, followed by a short invulnerability blink. Dashing also grants invulnerability and passes through projectiles. Boss projectiles stop at walls and obstacles, and check their entire movement each physics tick so fast shots cannot skip through the player. Flying-enemy shots cost 10 and reach an airborne angel, while ground enemies and boss contact and shots miss one. Running out of health ends the run.
- **Experience:** slain enemies drop experience gems, which are pulled in when you come near. Filling the bar at the top raises your level, pauses the game, and offers three upgrades; pick one by clicking or pressing 1-3.
- **Life pickups:** enemies sometimes drop life, and each boss drops two. Life stays on the ground while you are at full health.
- **Items:** enemies rarely drop an item, and the slain sin drops one. Walk over it to collect it. The top-right list appears after collecting an item and shows the latest six, with a total count. Every collected bonus remains active for the run.
- **Satan's shrines and the sin:** each run is one sin's map (`sin_index` on the `Run` node; the default is Pride). On every sin's map (not Satan's own), five of Satan's shrines stand on the points of a pentagram 1300 px around the landing site, each a red-glowing obelisk with a weaker copy of the sin beside it as its guard (35% health; it defends while the angel is within 520 px of its shrine and walks back otherwise). An **8-minute countdown** starts on landing: if any shrine still stands when it runs out, the angel dies. A shrine takes 20 blows from the player's weapons (only the player can damage it) and can be hit while its guard lives; breaking one heals the ground around it (a PLACEHOLDER green circle with a soft light). Breaking the last shrine stops the countdown and summons the sin at full strength. Slaying the sin wins the map: a portal opens near its death site, clear of walls and obstacles, and the run keeps going, with the horde still scaling and the angel still leveling, until you leave. Stand inside the portal, then press and hold E for one second to leave; releasing or stepping out cancels, and holding E before arriving does not activate it. Gold diamonds on a ring around the angel point toward shrines that are off screen, and once the sin falls a larger mint diamond points to the exit while it is off screen. Counts, distances, toughness, guard strength and the countdown are PLACEHOLDER values at the top of `eight/scripts/run.gd` and on the `Run` node.
- **Difficulty:** one continuous difficulty unit per minute after touchdown; the visible tier starts at 1 and rises every two minutes. Pausing for upgrades pauses the clock. New horde enemies gain 15% base speed, 60% base health, and 18% base contact damage per minute (integer stats rounded). At five minutes they have 1.75x speed, 4x health, and 1.9x damage. Spawn interval is `max(0.18, 1.1 / (1 + 0.35 * difficulty))` seconds, doubled during bosses; batch size is `min(12, 1 + floor(difficulty / 1.5))`, subject to the existing enemy cap. Imps unlock at difficulty 0.75, brutes at 2. Bosses gain a gentler 4% speed, 15% health and 6% contact damage per minute. These PLACEHOLDER tuning constants live in `run.gd`; portal hold time is exported in `exit_portal.gd`.

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move |
| Mouse | Aim the spear or bow |
| Press or hold left mouse button or J | Weapon combo: spear (thrust, thrust, finisher) or bow (shot, quicker shot, finisher) |
| Q or mouse wheel | Switch between spear and bow |
| Hold Space | Fly; release to land |
| Shift or right mouse button | Dash |
| 1 / 2 / 3 or click | Choose a level-up upgrade |
| 1 / 2 or click | Choose a weapon evolution path |
| F3 | Show or hide the stats overlay |
| Hold E inside an exit portal | Leave the map after slaying its sin (1 second) |
| 1-7 / click (hub) | Enter a sin's realm |
| S / click center (hub) | Summon Satan once all seven relics are sealed |
| B / click SHOP (hub) | Open the shop (Esc returns to the pentagram) |
| Esc | Pause or resume (Resume / Restart / Return to the pentagram); never opens over a level-up |
| R | Restart the run (not while an ending plays, nor after a win started from the pentagram) |

The HUD shows life and experience numerically as well as with a health orb and a bar, the shrines left and the shrine countdown (flagged in its last minute), active boss health, or the portal prompt at the top centre, plus the sin's realm, shrines broken, and the persistent run timer/difficulty tier, and the dash readiness and flight stamina gauges at the bottom (flight greys out below the take-off minimum), next to a weapon gauge showing the active weapon and its combo step. The **stats overlay** starts hidden; press F3 to open it at the top left. It shows FPS and frame time, CPU and physics time, draw calls, node count, and memory; live enemy count, boss health, boss projectiles, and pickups on the ground; kills and level; and the hero's current damage, attack rate, reach, pierce, speed, pickup radius, combo step, dash readiness, and flight stamina.

The owner's EIGHT logo appears at the top right as a transparent pixel-art adaptation of the supplied `Eight.pdf`, recolored in the game's mint, steel, and purple palette. This specific AI-assisted adaptation was requested by the owner; its provenance and generation prompt are recorded in `eight/assets/art/CREDITS.md` and `eight_logo_pixel.md`. The original design and other authored assets are preserved.

The map is deliberately calm: the floor is low-contrast and every prop (thorns, ooze pools, bones, red crystals, growths, rocks, dead grass, mushrooms) is static, so only enemies, pickups, and attacks move, apart from the lava pools' slow shimmer. Dead trees are no longer floor props: trees are breakable obstacles, larger and lighter than the props, so anything tree-shaped blocks.

The world art and gameplay content in the run are **PLACEHOLDER**: the character sprites and animations, the sounds and music, the arena layout, obstacle kinds and toughness, enemy types, upgrade and item names, every number, and the boss attack patterns (charge, projectile burst, aimed spread, summon minions). The patterns exist only so the eight bosses can be told apart during testing; they are not boss designs. The owner-requested logo adaptation is documented separately from these temporary assets. Rosters and values live in constants at the top of `eight/scripts/run.gd`; the sin map (`sin_index`), shrine countdown (`shrine_time`), spawning, and drop chances can be tuned on the `Run` node in the Inspector.

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
- `eight/scripts/` — player, enemies, bosses, pickups, run director, HUD, lava pools, lights, and test-space behavior.
- `eight/shaders/` — the light palette, darkness, light falloff and atmosphere shaders, and their materials.
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
godot --headless --path eight --script res://tests/flight_smoke.gd
godot --headless --path eight --script res://tests/projectile_smoke.gd
godot --headless --path eight --script res://tests/flying_enemy_smoke.gd
godot --headless --path eight --script res://tests/hud_smoke.gd
godot --headless --path eight --script res://tests/weapon_smoke.gd
godot --headless --path eight --script res://tests/shrine_smoke.gd
godot --headless --path eight --script res://tests/lava_smoke.gd
godot --headless --path eight --script res://tests/obstacle_smoke.gd
godot --headless --path eight --script res://tests/pixel_view_smoke.gd
godot --headless --path eight --script res://tests/campaign_smoke.gd
godot --headless --path eight --script res://tests/evolution_smoke.gd
godot --headless --path eight --script res://tests/build_smoke.gd
godot --headless --path eight --script res://tests/shop_smoke.gd
```

`prototype_smoke.gd` exercises movement, normalized diagonals, wall collision, mouse aiming, one hit per thrust, spear range, wall-blocked attacks, held attacks, target clearing, and reset. `run_smoke.gd` covers kills, experience pickup, piercing, level-up, damage and invulnerability, life pickups, dash, items, the last shrine summoning the sin, its exit winning the map, defeat, horde spawning, and that no boss arrives on a timer. `player_controls_smoke.gd` checks the physical Space/J/LMB bindings and the dash movement/invulnerability boundary. `projectile_smoke.gd` checks swept hits, wall blocking, invulnerable pass-through, expiry without a final hit, and spawning, travel, and facing under transformed parents. `flying_enemy_smoke.gd` checks the flying enemy's layer 5 collision and pillar pass-over, its preferred-distance hover, its wind-up and interval shot, from-air shot damage against grounded and airborne players, ground-shot and husk-touch misses against an airborne player, wall blocking for ground shots, kill experience and enemy count, and the 60-second roster gate. On this Windows Godot 4.7.2 setup, `--quit-after 600` and the benchmark can intermittently report audio playback/resource leaks during shutdown (also reproduced on unchanged HEAD); no gameplay script errors were observed. `glow_smoke` can likewise report audio-only shutdown leaks after PASS. A fresh import may report an unavailable locally configured Aseprite executable before falling back to the committed baked resources.

Also run the game with a visible window to judge control feel and readability; automated checks do not establish that the movement feels good.

`weapon_smoke.gd` checks Q and mouse-wheel weapon switching, the bow's three-shot combo (step order, the quicker second shot, restart after the finisher and after a late press, reset on weapon switch), the HUD weapon gauge and combo step, arrow damage, an arrow stopped by a structure, arrows expiring at their range, a buffered dash press (and that a stale press is dropped), and that a spear hit starts hit-stop and shake and time recovers afterwards.

`flight_smoke.gd` checks that holding Space climbs to a bobbing hover and stays up, releasing lands (one `jumped` and one `landed` per flight), a tap is a short hop, stamina drains in the air and refills only on the ground, take-off is refused below the minimum (and that press never fires later), running dry forces a landing that holding Space cannot undo, the HUD flight gauge follows stamina, an air dash keeps the angel up, structures still block flight, ground damage misses while airborne but `take_damage(10, true)` lands, the spear thrust and finisher hit a layer-5 flying stand-in only while airborne and a ground enemy only while grounded, arrows hit a flying stand-in from the ground and a ground enemy from the air, and a slain angel falls to the ground.

`obstacle_smoke.gd` checks that each obstacle kind breaks after its expected number of thrusts with one blow per thrust, the hit flash, shake, sound, hit-stop, darkening, and break effect, that the finisher and heavier arrows break obstacles faster, that arrows and the spear (thrust and finisher) stop at a standing obstacle and spare the enemy behind it but reach it once it breaks, that the angel is blocked on the ground and in flight and a ground enemy is held until the obstacle breaks, that ground shots stop and flying-enemy shots pass over, that enemies and their shots never damage obstacles, that the boundary walls cannot be damaged, and that each sin map's layout is deterministic, differs from the last, keeps the landing site and lanes clear, keeps decoration, portals, horde spawns, and bosses out of obstacles, opens with the five shrines on their pentagram points, frees a broken obstacle's spot at once, and spawns the sin clear of obstacles.

`shrine_smoke.gd` covers clock/tier growth, generic enemy scaling and spawn pressure, the five shrines on their pentagram points (each a light), one weaker leashed guard per shrine that returns home when the angel is far, chases when near, and drops a charge when the angel leaves its range, guards that never summon minions or the sin (while the sin still summons), shrines that only the player's blows damage (20 of them), the countdown running after landing and stopping once every shrine falls, healing (spot and light) once per shrine, the sin summoned once by the last shrine, safe portal placement near the slain sin, post-boss spawning, scaling, and leveling, fresh-press/hold/cancel portal confirmation winning the map, and the countdown killing a protected angel while shrines stand.

`hud_smoke.gd` checks the persistent timer/difficulty, the sin's realm, the shrine count and countdown (and its last-minute flag), the shrine markers (one per off-screen shrine, on a ring around the angel, pointing at its shrine, clear of every HUD panel, none for a shrine in view), portal instructions, visible logo, placeholder notice, physical F3 toggle, ability readiness, life/XP text and orb fill, boss status, item list limit, level-up text, and HUD bounds and overlap at the default viewport size.

`lava_smoke.gd` checks the lava query and its burn inset, the deterministic per-map pool layout (identical for the same sin map, different between maps, clear of the landing site, arena bounds, walls and pillars, pools spaced apart), burning at the configured rate over several ticks, the grace before the first tick, leaving stops the burn, flying and dashing are safe and reset exposure, burning to zero ends the run in defeat, ground enemies and bosses wade through lava unharmed and unslowed, and an enemy hit inside lava still lands while its hurt-blink delays burn ticks without ever granting or extending invulnerability.

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
With breakable obstacles added, three windowed runs on the same machine gave median
1.64-2.01 ms and p95 2.98-3.35 ms against 1.65-1.95 ms and 3.01-3.45 ms just before
(no measurable change), and 90 draw calls against 57: each tree in view costs about 6,
each wall segment or structure 2.
No runtime optimization has been applied: these aggregate samples do not isolate
movement, pickup processing, or poof allocation costs. Further controlled ablations
and repeated samples are required before attributing a hotspot.

## Pixel-perfect rendering

Every art pixel on screen is the same size. `eight/scenes/game.tscn` (`eight/scripts/game.gd`) renders the run into a fixed **640x360** SubViewport (one art pixel = 2 world units = 1 buffer pixel; the camera zoom is 0.5, so gameplay units, speeds, and ranges are unchanged) and shows it at the largest **whole-number** scale that fits the window, centered, with dark bars in any leftover space: 1280x720 is 2x, 1920x1080 is 3x, 2560x1440 is 4x, 3840x2160 is 6x, and in-between or non-16:9 windows (1366x768, ultrawide) keep the nearest smaller scale with bars. The minimum window is 1280x720. Sprites, rotated weapons, drawn shapes, lights, and glow all rasterize into that one buffer with nearest sampling. The HUD is moved out of the buffer to the native-resolution root, so UI text stays crisp; it can sit over the bars.

Every sprite draws at exactly 2x. Effects that used to be scaled up or down to read bigger or smaller (the landing and boss-death poofs, large XP gems, the finisher slash after reach upgrades, flying-enemy shots, obstacle-break poofs) now draw at 2x like everything else; bigger versions need larger hand-drawn art, not scaling. Flying-enemy shots, which reach an airborne angel and cross obstacles, are tinted violet (PLACEHOLDER) so they read apart from boss shots, which do neither. Opening `run.tscn` or a sin map scene directly (F6) still works but renders at native resolution without the pixel view; most tests use it that way.

`shop_smoke.gd` (with its own save file) checks feathers from kills, a guard, a shrine, a gem (pulled in), horde gem drops, and the sin, the HUD count and its fit, a damaged save clamped (negative feathers, out-of-range and unknown ranks), unaffordable, maxed, and unsavable purchases changing nothing, a purchase deducting its price and saving at once, the hub's balance and B opening the shop, its rows, pips, and prices, buying updating them and disabling what is no longer affordable, rows fitting the screen, Back returning to the hub, ranks applying once to a hub-launched run and never to an unhosted one, a purchase keeping sealed sins and Satan's fall, huge counters staying compact on the HUD, R during the fall waiting for the defeat to bank half (rounded down) with the card saying so, and a win banking everything exactly once even after a failed save and a retry.

`build_smoke.gd` checks might (spear, bow, side weapons), armor (and its floor of 1), haste (a hasted bow recovers twice as fast), luck (doubling a 50% heart chance always drops), the four stat level-ups in the pool, the three seeded chests on open ground away from the landing site, a chest opening once with one relic and dimming, a guard leaving a relic beside its evolution item, relics finding and levelling side weapons to III (then giving experience), the HUD list and find announcement, halos striking on touch with their re-hit delay, feathers holding fire with nothing in range then striking the nearest enemy in range and waiting their (hasted) interval, the pulse striking ground and flying enemies inside its ring only, the bolt striking within range only, no side weapon striking through a wall, real spear and side-weapon hits doubling under might, haste stopping at its floor and leaving the pool, portals keeping clear of chests, side weapons stopping once the angel falls, a feather already in flight not striking after the fall, and chests staying shut through the ending.

`evolution_smoke.gd` checks that a slain guard drops one evolution item for a weapon and a horde enemy can too, that collecting one pauses on that weapon's two paths (Esc refused, a level-up queued behind it and shown after, a flash on choosing, the gauge naming the path and its longest text fitting), once per weapon per run (a spare gives experience and later drops are for the other weapon), Whirlwind striking behind as well as ahead, Chain Light jumping along a chain but not beyond its range, Ricochet bouncing through a group while earlier arrows do not, Rain of Light landing at the aim within bow range and striking ground and flying enemies inside its circle after the delay but none outside, fresh runs starting unevolved, and a win closing an open choice.

`campaign_smoke.gd` (with its own save file) checks saved progress (fresh start, idempotent wins, Satan, round trip, a damaged file keeping only valid values, seven seals unlocking Satan), that every one of the eight map scenes keeps its authored obstacles and lava and has five shrines and guards (none on Satan's), the horde mixes (Sloth husks only and slower, Gluttony brutes, Envy flyers, husks before anything unlocks), Satan's calm ritual, his arrival and the horde after it, and his fall winning at once; that a sin map with its shrines deleted summons its sin after landing; then the hub (seven sins on screen, apart, clear of Satan and the header, sealed marks, Satan locked at six relics and S refused), and the loop: pressing 7 enters Sloth, R is refused during the ascension and before the hub, a win returns to the hub with the win saved, Satan unlocked and the new seal rippling once, a failed save is shown and waits (no automatic return) until a retry succeeds and seals the realm, S summons Satan's realm, and a defeat there offers Retry and the hub without saving a win.

`pixel_view_smoke.gd` checks the whole-number scales and centered bars at several window sizes, that the buffer stays 640x360, nearest/HDR settings, the camera zoom, that the HUD renders natively and the world in the buffer, that the player, spear, enemies, pickups (including big XP), poofs, flying-enemy shots and the finisher slash are all 2x, that mouse aim reaches the world through the scaled view with and without bars, that the camera lands on whole buffer pixels while the player keeps a fractional position, that Q, clicks, level-up choices (by click and number key while paused), the Esc pause menu (open, close, Resume button, refused over a level-up) and R restart all work through the host, that the UI scale follows the world scale, that a level-up arriving while paused replaces the pause menu, and that the boss tag and portal prompt are native HUD labels at independently computed positions (1080p and ultrawide with bars) that hide outside the world view. `hud_smoke.gd` checks the same tag position when `run.tscn` runs without the host.

## UI

The UI is crisp vector UI drawn by Godot from one shared theme, `eight/resources/ui_theme.tres`: the repo palette (void black, plum frames, pale mint text, pale gold highlights), **Alegreya Sans** for body and HUD text, **Marcellus** for headings and buttons (both SIL OFL 1.1; see `eight/assets/fonts/CREDITS.md`), and chamfered frames whose hover and panel states glow through StyleBox shadows. Type variations in the theme: `HeadingLabel` (Marcellus, gold), `MenuPanel` (glowing chamfered panel), and `ChoiceButton` (level-up cards). New screens should use the theme rather than inline styles.

- **Scaling:** the UI scales with the window at half the world's whole-number scale (1x at 1280x720, 1.5x at 1920x1080, 2x at 2560x1440) through the root content scale, so it keeps its size relative to the game and the text is re-rendered sharp at each size.
- **Pause:** Esc opens a pause menu (Resume, Restart run) and pauses the world; Esc or Resume closes it. It never opens over a level-up choice or after the run ends, closing it never unpauses a pending level-up, and a level-up that arrives while it is open replaces it.
- **Motion:** level-up panels and the pause menu pop in with a short overshoot, and the three level-up cards deal in one after another. UI tweens run while the tree is paused and ignore hit-stop slow-motion.
- **World tags:** the boss name and the portal's `EXIT [HOLD E]` prompt are HUD labels that follow their world position (`Hud.world_to_hud`), so they stay crisp instead of being drawn into the pixel buffer. A tag hides while its anchor is outside the world view, so it never floats in the bars.

## Shaders, glow and lighting

All look-development shaders, materials and light values are **PLACEHOLDER-tunable**, pending human art direction. No new art or audio is included. Forward Plus/D3D12 is preserved.

The run is dark: away from light the world shows as dim silhouettes, and glowing things are real light sources that reveal what is around them. There are three layers, all on canvas layer 0 so the result still blooms; Atmosphere is layer 1 and the HUD is layer 2.

1. **Glow.** HDR 2D and the run's Canvas-mode WorldEnvironment let colours above 1.0 (including drawn lava) bloom. Tight low glow levels and linear upscaling keep pixel edges clear. Tune `glow_intensity`, `glow_hdr_threshold` and `glow_levels` on WorldEnvironment.
2. **What glows: the light palette** (`eight/shaders/emissive.gdshader`). A sprite pixel painted in the material's `key` colour glows as `glow` x `energy`; with `whole` on, every pixel glows (things made of light). The key is matched on the original texture, so hit flashes and tints cannot switch a glow off. The materials beside the shader are the palette:
   - `eyes.tres`: **cream `#e6e29e` glows red** on every enemy and boss.
   - `player_light.tres`: **mint `#caebe0` glows blue-white** on the angel, and its cream halo glows gold.
   - `weapon_light.tres` (spear, bow, arrows, exit portal): cool whole-sprite glow; `enemy_ammo.tres`: hot orange-gold whole-sprite glow so enemy shots stay distinct from red enemies.
   - `pickup_light.tres`: every XP, life and item pickup glows in its own colours.
3. **What gets lit: darkness and lights** (`Lighting`, a CanvasGroup above the world in `run.tscn`). Its children draw light; `eight/shaders/lighting.gdshader` then multiplies the finished world by `ambient` + that light. Light is read once per art pixel (2 px) and stepped into dithered bands, so it stays on the pixel-art grid and does not swim when the camera moves. The camera snaps its final translation to whole world-buffer pixels; this intentionally trades away sub-pixel scrolling to keep the light cells stable. `Murk` is a faint additive haze drawn just below, so light pools read on the dark floor.

**Art rule for hand-made sprites:** to make something glow, paint it in the reserved colour: mint on the angel, cream on enemies. Nothing is set up per sprite. The cost is that those exact colours cannot be used for non-glowing detail on those sprites; on the placeholders, horn tips and teeth are cream, so they glow with the eyes. Greed and Sloth have dark pupils, so their cream details—not their pupils—glow until their placeholder art is repainted.

**Adding a light** takes one line: `add_to_group(&"light")` on a CanvasItem (or `groups=["light"]` in its scene). `eight/scripts/lights.gd` draws one falloff quad per visible member each frame, and a freed node leaves the group by itself. A light is two metadata values, `light` (a Color whose alpha is energy / 4) and `light_radius` (px), read from the node or, when the node has none, from its material. So a family is tuned once in its material (`eyes.tres`, `enemy_ammo.tres`, `weapon_light.tres`), and one kind can override it on its node (the boss sprite in `boss.tscn`, the exit portal in `exit_portal.tscn`). Lava makes one orange light per blob (`LIGHT_COLOR`, `LIGHT_REACH` in `lava_pools.gd`). Current lights: the angel's wings and halo, spear, bow and descent beam, enemy and boss sprites, enemy shots, arrows, pickups, the exit portal, and lava. Hit effects are not lights.

**Only the angel's light casts shadows.** `Lamp` (a PointLight2D on the player) lights nothing but `Lighting/AngelLight`, a light-only additive sheet, so its shadowed light joins the same sum as every other light. The lamp follows the angel's height and fades while descending, so the landing site stays dim until touchdown. Each `Breakable` carries a `LightOccluder2D` shaped like the drawn obstacle (a tree's trunk or the actual pillar art inside its texture), culled so the obstacle itself stays lit and its shadow falls behind it; breaking the obstacle removes the shadow. The Lamp's texture must fade by alpha, because a light-only item shows the light texture's alpha, and `shadow_item_cull_mask` must include AngelLight's light mask (2) as well as the occluders' (1), or no shadow is received.

| To change | Tune |
| --- | --- |
| How dark the unlit world is | `ambient` on Lighting's material |
| Band count, dither width, smooth light | `bands` (0 is smooth), `dither` |
| How bright light can get before it saturates | `max_light` |
| How much light shows on dark ground | `Murk` colour |
| The angel's light | `Lamp` energy, colour, `texture_scale` (reach) |
| A family's light | `metadata/light`, `metadata/light_radius` in its material |
| Glow colour and strength of a palette entry | `glow`, `energy` in its material |

- `eight/shaders/atmosphere.gdshader`: one screen sample, a restrained purple shadow grade, edge vignette, and two slow haze waves, applied after glow. Tune `strength` (0 disables), `vignette_strength`, `grade_strength`, `haze_strength`, and `drift_speed` on Atmosphere/Veil's material. The HUD is drawn afterwards.

Cost on the benchmark fixture (220 enemies, each a light; Windows / RTX 3060 / D3D12): median 2.24-2.27 ms against 1.98-2.00 ms just before, p95 3.6-3.8 ms against 3.3-3.5 ms, and 161 draw calls against 157. With the angel/weapon/beam lights and 600 glowing pickups added, three final-tuning runs measured median 2.70-2.77 ms and p95 4.37-4.39 ms, still at 161 draw calls.

Run `godot --headless --path eight --script res://tests/glow_smoke.gd` to check the rendering wiring: glow layers, the Lighting group, the Lamp, AngelLight and occluder masks, shadow removal on break, shared materials, that every requested actor, weapon, projectile, pickup, portal and lava blob is a light, that a freed light leaves the group, and that every angel, enemy and boss animation frame carries a glow-key pixel. Appearance still needs a windowed run.
