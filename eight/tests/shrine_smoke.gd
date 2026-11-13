extends SceneTree
## One sin's map through the real director: difficulty scaling, five shrines on a pentagram
## with a guard each, the countdown, healing, the sin boss, the exit portal, and post-boss
## scaling. Native Godot only.

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


func _shrines(run: Run) -> Array[Breakable]:
	var found: Array[Breakable] = []
	for child: Node in run.obstacles.get_children():
		var obstacle: Breakable = child as Breakable
		if obstacle != null and obstacle.kind == Breakable.Kind.SHRINE:
			found.append(obstacle)
	return found


func _new_run() -> Run:
	var run: Run = load("res://scenes/run.tscn").instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	return run


func _run() -> void:
	var run: Run = _new_run()
	await _ticks(3)
	var player: MountedPlayer = run.player
	player.invulnerable_left = 100000.0

	# Difficulty rises with the clock and scales every enemy type and spawn pressure.
	run.set_physics_process(false)
	var interval: float = run.spawn_interval()
	var batch: int = run.spawn_batch()
	run.elapsed = 119.9
	_check(run.difficulty_tier() == 1, "Tier must remain one before two minutes.")
	run.elapsed = 120.1
	_check(run.difficulty_tier() == 2 and run.difficulty() > 2.0, "Difficulty and tier must rise with the clock.")
	run.elapsed = 300.0
	for type_index: int in range(Run.ENEMY_TYPES.size()):
		var late: Enemy = run.spawn_enemy(type_index, Vector2(1000, 1000))
		_check(late.speed > float(Run.ENEMY_TYPES[type_index]["speed"]) and late.max_health > int(Run.ENEMY_TYPES[type_index]["health"]) and late.contact_damage > int(Run.ENEMY_TYPES[type_index]["damage"]), "Every enemy type must scale generically.")
		late.free()
	run.enemy_count = 0
	_check(run.spawn_interval() < interval and run.spawn_batch() > batch, "Difficulty must increase spawn pressure.")
	run.elapsed = 0.0
	run.set_physics_process(true)

	# Five shrines on the points of a pentagram, each with a weaker sin guard beside it.
	var shrines: Array[Breakable] = _shrines(run)
	_check(shrines.size() == Run.SHRINE_COUNT and run.shrines_left == Run.SHRINE_COUNT, "The map must place five shrines (got %d)." % shrines.size())
	for index: int in range(shrines.size()):
		var expected: Vector2 = Vector2.from_angle(-PI * 0.5 + TAU * index / Run.SHRINE_COUNT) * Run.SHRINE_RING
		_check(shrines[index].position.is_equal_approx(expected), "Shrine %d must stand on its pentagram point." % index)
		_check(shrines[index].is_in_group(&"light"), "A standing shrine must glow as a light.")
	_check(run.guards.size() == Run.SHRINE_COUNT and run.current_boss == null, "Each shrine needs one guard, and no sin boss yet.")
	for guard: Boss in run.guards:
		_check(guard.boss_name.begins_with("PRIDE GUARD") and guard.max_health < int(Run.BOSSES[0]["health"]), "Guards must be weaker Pride copies (%s, %d)." % [guard.boss_name, guard.max_health])
		_check(guard.leash > 0.0 and guard.global_position.distance_to(guard.home) < 220.0, "A guard must start beside its shrine.")

	# A guard defends only near its shrine: far away it walks home, near it chases.
	var guard: Boss = run.guards[0]
	guard.attack_left = 999.0
	guard.global_position = guard.home + Vector2(300.0, 0.0)
	await _ticks(20)
	_check(guard.global_position.distance_to(guard.home) < 300.0 - 20.0, "A guard must return toward its shrine while the angel is far.")
	player.global_position = guard.home + Vector2(0.0, 300.0)
	var before: float = guard.global_position.distance_to(player.global_position)
	await _ticks(20)
	_check(guard.global_position.distance_to(player.global_position) < before - 20.0, "A guard must chase the angel near its shrine.")
	# Leaving the leash mid-charge cancels the charge and sends the guard home.
	guard.attack_left = 0.0
	guard.patterns.assign([Boss.Pattern.CHARGE])
	await _ticks(3)
	_check(guard.windup_left > 0.0 or guard.charge_left > 0.0, "A guard near its shrine must start its charge.")
	player.global_position = Vector2.ZERO
	await _ticks(2)
	_check(guard.windup_left == 0.0 and guard.charge_left == 0.0, "Leaving the leash must cancel a guard's charge.")
	# Guards never summon minions, even on a summoning sin's map.
	guard.patterns.assign([Boss.Pattern.SUMMON])
	var horde: int = run.enemy_count
	guard._attack(Boss.Pattern.SUMMON)
	await _ticks(1)
	_check(run.enemy_count == horde, "A guard must not summon minions onto the horde.")
	for each: Boss in run.guards.duplicate():
		each.take_hit(each.max_health)
	await _ticks(2)
	_check(run.guards.is_empty() and run.current_boss == null and run.kills == Run.SHRINE_COUNT, "Killing guards must count kills without summoning the sin.")

	# Only player blows damage a shrine; enemies and boss shots do not.
	var shrine: Breakable = shrines[0]
	_check(not shrine.has_method(&"take_hit"), "A shrine must not be a take_hit target for enemy attacks.")
	shrine.take_blow(1)
	_check(shrine.health == shrine.max_health - 1 and shrine.max_health == 20, "A shrine must take 20 blows (health %d / %d)." % [shrine.health, shrine.max_health])

	# The countdown runs only after landing, and only while shrines stand.
	var countdown: float = run.shrine_time_left
	await _ticks(30)
	_check(run.shrine_time_left < countdown, "The countdown must run once landed.")

	# Breaking a shrine heals the ground around it, once; the last one summons the sin.
	for index: int in range(shrines.size() - 1):
		shrines[index].take_blow(1000)
		shrines[index].take_blow(1000)
	await _ticks(2)
	_check(run.shrines_left == 1 and run.healed_spots.size() == Run.SHRINE_COUNT - 1, "Each broken shrine must count once and heal its ground.")
	_check(run.current_boss == null, "The sin must wait for the last shrine.")
	var healed_lights: int = 0
	for child: Node in run.get_children():
		if child.name.begins_with("HealedLight") and child.is_in_group(&"light"):
			healed_lights += 1
	_check(healed_lights == Run.SHRINE_COUNT - 1, "Each healed spot must carry a light (got %d)." % healed_lights)
	shrines[shrines.size() - 1].take_blow(1000)
	await _ticks(2)
	var boss: Boss = run.current_boss
	var horde_before: int = run.enemy_count
	boss._attack(Boss.Pattern.SUMMON)
	await _ticks(1)
	_check(run.enemy_count > horde_before, "The sin itself must still summon minions.")
	_check(run.shrines_left == 0 and boss != null and boss.boss_name.begins_with("PRIDE (") and boss.max_health >= int(Run.BOSSES[0]["health"]), "The last shrine must summon the full Pride boss.")
	_check(run.spawn_sin_boss() == null, "The sin must never be summoned twice.")
	countdown = run.shrine_time_left
	await _ticks(30)
	_check(run.shrine_time_left == countdown, "The countdown must stop once every shrine is broken.")

	# The sin's death opens a portal near it; the map is won but the run continues and scales.
	boss.position = Vector2(850, 800)
	boss.take_hit(boss.max_health)
	await _ticks(2)
	var portal: ExitPortal = run.exit_portal
	_check(run.sin_boss_defeated and portal != null and portal.position.distance_to(Vector2(850, 800)) < 100.0, "The slain sin must open a portal nearby.")
	_check(not run.ended and run.spawn_sin_boss() == null, "Winning must not end the run or summon again.")
	for at: Vector2 in [Vector2(-600, -400), Vector2(9000, 9000), Vector2.ZERO]:
		var safe: Vector2 = run._portal_position(at)
		_check(Run.ARENA_RECT.grow(-ExitPortal.RADIUS).has_point(safe) and not run._blocked_rect(safe.x, safe.y, ExitPortal.RADIUS), "Portal must clear arena and obstacles.")
	run.spawning_enabled = true
	var difficulty: float = run.difficulty()
	await _ticks(90)
	_check(run.enemy_count > 0 and run.difficulty() > difficulty, "After the sin falls, the horde must keep spawning and scaling.")
	var level: int = run.level
	run.add_xp(run.xp_needed())
	await _ticks(1)
	_check(run.level == level + 1 and paused, "The angel must keep leveling after the sin falls.")
	while run.pending_level_ups > 0:
		run.choose_upgrade(0)
	run.spawning_enabled = false
	# The sin's loot lies at the portal; a level-up from it would pause the hold below.
	for pickup: Node in run.pickups.get_children():
		pickup.free()

	# Leaving: holding E before arriving cannot confirm; a fresh nearby hold of 1 s does.
	Input.action_press(&"enter_portal")
	await _ticks(2)
	player.position = portal.position
	await _ticks(70)
	_check(not run.ended, "Arriving with E held must not leave.")
	Input.action_release(&"enter_portal")
	await _ticks(2)
	Input.action_press(&"enter_portal")
	await _ticks(15)
	Input.action_release(&"enter_portal")
	await _ticks(2)
	_check(portal.hold_left == 0.0 and not run.ended, "Releasing early must cancel leaving.")
	Input.action_press(&"enter_portal")
	await _ticks(70)
	Input.action_release(&"enter_portal")
	_check(run.ended and run.victory, "Leaving through the portal must win the map.")
	await _ticks(roundi(Run.ASCENT_TIME * 60.0) + 10)
	_check(run.hud.end_label.text.begins_with("THE REALM OF PRIDE IS SAVED"), "The ascension must end on the saved realm (got %s)." % run.hud.end_label.text)
	paused = false
	run.queue_free()
	await _ticks(2)

	# Running out of time with shrines standing kills the angel, even while protected.
	var late: Run = _new_run()
	late.shrine_time = 0.3
	late.shrine_time_left = 0.3
	late.player.invulnerable_left = 100000.0
	await _ticks(30)
	_check(late.player.is_dead and late.ended and not late.victory, "The countdown must kill the angel while shrines stand.")
	await _ticks(roundi(Run.FALL_TIME * 60.0) + 10)
	_check(late.hud.end_label.text.begins_with("THE SHRINES OUTLASTED YOU"), "The defeat must name the countdown.")
	late.queue_free()
	await _ticks(15)
	if failures == 0:
		print("Shrine smoke passed: difficulty scaling, pentagram shrines with leashed guards, player-only shrine blows, countdown, healing, sin summoned once, portal win, post-boss scaling and leveling, countdown death.")
	quit(1 if failures > 0 else 0)
