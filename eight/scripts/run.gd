class_name Run
extends Node2D

## The run is over: emitted after the angel's ascension on a win, or once the fallen angel
## has dropped on a defeat. A host (Game) returns to the hub from here.
signal finished(victory: bool)
## Any enemy (horde, guard, sin, Satan) took damage: where (world), how much, whether it was a
## finisher or evolved strike (shown gold), and a stable key per enemy so numbers can stack.
signal enemy_damaged(at: Vector2, amount: int, heavy: bool, key: int)
## Survival run on one sin's map: horde spawning, experience, life, items, Satan's five
## shrines with their guards and countdown, then the sin boss and an exit portal. Arena
## layout, sprites, audio, stats, upgrades, and items are PLACEHOLDER content, not final design.

const ARENA_RECT: Rect2 = Rect2(-2000.0, -2000.0, 4000.0, 4000.0)
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const PORTAL_SCENE: PackedScene = preload("res://scenes/exit_portal.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/boss.tscn")
const FLOOR_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_env_floor.aseprite")
const BREAKABLE_SCENE: PackedScene = preload("res://scenes/breakable.tscn")
const DECOR_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_env_decor.aseprite")
const POOF_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_vfx_poof.aseprite")
const PIXEL_SCALE: float = 2.0
const LANDING_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_env_landing.aseprite")
const DECOR_COUNT: int = 460
## Decorations stay clear of the landing site in the middle of the plain.
const LANDING_CLEARANCE: float = 260.0
const DESCENT_HEIGHT: float = 420.0
const DESCENT_TIME: float = 1.6
## BOSSES index of Satan's map: no shrines; calm until Satan arrives after the ritual.
const SATAN: int = 7
## PLACEHOLDER seconds of calm after landing on Satan's map before Satan arrives.
const RITUAL_TIME: float = 3.0
## PLACEHOLDER win: the angel rises this high over this many seconds as the world heals.
const ASCENT_HEIGHT: float = 520.0
const ASCENT_TIME: float = 2.4
## PLACEHOLDER defeat: seconds the fallen angel lies before the end card, and the world's dim.
const FALL_TIME: float = 1.2
const FALLEN_TINT: Color = Color(0.5, 0.42, 0.55, 1.0)
## PLACEHOLDER: the darkness lifts to this ambient light as the won realm heals.
const SAVED_AMBIENT: Color = Color(0.8, 0.92, 0.86, 1.0)
## Satan's shrines stand on the points of a pentagram this far from the landing site.
const SHRINE_COUNT: int = 5
const SHRINE_RING: float = 1300.0
## PLACEHOLDER guards: a weaker copy of the map's sin boss beside each shrine. It defends the
## shrine while the angel is within GUARD_LEASH of it, and otherwise returns to it.
const GUARD_HEALTH_SCALE: float = 0.35
const GUARD_LEASH: float = 520.0
const GUARD_OFFSET: float = 130.0
## PLACEHOLDER healing: ground this far around a destroyed shrine shows healed, with a light.
const HEAL_RADIUS: float = 300.0
const HEAL_COLOR: Color = Color(0.36, 0.55, 0.45, 0.5)
const HEAL_LIGHT: Color = Color(0.55, 1.0, 0.8, 0.5)
## PLACEHOLDER obstacle layout. Structures stand where the old pillars stood on every map;
## wall segments and trees are scattered per map.
const STRUCTURE_SPOTS: Array[Vector2] = [Vector2(-600, -400), Vector2(700, 300), Vector2(-300, 900),
	Vector2(1200, -1000), Vector2(-1300, 700), Vector2(400, -1300)]
const WALL_COUNT: int = 8
const TREE_COUNT: int = 40
## Open ground kept between obstacles and from the arena walls, wider than the largest boss.
const OBSTACLE_LANE: float = 140.0

## PLACEHOLDER lava hazard: pool count and blob sizes per sin map (burn rates live on the
## Lava node). Layouts are deterministic per sin map.
const LAVA_COUNT_MIN: int = 6
const LAVA_COUNT_MAX: int = 11
const LAVA_RADIUS_MIN: float = 70.0
const LAVA_RADIUS_MAX: float = 150.0
const LAVA_BLOBS_MAX: int = 3
## Keep-out between pools and from walls and pillars.
const LAVA_SPACING: float = 72.0
## Extra keep-out beyond LANDING_CLEARANCE, so a pool rim never nears the landing sigil.
const LAVA_LANDING_MARGIN: float = 80.0
## Deterministic per-map seed; the step differs from the decor seed's.
const LAVA_SEED: int = 5501
const LAVA_SEED_STEP: int = 104729
const LAVA_ATTEMPTS: int = 600

## PLACEHOLDER AUDIO, synthesized by tools/placeholder_audio.py.
const SFX: Dictionary[StringName, AudioStream] = {
	&"spear_thrust": preload("res://assets/audio/placeholder/placeholder_spear_thrust.wav"),
	&"spear_sweep": preload("res://assets/audio/placeholder/placeholder_spear_sweep.wav"),
	&"jump": preload("res://assets/audio/placeholder/placeholder_jump.wav"),
	&"land": preload("res://assets/audio/placeholder/placeholder_land.wav"),
	&"holy_land": preload("res://assets/audio/placeholder/placeholder_holy_land.wav"),
	&"enemy_hit": preload("res://assets/audio/placeholder/placeholder_enemy_hit.wav"),
	&"enemy_death": preload("res://assets/audio/placeholder/placeholder_enemy_death.wav"),
	&"player_hurt": preload("res://assets/audio/placeholder/placeholder_player_hurt.wav"),
	&"dash": preload("res://assets/audio/placeholder/placeholder_dash.wav"),
	&"pickup_xp": preload("res://assets/audio/placeholder/placeholder_pickup_xp.wav"),
	&"pickup_life": preload("res://assets/audio/placeholder/placeholder_pickup_life.wav"),
	&"pickup_item": preload("res://assets/audio/placeholder/placeholder_pickup_item.wav"),
	&"level_up": preload("res://assets/audio/placeholder/placeholder_level_up.wav"),
	&"boss_spawn": preload("res://assets/audio/placeholder/placeholder_boss_spawn.wav"),
	&"boss_attack": preload("res://assets/audio/placeholder/placeholder_boss_attack.wav"),
	&"boss_death": preload("res://assets/audio/placeholder/placeholder_boss_death.wav"),
	&"victory": preload("res://assets/audio/placeholder/placeholder_victory.wav"),
	&"defeat": preload("res://assets/audio/placeholder/placeholder_defeat.wav"),
}
## Minimum seconds between repeats, so hordes do not stack dozens of identical sounds.
const SFX_SPACING: float = 0.045
const SFX_VOICES: int = 16

## Roster indices into ENEMY_TYPES (and the columns of ENEMY_UNLOCK and SIN_ENEMY_WEIGHTS).
const HUSK: int = 0
const IMP: int = 1
const BRUTE: int = 2
const FLYER: int = 3
const CHARGER: int = 4
const CASTER: int = 5
const BOMBER: int = 6
const SPLITTER: int = 7
const SHIELDER: int = 8
const MORTAR: int = 9
const SLEEPER: int = 10
const MIRROR: int = 11
## PLACEHOLDER horde types. An optional "scene" key instantiates a different enemy;
## the rest spawn the plain Enemy scene. "knockback" is the type's weight: light imps fly back,
## heavy brutes barely move. An optional "split" key makes the enemy die into that many of a
## type (which never split themselves).
const ENEMY_TYPES: Array[Dictionary] = [
	{"health": 1, "speed": 105.0, "radius": 14.0, "xp": 1, "damage": 10, "knockback": 240.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_husk.aseprite")},
	{"health": 1, "speed": 165.0, "radius": 10.0, "xp": 1, "damage": 8, "knockback": 310.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_imp.aseprite")},
	{"health": 4, "speed": 72.0, "radius": 22.0, "xp": 4, "damage": 25, "knockback": 120.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_brute.aseprite")},
	# Flying: hovers at a distance and fires aimed shots that reach an airborne player.
	{"health": 2, "speed": 120.0, "radius": 14.0, "xp": 3, "damage": 8, "knockback": 220.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_imp.aseprite"), "scene": preload("res://scenes/flying_enemy.tscn")},
	# Charger: stops, shows a lane, dashes along it, then stands still (punish it then).
	{"health": 3, "speed": 95.0, "radius": 18.0, "xp": 3, "damage": 18, "knockback": 160.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_brute.aseprite"), "scene": preload("res://scenes/charger.tscn")},
	# Ground caster: keeps its distance and fires ground shots after an ember glint.
	{"health": 2, "speed": 110.0, "radius": 12.0, "xp": 3, "damage": 8, "knockback": 260.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_imp.aseprite"), "scene": preload("res://scenes/ground_caster.tscn")},
	# Bomber: runs in, lights a fuse, and explodes, hurting the angel and nearby enemies.
	{"health": 1, "speed": 150.0, "radius": 11.0, "xp": 2, "damage": 22, "knockback": 300.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_imp.aseprite"), "scene": preload("res://scenes/bomber.tscn")},
	# Splitter: dies into two husks.
	{"health": 4, "speed": 80.0, "radius": 20.0, "xp": 2, "damage": 15, "knockback": 140.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_brute.aseprite"), "scene": preload("res://scenes/splitter.tscn"), "split": {"type": HUSK, "count": 2}},
	# Shielder: blocks blows from its front; finishers break its guard.
	{"health": 4, "speed": 70.0, "radius": 20.0, "xp": 4, "damage": 18, "knockback": 100.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_brute.aseprite"), "scene": preload("res://scenes/shielder.tscn")},
	# Mortar: stands back and marks circles under the angel that land a moment later.
	{"health": 3, "speed": 85.0, "radius": 18.0, "xp": 3, "damage": 12, "knockback": 160.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_brute.aseprite"), "scene": preload("res://scenes/mortar.tscn")},
	# Sleeper: still until woken, then fast, pulsing a slowing ring.
	{"health": 4, "speed": 95.0, "radius": 14.0, "xp": 3, "damage": 12, "knockback": 200.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_husk.aseprite"), "scene": preload("res://scenes/sleeper.tscn")},
	# Mirror: rushes a spear, shoots at a bow.
	{"health": 3, "speed": 140.0, "radius": 12.0, "xp": 4, "damage": 12, "knockback": 240.0, "frames": preload("res://assets/art/placeholder/placeholder_enemy_imp.aseprite"), "scene": preload("res://scenes/mirror.tscn")},
]

## One sin per map (sin_index); the last entry is Satan. Stats and patterns are PLACEHOLDER.
const BOSSES: Array[Dictionary] = [
	# Pride: phase 2 (half health) adds a guard stance that ends in a slam. Smarter tiers chain
	# its charges (smarts 1+) and turn some aimed fans into air fans (smarts 2+).
	{"name": "PRIDE", "health": 100, "speed": 95.0, "radius": 36.0, "interval": 2.4, "damage": 20,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_pride.aseprite"), "patterns": [Boss.Pattern.AIMED, Boss.Pattern.CHARGE],
		"phase_patterns": [[Boss.Pattern.AIMED, Boss.Pattern.CHARGE], [Boss.Pattern.AIMED, Boss.Pattern.CHARGE, Boss.Pattern.GUARD]],
		"phase_combos": [{}, {Boss.Pattern.GUARD: [Boss.Pattern.SLAM]}],
		"smart": {"chain_charges": 1, "air_fans": 2}},
	# Greed: coin rings with gaps either side of the angel, and ground casters at its side; at 60%
	# violet rain falls around the angel; at a quarter its coin rings spiral. Smarter tiers add a
	# coin wave to each volley (smarts 1+) and lead the rain (smarts 2+).
	{"name": "GREED", "health": 130, "speed": 80.0, "radius": 38.0, "interval": 2.6, "damage": 20,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_greed.aseprite"), "patterns": [Boss.Pattern.COINS, Boss.Pattern.SUMMON],
		"phase_thresholds": [0.6, 0.25],
		"phase_patterns": [[Boss.Pattern.COINS, Boss.Pattern.SUMMON], [Boss.Pattern.COINS, Boss.Pattern.RAIN, Boss.Pattern.SUMMON], [Boss.Pattern.COINS, Boss.Pattern.RAIN]],
		"phase_combos": [{}, {}, {Boss.Pattern.COINS: [Boss.Pattern.COINS, Boss.Pattern.COINS]}],
		"summon_type": CASTER, "smart": {"extra_waves": 1, "lead_rain": 2}},
	# Lust: charges and slow violet air kisses; at half health it blinks behind the angel and charges
	# at once (a quicker lane). Smarter tiers blink twice in a row (smarts 1+) and summon flyers once
	# past half health (smarts 2+).
	{"name": "LUST", "health": 110, "speed": 140.0, "radius": 32.0, "interval": 2.0, "damage": 20,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_lust.aseprite"), "patterns": [Boss.Pattern.CHARGE, Boss.Pattern.KISSES],
		"phase_patterns": [[Boss.Pattern.CHARGE, Boss.Pattern.KISSES], [Boss.Pattern.CHARGE, Boss.Pattern.KISSES, Boss.Pattern.BLINK]],
		"phase_combos": [{}, {Boss.Pattern.BLINK: [Boss.Pattern.CHARGE]}],
		"chained_charge_windup": 0.5,
		"smart": {"reaim": 0, "double_blink": 1, "summon": [2, FLYER]}},
	{"name": "ENVY", "health": 140, "speed": 105.0, "radius": 36.0, "interval": 2.2, "damage": 20,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_envy.aseprite"), "patterns": [Boss.Pattern.AIMED, Boss.Pattern.SUMMON]},
	# Gluttony: leaps onto the angel's spot and leaves bile, and vomits a wide fan; at half health
	# it devours (pulls the angel and the horde into its mouth, eats horde enemies, bites; it never
	# heals); at a fifth it summons splitters. Smarter tiers leap twice (smarts 1+) and leave bile
	# longer (smarts 2+).
	{"name": "GLUTTONY", "health": 220, "speed": 60.0, "radius": 54.0, "interval": 2.6, "damage": 20,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_gluttony.aseprite"), "patterns": [Boss.Pattern.LEAP, Boss.Pattern.VOMIT],
		"phase_thresholds": [0.5, 0.2],
		"phase_patterns": [[Boss.Pattern.LEAP, Boss.Pattern.VOMIT], [Boss.Pattern.LEAP, Boss.Pattern.VOMIT, Boss.Pattern.DEVOUR],
			[Boss.Pattern.LEAP, Boss.Pattern.VOMIT, Boss.Pattern.DEVOUR, Boss.Pattern.SUMMON]],
		"phase_combos": [{}, {}, {}], "summon_type": SPLITTER,
		"smart": {"double_leap": 1, "long_bile": 2}},
	# Wrath: charges twice and slams where it stops; at half health it enrages (faster, and a
	# burst after each charge); at a fifth it adds shockwaves. Smarter tiers re-aim its second
	# charge (smarts 1+) and let it summon bombers once enraged (smarts 2+).
	{"name": "WRATH", "health": 200, "speed": 125.0, "radius": 40.0, "interval": 1.8, "damage": 20,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_wrath.aseprite"), "patterns": [Boss.Pattern.CHARGE, Boss.Pattern.AIMED],
		"phase_thresholds": [0.5, 0.2],
		"phase_patterns": [[Boss.Pattern.CHARGE, Boss.Pattern.AIMED], [Boss.Pattern.CHARGE], [Boss.Pattern.CHARGE, Boss.Pattern.SHOCKWAVE]],
		"phase_combos": [{Boss.Pattern.CHARGE: [Boss.Pattern.CHARGE, Boss.Pattern.SLAM]},
			{Boss.Pattern.CHARGE: [Boss.Pattern.BURST, Boss.Pattern.CHARGE, Boss.Pattern.BURST, Boss.Pattern.SLAM]},
			{Boss.Pattern.CHARGE: [Boss.Pattern.BURST, Boss.Pattern.CHARGE, Boss.Pattern.BURST, Boss.Pattern.SLAM]}],
		"phase_speeds": [1.0, 1.2, 1.2], "phase_paces": [1.0, 0.75, 0.75], "slam_radius": 90.0, "slam_windup": 0.5,
		"smart": {"reaim": 1, "summon": [2, BOMBER]}},
	# Sloth: snores slow rings and spreads slowing sludge; at half health it yawns (a huge slam
	# with a long tell) and naps (a long punish window); at a fifth it wakes: a new tint, three times
	# as fast, charging, attacking far more often. Smarter tiers spread longer-lasting sludge
	# (smarts 1+) and rain from the air right after a yawn (smarts 2+).
	{"name": "SLOTH", "health": 240, "speed": 45.0, "radius": 46.0, "interval": 2.4, "damage": 20,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_sloth.aseprite"), "patterns": [Boss.Pattern.SNORE, Boss.Pattern.SLUDGE],
		"phase_thresholds": [0.65, 0.25],
		"phase_patterns": [[Boss.Pattern.SNORE, Boss.Pattern.SLUDGE], [Boss.Pattern.SNORE, Boss.Pattern.SLUDGE, Boss.Pattern.YAWN],
			[Boss.Pattern.CHARGE, Boss.Pattern.SNORE, Boss.Pattern.SLUDGE]],
		"phase_combos": [{}, {Boss.Pattern.YAWN: [Boss.Pattern.NAP]}, {}],
		"phase_speeds": [1.0, 1.0, 2.5], "phase_paces": [1.0, 0.85, 0.7],
		"phase_tints": [Color.WHITE, Color.WHITE, Color(1.35, 0.8, 0.75, 1.0)],
		"smart": {"long_sludge": 1, "rain_after_yawn": 2}},
	{"name": "SATAN", "health": 520, "speed": 110.0, "radius": 50.0, "interval": 1.5, "damage": 20,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_satan.aseprite"), "patterns": [Boss.Pattern.CHARGE, Boss.Pattern.BURST,
		Boss.Pattern.AIMED, Boss.Pattern.SUMMON]},
]

## Level-up choices. PLACEHOLDER names and values.
const UPGRADES: Array[Dictionary] = [
	{"name": "Sharper spear", "text": "+1 spear damage", "stat": "damage", "amount": 1.0},
	{"name": "Quicker thrusts", "text": "Thrust 12% faster", "stat": "attack_speed", "amount": 0.88},
	{"name": "Longer spear", "text": "+16 spear reach", "stat": "reach", "amount": 16.0},
	{"name": "Swifter mount", "text": "+20 movement speed", "stat": "speed", "amount": 20.0},
	{"name": "Vitality", "text": "+20 max health and heal 20", "stat": "max_health", "amount": 20.0},
	{"name": "Wider pull", "text": "+40 pickup radius", "stat": "magnet", "amount": 40.0},
	{"name": "Piercing spear", "text": "Thrust hits +1 more enemy", "stat": "pierce", "amount": 1.0},
	{"name": "Quicker dash", "text": "Dash cooldown -15%", "stat": "dash", "amount": 0.85},
	{"name": "Heavier arrows", "text": "+1 arrow damage", "stat": "bow_damage", "amount": 1.0},
	{"name": "Quicker shots", "text": "Bow fires 15% faster", "stat": "bow_speed", "amount": 0.85},
	{"name": "Piercing arrows", "text": "Arrows hit +1 more enemy", "stat": "bow_pierce", "amount": 1.0},
	{"name": "Might", "text": "+10% damage from every weapon", "stat": "might", "amount": 0.1},
	{"name": "Armor", "text": "Enemy hits deal 1 less damage", "stat": "armor", "amount": 1.0},
	{"name": "Haste", "text": "All cooldowns 8% shorter", "stat": "haste", "amount": 0.92},
	{"name": "Luck", "text": "+20% heart, item, and evolution drops", "stat": "luck", "amount": 0.2},
]
## PLACEHOLDER chests per map when its scene authors none, placed from the map's seed.
const CHEST_COUNT: int = 3
const CHEST_CLEARANCE: float = 500.0
## Experience given by a relic once every side weapon is at its highest level.
const SPARE_RELIC_XP: int = 10
## PLACEHOLDER feathers (the shop's currency) earned in a run: per kill, per guard, per shrine,
## for the sin (Satan pays more), and per feather gem picked up. Banked by the host when the run
## ends: all of it on a win, half (rounded down) on a defeat.
const FEATHERS_PER_KILL: int = 1
const FEATHERS_PER_GUARD: int = 10
const FEATHERS_PER_SHRINE: int = 15
const FEATHERS_PER_SIN: int = 50
const FEATHERS_PER_SATAN: int = 100
const FEATHER_GEM_VALUE: int = 5

## Weapon evolutions, per MountedPlayer.Weapon, in path order (path 1, path 2). Each changes
## that weapon's finisher; a weapon evolves once per run. PLACEHOLDER names and wording.
const EVOLUTIONS: Array[Array] = [
	[{"name": "Whirlwind", "text": "The finisher becomes a full spin, striking all around the angel."},
		{"name": "Chain Light", "text": "Finisher hits arc lightning on to up to 3 more enemies nearby."}],
	[{"name": "Ricochet", "text": "The finishing arrow bounces on to up to 4 more enemies."},
		{"name": "Rain of Light", "text": "The finishing shot calls light down on a circle at the aim."}],
]
## Experience given by an evolution item for a weapon that has already evolved.
const SPARE_EVOLUTION_XP: int = 10

## Collectible items found in the arena. PLACEHOLDER names and values.
const ITEMS: Array[Dictionary] = [
	{"name": "Item: Spearhead", "text": "+2 spear damage", "stat": "damage", "amount": 2.0},
	{"name": "Item: Feather", "text": "Thrust 20% faster", "stat": "attack_speed", "amount": 0.8},
	{"name": "Item: Heart vessel", "text": "+40 max health and heal 40", "stat": "max_health", "amount": 40.0},
	{"name": "Item: Lodestone", "text": "+90 pickup radius", "stat": "magnet", "amount": 90.0},
	{"name": "Item: Long haft", "text": "+28 spear reach", "stat": "reach", "amount": 28.0},
	{"name": "Item: Drill tip", "text": "Thrust hits +2 more enemies", "stat": "pierce", "amount": 2.0},
	{"name": "Item: Horseshoe", "text": "+40 movement speed", "stat": "speed", "amount": 40.0},
	{"name": "Item: Phial", "text": "Restore all life", "stat": "heal", "amount": 0.0},
]

## Difficulty (minutes) at which each roster entry joins the horde: husk, imp, brute, flyer.
## (Husk, imp, brute, flyer, charger, caster, bomber, splitter, shielder, mortar, sleeper,
## mirror.)
const ENEMY_UNLOCK: Array[float] = [0.0, 0.75, 2.0, 1.0, 1.5, 1.25, 2.5, 2.0, 2.25, 2.0, 1.75, 3.0]
## PLACEHOLDER horde mix per map: weights per roster type among the unlocked ones.
## Pride balanced with chargers and shielders, Greed imps, casters and mortars, Lust imps,
## flyers and casters, Envy flyers, splitters and mirrors, Gluttony brutes and splitters, Wrath
## imps, brutes, chargers and bombers, Sloth husks, sleepers and mortars, Satan everything.
const SIN_ENEMY_WEIGHTS: Array[Array] = [
	[4.0, 2.0, 1.0, 1.0, 2.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0],
	[2.0, 5.0, 1.0, 1.0, 0.0, 3.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0],
	[1.0, 4.0, 0.0, 3.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	[2.0, 1.0, 1.0, 5.0, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0, 0.0, 2.0],
	[2.0, 1.0, 5.0, 0.0, 0.0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0],
	[1.0, 4.0, 4.0, 0.0, 3.0, 0.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0],
	[1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 3.0, 0.0],
	[3.0, 3.0, 2.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
]
## PLACEHOLDER spawn pace per map (interval multiplier): Sloth's horde comes slower.
const SIN_SPAWN_PACE: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.4, 1.0]
## One difficulty unit per minute; tiers step every two units.
const DIFFICULTY_SECONDS: float = 60.0
const TIER_UNITS: float = 2.0
const HORDE_SPEED_GAIN: float = 0.15
const HORDE_HEALTH_GAIN: float = 0.6
const HORDE_DAMAGE_GAIN: float = 0.18
const BOSS_SPEED_GAIN: float = 0.04
const BOSS_HEALTH_GAIN: float = 0.15
const BOSS_DAMAGE_GAIN: float = 0.06
const BASE_SPAWN_INTERVAL: float = 1.1
const MIN_SPAWN_INTERVAL: float = 0.18
const SPAWN_PRESSURE_GAIN: float = 0.35
const MAX_SPAWN_BATCH: int = 12
## Difficulty tiers, chosen per map on the pentagram (see Progress.max_tier). PLACEHOLDER
## values (Kimi's proposal, health growth softened so the 8-minute countdown stays reachable). "health"/"damage"/"speed" multiply the horde's base stats and the
## "*_scaling" ones multiply its per-minute gains; "spawn_interval" and "spawn_pressure" shape
## the spawn pace and "batch" adds enemies per wave. "boss_*" do the same for the sin, Satan and
## the guards; "attack_rate" divides their attack interval and "patterns" adds that many of the
## generic patterns they lack. "feathers" multiplies every feather earned. The countdown never
## changes.
const TIERS: Array[Dictionary] = [
	{"name": "PENANCE", "health": 1.0, "damage": 1.0, "speed": 1.0, "health_scaling": 1.0, "damage_scaling": 1.0, "speed_scaling": 1.0,
		"spawn_interval": 1.0, "spawn_pressure": 1.0, "batch": 0, "boss_health": 1.0, "boss_damage": 1.0, "boss_speed": 1.0,
		"boss_scaling": 1.0, "attack_rate": 1.0, "patterns": 0, "feathers": 1.0},
	{"name": "PURGATORY", "health": 1.4, "damage": 1.25, "speed": 1.05, "health_scaling": 1.1, "damage_scaling": 1.15, "speed_scaling": 1.1,
		"spawn_interval": 0.85, "spawn_pressure": 1.15, "batch": 0, "boss_health": 1.3, "boss_damage": 1.2, "boss_speed": 1.03,
		"boss_scaling": 1.1, "attack_rate": 1.2, "patterns": 1, "feathers": 1.5},
	{"name": "DAMNATION", "health": 1.9, "damage": 1.6, "speed": 1.1, "health_scaling": 1.2, "damage_scaling": 1.3, "speed_scaling": 1.2,
		"spawn_interval": 0.7, "spawn_pressure": 1.3, "batch": 1, "boss_health": 1.7, "boss_damage": 1.5, "boss_speed": 1.06,
		"boss_scaling": 1.2, "attack_rate": 1.45, "patterns": 2, "feathers": 2.0},
	{"name": "ABYSS", "health": 2.5, "damage": 2.0, "speed": 1.15, "health_scaling": 1.35, "damage_scaling": 1.5, "speed_scaling": 1.3,
		"spawn_interval": 0.55, "spawn_pressure": 1.5, "batch": 2, "boss_health": 2.2, "boss_damage": 1.85, "boss_speed": 1.1,
		"boss_scaling": 1.25, "attack_rate": 1.75, "patterns": 2, "feathers": 3.0},
]
## PLACEHOLDER floor tints per sin map.
const REALM_TINTS: Array[Color] = [Color.WHITE, Color("a9c8a0"), Color("d4a5c6"),
	Color("9bbfd5"), Color("b6b58a"), Color("d69a91"), Color("aba0cb"), Color("c08bba")]

@export var spawning_enabled: bool = true
## Open the run with the angel descending onto the plain.
@export var intro_enabled: bool = true
## Which sin this map belongs to (index into BOSSES; 7 is Satan). Seeds the layout and tint.
@export_range(0, 7, 1) var sin_index: int = 0
## Difficulty tier (index into TIERS). Set before the run enters the tree: guards are made in _ready.
@export_range(0, 3, 1) var tier: int = 0
## PLACEHOLDER countdown: seconds after landing to destroy every shrine, or the angel dies.
@export_range(10.0, 3600.0, 10.0) var shrine_time: float = 480.0
@export_range(10, 1000, 10) var max_enemies: int = 220
@export_range(0.0, 1.0, 0.005) var heart_drop_chance: float = 0.03
@export_range(0.0, 1.0, 0.001) var item_drop_chance: float = 0.006
## PLACEHOLDER chance a horde enemy drops a feather gem (scaled by luck).
@export_range(0.0, 1.0, 0.005) var feather_drop_chance: float = 0.03
## PLACEHOLDER chance a horde enemy drops an evolution item (guards always drop one).
@export_range(0.0, 1.0, 0.0005) var evolution_drop_chance: float = 0.002
## Authored lava: one entry per pool, each a list of [center, radius] blobs. Empty means
## generate from the map's seed. Sin map scenes carry theirs, so they can be edited.
@export var lava_layout: Array = []

var elapsed: float = 0.0
var spawn_left: float = 1.0
var shrine_time_left: float = 0.0
var shrines_left: int = 0
## Shrines the map started with (0 on Satan's map, or on a map authored without any).
var shrine_total: int = 0
## Where shrines fell; the ground around each is drawn healed.
var healed_spots: Array[Vector2] = []
var guards: Array[Boss] = []
var sin_boss_defeated: bool = false
var ritual_left: float = RITUAL_TIME
## 0..1 while the won world heals over the ascension.
var heal_world: float = 0.0:
	set(value):
		heal_world = value
		queue_redraw()
var exit_portal: ExitPortal
var current_boss: Boss
var enemy_count: int = 0
var level: int = 1
var xp: int = 0
var kills: int = 0
var pending_level_ups: int = 0
var level_up_options: Array[Dictionary] = []
## The weapon whose evolution choice is open, or -1.
var evolution_weapon: int = -1
## Feathers earned this run (banked by the host when the run ends).
var feathers_earned: int = 0
## True once the end card is up (after the fall or the ascension); restart waits for it.
var ending_done: bool = false
## The newest side-weapon find, for the HUD to announce: [kind, level], or empty.
var last_relic: Array = []
var items: Array[Dictionary] = []
var ended: bool = false
var victory: bool = false
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_next_voice: int = 0
var sfx_last_played: Dictionary[StringName, float] = {}
## Static decorations, drawn once with the floor: [texture, position, flip].
var decor_props: Array[Array] = []
var has_landed: bool = false
var sparks: ImpactSparks

@onready var geometry: StaticBody2D = $Geometry
@onready var obstacles: Node2D = $Obstacles
@onready var chests: Node2D = $Chests
@onready var pickups: Node2D = $Pickups
@onready var actors: Node2D = $Actors
@onready var player: MountedPlayer = $MountedPlayer
@onready var hud: Hud = $HUD/Hud
@onready var effects: Node2D = $Effects
@onready var music: AudioStreamPlayer = $Music
@onready var lava: LavaPools = $Lava
@onready var veil: ShaderMaterial = ($Atmosphere/Veil as ColorRect).material as ShaderMaterial


func _ready() -> void:
	shrine_time_left = shrine_time
	# The sin-eye material is shared by every enemy; start each run from the scene default
	# (HIGH). A hub-launched run then applies the player's quality (see Game and Settings).
	Enemy.EYE_MATERIAL.set_shader_parameter(&"pulse", Settings.PULSE_ON)
	var camera: Camera2D = player.get_node("Camera2D") as Camera2D
	camera.limit_left = int(ARENA_RECT.position.x)
	camera.limit_top = int(ARENA_RECT.position.y)
	camera.limit_right = int(ARENA_RECT.end.x)
	camera.limit_bottom = int(ARENA_RECT.end.y)
	player.died.connect(_on_player_died)
	player.hurt.connect(play_sfx.bind(&"player_hurt"))
	player.attack_started.connect(_on_player_attack)
	player.jumped.connect(play_sfx.bind(&"jump"))
	player.landed.connect(_on_player_landed)
	player.dashed.connect(play_sfx.bind(&"dash"))
	# PLACEHOLDER AUDIO: a perfect dodge reuses the item chime.
	player.perfect_dodged.connect(play_sfx.bind(&"pickup_item", 0.0))
	sparks = ImpactSparks.new()
	sparks.name = &"Sparks"
	effects.add_child(sparks)
	# PLACEHOLDER AUDIO: the bow reuses the spear thrust sound.
	player.arrow_fired.connect(play_sfx.bind(&"spear_thrust", 0.12).unbind(1))
	hud.run = self
	for index: int in range(SFX_VOICES):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = &"Master"
		voice.volume_db = -6.0
		# Level-up and victory sounds play while the tree is paused.
		voice.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(voice)
		sfx_players.append(voice)
	(music.stream as AudioStreamOggVorbis).loop = true
	# A sin map scene carries its own authored obstacles and lava; otherwise generate them.
	if obstacles.get_child_count() == 0:
		_place_obstacles()
	else:
		_adopt_obstacles()
	lava.player = player
	if lava_layout.is_empty():
		_scatter_lava()
	else:
		lava.set_pools(lava_layout)
	_scatter_decor()
	_spawn_guards()
	_place_chests()
	player.ascended.connect(_on_ascended)
	if intro_enabled:
		player.begin_descent(DESCENT_HEIGHT, DESCENT_TIME)
	else:
		has_landed = true
		music.play()


## Pins the haze to the world: the veil learns which world area the view shows this frame.
func _process(_delta: float) -> void:
	var canvas: Transform2D = get_viewport().get_canvas_transform()
	veil.set_shader_parameter(&"world_origin", canvas.affine_inverse() * Vector2.ZERO)
	veil.set_shader_parameter(&"world_size", get_viewport().get_visible_rect().size / canvas.get_scale())


func _on_player_attack(step: int) -> void:
	if step == MountedPlayer.COMBO_LENGTH - 1:
		play_sfx(&"spear_sweep", 0.05)
	else:
		play_sfx(&"spear_thrust", 0.12)


func _on_player_landed() -> void:
	if has_landed:
		play_sfx(&"land")
		_spawn_poof(player.global_position + Vector2(0.0, 12.0))
		return
	# First touchdown on the plain: the run begins.
	has_landed = true
	play_sfx(&"holy_land", 0.0)
	_spawn_poof(player.global_position + Vector2(0.0, 12.0))
	music.play()


func play_sfx(sound: StringName, pitch_jitter: float = 0.08) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(sfx_last_played.get(sound, -1.0)) < SFX_SPACING:
		return
	sfx_last_played[sound] = now
	var voice: AudioStreamPlayer = sfx_players[sfx_next_voice]
	sfx_next_voice = (sfx_next_voice + 1) % sfx_players.size()
	voice.stream = SFX[sound]
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.play()


## Always drawn at PIXEL_SCALE so every art pixel matches; bigger bursts need bigger art.
func _spawn_poof(at: Vector2) -> void:
	var poof: AnimatedSprite2D = AnimatedSprite2D.new()
	poof.sprite_frames = POOF_FRAMES
	poof.position = at
	poof.scale = Vector2(PIXEL_SCALE, PIXEL_SCALE)
	poof.animation_finished.connect(poof.queue_free)
	effects.add_child(poof)
	poof.play(&"poof")


## PLACEHOLDER decoration: static, non-blocking props scattered with a fixed seed.
func _scatter_decor() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	decor_props.clear()
	rng.seed = 8 + sin_index * 7919
	var animations: PackedStringArray = DECOR_FRAMES.get_animation_names()
	# Trees are breakable obstacles now; a dead-tree floor prop would read as one.
	animations.erase("deadtree")
	while decor_props.size() < DECOR_COUNT:
		var at: Vector2 = Vector2(
			rng.randf_range(ARENA_RECT.position.x + 48.0, ARENA_RECT.end.x - 48.0),
			rng.randf_range(ARENA_RECT.position.y + 48.0, ARENA_RECT.end.y - 48.0)
		)
		if _blocked_rect(at.x, at.y, 40.0) or at.length() < LANDING_CLEARANCE or lava.point_in_lava(at, 24.0):
			continue
		var animation: StringName = StringName(animations[rng.randi() % animations.size()])
		decor_props.append([DECOR_FRAMES.get_frame_texture(animation, 0), at, rng.randf() < 0.5])
	queue_redraw()


## PLACEHOLDER lava: irregular pools of one to three overlapping blobs, deterministic
## per sin map, clear of the landing site, walls and obstacles, and spaced from each other.
func _scatter_lava() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = LAVA_SEED + sin_index * LAVA_SEED_STEP
	var target: int = rng.randi_range(LAVA_COUNT_MIN, LAVA_COUNT_MAX)
	var pool_blobs: Array = []
	var accepted: Array = [] # [center, extent] of the pools placed so far.
	for attempt: int in range(LAVA_ATTEMPTS):
		if pool_blobs.size() >= target:
			break
		var base: float = rng.randf_range(LAVA_RADIUS_MIN, LAVA_RADIUS_MAX)
		var blobs: Array = [[Vector2.ZERO, base]]
		var extent: float = base
		for extra: int in range(rng.randi_range(0, LAVA_BLOBS_MAX - 1)):
			var offset: Vector2 = Vector2.from_angle(rng.randf() * TAU) * base * rng.randf_range(0.15, 0.5)
			var radius: float = base * rng.randf_range(0.45, 0.7)
			blobs.append([offset, radius])
			extent = maxf(extent, offset.length() + radius)
		var room: Rect2 = ARENA_RECT.grow(-(extent + LAVA_SPACING))
		var at: Vector2 = Vector2(
			rng.randf_range(room.position.x, room.end.x),
			rng.randf_range(room.position.y, room.end.y)
		)
		if at.length() - extent < LANDING_CLEARANCE + LAVA_LANDING_MARGIN:
			continue
		if _blocked_rect(at.x, at.y, extent + LAVA_SPACING):
			continue
		var clear: bool = true
		for other: Array in accepted:
			if at.distance_to(other[0]) <= extent + (other[1] as float) + LAVA_SPACING:
				clear = false
				break
		if not clear:
			continue
		accepted.append([at, extent])
		for blob: Array in blobs:
			blob[0] = (blob[0] as Vector2) + at
		pool_blobs.append(blobs)
	lava.set_pools(pool_blobs)


## True when (x, y) lies within margin of an arena wall or a standing obstacle. Anything
## placed on the floor can ask this; a broken obstacle no longer counts.
func _blocked_rect(x: float, y: float, margin: float) -> bool:
	for child: Node in geometry.get_children():
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var size: Vector2 = (collision.shape as RectangleShape2D).size + Vector2(margin, margin) * 2.0
		if Rect2(collision.position - size * 0.5, size).has_point(Vector2(x, y)):
			return true
	for child: Node in obstacles.get_children():
		var obstacle: Breakable = child as Breakable
		if obstacle != null and obstacle.is_standing() and obstacle.footprint().grow(margin).has_point(Vector2(x, y)):
			return true
	for child: Node in chests.get_children():
		if (child as Chest).footprint().grow(margin).has_point(Vector2(x, y)):
			return true
	return false


## True when the point sits in molten lava (see LavaPools.point_in_lava). Lets hazards and
## placement, e.g. the exit portal, keep clear of the pools.
func point_in_lava(point: Vector2, inset: float = 0.0) -> bool:
	return lava.point_in_lava(point, inset)
## Shrine positions: the points of a pentagram around the landing site, the first due north.
static func shrine_spots() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for index: int in range(SHRINE_COUNT):
		spots.append(Vector2.from_angle(-PI * 0.5 + TAU * index / SHRINE_COUNT) * SHRINE_RING)
	return spots


## PLACEHOLDER obstacles, built from a fixed seed per map: Satan's shrines, the structures, then
## wall segments and trees wherever they keep open lanes and the landing site clear.
func _place_obstacles() -> void:
	for child: Node in obstacles.get_children():
		child.free()
	if sin_index != SATAN:
		for spot: Vector2 in shrine_spots():
			_add_obstacle(Breakable.Kind.SHRINE, spot, false)
	_count_shrines()
	for spot: Vector2 in STRUCTURE_SPOTS:
		_add_obstacle(Breakable.Kind.STRUCTURE, spot, false)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 88 + sin_index * 6113
	var room: Rect2 = ARENA_RECT.grow(-OBSTACLE_LANE)
	for index: int in range(WALL_COUNT + TREE_COUNT):
		var kind: Breakable.Kind = Breakable.Kind.WALL if index < WALL_COUNT else Breakable.Kind.TREE
		# shortcut: a crowded map may get fewer than the counts; fine at these densities.
		for attempt: int in range(40):
			var vertical: bool = rng.randf() < 0.5
			var size: Vector2 = Breakable.footprint_size(kind, vertical)
			var at: Vector2 = Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
			var spot: Rect2 = Rect2(at - size * 0.5, size)
			if room.encloses(spot) and not spot.grow(LANDING_CLEARANCE).has_point(Vector2.ZERO) and not _crowds_obstacle(spot):
				_add_obstacle(kind, at, vertical)
				break


## Hooks up obstacles authored in a sin map scene, exactly as _add_obstacle would.
func _adopt_obstacles() -> void:
	for child: Node in obstacles.get_children():
		var obstacle: Breakable = child as Breakable
		obstacle.hit.connect(play_sfx.bind(&"enemy_hit").unbind(1))
		obstacle.broken.connect(_on_obstacle_broken)
	_count_shrines()


func _count_shrines() -> void:
	shrines_left = 0
	for child: Node in obstacles.get_children():
		if (child as Breakable).kind == Breakable.Kind.SHRINE:
			shrines_left += 1
	shrine_total = shrines_left


func _crowds_obstacle(spot: Rect2) -> bool:
	for child: Node in obstacles.get_children():
		if spot.grow(OBSTACLE_LANE).intersects((child as Breakable).footprint()):
			return true
	return false


func _add_obstacle(kind: Breakable.Kind, at: Vector2, vertical: bool) -> Breakable:
	var obstacle: Breakable = BREAKABLE_SCENE.instantiate() as Breakable
	obstacle.kind = kind
	obstacle.vertical = vertical
	obstacle.position = at
	obstacle.hit.connect(play_sfx.bind(&"enemy_hit").unbind(1))
	obstacle.broken.connect(_on_obstacle_broken)
	obstacles.add_child(obstacle)
	return obstacle


func _on_obstacle_broken(obstacle: Breakable) -> void:
	# PLACEHOLDER AUDIO: the landing thud doubles as the break sound.
	play_sfx(&"land")
	_spawn_poof(obstacle.position)
	if obstacle.kind == Breakable.Kind.SHRINE:
		_on_shrine_destroyed(obstacle)


## The world heals around a fallen shrine; the last one summons the sin and stops the countdown.
func _on_shrine_destroyed(shrine: Breakable) -> void:
	shrines_left -= 1
	feathers_earned += FEATHERS_PER_SHRINE
	healed_spots.append(shrine.position)
	var light: Node2D = Node2D.new()
	light.name = &"HealedLight"
	light.position = shrine.position
	light.set_meta(&"light", HEAL_LIGHT)
	light.set_meta(&"light_radius", HEAL_RADIUS)
	light.add_to_group(&"light")
	add_child(light, true)
	play_sfx(&"holy_land", 0.0)
	queue_redraw()
	if shrines_left == 0:
		spawn_sin_boss()


## Authored chests are kept; a map without any gets CHEST_COUNT from its seed, on open ground
## away from the landing site and out of lava.
func _place_chests() -> void:
	if chests.get_child_count() == 0:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 404 + sin_index * 2749
		var placed: int = 0
		for attempt: int in range(200):
			if placed >= CHEST_COUNT:
				break
			var room: Rect2 = ARENA_RECT.grow(-OBSTACLE_LANE)
			var at: Vector2 = Vector2(rng.randf_range(room.position.x, room.end.x), rng.randf_range(room.position.y, room.end.y))
			if at.length() < CHEST_CLEARANCE or _blocked_rect(at.x, at.y, 40.0) or lava.point_in_lava(at, -40.0):
				continue
			var chest: Chest = Chest.new()
			chest.name = "Chest%d" % (placed + 1)
			chest.position = SideWeapons.on_grid(at)
			chests.add_child(chest)
			placed += 1
	for child: Node in chests.get_children():
		var chest: Chest = child as Chest
		chest.target = player
		chest.opened.connect(_on_chest_opened)


func _on_chest_opened(chest: Chest) -> void:
	play_sfx(&"pickup_item", 0.0)
	_spawn_poof(chest.global_position)
	spawn_pickup(Pickup.Kind.RELIC, chest.global_position + Vector2(0.0, 30.0), 0)


## A relic: a random side weapon the angel lacks or can still level; experience once all are maxed.
func grant_relic() -> void:
	var open: Array[int] = player.side_weapons.can_grow()
	if open.is_empty():
		add_xp(SPARE_RELIC_XP)
		return
	var kind: int = open.pick_random()
	player.side_weapons.add(kind)
	last_relic = [kind, player.side_weapons.levels[kind]]
	hud.announce_relic(kind)


## One guard per shrine, standing on its outer side.
func _spawn_guards() -> void:
	guards.clear()
	for child: Node in obstacles.get_children():
		var shrine: Breakable = child as Breakable
		if shrine == null or shrine.kind != Breakable.Kind.SHRINE:
			continue
		var guard: Boss = _make_boss(GUARD_HEALTH_SCALE, true)
		guard.boss_name = "%s GUARD (PLACEHOLDER)" % BOSSES[sin_index]["name"]
		guard.home = shrine.position
		guard.leash = GUARD_LEASH
		guard.position = _open_spot(shrine.position + shrine.position.normalized() * GUARD_OFFSET, guard.radius + 8.0)
		guard.died.connect(_on_guard_died)
		actors.add_child(guard)
		guards.append(guard)


func _on_guard_died(guard: Enemy) -> void:
	kills += 1
	feathers_earned += FEATHERS_PER_GUARD
	guards.erase(guard)
	play_sfx(&"boss_death", 0.0)
	_spawn_poof(guard.global_position)
	spawn_pickup(Pickup.Kind.XP, guard.global_position, guard.xp_value)
	drop_evolution(guard.global_position + Vector2(0.0, 30.0))
	spawn_pickup(Pickup.Kind.RELIC, guard.global_position + Vector2(30.0, 0.0), 0)


## Drops an evolution item for a weapon that has not evolved yet (none once both have).
func drop_evolution(at: Vector2) -> Pickup:
	var open: Array[int] = []
	for which: int in [MountedPlayer.Weapon.SPEAR, MountedPlayer.Weapon.BOW]:
		if not player.is_evolved(which):
			open.append(which)
	if open.is_empty():
		return null
	return spawn_pickup(Pickup.Kind.EVOLUTION, at, open.pick_random())


func _physics_process(delta: float) -> void:
	if ended or not has_landed:
		return
	elapsed += delta
	if shrines_left > 0:
		shrine_time_left = maxf(0.0, shrine_time_left - delta)
		if shrine_time_left == 0.0:
			# Satan's shrines outlasted the angel.
			player.kill()
			return
	if sin_index != SATAN and shrines_left == 0 and not sin_boss_defeated and current_boss == null:
		# No shrines stand (all broken, or none were authored): the sin comes.
		spawn_sin_boss()
	if sin_index == SATAN and not sin_boss_defeated and current_boss == null:
		# The ritual: calm until Satan arrives.
		ritual_left -= delta
		if ritual_left <= 0.0:
			spawn_sin_boss()
		return
	if not spawning_enabled:
		return
	spawn_left -= delta
	if spawn_left <= 0.0:
		var interval: float = spawn_interval() * SIN_SPAWN_PACE[sin_index]
		spawn_left = interval * (2.0 if current_boss != null else 1.0)
		for count: int in range(spawn_batch()):
			if enemy_count < max_enemies:
				spawn_enemy(_pick_enemy_type(), _random_offscreen_point())


func difficulty() -> float:
	return elapsed / DIFFICULTY_SECONDS


func difficulty_tier() -> int:
	return 1 + int(difficulty() / TIER_UNITS)


func spawn_interval() -> float:
	var rules: Dictionary = TIERS[tier]
	return maxf(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL * rules["spawn_interval"] / (1.0 + difficulty() * SPAWN_PRESSURE_GAIN * rules["spawn_pressure"]))


func spawn_batch() -> int:
	return mini(MAX_SPAWN_BATCH, 1 + int(difficulty() / 1.5) + int(TIERS[tier]["batch"]))


## Feathers this run is worth: everything earned times the tier's reward.
func feathers_total() -> int:
	return floori(feathers_earned * float(TIERS[tier]["feathers"]))


## Search outward from the death site, keeping the whole portal clear of walls and obstacles.
func _portal_position(at: Vector2) -> Vector2:
	return _open_spot(at, ExitPortal.RADIUS + 24.0, true)


## The nearest point to `at`, searching outward in rings, with `clearance` around it free of
## walls and standing obstacles (and of lava, for the portal; enemies may spawn in lava).
func _open_spot(at: Vector2, clearance: float, avoid_lava: bool = false) -> Vector2:
	var safe: Rect2 = ARENA_RECT.grow(-clearance)
	var origin: Vector2 = at.clamp(safe.position, safe.end)
	for ring: int in range(12):
		for step: int in range(16 if ring > 0 else 1):
			var candidate: Vector2 = origin + Vector2.from_angle(TAU * step / 16.0) * ring * 40.0
			if safe.has_point(candidate) and not _blocked_rect(candidate.x, candidate.y, clearance) and not (avoid_lava and lava.point_in_lava(candidate, -clearance)):
				return candidate
	return Vector2.ZERO # Landing site is always clear.


func xp_needed() -> int:
	return 3 + level * 4


## A weighted pick from this map's mix among the roster entries unlocked by difficulty.
func _pick_enemy_type() -> int:
	var weights: Array = SIN_ENEMY_WEIGHTS[sin_index]
	var total: float = 0.0
	for index: int in range(weights.size()):
		if difficulty() >= ENEMY_UNLOCK[index]:
			total += weights[index]
	var roll: float = randf() * total
	for index: int in range(weights.size()):
		if difficulty() >= ENEMY_UNLOCK[index] and weights[index] > 0.0:
			roll -= weights[index]
			if roll < 0.0:
				return index
	return 0


func _random_offscreen_point() -> Vector2:
	var point: Vector2 = player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(720.0, 820.0)
	# Clear of the largest horde enemy's radius, so nothing spawns inside an obstacle.
	return _open_spot(point.clamp(ARENA_RECT.position + Vector2(60.0, 60.0), ARENA_RECT.end - Vector2(60.0, 60.0)), 30.0)


func spawn_enemy(type_index: int, at: Vector2) -> Enemy:
	var data: Dictionary = ENEMY_TYPES[type_index]
	var rules: Dictionary = TIERS[tier]
	var enemy: Enemy = (data.get("scene", ENEMY_SCENE) as PackedScene).instantiate() as Enemy
	var health_scale: float = rules["health"] * (1.0 + difficulty() * HORDE_HEALTH_GAIN * rules["health_scaling"])
	enemy.max_health = maxi(1, roundi(float(data["health"]) * health_scale))
	enemy.speed = float(data["speed"]) * rules["speed"] * (1.0 + difficulty() * HORDE_SPEED_GAIN * rules["speed_scaling"])
	enemy.radius = float(data["radius"])
	enemy.xp_value = int(data["xp"])
	enemy.knockback_strength = float(data["knockback"])
	if data.has("split"):
		enemy.set_meta(&"split", data["split"])
	if enemy is Bomber:
		(enemy as Bomber).enemy_damage = maxi(1, roundi(Bomber.ENEMY_DAMAGE * health_scale))
	var damage_scale: float = rules["damage"] * (1.0 + difficulty() * HORDE_DAMAGE_GAIN * rules["damage_scaling"])
	enemy.contact_damage = roundi(float(data["damage"]) * damage_scale)
	if enemy is FlyingEnemy:
		(enemy as FlyingEnemy).shot_damage = roundi((enemy as FlyingEnemy).shot_damage * damage_scale)
	enemy.frames = data["frames"] as SpriteFrames
	enemy.position = at
	enemy.target = player
	enemy.died.connect(_on_enemy_died)
	enemy.hit.connect(_on_enemy_hit)
	enemy.damaged.connect(_on_enemy_damaged)
	actors.add_child(enemy)
	enemy_count += 1
	return enemy


## A boss from this map's sin, scaled by difficulty and tier; health_scale weakens guards.
## Guards never summon, so their extra tier patterns are real attacks.
func _make_boss(health_scale: float = 1.0, guard: bool = false) -> Boss:
	var data: Dictionary = BOSSES[sin_index]
	var rules: Dictionary = TIERS[tier]
	var growth: float = difficulty() * rules["boss_scaling"]
	var boss: Boss = BOSS_SCENE.instantiate() as Boss
	boss.boss_name = "%s (PLACEHOLDER)" % data["name"]
	boss.max_health = maxi(1, roundi(float(data["health"]) * health_scale * rules["boss_health"] * (1.0 + growth * BOSS_HEALTH_GAIN)))
	boss.speed = float(data["speed"]) * rules["boss_speed"] * (1.0 + growth * BOSS_SPEED_GAIN)
	boss.radius = float(data["radius"])
	boss.attack_interval = float(data["interval"]) / rules["attack_rate"]
	var damage_scale: float = rules["boss_damage"] * (1.0 + growth * BOSS_DAMAGE_GAIN)
	boss.contact_damage = roundi(float(data["damage"]) * damage_scale)
	boss.shot_damage = roundi(boss.shot_damage * damage_scale)
	boss.frames = data["frames"] as SpriteFrames
	boss.patterns.assign(data["patterns"])
	if guard:
		boss.patterns.erase(Boss.Pattern.SUMMON)
	# Smarter tiers add the generic patterns this sin lacks, in a fixed order.
	var extras: Array[int] = []
	var extra: int = rules["patterns"]
	# A sin with its own summon rule (smart "summon") keeps summons to that rule, and a pattern a
	# sin uses in any of its phases is never an extra (it keeps its place in the fight).
	var own_summons: bool = (data.get("smart", {}) as Dictionary).has("summon")
	var own: Array = []
	for list: Array in data.get("phase_patterns", []):
		own.append_array(list)
	for pattern: int in [Boss.Pattern.CHARGE, Boss.Pattern.AIMED, Boss.Pattern.BURST, Boss.Pattern.SUMMON]:
		if extra > 0 and not boss.patterns.has(pattern) and not own.has(pattern) and not ((guard or own_summons) and pattern == Boss.Pattern.SUMMON):
			extras.append(pattern)
			extra -= 1
	boss.patterns.append_array(extras)
	# A sin with its own phases swaps in each phase's patterns (plus the same extras), combos, and
	# speeds; guards fight with phase one only (its patterns and combos, no thresholds).
	var smart: Dictionary = data.get("smart", {})
	var combo_list: Array = data.get("phase_combos", [])
	for index: int in range(combo_list.size()):
		var combo: Dictionary = (combo_list[index] as Dictionary).duplicate(true)
		if smart.has("chain_charges") and tier >= int(smart["chain_charges"]):
			# A smarter boss follows each charge with a second, re-aimed one.
			combo[Boss.Pattern.CHARGE] = [Boss.Pattern.CHARGE] + combo.get(Boss.Pattern.CHARGE, [])
		if smart.has("double_blink") and tier >= int(smart["double_blink"]) and combo.has(Boss.Pattern.BLINK):
			# A smarter Lust blinks and charges twice in a row.
			combo[Boss.Pattern.BLINK] = combo[Boss.Pattern.BLINK] + [Boss.Pattern.BLINK] + combo[Boss.Pattern.BLINK]
		if smart.has("rain_after_yawn") and tier >= int(smart["rain_after_yawn"]) and combo.has(Boss.Pattern.YAWN):
			# A smarter Sloth rains from the air right after a yawn, before it naps.
			combo[Boss.Pattern.YAWN] = [Boss.Pattern.RAIN] + combo[Boss.Pattern.YAWN]
		if smart.has("double_leap") and tier >= int(smart["double_leap"]):
			# A smarter Gluttony leaps twice in a row.
			combo[Boss.Pattern.LEAP] = [Boss.Pattern.LEAP]
		if smart.has("extra_waves") and tier >= int(smart["extra_waves"]):
			# A smarter Greed adds a coin wave to every volley.
			combo[Boss.Pattern.COINS] = combo.get(Boss.Pattern.COINS, []) + [Boss.Pattern.COINS]
		boss.phase_combos.append(combo)
	if not boss.phase_combos.is_empty():
		boss.combos = boss.phase_combos[0]
	if guard:
		boss.phase_combos.clear()
		boss.combos.clear()
		boss.phase_thresholds.clear()
	elif data.has("phase_patterns"):
		var summons: Array = smart.get("summon", [])
		for list: Array in data["phase_patterns"]:
			var phase_list: Array[int] = []
			phase_list.assign(list)
			phase_list.append_array(extras)
			# Smarter bosses summon their realm's enemy once past their first phase.
			if not summons.is_empty() and tier >= int(summons[0]) and boss.phase_patterns.size() > 0 and not phase_list.has(Boss.Pattern.SUMMON):
				phase_list.append(Boss.Pattern.SUMMON)
			boss.phase_patterns.append(phase_list)
		boss.phase_thresholds.assign(data.get("phase_thresholds", [0.5]))
		boss.phase_speeds.assign(data.get("phase_speeds", []))
		boss.phase_paces.assign(data.get("phase_paces", []))
		boss.phase_tints.assign(data.get("phase_tints", []))
	boss.summon_type = int(data.get("summon_type", HUSK))
	if smart.has("summon"):
		boss.summon_type = int((smart["summon"] as Array)[1])
	if smart.has("lead_rain") and tier >= int(smart["lead_rain"]):
		boss.lead_rain = true
	if smart.has("long_bile") and tier >= int(smart["long_bile"]):
		boss.bile_time = 6.0
	if smart.has("long_sludge") and tier >= int(smart["long_sludge"]):
		boss.sludge_time = 7.0
	boss.slam_radius = float(data.get("slam_radius", Boss.SLAM_RADIUS))
	boss.slam_windup = float(data.get("slam_windup", Boss.WINDUPS[Boss.Pattern.SLAM]))
	boss.chained_charge_windup = float(data.get("chained_charge_windup", Boss.WINDUPS[Boss.Pattern.CHARGE]))
	boss.smarts = tier
	# A smarter boss re-aims chained charges (Pride's chain always re-aims).
	if (smart.has("reaim") and tier >= int(smart["reaim"])) or (smart.has("chain_charges") and tier >= int(smart["chain_charges"])):
		boss.reaim_chains = true
	if smart.has("air_fans") and tier >= int(smart["air_fans"]):
		boss.air_fans = true
	boss.xp_value = roundi((20 + sin_index * 5) * maxf(health_scale, 0.5))
	boss.knockback_strength = 0.0
	boss.target = player
	boss.hit.connect(_on_enemy_hit)
	boss.damaged.connect(_on_enemy_damaged)
	boss.attacked.connect(play_sfx.bind(&"boss_attack", 0.05).unbind(1))
	boss.phase_changed.connect(play_sfx.bind(&"boss_spawn", 0.0).unbind(1))
	boss.ate.connect(_on_boss_ate)
	return boss


## Summons this map's sin once every shrine has fallen (never twice, never after the run ends).
func spawn_sin_boss() -> Boss:
	if ended or current_boss != null or sin_boss_defeated:
		return null
	var boss: Boss = _make_boss()
	boss.position = _open_spot((player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * 520.0).clamp(
		ARENA_RECT.position + Vector2(120.0, 120.0), ARENA_RECT.end - Vector2(120.0, 120.0)
	), boss.radius + 8.0)
	boss.died.connect(_on_boss_died)
	# Only the sin summons; guards stay local to their shrines and off the horde cap.
	boss.summon_requested.connect(_on_boss_summon)
	boss.attacked.connect(_plan_summon)
	actors.add_child(boss)
	current_boss = boss
	play_sfx(&"boss_spawn", 0.0)
	return boss


## A summon's spots are chosen when its wind-up starts, so its marks show exactly where the
## minions will appear.
## A devoured horde enemy is simply gone: no kill, no loot, and the boss does not heal.
func _on_boss_ate(_boss: Boss, enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or enemy.health <= 0:
		return
	enemy.health = 0
	enemy.collision_shape.set_deferred(&"disabled", true)
	enemy_count -= 1
	_spawn_poof(enemy.global_position)
	enemy.queue_free()


func _plan_summon(boss: Boss) -> void:
	if boss.pending != Boss.Pattern.SUMMON:
		return
	for offset: Vector2 in boss.summon_offsets():
		boss.summon_spots.append(_open_spot(boss.global_position + offset, 20.0))


func _on_boss_summon(boss: Boss, count: int) -> void:
	var offsets: Array[Vector2] = boss.summon_offsets()
	for index: int in range(count):
		if enemy_count < max_enemies:
			var at: Vector2 = boss.summon_spots[index] if index < boss.summon_spots.size() else _open_spot(boss.global_position + offsets[index % offsets.size()], 20.0)
			spawn_enemy(boss.summon_type, at)
	boss.summon_spots.clear()


## A splitter's children spread across the line to the angel from where it fell (never onto
## the angel), within the horde cap.
func _split(rule: Dictionary, at: Vector2) -> void:
	var count: int = rule["count"]
	var side: Vector2 = (at - player.global_position).orthogonal().normalized()
	if side.is_zero_approx():
		side = Vector2.UP
	for index: int in range(count):
		if ended or enemy_count >= max_enemies:
			return
		var offset: float = (float(index) - (count - 1) * 0.5) * 48.0
		spawn_enemy(rule["type"], _open_spot(at + side * offset, 20.0))


## Sparks along the push (or away from the angel for enemies too heavy to push), and the HUD's
## damage number.
func _on_enemy_damaged(enemy: Enemy, amount: int, heavy: bool) -> void:
	if amount == 0 and enemy.blocked_last:
		# PLACEHOLDER AUDIO: a blocked blow reuses the landing thud.
		play_sfx(&"land", 0.0)
	var direction: Vector2 = enemy.knockback.normalized()
	if direction.is_zero_approx():
		direction = (enemy.global_position - player.global_position).normalized()
	sparks.add(enemy.global_position - direction * enemy.radius * 0.5, direction, heavy)
	enemy_damaged.emit(enemy.global_position - Vector2(0.0, enemy.radius), amount, heavy, enemy.get_instance_id())


func _on_enemy_hit(_enemy: Enemy) -> void:
	play_sfx(&"enemy_hit")


func _on_enemy_died(enemy: Enemy) -> void:
	enemy_count -= 1
	if ended:
		return # Nothing earned after the run is over.
	kills += 1
	feathers_earned += FEATHERS_PER_KILL
	play_sfx(&"enemy_death")
	_spawn_poof(enemy.global_position)
	spawn_pickup(Pickup.Kind.XP, enemy.global_position, enemy.xp_value)
	if enemy.has_meta(&"split"):
		# Deferred: deaths arrive inside hit callbacks and physics queries.
		_split.call_deferred(enemy.get_meta(&"split"), enemy.global_position)
	if randf() < heart_drop_chance * player.luck:
		spawn_pickup(Pickup.Kind.HEART, enemy.global_position + Vector2(12.0, 0.0), 20)
	if randf() < item_drop_chance * player.luck:
		spawn_pickup(Pickup.Kind.ITEM, enemy.global_position, randi() % ITEMS.size())
	if randf() < feather_drop_chance * player.luck:
		spawn_pickup(Pickup.Kind.FEATHER, enemy.global_position + Vector2(0.0, 12.0), FEATHER_GEM_VALUE)
	if randf() < evolution_drop_chance * player.luck:
		drop_evolution(enemy.global_position + Vector2(-12.0, 0.0))


## The sin falls: the map is won. A portal opens to leave whenever the angel chooses; until
## then the horde keeps scaling and the angel keeps growing.
func _on_boss_died(enemy: Enemy) -> void:
	kills += 1
	feathers_earned += FEATHERS_PER_SATAN if sin_index == SATAN else FEATHERS_PER_SIN
	var at: Vector2 = enemy.global_position
	current_boss = null
	sin_boss_defeated = true
	play_sfx(&"boss_death", 0.0)
	_spawn_poof(at)
	if sin_index == SATAN:
		# The last fight: the world is saved at once.
		_end_run(true)
		return
	exit_portal = PORTAL_SCENE.instantiate() as ExitPortal
	exit_portal.position = _portal_position(at)
	exit_portal.target = player
	exit_portal.confirmed.connect(_end_run.bind(true), CONNECT_DEFERRED)
	add_child(exit_portal)
	spawn_pickup(Pickup.Kind.XP, at, enemy.xp_value)
	spawn_pickup(Pickup.Kind.HEART, at + Vector2(-30.0, 20.0), 20)
	spawn_pickup(Pickup.Kind.HEART, at + Vector2(30.0, 20.0), 20)
	spawn_pickup(Pickup.Kind.ITEM, at + Vector2(0.0, -30.0), randi() % ITEMS.size())


func spawn_pickup(kind: Pickup.Kind, at: Vector2, value: int) -> Pickup:
	var pickup: Pickup = Pickup.new()
	pickup.kind = kind
	if kind == Pickup.Kind.ITEM or kind == Pickup.Kind.EVOLUTION:
		pickup.item_index = value
	else:
		pickup.value = value
	pickup.position = at
	pickup.target = player
	pickup.collected.connect(_on_pickup_collected)
	pickups.add_child(pickup)
	return pickup


func _on_pickup_collected(pickup: Pickup) -> void:
	match pickup.kind:
		Pickup.Kind.XP:
			play_sfx(&"pickup_xp", 0.15)
			add_xp(pickup.value)
		Pickup.Kind.HEART:
			play_sfx(&"pickup_life", 0.0)
			player.heal(pickup.value)
		Pickup.Kind.ITEM:
			play_sfx(&"pickup_item", 0.0)
			var item: Dictionary = ITEMS[pickup.item_index]
			items.append(item)
			_apply_bonus(item["stat"] as String, float(item["amount"]))
		Pickup.Kind.RELIC:
			play_sfx(&"pickup_item", 0.0)
			grant_relic()
		Pickup.Kind.FEATHER:
			play_sfx(&"pickup_xp", 0.1)
			feathers_earned += pickup.value
		Pickup.Kind.EVOLUTION:
			play_sfx(&"pickup_item", 0.0)
			# Once per weapon per run: a spare item is experience instead.
			if player.is_evolved(pickup.item_index):
				add_xp(SPARE_EVOLUTION_XP)
			elif not ended:
				_offer_evolution(pickup.item_index)


## Pauses for the weapon's two evolution paths; a level-up waits until it is chosen.
func _offer_evolution(which: int) -> void:
	evolution_weapon = which
	get_tree().paused = true
	play_sfx(&"level_up", 0.0)
	hud.show_evolution(which, EVOLUTIONS[which])


## Takes path index 0 or 1 for the weapon on offer, then any queued level-up.
func choose_evolution(index: int) -> void:
	if evolution_weapon < 0 or index < 0 or index >= EVOLUTIONS[evolution_weapon].size():
		return
	player.evolve(evolution_weapon, index + 1)
	evolution_weapon = -1
	hud.hide_evolution()
	if pending_level_ups > 0:
		_offer_level_up()
	else:
		get_tree().paused = false


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		pending_level_ups += 1
	if pending_level_ups > 0 and level_up_options.is_empty() and evolution_weapon < 0 and not ended:
		_offer_level_up()


func _offer_level_up() -> void:
	var pool: Array[Dictionary] = UPGRADES.duplicate()
	# Haste at its floor would do nothing.
	if player.haste <= MountedPlayer.HASTE_FLOOR + 0.001:
		pool = pool.filter(func(upgrade: Dictionary) -> bool: return upgrade["stat"] != "haste")
	pool.shuffle()
	level_up_options.assign(pool.slice(0, 3))
	get_tree().paused = true
	play_sfx(&"level_up", 0.0)
	hud.show_level_up(level_up_options)


func choose_upgrade(index: int) -> void:
	if index < 0 or index >= level_up_options.size():
		return
	var upgrade: Dictionary = level_up_options[index]
	_apply_bonus(upgrade["stat"] as String, float(upgrade["amount"]))
	pending_level_ups -= 1
	level_up_options.clear()
	if pending_level_ups > 0:
		_offer_level_up()
	else:
		hud.hide_level_up()
		get_tree().paused = false


func _apply_bonus(stat: String, amount: float) -> void:
	match stat:
		"damage":
			player.spear_damage += int(amount)
		"attack_speed":
			player.thrust_cooldown = maxf(0.1, player.thrust_cooldown * amount)
			player.thrust_duration = maxf(0.1, player.thrust_duration * amount)
		"reach":
			player.spear_reach += amount
		"speed":
			player.movement_speed += amount
		"max_health":
			player.max_health += int(amount)
			player.heal(int(amount))
		"magnet":
			player.pickup_radius += amount
		"pierce":
			player.spear_pierce += int(amount)
		"dash":
			player.dash_cooldown = maxf(0.1, player.dash_cooldown * amount)
		"bow_damage":
			player.bow_damage += int(amount)
		"bow_speed":
			player.bow_cooldown = maxf(0.05, player.bow_cooldown * amount)
			player.bow_finisher_cooldown = maxf(0.05, player.bow_finisher_cooldown * amount)
		"bow_pierce":
			player.bow_pierce += int(amount)
		"heal":
			player.heal(player.max_health)
		"might":
			player.might += amount
		"armor":
			player.armor += int(amount)
		"haste":
			player.haste = maxf(MountedPlayer.HASTE_FLOOR, player.haste * amount)
		"luck":
			player.luck += amount
		"flight":
			player.flight_time += amount
			player.flight_stamina = player.flight_time
		_:
			push_error("Unknown bonus stat: %s" % stat)


func _on_player_died() -> void:
	_end_run(false)


func _end_run(won: bool) -> void:
	if ended:
		return
	ended = true
	victory = won
	# Nothing already in flight may act on the ended run: arrows, feathers, and falling light.
	for child: Node in get_children():
		if child is Arrow or child is LightRain:
			child.queue_free()
	for child: Node in chests.get_children():
		child.set_physics_process(false)
	music.stop()
	play_sfx(&"victory" if won else &"defeat", 0.0)
	var tween: Tween = create_tween()
	if won:
		# The angel rises in a beam and the whole realm heals beneath it; the horde is gone.
		for child: Node in actors.get_children():
			child.queue_free()
		for child: Node in pickups.get_children():
			child.queue_free()
		if is_instance_valid(exit_portal):
			exit_portal.queue_free()
		hud.hide_level_up()
		hud.hide_evolution()
		evolution_weapon = -1
		pending_level_ups = 0
		level_up_options.clear()
		get_tree().paused = false
		player.begin_ascent(ASCENT_HEIGHT, ASCENT_TIME)
		tween.set_parallel()
		tween.tween_property(self, ^"heal_world", 1.0, ASCENT_TIME).set_trans(Tween.TRANS_SINE)
		# The darkness lifts from the shader's own ambient (unset until changed, so read its default).
		var lighting: ShaderMaterial = $Lighting.material
		var ambient: Variant = lighting.get_shader_parameter(&"ambient")
		if ambient == null:
			ambient = RenderingServer.shader_get_parameter_default(lighting.shader.get_rid(), &"ambient")
		if ambient is Color:
			tween.tween_method(func(value: Color) -> void: lighting.set_shader_parameter(&"ambient", value), ambient, SAVED_AMBIENT, ASCENT_TIME).set_trans(Tween.TRANS_SINE)
		return
	# The angel falls and the world dims; the end card follows.
	tween.tween_property(self, ^"modulate", FALLEN_TINT, FALL_TIME)
	tween.tween_callback(_show_ending.bind(false))


func _on_ascended() -> void:
	player.visible = false
	_show_ending(true)


func _show_ending(won: bool) -> void:
	ending_done = true
	hud.show_end(won)
	finished.emit(won)


func _draw() -> void:
	# PLACEHOLDER arena art: the corrupted plain, its static props, the landing site, and the
	# arena walls. Breakable obstacles draw themselves.
	draw_rect(ARENA_RECT.grow(400.0), Color("070109"))
	var tile: float = 32.0 * PIXEL_SCALE
	var variants: int = FLOOR_FRAMES.get_frame_count(&"tiles")
	var columns: int = int(ARENA_RECT.size.x / tile)
	var rows: int = int(ARENA_RECT.size.y / tile)
	for row: int in range(rows):
		for column: int in range(columns):
			# Mostly plain tiles, with rare marked variants.
			var roll: int = (column * 73856093 ^ row * 19349663 ^ sin_index * 83492791) & 0xffff
			var variant: int = 0 if roll % 13 != 0 else 1 + (roll / 13) % (variants - 1)
			var at: Vector2 = ARENA_RECT.position + Vector2(column, row) * tile
			draw_texture_rect(FLOOR_FRAMES.get_frame_texture(&"tiles", variant), Rect2(at, Vector2(tile, tile)), false, REALM_TINTS[sin_index])
	# PLACEHOLDER healed ground around each fallen shrine, then the whole realm once won.
	for spot: Vector2 in healed_spots:
		draw_circle(spot, HEAL_RADIUS, HEAL_COLOR)
	if heal_world > 0.0:
		draw_rect(ARENA_RECT, Color(HEAL_COLOR, HEAL_COLOR.a * heal_world))
	var landing: Texture2D = LANDING_FRAMES.get_frame_texture(&"idle", 0)
	draw_texture_rect(landing, Rect2(-landing.get_size() * PIXEL_SCALE * 0.5 + Vector2(0.0, 12.0), landing.get_size() * PIXEL_SCALE), false)
	for prop: Array in decor_props:
		var texture: Texture2D = prop[0]
		var size: Vector2 = texture.get_size() * PIXEL_SCALE
		var bounds: Rect2 = Rect2(prop[1] as Vector2 - size * 0.5, size)
		if prop[2]:
			bounds = Rect2(bounds.position + Vector2(size.x, 0.0), Vector2(-size.x, size.y))
		draw_texture_rect(texture, bounds, false)
	for child: Node in geometry.get_children():
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var size: Vector2 = (collision.shape as RectangleShape2D).size
		var bounds: Rect2 = Rect2(collision.position - size * 0.5, size)
		draw_rect(bounds, Color("1e182e"))
		draw_rect(bounds, Color("070109"), false, 4.0)
