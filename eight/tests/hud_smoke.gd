extends SceneTree
## Native Godot smoke check for the run HUD; no test framework required.

const RUN_SCENE: PackedScene = preload("res://scenes/run.tscn")

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _wait_ticks(count: int) -> void:
	for tick: int in range(count):
		await physics_frame
	await process_frame


## Exercise the real F3 mapping and viewport input delivery.
func _toggle_stats(hud: Hud) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_F3
	event.pressed = true
	Input.parse_input_event(event)
	await _wait_ticks(2)
	event = InputEventKey.new()
	event.physical_keycode = KEY_F3
	event.pressed = false
	Input.parse_input_event(event)
	await _wait_ticks(1)


## Checks everything in names is on screen and clear of the rest. BossStatus and BossPanel
## take turns in one slot, so a call lists only one of them.
func _check_layout(hud: Hud, names: PackedStringArray) -> void:
	names.append("Logo")
	names.append("Title")
	names.append("StageStatus")
	names.append("Difficulty")
	var screen: Rect2 = hud.get_global_rect()
	_check(screen.size.x >= 1280.0 and screen.size.y >= 720.0, "The HUD must fill the viewport.")
	var rects: Array[Rect2] = []
	for node_name: String in names:
		var rect: Rect2 = (hud.get_node(node_name) as Control).get_global_rect()
		_check(screen.encloses(rect), "%s must stay on screen, got %s." % [node_name, rect])
		rects.append(rect)
	for first: int in range(names.size()):
		for second: int in range(first + 1, names.size()):
			_check(not rects[first].intersects(rects[second]), "%s must not overlap %s." % [names[first], names[second]])
	_check(hud.stats_label.get_minimum_size().x <= hud.stats_label.size.x, "The status line must fit its panel.")


func _run() -> void:
	# The UI renders at native window size (no stretch), so lay it out at the minimum window.
	root.size = Vector2i(1280, 720)
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	var hud: Hud = run.hud
	var player: MountedPlayer = run.player
	var logo: TextureRect = hud.get_node("Logo") as TextureRect
	_check(logo.texture != null and logo.is_visible_in_tree(), "The owner's pixel logo must be visible.")
	_check(logo.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "The logo must use nearest-neighbor filtering.")

	# The placeholder notice stays up; the debug overlay stays out of the way until F3.
	var notice: Label = hud.get_node("AssetNotice") as Label
	_check(notice.is_visible_in_tree(), "The placeholder notice must always show.")
	_check(notice.text.contains("PLACEHOLDER ART") and notice.text.contains("PLACEHOLDER AUDIO"), "The notice must name art and audio.")
	_check(not hud.stats_panel.visible, "The stats overlay must start hidden.")
	await _toggle_stats(hud)
	_check(hud.stats_panel.visible and hud.debug_label.text.contains("FPS"), "F3 must show the filled stats overlay.")
	_check(hud.debug_label.text.contains("FLIGHT 100%"), "The stats overlay must show flight stamina.")
	await _wait_ticks(1)
	_check_layout(hud, PackedStringArray(["StatusPanel", "StatsPanel", "BossStatus", "AssetNotice", "Abilities", "Controls", "LevelUp"]))
	await _toggle_stats(hud)
	_check(not hud.stats_panel.visible, "F3 must hide the stats overlay again.")

	# Readiness is on screen without the overlay.
	_check(hud.dash_label.is_visible_in_tree() and hud.dash_label.text == "DASH READY", "Dash must read ready.")
	_check(hud.flight_label.is_visible_in_tree() and hud.flight_label.text == "FLIGHT READY", "Flight must read ready.")
	_check(hud.flight_bar.value == 1.0 and hud.flight_bar.self_modulate == Color.WHITE, "A full flight gauge must be full and lit.")
	player.dash_cooldown_left = 0.35
	player.flight_stamina = player.flight_time * 0.5
	await process_frame
	_check(hud.dash_label.text.begins_with("DASH 0."), "Dash must show its cooldown, got %s." % hud.dash_label.text)
	_check(hud.dash_bar.value < 1.0, "The dash bar must drain on cooldown.")
	# The flight gauge follows stamina and greys out below the take-off minimum.
	_check(hud.flight_label.text == "FLIGHT 50%" and is_equal_approx(hud.flight_bar.value, 0.5), "The flight gauge must follow stamina, got %s." % hud.flight_label.text)
	_check(hud.flight_bar.self_modulate == Color.WHITE, "Flight must stay lit while take-off is possible.")
	player.flight_stamina = player.flight_min_stamina * 0.5
	await process_frame
	_check(hud.flight_bar.value < player.flight_min_stamina / player.flight_time, "The flight gauge must drop with stamina.")
	_check(hud.flight_bar.self_modulate == Hud.ABILITY_WAIT_TINT, "Flight must grey out below the take-off minimum.")
	player.flight_stamina = player.flight_time
	player.dash_cooldown_left = 0.0
	player.begin_descent(100.0, 0.5)
	await process_frame
	_check(hud.dash_label.text == "DASH --" and hud.flight_label.text == "FLIGHT --", "Abilities must read locked during descent.")
	await _wait_ticks(40)
	_check(hud.dash_label.text == "DASH READY" and hud.flight_label.text == "FLIGHT READY", "Abilities must read ready after landing.")

	# Life and experience read as numbers as well as fill.
	player.health = 1
	run.xp = 2
	await process_frame
	_check(hud.life_label.text == "LIFE 1 / 100", "Life must read as a number, got %s." % hud.life_label.text)
	_check(hud.life_label.self_modulate == Hud.LOW_LIFE_TINT, "Low health must be flagged.")
	_check(hud.xp_label.text == "LEVEL 1    XP 2 / 7", "XP must read as numbers, got %s." % hud.xp_label.text)
	player.health = player.max_health

	# The orb fill fraction follows health, including when max health grows.
	player.health = 73
	await process_frame
	_check(absf(hud.orb_fill_fraction() - 0.73) < 0.001, "The orb fill must follow health, got %f." % hud.orb_fill_fraction())
	player.max_health = 200
	player.health = 100
	await process_frame
	_check(absf(hud.orb_fill_fraction() - 0.5) < 0.001, "The orb fill must follow max health growth, got %f." % hud.orb_fill_fraction())
	player.max_health = 100
	player.health = player.max_health

	_check(hud.difficulty_label.text.contains("TIME") and hud.difficulty_label.text.contains("DIFFICULTY 1"), "Clock and difficulty must stay visible.")
	_check(hud.stage_label.text == "REALM OF PRIDE", "The sin's realm must show.")
	_check(hud.stats_label.text.contains("SHRINES 0 / 5"), "Broken shrines must be counted, got %s." % hud.stats_label.text)
	# The shrine countdown and the boss bar share a slot, so exactly one shows.
	_check(hud.boss_status_label.visible and hud.boss_status_label.text.begins_with("DESTROY SATAN'S SHRINES   5 LEFT") and hud.boss_status_label.text.contains("8:00"), "The shrines and countdown must show, got %s." % hud.boss_status_label.text)
	_check(hud.boss_status_label.self_modulate == Color.WHITE, "A long countdown must not be flagged.")
	run.shrine_time_left = 30.0
	await process_frame
	_check(hud.boss_status_label.self_modulate == Hud.ALERT_TINT and hud.boss_status_label.text.contains("0:30"), "The last minute must be flagged.")
	# Off-view shrines get edge markers; the player at the landing site sees none of them.
	var tips: Array[Array] = hud.shrine_marker_tips()
	_check(hud.shrine_markers.is_visible_in_tree() and tips.size() == Run.SHRINE_COUNT, "Every off-view shrine needs a marker (got %d)." % tips.size())
	var angel: Vector2 = hud.world_to_hud(player.global_position)
	var spots: Array[Vector2] = Run.shrine_spots()
	for index: int in range(tips.size()):
		var tip: Vector2 = tips[index][0]
		_check(is_equal_approx(tip.distance_to(angel), Hud.SHRINE_MARKER_RING), "A marker must ride the ring around the angel.")
		_check((tips[index][1] as Vector2).dot((spots[index] - player.global_position).normalized()) > 0.99, "A marker must point toward its shrine.")
		for node_name: String in ["StatusPanel", "BossStatus", "StageStatus", "Difficulty", "Logo", "Title", "AssetNotice", "Abilities", "Controls"]:
			_check(not (hud.get_node(node_name) as Control).get_global_rect().grow(12.0).has_point(tip), "A marker must not sit on %s (at %s)." % [node_name, tip])
	player.global_position = Run.shrine_spots()[0] + Vector2(0.0, 120.0)
	await _wait_ticks(2)
	_check(hud.shrine_marker_tips().size() == Run.SHRINE_COUNT - 1, "A shrine on screen needs no marker.")
	player.global_position = Vector2.ZERO
	await _wait_ticks(2)
	run.spawn_sin_boss()
	await process_frame
	_check(hud.boss_panel.visible and not hud.boss_status_label.visible, "The boss bar must replace the countdown.")
	_check(hud.boss_name_label.text.ends_with("100%"), "The boss bar must show health, got %s." % hud.boss_name_label.text)
	_check_layout(hud, PackedStringArray(["StatusPanel", "BossPanel", "AssetNotice", "Abilities", "Controls", "LevelUp"]))
	var boss: Boss = run.current_boss
	# Opened directly (no pixel host), the boss tag follows the camera at 1:1 screen pixels.
	boss.speed = 0.0
	boss.global_position = player.global_position + Vector2(200.0, 60.0)
	await _wait_ticks(2)
	var anchor: Vector2 = boss.global_position - Vector2(0.0, boss.radius + 18.0)
	var expected: Vector2 = root.get_visible_rect().size * 0.5 + (anchor - player.camera.get_screen_center_position())
	var tag_rect: Rect2 = hud.boss_tag.get_global_rect()
	_check(hud.boss_tag.visible and absf(tag_rect.get_center().x - expected.x) < 1.5 and absf(tag_rect.end.y - expected.y) < 1.5, "Unhosted, the boss tag must sit centered on %s (tag %s)." % [expected, tag_rect])
	boss.take_hit(boss.max_health)
	await process_frame
	_check(hud.boss_status_label.text.begins_with("PRIDE DEFEATED") and hud.boss_status_label.text.contains("HOLD E"), "The exit prompt must explain leaving.")
	# An exit off the view gets its own marker on the ring, pointing at it; none once in view.
	player.global_position = run.exit_portal.global_position + Vector2(0.0, 900.0)
	await _wait_ticks(3)
	var exit: Array = hud.exit_marker_tip()
	_check(not exit.is_empty() and (exit[1] as Vector2).dot(Vector2.UP) > 0.99, "An off-screen exit must get a marker pointing at it (got %s)." % [exit])
	player.global_position = run.exit_portal.global_position + Vector2(0.0, 120.0)
	await _wait_ticks(3)
	_check(hud.exit_marker_tip().is_empty(), "An exit in view needs no marker.")
	player.global_position = Vector2.ZERO
	await _wait_ticks(2)

	# Items stay out of the way until there is something to list.
	_check(not hud.items_label.visible, "An empty item list must stay hidden.")
	run.items.append(Run.ITEMS[0])
	await process_frame
	_check(hud.items_label.visible and hud.items_label.text.contains("Spearhead  +2 spear damage"), "Items must be listed.")
	_check(not hud.items_label.text.contains("Item:"), "The list must not repeat the Item prefix.")
	for count: int in range(Hud.ITEMS_SHOWN + 2):
		run.items.append(Run.ITEMS[5])
	await process_frame
	_check(hud.items_label.text.split("\n").size() == Hud.ITEMS_SHOWN + 1, "The item list must stay compact.")

	# Worst-case status text still fits beside a full item list.
	run.elapsed = 5999.0
	run.kills = 99999
	await _wait_ticks(1)
	_check_layout(hud, PackedStringArray(["StatusPanel", "BossStatus", "AssetNotice", "Items", "Abilities", "Controls", "LevelUp"]))

	# Level-up choices separate the name from its effect, and flag queued choices.
	run.add_xp(run.xp_needed() + 100)
	await _wait_ticks(1)
	_check(hud.level_up_panel.visible, "The level-up choices must show.")
	_check(run.pending_level_ups > 1 and hud.level_up_heading.text.contains("MORE"), "Queued level-ups must be flagged.")
	for index: int in range(hud.choice_buttons.size()):
		var option: Dictionary = run.level_up_options[index]
		_check(hud.choice_buttons[index].text == "%d   %s" % [index + 1, option["name"]], "Choice %d must show its key and name." % index)
		_check(hud.choice_details[index].text == option["text"], "Choice %d must show its effect." % index)
		_check(hud.choice_details[index].get_minimum_size().x <= hud.choice_details[index].size.x, "Choice %d effect must fit." % index)
	paused = false
	run.queue_free()
	# Let the audio server release playbacks before quitting.
	await _wait_ticks(15)

	if failures == 0:
		print("HUD smoke passed.")
	quit(failures)
