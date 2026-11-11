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
	await _wait_ticks(1)
	_check_layout(hud, PackedStringArray(["StatusPanel", "StatsPanel", "BossStatus", "AssetNotice", "Abilities", "Controls", "LevelUp"]))
	await _toggle_stats(hud)
	_check(not hud.stats_panel.visible, "F3 must hide the stats overlay again.")

	# Readiness is on screen without the overlay.
	_check(hud.dash_label.is_visible_in_tree() and hud.dash_label.text == "DASH READY", "Dash must read ready.")
	_check(hud.jump_label.is_visible_in_tree() and hud.jump_label.text == "JUMP READY", "Jump must read ready.")
	player.dash_cooldown_left = 0.35
	player.jump_time = 0.0
	await process_frame
	_check(hud.dash_label.text.begins_with("DASH 0."), "Dash must show its cooldown, got %s." % hud.dash_label.text)
	_check(hud.dash_bar.value < 1.0, "The dash bar must drain on cooldown.")
	_check(hud.jump_label.text.begins_with("JUMP 0."), "Jump must wait while airborne, got %s." % hud.jump_label.text)
	player.jump_time = -1.0
	player.height = 0.0
	player.dash_cooldown_left = 0.0
	player.begin_descent(100.0, 0.5)
	await process_frame
	_check(hud.dash_label.text == "DASH --" and hud.jump_label.text == "JUMP --", "Abilities must read locked during descent.")
	await _wait_ticks(40)
	_check(hud.dash_label.text == "DASH READY", "Dash must read ready after landing.")

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
	_check(hud.stage_label.text == "STAGE 1 / 8 - PRIDE", "Stage and sin must show.")
	# The countdown and the boss bar share a slot, so exactly one shows.
	_check(hud.boss_status_label.visible and hud.boss_status_label.text.begins_with("NEXT BOSS: PRIDE IN"), "The next boss must be named.")
	run.boss_left = 5.0
	await process_frame
	_check(hud.boss_status_label.self_modulate == Hud.BOSS_WARNING_TINT, "An imminent boss must be flagged.")
	run.spawn_next_boss()
	await process_frame
	_check(hud.boss_panel.visible and not hud.boss_status_label.visible, "The boss bar must replace the countdown.")
	_check(hud.boss_name_label.text.ends_with("100%"), "The boss bar must show health, got %s." % hud.boss_name_label.text)
	_check_layout(hud, PackedStringArray(["StatusPanel", "BossPanel", "AssetNotice", "Abilities", "Controls", "LevelUp"]))
	var boss: Boss = run.current_boss
	boss.take_hit(boss.max_health)
	await process_frame
	_check(hud.boss_status_label.text.contains("EXIT OPEN") and hud.boss_status_label.text.contains("HOLD E"), "The exit prompt must explain confirmation.")
	run._advance_stage()
	await process_frame

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
	run.boss_index = 7
	await _wait_ticks(1)
	_check_layout(hud, PackedStringArray(["StatusPanel", "BossStatus", "AssetNotice", "Items", "Abilities", "Controls", "LevelUp"]))
	run.boss_index = 0

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
