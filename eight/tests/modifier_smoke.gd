extends SceneTree
## Native Godot smoke check for the Scorched Earth map modifier: hotter, quicker lava burns and
## more feathers on a scorched run, nothing changed on a normal one, the HUD naming it, and a
## hub-style start carrying it into the map and announcing it on landing.

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


func _new_run(scorched: bool) -> Run:
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	run.scorched = scorched
	root.add_child(run)
	current_scene = run
	return run


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var normal: Run = _new_run(false)
	await _wait_ticks(3)
	var burn: int = normal.lava.burn_damage
	var interval: float = normal.lava.burn_interval
	normal.feathers_earned = 100
	_check(burn == 8 and is_equal_approx(interval, 0.5) and normal.feathers_total() == 100 and not normal.hud.stage_label.text.contains("SCORCHED") and not normal.hud.relic_label.visible, "A normal run must keep its lava, feathers, and title, and announce nothing.")
	normal.queue_free()
	await _wait_ticks(2)

	var scorched: Run = _new_run(true)
	await _wait_ticks(3)
	_check(scorched.lava.burn_damage == roundi(burn * Run.SCORCHED_BURN) and is_equal_approx(scorched.lava.burn_interval, interval * Run.SCORCHED_INTERVAL), "Scorched Earth must burn harder and more often (%d, %.3f)." % [scorched.lava.burn_damage, scorched.lava.burn_interval])
	scorched.feathers_earned = 100
	_check(scorched.feathers_total() == floori(100 * Run.SCORCHED_FEATHERS), "Scorched Earth must pay more feathers (%d)." % scorched.feathers_total())
	_check(scorched.hud.stage_label.text.contains("SCORCHED EARTH"), "The HUD must name the modifier (%s)." % scorched.hud.stage_label.text)
	var line: Label = scorched.hud.relic_label
	_check(line.visible and line.text.begins_with("SCORCHED EARTH") and line.self_modulate == Hud.BURN_TINT, "A run without the intro must announce the modifier too, in the burn colour.")
	# A newer announcement replaces the older one whole: the old fade must not cut it short.
	await _wait_ticks(90)
	scorched.hud.announce("NEWER LINE")
	await _wait_ticks(80)
	_check(line.visible and line.text == "NEWER LINE" and line.modulate.a > 0.9 and line.self_modulate == Color.WHITE, "An older announcement must not fade a newer one (%.2f)." % line.modulate.a)
	scorched.queue_free()
	await _wait_ticks(2)

	# A hub-style start carries the roll into the map, and the landing announces it.
	Progress.path = "user://modifier_progress.cfg"
	Settings.path = "user://modifier_settings.cfg"
	Game.start_map(self, 0, 0, true)
	await _wait_ticks(5)
	var game: Game = current_scene as Game
	_check(game != null and game.run.scorched, "Game.start_map must carry Scorched Earth into the map.")
	if game != null:
		game.run.player.invulnerable_left = 100000.0
		for tick: int in range(240):
			if game.run.has_landed:
				break
			await _wait_ticks(1)
		await _wait_ticks(2)
		_check(game.run.has_landed and game.run.hud.relic_label.visible and game.run.hud.relic_label.text.begins_with("SCORCHED EARTH"), "Landing must announce Scorched Earth (%s)." % game.run.hud.relic_label.text)
		# A restart (R / Retry) keeps the roll.
		game.run.hud.restart()
		await _wait_ticks(5)
		_check(current_scene is Game and current_scene != game and (current_scene as Game).run.scorched, "A restart must keep Scorched Earth.")
	Game.start_map(self, 0)
	await _wait_ticks(5)
	_check(not (current_scene as Game).run.scorched, "A start without the roll must be a normal run.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://modifier_progress.cfg"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://modifier_settings.cfg"))
	current_scene.queue_free()
	await _wait_ticks(30) # Let freed nodes and sounds finish before quitting.
	if failures == 0:
		print("modifier_smoke: PASS")
	quit(1 if failures > 0 else 0)
