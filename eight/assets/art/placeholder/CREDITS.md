# Sprite credits

**Status: the game's sprites for alpha 0.1, approved by the EIGHT project owner on 2026-11-19.**

- Files: all `.aseprite` sprites in this folder and their `.ase_bake.res` Aseprite Wizard bake files. The `placeholder_` file prefix is kept only so existing scene and script references stay valid.
- Source: drawn by code in `tools/placeholder_art.lua` (AI-written, run in Aseprite's batch mode) for EIGHT, from the owner's character and realm direction. They are generated, not hand-drawn. No external images, packs, or generative-image services were used.
- Palette and style direction: supplied by the EIGHT project owner (21-color palette, dark dithered mood, 32x32 base size).
- Rights: created for this repository; no third-party license applies.
- Redrawing: hand-drawn art can replace any file under the same name, tags (animation names), and canvas size; the game picks it up on import.

| File | Canvas | Animations (Aseprite tags) |
| --- | --- | --- |
| `placeholder_player` (purple-robed angel on a black ox; no baked shadow, the game draws it) | 32x32 | `idle`, `run`, `dash`, `jump`, `descend` |
| `placeholder_spear_light` (white light trident, pivot at the left edge; no detached particles) | 48x16 | `idle` |
| `placeholder_vfx_slash` (combo finisher arc) | 128x128 | `_slash` |
| `placeholder_enemy_husk`, `_imp`, `_brute` | 32x32 | `walk` |
| `placeholder_enemy_flying_eye` (winged eye creature for the flying shooter; no baked shadow) | 32x32 | `walk` |
| `placeholder_boss_pride`, `_greed`, `_lust`, `_envy`, `_gluttony`, `_wrath`, `_sloth`, `_satan` | 64x64 | `idle`, `attack` |
| `placeholder_boss_satan_head` (Satan's giant head) | 96x96 | `idle`, `attack` |
| `placeholder_boss_satan_hand` (each of Satan's two hands; faces right, mirrored for the left) | 48x48 | `idle`, `attack` |
| `placeholder_pickup_xp`, `_life`, `_item`, `_feather` (the shop currency) | 16x16 | `idle` |
| `placeholder_projectile_fire` | 16x16 | `fly` |
| `placeholder_vfx_poof` | 32x32 | `_poof` (the `_` prefix makes it play once) |
| `placeholder_env_floor` (corrupted plain) | 32x32 | `tiles` (each frame is a floor variant) |
| `placeholder_env_landing` (landing sigil) | 64x64 | `idle` |
| `placeholder_env_pillar` | 80x80 | `idle` |
| `placeholder_env_decor` (static props, one frame each) | 32x32 | `mushroom`, `deadgrass`, `rock`, `thorns`, `bones`, `pool`, `crystal`, `growth`, `deadtree` |

Art faces right; the game mirrors it. Everything is drawn at 2x in game, so every art pixel is the same size on screen.
