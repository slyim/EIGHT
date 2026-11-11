class_name Hud
extends Control
## Run HUD. Layout, colors, and wording are PLACEHOLDER UI. Keeps running while paused
## so level-up choices and restart work.

const STATS_REFRESH: float = 0.25
const ITEMS_SHOWN: int = 6
const ORB_EMPTY_TINT: Color = Color(0.3, 0.22, 0.34, 1.0)
const ORB_FILL_TINT: Color = Color(0.85, 0.32, 0.3, 1.0)
const ORB_OUTLINE_TINT: Color = Color(0.0275, 0.0039, 0.0353, 1.0)
## Low health is flagged below this fraction of max health.
const LOW_LIFE_FRACTION: float = 0.25
const LOW_LIFE_TINT: Color = Color(1.0, 0.45, 0.42, 1.0)
const BOSS_WARNING_SECONDS: float = 10.0
const BOSS_WARNING_TINT: Color = Color(1.0, 0.8, 0.45, 1.0)
const ABILITY_WAIT_TINT: Color = Color(0.6, 0.6, 0.6, 1.0)

var run: Run: set = _set_run
var stats_refresh_left: float = 0.0
## Active weapon and bow draw, built from the flight gauge so it matches the other gauges.
var weapon_bar: ProgressBar
var weapon_label: Label

@onready var stats_label: Label = $Stats
@onready var xp_bar: ProgressBar = $XPBar
@onready var xp_label: Label = $XPBar/XPLabel
@onready var health_orb: Control = $HealthOrb
@onready var life_label: Label = $LifeLabel
@onready var boss_status_label: Label = $BossStatus
@onready var dash_bar: ProgressBar = $Abilities/DashBar
@onready var dash_label: Label = $Abilities/DashBar/Label
@onready var flight_bar: ProgressBar = $Abilities/FlightBar
@onready var flight_label: Label = $Abilities/FlightBar/Label
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
	health_orb.draw.connect(_draw_health_orb)
	weapon_bar = flight_bar.duplicate() as ProgressBar
	weapon_bar.name = &"WeaponBar"
	flight_bar.get_parent().add_child(weapon_bar)
	weapon_label = weapon_bar.get_node(^"Label") as Label
	level_up_panel.hide()
	boss_panel.hide()
	end_label.hide()


## The run assigns itself once it is ready; hook the player's health signal then.
func _set_run(value: Run) -> void:
	run = value
	if value != null and not value.player.health_changed.is_connected(_update_life):
		value.player.health_changed.connect(_update_life)


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
	_update_life(player.health, player.max_health)
	_update_ability(dash_bar, dash_label, "DASH", _dash_wait(), player.dash_duration + player.dash_cooldown)
	_update_flight(player)
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


## Remaining flight stamina, rounded down so 100% only shows when full.
func _flight_percent(player: MountedPlayer) -> int:
	return floori(100.0 * player.flight_stamina / player.flight_time)


## The flight gauge holds the remaining stamina; it greys out below the take-off minimum.
func _update_flight(player: MountedPlayer) -> void:
	var locked: bool = player.is_dead or player.is_descending()
	flight_bar.value = 0.0 if locked else player.flight_stamina / player.flight_time
	var low: bool = player.flight_stamina < player.flight_min_stamina
	flight_bar.self_modulate = ABILITY_WAIT_TINT if locked or low else Color.WHITE
	if locked:
		flight_label.text = "FLIGHT --"
	elif player.flight_stamina >= player.flight_time:
		flight_label.text = "FLIGHT READY"
	else:
		flight_label.text = "FLIGHT %d%%" % _flight_percent(player)


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


func _update_life(current: int, maximum: int) -> void:
	life_label.text = "LIFE %d / %d" % [current, maximum]
	life_label.self_modulate = LOW_LIFE_TINT if current <= roundi(LOW_LIFE_FRACTION * maximum) else Color.WHITE
	health_orb.queue_redraw()


func _draw_health_orb() -> void:
	# PLACEHOLDER life display: an orb filled from the bottom up in proportion to health.
	if run == null:
		return
	var center: Vector2 = health_orb.size * 0.5
	var radius: float = minf(health_orb.size.x, health_orb.size.y) * 0.5 - 2.0
	_draw_orb_shape(health_orb, center, radius)
	_draw_orb_fill(health_orb, center, radius, orb_fill_fraction())


## The orb's container shape: empty interior and outline. Kept apart from the fill so the
## circle can later be swapped for a heart without touching the fill logic.
func _draw_orb_shape(canvas: Control, center: Vector2, radius: float) -> void:
	canvas.draw_circle(center, radius, ORB_EMPTY_TINT)
	canvas.draw_arc(center, radius, 0.0, TAU, 40, ORB_OUTLINE_TINT, 3.0, true)


## Fills the circular segment below the health fraction's chord, rising from the bottom.
func _draw_orb_fill(canvas: Control, center: Vector2, radius: float, fraction: float) -> void:
	if fraction <= 0.0:
		return
	# Chord position: at fraction f the fill surface sits at sin(1 - 2f) * radius from the
	# center, and every angle in [start, PI - start] lies below that chord.
	var start: float = asin(clampf(1.0 - 2.0 * fraction, -1.0, 1.0))
	var points: PackedVector2Array = []
	for step: int in range(25):
		var angle: float = lerpf(start, PI - start, step / 24.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	canvas.draw_colored_polygon(points, ORB_FILL_TINT)


func orb_fill_fraction() -> float:
	if run == null:
		return 0.0
	return clampf(float(run.player.health) / float(run.player.max_health), 0.0, 1.0)


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
		"COMBO %d/%d  DASH %s  FLIGHT %d%%" % [
			player.attack_step + 1 if player.combo_window_left > 0.0 or player.attack_time_left > 0.0 else 0,
			MountedPlayer.COMBO_LENGTH,
			"ok" if _dash_wait() <= 0.0 else "--",
			_flight_percent(player),
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
	# No focus grab: Space is the flight key and must not pick a choice by accident.
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
