extends SceneTree
## Native Godot smoke check for boss projectiles; no test framework required.

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


func _clear_projectiles() -> void:
	for node: Node in get_nodes_in_group(&"enemy_projectiles"):
		node.queue_free()
	await _wait_ticks(1)


func _run() -> void:
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	var player: MountedPlayer = run.player

	# 1. Fast projectile crossing the player between physics ticks still hits and frees itself.
	player.global_position = Vector2.ZERO
	player.health = player.max_health
	player.invulnerable_left = 0.0
	var fast: EnemyProjectile = EnemyProjectile.new()
	fast.velocity = Vector2(36000.0, 0.0)
	fast.target = player
	run.actors.add_child(fast)
	fast.global_position = Vector2(-200.0, 0.0)
	await _wait_ticks(2)
	_check(player.health == player.max_health - 12, "Fast projectile crossing player between ticks must deal damage.")
	_check(not is_instance_valid(fast), "Projectile must free itself after damaging the player.")
	await _clear_projectiles()

	# 2. World geometry (a structure) blocks projectile before reaching the player behind it.
	# The first structure (Run.STRUCTURE_SPOTS[0]) sits at (-600, -400) with size (160, 160),
	# spanning x in [-680, -520].
	player.global_position = Vector2(-460.0, -400.0)
	player.health = player.max_health
	player.invulnerable_left = 0.0
	var blocked: EnemyProjectile = EnemyProjectile.new()
	blocked.velocity = Vector2(36000.0, 0.0)
	blocked.target = player
	run.actors.add_child(blocked)
	blocked.global_position = Vector2(-740.0, -400.0)
	await _wait_ticks(2)
	_check(player.health == player.max_health, "World wall must block projectile before reaching player behind it.")
	_check(not is_instance_valid(blocked), "Projectile blocked by a world wall must be freed.")
	await _clear_projectiles()

	# 3. Invulnerable pass-through: dashing, airborne, and hurt-invulnerable states let projectiles pass without consuming them.
	player.global_position = Vector2.ZERO
	player.health = player.max_health
	player.invulnerable_left = 0.0
	player.dash_direction = Vector2.ZERO
	player.dash_time_left = 0.5
	var dash_shot: EnemyProjectile = EnemyProjectile.new()
	dash_shot.velocity = Vector2(24000.0, 0.0)
	dash_shot.target = player
	run.actors.add_child(dash_shot)
	dash_shot.global_position = Vector2(-150.0, 0.0)
	await _wait_ticks(1)
	_check(player.health == player.max_health, "Dashing player must not take projectile damage.")
	_check(is_instance_valid(dash_shot) and dash_shot.global_position.x > 100.0, "Projectile must pass through dashing player without being consumed.")
	player.dash_time_left = 0.0
	await _clear_projectiles()

	player.height = MountedPlayer.JUMP_CLEAR_HEIGHT + 10.0
	var jump_shot: EnemyProjectile = EnemyProjectile.new()
	jump_shot.velocity = Vector2(24000.0, 0.0)
	jump_shot.target = player
	run.actors.add_child(jump_shot)
	jump_shot.global_position = Vector2(-150.0, 0.0)
	await _wait_ticks(1)
	_check(player.health == player.max_health, "Airborne player must clear projectile damage.")
	_check(is_instance_valid(jump_shot) and jump_shot.global_position.x > 100.0, "Projectile must pass through airborne player.")
	player.height = 0.0
	await _clear_projectiles()

	player.invulnerable_left = 0.5
	var hurt_shot: EnemyProjectile = EnemyProjectile.new()
	hurt_shot.velocity = Vector2(24000.0, 0.0)
	hurt_shot.target = player
	run.actors.add_child(hurt_shot)
	hurt_shot.global_position = Vector2(-150.0, 0.0)
	await _wait_ticks(1)
	_check(player.health == player.max_health, "Hurt-invulnerable player must ignore projectile damage.")
	_check(is_instance_valid(hurt_shot) and hurt_shot.global_position.x > 100.0, "Projectile must pass through hurt-invulnerable player.")
	player.invulnerable_left = 0.0
	await _clear_projectiles()

	# 4. Lifetime expiry frees projectile when life_left runs out.
	var expiring: EnemyProjectile = EnemyProjectile.new()
	expiring.velocity = Vector2(60.0, 0.0)
	expiring.life_left = 0.03
	expiring.target = player
	run.actors.add_child(expiring)
	expiring.global_position = Vector2(0.0, 300.0)
	await _wait_ticks(4)
	_check(not is_instance_valid(expiring), "Projectile must expire and free itself when life_left reaches zero.")
	await _clear_projectiles()

	# Expired projectiles must not gain a last damaging sweep.
	player.global_position = Vector2.ZERO
	player.health = player.max_health
	player.invulnerable_left = 0.0
	var expired: EnemyProjectile = EnemyProjectile.new()
	expired.velocity = Vector2(24000.0, 0.0)
	expired.life_left = 0.001
	expired.target = player
	run.actors.add_child(expired)
	expired.global_position = Vector2(-150.0, 0.0)
	await _wait_ticks(2)
	_check(player.health == player.max_health, "An expired projectile must not damage the player.")
	_check(not is_instance_valid(expired), "An expired projectile must be freed.")

	# 5. Transformed parent coordinate correctness when Boss spawns projectiles and moves them.
	run.actors.position = Vector2(300.0, -200.0)
	run.actors.scale = Vector2(2.0, 2.0)
	run.actors.rotation = 0.35
	var boss: Boss = run.spawn_sin_boss()
	boss.speed = 0.0
	boss.attack_left = 999.0
	boss.global_position = Vector2(100.0, 100.0)
	player.global_position = Vector2(260.0, 100.0)
	player.health = player.max_health
	player.invulnerable_left = 0.0
	await _wait_ticks(1)
	boss._fire(Vector2.RIGHT)
	var shots: Array[Node] = get_nodes_in_group(&"enemy_projectiles")
	_check(shots.size() == 1, "Boss._fire must spawn a projectile in enemy_projectiles group.")
	var spawned: EnemyProjectile = shots[0] as EnemyProjectile
	_check(absf(spawned.global_rotation) < 0.001, "Projectile art must face its world-space velocity under a rotated parent.")
	var expected_spawn: Vector2 = boss.global_position + Vector2.RIGHT * boss.radius
	_check(spawned.global_position.distance_to(expected_spawn) < 0.5, "Projectile must spawn at boss global_position + direction * radius even under transformed parent (got %s, expected %s)." % [spawned.global_position, expected_spawn])
	await _wait_ticks(45)
	_check(player.health == player.max_health - 12, "Boss projectile under transformed parent must travel in world space and hit the player.")
	_check(not is_instance_valid(spawned), "Boss projectile must free itself after hitting player under transformed parent.")

	boss.queue_free()
	await _clear_projectiles()
	run.queue_free()
	await _wait_ticks(15)

	if failures == 0:
		print("PASS: swept fast-projectile hit, world wall occlusion, dash/jump/hurt invulnerable pass-through, lifetime expiry, and transformed parent global coordinates.")
	quit(1 if failures > 0 else 0)
