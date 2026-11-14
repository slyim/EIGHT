extends SceneTree
## The campaign: saved progress, the eight authored map scenes and their horde mixes, Satan's
## calm ritual map, the pentagram hub, and the loop hub -> map -> win (saved) -> hub, plus
## defeat -> hub. Uses its own save file; native Godot only.

const TEST_SAVE: String = "user://test_progress.cfg"

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _ticks(count: int) -> void:
	for index: int in range(count):
		await physics_frame
	await process_frame


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _ticks(1)


func _save(sealed: Array, satan: Variant = false) -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("progress", "sealed", sealed)
	file.set_value("progress", "satan_defeated", satan)
	file.save(TEST_SAVE)


## Waits until the current scene is of the given class (scene changes are deferred).
func _scene_becomes(script: Script, limit: int = 600) -> bool:
	for tick: int in range(limit):
		if current_scene != null and current_scene.get_script() == script and current_scene.is_node_ready():
			return true
		await process_frame
	return false


func _run() -> void:
	root.size = Vector2i(1280, 720)
	Progress.path = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))

	# 1. Saved progress: fresh, idempotent wins, Satan, round trip, and damaged files.
	var progress: Progress = Progress.load_saved()
	_check(progress.sealed.is_empty() and not progress.satan_unlocked() and not progress.satan_defeated, "A missing save must be a fresh start.")
	progress.record_win(2)
	progress.record_win(2)
	progress.record_win(Run.SATAN)
	_check(progress.save() == OK, "Progress must save.")
	var loaded: Progress = Progress.load_saved()
	_check(loaded.sealed == [2] and loaded.satan_defeated, "Progress must load back exactly (got %s, %s)." % [loaded.sealed, loaded.satan_defeated])
	_save([99, -1, "x", 3, 3, 2.0], "yes")
	loaded = Progress.load_saved()
	_check(loaded.sealed == [3] and not loaded.satan_defeated, "A damaged save must keep only valid values (got %s, %s)." % [loaded.sealed, loaded.satan_defeated])
	_save([0, 1, 2, 3, 4, 5, 6])
	_check(Progress.load_saved().satan_unlocked(), "Seven sealed sins must unlock Satan.")

	# 2. Each map scene is authored: its sin, its own obstacles and lava, never regenerated.
	for index: int in range(Run.BOSSES.size()):
		var scene: PackedScene = load(Game.map_path(index)) as PackedScene
		var map: Run = scene.instantiate() as Run
		var authored: int = map.get_node(^"Obstacles").get_child_count()
		var first: Vector2 = (map.get_node(^"Obstacles").get_child(0) as Node2D).position
		map.intro_enabled = false
		map.spawning_enabled = false
		root.add_child(map)
		await _ticks(1)
		_check(map.sin_index == index and authored > 0 and map.obstacles.get_child_count() == authored and map.obstacles.get_child(0).position == first, "Map %d must keep its authored obstacles." % index)
		_check(not map.lava_layout.is_empty() and map.lava.pools.size() == map.lava_layout.size(), "Map %d must use its authored lava." % index)
		var expected: int = 0 if index == Run.SATAN else Run.SHRINE_COUNT
		_check(map.shrines_left == expected and map.guards.size() == expected, "Map %d must have %d shrines and guards (got %d, %d)." % [index, expected, map.shrines_left, map.guards.size()])
		map.free()
	await _ticks(2)

	# A sin map edited down to no shrines still summons its sin after landing.
	var bare: Run = (load(Game.map_path(1)) as PackedScene).instantiate() as Run
	for child: Node in bare.get_node(^"Obstacles").get_children():
		if (child as Breakable).kind == Breakable.Kind.SHRINE:
			child.free()
	bare.intro_enabled = false
	bare.spawning_enabled = false
	root.add_child(bare)
	await _ticks(3)
	_check(bare.shrines_left == 0 and bare.current_boss != null and bare.current_boss.boss_name.begins_with("GREED"), "A map with no shrines must summon its sin after landing.")
	bare.free()
	await _ticks(2)

	# 3. Horde mixes: Sloth is husks only and slower, Gluttony brutes, Envy flyers.
	var mix: Run = (load(Game.map_path(0)) as PackedScene).instantiate() as Run
	mix.intro_enabled = false
	mix.spawning_enabled = false
	root.add_child(mix)
	await _ticks(1)
	mix.set_physics_process(false)
	mix.elapsed = 600.0
	for sin: int in [6, 4, 3]:
		mix.sin_index = sin
		var counts: Array[int] = []
		counts.resize(Run.ENEMY_TYPES.size())
		for roll: int in range(400):
			counts[mix._pick_enemy_type()] += 1
		match sin:
			6:
				_check(counts[0] == 400, "Sloth must send only husks (got %s)." % [counts])
			4:
				_check(counts[2] > counts[0] and counts[2] > counts[1] and counts[Run.FLYER] == 0, "Gluttony must favor brutes and send no flyers (got %s)." % [counts])
			3:
				_check(counts[3] > counts[0] and counts[3] > counts[1] and counts[3] > counts[2], "Envy must favor flyers (got %s)." % [counts])
	mix.elapsed = 10.0
	mix.sin_index = 3
	var early: Array[int] = []
	early.resize(Run.ENEMY_TYPES.size())
	for roll: int in range(200):
		early[mix._pick_enemy_type()] += 1
	_check(early[0] == 200, "Before anything unlocks, every map must send husks (got %s)." % [early])
	_check(Run.SIN_SPAWN_PACE[6] > 1.0 and Run.SIN_SPAWN_PACE[0] == 1.0, "Sloth's horde must come slower.")
	mix.free()

	# 4. Satan's map: no shrines or countdown, calm through the ritual, then Satan; his fall wins.
	var satan_map: Run = (load(Game.map_path(Run.SATAN)) as PackedScene).instantiate() as Run
	satan_map.intro_enabled = false
	root.add_child(satan_map)
	satan_map.player.invulnerable_left = 100000.0
	await _ticks(roundi(Run.RITUAL_TIME * 60.0) - 30)
	_check(satan_map.current_boss == null and satan_map.enemy_count == 0, "Satan's map must stay calm through the ritual.")
	_check(satan_map.hud.boss_status_label.text.begins_with("THE RITUAL IS COMPLETE") and satan_map.hud.boss_status_label.text.contains("SATAN COMES IN"), "Satan's map must announce the ritual (got %s)." % satan_map.hud.boss_status_label.text)
	_check(not satan_map.hud.stats_label.text.contains("SHRINES"), "Satan's map must not count shrines it does not have (got %s)." % satan_map.hud.stats_label.text)
	_check(satan_map.shrine_time_left == satan_map.shrine_time, "Satan's map must have no countdown.")
	await _ticks(60)
	var satan: Boss = satan_map.current_boss
	_check(satan != null and satan.boss_name.begins_with("SATAN"), "Satan must arrive after the ritual.")
	await _ticks(90)
	_check(satan_map.enemy_count > 0, "The horde must rise once Satan arrives.")
	satan.take_hit(satan.max_health)
	await _ticks(2)
	_check(satan_map.ended and satan_map.victory and satan_map.exit_portal == null, "Satan's fall must win at once, with no portal.")
	satan_map.free()
	await _ticks(2)

	# 5. The hub: seven sins on the ring, on screen and apart; Satan locked at six relics.
	_save([0, 1, 2, 3, 4, 5])
	change_scene_to_file(Game.HUB_SCENE)
	_check(await _scene_becomes(Hub), "The hub must open.")
	var hub: Hub = current_scene as Hub
	await _ticks(2)
	_check(hub.sin_buttons.size() == Run.SATAN, "The hub must show seven sins.")
	var screen: Rect2 = hub.get_global_rect()
	for index: int in range(hub.sin_buttons.size()):
		var rect: Rect2 = hub.sin_buttons[index].get_global_rect()
		_check(screen.encloses(rect), "Sin %d must be on screen (%s)." % [index, rect])
		_check(not rect.intersects(hub.satan_button.get_global_rect()), "Sin %d must not cover Satan." % index)
		_check(not rect.intersects(hub.get_node("Header").get_global_rect()), "Sin %d must not cover the header." % index)
		for other: int in range(index + 1, hub.sin_buttons.size()):
			_check(not rect.intersects(hub.sin_buttons[other].get_global_rect()), "Sins %d and %d must not overlap." % [index, other])
		_check(hub.sin_buttons[index].text.contains("BEST PENANCE") == (index < 6), "Sin %d must show its best tier once sealed." % index)
	_check(hub.satan_button.disabled and hub.satan_button.text.contains("6 / 7"), "Satan must stay locked at six relics (%s)." % hub.satan_button.text)
	await _key(KEY_S)
	_check(current_scene == hub, "S must not summon Satan while locked.")

	# 6. Entering a sin, winning, and coming back: the win is saved and the new seal ripples.
	await _key(KEY_7)
	_check(await _scene_becomes(Game), "Pressing 7 must enter a map.")
	var game: Game = current_scene as Game
	_check(game.run.sin_index == 6, "Pressing 7 must open Sloth's map (got %d)." % game.run.sin_index)
	await _ticks(5)
	game.run._end_run(true)
	# R during the ascension and during the linger must not restart (or lose) a won map.
	await _key(KEY_R)
	_check(current_scene == game and game.run.player.ascending, "R must not interrupt the ascension.")
	for tick: int in range(600):
		if game.run.hud.end_label.visible:
			break
		await process_frame
	await _key(KEY_R)
	_check(current_scene == game, "R must not restart a won map before the hub.")
	_check(await _scene_becomes(Hub, 900), "A won map must return to the hub.")
	hub = current_scene as Hub
	_check(Progress.load_saved().sealed.has(6) and hub.progress.satan_unlocked(), "The win must be saved before the hub opens.")
	_check(not hub.satan_button.disabled and hub.satan_button.text.begins_with("SUMMON SATAN"), "Seven relics must unlock the summon.")
	await _ticks(60)
	_check(hub.sealed_now == 6 and hub.seal_wave > 0.0, "The newly sealed sin must ripple.")
	_check(Hub.just_sealed == -1, "The ripple must play only once.")

	# A failed save is shown, never mistaken for success; trying again once writable seals it.
	_save([0, 1, 2, 3, 4, 5])
	Progress.path = "user://missing_folder/nested/progress.cfg"
	await _key(KEY_1)
	_check(await _scene_becomes(Game), "Pressing 1 must enter Pride.")
	game = current_scene as Game
	await _ticks(5)
	game.run._end_run(true)
	for tick: int in range(900):
		if game.run.hud.save_failed.visible:
			break
		await process_frame
	_check(game.run.hud.save_failed.visible and game.run.hud.end_label.text.begins_with("PRIDE DEFEATED") and game.run.hud.end_label.text.contains("COULD NOT BE SAVED") and not game.run.hud.end_label.text.contains("IS SAVED"), "A failed save must be shown to the player.")
	await _ticks(roundi(Game.WIN_LINGER * 60.0) + 30)
	_check(current_scene == game, "A failed save must not move on to the hub by itself.")
	Progress.path = TEST_SAVE
	_save([1, 2, 3, 4, 5, 6])
	(game.run.hud.get_node(^"SaveFailed/Retry") as Button).pressed.emit()
	_check(not game.run.hud.save_failed.visible, "A successful retry must clear the warning.")
	_check(await _scene_becomes(Hub, 900), "A successful retry must return to the hub.")
	hub = current_scene as Hub
	_check(hub.progress.satan_unlocked(), "The retried save must seal the realm.")

	# 7. Summoning opens Satan's map; a defeat there offers Retry and the hub, which returns.
	await _key(KEY_S)
	_check(await _scene_becomes(Game), "S must summon Satan once unlocked.")
	game = current_scene as Game
	_check(game.run.sin_index == Run.SATAN, "The summon must open Satan's map.")
	await _ticks(5)
	game.run.player.kill()
	await _ticks(roundi(Run.FALL_TIME * 60.0) + 10)
	_check(game.run.hud.end_buttons.visible and game.run.hud.end_label.text.begins_with("YOU HAVE FALLEN"), "A hosted defeat must offer Retry and the hub.")
	(game.run.hud.get_node(^"EndButtons/Hub") as Button).pressed.emit()
	_check(await _scene_becomes(Hub), "Return to the pentagram must open the hub.")
	_check(not Progress.load_saved().satan_defeated, "A defeat must not be saved as a win.")

	current_scene.queue_free()
	await _ticks(15)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	if failures == 0:
		print("Campaign smoke passed: saved progress and damaged saves, eight authored maps, horde mixes, Satan's ritual map, the hub ring and lock, hub -> map -> saved win -> hub with ripple, summon, defeat -> hub.")
	quit(1 if failures > 0 else 0)
