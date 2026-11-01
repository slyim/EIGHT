class_name Run
extends Node2D
## Survival run graybox: horde spawning, experience, life, items, and the boss sequence
## (seven sins, then Satan). Arena layout, sprites, audio, stats, upgrades, and items
## are PLACEHOLDER content, not final design.

const ARENA_RECT: Rect2 = Rect2(-2000.0, -2000.0, 4000.0, 4000.0)
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/boss.tscn")
const FLOOR_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_env_floor.aseprite")
const PILLAR_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_env_pillar.aseprite")
const DECOR_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_env_decor.aseprite")
const POOF_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_vfx_poof.aseprite")
const PIXEL_SCALE: float = 2.0
const LANDING_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_env_landing.aseprite")
const DECOR_COUNT: int = 460
## Decorations stay clear of the landing site in the middle of the plain.
const LANDING_CLEARANCE: float = 260.0
const DESCENT_HEIGHT: float = 420.0
const DESCENT_TIME: float = 1.6

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

## PLACEHOLDER horde types.
const ENEMY_TYPES: Array[Dictionary] = [
	{"health": 1, "speed": 105.0, "radius": 14.0, "xp": 1, "frames": preload("res://assets/art/placeholder/placeholder_enemy_husk.aseprite")},
	{"health": 1, "speed": 165.0, "radius": 10.0, "xp": 1, "frames": preload("res://assets/art/placeholder/placeholder_enemy_imp.aseprite")},
	{"health": 4, "speed": 72.0, "radius": 22.0, "xp": 4, "frames": preload("res://assets/art/placeholder/placeholder_enemy_brute.aseprite")},
]

## Fights in order; the last entry is the final boss. Stats and patterns are PLACEHOLDER.
const BOSSES: Array[Dictionary] = [
	{"name": "PRIDE", "health": 60, "speed": 95.0, "radius": 36.0, "interval": 2.4,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_pride.aseprite"), "patterns": [Boss.Pattern.AIMED, Boss.Pattern.CHARGE]},
	{"name": "GREED", "health": 90, "speed": 80.0, "radius": 38.0, "interval": 2.6,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_greed.aseprite"), "patterns": [Boss.Pattern.SUMMON, Boss.Pattern.BURST]},
	{"name": "LUST", "health": 110, "speed": 140.0, "radius": 32.0, "interval": 2.0,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_lust.aseprite"), "patterns": [Boss.Pattern.CHARGE, Boss.Pattern.AIMED]},
	{"name": "ENVY", "health": 140, "speed": 105.0, "radius": 36.0, "interval": 2.2,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_envy.aseprite"), "patterns": [Boss.Pattern.AIMED, Boss.Pattern.SUMMON]},
	{"name": "GLUTTONY", "health": 220, "speed": 60.0, "radius": 54.0, "interval": 2.6,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_gluttony.aseprite"), "patterns": [Boss.Pattern.BURST, Boss.Pattern.SUMMON]},
	{"name": "WRATH", "health": 200, "speed": 125.0, "radius": 40.0, "interval": 1.8,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_wrath.aseprite"), "patterns": [Boss.Pattern.CHARGE, Boss.Pattern.BURST]},
	{"name": "SLOTH", "health": 260, "speed": 45.0, "radius": 46.0, "interval": 2.8,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_sloth.aseprite"), "patterns": [Boss.Pattern.BURST, Boss.Pattern.SUMMON]},
	{"name": "SATAN", "health": 520, "speed": 110.0, "radius": 50.0, "interval": 1.5,
		"frames": preload("res://assets/art/placeholder/placeholder_boss_satan.aseprite"), "patterns": [Boss.Pattern.CHARGE, Boss.Pattern.BURST,
		Boss.Pattern.AIMED, Boss.Pattern.SUMMON]},
]

## Level-up choices. PLACEHOLDER names and values.
const UPGRADES: Array[Dictionary] = [
	{"name": "Sharper spear", "text": "+1 spear damage", "stat": "damage", "amount": 1.0},
	{"name": "Quicker thrusts", "text": "Thrust 12% faster", "stat": "attack_speed", "amount": 0.88},
	{"name": "Longer spear", "text": "+16 spear reach", "stat": "reach", "amount": 16.0},
	{"name": "Swifter mount", "text": "+20 movement speed", "stat": "speed", "amount": 20.0},
	{"name": "Vitality", "text": "+1 max life and heal 1", "stat": "max_health", "amount": 1.0},
	{"name": "Wider pull", "text": "+40 pickup radius", "stat": "magnet", "amount": 40.0},
	{"name": "Piercing spear", "text": "Thrust hits +1 more enemy", "stat": "pierce", "amount": 1.0},
	{"name": "Quicker dash", "text": "Dash cooldown -15%", "stat": "dash", "amount": 0.85},
]

## Collectible items found in the arena. PLACEHOLDER names and values.
const ITEMS: Array[Dictionary] = [
	{"name": "Item: Spearhead", "text": "+2 spear damage", "stat": "damage", "amount": 2.0},
	{"name": "Item: Feather", "text": "Thrust 20% faster", "stat": "attack_speed", "amount": 0.8},
	{"name": "Item: Heart vessel", "text": "+2 max life and heal 2", "stat": "max_health", "amount": 2.0},
	{"name": "Item: Lodestone", "text": "+90 pickup radius", "stat": "magnet", "amount": 90.0},
	{"name": "Item: Long haft", "text": "+28 spear reach", "stat": "reach", "amount": 28.0},
	{"name": "Item: Drill tip", "text": "Thrust hits +2 more enemies", "stat": "pierce", "amount": 2.0},
	{"name": "Item: Horseshoe", "text": "+40 movement speed", "stat": "speed", "amount": 40.0},
	{"name": "Item: Phial", "text": "Restore all life", "stat": "heal", "amount": 0.0},
]

@export var spawning_enabled: bool = true
## Open the run with the angel descending onto the plain.
@export var intro_enabled: bool = true
@export_range(5.0, 600.0, 5.0) var boss_interval: float = 60.0
@export_range(10, 1000, 10) var max_enemies: int = 220
@export_range(0.0, 1.0, 0.005) var heart_drop_chance: float = 0.03
@export_range(0.0, 1.0, 0.001) var item_drop_chance: float = 0.006

var elapsed: float = 0.0
var spawn_left: float = 1.0
var boss_left: float = 0.0
var boss_index: int = 0
var current_boss: Boss
var enemy_count: int = 0
var level: int = 1
var xp: int = 0
var kills: int = 0
var pending_level_ups: int = 0
var level_up_options: Array[Dictionary] = []
var items: Array[Dictionary] = []
var ended: bool = false
var victory: bool = false
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_next_voice: int = 0
var sfx_last_played: Dictionary[StringName, float] = {}
## Static decorations, drawn once with the floor: [texture, position, flip].
var decor_props: Array[Array] = []
var has_landed: bool = false

@onready var geometry: StaticBody2D = $Geometry
@onready var pickups: Node2D = $Pickups
@onready var actors: Node2D = $Actors
@onready var player: MountedPlayer = $MountedPlayer
@onready var hud: Hud = $HUD/Hud
@onready var effects: Node2D = $Effects
@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	boss_left = boss_interval
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
	_scatter_decor()
	if intro_enabled:
		player.begin_descent(DESCENT_HEIGHT, DESCENT_TIME)
	else:
		has_landed = true
		music.play()


func _on_player_attack(step: int) -> void:
	if step == MountedPlayer.COMBO_LENGTH - 1:
		play_sfx(&"spear_sweep", 0.05)
	else:
		play_sfx(&"spear_thrust", 0.12)


func _on_player_landed() -> void:
	if has_landed:
		play_sfx(&"land")
		_spawn_poof(player.global_position + Vector2(0.0, 12.0), PIXEL_SCALE * 0.8)
		return
	# First touchdown on the plain: the run begins.
	has_landed = true
	play_sfx(&"holy_land", 0.0)
	_spawn_poof(player.global_position + Vector2(0.0, 12.0), PIXEL_SCALE * 3.0)
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


func _spawn_poof(at: Vector2, size: float) -> void:
	var poof: AnimatedSprite2D = AnimatedSprite2D.new()
	poof.sprite_frames = POOF_FRAMES
	poof.position = at
	poof.scale = Vector2(size, size)
	poof.animation_finished.connect(poof.queue_free)
	effects.add_child(poof)
	poof.play(&"poof")


## PLACEHOLDER decoration: static, non-blocking props scattered with a fixed seed.
func _scatter_decor() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 8
	var animations: PackedStringArray = DECOR_FRAMES.get_animation_names()
	while decor_props.size() < DECOR_COUNT:
		var at: Vector2 = Vector2(
			rng.randf_range(ARENA_RECT.position.x + 48.0, ARENA_RECT.end.x - 48.0),
			rng.randf_range(ARENA_RECT.position.y + 48.0, ARENA_RECT.end.y - 48.0)
		)
		if _blocked_rect(at.x, at.y, 40.0) or at.length() < LANDING_CLEARANCE:
			continue
		var animation: StringName = StringName(animations[rng.randi() % animations.size()])
		decor_props.append([DECOR_FRAMES.get_frame_texture(animation, 0), at, rng.randf() < 0.5])
	queue_redraw()


func _blocked_rect(x: float, y: float, margin: float) -> bool:
	for child: Node in geometry.get_children():
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var size: Vector2 = (collision.shape as RectangleShape2D).size + Vector2(margin, margin) * 2.0
		if Rect2(collision.position - size * 0.5, size).has_point(Vector2(x, y)):
			return true
	return false


func _physics_process(delta: float) -> void:
	if ended or not has_landed:
		return
	elapsed += delta
	if not spawning_enabled:
		return
	spawn_left -= delta
	if spawn_left <= 0.0:
		var interval: float = maxf(0.18, 1.1 - elapsed * 0.004)
		spawn_left = interval * (2.0 if current_boss != null else 1.0)
		for count: int in range(1 + int(elapsed / 90.0)):
			if enemy_count < max_enemies:
				spawn_enemy(_pick_enemy_type(), _random_offscreen_point())
	if current_boss == null and boss_index < BOSSES.size():
		boss_left -= delta
		if boss_left <= 0.0:
			spawn_next_boss()


func xp_needed() -> int:
	return 3 + level * 4


func _pick_enemy_type() -> int:
	var roll: float = randf()
	if elapsed > 120.0 and roll < 0.15:
		return 2
	if elapsed > 45.0 and roll < 0.4:
		return 1
	return 0


func _random_offscreen_point() -> Vector2:
	var point: Vector2 = player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(720.0, 820.0)
	return point.clamp(ARENA_RECT.position + Vector2(60.0, 60.0), ARENA_RECT.end - Vector2(60.0, 60.0))


func spawn_enemy(type_index: int, at: Vector2) -> Enemy:
	var data: Dictionary = ENEMY_TYPES[type_index]
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.max_health = int(data["health"]) + int(elapsed / 120.0)
	enemy.speed = float(data["speed"])
	enemy.radius = float(data["radius"])
	enemy.xp_value = int(data["xp"])
	enemy.frames = data["frames"] as SpriteFrames
	enemy.position = at
	enemy.target = player
	enemy.died.connect(_on_enemy_died)
	enemy.hit.connect(_on_enemy_hit)
	actors.add_child(enemy)
	enemy_count += 1
	return enemy


func spawn_next_boss() -> Boss:
	var data: Dictionary = BOSSES[boss_index]
	var boss: Boss = BOSS_SCENE.instantiate() as Boss
	boss.boss_name = "%s (PLACEHOLDER)" % data["name"]
	boss.max_health = int(data["health"])
	boss.speed = float(data["speed"])
	boss.radius = float(data["radius"])
	boss.attack_interval = float(data["interval"])
	boss.frames = data["frames"] as SpriteFrames
	boss.patterns.assign(data["patterns"])
	boss.xp_value = 20 + boss_index * 5
	boss.knockback_strength = 0.0
	boss.target = player
	boss.position = (player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * 520.0).clamp(
		ARENA_RECT.position + Vector2(120.0, 120.0), ARENA_RECT.end - Vector2(120.0, 120.0)
	)
	boss.died.connect(_on_boss_died)
	boss.hit.connect(_on_enemy_hit)
	boss.summon_requested.connect(_on_boss_summon)
	boss.attacked.connect(play_sfx.bind(&"boss_attack", 0.05).unbind(1))
	actors.add_child(boss)
	current_boss = boss
	play_sfx(&"boss_spawn", 0.0)
	return boss


func _on_boss_summon(boss: Boss, count: int) -> void:
	for index: int in range(count):
		if enemy_count < max_enemies:
			spawn_enemy(0, boss.global_position + Vector2.RIGHT.rotated(TAU * index / count) * (boss.radius + 30.0))


func _on_enemy_hit(_enemy: Enemy) -> void:
	play_sfx(&"enemy_hit")


func _on_enemy_died(enemy: Enemy) -> void:
	enemy_count -= 1
	kills += 1
	play_sfx(&"enemy_death")
	_spawn_poof(enemy.global_position, PIXEL_SCALE)
	spawn_pickup(Pickup.Kind.XP, enemy.global_position, enemy.xp_value)
	if randf() < heart_drop_chance:
		spawn_pickup(Pickup.Kind.HEART, enemy.global_position + Vector2(12.0, 0.0), 1)
	if randf() < item_drop_chance:
		spawn_pickup(Pickup.Kind.ITEM, enemy.global_position, randi() % ITEMS.size())


func _on_boss_died(enemy: Enemy) -> void:
	kills += 1
	var at: Vector2 = enemy.global_position
	current_boss = null
	play_sfx(&"boss_death", 0.0)
	_spawn_poof(at, PIXEL_SCALE * 3.0)
	boss_index += 1
	boss_left = boss_interval
	if boss_index >= BOSSES.size():
		_end_run(true)
		return
	spawn_pickup(Pickup.Kind.XP, at, enemy.xp_value)
	spawn_pickup(Pickup.Kind.HEART, at + Vector2(-30.0, 20.0), 1)
	spawn_pickup(Pickup.Kind.HEART, at + Vector2(30.0, 20.0), 1)
	spawn_pickup(Pickup.Kind.ITEM, at + Vector2(0.0, -30.0), randi() % ITEMS.size())


func spawn_pickup(kind: Pickup.Kind, at: Vector2, value: int) -> Pickup:
	var pickup: Pickup = Pickup.new()
	pickup.kind = kind
	if kind == Pickup.Kind.ITEM:
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


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		pending_level_ups += 1
	if pending_level_ups > 0 and level_up_options.is_empty() and not ended:
		_offer_level_up()


func _offer_level_up() -> void:
	var pool: Array[Dictionary] = UPGRADES.duplicate()
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
		"heal":
			player.heal(player.max_health)
		_:
			push_error("Unknown bonus stat: %s" % stat)


func _on_player_died() -> void:
	_end_run(false)


func _end_run(won: bool) -> void:
	if ended:
		return
	ended = true
	victory = won
	music.stop()
	play_sfx(&"victory" if won else &"defeat", 0.0)
	hud.show_end(won)
	if won:
		get_tree().paused = true


func _draw() -> void:
	# PLACEHOLDER arena art: the corrupted plain, its static props, the landing site, and pillars.
	draw_rect(ARENA_RECT.grow(400.0), Color("070109"))
	var tile: float = 32.0 * PIXEL_SCALE
	var variants: int = FLOOR_FRAMES.get_frame_count(&"tiles")
	var columns: int = int(ARENA_RECT.size.x / tile)
	var rows: int = int(ARENA_RECT.size.y / tile)
	for row: int in range(rows):
		for column: int in range(columns):
			# Mostly plain tiles, with rare marked variants.
			var roll: int = (column * 73856093 ^ row * 19349663) & 0xffff
			var variant: int = 0 if roll % 13 != 0 else 1 + (roll / 13) % (variants - 1)
			var at: Vector2 = ARENA_RECT.position + Vector2(column, row) * tile
			draw_texture_rect(FLOOR_FRAMES.get_frame_texture(&"tiles", variant), Rect2(at, Vector2(tile, tile)), false)
	var landing: Texture2D = LANDING_FRAMES.get_frame_texture(&"idle", 0)
	draw_texture_rect(landing, Rect2(-landing.get_size() * PIXEL_SCALE * 0.5 + Vector2(0.0, 12.0), landing.get_size() * PIXEL_SCALE), false)
	for prop: Array in decor_props:
		var texture: Texture2D = prop[0]
		var size: Vector2 = texture.get_size() * PIXEL_SCALE
		var bounds: Rect2 = Rect2(prop[1] as Vector2 - size * 0.5, size)
		if prop[2]:
			bounds = Rect2(bounds.position + Vector2(size.x, 0.0), Vector2(-size.x, size.y))
		draw_texture_rect(texture, bounds, false)
	var pillar: Texture2D = PILLAR_FRAMES.get_frame_texture(&"idle", 0)
	for child: Node in geometry.get_children():
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var size: Vector2 = (collision.shape as RectangleShape2D).size
		var bounds: Rect2 = Rect2(collision.position - size * 0.5, size)
		if size.x == size.y:
			draw_texture_rect(pillar, bounds, false)
		else:
			draw_rect(bounds, Color("1e182e"))
			draw_rect(bounds, Color("070109"), false, 4.0)
