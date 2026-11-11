extends SceneTree
## Breakable obstacles in the survival run: toughness per kind, weapon interaction, blocking,
## per-stage layout, and safe portal/spawn placement; native Godot only.

const RUN_SCENE: PackedScene = preload("res://scenes/run.tscn")

var failures: int = 0


func _initialize() -> void:
	# A script error ends the test coroutine before quit(); fail instead of hanging.
	create_timer(180.0, true, false, true).timeout.connect(func() -> void:
		push_error("Obstacle smoke timed out.")
		quit(1))
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _wait_ticks(count: int) -> void:
	for tick: int in range(count):
		await physics_frame
	await process_frame


func _aim_at(world_point: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * root.get_canvas_transform() * world_point
	motion.global_position = motion.position
	Input.warp_mouse(motion.position)
	Input.parse_input_event(motion)
	await _wait_ticks(2)


## One spear attack; step 0 is a thrust, step 2 the sweeping finisher.
func _spear_attack(player: MountedPlayer, step: int) -> void:
	player.attack_step = step - 1
	player.combo_window_left = 1.0 if step > 0 else 0.0
	player.cooldown_left = 0.0
	Input.action_press(&"attack")
	await _wait_ticks(3)
	Input.action_release(&"attack")
	await _wait_ticks(20)


## A motionless enemy that never reaches the player.
func _still_enemy(run: Run, at: Vector2) -> Enemy:
	var enemy: Enemy = run.spawn_enemy(0, at)
	enemy.speed = 0.0
	enemy.knockback_strength = 0.0
	enemy.health = 50
	return enemy


func _clear(run: Run) -> void:
	for child: Node in run.obstacles.get_children():
		child.free()
	for child: Node in run.actors.get_children():
		child.free()
	# Arrows fly as children of the run itself.
	for child: Node in run.get_children():
		if child is Arrow:
			child.free()
	run.enemy_count = 0
	run.player.global_position = Vector2.ZERO
	run.player.spear_pierce = 1
	await _wait_ticks(2)


## True once an obstacle has broken, whether or not its debris has finished and freed it.
func _broken(obstacle: Breakable) -> bool:
	return not is_instance_valid(obstacle) or not obstacle.is_standing()


## [kind, position, vertical] for every obstacle, in placement order.
func _layout(run: Run) -> Array:
	var layout: Array = []
	for child: Node in run.obstacles.get_children():
		var obstacle: Breakable = child as Breakable
		layout.append([obstacle.kind, obstacle.position, obstacle.vertical])
	return layout


func _run() -> void:
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	var player: MountedPlayer = run.player
	player.invulnerable_left = 100000.0
	await _clear(run)
	await _aim_at(Vector2(400.0, 0.0))

	# 1. Each kind breaks after its expected number of thrusts, one blow per thrust, with a
	# flash, shake, hit sound, hit-stop, darkening cracks, and a break effect.
	# Near faces 46 px from the angel; indexed by kind (wall, structure, tree).
	var near_face: Array[float] = [70.0, 126.0, 70.0]
	for kind: Breakable.Kind in [Breakable.Kind.TREE, Breakable.Kind.WALL, Breakable.Kind.STRUCTURE]:
		var obstacle: Breakable = run._add_obstacle(kind, Vector2(near_face[kind], 0.0), true)
		var toughness: int = int(Breakable.KINDS[kind]["health"])
		# Seen through signals, so nothing reads the obstacle after it may have freed itself.
		var hits: Array[int] = [0]
		var last_health: Array[int] = [toughness]
		var breaks: Array[int] = [0]
		var break_ok: Array[bool] = [false]
		obstacle.hit.connect(func(struck: Breakable) -> void:
			hits[0] += 1
			last_health[0] = struck.health)
		# The run connected first, so its sound and poof are already out when this sees the break.
		obstacle.broken.connect(func(struck: Breakable) -> void:
			breaks[0] += 1
			break_ok[0] = struck.collision_layer == 0 and not struck.is_standing() and run.sfx_last_played.has(&"land") and run.effects.get_child_count() > 0)
		await _wait_ticks(2)
		var expected: int = ceili(float(toughness) / player.spear_damage)
		_check(obstacle.max_health == toughness and obstacle.collision_layer == 1, "Kind %d must take its table toughness on the World layer." % kind)
		_check(not obstacle.is_processing(), "A standing, untouched obstacle must not process every frame.")
		for blow: int in range(expected):
			if breaks[0] > 0:
				_check(false, "Kind %d broke early, after %d thrusts." % [kind, blow])
				break
			if blow == 0 and kind == Breakable.Kind.TREE:
				# The first blow on an obstacle gives the hit-stop and shake a spear hit on an enemy does.
				player.cooldown_left = 0.0
				player.combo_window_left = 0.0
				Input.action_press(&"attack")
				for tick: int in range(12):
					await physics_frame
					if hits[0] > 0:
						break
				Input.action_release(&"attack")
				_check(hits[0] == 1 and Engine.time_scale < 1.0 and player.shake_left > 0.0, "A thrust on an obstacle must start hit-stop and camera shake.")
				_check(obstacle.shake_left > 0.0 and obstacle.modulate == Breakable.FLASH_COLOR, "A blow must flash and shake the obstacle.")
				_check(run.sfx_last_played.has(&"enemy_hit"), "A blow must play the hit sound the way enemy hits do.")
				await _wait_ticks(20)
			else:
				await _spear_attack(player, 0)
			_check(hits[0] == blow + 1 and last_health[0] == toughness - blow - 1, "Each thrust must land exactly one blow on kind %d (hits %d, health %d)." % [kind, hits[0], last_health[0]])
			if breaks[0] == 0:
				_check(not obstacle.is_processing() and obstacle.modulate.r < 1.0, "A damaged obstacle must settle, darkened, once the hit effect ends.")
		_check(breaks[0] == 1, "Kind %d must break after %d thrusts." % [kind, expected])
		_check(break_ok[0], "Breaking must stop collision at once and play the break sound and a poof.")
		await _wait_ticks(roundi(Breakable.BREAK_TIME * 60.0) + 4)
		_check(not is_instance_valid(obstacle), "A broken obstacle must free itself after its debris.")
	await _clear(run)

	# 2. The finisher (double damage) and charged arrows break things faster than thrusts.
	var wall: Breakable = run._add_obstacle(Breakable.Kind.WALL, Vector2(70.0, 0.0), true)
	var health: Array[int] = [wall.max_health]
	wall.hit.connect(func(struck: Breakable) -> void: health[0] = struck.health)
	await _wait_ticks(2)
	for swing: int in range(3):
		await _spear_attack(player, 2)
		_check(health[0] == int(Breakable.KINDS[Breakable.Kind.WALL]["health"]) - 2 * (swing + 1), "Each finisher must land one double-damage blow (health %d)." % health[0])
	_check(_broken(wall), "Three finishers must break a wall that takes six thrusts.")
	await _clear(run)
	var tree: Breakable = run._add_obstacle(Breakable.Kind.TREE, Vector2(200.0, 0.0), false)
	health[0] = tree.max_health
	tree.hit.connect(func(struck: Breakable) -> void: health[0] = struck.health)
	await _wait_ticks(2)
	player.fire_arrow(0.0)
	await _wait_ticks(30)
	_check(health[0] == int(Breakable.KINDS[Breakable.Kind.TREE]["health"]) - player.bow_min_damage, "A tap arrow must deal minimum bow damage to an obstacle.")
	player.fire_arrow(1.0)
	await _wait_ticks(30)
	_check(_broken(tree), "A charged arrow must break a tree in one shot.")
	await _clear(run)

	# 3. An arrow spends itself on an obstacle whatever its pierce; once broken, it flies on.
	wall = run._add_obstacle(Breakable.Kind.WALL, Vector2(200.0, 0.0), true)
	var behind: Enemy = _still_enemy(run, Vector2(320.0, 0.0))
	await _wait_ticks(2)
	var arrow: Arrow = player.fire_arrow(1.0)
	await _wait_ticks(30)
	_check(not is_instance_valid(arrow), "An arrow must be freed at the obstacle it hits.")
	_check(wall.health == wall.max_health - player.bow_max_damage and behind.health == 50, "A piercing arrow must stop at an obstacle and spare the enemy behind it (wall %d, enemy %d)." % [wall.health, behind.health])
	wall.take_blow(100)
	player.fire_arrow(1.0)
	await _wait_ticks(30)
	_check(behind.health == 50 - player.bow_max_damage, "Once the obstacle breaks, an arrow must reach the enemy behind it.")
	await _clear(run)

	# 4. The spear and finisher stop at an obstacle and spare the enemy behind it.
	player.spear_pierce = 5
	wall = run._add_obstacle(Breakable.Kind.WALL, Vector2(58.0, 0.0), true)
	health[0] = wall.max_health
	wall.hit.connect(func(struck: Breakable) -> void: health[0] = struck.health)
	behind = _still_enemy(run, Vector2(100.0, 0.0))
	await _wait_ticks(2)
	await _spear_attack(player, 0)
	_check(health[0] == 5 and behind.health == 50, "A piercing thrust must stop at the obstacle (wall %d, enemy %d)." % [health[0], behind.health])
	await _spear_attack(player, 2)
	_check(health[0] == 3 and behind.health == 50, "The finisher must not reach an enemy behind a standing obstacle (wall %d, enemy %d)." % [health[0], behind.health])
	if is_instance_valid(wall):
		wall.take_blow(100)
	await _spear_attack(player, 0)
	_check(behind.health == 49, "Once the obstacle breaks, the thrust must reach the enemy behind it.")
	await _clear(run)

	# 5. The angel is blocked on the ground and in the air until the obstacle breaks.
	tree = run._add_obstacle(Breakable.Kind.TREE, Vector2(90.0, 0.0), false)
	await _wait_ticks(2)
	Input.action_press(&"move_right")
	await _wait_ticks(30)
	_check(player.global_position.x < 90.0 - 26.0 - 20.0, "A tree must block the angel on the ground, got x %f." % player.global_position.x)
	player.flight_stamina = player.flight_time
	Input.action_press(&"jump")
	await _wait_ticks(20)
	_check(player.is_airborne() and player.global_position.x < 90.0 - 26.0 - 20.0, "A tree must block the angel in flight too, got x %f." % player.global_position.x)
	Input.action_release(&"jump")
	await _wait_ticks(25)
	tree.take_blow(100)
	await _wait_ticks(30)
	Input.action_release(&"move_right")
	_check(player.global_position.x > 130.0, "A broken tree must let the angel through, got x %f." % player.global_position.x)
	await _clear(run)

	# 6. A ground enemy is held by an obstacle, cannot damage it, and passes once it breaks.
	wall = run._add_obstacle(Breakable.Kind.WALL, Vector2(150.0, 0.0), true)
	var husk: Enemy = run.spawn_enemy(0, Vector2(260.0, 0.0))
	await _wait_ticks(60)
	_check(husk.global_position.x > 174.0 + husk.radius - 2.0, "A wall must hold a ground enemy, got x %f." % husk.global_position.x)
	_check(wall.health == wall.max_health, "Enemies pressing on an obstacle must not damage it.")
	wall.take_blow(100)
	await _wait_ticks(60)
	_check(husk.global_position.x < 126.0, "A broken wall must let the enemy through, got x %f." % husk.global_position.x)
	await _clear(run)

	# 7. Ground shots stop at an obstacle; flying enemies' shots pass over; neither damages it.
	player.invulnerable_left = 0.0
	wall = run._add_obstacle(Breakable.Kind.WALL, Vector2(-100.0, 0.0), true)
	await _wait_ticks(2)
	for from_air: bool in [false, true]:
		var shot: EnemyProjectile = EnemyProjectile.new()
		shot.velocity = Vector2(36000.0, 0.0)
		shot.damage = 10
		shot.from_air = from_air
		shot.target = player
		run.actors.add_child(shot)
		shot.global_position = Vector2(-300.0, 0.0)
		await _wait_ticks(2)
		_check(not is_instance_valid(shot), "Every shot must be freed, at the obstacle or at the player.")
		if from_air:
			_check(player.health == player.max_health - 10, "A flying enemy's shot must pass over an obstacle.")
		else:
			_check(player.health == player.max_health, "A ground shot must stop at an obstacle.")
	_check(wall.health == wall.max_health, "Enemy shots must not damage an obstacle.")
	player.invulnerable_left = 100000.0
	player.heal(100)
	await _clear(run)

	# 8. The arena's boundary walls cannot be damaged by any weapon.
	player.global_position = Vector2(0.0, -1940.0)
	await _wait_ticks(2)
	await _aim_at(Vector2(0.0, -1990.0))
	await _spear_attack(player, 0)
	await _spear_attack(player, 2)
	arrow = player.fire_arrow(1.0)
	await _wait_ticks(10)
	_check(not is_instance_valid(arrow), "An arrow must stop at the boundary wall.")
	_check(not (run.geometry is Breakable) and not run.geometry.has_method(&"take_blow") and not run.geometry.has_method(&"take_hit"), "The boundary walls must have no way to take damage.")
	_check(run.geometry.collision_layer == 1 and run.geometry.get_child_count() == 4 and run._blocked_rect(0.0, -2010.0, 0.0), "The boundary walls must stay standing.")
	await _clear(run)
	await _aim_at(Vector2(400.0, 0.0))

	# 9. The layout is deterministic per stage, differs between stages, keeps the landing site
	# and lanes open, and leaves portals and spawns outside every obstacle.
	var layouts: Array = []
	var room: Rect2 = Run.ARENA_RECT.grow(-Run.OBSTACLE_LANE)
	for stage: int in range(Run.BOSSES.size()):
		run.stage_index = stage
		run._place_obstacles()
		var layout: Array = _layout(run)
		run._place_obstacles()
		run._scatter_decor()
		_check(_layout(run) == layout, "Stage %d's layout must be the same every time it is built." % stage)
		_check(layout.size() == Run.STRUCTURE_SPOTS.size() + Run.WALL_COUNT + Run.TREE_COUNT, "Stage %d must place every obstacle, got %d." % [stage, layout.size()])
		_check(stage == 0 or layout != layouts[stage - 1], "Stage %d's layout must differ from the last stage's." % stage)
		layouts.append(layout)
		var rects: Array[Rect2] = []
		for child: Node in run.obstacles.get_children():
			rects.append((child as Breakable).footprint())
		for index: int in range(rects.size()):
			var rect: Rect2 = rects[index]
			_check(Vector2.ZERO.clamp(rect.position, rect.end).length() >= Run.LANDING_CLEARANCE, "Stage %d keeps an obstacle on the landing site at %s." % [stage, rect])
			_check(room.encloses(rect), "Stage %d crowds the arena wall with %s." % [stage, rect])
			for other: int in range(index + 1, rects.size()):
				_check(not rect.grow(Run.OBSTACLE_LANE - 0.5).intersects(rects[other]), "Stage %d leaves no lane between %s and %s." % [stage, rect, rects[other]])
		for prop: Array in run.decor_props:
			var at: Vector2 = prop[1]
			_check(not run._blocked_rect(at.x, at.y, 0.0), "Stage %d scatters decoration inside an obstacle at %s." % [stage, at])
		var sites: Array[Vector2] = []
		for x: int in range(-2000, 2001, 400):
			for y: int in range(-2000, 2001, 400):
				sites.append(Vector2(x, y))
		for rect: Rect2 in rects:
			sites.append(rect.get_center())
		for site: Vector2 in sites:
			var portal: Vector2 = run._portal_position(site)
			_check(Run.ARENA_RECT.grow(-ExitPortal.RADIUS).has_point(portal) and not run._blocked_rect(portal.x, portal.y, ExitPortal.RADIUS), "Stage %d puts a portal inside an obstacle at %s." % [stage, portal])
		for sample: int in range(40):
			player.global_position = sites[sample * 7 % sites.size()]
			var spawn: Vector2 = run._random_offscreen_point()
			_check(not run._blocked_rect(spawn.x, spawn.y, 22.0), "Stage %d spawns an enemy inside an obstacle at %s." % [stage, spawn])
	player.global_position = Vector2.ZERO

	# A broken obstacle no longer occupies its spot for anything placed later.
	run.stage_index = 0
	run._place_obstacles()
	var first: Breakable = run.obstacles.get_child(Run.STRUCTURE_SPOTS.size()) as Breakable
	var spot: Vector2 = first.position
	_check(run._blocked_rect(spot.x, spot.y, 0.0), "A standing obstacle must occupy its spot.")
	first.take_blow(100)
	_check(not run._blocked_rect(spot.x, spot.y, 0.0) and run._portal_position(spot) == spot, "A broken obstacle must free its spot at once.")
	(run.obstacles.get_child(0) as Breakable).take_blow(3)

	# 10. Advancing the stage rebuilds the next stage's layout fresh, with broken ones back.
	var boss: Boss = run.spawn_next_boss()
	_check(not run._blocked_rect(boss.position.x, boss.position.y, boss.radius), "A boss must not spawn inside an obstacle.")
	boss.take_hit(boss.max_health)
	await _wait_ticks(2)
	_check(is_instance_valid(run.exit_portal), "The slain sin must open a portal.")
	run._advance_stage()
	await _wait_ticks(2)
	_check(run.stage_index == 1 and _layout(run) == layouts[1], "Advancing must build the next stage's layout.")
	var whole: bool = true
	for child: Node in run.obstacles.get_children():
		var obstacle: Breakable = child as Breakable
		whole = whole and obstacle.is_standing() and obstacle.health == obstacle.max_health and obstacle.collision_layer == 1
	_check(whole and run.obstacles.get_child_count() == layouts[1].size(), "Every obstacle in a new stage must stand at full health.")

	run.queue_free()
	# Let the audio server release playbacks before quitting.
	await _wait_ticks(15)
	if failures == 0:
		print("PASS: obstacle toughness per kind, one blow per thrust, hit feedback and hit-stop, finisher and charged arrow, arrow and spear stopped then through, angel blocked on ground and in flight, enemy held then through, ground vs flying shots, no enemy damage, unbreakable boundary, deterministic per-stage layout with clear landing and lanes, safe portals and spawns, freed spots, fresh layout on stage advance.")
	quit(1 if failures > 0 else 0)
