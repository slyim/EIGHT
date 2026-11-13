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
## The shrine countdown is flagged in its last minute.
const SHRINE_WARNING_SECONDS: float = 60.0
## PLACEHOLDER markers toward standing shrines that are off the world view: diamonds on a
## ring around the angel (UI units), so they never sit on other HUD elements.
const SHRINE_MARKER_COLOR: Color = Color(0.902, 0.886, 0.6196, 0.9)
const SHRINE_MARKER_RING: float = 120.0
## The exit gets a larger mint marker on the same ring, so it reads apart from shrines.
const EXIT_MARKER_COLOR: Color = Color(0.7922, 0.9216, 0.8784, 0.95)
## Tint for anything urgent: the countdown's last minute, the exit prompt.
const ALERT_TINT: Color = Color(1.0, 0.8, 0.45, 1.0)
const ABILITY_WAIT_TINT: Color = Color(0.6, 0.6, 0.6, 1.0)
## PLACEHOLDER burn callout tint while the angel stands in lava.
const BURN_TINT: Color = Color(1.0, 0.55, 0.2, 1.0)

## The player chose to leave for the pentagram hub (only offered when a Game hosts the run).
signal hub_requested

var run: Run: set = _set_run
## Set by the pixel host: the scaled view showing the world, for placing world tags.
var world_view: SubViewportContainer
## Name tag over the active boss and the exit prompt over the portal, drawn as crisp UI.
var boss_tag: Label
var portal_tag: Label
## Draws the edge markers toward off-view shrines.
var shrine_markers: Control
## Side weapons carried (bottom left) and the announcement of a new find (center).
var side_label: Label
var relic_label: Label
var stats_refresh_left: float = 0.0
## Active weapon and its combo step, built from the flight gauge so it matches the other gauges.
var weapon_bar: ProgressBar
var weapon_label: Label
## Hidden "BURNING" callout, built in code like the weapon gauge.
var burn_label: Label

@onready var stats_label: Label = $Stats
@onready var xp_bar: ProgressBar = $XPBar
@onready var xp_label: Label = $XPBar/XPLabel
@onready var health_orb: Control = $HealthOrb
@onready var life_label: Label = $LifeLabel
@onready var stage_label: Label = $StageStatus
@onready var difficulty_label: Label = $Difficulty
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
@onready var pause_menu: Control = $PauseMenu
@onready var end_buttons: Control = $EndButtons
@onready var save_failed: Control = $SaveFailed
@onready var evolution_panel: Control = $Evolution
@onready var evolution_cards: Array[Button] = [$Evolution/Box/Paths/Path1 as Button, $Evolution/Box/Paths/Path2 as Button]


func _ready() -> void:
	for index: int in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_on_choice.bind(index))
	health_orb.draw.connect(_draw_health_orb)
	weapon_bar = flight_bar.duplicate() as ProgressBar
	weapon_bar.name = &"WeaponBar"
	flight_bar.get_parent().add_child(weapon_bar)
	weapon_label = weapon_bar.get_node(^"Label") as Label
	# PLACEHOLDER burn callout above the ability gauges; nothing else occupies that slot.
	burn_label = Label.new()
	burn_label.name = &"BurnLabel"
	burn_label.text = "BURNING"
	burn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burn_label.add_theme_font_size_override(&"font_size", 16)
	burn_label.self_modulate = BURN_TINT
	burn_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	burn_label.offset_left = -80.0
	burn_label.offset_right = 80.0
	burn_label.offset_top = -98.0
	burn_label.offset_bottom = -76.0
	burn_label.visible = false
	add_child(burn_label)
	shrine_markers = Control.new()
	shrine_markers.name = &"ShrineMarkers"
	shrine_markers.set_anchors_preset(Control.PRESET_FULL_RECT)
	shrine_markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shrine_markers.draw.connect(_draw_shrine_markers)
	add_child(shrine_markers)
	move_child(shrine_markers, 0)
	side_label = Label.new()
	side_label.name = &"SideWeapons"
	side_label.add_theme_font_size_override(&"font_size", 15)
	side_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	side_label.offset_left = 16.0
	side_label.offset_right = 300.0
	side_label.offset_top = -150.0
	side_label.offset_bottom = -40.0
	side_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	side_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(side_label)
	relic_label = Label.new()
	relic_label.name = &"RelicFound"
	relic_label.theme_type_variation = &"HeadingLabel"
	relic_label.add_theme_font_size_override(&"font_size", 22)
	relic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	relic_label.offset_left = -300.0
	relic_label.offset_right = 300.0
	relic_label.offset_top = -170.0
	relic_label.offset_bottom = -136.0
	relic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_label.visible = false
	add_child(relic_label)
	boss_tag = _world_tag(&"BossTag", &"HeadingLabel", 18)
	portal_tag = _world_tag(&"PortalTag", &"Label", 18)
	portal_tag.text = "EXIT  [HOLD E]"
	($PauseMenu/Box/Resume as Button).pressed.connect(set_paused.bind(false))
	($PauseMenu/Box/Restart as Button).pressed.connect(restart)
	($PauseMenu/Box/Hub as Button).pressed.connect(hub_requested.emit)
	($PauseMenu/Box/Settings as Button).pressed.connect(open_settings)
	for index: int in range(evolution_cards.size()):
		evolution_cards[index].pressed.connect(_on_evolution_choice.bind(index))
	evolution_panel.hide()
	($EndButtons/Retry as Button).pressed.connect(restart)
	($EndButtons/Hub as Button).pressed.connect(hub_requested.emit)
	level_up_panel.hide()
	boss_panel.hide()
	end_label.hide()
	pause_menu.hide()


func _world_tag(tag_name: StringName, variation: StringName, font_size: int) -> Label:
	var tag: Label = Label.new()
	tag.name = tag_name
	tag.theme_type_variation = variation
	tag.add_theme_font_size_override(&"font_size", font_size)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.visible = false
	add_child(tag)
	move_child(tag, 0)
	return tag


## HUD position of a world point: through the world camera, then the scaled view if hosted.
func world_to_hud(point: Vector2) -> Vector2:
	var screen: Vector2 = run.get_viewport().get_canvas_transform() * point
	if world_view != null:
		return world_view.position + screen * world_view.stretch_shrink
	return screen


## Centers a tag horizontally just above a world point; hidden while that point is outside
## the world view (so it never floats in the bars).
func _place_tag(tag: Label, point: Vector2) -> void:
	var at: Vector2 = world_to_hud(point)
	var bounds: Rect2 = world_view.get_rect() if world_view != null else Rect2(Vector2.ZERO, size)
	tag.visible = bounds.has_point(at)
	tag.size = tag.get_minimum_size()
	tag.position = (at - Vector2(tag.size.x * 0.5, tag.size.y)).round()


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
	stats_label.text = "KILLS %s    FEATHERS %s" % [compact(run.kills), compact(run.feathers_earned)]
	if run.shrine_total > 0:
		stats_label.text += "    SHRINES %d / %d" % [run.shrine_total - run.shrines_left, run.shrine_total]
	difficulty_label.text = "TIME %02d:%02d   DIFFICULTY %d" % [minutes, seconds, run.difficulty_tier()]
	stage_label.text = "REALM OF %s" % Run.BOSSES[run.sin_index]["name"]
	shrine_markers.queue_redraw()
	xp_bar.max_value = run.xp_needed()
	xp_bar.value = run.xp
	xp_label.text = "LEVEL %d    XP %d / %d" % [run.level, run.xp, run.xp_needed()]

	var player: MountedPlayer = run.player
	_update_life(player.health, player.max_health)
	_update_ability(dash_bar, dash_label, "DASH", _dash_wait(), player.dash_duration + player.dash_cooldown)
	_update_flight(player)
	_update_weapon(player)
	burn_label.visible = run.lava != null and run.lava.burning and not run.ended
	_update_side_weapons(player)
	# Once the run ends the play gauges and controls step aside for the ending.
	($Abilities as Control).visible = not run.ended
	($Controls as Control).visible = not run.ended

	items_label.visible = not run.items.is_empty()
	if items_label.visible:
		var lines: PackedStringArray = PackedStringArray(["ITEMS (%d)" % run.items.size()])
		for item: Dictionary in run.items.slice(-ITEMS_SHOWN):
			lines.append("%s  %s" % [(item["name"] as String).trim_prefix("Item: "), item["text"]])
		items_label.text = "\n".join(lines)

	var boss: Boss = run.current_boss
	boss_tag.visible = is_instance_valid(boss)
	if boss_tag.visible:
		boss_tag.text = boss.boss_name
		_place_tag(boss_tag, boss.global_position - Vector2(0.0, boss.radius + 18.0))
	portal_tag.visible = is_instance_valid(run.exit_portal)
	if portal_tag.visible:
		_place_tag(portal_tag, run.exit_portal.global_position - Vector2(0.0, ExitPortal.RADIUS + 12.0))
	boss_panel.visible = is_instance_valid(boss)
	boss_status_label.visible = not boss_panel.visible
	if boss_panel.visible:
		boss_name_label.text = "%s  %d%%" % [boss.boss_name, ceili(100.0 * boss.health / boss.max_health)]
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.health
	else:
		_update_boss_status()


func _update_boss_status() -> void:
	if run.ended:
		boss_status_label.text = ""
		return
	if is_instance_valid(run.exit_portal):
		boss_status_label.text = "%s DEFEATED - HOLD E IN PORTAL TO LEAVE\nStay to grow stronger; the horde keeps rising" % Run.BOSSES[run.sin_index]["name"]
		boss_status_label.self_modulate = ALERT_TINT
		return
	if run.sin_index == Run.SATAN:
		boss_status_label.text = "THE RITUAL IS COMPLETE\nSATAN COMES IN %d" % ceili(run.ritual_left)
		boss_status_label.self_modulate = ALERT_TINT
		return
	if run.shrines_left <= 0:
		boss_status_label.text = "THE SHRINES ARE BROKEN" if run.shrine_total > 0 else "%s APPROACHES" % Run.BOSSES[run.sin_index]["name"]
		boss_status_label.self_modulate = Color.WHITE
		return
	var left: int = ceili(run.shrine_time_left)
	boss_status_label.text = "DESTROY SATAN'S SHRINES   %d LEFT\n%d:%02d" % [run.shrines_left, left / 60, left % 60]
	boss_status_label.self_modulate = ALERT_TINT if run.shrine_time_left <= SHRINE_WARNING_SECONDS else Color.WHITE


## Where each marker sits: [tip, direction] on a ring around the angel, toward every
## standing shrine that is off the world view.
func shrine_marker_tips() -> Array[Array]:
	var tips: Array[Array] = []
	if run == null or run.ended:
		return tips
	for child: Node in run.obstacles.get_children():
		var shrine: Breakable = child as Breakable
		if shrine != null and shrine.kind == Breakable.Kind.SHRINE and shrine.is_standing():
			var tip: Array = _ring_tip(shrine.global_position)
			if not tip.is_empty():
				tips.append(tip)
	return tips


## [tip, direction] toward the open exit portal while it is off the world view, else empty.
func exit_marker_tip() -> Array:
	if run == null or run.ended or not is_instance_valid(run.exit_portal):
		return []
	return _ring_tip(run.exit_portal.global_position)


## A point on the ring around the angel toward a world point, or empty while it is in view.
func _ring_tip(point: Vector2) -> Array:
	var view: Rect2 = world_view.get_rect() if world_view != null else Rect2(Vector2.ZERO, size)
	var at: Vector2 = world_to_hud(point)
	if view.has_point(at):
		return []
	var angel: Vector2 = world_to_hud(run.player.global_position)
	var direction: Vector2 = (at - angel).normalized()
	return [angel + direction * SHRINE_MARKER_RING, direction]


func _draw_marker(tip: Array, length: float, color: Color) -> void:
	var at: Vector2 = tip[0]
	var forward: Vector2 = tip[1]
	var side: Vector2 = forward.orthogonal() * length * 0.66
	shrine_markers.draw_colored_polygon(PackedVector2Array([at + forward * length, at + side, at - forward * length * 0.66, at - side]), color)


func _draw_shrine_markers() -> void:
	for tip: Array in shrine_marker_tips():
		_draw_marker(tip, 12.0, SHRINE_MARKER_COLOR)
	var exit: Array = exit_marker_tip()
	if not exit.is_empty():
		_draw_marker(exit, 18.0, EXIT_MARKER_COLOR)


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


## The weapon's evolution path name, or "" before it evolves.
func path_name(player: MountedPlayer, which: MountedPlayer.Weapon) -> String:
	var path: int = player.spear_path if which == MountedPlayer.Weapon.SPEAR else player.bow_path
	return "" if path == 0 else String(Run.EVOLUTIONS[which][path - 1]["name"]).to_upper()


func _update_weapon(player: MountedPlayer) -> void:
	var weapon_name: String = "SPEAR" if player.weapon == MountedPlayer.Weapon.SPEAR else "BOW"
	# Path names are unique per weapon, so an evolved weapon shows just its path (it fits the gauge).
	var evolved: String = path_name(player, player.weapon)
	if evolved != "":
		weapon_name = evolved
	var step: int = player.combo_step()
	if step < 0:
		weapon_label.text = "%s  [Q]" % weapon_name
	else:
		weapon_label.text = "%s  %d / %d" % [weapon_name, step + 1, MountedPlayer.COMBO_LENGTH]
	weapon_bar.value = 1.0 if step < 0 else float(step + 1) / MountedPlayer.COMBO_LENGTH


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
	var attack_rate: float = 1.0 / maxf(player.thrust_cooldown * player.haste, player.thrust_duration)
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
		"DMG %d  ATK %.1f/s  REACH %d" % [player.dealt(player.spear_damage), attack_rate, roundi(player.spear_reach)],
		"PIERCE %d  SPEED %d  PULL %d" % [player.spear_pierce, roundi(player.movement_speed), roundi(player.pickup_radius)],
		"COMBO %d/%d  DASH %s  FLIGHT %d%%" % [
			player.combo_step() + 1,
			MountedPlayer.COMBO_LENGTH,
			"ok" if _dash_wait() <= 0.0 else "--",
			_flight_percent(player),
		],
	])
	return "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if has_node(^"SettingsPanel"):
		return # The settings panel has the keys while it is open.
	if event.is_action_pressed(&"toggle_stats"):
		get_viewport().set_input_as_handled()
		stats_panel.visible = not stats_panel.visible
		stats_refresh_left = 0.0
		return
	if event.is_action_pressed(&"reset"):
		get_viewport().set_input_as_handled()
		restart()
		return
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		set_paused(not pause_menu.visible)
		return
	var key: InputEventKey = event as InputEventKey
	if evolution_panel.visible and key != null and key.pressed and not key.echo:
		var path: int = key.physical_keycode - KEY_1
		if path >= 0 and path < evolution_cards.size():
			get_viewport().set_input_as_handled()
			_on_evolution_choice(path)
		return
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
	# One pausing panel at a time: a level-up replaces the pause menu (the tree stays paused).
	pause_menu.hide()
	# No focus grab: Space is the flight key and must not pick a choice by accident.
	level_up_panel.show()
	_pop_in(level_up_panel, 0.0)
	# The cards deal in one after another.
	for index: int in range(choice_buttons.size()):
		_pop_in(choice_buttons[index], 0.08 + index * 0.07)


## Theatrical entrance: scale up from 85% with an overshoot while fading in. Runs while the
## tree is paused and ignores hit-stop slow-motion.
func _pop_in(control: Control, delay: float) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(0.85, 0.85)
	control.modulate.a = 0.0
	var tween: Tween = control.create_tween().set_parallel().set_ignore_time_scale()
	tween.tween_property(control, ^"scale", Vector2.ONE, 0.22).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, ^"modulate:a", 1.0, 0.14).set_delay(delay)


## Opens or closes the pause menu. It never opens over a level-up choice or after the run ends,
## and closing it never unpauses a level-up.
func set_paused(open: bool) -> void:
	if open and (run.ended or level_up_panel.visible or evolution_panel.visible):
		return
	pause_menu.visible = open
	get_tree().paused = open or level_up_panel.visible or evolution_panel.visible
	if open:
		# Only a hosted run has a hub to return to.
		($PauseMenu/Box/Hub as Button).visible = world_view != null
		_pop_in(pause_menu, 0.0)


## Retry. Refused while an ending plays (the fall or the ascension), so a hosted defeat always
## banks its feathers first, and after a hosted win (its save and return to the hub must
## finish); an unhosted run (F6) may start again once its ending is over.
## The settings panel over the pause menu; closing it brings the pause menu back.
func open_settings() -> SettingsPanel:
	var panel: SettingsPanel = (load("res://scenes/settings_panel.tscn") as PackedScene).instantiate() as SettingsPanel
	panel.run = run
	pause_menu.hide()
	panel.closed.connect(func() -> void: pause_menu.visible = get_tree().paused and not level_up_panel.visible and not evolution_panel.visible)
	add_child(panel)
	return panel


func restart() -> void:
	if run != null and run.ended and (not run.ending_done or (run.victory and world_view != null)):
		return
	get_tree().paused = false
	get_tree().reload_current_scene()


## Counts above 9999 shorten to thousands ("12.3K"), so the status line always fits.
static func compact(count: int) -> String:
	return str(count) if count < 10000 else "%.1fK" % (count / 1000.0)


## Adds the banked feathers to the end card: all of them on a win, half on a defeat.
func show_feathers(kept: int, earned: int, saved: bool) -> void:
	if not saved:
		end_label.text += "\nFEATHERS COULD NOT BE SAVED"
	elif kept == earned:
		end_label.text += "\n+%d FEATHERS" % kept
	else:
		end_label.text += "\nKEPT %d OF %d FEATHERS" % [kept, earned]


## The win could not be written: say so, and offer to try again or leave knowingly unsaved.
func show_save_failed(error: Error) -> void:
	end_label.text = "%s DEFEATED\nYOUR PROGRESS COULD NOT BE SAVED (ERROR %d)" % [Run.BOSSES[run.sin_index]["name"], error]
	end_label.show()
	save_failed.show()
	for index: int in range(save_failed.get_child_count()):
		_pop_in(save_failed.get_child(index) as Control, 0.08 * index)


## The two evolution paths for a weapon, as cards that deal in; 1 / 2 or a click picks one.
func show_evolution(which: int, paths: Array) -> void:
	pause_menu.hide()
	($Evolution/Box/Heading as Label).text = "%s EVOLUTION" % ("SPEAR" if which == MountedPlayer.Weapon.SPEAR else "BOW")
	for index: int in range(evolution_cards.size()):
		var card: Button = evolution_cards[index]
		(card.get_node(^"Text/Title") as Label).text = "%d   %s" % [index + 1, String(paths[index]["name"]).to_upper()]
		(card.get_node(^"Text/Detail") as Label).text = paths[index]["text"]
	evolution_panel.show()
	_pop_in(evolution_panel, 0.0)
	for index: int in range(evolution_cards.size()):
		_pop_in(evolution_cards[index], 0.1 + index * 0.1)


func hide_evolution() -> void:
	evolution_panel.hide()


func _on_evolution_choice(index: int) -> void:
	if not evolution_panel.visible:
		return
	run.choose_evolution(index)
	_flash()


## Theatrical: a brief white flash over everything, unaffected by pause or hit-stop.
func _flash() -> void:
	var flash: ColorRect = ColorRect.new()
	flash.name = &"Flash"
	flash.color = Color(1.0, 1.0, 1.0, 0.45)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tween: Tween = flash.create_tween().set_ignore_time_scale()
	tween.tween_property(flash, ^"color:a", 0.0, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)


func _update_side_weapons(player: MountedPlayer) -> void:
	var lines: PackedStringArray = []
	for kind: int in range(player.side_weapons.levels.size()):
		if player.side_weapons.levels[kind] > 0:
			lines.append(player.side_weapons.label(kind).to_upper())
	side_label.visible = not lines.is_empty() and not run.ended
	side_label.text = "SIDE WEAPONS\n" + "\n".join(lines)


## Names a side-weapon find for a moment above the gauges.
func announce_relic(kind: int) -> void:
	var weapons: SideWeapons = run.player.side_weapons
	relic_label.text = ("NEW: %s" if weapons.levels[kind] == 1 else "UPGRADED: %s") % weapons.label(kind).to_upper()
	relic_label.show()
	_pop_in(relic_label, 0.0)
	var tween: Tween = relic_label.create_tween().set_ignore_time_scale()
	tween.tween_interval(2.0)
	tween.tween_property(relic_label, ^"modulate:a", 0.0, 0.4)
	tween.tween_callback(relic_label.hide)


func hide_level_up() -> void:
	level_up_panel.hide()


func show_end(victory: bool) -> void:
	level_up_panel.hide()
	evolution_panel.hide()
	pause_menu.hide()
	var hosted: bool = world_view != null
	if victory and run.sin_index == Run.SATAN:
		end_label.text = "SATAN DEFEATED\nTHE WORLD IS SAVED"
	elif victory:
		end_label.text = "THE REALM OF %s IS SAVED" % Run.BOSSES[run.sin_index]["name"]
	elif run.shrines_left > 0 and run.shrine_time_left <= 0.0:
		end_label.text = "THE SHRINES OUTLASTED YOU"
	else:
		end_label.text = "YOU HAVE FALLEN"
	# A hosted win returns to the hub by itself; a defeat offers Retry and the hub.
	if not hosted:
		end_label.text += "\nR to start a new run"
	end_label.show()
	_pop_in(end_label, 0.0)
	end_buttons.visible = hosted and not victory
	if end_buttons.visible:
		for index: int in range(end_buttons.get_child_count()):
			_pop_in(end_buttons.get_child(index) as Control, 0.12 + index * 0.08)


func _on_choice(index: int) -> void:
	run.choose_upgrade(index)
