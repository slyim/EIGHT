class_name Hud
extends Control
## Run HUD. Layout, colors, and wording are PLACEHOLDER UI. Keeps running while paused
## so level-up choices and restart work.

const LIFE_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_pickup_life.aseprite")

const STATS_REFRESH: float = 0.25

var run: Run
var stats_refresh_left: float = 0.0

@onready var stats_label: Label = $Stats
@onready var xp_bar: ProgressBar = $XPBar
@onready var items_label: Label = $Items
@onready var boss_panel: Control = $BossPanel
@onready var boss_name_label: Label = $BossPanel/BossName
@onready var boss_bar: ProgressBar = $BossPanel/BossBar
@onready var level_up_panel: Control = $LevelUp
@onready var choice_buttons: Array[Button] = [
	$LevelUp/Box/Choice1 as Button, $LevelUp/Box/Choice2 as Button, $LevelUp/Box/Choice3 as Button,
]
@onready var end_label: Label = $EndLabel
@onready var stats_panel: Control = $StatsPanel
@onready var debug_label: Label = $StatsPanel/Stats


func _ready() -> void:
	for index: int in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_on_choice.bind(index))
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
	var boss_text: String = "FINAL BOSS SLAIN"
	if run.boss_index < Run.BOSSES.size():
		boss_text = "BOSS ACTIVE" if run.current_boss != null else "NEXT BOSS IN %ds" % ceili(run.boss_left)
	stats_label.text = "LEVEL %d    TIME %02d:%02d    KILLS %d    SINS SLAIN %d / 7\n%s" % [
		run.level, minutes, seconds, run.kills, mini(run.boss_index, 7), boss_text,
	]
	xp_bar.max_value = run.xp_needed()
	xp_bar.value = run.xp

	var lines: PackedStringArray = PackedStringArray(["ITEMS (%d)" % run.items.size()])
	for item: Dictionary in run.items.slice(-8):
		lines.append("%s  %s" % [item["name"], item["text"]])
	items_label.text = "\n".join(lines)

	var boss: Boss = run.current_boss
	boss_panel.visible = is_instance_valid(boss)
	if boss_panel.visible:
		boss_name_label.text = boss.boss_name
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.health
	queue_redraw()


func _draw() -> void:
	# PLACEHOLDER life display: one heart sprite per point of life.
	if run == null:
		return
	var player: MountedPlayer = run.player
	var heart: Texture2D = LIFE_FRAMES.get_frame_texture(&"idle", 0)
	for index: int in range(player.max_health):
		var bounds: Rect2 = Rect2(20.0 + index * 30.0, 82.0, 32.0, 32.0)
		var tint: Color = Color.WHITE if index < player.health else Color(0.22, 0.16, 0.26, 1.0)
		draw_texture_rect(heart, bounds, false, tint)


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
			"ok" if player.dash_cooldown_left <= 0.0 else "--",
			"ok" if player.jump_time < 0.0 and player.jump_cooldown_left <= 0.0 else "--",
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
		choice_buttons[index].text = "%d.  %s\n%s" % [index + 1, option["name"], option["text"]]
	# No focus grab: Space is also the attack key and must not pick a choice by accident.
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
