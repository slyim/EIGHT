extends SceneTree
## Boss redesigns, one sin at a time. Pride: phase one is the aimed fan and the charge; at half
## health it poses (standing, still hittable) and adds a guard stance that blocks front blows
## (heavy blows break it and open a long punish window) and ends in a slam around it that a
## grounded angel must leave or fly over. Guards fight with phase one only. Smarter tiers chain
## its charges and turn some fans into violet air fans. Wrath: two charges and a slam where it
## stops; enraged at half health (faster, a burst after each charge); shockwave rings at a fifth.
## Smarter Wrath re-aims its second charge and summons bombers once enraged. Greed: coin rings
## with gaps either side of the angel and ground casters; violet air rain at 60%; spiralling coin
## volleys at a quarter. Smarter Greed adds a coin wave and leads its rain. Lust: charges and
## slow violet air kisses; at half health it blinks behind the angel and charges at once.
## Smarter Lust blinks twice and summons flyers past half health. Gluttony: leaps onto the
## angel's spot and leaves bile; at half health vomits and devours (pulls the angel and the horde
## in, eats horde enemies without healing, bites); at a fifth summons splitters. Smarter Gluttony
## leaps twice and leaves bile longer. Sloth: snores slow rings and spreads slowing sludge; at
## half health yawns (a huge slam) and naps; at a fifth wakes (tint, triple speed, charges).
## Smarter Sloth's sludge lasts longer and it rains after a yawn. Native Godot only.

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


## True when the shots are exactly one coin ring: every slot but the two gaps, aimed at aim and
## turned by turn, each slot once.
func _is_coin_ring(shots: Array[Node], aim: Vector2, turn: float) -> bool:
	var expected: Array[Vector2] = []
	for slot: int in range(Boss.COIN_SLOTS):
		if slot != Boss.COIN_GAP and slot != Boss.COIN_SLOTS - Boss.COIN_GAP:
			expected.append(aim.rotated(turn + TAU * slot / Boss.COIN_SLOTS))
	if shots.size() != expected.size():
		return false
	for direction: Vector2 in expected:
		var matches: int = 0
		for shot: Node in shots:
			if (shot as EnemyProjectile).velocity.normalized().dot(direction) > 0.999:
				matches += 1
		if matches != 1:
			return false
	return true


## The enemy shots fired since the last call (frees them so the next ring is counted alone).
func _take_shots() -> Array[Node]:
	var shots: Array[Node] = get_nodes_in_group(&"enemy_projectiles")
	var copy: Array[Node] = shots.duplicate()
	for shot: Node in shots:
		shot.remove_from_group(&"enemy_projectiles")
		shot.queue_free()
	return copy


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
	_check(boss.patterns == [Boss.Pattern.CHARGE, Boss.Pattern.AIMED] and boss.combos.get(Boss.Pattern.CHARGE, []) == [Boss.Pattern.CHARGE, Boss.Pattern.SLAM] and boss.phase_thresholds == [0.5, 0.2] and is_equal_approx(boss.slam_radius, 90.0), "Wrath must open with its charge combo and its fan (%s, %s)." % [boss.patterns, boss.combos])
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
	_check(not sin_boss.patterns.has(Boss.Pattern.SUMMON), "Damnation Wrath must not summon before its enrage.")
	run.queue_free()
	await _ticks(2)

	# 5. Greed: a coin ring with gaps either side of the angel, and ground casters.
	run = _new_run(0, 1)
	await _ticks(3)
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	_check(run.guards[0].patterns == [Boss.Pattern.COINS] and run.guards[0].combos.is_empty(), "Greed's guards must only throw coins (%s)." % [run.guards[0].patterns])
	boss = _pride(run)
	_check(boss.patterns == [Boss.Pattern.COINS, Boss.Pattern.SUMMON] and boss.summon_type == Run.CASTER and boss.phase_thresholds == [0.6, 0.25], "Greed must open with coins and casters (%s)." % [boss.patterns])
	await _ticks(2)
	boss.start_attack(Boss.Pattern.COINS)
	var aim: Vector2 = boss.charge_direction
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.COINS] * 60.0) + 2)
	var coins: Array[Node] = _take_shots()
	_check(_is_coin_ring(coins, aim, 0.0), "A coin ring must fill every slot but the gap either side of the angel (%d coins)." % coins.size())
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.COINS] * 60.0) + 2)
	run.spawn_sin_boss()
	await _ticks(2)
	var greed: Boss = run.current_boss
	greed.attack_left = 999.0
	horde = run.enemy_count
	greed._attack(Boss.Pattern.SUMMON)
	await _ticks(1)
	var casters: int = 0
	for actor: Node in run.actors.get_children():
		if actor is GroundCaster and not actor is Mortar and not actor is Mirror:
			casters += 1
	_check(run.enemy_count > horde and casters == run.enemy_count - horde, "Greed's summons must be ground casters (%d)." % casters)
	greed.queue_free()
	# The casters would fire into the coin counts below.
	for actor: Node in run.actors.get_children():
		if actor is GroundCaster:
			actor.queue_free()
	# 60%: violet rain around the angel, landing one after another, reaching it in the air.
	boss.take_hit(boss.max_health - roundi(boss.max_health * 0.6) + 1)
	_check(boss.phase == 2 and boss.patterns.has(Boss.Pattern.RAIN), "At 60%% Greed must add rain (%s)." % [boss.patterns])
	await _ticks(int(Boss.PHASE_POSE * 60.0) + 2)
	boss.attack_left = 999.0
	await _take_off(player)
	boss.start_attack(Boss.Pattern.RAIN)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.RAIN] * 60.0) + 2)
	var drops: Array[GroundStrike] = []
	for child: Node in run.actors.get_children():
		if child is GroundStrike:
			drops.append(child)
	_check(drops.size() == Boss.RAIN_SPOTS.size() and drops.all(func(drop: GroundStrike) -> bool: return drop.from_air) and drops[1].delay > drops[0].delay, "Rain must mark five staggered air circles (%d)." % drops.size())
	_check(drops[0].global_position.distance_to(player.global_position) < 1.0, "Rain must fall around the angel.")
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.RAIN_DELAY * 60.0) + 2)
	_check(player.is_airborne() and player.health < health, "Rain must reach a flying angel.")
	Input.action_release(&"jump")
	player.invulnerable_left = 100000.0
	await _settle()
	await _ticks(60)
	# A quarter: coin volleys spiral (three rings, each turned half a slot).
	boss.take_hit(boss.health - roundi(boss.max_health * 0.25) + 1)
	_check(boss.phase == 3 and boss.combos.get(Boss.Pattern.COINS, []) == [Boss.Pattern.COINS, Boss.Pattern.COINS], "At a quarter Greed's coins must spiral (%s)." % [boss.combos])
	await _ticks(int(Boss.PHASE_POSE * 60.0) + 2)
	boss.attack_left = 999.0
	_take_shots()
	boss.start_attack(Boss.Pattern.COINS)
	var spiral_aim: Vector2 = boss.charge_direction
	# The angel moves between rings; a spiral keeps its aim and only turns.
	for ring: int in range(3):
		await _ticks(int(Boss.WINDUPS[Boss.Pattern.COINS] * 60.0) + 1)
		var volley: Array[Node] = _take_shots()
		_check(_is_coin_ring(volley, spiral_aim, ring * PI / Boss.COIN_SLOTS), "Spiral ring %d must be the volley's ring turned %d half-slots (%d coins)." % [ring + 1, ring, volley.size()])
		player.global_position += Vector2(0.0, 40.0)
	boss._cancel()
	run.queue_free()
	await _ticks(2)

	# Smarter Greed: Purgatory adds a coin wave; Damnation leads its rain.
	run = _new_run(1, 1)
	await _ticks(3)
	boss = _pride(run)
	_check(boss.phase_combos.size() == 3 and boss.phase_combos[0].get(Boss.Pattern.COINS, []) == [Boss.Pattern.COINS] and boss.phase_combos[1].get(Boss.Pattern.COINS, []) == [Boss.Pattern.COINS] and boss.phase_combos[2].get(Boss.Pattern.COINS, []) == [Boss.Pattern.COINS, Boss.Pattern.COINS, Boss.Pattern.COINS] and not boss.lead_rain, "Purgatory Greed must add one coin wave in every phase (%s)." % [boss.phase_combos])
	run.queue_free()
	await _ticks(2)
	run = _new_run(2, 1)
	await _ticks(3)
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	boss = _pride(run)
	_check(boss.lead_rain, "Damnation Greed must lead its rain.")
	await _ticks(2)
	Input.action_press(&"move_right")
	await _ticks(3)
	boss._attack(Boss.Pattern.RAIN)
	var lead_center: Vector2 = player.global_position + player.velocity.limit_length(player.movement_speed) * Boss.RAIN_LEAD
	Input.action_release(&"move_right")
	var first: GroundStrike = null
	for child: Node in run.actors.get_children():
		if child is GroundStrike:
			first = child
			break
	_check(first != null and first.global_position.distance_to(lead_center) < 1.0 and player.velocity.length() > 100.0, "A leading rain must land where the angel is heading.")
	for child: Node in run.actors.get_children():
		if child is GroundStrike:
			child.free()
	# A dash does not throw the rain across the arena: the lead is capped at walking speed.
	await _ticks(30)
	player.dash_cooldown_left = 0.0
	player.dash_direction = Vector2.RIGHT
	Input.action_press(&"dash")
	await _ticks(2)
	Input.action_release(&"dash")
	var dashing: float = player.velocity.length()
	var from: Vector2 = player.global_position
	boss._attack(Boss.Pattern.RAIN)
	var dash_drop: GroundStrike = null
	for child: Node in run.actors.get_children():
		if child is GroundStrike:
			dash_drop = child
			break
	_check(dashing > player.movement_speed * 1.5 and dash_drop != null and dash_drop.global_position.distance_to(from) <= player.movement_speed * Boss.RAIN_LEAD + 1.0, "A dash must not throw the rain further than walking would (%f)." % (dash_drop.global_position.distance_to(from) if dash_drop != null else -1.0))
	run.queue_free()
	await _ticks(2)

	# 6. Lust: kisses are three slow violet air shots.
	run = _new_run(0, 2)
	await _ticks(3)
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	boss = _pride(run)
	_check(boss.patterns == [Boss.Pattern.CHARGE, Boss.Pattern.KISSES] and boss.reaim_chains, "Lust must open with its charge and kisses (%s)." % [boss.patterns])
	await _ticks(2)
	_take_shots()
	boss.start_attack(Boss.Pattern.KISSES)
	_check(boss.fan_from_air and boss.get_meta(&"light") == Boss.AIR_TELEGRAPH_LIGHT, "Kisses must be told in violet.")
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.KISSES] * 60.0) + 1)
	var kisses: Array[Node] = _take_shots()
	_check(kisses.size() == Boss.KISS_COUNT and kisses.all(func(kiss: Node) -> bool: return (kiss as EnemyProjectile).from_air and is_equal_approx((kiss as EnemyProjectile).velocity.length(), Boss.KISS_SPEED)), "Kisses must be three slow air shots (%d)." % kisses.size())
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.KISSES] * 60.0) + 2)
	# Half health: a blink behind the angel, then a quick charge straight at it.
	boss.take_hit(boss.max_health / 2 + 1)
	_check(boss.phase == 2 and boss.patterns.has(Boss.Pattern.BLINK) and boss.combos.get(Boss.Pattern.BLINK, []) == [Boss.Pattern.CHARGE], "At half health Lust must add its blink (%s)." % [boss.patterns])
	await _ticks(int(Boss.PHASE_POSE * 60.0) + 2)
	boss.attack_left = 999.0
	var before: Vector2 = boss.global_position
	boss.start_attack(Boss.Pattern.BLINK)
	var spot: Vector2 = boss.blink_spot
	var side: Vector2 = player.global_position - before
	_check(is_equal_approx(spot.distance_to(player.global_position), Boss.BLINK_BEHIND) and (spot - player.global_position).dot(side) > 0.0, "A blink must mark a circle behind the angel (%s)." % spot)
	_check(not boss.is_in_group(&"light") or boss.get_meta(&"light") != Boss.TELEGRAPH_LIGHT, "A blink is not an attack, so it casts no ember light.")
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.BLINK] * 60.0) + 1)
	_check(boss.global_position.distance_to(spot) < 1.0, "Lust must appear on its blink circle.")
	var at_angel: Vector2 = (player.global_position - boss.global_position).normalized()
	_check(boss.pending == Boss.Pattern.CHARGE and is_equal_approx(boss.windup_total, 0.5) and boss.charge_direction.dot(at_angel) > 0.99, "A blink must lead straight into a quick charge at the angel.")
	boss._cancel()
	await _ticks(2)
	# Walking onto the marked circle calls the blink off: no landing on the angel, no charge.
	boss.start_attack(Boss.Pattern.BLINK)
	var marked: Vector2 = boss.blink_spot
	var stayed: Vector2 = boss.global_position
	player.global_position = marked
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.BLINK] * 60.0) + 2)
	_check(boss.global_position.distance_to(stayed) < 1.0 and boss.pending != Boss.Pattern.CHARGE and player.health == health, "A blink onto the angel must be called off (moved %f)." % boss.global_position.distance_to(stayed))
	player.invulnerable_left = 100000.0
	boss._cancel()
	# Against a wall, the blink lands on open ground inside the arena.
	boss.global_position = Vector2(Run.ARENA_RECT.position.x + 300.0, 0.0)
	player.global_position = Vector2(Run.ARENA_RECT.position.x + 60.0, 0.0)
	await _ticks(2)
	boss.start_attack(Boss.Pattern.BLINK)
	_check(Run.ARENA_RECT.grow(-boss.radius).has_point(boss.blink_spot) and boss.blink_spot.x > player.global_position.x, "A blink toward a wall must land in front instead (%s)." % boss.blink_spot)
	boss._cancel()
	run.queue_free()
	await _ticks(2)

	# Smarter Lust: Purgatory blinks twice; Damnation summons flyers past half health.
	run = _new_run(1, 2)
	await _ticks(3)
	boss = _pride(run)
	_check(boss.phase_combos[1].get(Boss.Pattern.BLINK, []) == [Boss.Pattern.CHARGE, Boss.Pattern.BLINK, Boss.Pattern.CHARGE], "Purgatory Lust must blink twice (%s)." % [boss.phase_combos])
	# Run the whole chain: two blinks and two charges, each behind its own tell.
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	await _ticks(2)
	boss.take_hit(boss.max_health / 2 + 1)
	await _ticks(int(Boss.PHASE_POSE * 60.0) + 2)
	boss.attack_left = 999.0
	var steps: Array[int] = []
	var record: Callable = func(attacker: Boss) -> void: steps.append(attacker.pending)
	boss.attacked.connect(record)
	boss.start_attack(Boss.Pattern.BLINK)
	for tick: int in range(300):
		await _ticks(1)
		if boss.recover_left > 0.0:
			break
	boss.attacked.disconnect(record)
	_check(steps == [Boss.Pattern.BLINK, Boss.Pattern.CHARGE, Boss.Pattern.BLINK, Boss.Pattern.CHARGE], "Purgatory Lust must blink, charge, blink, charge (%s)." % [steps])
	run.queue_free()
	await _ticks(2)
	run = _new_run(2, 2)
	await _ticks(3)
	player = run.player
	player.invulnerable_left = 100000.0
	boss = _pride(run)
	_check(not boss.patterns.has(Boss.Pattern.SUMMON) and boss.phase_patterns[1].has(Boss.Pattern.SUMMON) and boss.summon_type == Run.FLYER, "Damnation Lust must summon flyers past half health (%s)." % [boss.patterns])
	run.spawn_sin_boss()
	await _ticks(2)
	var lust: Boss = run.current_boss
	lust.attack_left = 999.0
	horde = run.enemy_count
	lust._attack(Boss.Pattern.SUMMON)
	await _ticks(1)
	var flyers: int = 0
	for actor: Node in run.actors.get_children():
		if actor is FlyingEnemy and not actor is GroundCaster:
			flyers += 1
	_check(run.enemy_count > horde and flyers == run.enemy_count - horde, "Lust's summons must be flyers (%d)." % flyers)
	run.queue_free()
	await _ticks(2)

	# 7. Gluttony: a leap onto the angel's spot, leaving bile.
	run = _new_run(0, 4)
	await _ticks(3)
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	boss = _pride(run)
	_check(boss.patterns == [Boss.Pattern.LEAP, Boss.Pattern.VOMIT] and boss.summon_type == Run.SPLITTER and boss.phase_thresholds == [0.5, 0.2], "Gluttony must open with its leap and vomit (%s)." % [boss.patterns])
	await _ticks(2)
	boss.start_attack(Boss.Pattern.LEAP)
	var landing: Vector2 = boss.leap_spot
	_check(landing.distance_to(player.global_position) < 1.0, "A leap must mark where the angel stands.")
	player.global_position = landing + Vector2(0.0, 200.0)
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.LEAP] * 60.0) + 2)
	var bile: BileZone = null
	for child: Node in run.actors.get_children():
		if child is BileZone:
			bile = child
	_check(boss.flash_radius == Boss.LEAP_RADIUS and boss.slam_flash_left > 0.0, "The landing flash must cover the leap's circle.")
	_check(boss.global_position.distance_to(landing) < 1.0 and bile != null and bile.global_position.distance_to(landing) < 1.0 and is_equal_approx(bile.lifetime, 4.0), "Gluttony must land on the mark and leave bile.")
	_check(player.health == health, "An angel who left the circle must be safe.")
	# Walking into the bile hurts; flying over it does not.
	player.global_position = landing + Vector2(40.0, 0.0)
	await _ticks(3)
	_check(player.health < health, "Bile must hurt a grounded angel in it.")
	player.invulnerable_left = 100000.0
	await _settle()
	player.global_position = landing + Vector2(0.0, 300.0)
	await _take_off(player)
	player.global_position = landing + Vector2(40.0, 0.0)
	player.invulnerable_left = 0.0
	health = player.health
	# Longer than one bile tick, so the puddle surely checks the angel.
	await _ticks(int(BileZone.TICK * 60.0) + 10)
	_check(player.is_airborne() and player.health == health and is_instance_valid(bile) and bile.global_position.distance_to(player.global_position) < bile.radius, "Flying over bile must be safe (airborne %s, bile %s, %d)." % [player.is_airborne(), is_instance_valid(bile), health - player.health])
	Input.action_release(&"jump")
	player.invulnerable_left = 100000.0
	player.global_position = landing + Vector2(0.0, 300.0)
	await _ticks(40)
	# A leap landing on the angel hurts.
	boss.attack_left = 999.0
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.LEAP] * 60.0) + 2)
	boss.start_attack(Boss.Pattern.LEAP)
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.LEAP] * 60.0) + 2)
	_check(player.health < health, "A leap must hurt an angel still in its circle.")
	player.invulnerable_left = 100000.0
	await _settle()
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.LEAP] * 60.0) + 2)
	for child: Node in run.actors.get_children():
		if child is BileZone:
			child.queue_free()

	# Half health: a wide vomit fan and the devour.
	boss.take_hit(boss.max_health / 2 + 1)
	_check(boss.phase == 2 and boss.patterns.has(Boss.Pattern.DEVOUR), "At half health Gluttony must devour (%s)." % [boss.patterns])
	await _ticks(int(Boss.PHASE_POSE * 60.0) + 2)
	boss.attack_left = 999.0
	boss.speed = 0.0
	_take_shots()
	boss.start_attack(Boss.Pattern.VOMIT)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.VOMIT] * 60.0) + 1)
	_check(_take_shots().size() == Boss.VOMIT_COUNT, "Vomit must be a fan of nine shots.")
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.VOMIT] * 60.0) + 2)
	# The devour pulls the angel in, eats horde enemies (no kill, no heal), and bites.
	player.global_position = boss.global_position + Vector2(220.0, 0.0)
	var prey: Enemy = run.spawn_enemy(Run.HUSK, boss.global_position + Vector2(140.0, 20.0))
	prey.speed = 0.0
	await _ticks(1)
	var gluttony_health: int = boss.health
	var kills: int = run.kills
	horde = run.enemy_count
	boss.start_attack(Boss.Pattern.DEVOUR)
	_check(boss.get_meta(&"light") == Boss.AIR_TELEGRAPH_LIGHT, "The devour must be told in violet (it reaches the air).")
	var start_gap: float = player.global_position.distance_to(boss.global_position)
	await _ticks(int((Boss.WINDUPS[Boss.Pattern.DEVOUR] + 0.6) * 60.0))
	_check(boss.devour_left > 0.0 and player.global_position.distance_to(boss.global_position) < start_gap - 40.0, "The inhale must pull the angel toward the mouth.")
	await _ticks(30)
	_check(not is_instance_valid(prey) and run.enemy_count == horde - 1 and run.kills == kills and boss.health == gluttony_health, "Prey reaching the mouth must be eaten: no kill, no heal (valid %s, count %d vs %d, kills %d vs %d, health %d vs %d)." % [is_instance_valid(prey), run.enemy_count, horde - 1, run.kills, kills, boss.health, gluttony_health])
	# The bite reaches the air (Gluttony's body does not), so a flying angel at the mouth tells
	# the bite apart from plain contact.
	await _take_off(player)
	player.global_position = boss.global_position + Vector2(boss.radius + 30.0, 0.0)
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.DEVOUR_TIME * 60.0))
	_check(player.is_airborne() and player.health == health - roundi(boss.contact_damage * Boss.BITE_SCALE) and boss.devour_left <= 0.0, "The closing bite must hurt an angel at the mouth, even in the air (%d)." % (health - player.health))
	Input.action_release(&"jump")
	player.invulnerable_left = 100000.0
	await _ticks(30)
	await _settle()
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.DEVOUR] * 60.0) + 2)
	# A dash is not pulled.
	player.global_position = boss.global_position + Vector2(220.0, 0.0)
	boss.start_attack(Boss.Pattern.DEVOUR)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.DEVOUR] * 60.0) + 2)
	player.dash_cooldown_left = 0.0
	player.pull = Vector2.ZERO
	Input.action_press(&"move_right")
	Input.action_press(&"dash")
	await _ticks(2)
	Input.action_release(&"dash")
	Input.action_release(&"move_right")
	_check(player.dash_time_left > 0.0 and player.velocity.x > player.dash_speed - 1.0, "A dash must escape the pull at full speed (%s)." % player.velocity)
	boss._cancel()
	# A fifth: splitters join.
	boss.take_hit(boss.health - boss.max_health / 5 + 1)
	_check(boss.phase == 3 and boss.patterns.has(Boss.Pattern.SUMMON), "At a fifth Gluttony must summon (%s)." % [boss.patterns])
	run.queue_free()
	await _ticks(2)

	# Smarter Gluttony: Purgatory leaps twice; Damnation's bile lasts longer.
	run = _new_run(1, 4)
	await _ticks(3)
	boss = _pride(run)
	_check(boss.phase_combos.size() == 3 and boss.phase_combos.all(func(combo: Dictionary) -> bool: return combo.get(Boss.Pattern.LEAP, []) == [Boss.Pattern.LEAP]) and is_equal_approx(boss.bile_time, 4.0), "Purgatory Gluttony must leap twice in every phase (%s)." % [boss.phase_combos])
	await _ticks(2)
	boss.start_attack(Boss.Pattern.LEAP)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.LEAP] * 60.0) + 1)
	_check(boss.pending == Boss.Pattern.LEAP and is_equal_approx(boss.windup_total, Boss.CHAINED_LEAP_WINDUP), "The second leap must be told for less time (%f)." % boss.windup_total)
	boss._cancel()
	run.queue_free()
	await _ticks(2)
	run = _new_run(2, 4)
	await _ticks(3)
	boss = _pride(run)
	_check(is_equal_approx(boss.bile_time, 6.0), "Damnation Gluttony's bile must last longer.")
	run.queue_free()
	await _ticks(2)

	# 8. Sloth: a slow snore ring and slowing sludge.
	run = _new_run(0, 6)
	await _ticks(3)
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	boss = _pride(run)
	_check(boss.patterns == [Boss.Pattern.SNORE, Boss.Pattern.SLUDGE] and boss.phase_thresholds == [0.65, 0.25], "Sloth must open with snores and sludge (%s)." % [boss.patterns])
	# The landing site is always open ground, so no shot starts inside an obstacle.
	boss.global_position = Vector2.ZERO
	player.global_position = Vector2(200.0, 0.0)
	await _ticks(2)
	_take_shots()
	var snore_aim: Vector2 = (player.global_position - boss.global_position).normalized()
	boss.start_attack(Boss.Pattern.SNORE)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.SNORE] * 60.0) + 1)
	var snores: Array[Node] = _take_shots()
	_check(snores.size() == Boss.SNORE_COUNT and snores.all(func(shot: Node) -> bool: return is_equal_approx((shot as EnemyProjectile).velocity.length(), Boss.SNORE_SPEED)) and snores.any(func(shot: Node) -> bool: return (shot as EnemyProjectile).velocity.normalized().dot(snore_aim) > 0.999), "A snore must be a slow ring with one shot at the angel (%d)." % snores.size())
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.SNORE] * 60.0) + 2)
	var sludge_center: Vector2 = player.global_position
	boss.start_attack(Boss.Pattern.SLUDGE)
	player.global_position = sludge_center + Vector2(0.0, 320.0)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.SLUDGE] * 60.0) + 2)
	var pools: Array[BileZone] = []
	for child: Node in run.actors.get_children():
		if child is BileZone:
			pools.append(child)
	_check(pools.size() == Boss.SLUDGE_SPOTS.size() and pools.all(func(pool: BileZone) -> bool: return pool.slow_factor > 0.0 and is_equal_approx(pool.lifetime, 5.0)) and pools[0].global_position.distance_to(sludge_center) < 1.0, "Sludge must pool around where the angel stood (%d)." % pools.size())
	_check(player.slow_left <= 0.0, "An angel who left the marks must not be slowed.")
	player.global_position = sludge_center
	health = player.health
	await _ticks(3)
	_check(player.slow_left > 0.0 and is_equal_approx(player.slow_factor, Boss.SLUDGE_SLOW) and player.health == health, "Sludge must slow, not hurt.")
	player.slow_left = 0.0
	player.global_position = sludge_center + Vector2(0.0, 300.0)
	await _take_off(player)
	player.global_position = sludge_center
	await _ticks(5)
	_check(player.is_airborne() and player.slow_left <= 0.0, "Flying over sludge must not slow.")
	Input.action_release(&"jump")
	await _ticks(30)
	for pool: BileZone in pools:
		if is_instance_valid(pool):
			pool.queue_free()
	player.slow_left = 0.0
	# Sludge near a wall stays inside the arena and off the wall.
	boss.global_position = Vector2(Run.ARENA_RECT.position.x + 400.0, 0.0)
	player.global_position = Vector2(Run.ARENA_RECT.position.x + 30.0, 0.0)
	await _ticks(2)
	boss.start_attack(Boss.Pattern.SLUDGE)
	_check(boss.sludge_spots.all(func(spot: Vector2) -> bool: return Run.ARENA_RECT.grow(-Boss.SLUDGE_RADIUS).has_point(spot)), "Sludge must stay inside the arena (%s)." % [boss.sludge_spots])
	boss._cancel()
	boss.global_position = Vector2.ZERO
	player.global_position = Vector2(200.0, 0.0)
	await _ticks(2)
	# 65%: the yawn (a huge slam, fly over it), then a nap.
	boss.take_hit(boss.max_health - roundi(boss.max_health * 0.65) + 1)
	_check(boss.phase == 2 and boss.patterns.has(Boss.Pattern.YAWN) and boss.combos.get(Boss.Pattern.YAWN, []) == [Boss.Pattern.NAP], "At 65%% Sloth must yawn and nap (%s)." % [boss.combos])
	await _ticks(int(Boss.PHASE_POSE * 60.0) + 2)
	boss.attack_left = 999.0
	player.global_position = boss.global_position + Vector2(250.0, 0.0)
	boss.start_attack(Boss.Pattern.YAWN)
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.YAWN] * 60.0) + 2)
	_check(player.health < health, "A yawn must hit a grounded angel far out (250 px).")
	player.invulnerable_left = 100000.0
	_check(boss.pending == Boss.Pattern.NAP or boss.napping, "A yawn must lead into a nap.")
	await _ticks(10)
	boss.speed = 200.0
	var dozing: Vector2 = boss.global_position
	await _ticks(30)
	_check(boss.napping and boss.recover_left > 0.0 and boss.global_position.distance_to(dozing) < 0.5, "A napping Sloth must lie still, wide open.")
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.NAP] * 60.0))
	_check(not boss.napping, "The nap must end.")
	boss.speed = 0.0
	await _settle()
	# Flying clears the yawn.
	await _take_off(player)
	boss.attack_left = 999.0
	boss.start_attack(Boss.Pattern.YAWN)
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.YAWN] * 60.0) + 2)
	_check(player.is_airborne() and player.health == health, "Flying must clear the yawn (%d)." % (health - player.health))
	Input.action_release(&"jump")
	player.invulnerable_left = 100000.0
	boss._cancel()
	# A quarter: Sloth wakes.
	boss.base_speed = 40.0
	boss.take_hit(boss.health - boss.max_health / 4 + 1)
	_check(boss.phase == 3 and is_equal_approx(boss.speed, 100.0) and is_equal_approx(boss.attack_interval, boss.base_interval * 0.7) and boss.sprite.self_modulate != Color.WHITE and boss.patterns.has(Boss.Pattern.CHARGE) and not boss.patterns.has(Boss.Pattern.YAWN), "At a quarter Sloth must wake (%f, %f, %s)." % [boss.speed, boss.attack_interval, boss.patterns])
	run.queue_free()
	await _ticks(2)

	# Smarter Sloth: Purgatory's sludge lasts longer; Damnation rains after a yawn.
	run = _new_run(1, 6)
	await _ticks(3)
	boss = _pride(run)
	_check(is_equal_approx(boss.sludge_time, 7.0) and boss.phase_combos[1].get(Boss.Pattern.YAWN, []) == [Boss.Pattern.NAP], "Purgatory Sloth's sludge must last longer.")
	run.queue_free()
	await _ticks(2)
	run = _new_run(2, 6)
	await _ticks(3)
	boss = _pride(run)
	_check(boss.phase_combos[1].get(Boss.Pattern.YAWN, []) == [Boss.Pattern.RAIN, Boss.Pattern.NAP], "Damnation Sloth must rain after a yawn (%s)." % [boss.phase_combos])
	_check(not boss.patterns.has(Boss.Pattern.CHARGE) and boss.phase_patterns.all(func(list: Array) -> bool: return list.count(Boss.Pattern.CHARGE) <= 1) and not boss.phase_patterns[0].has(Boss.Pattern.CHARGE), "Sloth's tier extras must not bring its wake charge early (%s)." % [boss.phase_patterns])
	# The nap after the rain waits until the last drop has landed.
	player = run.player
	player.hit_stop_enabled = false
	player.invulnerable_left = 100000.0
	await _ticks(2)
	boss.take_hit(boss.max_health - roundi(boss.max_health * 0.65) + 1)
	await _ticks(int(Boss.PHASE_POSE * 60.0) + 2)
	boss.attack_left = 999.0
	boss.start_attack(Boss.Pattern.YAWN)
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.YAWN] * 60.0) + int(Boss.WINDUPS[Boss.Pattern.RAIN] * 60.0) + 4)
	var rain_done: float = Boss.RAIN_DELAY + Boss.RAIN_STAGGER * (Boss.RAIN_SPOTS.size() - 1)
	_check(boss.pending == Boss.Pattern.NAP and is_equal_approx(boss.windup_total, rain_done) and not boss.napping, "The nap must wait for the rain to land (%f)." % boss.windup_total)
	boss._cancel()

	await _settle()
	run.queue_free()
	await _ticks(30)
	print("boss_smoke: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
