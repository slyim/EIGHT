class_name Hud
extends Control
## Run HUD. Layout, colors, and wording are PLACEHOLDER UI. Keeps running while paused
## so level-up choices and restart work.

const LIFE_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_pickup_life.aseprite")

const STATS_REFRESH: float = 0.25
const ITEMS_SHOWN: int = 6
const HEART_SIZE: float = 32.0
const HEART_PITCH: float = 30.0
const EMPTY_HEART_TINT: Color = Color(0.3, 0.22, 0.34, 1.0)
const LOW_LIFE_TINT: Color = Color(1.0, 0.45, 0.42, 1.0)
const BOSS_WARNING_SECONDS: float = 10.0
const BOSS_WARNING_TINT: Color = Color(1.0, 0.8, 0.45, 1.0)
const ABILITY_WAIT_TINT: Color = Color(0.6, 0.6, 0.6, 1.0)

var run: Run
var stats_refresh_left: float = 0.0
## Active weapon and bow draw, built from the jump gauge so it matches the other gauges.
var weapon_bar: ProgressBar
var weapon_label: Label

@onready var stats_label: Label = $Stats
@onready var xp_bar: ProgressBar = $XPBar
@onready var xp_label: Label = $XPBar/XPLabel
@onready var life_hearts: Control = $LifeHearts
@onready var life_label: Label = $LifeLabel
@onready var boss_status_label: Label = $BossStatus
@onready var dash_bar: ProgressBar = $Abilities/DashBar
@onready var dash_label: Label = $Abilities/DashBar/Label
@onready var jump_bar: ProgressBar = $Abilities/JumpBar
@onready var jump_label: Label = $Abilities/JumpBar/Label
@onready var items_label: Label = $Items
@onready var boss_panel: Control = $BossPanel
@onready var boss_name_label: Label = $BossPanel/BossName
@onready var boss_bar: ProgressBar = $BossPanel/BossBar
@onready var level_up_panel: Control = $LevelUp
@onready var level_up_heading: Label = $LevelUp/Box/Heading
@onready var choice_buttons: Array[Button] = [
	$LevelUp/Box/Choice1 as Button, $LevelUp/Box/Choice2 as Button, $LevelUp/Box/Choice3 as Button,
]
@onready var choice_details: Array[Label] = [
	$LevelUp/Box/Choice1/Detail as Label, $LevelUp/Box/Choice2/Detail as Label, $LevelUp/Box/Choice3/Detail as Label,
]
@onready var end_label: Label = $EndLabel
@onready var stats_panel: Control = $StatsPanel
@onready var debug_label: Label = $StatsPanel/Stats


func _ready() -> void:
	for index: int in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_on_choice.bind(index))
	life_hearts.draw.connect(_draw_life)
	weapon_bar = jump_bar.duplicate() as ProgressBar
	weapon_bar.name = &"WeaponBar"
	jump_bar.get_parent().add_child(weapon_bar)
	weapon_label = weapon_bar.get_node(^"Label") as Label
	level_up_panel.hide()
	boss_panel.hide()
	end_label.hide()


func _process(_delta: float) -> void:
	if run == null:
		return
	stats_refresh_left -= _delta
	if stats_panel.visible and stats_refresh_left <= 0.0:
		stats_refresh_left = STATS_REFRESH
		debug_label.text = _stats_text()
	var minutes: int = int(run.elapsed) / 60
	var seconds: int = int(run.elapsed) % 60
	stats_label.text = "TIME %02d:%02d    KILLS %d    SINS %d / 7" % [minutes, seconds, run.kills, mini(run.boss_index, 7)]
	xp_bar.max_value = run.xp_needed()
	xp_bar.value = run.xp
	xp_label.text = "LEVEL %d    XP %d / %d" % [run.level, run.xp, run.xp_needed()]

	var player: MountedPlayer = run.player
	life_label.text = "LIFE %d/%d" % [player.health, player.max_health]
	life_label.self_modulate = LOW_LIFE_TINT if player.health <= 1 else Color.WHITE
	life_hearts.queue_redraw()
	_update_ability(dash_bar, dash_label, "DASH", _dash_wait(), player.dash_duration + player.dash_cooldown)
	_update_ability(jump_bar, jump_label, "JUMP", _jump_wait(), player.jump_duration + player.jump_cooldown)
	_update_weapon(player)

	items_label.visible = not run.items.is_empty()
	if items_label.visible:
		var lines: PackedStringArray = PackedStringArray(["ITEMS (%d)" % run.items.size()])
		for item: Dictionary in run.items.slice(-ITEMS_SHOWN):
			lines.append("%s  %s" % [(item["name"] as String).trim_prefix("Item: "), item["text"]])
		items_label.text = "\n".join(lines)

	var boss: Boss = run.current_boss
	boss_panel.visible = is_instance_valid(boss)
	boss_status_label.visible = not boss_panel.visible
	if boss_panel.visible:
		boss_name_label.text = "%s  %d%%" % [boss.boss_name, ceili(100.0 * boss.health / boss.max_health)]
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.health
	else:
		_update_boss_status()


func _update_boss_status() -> void:
	if run.boss_index >= Run.BOSSES.size():
		boss_status_label.text = "FINAL BOSS SLAIN"
		boss_status_label.self_modulate = Color.WHITE
		return
	boss_status_label.text = "NEXT BOSS: %s IN %ds" % [Run.BOSSES[run.boss_index]["name"], ceili(run.boss_left)]
	boss_status_label.self_modulate = BOSS_WARNING_TINT if run.boss_left <= BOSS_WARNING_SECONDS else Color.WHITE


## Seconds until a dash can start.
func _dash_wait() -> float:
	return maxf(run.player.dash_cooldown_left, run.player.dash_time_left)


## Seconds until a jump can start: the rest of any jump in progress, then its cooldown.
func _jump_wait() -> float:
	var player: MountedPlayer = run.player
	var wait: float = player.jump_cooldown_left
	if player.jump_time >= 0.0:
		wait = player.jump_duration - player.jump_time + player.jump_cooldown
	return maxf(wait, player.dash_time_left)


func _update_weapon(player: MountedPlayer) -> void:
	var charge: float = player.draw_charge()
	if player.weapon == MountedPlayer.Weapon.SPEAR:
		weapon_label.text = "SPEAR  [Q]"
		weapon_bar.value = 1.0
	elif charge < 0.0:
		weapon_label.text = "BOW  [Q]"
		weapon_bar.value = 0.0
	else:
		weapon_label.text = "BOW FULL" if charge >= 1.0 else "BOW DRAW %d%%" % roundi(charge * 100.0)
		weapon_bar.value = charge
	weapon_bar.self_modulate = Color.WHITE if charge < 0.0 or charge >= 1.0 else ABILITY_WAIT_TINT


func _update_ability(bar: ProgressBar, label: Label, ability: String, wait: float, total: float) -> void:
	var locked: bool = run.player.is_dead or run.player.is_descending()
	var usable: bool = wait <= 0.0 and not locked
	bar.value = 0.0 if locked else 1.0 - clampf(wait / total, 0.0, 1.0)
	bar.self_modulate = Color.WHITE if usable else ABILITY_WAIT_TINT
	if usable:
		label.text = "%s READY" % ability
	elif locked:
		label.text = "%s --" % ability
	else:
		label.text = "%s %.1fs" % [ability, ceilf(wait * 10.0) / 10.0]


func _draw_life() -> void:
	# PLACEHOLDER life display: one heart sprite per point of life, tighter as max life grows.
	if run == null:
		return
	var player: MountedPlayer = run.player
	var heart: Texture2D = LIFE_FRAMES.get_frame_texture(&"idle", 0)
	var pitch: float = HEART_PITCH
	if player.max_health > 1:
		pitch = minf(pitch, (life_hearts.size.x - HEART_SIZE) / (player.max_health - 1))
	for index: int in range(player.max_health):
		var bounds: Rect2 = Rect2(index * pitch, 0.0, HEART_SIZE, HEART_SIZE)
		var tint: Color = Color.WHITE if index < player.health else EMPTY_HEART_TINT
		life_hearts.draw_texture_rect(heart, bounds, false, tint)


func _stats_text() -> String:
	var player: MountedPlayer = run.player
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var frame_ms: float = 1000.0 / maxf(fps, 1.0)
	var process_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var memory_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var boss_text: String = "-"
	if is_instance_valid(run.current_boss):
		boss_text = "%s %d%%" % [
			run.current_boss.boss_name.get_slice(" ", 0),
			roundi(100.0 * run.current_boss.health / run.current_boss.max_health),
		]
	var attack_rate: float = 1.0 / maxf(player.thrust_cooldown, player.thrust_duration)
	var lines: PackedStringArray = PackedStringArray([
		"FPS %3d   FRAME %5.1f ms" % [roundi(fps), frame_ms],
		"CPU %5.1f ms  PHYS %5.1f ms" % [process_ms, physics_ms],
		"DRAWS %4d   NODES %5d" % [draw_calls, nodes],
		"MEMORY %6.1f MB" % memory_mb,
		"",
		"ENEMIES %3d / %d" % [run.enemy_count, run.max_enemies],
		"BOSS    %s" % boss_text,
		"SHOTS   %3d   DROPS %3d" % [get_tree().get_node_count_in_group(&"enemy_projectiles"), run.pickups.get_child_count()],
		"KILLS   %4d  LEVEL %2d" % [run.kills, run.level],
		"",
		"DMG %d  ATK %.1f/s  REACH %d" % [player.spear_damage, attack_rate, roundi(player.spear_reach)],
		"PIERCE %d  SPEED %d  PULL %d" % [player.spear_pierce, roundi(player.movement_speed), roundi(player.pickup_radius)],
		"COMBO %d/%d  DASH %s  JUMP %s" % [
			player.attack_step + 1 if player.combo_window_left > 0.0 or player.attack_time_left > 0.0 else 0,
			MountedPlayer.COMBO_LENGTH,
			"ok" if _dash_wait() <= 0.0 else "--",
			"ok" if _jump_wait() <= 0.0 else "--",
		],
	])
	return "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_stats"):
		get_viewport().set_input_as_handled()
		stats_panel.visible = not stats_panel.visible
		stats_refresh_left = 0.0
		return
	if event.is_action_pressed(&"reset"):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	var key: InputEventKey = event as InputEventKey
	if level_up_panel.visible and key != null and key.pressed and not key.echo:
		var index: int = key.physical_keycode - KEY_1
		if index >= 0 and index < choice_buttons.size():
			get_viewport().set_input_as_handled()
			_on_choice(index)


func show_level_up(options: Array[Dictionary]) -> void:
	for index: int in range(choice_buttons.size()):
		var option: Dictionary = options[index]
		choice_buttons[index].text = "%d   %s" % [index + 1, option["name"]]
		choice_details[index].text = option["text"]
	var more: int = run.pending_level_ups - 1
	level_up_heading.text = "LEVEL UP - CHOOSE ONE" if more <= 0 else "LEVEL UP - CHOOSE ONE (+%d MORE)" % more
	# No focus grab: Space is the jump key and must not pick a choice by accident.
	level_up_panel.show()


func hide_level_up() -> void:
	level_up_panel.hide()


func show_end(victory: bool) -> void:
	level_up_panel.hide()
	if victory:
		end_label.text = "SATAN DEFEATED - ALL EIGHT SLAIN\nR to start a new run"
	else:
		end_label.text = "YOU HAVE FALLEN\nR to start a new run"
	end_label.show()


func _on_choice(index: int) -> void:
	run.choose_upgrade(index)
