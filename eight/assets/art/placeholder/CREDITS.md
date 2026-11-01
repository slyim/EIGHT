# Placeholder art credits

**Status: every file in this folder is a temporary `PLACEHOLDER`, to be replaced by hand-drawn art.**

- Files: all `placeholder_*.aseprite` sprites and their `.placeholder_*.ase_bake.res` Aseprite Wizard bake files.
- Source: drawn procedurally by `tools/placeholder_art.lua` (AI-written code, run in Aseprite's batch mode) for EIGHT. No external images, packs, or generative-image services were used.
- Palette and style direction: supplied by the EIGHT project owner (21-color palette, dark dithered mood, 32x32 base size).
- Rights: created for this repository; no third-party license applies.
- Replacement: draw the final art in Aseprite under the same file names, tags (animation names), and canvas sizes, and the game picks it up on import. Remove the `placeholder_` prefix and this notice once the files are human-made production art.

| File | Canvas | Animations (Aseprite tags) |
| --- | --- | --- |
| `placeholder_player` (purple-robed angel on a black ox; no baked shadow, the game draws it) | 32x32 | `idle`, `run`, `dash`, `jump`, `descend` |
| `placeholder_spear_light` (light trident, pivot at the left edge) | 48x16 | `idle` |
| `placeholder_vfx_slash` (combo finisher arc) | 128x128 | `_slash` |
| `placeholder_enemy_husk`, `_imp`, `_brute` | 32x32 | `walk` |
| `placeholder_boss_pride`, `_greed`, `_lust`, `_envy`, `_gluttony`, `_wrath`, `_sloth`, `_satan` | 64x64 | `idle`, `attack` |
| `placeholder_pickup_xp`, `_life`, `_item` | 16x16 | `idle` |
| `placeholder_projectile_fire` | 16x16 | `fly` |
| `placeholder_vfx_poof` | 32x32 | `_poof` (the `_` prefix makes it play once) |
| `placeholder_env_floor` (corrupted plain) | 32x32 | `tiles` (each frame is a floor variant) |
| `placeholder_env_landing` (landing sigil) | 64x64 | `idle` |
| `placeholder_env_pillar` | 80x80 | `idle` |
| `placeholder_env_decor` (static props, one frame each) | 32x32 | `mushroom`, `deadgrass`, `rock`, `thorns`, `bones`, `pool`, `crystal`, `growth`, `deadtree` |

Art faces right; the game mirrors it. Everything is drawn at 2x in game.
