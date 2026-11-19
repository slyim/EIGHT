# EIGHT artist handoff

The [asset library](../) contains the [art](./), [audio](../audio/) and [fonts](../fonts/). Put new human-made drawings in this art folder under descriptive filenames. Keep editable sources with their exports and add the creator, rights and status to [art credits](CREDITS.md). The programmer can then switch the scene or script reference and check the result in game. Keep the existing placeholder available until that check passes.

**Start with the [illustrated offline handoff](handoff/index.html).** It pictures all 23 source sheets (136 unique source frames and every stored tag view), both original PNGs, the project SVG, and 139 actual runtime stills covering shared/tinted enemies, code-drawn visuals, realms and UI. Keep its `frames/`, `runtime/` and `originals/` folders beside the HTML so every local image and native-file link works offline. See the [verification report](handoff/VERIFICATION.md) for coverage, hashes and limits.

**Healing ring.** The [new gameplay reference](handoff/shrine-heal.png) shows the usable ring crossing a guard attack lane. Preserve both boundaries, the healing countdown and the visual difference between a charged and a spent shrine.

## Art already on disk

| Existing work | Use in the build |
| --- | --- |
| `eight_logo_pixel.png` | HUD logo. Owner-supplied design with an explicitly approved AI-assisted pixel adaptation. |
| `Sprite-0001.png` | Owner-supplied image. Imported, with its role and final status still for the owner to decide. |
| 23 Aseprite sheets | Procedural temporary art. The drawing list below accounts for every sheet. |
| Marcellus and Alegreya Sans | Selected, licensed interface fonts. Credits and license files are in the fonts folder. |
| Godot project icon | Editor/template icon at `res://icon.svg`. A human-made application icon is a separate delivery. |

## Art direction

- Use vector artwork for portraits and icons, and pixel art for the world. The world prototype uses nearest-neighbor sampling at 2×.
- The hero is a female angel in a purple cloak, riding a black ox and using a light spear/bow.
- Realm assignments: Odin/Pride red; Midas/Greed yellow; Lilith/Lust pink; Loki/Envy green; Wendigo/Gluttony orange; Cerberus/Wrath red; Edward/Sloth blue. Satan is the finale. Compare these targets with the [current realm renders](handoff/index.html#realms), rather than treating the placeholder visuals as final designs.

## Drawings with existing sheets

Use the [original sheets and tag reference](placeholder/CREDITS.md) as size and animation guides. The prototype mirrors right-facing sprites and renders them at 2×. One art pixel occupies two world units. The player shadow is drawn separately.

| Draw | Sheets | Canvas | Animation or alignment to preserve |
| --- | ---: | --- | --- |
| Female purple-cloaked angel riding the black ox | 1 | 32×32 | idle, run, dash, jump, descend |
| Spear of light | 1 | 48×16 | idle, grip at left edge |
| Spear finisher arc | 1 | 128×128 | one-shot `_slash` |
| Husk, imp, brute | 3 | 32×32 | walk |
| Pride, Greed, Lust, Envy, Gluttony, Wrath, Sloth, Satan | 8 | 64×64 | idle and attack for each |
| Experience, life and item pickups | 3 | 16×16 | idle |
| Enemy fire projectile | 1 | 16×16 | fly |
| Impact/disappearance puff | 1 | 32×32 | one-shot `_poof` |
| Corrupted floor, landing sigil and pillar | 3 | 32×32, 64×64, 80×80 | floor variation frames, idle sigil and pillar |
| Environmental props | 1 | 32×32 per frame | mushroom, dead grass, rock, thorns, bones, pool, crystal, growth, dead tree |

## Visuals that share art or are drawn by Godot

These have no dedicated final sheet. Each row describes what the player sees today. The owner can retain procedural motion, indicators or layout and supply only the underlying shapes and textures.

| Area | Human art to design or direct | Where to check it |
| --- | --- | --- |
| Other horde silhouettes | Flyer, charger, ground caster, bomber, splitter, shielder, mortar, sleeper and mirror. Distinguish the elite treatment, shield direction, airborne shadow and wake/fuse states at play size. | Enemy scenes, `scripts/run.gd`; [horde stills](handoff/index.html#runtime-enemy) and [state stills](handoff/index.html#runtime-state) |
| Weapons and hits | Bow, arrow, spear/bow evolution effects, orbiting halos, seeking feathers, holy pulse, judgment bolt, hit sparks and afterimages where used. | `mounted_player.gd`, `arrow.gd`, `side_weapons.gd`, `impact_sparks.gd`, `light_rain.gd`; [weapon and VFX stills](handoff/index.html#runtime-vfx) |
| Drops and objectives | Feather currency, side-weapon relic, spear and bow evolution pickups, closed/open chest, five shrines, their broken/healed state, and exit portal. | `pickup.gd`, `chest.gd`, `breakable.gd`, `exit_portal.gd`; [pickup stills](handoff/index.html#runtime-pickup) and [objective stills](handoff/index.html#runtime-objects) |
| Terrain and breakables | Wall segments, trees, damage stages and debris, arena boundary, lava surface and edges, realm tints, healed and scorched ground. | `breakable.gd`, `lava_pools.gd`, `run.gd`, `shaders/`; [object stills](handoff/index.html#runtime-objects), [hazards](handoff/index.html#runtime-hazards), [realms](handoff/index.html#realms) |
| Boss attacks | Charge lane, fans and rings, summon marks, guard, slam, shockwave, coins and rain, kisses and blink, leap and bile, devour, snore, sludge, yawn and nap, mirror attacks and decoys, Satan's beams. Preserve hit area, direction and warning timing. | `boss.gd`, `enemy_projectile.gd`, `shockwave.gd`, `ground_strike.gd`, `bile_zone.gd`; [tell stills](handoff/index.html#runtime-boss) and [release stills](handoff/index.html#runtime-release) |
| Interface and transitions | Pentagram hub, sin pedestals and relics, sealing ripple, health orb, resource gauges, shrine arrows, shop and choice panels, win/defeat treatment, descent and ascent effects. Preserve text and live values as UI. | `hub.gd`, `hud.gd`, `shop.gd`, `settings_panel.gd`, `resources/ui_theme.tres`; [full-scene stills](handoff/index.html#interface) |
| Prototype only | Practice target and training floor, if the spear test room is ever shown as finished content. | `prototype.gd`, `practice_target.gd`; [test-space still](handoff/index.html#interface) |

**First drawing batch.** Start with the female purple-cloaked angel and black ox, one husk, the light spear and the corrupted floor. Put them together in the opening encounter and check silhouette, grip position, and contrast at game scale before drawing the rest of the roster.
