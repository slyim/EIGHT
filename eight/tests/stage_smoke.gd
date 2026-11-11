extends SceneTree
## Difficulty, portal safety/confirmation, and all eight stages through the real director.

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

func _run() -> void:
	var run: Run = load("res://scenes/run.tscn").instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	run.set_physics_process(false)
	run.player.set_physics_process(false)
	run.player.invulnerable_left = 100000.0
	_check(InputMap.action_get_events(&"enter_portal")[0].physical_keycode == KEY_E, "Portal must bind physical E.")
	run.elapsed = 0.0
	var early: Enemy = run.spawn_enemy(0, Vector2(1000, 1000))
	var speed: float = early.speed
	var health: int = early.max_health
	var damage: int = early.contact_damage
	var interval: float = run.spawn_interval()
	var batch: int = run.spawn_batch()
	run._physics_process(119.9)
	_check(run.difficulty_tier() == 1, "Tier must remain one before two minutes.")
	run._physics_process(0.2)
	_check(run.difficulty_tier() == 2 and run.difficulty() > 2.0, "Difficulty and tier must rise with clock.")
	run.elapsed = 300.0
	for type_index: int in range(Run.ENEMY_TYPES.size()):
		var late: Enemy = run.spawn_enemy(type_index, Vector2(1000, 1000))
		_check(late.speed > float(Run.ENEMY_TYPES[type_index]["speed"]) and late.max_health > int(Run.ENEMY_TYPES[type_index]["health"]) and late.contact_damage > int(Run.ENEMY_TYPES[type_index]["damage"]), "Every enemy type must scale generically.")
	_check(run.spawn_interval() < interval and run.spawn_batch() > batch, "Difficulty must increase spawn pressure.")
	_check(speed == 105.0 and health == 1 and damage == 10, "Starting husk stats must stay intact.")
	for at: Vector2 in [Vector2(-600, -400), Vector2(9000, 9000), Vector2.ZERO]:
		var safe: Vector2 = run._portal_position(at)
		_check(Run.ARENA_RECT.grow(-ExitPortal.RADIUS).has_point(safe) and not run._blocked_rect(safe.x, safe.y, ExitPortal.RADIUS), "Portal must clear arena and pillars.")
	for index: int in range(8):
		run.spawning_enabled = true
		run.boss_left = 0.01
		run._physics_process(0.02)
		var boss: Boss = run.current_boss
		_check(boss != null and boss.boss_name.begins_with(Run.BOSSES[index]["name"]), "Countdown must reach each boss in order.")
		_check(boss.max_health > int(Run.BOSSES[index]["health"]), "Boss health must scale.")
		boss.position = Vector2(850, 800)
		boss.take_hit(boss.max_health)
		await _ticks(2)
		if index == 7:
			break
		var portal: ExitPortal = run.exit_portal
		_check(portal.z_index >= run.z_index, "Portal must draw above the floor.")
		_check(portal != null and portal.position.distance_to(Vector2(850, 800)) < 100.0, "Portal must appear near the slain boss.")
		run._physics_process(run.boss_interval + 5.0)
		_check(run.current_boss == null and run.spawn_next_boss() == null and run.enemy_count > 0, "Horde continues but next boss must wait for exit.")
		run.spawn_pickup(Pickup.Kind.ITEM, Vector2(1500, 1500), 0)
		var shot: EnemyProjectile = EnemyProjectile.new()
		run.actors.add_child(shot)
		shot.position = Vector2(1500, 1500)
		for pickup: Node in run.pickups.get_children():
			pickup.set_physics_process(false)
		var decor_before: Vector2 = run.decor_props[0][1]
		var elapsed_before: float = run.elapsed
		var items_before: int = run.items.size()
		# Holding before arriving cannot confirm; a fresh nearby press is required.
		Input.action_press(&"enter_portal")
		await _ticks(2)
		run.player.position = portal.position
		await _ticks(70)
		_check(run.stage_index == index, "Arriving with E held must not trigger exit.")
		Input.action_release(&"enter_portal")
		await _ticks(2)
		Input.action_press(&"enter_portal")
		await _ticks(15)
		Input.action_release(&"enter_portal")
		await _ticks(2)
		_check(portal.hold_left == 0.0, "Releasing early must cancel confirmation.")
		Input.action_press(&"enter_portal")
		await _ticks(70)
		Input.action_release(&"enter_portal")
		_check(run.stage_index == index + 1 and run.exit_portal == null, "Confirmed exit must advance stage.")
		_check(run.enemy_count == 0 and run.actors.get_child_count() == 0 and run.pickups.get_child_count() == 0, "Exit must clear enemies, projectiles and ground loot.")
		_check(run.player.position == Vector2.ZERO and run.boss_left == run.boss_interval, "Exit must reset landing and countdown.")
		_check(run.elapsed == elapsed_before and run.items.size() == items_before, "Exit must preserve difficulty and collected items.")
		_check(run.decor_props[0][1] != decor_before, "Each stage must re-scatter decoration.")
	_check(run.ended and run.victory and paused and run.exit_portal == null and run.boss_index == 8, "Satan must win immediately without portal.")
	paused = false
	run.queue_free()
	await _ticks(15)
	if failures == 0:
		print("Stage smoke passed: difficulty, scaling, safe portals, confirmation, cleanup, eight-stage flow and victory.")
	quit(failures)
