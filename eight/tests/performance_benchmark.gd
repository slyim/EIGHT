extends SceneTree
## Fixed-seed stress fixture; run with --disable-vsync --max-fps 0.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	seed(8)
	var run: Run = load("res://scenes/run.tscn").instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	# Keep contact and collection from ending or pausing the fixed workload.
	run.player.set_physics_process(false)
	run.player.invulnerable_left = 100000.0
	run.player.set_collision_layer_value(1, false)
	for index: int in range(run.max_enemies):
		var angle: float = TAU * index / run.max_enemies
		var enemy: Enemy = run.spawn_enemy(0, Vector2.from_angle(angle) * 650.0)
		enemy.set_physics_process(true)
		enemy.target = run.player
	for index: int in range(600):
		run.spawn_pickup(Pickup.Kind.XP, Vector2(400 + index % 30 * 24, -300 + index / 30 * 24), 1)
	var samples: Array[float] = []
	var totals: PackedFloat64Array = PackedFloat64Array([0, 0, 0, 0, 0])
	var previous: int = Time.get_ticks_usec()
	for frame_index: int in range(720):
		# Exercise allocation and animation expiry continuously.
		for effect_index: int in range(8):
			run._spawn_poof(Vector2(200 + effect_index * 30, 200), 2.0)
		await process_frame
		var now: int = Time.get_ticks_usec()
		if frame_index >= 120:
			samples.append((now - previous) / 1000.0)
			var monitors: Array[int] = [Performance.TIME_PROCESS, Performance.TIME_PHYSICS_PROCESS, Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME, Performance.OBJECT_COUNT, Performance.OBJECT_NODE_COUNT]
			for index: int in range(monitors.size()):
				totals[index] += Performance.get_monitor(monitors[index])
		previous = now
	for index: int in range(totals.size()):
		totals[index] /= samples.size()
	samples.sort()
	print("BENCH mode=", DisplayServer.get_name(), " frames=", samples.size(), " median_ms=", samples[300], " p95_ms=", samples[570], " monitors_mean(process_s,physics_s,draw_calls,objects,nodes)=", totals)
	quit()


