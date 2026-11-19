class_name Hud
extends Control
## Run HUD. Layout, colors, and wording are PLACEHOLDER UI. Keeps running while paused
## so level-up choices and restart work.

const STATS_REFRESH: float = 0.25
const ITEMS_SHOWN: int = 6
const ORB_EMPTY_TINT: Color = Color("14081a")
const ORB_FILL_TINT: Color = Color("c4615c")
const ORB_OUTLINE_TINT: Color = Color(0.0275, 0.0039, 0.0353, 1.0)
## The heart's gold rim, its deep blood at the bottom, and its beat (beats per second; swell).
const HEART_RIM: Color = Color(0.863, 0.804, 0.576, 1.0)
const HEART_DEEP: Color = Color("6b2c40")
## Recent damage drains out of the heart as a pale trail after this pause (seconds).
const HEART_TRAIL: Color = Color(0.863, 0.804, 0.576, 0.85)
const HEART_TRAIL_HOLD: float = 0.45
## Liquid gauge colours (top of the liquid, bottom of the liquid).
const XP_LIQUID: Array[Color] = [Color("729aa1"), Color("2e3850")]
const BOSS_LIQUID: Array[Color] = [Color("c4615c"), Color("6b2c40")]
const HEART_RATE: float = 1.1
const HEART_LOW_RATE: float = 2.2
const HEART_SWELL: float = 0.07
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
## PLACEHOLDER slowed callout tint (the same slot as BURNING; burning wins).
const SLOW_TINT: Color = Color(0.6, 0.7, 0.95, 1.0)
## PLACEHOLDER crimson screen-edge vignette for low health and hurt flashes.
const VIGNETTE_COLOR: Color = Color(0.85, 0.14, 0.18, 1.0)
const VIGNETTE_WIDTH: float = 56.0
const VIGNETTE_BANDS: int = 4
const VIGNETTE_PULSE_HZ: float = 0.8
const HURT_FLASH_TIME: float = 0.15
## PLACEHOLDER "PERFECT" dodge callout above the angel.
const PERFECT_TIME: float = 0.6
const PERFECT_OFFSET: float = 34.0
const PERFECT_RISE: float = 16.0

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
## The announcement's one pop-in, hold, and fade; a newer announcement replaces it whole.
var announce_tween: Tween
var stats_refresh_left: float = 0.0
## F1 shows the controls line; hidden by default so the screen stays the game's.
var help_shown: bool = false
## Shown liquid levels ease toward the real values; slosh (0..1) swells the wave after a change.
var heart_shown: float = -1.0
var heart_trail: float = 1.0
var heart_trail_hold: float = 0.0
var heart_slosh: float = 0.0
var xp_shown: float = 0.0
var xp_slosh: float = 0.0
var boss_shown: float = 1.0
var boss_slosh: float = 0.0
## Dims the world behind the level-up, evolution, and pause choices.
var scrim: ColorRect
## Active weapon and its combo step, built from the flight gauge so it matches the other gauges.
var weapon_bar: ProgressBar
var weapon_label: Label
## Hidden "BURNING" callout, built in code like the weapon gauge.
var burn_label: Label
## Settings: floating damage numbers on or off.
var damage_numbers_enabled: bool = true:
	set(value):
		damage_numbers_enabled = value
		if not value and damage_numbers != null:
			damage_numbers.clear()
var damage_numbers: DamageNumbers
## Crimson screen-edge vignette for low health and hurt flashes, over the world view.
var vignette: Control
var hurt_flash_left: float = 0.0
var vignette_pulse: float = 0.0
## Short gold "PERFECT" callout near the angel on a perfect dodge.
var perfect_label: Label
var perfect_left: float = 0.0

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
	UiMotion.watch(self)
	for index: int in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_on_choice.bind(index))
	health_orb.draw.connect(_draw_health_orb)
	scrim = ColorRect.new()
	scrim.name = &"Scrim"
	scrim.color = Color(0.0275, 0.0039, 0.0353, 0.62)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.visible = false
	add_child(scrim)
	move_child(scrim, level_up_panel.get_index())
	xp_bar.draw.connect(func() -> void: Liquid.draw_bar(xp_bar, Rect2(Vector2.ZERO, xp_bar.size).grow(-2.5), xp_shown, XP_LIQUID[0], XP_LIQUID[1], _now(), xp_slosh))
	boss_bar.draw.connect(func() -> void: Liquid.draw_bar(boss_bar, Rect2(Vector2.ZERO, boss_bar.size).grow(-2.5), boss_shown, BOSS_LIQUID[0], BOSS_LIQUID[1], _now(), boss_slosh))
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
	vignette = Control.new()
	vignette.name = &"Vignette"
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.visible = false
	vignette.draw.connect(_draw_vignette)
	add_child(vignette)
	move_child(vignette, 0)
	damage_numbers = DamageNumbers.new()
	damage_numbers.name = &"DamageNumbers"
	damage_numbers.hud = self
	damage_numbers.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_numbers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_numbers)
	move_child(damage_numbers, 0)
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
	relic_label.offset_left = -360.0
	relic_label.offset_right = 360.0
	relic_label.offset_top = -170.0
	relic_label.offset_bottom = -136.0
	relic_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	relic_label.visible = false
	add_child(relic_label)
	boss_tag = _world_tag(&"BossTag", &"HeadingLabel", 18)
	portal_tag = _world_tag(&"PortalTag", &"Label", 18)
	portal_tag.text = "EXIT  [HOLD E]"
	perfect_label = _world_tag(&"PerfectLabel", &"HeadingLabel", 20)
	perfect_label.text = "PERFECT"
	if run != null and not run.enemy_damaged.is_connected(damage_numbers.record):
		run.enemy_damaged.connect(damage_numbers.record)
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


## The run assigns itself once it is ready; hook the player's and run's combat signals then.
func _set_run(value: Run) -> void:
	run = value
	if value == null:
		return
	if not value.player.health_changed.is_connected(_update_life):
		value.player.health_changed.connect(_update_life)
	if not value.player.hurt.is_connected(_on_player_hurt):
		value.player.hurt.connect(_on_player_hurt)
	if not value.player.perfect_dodged.is_connected(_on_perfect_dodged):
		value.player.perfect_dodged.connect(_on_perfect_dodged)
	if damage_numbers != null and not value.enemy_damaged.is_connected(damage_numbers.record):
		value.enemy_damaged.connect(damage_numbers.record)


func _process(_delta: float) -> void:
	if run == null:
		return
	stats_refresh_left -= _delta
	if stats_panel.visible and stats_refresh_left <= 0.0:
		stats_refresh_left = STATS_REFRESH
		debug_label.text = _stats_text()
	var minutes: int = int(run.elapsed) / 60
	var seconds: int = int(run.elapsed) % 60
	stats_label.text = tr("KILLS %s    FEATHERS %s") % [compact(run.kills), compact(run.feathers_total())]
	if run.shrine_total > 0:
		stats_label.text += "    " + tr("SHRINES %d / %d") % [run.shrine_total - run.shrines_left, run.shrine_total]
	difficulty_label.text = tr("TIME %02d:%02d   %s   THREAT %d") % [minutes, seconds, tr(Run.TIERS[run.tier]["name"]), run.difficulty_tier()]
	stage_label.text = tr("REALM OF %s") % tr(Run.BOSSES[run.sin_index]["name"])
	if run.scorched:
		stage_label.text += "   " + tr("SCORCHED EARTH")
	if run.surge_left > 0.0 and not run.ended:
		stage_label.text += "   " + tr("HORDE SURGE %d") % ceili(run.surge_left)
	shrine_markers.queue_redraw()
	xp_bar.max_value = run.xp_needed()
	xp_bar.value = run.xp
	_update_liquids(_delta)
	var modal: bool = level_up_panel.visible or evolution_panel.visible or pause_menu.visible
	if modal and not scrim.visible:
		scrim.visible = true
		scrim.modulate.a = 0.0
		scrim.create_tween().set_ignore_time_scale().tween_property(scrim, ^"modulate:a", 1.0, 0.15)
	elif not modal:
		scrim.visible = false
	xp_label.text = tr("LEVEL %d    XP %d / %d") % [run.level, run.xp, run.xp_needed()]

	var player: MountedPlayer = run.player
	# Hits, edges, and callouts belong to the live world; a paused screen shows none of them.
	damage_numbers.visible = not get_tree().paused
	hurt_flash_left = maxf(0.0, hurt_flash_left - _delta)
	vignette_pulse += _delta
	_update_life(player.health, player.max_health)
	if perfect_left > 0.0:
		perfect_left = maxf(0.0, perfect_left - _delta)
		_place_perfect()
	elif perfect_label.visible:
		perfect_label.visible = false
	_update_ability(dash_bar, dash_label, tr("DASH"), _dash_wait(), player.dash_duration + player.dash_cooldown)
	_update_flight(player)
	_update_weapon(player)
	var burning: bool = run.lava != null and run.lava.burning
	burn_label.visible = not run.ended and (burning or run.player.slow_left > 0.0 or run.healing_time > 0.0)
	burn_label.text = tr("BURNING") if burning else tr("SLOWED")
	burn_label.self_modulate = BURN_TINT if burning else SLOW_TINT
	if not burning and player.slow_left <= 0.0 and run.healing_time > 0.0:
		burn_label.text = tr("HEAL IN %d") % ceili(Run.SHRINE_HEAL_TIME - run.healing_time)
		burn_label.self_modulate = Color("bee5cf")
	_update_side_weapons(player)
	# Once the run ends the play gauges and the F1 controls step aside for the ending.
	($Abilities as Control).visible = not run.ended
	($Controls as Control).visible = help_shown and not run.ended

	items_label.visible = not run.items.is_empty()
	if items_label.visible:
		var lines: PackedStringArray = PackedStringArray([tr("ITEMS (%d)") % run.items.size()])
		for item: Dictionary in run.items.slice(-ITEMS_SHOWN):
			lines.append("%s  %s" % [tr((item["name"] as String).trim_prefix("Item: ")), tr(item["text"])])
		items_label.text = "\n".join(lines)

	var boss: Boss = run.current_boss
	boss_tag.visible = is_instance_valid(boss)
	if boss_tag.visible:
		boss_tag.text = boss.display_name()
		_place_tag(boss_tag, boss.global_position - Vector2(0.0, boss.radius + 18.0))
	portal_tag.visible = is_instance_valid(run.exit_portal)
	if portal_tag.visible:
		_place_tag(portal_tag, run.exit_portal.global_position - Vector2(0.0, ExitPortal.RADIUS + 12.0))
	boss_panel.visible = is_instance_valid(boss)
	boss_status_label.visible = not boss_panel.visible
	if boss_panel.visible:
		var health: int = run.satan_health() if run.sin_index == Run.SATAN else boss.health
		var maximum: int = run.satan_max_health if run.sin_index == Run.SATAN else boss.max_health
		boss_name_label.text = "%s  %d%%" % [boss.display_name(), ceili(100.0 * health / maximum)]
		boss_bar.max_value = maximum
		boss_bar.value = health
		var boss_target: float = clampf(float(health) / maximum, 0.0, 1.0)
		if absf(boss_target - boss_shown) > 0.001:
			boss_slosh = 1.0
		boss_shown = Liquid.approach(boss_shown, boss_target, _delta, 10.0)
		boss_slosh = maxf(0.0, boss_slosh - _delta * 1.5)
		boss_bar.queue_redraw()
	else:
		_update_boss_status()


func _update_boss_status() -> void:
	if run.ended:
		boss_status_label.text = ""
		return
	if is_instance_valid(run.exit_portal):
		boss_status_label.text = tr("%s DEFEATED - HOLD E IN PORTAL TO LEAVE\nStay to grow stronger; the horde keeps rising") % tr(Run.BOSSES[run.sin_index]["name"])
		boss_status_label.self_modulate = ALERT_TINT
		return
	if run.sin_index == Run.SATAN:
		boss_status_label.text = tr("THE RITUAL IS COMPLETE\nSATAN COMES IN %d") % ceili(run.ritual_left)
		boss_status_label.self_modulate = ALERT_TINT
		return
	if run.shrines_left <= 0:
		boss_status_label.text = tr("THE SHRINES ARE BROKEN") if run.shrine_total > 0 else tr("%s APPROACHES") % tr(Run.BOSSES[run.sin_index]["name"])
		boss_status_label.self_modulate = Color.WHITE
		return
	var left: int = ceili(run.shrine_time_left)
	boss_status_label.text = tr("DESTROY SATAN'S SHRINES   %d LEFT\n%d:%02d") % [run.shrines_left, left / 60, left % 60]
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
		flight_label.text = tr("FLIGHT --")
	elif player.flight_stamina >= player.flight_time:
		flight_label.text = tr("FLIGHT READY")
	else:
		flight_label.text = tr("FLIGHT %d%%") % _flight_percent(player)


## The weapon's evolution path name in the current language, or "" before it evolves.
func path_name(player: MountedPlayer, which: MountedPlayer.Weapon) -> String:
	var path: int = player.spear_path if which == MountedPlayer.Weapon.SPEAR else player.bow_path
	return "" if path == 0 else tr(String(Run.EVOLUTIONS[which][path - 1]["name"]).to_upper())


func _update_weapon(player: MountedPlayer) -> void:
	var weapon_name: String = tr("SPEAR") if player.weapon == MountedPlayer.Weapon.SPEAR else tr("BOW")
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
		label.text = tr("%s READY") % ability
	elif locked:
		label.text = "%s --" % ability
	else:
		label.text = tr("%s %.1fs") % [ability, ceilf(wait * 10.0) / 10.0]


func _update_life(current: int, maximum: int) -> void:
	life_label.text = tr("LIFE %d / %d") % [current, maximum]
	var low_life: bool = not run.ended and not run.player.is_dead and current > 0 and current <= roundi(LOW_LIFE_FRACTION * maximum)
	life_label.self_modulate = LOW_LIFE_TINT if current <= roundi(LOW_LIFE_FRACTION * maximum) else Color.WHITE
	if vignette != null:
		vignette.visible = not run.ended and not get_tree().paused and (low_life or hurt_flash_left > 0.0)
		if vignette.visible:
			vignette.queue_redraw()
	health_orb.queue_redraw()


func _is_low_life() -> bool:
	if run == null or run.ended or run.player.is_dead or run.player.health <= 0:
		return false
	return run.player.health <= roundi(LOW_LIFE_FRACTION * run.player.max_health)


func _on_player_hurt() -> void:
	if run == null or run.ended:
		return
	hurt_flash_left = HURT_FLASH_TIME
	if vignette != null:
		vignette.visible = true
		vignette.queue_redraw()


func _draw_vignette() -> void:
	if run == null or run.ended:
		return
	var low_alpha: float = (0.18 + 0.1 * (0.5 + 0.5 * sin(vignette_pulse * TAU * VIGNETTE_PULSE_HZ))) if _is_low_life() else 0.0
	var flash_alpha: float = 0.42 * clampf(hurt_flash_left / HURT_FLASH_TIME, 0.0, 1.0)
	var strength: float = maxf(low_alpha, flash_alpha)
	if strength <= 0.0:
		return
	var rect: Rect2 = world_view.get_rect() if world_view != null else Rect2(Vector2.ZERO, size)
	var step_w: float = VIGNETTE_WIDTH / VIGNETTE_BANDS
	for band: int in range(VIGNETTE_BANDS):
		var weight: float = float(VIGNETTE_BANDS - band) / float(VIGNETTE_BANDS)
		var color: Color = VIGNETTE_COLOR
		color.a = strength * weight * weight
		var r: Rect2 = rect.grow(-band * step_w)
		vignette.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, step_w), color)
		vignette.draw_rect(Rect2(r.position.x, r.end.y - step_w, r.size.x, step_w), color)
		vignette.draw_rect(Rect2(r.position.x, r.position.y + step_w, step_w, r.size.y - 2.0 * step_w), color)
		vignette.draw_rect(Rect2(r.end.x - step_w, r.position.y + step_w, step_w, r.size.y - 2.0 * step_w), color)


func _on_perfect_dodged() -> void:
	if run == null or run.ended or perfect_label == null:
		return
	perfect_left = PERFECT_TIME
	_place_perfect()
	perfect_label.pivot_offset = perfect_label.size * 0.5
	perfect_label.scale = Vector2(0.85, 0.85)
	perfect_label.modulate = Color(1.15, 1.1, 0.85, 1.0)
	var tween: Tween = perfect_label.create_tween().set_ignore_time_scale()
	tween.tween_property(perfect_label, ^"scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _place_perfect() -> void:
	if perfect_left <= 0.0 or run == null or run.ended or get_tree().paused:
		perfect_label.visible = false
		return
	var progress: float = 1.0 - clampf(perfect_left / PERFECT_TIME, 0.0, 1.0)
	var anchor: Vector2 = run.player.global_position - Vector2(0.0, PERFECT_OFFSET + run.player.height)
	_place_tag(perfect_label, anchor)
	perfect_label.position.y = roundf(perfect_label.position.y - PERFECT_RISE * progress)
	perfect_label.modulate.a = clampf(perfect_left / (PERFECT_TIME * 0.45), 0.0, 1.0)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Eases the shown liquid levels: damage drops the heart at once and leaves a pale trail that
## drains after a beat; healing and experience pour in; every change sloshes the surface.
func _update_liquids(delta: float) -> void:
	var life: float = orb_fill_fraction()
	if heart_shown < 0.0:
		heart_shown = life
		heart_trail = life
	if life < heart_shown - 0.0001:
		heart_trail = maxf(heart_trail, heart_shown)
		heart_shown = life
		heart_trail_hold = HEART_TRAIL_HOLD
		heart_slosh = 1.0
	elif life > heart_shown + 0.0001:
		heart_shown = Liquid.approach(heart_shown, life, delta, 6.0)
		heart_slosh = maxf(heart_slosh, 0.5)
	heart_trail_hold -= delta
	if heart_trail_hold <= 0.0:
		heart_trail = Liquid.approach(heart_trail, heart_shown, delta, 5.0)
	heart_trail = maxf(heart_trail, heart_shown)
	heart_slosh = maxf(0.0, heart_slosh - delta * 1.2)
	var xp: float = clampf(float(run.xp) / maxf(1.0, float(run.xp_needed())), 0.0, 1.0)
	if xp < xp_shown - 0.01:
		xp_shown = 0.0 # A level-up empties the gauge; it refills from the bottom.
	if xp > xp_shown + 0.001:
		xp_slosh = 1.0
	xp_shown = Liquid.approach(xp_shown, xp, delta)
	xp_slosh = maxf(0.0, xp_slosh - delta * 1.5)
	xp_bar.queue_redraw()


func _draw_health_orb() -> void:
	# Life as a beating vector heart of liquid, set in a chamfered medallion.
	if run == null:
		return
	var now: float = _now()
	var size: Vector2 = health_orb.size
	var socket: PackedVector2Array = OrnateBox.plate(Rect2(Vector2.ZERO, size).grow(-3.0), size.x * 0.28)
	var socket_closed: PackedVector2Array = socket.duplicate()
	socket_closed.append(socket[0])
	health_orb.draw_colored_polygon(socket, Color("14081a"))
	health_orb.draw_polyline(socket_closed, Color("070109"), 4.0, true)
	health_orb.draw_polyline(socket_closed, Color("b7836b"), 2.0, true)
	# Lub-dub: two quick swells per beat, twice as fast at low life.
	var phase: float = fposmod(now * (HEART_LOW_RATE if _is_low_life() else HEART_RATE), 1.0)
	var beat: float = maxf(_swell(phase, 0.0), 0.6 * _swell(phase, 0.2))
	var heart: PackedVector2Array = heart_points(size * 0.5 + Vector2(0.0, 1.0), minf(size.x, size.y) * 0.36 * (1.0 + HEART_SWELL * beat))
	_draw_orb_shape(health_orb, heart)
	_draw_orb_fill(health_orb, heart, maxf(heart_shown, 0.0), now)
	var closed: PackedVector2Array = heart.duplicate()
	closed.append(heart[0])
	var rim: Color = HEART_RIM.lerp(Color.WHITE, clampf(hurt_flash_left / HURT_FLASH_TIME, 0.0, 1.0))
	health_orb.draw_polyline(closed, ORB_OUTLINE_TINT, 4.5, true)
	health_orb.draw_polyline(closed, Color("b7836b"), 2.2, true)
	# A bright edge along the top of both lobes.
	health_orb.draw_polyline(heart.slice(40, 48) + heart.slice(0, 9), rim, 1.0, true)


## A heart outline (the classic parametric curve) fitted to a half-width around center.
static func heart_points(center: Vector2, half: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	var unit: float = half / 16.0
	for step: int in range(48):
		var t: float = TAU * step / 48.0
		var x: float = 16.0 * pow(sin(t), 3.0)
		var y: float = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(center + Vector2(x, y - 2.5) * unit)
	return points


static func _swell(phase: float, at: float) -> float:
	return exp(-pow((phase - at) / 0.07, 2.0))


## The heart's empty chamber and its drop shadow.
func _draw_orb_shape(canvas: Control, heart: PackedVector2Array) -> void:
	var shadow: PackedVector2Array = []
	for point: Vector2 in heart:
		shadow.append(point + Vector2(0.0, 2.0))
	canvas.draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.5))
	canvas.draw_colored_polygon(heart, ORB_EMPTY_TINT)


## Fills the heart by area: first the pale trail of recent damage, then the blood, whose
## surface waves (more right after a change) under a thin cream meniscus.
func _draw_orb_fill(canvas: Control, heart: PackedVector2Array, fraction: float, now: float) -> void:
	if fraction <= 0.0 and heart_trail <= 0.0:
		return
	var bounds: Rect2 = Rect2(heart[0], Vector2.ZERO)
	for point: Vector2 in heart:
		bounds = bounds.expand(point)
	if heart_trail > fraction + 0.002:
		Liquid.draw_pool(canvas, heart, bounds, fill_level(heart, bounds, heart_trail), HEART_TRAIL, HEART_TRAIL, now, 0.0, false)
	if fraction <= 0.0:
		return
	var level: float = fill_level(heart, bounds, fraction)
	var top: Color = ORB_FILL_TINT.lerp(Color("97576c"), 0.5 + 0.5 * sin(now * TAU * HEART_LOW_RATE)) if _is_low_life() else ORB_FILL_TINT
	Liquid.draw_pool(canvas, heart, bounds, level, top, HEART_DEEP, now, heart_slosh, fraction < 1.0)
	if fraction < 1.0:
		var crossing: PackedFloat32Array = _crossings(heart, level)
		if crossing.size() >= 2:
			canvas.draw_line(Vector2(crossing[0] + 1.0, level), Vector2(crossing[crossing.size() - 1] - 1.0, level), Color(0.902, 0.886, 0.62, 0.7), 1.2, true)
	# A thin glint on the left lobe, like light on glass, once the blood reaches it.
	var lobe: Vector2 = bounds.position + bounds.size * Vector2(0.28, 0.26)
	if level < lobe.y + 2.0:
		canvas.draw_arc(lobe, bounds.size.x * 0.14, deg_to_rad(195.0), deg_to_rad(255.0), 8, Color(0.792, 0.922, 0.878, 0.45), 1.5, true)


## Where a horizontal line crosses the heart's outline, left to right.
static func _crossings(shape: PackedVector2Array, y: float) -> PackedFloat32Array:
	var xs: PackedFloat32Array = []
	for index: int in range(shape.size()):
		var a: Vector2 = shape[index]
		var b: Vector2 = shape[(index + 1) % shape.size()]
		if (a.y - y) * (b.y - y) <= 0.0 and not is_equal_approx(a.y, b.y):
			xs.append(lerpf(a.x, b.x, (y - a.y) / (b.y - a.y)))
	xs.sort()
	return xs


## The surface height at which the heart holds this fraction of its area, so the fill reads
## true even though the heart narrows to a point at the bottom.
static func fill_level(heart: PackedVector2Array, bounds: Rect2, fraction: float) -> float:
	var whole: float = _area(heart)
	var low: float = bounds.position.y
	var high: float = bounds.end.y
	for _step: int in range(14):
		var level: float = (low + high) * 0.5
		var below: PackedVector2Array = [Vector2(bounds.position.x - 1.0, level), Vector2(bounds.end.x + 1.0, level), Vector2(bounds.end.x + 1.0, bounds.end.y + 1.0), Vector2(bounds.position.x - 1.0, bounds.end.y + 1.0)]
		var filled: float = 0.0
		for part: PackedVector2Array in Geometry2D.intersect_polygons(heart, below):
			filled += _area(part)
		if filled / whole > fraction:
			low = level
		else:
			high = level
	return (low + high) * 0.5


static func _area(points: PackedVector2Array) -> float:
	var twice: float = 0.0
	for index: int in range(points.size()):
		twice += points[index].cross(points[(index + 1) % points.size()])
	return absf(twice) * 0.5


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
			run.current_boss.display_name(),
			roundi(100.0 * run.current_boss.health / run.current_boss.max_health),
		]
	var attack_rate: float = 1.0 / maxf(player.thrust_cooldown * player.haste, player.thrust_duration)
	var lines: PackedStringArray = PackedStringArray([
		tr("FPS %3d   FRAME %5.1f ms") % [roundi(fps), frame_ms],
		tr("CPU %5.1f ms  PHYS %5.1f ms") % [process_ms, physics_ms],
		tr("DRAWS %4d   NODES %5d") % [draw_calls, nodes],
		tr("MEMORY %6.1f MB") % memory_mb,
		"",
		tr("ENEMIES %3d / %d") % [run.enemy_count, run.max_enemies],
		tr("BOSS    %s") % boss_text,
		tr("SHOTS   %3d   DROPS %3d") % [get_tree().get_node_count_in_group(&"enemy_projectiles"), run.pickups.get_child_count()],
		tr("KILLS   %4d  LEVEL %2d") % [run.kills, run.level],
		"",
		tr("DMG %d  ATK %.1f/s  REACH %d") % [player.dealt(player.spear_damage), attack_rate, roundi(player.spear_reach)],
		tr("PIERCE %d  SPEED %d  PULL %d") % [player.spear_pierce, roundi(player.movement_speed), roundi(player.pickup_radius)],
		tr("COMBO %d/%d  DASH %s  FLIGHT %d%%") % [
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
	if event.is_action_pressed(&"toggle_help"):
		get_viewport().set_input_as_handled()
		help_shown = not help_shown
		return
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


## Level-up cards, or a shrine pact offer (its own heading; it may have fewer cards).
func show_level_up(options: Array[Dictionary], heading: String = "") -> void:
	for index: int in range(choice_buttons.size()):
		choice_buttons[index].visible = index < options.size()
		choice_details[index].visible = index < options.size()
		if index < options.size():
			var option: Dictionary = options[index]
			choice_buttons[index].text = "%d   %s" % [index + 1, tr(option["name"])]
			choice_details[index].text = tr(option["text"])
	($LevelUp/Box/Hint as Label).text = tr("Click a choice or press 1-%d") % options.size()
	var more: int = run.pending_level_ups - 1
	level_up_heading.text = tr(heading) if heading != "" else (tr("LEVEL UP - CHOOSE ONE") if more <= 0 else tr("LEVEL UP - CHOOSE ONE (+%d MORE)") % more)
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
	UiMotion.pop_in(control, delay, 0.22)


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
		end_label.text += "\n" + tr("FEATHERS COULD NOT BE SAVED")
	elif kept == earned:
		end_label.text += "\n" + tr("+%d FEATHERS") % kept
	else:
		end_label.text += "\n" + tr("KEPT %d OF %d FEATHERS") % [kept, earned]


## The win could not be written: say so, and offer to try again or leave knowingly unsaved.
func show_save_failed(error: Error) -> void:
	end_label.text = tr("%s DEFEATED\nYOUR PROGRESS COULD NOT BE SAVED (ERROR %d)") % [tr(Run.BOSSES[run.sin_index]["name"]), error]
	end_label.show()
	save_failed.show()
	for index: int in range(save_failed.get_child_count()):
		_pop_in(save_failed.get_child(index) as Control, 0.08 * index)


## The two evolution paths for a weapon, as cards that deal in; 1 / 2 or a click picks one.
func show_evolution(which: int, paths: Array) -> void:
	pause_menu.hide()
	($Evolution/Box/Heading as Label).text = tr("%s EVOLUTION") % (tr("SPEAR") if which == MountedPlayer.Weapon.SPEAR else tr("BOW"))
	for index: int in range(evolution_cards.size()):
		var card: Button = evolution_cards[index]
		(card.get_node(^"Text/Title") as Label).text = "%d   %s" % [index + 1, tr(String(paths[index]["name"]).to_upper())]
		(card.get_node(^"Text/Detail") as Label).text = tr(paths[index]["text"])
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
			lines.append(player.side_weapons.label(kind))
	side_label.visible = not lines.is_empty() and not run.ended
	side_label.text = tr("SIDE WEAPONS") + "\n" + "\n".join(lines)


## Names a side-weapon find for a moment above the gauges.
func announce_relic(kind: int) -> void:
	var weapons: SideWeapons = run.player.side_weapons
	announce((tr("NEW: %s") if weapons.levels[kind] == 1 else tr("UPGRADED: %s")) % weapons.label(kind))


## Shows a line above the ability bar for two seconds (a relic find, the run's map modifier),
## tinted (a warning in the burn colour). A newer line replaces an older one at once.
## The run passes English lines; they are translated here, at display.
func announce(text: String, tint: Color = Color.WHITE) -> void:
	if announce_tween != null:
		announce_tween.kill()
	relic_label.text = tr(text)
	relic_label.self_modulate = tint
	relic_label.show()
	relic_label.pivot_offset = relic_label.size * 0.5
	relic_label.scale = Vector2(0.85, 0.85)
	relic_label.modulate.a = 0.0
	announce_tween = relic_label.create_tween().set_ignore_time_scale().set_parallel()
	announce_tween.tween_property(relic_label, ^"scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	announce_tween.tween_property(relic_label, ^"modulate:a", 1.0, 0.14)
	announce_tween.chain().tween_interval(2.0)
	announce_tween.chain().tween_property(relic_label, ^"modulate:a", 0.0, 0.4)
	announce_tween.chain().tween_callback(relic_label.hide)


func hide_level_up() -> void:
	level_up_panel.hide()


func show_end(victory: bool) -> void:
	level_up_panel.hide()
	evolution_panel.hide()
	pause_menu.hide()
	vignette.hide()
	perfect_label.hide()
	perfect_left = 0.0
	hurt_flash_left = 0.0
	damage_numbers.clear()
	var hosted: bool = world_view != null
	if victory and run.sin_index == Run.SATAN:
		end_label.text = tr("SATAN DEFEATED\nTHE WORLD IS SAVED")
	elif victory:
		end_label.text = tr("THE REALM OF %s IS SAVED") % tr(Run.BOSSES[run.sin_index]["name"])
	elif run.shrines_left > 0 and run.shrine_time_left <= 0.0:
		end_label.text = tr("THE SHRINES OUTLASTED YOU")
	else:
		end_label.text = tr("YOU HAVE FALLEN")
	# A hosted win returns to the hub by itself; a defeat offers Retry and the hub.
	if not hosted:
		end_label.text += "\n" + tr("R to start a new run")
	end_label.show()
	_pop_in(end_label, 0.0)
	end_buttons.visible = hosted and not victory
	if end_buttons.visible:
		for index: int in range(end_buttons.get_child_count()):
			_pop_in(end_buttons.get_child(index) as Control, 0.12 + index * 0.08)


func _on_choice(index: int) -> void:
	run.choose_upgrade(index)
