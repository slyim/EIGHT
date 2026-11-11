# Wave 3 placeholder shader verification

Implementation branch: `t3/glow-shaders-atmosphere`. No gameplay, placement, collision, damage, asset or renderer changes. No push.

## Added files

- `eight/shaders/emissive.gdshader` (+ UID): original-texture eye keys independent of hit flash/violet tint, cool emission preserving vertex alpha, and red projectile emission preserving texture silhouettes.
- `eight/shaders/atmosphere.gdshader` (+ UID): one screen sample, multiplicative purple shadow grade, vignette, slow two-wave haze; strength uniforms allow disabling.
- `eight/shaders/{eyes,player_light,weapon_light,enemy_ammo}.tres`: shared PLACEHOLDER-tunable material profiles. Enemies use instance uniforms, not material duplication.
- `eight/tests/glow_smoke.gd` (+ UID): HDR/Canvas glow/layer wiring, all enemy/boss materials, player and projectile materials, and colour-key coverage of every enemy/boss animation frame.

Existing project/scenes attach materials and add the WorldEnvironment and Atmosphere below HUD. Minimal edits in enemy.gd, enemy_projectile.gd, flying_enemy.gd and arrow.gd attach shared emission or remove the violet ammunition tint. README documents tuning.

## Eye inspection

Inspected baked frame images extracted through Godot, plus existing `tools/placeholder_art.lua`; no assets regenerated. All frames have distinguishable eyes, so no fallback art/points were needed. Coordinates below are untrimmed sprite pixels (bounds include bobbing).

| Sprite | Keys | Eye region x/y (exclusive end) |
| --- | --- | --- |
| Husk | cream #e6e29e | 19..22 / 15..17 |
| Imp, flying imp | cream | 19..20 / 11..14; single profile eye in side-facing art |
| Brute | cream | 25..27 / 13..15 |
| Pride | black #070109, cream in attack | 30..35 / 25..27 |
| Greed | black pupils | 25..40 / 34..36 |
| Lust | cream | 30..35 / 23..25 |
| Envy | cream, multiple body eyes | 24..40 / 20..55; closed eyes remain closed |
| Gluttony | cream | 22..35 / 15..20 |
| Wrath | cream | 29..36 / 26..29 |
| Sloth | black stalk pupils | 50..58 / 28..36 |
| Satan | cream idle, mint #caebe0 attack | 29..36 / 22..24 |

Palette keys are compared in linear colour space with tolerance 0.025; original texture sampling precedes modulation. Replace bounds/keys for differently packed or human-authored art. Godot documentation checked: https://docs.godotengine.org/en/latest/tutorials/3d/environment_and_post_processing.html#using-glow-in-2d and https://docs.godotengine.org/en/4.5/classes/class_projectsettings.html (glow upscaling). Actual 4.7.2 D3D12 windowed rendering verified the contract.

## Commands and results

All commands ran from the repository root. `G` below is `C:/Users/shyle/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`; temporary scripts/logs/screenshots are under `%TEMP%` and are excluded from the commit.

- Read AGENTS.md, README.md, applicable skill instructions and affected scripts/scenes; used `rg`, `git status`, `git diff`, and the Impeccable `context` launcher (success; scoped refinement allowed).
- `G --path eight --disable-vsync --max-fps 0 --script res://tests/performance_benchmark.gd`: initial attempt exit 1 (fresh worktree script-class cache missing). After import, exit 0: baseline 1.595 ms median, 2.782 p95, 57 draw calls.
- `G --headless --path eight --editor --import --quit`: before implementation and after implementation/final edits, exit 0. No script/shader errors. Expected unavailable Aseprite executable warnings only.
- `G --headless --path eight --script %TEMP%/eight-inspect.gd`: exit 0; extracted existing baked images for pixel inspection. Python/Pillow produced only temporary inspection crops/contact sheets.
- `G --path eight --script %TEMP%/eight-visual.gd`: initial fixture parse failure (missing movement argument to `_update_visuals`), corrected; reruns exit 0. Final fixture uses `--resolution 1280x720`, forces root window size, disables gameplay movement/spawning, and captures all roster sprites, all eight bosses, shots, arrow, portal, player and HUD.
- `G --path eight --disable-vsync --max-fps 0 --script res://tests/performance_benchmark.gd`: initial after 2.382 median, 4.055 p95, 58 draws. Switched glow upscaling to linear and standardized window resolution.
- Controlled original-HEAD baseline (temporarily restored tracked source bytes with Python, restored edits in finally): `G --path eight --resolution 1280x720 --disable-vsync --max-fps 0 --script res://tests/performance_benchmark.gd`, exit 0. Median **1.587 ms**, p95 **2.803 ms**, 57 draws. Mean process_s/physics_s/objects/nodes: 0.018159692 / 0.069389155 / 4762.133 / 2708.133.
- Same benchmark on final material tuning: exit 0. Median **1.792 ms**, p95 **3.123 ms**, 58 draws. Means: 0.021105020 / 0.052527953 / 4629.425 / 2560.413. Intermediate optimized sample: 1.775 median / 3.028 p95. The 720-frame fixture includes 120 warmup and 600 sampled frames on RTX 3060. Measured final increase is 0.205 ms median (12.9%), 0.320 ms p95; about 1.2% of a 60 FPS frame budget. This is measurable overhead, not a claim of zero cost. Fixture sampling time affects object/node means; monitor times are noisier than direct frame samples.
- `G --headless --path eight --script res://tests/<name>.gd`: each of `prototype_smoke`, `run_smoke`, `player_controls_smoke`, `flight_smoke`, `projectile_smoke`, `flying_enemy_smoke`, `hud_smoke`, `weapon_smoke`, `stage_smoke`, `glow_smoke` exited 0, PASS. Final glow test additionally checks every animation frame's eye keys. Expected shutdown ObjectDB/resources-in-use messages appeared on some runs, including the unchanged baseline.

## Windowed observations

Looked at saved viewport PNGs and enlarged eye crops, including idle, attack, full hit flash, full bow draw, hurt alpha, bloom disabled, atmosphere disabled, and Wrath floor tint. All four horde types have red eyes (the imp has one visible side-profile eye); all bosses have keyed red eyes, including Sloth's stalks and Satan's mint attack eyes. Red cores remain red during bright hit flashes and the flying violet tint. Shots have red bloom; flying shots are visibly smaller. The character has restrained cool emission, weapons/arrow and portal are brighter; bow draw shape, full-charge glint and hurt transparency remain visible. The HUD stays crisp above both effects. Vignette/haze are restrained; stage colours remain distinct. Bloom-on versus bloom-off images visibly differ around emissive elements (pixel comparison also confirms a changed halo). Screenshots are `%TEMP%/eight-glow-{spear,no-bloom,flash-bow,attack-bow,hurt-blink,no-atmosphere,wrath-floor}.png`.

Not verified: sustained human combat readability/feel, long-session GPU timing, alternate hardware/resolutions, and the other agents' lava/obstacles after merge. No human playtest was substituted by these scripted captures. HDR lava will enter the same canvas glow path; actual merged lava still needs inspection.
