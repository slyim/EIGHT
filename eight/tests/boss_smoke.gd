extends SceneTree
## Boss redesigns, one sin at a time. Pride: phase one is the aimed fan and the charge; at half
## health it poses (standing, still hittable) and adds a guard stance that blocks front blows
## (heavy blows break it and open a long punish window) and ends in a slam around it that a
## grounded angel must leave or fly over. Guards fight with phase one only. Smarter tiers chain
## its charges and turn some fans into violet air fans. Wrath: two charges and a slam where it
## stops; enraged at half health (faster, a burst after each charge); shockwave rings at a fifth.
## Smarter Wrath re-aims its second charge and summons bombers once enraged. Native Godot only.

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


func _settle() -> void:
	while Engine.time_scale < 1.0:
		await process_frame


func _new_run(tier: int, sin: int = 0) -> Run:
	var run: Run = load("res://scenes/run.tscn").instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	run.tier = tier
	run.sin_index = sin
	root.add_child(run)
	current_scene = run
	return run


## Pride, standing still, on open ground beside the angel.
func _pride(run: Run) -> Boss:
	for guard: Boss in run.guards.duplicate():
		guard.queue_free()
	var boss: Boss = run._make_boss()
	boss.speed = 0.0
	boss.attack_left = 999.0
	run.actors.add_child(boss)
	boss.global_position = Vector2(-1800.0, 1600.0)
	run.player.global_position = boss.global_position + Vector2(200.0, 0.0)
	return boss


func _take_off(player: MountedPlayer) -> void:
	Input.action_press(&"jump")
	for tick: int in range(60):
		await _ticks(1)
		if player.is_airborne():
			return


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var run: Run = _new_run(0)
	await _ticks(3)
	var player: MountedPlayer = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	_check(run.guards[0].phase_patterns.is_empty() and not run.guards[0].patterns.has(Boss.Pattern.GUARD), "Pride's guards must fight with phase one only.")
	var boss: Boss = _pride(run)
	await _ticks(2)
	_check(boss.patterns.size() == 2 and boss.patterns.has(Boss.Pattern.AIMED) and boss.patterns.has(Boss.Pattern.CHARGE), "Phase one is the fan and the charge (%s)." % [boss.patterns])

	# 1. Half health: a pose (standing, hittable), then phase two's patterns.
	boss.start_attack(Boss.Pattern.AIMED)
	boss.take_hit(boss.max_health / 2 + 1)
	_check(boss.phase == 2 and boss.pose_left > 0.0 and boss.windup_left == 0.0 and boss.patterns.has(Boss.Pattern.GUARD), "Half health must pose, call off the attack, and add the guard (%s)." % [boss.patterns])
	var health: int = boss.health
	boss.take_hit(1)
	_check(boss.health == health - 1, "A posing boss must still take hits.")
	boss.speed = 200.0
	var held: Vector2 = boss.global_position
	await _ticks(10)
	_check(boss.global_position.distance_to(held) < 0.5, "A posing boss must stand.")
	await _ticks(int(Boss.PHASE_POSE * 60.0))
	boss.speed = 0.0
	_check(boss.pose_left <= 0.0, "The pose must end.")

	# 2. The guard stance blocks front blows, lets side and rear blows land, then slams.
	boss.start_attack(Boss.Pattern.GUARD)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.GUARD] * 60.0) + 2)
	_check(boss.guard_left > 0.0, "The guard stance must rise after its tell.")
	health = boss.health
	boss.take_hit(3)
	_check(boss.health == health and boss.blocked_last, "A front blow must be blocked by the guard.")
	boss.take_hit(3, false, boss.global_position + Vector2(-60.0, 0.0))
	_check(boss.health == health - 3, "A blow from behind must land through the guard.")
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.GUARD_TIME * 60.0) + 2)
	_check(boss.pending == Boss.Pattern.SLAM or boss.slam_flash_left > 0.0, "The guard must end in a slam.")
	player.global_position = boss.global_position + Vector2(80.0, 0.0)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.SLAM] * 60.0) + 2)
	_check(player.health < health, "The slam must hit a grounded angel inside it.")
	player.invulnerable_left = 100000.0
	await _settle()
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.SLAM] * 60.0) + 2)
	# A flying angel clears the slam.
	boss.start_attack(Boss.Pattern.SLAM)
	await _take_off(player)
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.SLAM] * 60.0) + 2)
	_check(player.is_airborne() and player.health == health, "Flying must clear the slam.")
	Input.action_release(&"jump")
	player.invulnerable_left = 100000.0
	await _ticks(40)
	# A heavy front blow breaks the guard: it lands, no slam follows, and the boss stays open.
	boss.start_attack(Boss.Pattern.GUARD)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.GUARD] * 60.0) + 2)
	var started: Array[int] = []
	var watch: Callable = func(attacker: Boss) -> void: started.append(attacker.pending)
	boss.attacked.connect(watch)
	health = boss.health
	boss.take_hit(4, true)
	_check(boss.health == health - 4 and boss.guard_left == 0.0 and boss.recover_left >= Boss.GUARD_BROKEN_RECOVERY - 0.02, "A heavy blow must break the guard and open the boss.")
	for tick: int in range(int(Boss.GUARD_BROKEN_RECOVERY * 60.0) + 2):
		await _ticks(1)
		_check(boss.slam_flash_left <= 0.0, "A broken guard must never slam.")
	_check(not started.has(Boss.Pattern.SLAM), "A broken guard must not start a slam (%s)." % [started])
	# A heavy blow from behind breaks it too.
	boss.start_attack(Boss.Pattern.GUARD)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.GUARD] * 60.0) + 2)
	boss.take_hit(2, true, boss.global_position - boss.guard_facing * 60.0)
	_check(boss.guard_left == 0.0 and boss.recover_left > 1.0, "A heavy blow from behind must break the guard too.")
	boss.attacked.disconnect(watch)
	await _ticks(int(Boss.GUARD_BROKEN_RECOVERY * 60.0) + 2)
	# With no angel to judge from, a plain blow on a guard simply lands (no error).
	boss.start_attack(Boss.Pattern.GUARD)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.GUARD] * 60.0) + 2)
	var angel: MountedPlayer = boss.target
	boss.target = null
	health = boss.health
	boss.take_hit(1)
	_check(boss.health == health - 1, "A guard with no target must not block or fail.")
	boss.target = angel
	run.queue_free()
	await _ticks(2)

	# 3. Smarter Pride: Purgatory chains its charge; Damnation adds violet air fans.
	run = _new_run(0)
	await _ticks(3)
	boss = _pride(run)
	_check(not boss.combos.has(Boss.Pattern.CHARGE) and not boss.air_fans, "Penance Pride must not be smarter.")
	run.queue_free()
	await _ticks(2)
	run = _new_run(1)
	await _ticks(3)
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	boss = _pride(run)
	_check(boss.combos.get(Boss.Pattern.CHARGE, []) == [Boss.Pattern.CHARGE] and not boss.air_fans, "Purgatory Pride must chain its charges.")
	await _ticks(2)
	var pride_anchor: Vector2 = player.global_position
	boss.start_attack(Boss.Pattern.CHARGE)
	await _ticks(2)
	player.global_position = pride_anchor + Vector2(0.0, 160.0)
	await _ticks(int((Boss.WINDUPS[Boss.Pattern.CHARGE] + Boss.CHARGE_TIME) * 60.0) + 1)
	var pride_aim: Vector2 = (player.global_position - boss.global_position).normalized()
	_check(boss.pending == Boss.Pattern.CHARGE and boss.windup_left > 0.0 and boss.combo_queue.is_empty() and boss.charge_direction.dot(pride_aim) > 0.99, "A chained charge must show a fresh lane, re-aimed at the angel.")
	await _ticks(int((Boss.WINDUPS[Boss.Pattern.CHARGE] + Boss.CHARGE_TIME) * 60.0) + 3)
	_check(boss.recover_left > 0.0, "After the chain the boss must rest.")
	run.queue_free()
	await _ticks(2)
	run = _new_run(2)
	await _ticks(3)
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	boss = _pride(run)
	_check(boss.air_fans, "Damnation Pride must use air fans.")
	await _ticks(2)
	for attempt: int in range(40):
		boss.start_attack(Boss.Pattern.AIMED)
		if boss.fan_from_air:
			break
		boss._cancel()
	_check(boss.fan_from_air and boss.get_meta(&"light") == Boss.AIR_TELEGRAPH_LIGHT, "Some fans must come from the air, lit violet.")
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.AIMED] * 60.0) + 2)
	var shots: Array[Node] = get_nodes_in_group(&"enemy_projectiles")
	_check(shots.size() == 5 and shots.all(func(shot: Node) -> bool: return (shot as EnemyProjectile).from_air and (shot as EnemyProjectile).material.resource_path.ends_with("enemy_air_ammo.tres")), "An air fan's shots must reach a flying angel and glow violet (%d)." % shots.size())

	run.queue_free()
	await _ticks(2)

	# 4. Wrath: two charges, then a slam where it stops.
	run = _new_run(0, 5)
	await _ticks(3)
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	boss = _pride(run)
	_check(boss.patterns == [Boss.Pattern.CHARGE] and boss.combos.get(Boss.Pattern.CHARGE, []) == [Boss.Pattern.CHARGE, Boss.Pattern.SLAM] and boss.phase_thresholds == [0.5, 0.2] and is_equal_approx(boss.slam_radius, 90.0), "Wrath must open with its charge combo (%s, %s)." % [boss.patterns, boss.combos])
	var wrath_guard: Boss = run.guards[0]
	_check(wrath_guard.phase_thresholds.is_empty() and wrath_guard.phase_combos.is_empty() and wrath_guard.combos.is_empty(), "Wrath's guards must keep phase one with no phases or combos.")
	wrath_guard.start_attack(Boss.Pattern.CHARGE)
	_check(wrath_guard.combo_queue.is_empty(), "A guard's charge must not open a combo.")
	wrath_guard._cancel()
	# A normally built Wrath keeps its tier-scaled spawn speed as the base the enrage scales.
	var plain: Boss = run._make_boss()
	var spawn_speed: float = plain.speed
	run.actors.add_child(plain)
	await _ticks(1)
	_check(spawn_speed > 0.0 and is_equal_approx(plain.base_speed, spawn_speed), "Wrath's base speed must be its spawn speed (%f vs %f)." % [plain.base_speed, spawn_speed])
	plain.queue_free()
	await _ticks(2)
	var anchor: Vector2 = player.global_position
	boss.start_attack(Boss.Pattern.CHARGE)
	await _ticks(2)
	player.global_position = anchor + Vector2(0.0, 160.0)
	await _ticks(int((Boss.WINDUPS[Boss.Pattern.CHARGE] + Boss.CHARGE_TIME) * 60.0) + 1)
	var to_anchor: Vector2 = (anchor - boss.global_position).normalized()
	_check(boss.pending == Boss.Pattern.CHARGE and boss.charge_direction.dot(to_anchor) > 0.99, "Wrath's second charge must head for where the angel stood (%s vs %s)." % [boss.charge_direction, to_anchor])
	await _ticks(int((Boss.WINDUPS[Boss.Pattern.CHARGE] + Boss.CHARGE_TIME) * 60.0) + 1)
	_check(boss.pending == Boss.Pattern.SLAM and is_equal_approx(boss.windup_total, 0.5), "Wrath's charges must end in a quick slam.")
	player.global_position = boss.global_position + Vector2(70.0, 0.0)
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(0.5 * 60.0) + 2)
	_check(player.health < health and boss.recover_left > 0.0, "The slam must land, then Wrath rests.")
	player.invulnerable_left = 100000.0
	await _settle()
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.SLAM] * 60.0) + 2)

	# Half health: enraged (faster), and a burst follows each charge.
	# The helper stood the boss still; give it a real base speed to scale.
	boss.base_speed = 100.0
	var calm_speed: float = boss.base_speed
	boss.take_hit(boss.max_health / 2 + 1)
	_check(boss.phase == 2 and is_equal_approx(boss.speed, calm_speed * 1.2) and boss.combos.get(Boss.Pattern.CHARGE, []) == [Boss.Pattern.BURST, Boss.Pattern.CHARGE, Boss.Pattern.BURST, Boss.Pattern.SLAM], "Half health must enrage Wrath (%f, %s)." % [boss.speed, boss.combos])
	await _ticks(int(Boss.PHASE_POSE * 60.0) + 2)
	boss.speed = 0.0
	boss.start_attack(Boss.Pattern.CHARGE)
	await _ticks(int((Boss.WINDUPS[Boss.Pattern.CHARGE] + Boss.CHARGE_TIME) * 60.0) + 2)
	_check(boss.pending == Boss.Pattern.BURST, "An enraged charge must be followed by a burst.")
	boss._cancel()
	# A fifth: shockwaves join.
	boss.take_hit(boss.health - boss.max_health / 5 + 1)
	_check(boss.phase == 3 and boss.patterns.has(Boss.Pattern.SHOCKWAVE) and is_equal_approx(boss.attack_interval, boss.base_interval * 0.75), "At a fifth Wrath must add shockwaves without speeding up again (%s, %f)." % [boss.patterns, boss.attack_interval])
	await _ticks(int(Boss.PHASE_POSE * 60.0) + 2)
	# Phase three sped Wrath up again; hold it still so only the rings can hurt.
	boss.speed = 0.0
	boss.attack_left = 999.0
	player.global_position = boss.global_position + Vector2(150.0, 0.0)
	boss.start_attack(Boss.Pattern.SHOCKWAVE)
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.SHOCKWAVE] * 60.0) + 2)
	var waves: Array[Shockwave] = []
	for child: Node in run.actors.get_children():
		if child is Shockwave:
			waves.append(child)
	_check(waves.size() == 1, "A shockwave must roll out from Wrath.")
	var hits: int = 0
	var was: int = player.health
	for tick: int in range(90):
		await _ticks(1)
		if player.health < was:
			hits += 1
			was = player.health
			player.invulnerable_left = 0.0
	_check(hits == Shockwave.RINGS and player.health < health and waves[0].landed.all(func(done: bool) -> bool: return done), "All three rings must land once each on a grounded angel (%d)." % hits)
	player.invulnerable_left = 100000.0
	await _settle()
	await _ticks(90)
	_check(not is_instance_valid(waves[0]), "The rings must fade once they have rolled out.")
	# Flying over the rings clears them.
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.SHOCKWAVE] * 60.0) + 2)
	await _take_off(player)
	boss.start_attack(Boss.Pattern.SHOCKWAVE)
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.SHOCKWAVE] * 60.0) + 40)
	_check(player.is_airborne() and player.health == health, "Flying must clear the shockwave rings.")
	Input.action_release(&"jump")
	player.invulnerable_left = 100000.0
	run.queue_free()
	await _ticks(2)

	# Smarter Wrath: Purgatory re-aims its second charge; Damnation summons bombers once enraged.
	run = _new_run(1, 5)
	await _ticks(3)
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	boss = _pride(run)
	_check(boss.reaim_chains and not boss.patterns.has(Boss.Pattern.SUMMON), "Purgatory Wrath must re-aim between charges.")
	await _ticks(2)
	anchor = player.global_position
	boss.start_attack(Boss.Pattern.CHARGE)
	await _ticks(2)
	player.global_position = anchor + Vector2(0.0, 160.0)
	await _ticks(int((Boss.WINDUPS[Boss.Pattern.CHARGE] + Boss.CHARGE_TIME) * 60.0) + 1)
	var to_angel: Vector2 = (player.global_position - boss.global_position).normalized()
	_check(boss.pending == Boss.Pattern.CHARGE and boss.charge_direction.dot(to_angel) > 0.99, "A re-aimed second charge must head for the angel.")
	run.queue_free()
	await _ticks(2)
	run = _new_run(2, 5)
	await _ticks(3)
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	boss = _pride(run)
	_check(not boss.patterns.has(Boss.Pattern.SUMMON) and boss.phase_patterns[1].has(Boss.Pattern.SUMMON) and boss.summon_type == Run.BOMBER, "Damnation Wrath must summon bombers once enraged.")
	run.spawn_sin_boss()
	await _ticks(2)
	var sin_boss: Boss = run.current_boss
	sin_boss.attack_left = 999.0
	var horde: int = run.enemy_count
	sin_boss._attack(Boss.Pattern.SUMMON)
	await _ticks(1)
	var bombers: int = 0
	for actor: Node in run.actors.get_children():
		if actor is Bomber:
			bombers += 1
	_check(run.enemy_count > horde and bombers == run.enemy_count - horde, "Wrath's summons must be bombers (%d)." % bombers)

	await _settle()
	run.queue_free()
	await _ticks(30)
	print("boss_smoke: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
