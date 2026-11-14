extends SceneTree
## Native Godot smoke check for the Horde Surge event: its first gap, the surge starting with an
## announcement and a HUD countdown, quicker and bigger spawns while it runs, and its end
## restarting the gap.

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


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var run: Run = RUN_SCENE.instantiate() as Run
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	run.player.invulnerable_left = 100000.0
	run.elite_left = 100000.0
	run.max_enemies = 1000
	_check(run.surge_left == 0.0 and run.surge_next >= Run.SURGE_GAP_MIN - 1.0 and run.surge_next <= Run.SURGE_GAP_MAX, "The first surge must wait 90-150 s (%.1f)." % run.surge_next)
	# The surge clock stands still before landing and while paused (level-ups).
	var waiting: float = run.surge_next
	run.has_landed = false
	await _wait_ticks(5)
	run.has_landed = true
	paused = true
	await _wait_ticks(5)
	paused = false
	_check(is_equal_approx(run.surge_next, waiting), "The surge clock must wait for landing and stop while paused.")

	# A normal spawn wave: its batch and the wait to the next.
	run.spawn_left = 0.0
	var before: int = run.enemy_count
	await _wait_ticks(1)
	var normal_batch: int = run.enemy_count - before
	var normal_wait: float = run.spawn_left
	_check(normal_batch == run.spawn_batch() and normal_batch > 0, "A normal wave must spawn the usual batch (%d)." % normal_batch)

	# The surge starts: announced, counted down, quicker and bigger waves.
	run.surge_next = 0.0
	await _wait_ticks(1)
	_check(run.surge_left > Run.SURGE_TIME - 1.0, "A due surge must start (%.1f)." % run.surge_left)
	_check(run.hud.relic_label.visible and run.hud.relic_label.text == "HORDE SURGE", "The surge must be announced (%s)." % run.hud.relic_label.text)
	await _wait_ticks(20)
	_check(run.hud.stage_label.text.contains("HORDE SURGE %d" % ceili(run.surge_left)), "The HUD must count the surge down (%s)." % run.hud.stage_label.text)
	run.spawn_left = 0.0
	before = run.enemy_count
	await _wait_ticks(1)
	_check(run.enemy_count - before == run.spawn_batch() + Run.SURGE_BATCH, "A surge wave must be bigger (%d)." % (run.enemy_count - before))
	_check(run.spawn_left < normal_wait * (Run.SURGE_INTERVAL + 0.05), "Surge waves must come quicker (%.2f vs %.2f)." % [run.spawn_left, normal_wait])

	# It ends: no countdown, the usual waves, and a fresh gap to the next.
	run.surge_left = 0.05
	await _wait_ticks(5)
	_check(run.surge_left == 0.0 and run.surge_next >= Run.SURGE_GAP_MIN - 1.0 and run.surge_next <= Run.SURGE_GAP_MAX and not run.hud.stage_label.text.contains("SURGE"), "A finished surge must end and restart the gap (%.1f)." % run.surge_next)
	run.spawn_left = 0.0
	before = run.enemy_count
	await _wait_ticks(1)
	_check(run.enemy_count - before == run.spawn_batch(), "After the surge, waves must return to normal.")

	# A relic line already showing keeps its place; the title still counts the surge down.
	run.hud.announce("NEW: SOMETHING")
	run.surge_next = 0.0
	await _wait_ticks(20)
	_check(run.surge_left > 0.0 and run.hud.relic_label.text == "NEW: SOMETHING" and run.hud.stage_label.text.contains("HORDE SURGE"), "A surge must not erase a line already showing (%s)." % run.hud.relic_label.text)
	# A run that ends mid-surge drops the countdown from its title.
	run.ended = true
	await _wait_ticks(20)
	_check(not run.hud.stage_label.text.contains("SURGE"), "An ended run must not keep a frozen surge countdown.")
	# The longest title (the longest realm name, Scorched Earth, and a surge) fits its label.
	var title: Label = run.hud.stage_label
	var longest: String = "REALM OF GLUTTONY   SCORCHED EARTH   HORDE SURGE 20"
	var width: float = title.get_theme_font(&"font").get_string_size(longest, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size(&"font_size")).x
	_check(width <= title.size.x, "The longest realm title must fit its label (%.0f of %.0f px)." % [width, title.size.x])

	run.queue_free()
	await _wait_ticks(30) # Let freed nodes and sounds finish before quitting.
	if failures == 0:
		print("event_smoke: PASS")
	quit(1 if failures > 0 else 0)
