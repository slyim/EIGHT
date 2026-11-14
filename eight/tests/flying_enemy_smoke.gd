extends SceneTree
## Native Godot smoke check for the flying shooting enemy; no test framework required.

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


func _clear_actors(run: Run) -> void:
	for child: Node in run.actors.get_children():
		child.queue_free()
	run.enemy_count = 0
	await _wait_ticks(1)


func _reset_player(run: Run) -> void:
	var player: MountedPlayer = run.player
	player.global_position = Vector2.ZERO
	player.height = 0.0
	player.invulnerable_left = 0.0
	player.dash_time_left = 0.0
	player.health = player.max_health


## A from-air shot fired from the west at a target at `target_position`.
func _fire_shot(run: Run, target: MountedPlayer, target_position: Vector2, from_air: bool, damage: int) -> EnemyProjectile:
	var shot: EnemyProjectile = EnemyProjectile.new()
	shot.velocity = Vector2(36000.0, 0.0)
	shot.damage = damage
	shot.from_air = from_air
	shot.target = target
	run.actors.add_child(shot)
	shot.global_position = target_position - Vector2(290.0, 0.0)
	return shot


func _run() -> void:
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	var player: MountedPlayer = run.player
	var flyer_type: int = Run.FLYER

	# 1. The new roster entry spawns the flying enemy with its roster stats.
	# Difficulty scales stats with elapsed time; the roster values apply at zero.
	run.elapsed = 0.0
	var flyer: Enemy = run.spawn_enemy(flyer_type, Vector2(400.0, 0.0))
	_check(flyer is FlyingEnemy, "The new ENEMY_TYPES entry must instantiate the flying enemy scene.")
	_check(flyer.flying, "A flying enemy must set the flying flag.")
	_check(flyer.collision_layer == 16 and flyer.collision_mask == 0, "A flying enemy must sit on layer 5 (16) alone and collide with nothing.")
	_check(run.enemy_count == 1, "A flying enemy must count toward enemy_count.")
	_check(flyer.max_health == 2 and flyer.speed == 120.0 and flyer.xp_value == 3 and flyer.contact_damage == 8, "Flying enemy roster stats must carry through spawn_enemy.")
	await _clear_actors(run)

	# 2. It crosses the pillar interior on the way in (layer 5 ignores the world) and holds
	# its preferred distance instead of piling onto the player.
	player.global_position = Vector2(-100.0, -400.0)
	var approach: Enemy = run.spawn_enemy(flyer_type, Vector2(-760.0, -400.0))
	# The first structure (the old Pillar1) spans x in [-680, -520] at y in [-480, -320];
	# sample its shrunk core.
	var pillar_core: Rect2 = Rect2(-660.0, -460.0, 120.0, 120.0)
	var over_pillar: bool = false
	var ticks: int = 0
	while ticks < 600 and approach.global_position.distance_to(player.global_position) > 200.0:
		if pillar_core.has_point(approach.global_position):
			over_pillar = true
		await physics_frame
		ticks += 1
	await _wait_ticks(10)
	_check(over_pillar, "A flying enemy must pass over the pillar interior, not slide around it.")
	var held: float = approach.global_position.distance_to(player.global_position)
	_check(held >= 140.0 and held <= 200.0, "A flying enemy must hold its preferred distance (~170), got %.1f." % held)
	await _clear_actors(run)

	# 3. After a short wind-up it fires one aimed shot per interval.
	_reset_player(run)
	var shooter: Enemy = run.spawn_enemy(flyer_type, Vector2(300.0, 0.0))
	shooter.speed = 0.0
	shooter.fire_left = 0.1
	await _wait_ticks(10)
	_check(shooter.windup_left > 0.0, "Firing must be preceded by a short wind-up tell.")
	await _wait_ticks(30)
	var shots: Array[Node] = get_nodes_in_group(&"enemy_projectiles")
	_check(shots.size() == 1, "The flying enemy must fire one shot per interval, got %d." % shots.size())
	if shots.size() == 1:
		var shot: EnemyProjectile = shots[0] as EnemyProjectile
		_check(shot.from_air and shot.damage == shooter.shot_damage, "Its shot must carry from_air and its shot_damage.")
		_check(absf(shot.velocity.length() - shooter.shot_speed) < 1.0, "Its shot must travel at the exported shot speed.")
		_check(shot.target == player and shot.velocity.x < 0.0, "Its shot must be aimed at the player.")
	await _clear_actors(run)

	# 4. Its shots hurt a grounded player and an airborne one; ground shots miss an airborne one.
	_reset_player(run)
	_fire_shot(run, player, Vector2.ZERO, true, 10)
	await _wait_ticks(2)
	_check(player.health == player.max_health - 10, "A from-air shot must hurt a grounded player.")
	await _clear_actors(run)

	_reset_player(run)
	player.height = MountedPlayer.JUMP_CLEAR_HEIGHT + 10.0
	_fire_shot(run, player, Vector2.ZERO, true, 10)
	await _wait_ticks(2)
	_check(player.health == player.max_health - 10, "A from-air shot must hurt an airborne player.")
	await _clear_actors(run)

	_reset_player(run)
	player.height = MountedPlayer.JUMP_CLEAR_HEIGHT + 10.0
	_fire_shot(run, player, Vector2.ZERO, false, 12)
	await _wait_ticks(2)
	_check(player.health == player.max_health, "A ground shot must still miss an airborne player.")
	player.height = 0.0
	await _clear_actors(run)

	# 5. A pillar does not stop a from-air shot but stops a ground shot.
	_reset_player(run)
	player.global_position = Vector2(-460.0, -400.0)
	var passed: EnemyProjectile = _fire_shot(run, player, player.global_position, true, 10)
	await _wait_ticks(2)
	_check(player.health == player.max_health - 10, "A pillar must not stop a from-air shot.")
	_check(not is_instance_valid(passed), "A from-air shot that reached the player must be freed.")
	await _clear_actors(run)

	_reset_player(run)
	player.global_position = Vector2(-460.0, -400.0)
	var stopped: EnemyProjectile = _fire_shot(run, player, player.global_position, false, 12)
	await _wait_ticks(2)
	_check(player.health == player.max_health, "A pillar must still stop a ground shot before the player.")
	_check(not is_instance_valid(stopped), "A ground shot stopped by a pillar must be freed.")
	await _clear_actors(run)

	# 6. A ground enemy's touch still misses an airborne player.
	_reset_player(run)
	var husk: Enemy = run.spawn_enemy(0, Vector2(30.0, 0.0))
	husk.speed = 0.0
	player.height = MountedPlayer.JUMP_CLEAR_HEIGHT + 10.0
	await _wait_ticks(3)
	_check(player.health == player.max_health, "A husk's ground touch must miss an airborne player.")
	player.height = 0.0
	player.invulnerable_left = 0.0
	await _wait_ticks(3)
	_check(player.health == player.max_health - 10, "A husk's touch must still hurt a grounded player.")
	await _clear_actors(run)

	# 7. Killing a flying enemy decrements enemy_count and drops its experience.
	_reset_player(run)
	player.pickup_radius = 500.0
	var dying: Enemy = run.spawn_enemy(flyer_type, Vector2(90.0, 0.0))
	dying.speed = 0.0
	await _wait_ticks(2)
	_check(run.enemy_count == 1, "The flying enemy must count toward enemy_count.")
	dying.take_hit(dying.max_health)
	await _wait_ticks(60)
	_check(not is_instance_valid(dying), "Killing the flying enemy must free it.")
	_check(run.enemy_count == 0 and run.kills == 1, "Killing a flying enemy must decrement enemy_count and count a kill.")
	_check(run.xp == 3, "A dead flying enemy must drop 3 experience that the player collects.")
	await _clear_actors(run)

	# 8. The roster gate: flyers are only picked after about a minute, at a modest share.
	run.elapsed = 30.0
	var early: bool = false
	for roll: int in range(200):
		if run._pick_enemy_type() == flyer_type:
			early = true
	run.elapsed = 70.0
	var late_flyers: int = 0
	for roll: int in range(200):
		if run._pick_enemy_type() == flyer_type:
			late_flyers += 1
	run.elapsed = 0.0
	_check(not early, "Flying enemies must not be picked before 60 seconds.")
	_check(late_flyers > 0, "Flying enemies must appear after 60 seconds.")
	_check(late_flyers < 60, "Flying enemies must stay a modest share of spawns, got %d / 200." % late_flyers)

	run.queue_free()
	await _wait_ticks(15)

	if failures == 0:
		print("PASS: flying enemy layer 5 and pillar pass-through, preferred distance, wind-up and interval shot, from-air shot damage grounded and airborne, ground-shot miss airborne, pillar stops ground shots, husk touch miss airborne, kill xp and count, roster gate.")
	quit(1 if failures > 0 else 0)
