extends SceneTree
## The first new enemy batch: each realm's mix brings its own types at their unlock times; the
## charger telegraphs a lane, dashes, and rests; the ground caster keeps its distance and fires
## ground shots that miss an airborne angel; the bomber lights a fuse and its blast hurts the
## angel and nearby ground enemies (not if slain first, and not an airborne angel); the
## splitter dies into two husks that never split, within the horde cap. Native Godot only.

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


## Holds Space until the angel is airborne (release with Input.action_release).
func _take_off(player: MountedPlayer) -> void:
	Input.action_press(&"jump")
	for tick: int in range(60):
		await _ticks(1)
		if player.is_airborne():
			return


func _new_run() -> Run:
	var run: Run = load("res://scenes/run.tscn").instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	return run


func _clear(run: Run) -> void:
	for actor: Node in run.actors.get_children():
		if actor is Enemy:
			actor.free()
	run.enemy_count = 0
	run.guards.clear()
	for shot: Node in get_nodes_in_group(&"enemy_projectiles"):
		shot.free()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var run: Run = _new_run()
	await _ticks(3)
	var player: MountedPlayer = run.player
	player.hit_stop_enabled = false
	_clear(run)

	# 1. The roster: each new type has its own behavior, and each realm brings its own.
	var kinds: Dictionary = {Run.CHARGER: Charger, Run.CASTER: GroundCaster, Run.BOMBER: Bomber,
		Run.SHIELDER: Shielder, Run.MORTAR: Mortar, Run.SLEEPER: Sleeper, Run.MIRROR: Mirror}
	for type_index: int in kinds:
		var sample: Enemy = run.spawn_enemy(type_index, Vector2(1500.0, 1500.0))
		_check(is_instance_of(sample, kinds[type_index]), "Roster entry %d must spawn its own enemy." % type_index)
	var splitter_sample: Enemy = run.spawn_enemy(Run.SPLITTER, Vector2(1500.0, 1500.0))
	_check(splitter_sample.has_meta(&"split"), "The splitter must carry its split rule.")
	_clear(run)
	run.set_physics_process(false)
	var homes: Dictionary = {Run.CHARGER: [0, 5, 7], Run.CASTER: [1, 2, 7], Run.BOMBER: [5, 7], Run.SPLITTER: [3, 4, 7],
		Run.SHIELDER: [0, 7], Run.MORTAR: [1, 6, 7], Run.SLEEPER: [6, 7], Run.MIRROR: [3, 7]}
	run.elapsed = 600.0
	for sin: int in range(Run.SATAN + 1):
		run.sin_index = sin
		var seen: Dictionary = {}
		for roll: int in range(800):
			seen[run._pick_enemy_type()] = true
		for type_index: int in homes:
			_check(seen.has(type_index) == (homes[type_index] as Array).has(sin), "Type %d must appear exactly on its realms (sin %d)." % [type_index, sin])
	# Staggered arrival: on Wrath, chargers come at 1:30 and bombers at 2:30.
	run.sin_index = 5
	for at: Array in [[80.0, false, false], [100.0, true, false], [160.0, true, true]]:
		run.elapsed = at[0]
		var seen: Dictionary = {}
		for roll: int in range(800):
			seen[run._pick_enemy_type()] = true
		_check(seen.has(Run.CHARGER) == at[1] and seen.has(Run.BOMBER) == at[2], "Wrath's chargers and bombers must arrive on time (at %d s: %s)." % [at[0], seen.keys()])
	for check: Array in [[1, Run.CASTER, 70.0, 80.0], [4, Run.SPLITTER, 115.0, 125.0], [6, Run.SLEEPER, 100.0, 110.0],
			[0, Run.SHIELDER, 130.0, 140.0], [1, Run.MORTAR, 115.0, 125.0], [3, Run.MIRROR, 175.0, 185.0]]:
		run.sin_index = check[0]
		for at: float in [check[2], check[3]]:
			run.elapsed = at
			var seen: Dictionary = {}
			for roll: int in range(800):
				seen[run._pick_enemy_type()] = true
			_check(seen.has(check[1]) == (at == check[3]), "Type %d must arrive on time on sin %d (at %d s)." % [check[1], check[0], at])
	run.elapsed = 0.0
	run.set_physics_process(true)

	# 2. The charger: lane, dash, rest.
	player.global_position = Vector2(-1800.0, 1600.0)
	player.invulnerable_left = 100000.0
	var charger: Charger = run.spawn_enemy(Run.CHARGER, player.global_position + Vector2(-200.0, 0.0)) as Charger
	await _ticks(3)
	_check(charger.windup_left > 0.0 and charger.dash_direction.x > 0.99 and charger.dash_length > 100.0, "A close charger must stop and show its lane (%f)." % charger.dash_length)
	var held: Vector2 = charger.global_position
	await _ticks(5)
	_check(charger.global_position.distance_to(held) < 0.5, "A winding charger must stand still.")
	await _ticks(int(Charger.WINDUP_TIME * 60.0))
	_check(charger.dash_left > 0.0 or charger.recover_left > 0.0, "The charger must dash after its wind-up.")
	await _ticks(int(Charger.DASH_TIME * 60.0) + 1)
	_check(charger.global_position.x > held.x + 100.0 and charger.recover_left > 0.0, "The dash must carry it along the lane into its rest.")
	var rest: Vector2 = charger.global_position
	await _ticks(10)
	_check(charger.global_position.distance_to(rest) < 0.5, "A resting charger must stand still.")
	await _ticks(int(Charger.RECOVER_TIME * 60.0))
	player.global_position = charger.global_position + Vector2(150.0, 0.0)
	await _ticks(5)
	_check(charger.windup_left <= 0.0 and charger.dash_left <= 0.0 and charger.cooldown_left > 0.0, "A charger must wait after its rest before the next lane.")
	await _ticks(int(Charger.COOLDOWN_TIME * 60.0) + 2)
	_check(charger.windup_left > 0.0 or charger.dash_left > 0.0, "After its cooldown the charger charges again.")
	# A lane toward a wall stops at the wall.
	charger.free()
	run.enemy_count = 0
	player.global_position = Vector2(Run.ARENA_RECT.position.x + 60.0, 0.0)
	var walled: Charger = run.spawn_enemy(Run.CHARGER, player.global_position + Vector2(140.0, 0.0)) as Charger
	await _ticks(3)
	_check(walled.windup_left > 0.0 and walled.dash_length < 200.0 - walled.radius, "A charger's lane must stop at a wall (%f)." % walled.dash_length)
	_clear(run)

	# 3. The ground caster: keeps away; ground shots miss an airborne angel.
	player.global_position = Vector2(-1800.0, 1600.0)
	var caster: GroundCaster = run.spawn_enemy(Run.CASTER, player.global_position + Vector2(80.0, 0.0)) as GroundCaster
	await _ticks(2)
	_check(not caster.flying and caster.collision_layer == 8 and caster.collision_mask == 1, "The caster must be a ground enemy that walls stop.")
	var close: float = caster.global_position.distance_to(player.global_position)
	await _ticks(20)
	_check(caster.global_position.distance_to(player.global_position) > close + 20.0, "The caster must back away to its distance.")
	_check(caster.sprite.position == caster.sprite_base and caster.lift == 0.0, "A walking caster must not bob.")
	caster.fire_left = 0.0
	await _ticks(2)
	var locked: Vector2 = caster.aim
	player.global_position += Vector2(0.0, 120.0)
	await _ticks(5)
	_check(caster.windup_left > 0.0 and caster.aim == locked, "The caster's aim must lock when its glint starts.")
	await _ticks(int(FlyingEnemy.WINDUP_TIME * 60.0))
	var shots: Array[Node] = get_nodes_in_group(&"enemy_projectiles")
	_check(shots.size() == 1 and not (shots[0] as EnemyProjectile).from_air and (shots[0] as EnemyProjectile).velocity.normalized().is_equal_approx(locked), "The caster must fire one ground shot along its locked aim.")
	run.tier = 3
	var hard_caster: GroundCaster = run.spawn_enemy(Run.CASTER, Vector2(1500.0, 1500.0)) as GroundCaster
	var hard_bomber: Bomber = run.spawn_enemy(Run.BOMBER, Vector2(1500.0, 1400.0)) as Bomber
	run.tier = 0
	var easy_caster: GroundCaster = run.spawn_enemy(Run.CASTER, Vector2(1400.0, 1500.0)) as GroundCaster
	_check(hard_caster.shot_damage > easy_caster.shot_damage and hard_bomber.enemy_damage > Bomber.ENEMY_DAMAGE, "Abyss must scale caster shots and the bomber's blast on enemies (%d vs %d, %d)." % [hard_caster.shot_damage, easy_caster.shot_damage, hard_bomber.enemy_damage])
	hard_caster.free()
	hard_bomber.free()
	easy_caster.free()
	run.enemy_count -= 3
	await _take_off(player)
	player.invulnerable_left = 0.0
	var health: int = player.health
	await _ticks(40)
	_check(player.is_airborne() and player.health == health, "A ground shot must miss an airborne angel.")
	Input.action_release(&"jump")
	await _ticks(30)
	_clear(run)
	player.invulnerable_left = 100000.0

	# 4. The bomber: fuse, blast that hurts the angel and ground enemies, not flyers.
	player.global_position = Vector2(-1800.0, 1600.0)
	var bomber: Bomber = run.spawn_enemy(Run.BOMBER, player.global_position + Vector2(160.0, 0.0)) as Bomber
	var husk: Enemy = run.spawn_enemy(Run.HUSK, player.global_position + Vector2(40.0, 40.0))
	husk.speed = 0.0
	husk.max_health = 50
	husk.health = 50
	var flyer: Enemy = run.spawn_enemy(Run.FLYER, player.global_position + Vector2(40.0, -40.0))
	flyer.speed = 0.0
	flyer.max_health = 50
	flyer.health = 50
	var lit: bool = false
	for tick: int in range(60):
		await _ticks(1)
		if bomber.fuse_left > 0.0:
			lit = true
			break
	_check(lit and is_instance_valid(bomber), "A close bomber must light its fuse.")
	player.invulnerable_left = 0.0
	health = player.health
	var kills: int = run.kills
	await _ticks(int(Bomber.FUSE_TIME * 60.0) + 2)
	_check(not is_instance_valid(bomber) and run.kills == kills + 1, "The bomber must die in its blast, counted as a kill.")
	_check(player.health < health, "The blast must hurt the angel.")
	_check(husk.health == 50 - Bomber.ENEMY_DAMAGE, "The blast must hurt ground enemies (husk %d)." % husk.health)
	_check(flyer.health == 50, "The blast must not reach flyers.")
	_clear(run)
	await _settle()
	# Slain first: no blast. Airborne: the blast misses.
	player.invulnerable_left = 100000.0
	var early: Bomber = run.spawn_enemy(Run.BOMBER, player.global_position + Vector2(160.0, 0.0)) as Bomber
	for tick: int in range(60):
		await _ticks(1)
		if early.fuse_left > 0.0:
			break
	player.invulnerable_left = 0.0
	health = player.health
	early.take_hit(100)
	await _ticks(int(Bomber.FUSE_TIME * 60.0) + 2)
	_check(player.health == health, "A bomber slain before its fuse runs out must not explode.")
	await _settle()
	player.invulnerable_left = 100000.0
	var high: Bomber = run.spawn_enemy(Run.BOMBER, player.global_position + Vector2(160.0, 0.0)) as Bomber
	for tick: int in range(60):
		await _ticks(1)
		if high.fuse_left > 0.0:
			break
	await _take_off(player)
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Bomber.FUSE_TIME * 60.0) + 2)
	_check(player.is_airborne() and not is_instance_valid(high) and player.health == health, "The blast must miss an airborne angel.")
	Input.action_release(&"jump")
	await _ticks(30)
	player.invulnerable_left = 100000.0
	_clear(run)

	# 5. The splitter: dies into two husks that never split, within the horde cap.
	player.global_position = Vector2(-1540.0, 1500.0)
	var splitter: Enemy = run.spawn_enemy(Run.SPLITTER, Vector2(-1500.0, 1500.0))
	splitter.take_hit(1000)
	await _ticks(2)
	var children: Array[Enemy] = []
	for actor: Node in run.actors.get_children():
		if actor is Enemy and is_instance_valid(actor) and (actor as Enemy).health > 0:
			children.append(actor as Enemy)
	_check(children.size() == 2 and run.enemy_count == 2 and children.all(func(child: Enemy) -> bool: return not child.has_meta(&"split")), "A splitter must die into two husks (%d)." % children.size())
	_check(children.all(func(child: Enemy) -> bool: return child.global_position.distance_to(player.global_position) > child.radius + MountedPlayer.HURT_RADIUS), "A close kill must not drop husks onto the angel.")
	children[0].take_hit(1000)
	await _ticks(2)
	_check(run.enemy_count == 1, "Its children must not split again.")
	run.max_enemies = run.enemy_count + 1
	run.spawn_enemy(Run.SPLITTER, Vector2(-1400.0, 1500.0)).take_hit(1000)
	await _ticks(2)
	_check(run.enemy_count <= run.max_enemies, "Splitting must respect the horde cap (%d / %d)." % [run.enemy_count, run.max_enemies])
	_clear(run)
	run.max_enemies = 1000
	var crowd: Array[Enemy] = []
	for index: int in range(80):
		var packed: Enemy = run.spawn_enemy(Run.HUSK, Vector2(-1500.0 + (index % 9) * 6.0, 1500.0 + (index / 9) * 6.0))
		packed.speed = 0.0
		packed.max_health = 100
		packed.health = 100
		crowd.append(packed)
	var big: Bomber = run.spawn_enemy(Run.BOMBER, Vector2(-1480.0, 1520.0)) as Bomber
	await _ticks(1)
	big.explode()
	_check(crowd.all(func(each: Enemy) -> bool: return each.health < 100), "A blast must reach every enemy inside it, even in a dense crowd.")
	_clear(run)

	# 6. Batch two. The shielder blocks blows from its front; heavy blows break its guard.
	for pickup: Node in run.pickups.get_children():
		pickup.free()
	run.pending_level_ups = 0
	run.hud.hide_level_up()
	paused = false
	player.global_position = Vector2(-1800.0, 1600.0)
	player.invulnerable_left = 100000.0
	var shielder: Shielder = run.spawn_enemy(Run.SHIELDER, player.global_position + Vector2(120.0, 0.0)) as Shielder
	shielder.speed = 0.0
	shielder.max_health = 50
	shielder.health = 50
	shielder.facing = Vector2.LEFT
	await _ticks(1)
	var reported: Array[int] = []
	var shield_key: int = shielder.get_instance_id()
	var listen: Callable = func(_at: Vector2, amount: int, _heavy: bool, key: int) -> void:
		if key == shield_key:
			reported.append(amount)
	run.enemy_damaged.connect(listen)
	shielder.take_hit(3)
	_check(shielder.health == 50 and shielder.knockback.is_zero_approx() and reported == [0] and shielder.block_flash_left > 0.0, "A blow from the front must be blocked: a flash, sparks, no number, no push (health %d, %s)." % [shielder.health, reported])
	var behind: Enemy = run.spawn_enemy(Run.HUSK, shielder.global_position + Vector2(40.0, 0.0))
	behind.speed = 0.0
	behind.max_health = 50
	behind.health = 50
	await _ticks(1)
	player.aim_direction = Vector2.RIGHT
	player.bow_pierce = 3
	player.fire_arrow(0)
	await _ticks(20)
	player.spear_cast.rotation = 0.0
	player.spear_cast.target_position = Vector2(player.spear_reach * 2.0, 0.0)
	player.spear_cast.clear_exceptions()
	player.thrust_hits_left = 3
	player._resolve_spear_hits()
	_check(shielder.health == 50 and behind.health == 50, "A raised shield must stop piercing arrows and thrusts (behind: %d)." % behind.health)
	behind.free()
	run.enemy_count -= 1
	await _settle()
	shielder.take_hit(3, false, shielder.global_position + Vector2(40.0, 0.0))
	_check(shielder.health == 47, "A blow from behind must land.")
	shielder.take_hit(5, true)
	_check(shielder.health == 42 and shielder.broken_left > 0.0, "A heavy blow from the front must break the guard and land.")
	shielder.take_hit(2)
	_check(shielder.health == 40, "Blows land while the guard is broken.")
	shielder.broken_left = 0.0
	shielder.facing = Vector2.UP
	await _ticks(10)
	_check(absf(shielder.facing.angle_to(Vector2.LEFT)) > 0.1 and absf(shielder.facing.angle_to(Vector2.UP)) > 0.1, "A shielder must turn slowly toward the angel (%s)." % shielder.facing)
	run.enemy_damaged.disconnect(listen)
	_clear(run)

	# The mortar marks a circle where the angel stands; it lands a moment later.
	var far_mortar: Mortar = run.spawn_enemy(Run.MORTAR, player.global_position + Vector2(900.0, 0.0)) as Mortar
	far_mortar.speed = 0.0
	far_mortar.fire_left = 0.0
	await _ticks(90)
	var far_strikes: int = 0
	for child: Node in run.actors.get_children():
		if child is GroundStrike:
			far_strikes += 1
	_check(far_strikes == 0, "A mortar out of sight must hold its fire.")
	far_mortar.free()
	run.enemy_count -= 1
	var mortar: Mortar = run.spawn_enemy(Run.MORTAR, player.global_position + Vector2(260.0, 0.0)) as Mortar
	mortar.fire_left = 0.0
	await _ticks(int(FlyingEnemy.WINDUP_TIME * 60.0) + 3)
	var strikes: Array[GroundStrike] = []
	for child: Node in run.actors.get_children():
		if child is GroundStrike:
			strikes.append(child)
	_check(strikes.size() == 1 and strikes[0].global_position.distance_to(player.global_position) < 1.0 and get_nodes_in_group(&"enemy_projectiles").is_empty(), "A mortar must mark a circle under the angel instead of shooting.")
	player.invulnerable_left = 0.0
	health = player.health
	await _ticks(int(Mortar.STRIKE_DELAY * 60.0) + 2)
	_check(player.health < health, "A mortar circle must land on an angel standing in it.")
	player.invulnerable_left = 100000.0
	_clear(run)
	await _settle()

	# The sleeper waits, wakes when the angel comes close, and pulses a slowing ring.
	var sleeper: Sleeper = run.spawn_enemy(Run.SLEEPER, player.global_position + Vector2(300.0, 0.0)) as Sleeper
	await _ticks(20)
	_check(not sleeper.awake and sleeper.global_position.distance_to(player.global_position) > 299.0 and sleeper.speed > 0.0, "A sleeper must lie still while the angel is away.")
	player.global_position = sleeper.global_position + Vector2(-140.0, 0.0)
	await _ticks(2)
	_check(sleeper.awake and sleeper.waking_left > 0.0, "Coming close must wake it, with a ring first.")
	await _ticks(int(Sleeper.WAKE_TIME * 60.0) + 10)
	_check(sleeper.global_position.distance_to(player.global_position) < 139.0, "Once awake it must close in.")
	sleeper.pulse_left = 0.0
	await _ticks(2)
	_check(sleeper.tell_left > 0.0, "Its slowing pulse must show a ring first.")
	await _ticks(int(Sleeper.PULSE_TELL * 60.0) + 2)
	_check(player.slow_left > 0.0 and player.slow_factor < 1.0, "The pulse must slow an angel inside it.")
	run.hud._process(0.0)
	_check(run.hud.burn_label.visible and run.hud.burn_label.text == "SLOWED", "The HUD must say the angel is slowed.")
	var slowed_speed: float = 0.0
	Input.action_press(&"move_up")
	await _ticks(2)
	slowed_speed = player.velocity.length()
	Input.action_release(&"move_up")
	_check(absf(slowed_speed - player.movement_speed * player.slow_factor) < 1.0, "A slowed angel must walk slower (%f)." % slowed_speed)
	await _take_off(player)
	_check(not player.apply_slow(0.5, 1.0), "An airborne angel must not be slowed.")
	Input.action_press(&"move_up")
	await _ticks(2)
	var flying_speed: float = player.velocity.length()
	Input.action_release(&"move_up")
	_check(player.slow_left > 0.0 and flying_speed > player.movement_speed * player.slow_factor + 1.0, "A slow must not hold back an airborne angel (%f)." % flying_speed)
	Input.action_release(&"jump")
	player.slow_left = 0.0
	await _ticks(30)
	player.apply_slow(0.5, 1.5)
	player.apply_slow(0.8, 0.1)
	_check(is_equal_approx(player.slow_factor, 0.5) and player.slow_left > 1.0, "Overlapping slows must keep the strongest and the longest (%f, %f)." % [player.slow_factor, player.slow_left])
	player.slow_left = 0.0
	player.apply_slow(0.8, 0.5)
	_check(is_equal_approx(player.slow_factor, 0.8), "A fresh slow takes its own factor.")
	# A brief strong slow does not stretch to a weaker slow's length: the weaker takes over after.
	player.slow_left = 0.0
	player.next_slow_left = 0.0
	player.apply_slow(0.6, 0.3)
	player.apply_slow(0.68, 1.2)
	_check(is_equal_approx(player.slow_factor, 0.6) and player.slow_left <= 0.31, "The strong slow must keep its own short time.")
	await _ticks(25)
	_check(is_equal_approx(player.slow_factor, 0.68) and player.slow_left > 0.5, "The weaker, longer slow must take over (%f, %f)." % [player.slow_factor, player.slow_left])
	# The other order: a strong brief slow on top of a weak long one, then the weak one resumes.
	player.slow_left = 0.0
	player.next_slow_left = 0.0
	player.apply_slow(0.68, 1.2)
	player.apply_slow(0.6, 0.3)
	await _ticks(25)
	_check(is_equal_approx(player.slow_factor, 0.68) and player.slow_left > 0.5, "A strong brief slow on a weak long one must hand back to it (%f, %f)." % [player.slow_factor, player.slow_left])
	player.slow_left = 0.0
	player.next_slow_left = 0.0
	player.slow_left = 0.0
	await _ticks(30)
	var struck: Sleeper = run.spawn_enemy(Run.SLEEPER, player.global_position + Vector2(400.0, 0.0)) as Sleeper
	await _ticks(1)
	struck.take_hit(1)
	_check(struck.awake, "Striking a sleeper must wake it.")
	_clear(run)

	# The mirror copies the angel's weapon: it rushes a spear and shoots at a bow.
	player.weapon = MountedPlayer.Weapon.SPEAR
	var mirror: Mirror = run.spawn_enemy(Run.MIRROR, player.global_position + Vector2(260.0, 0.0)) as Mirror
	mirror.fire_left = 0.0
	await _ticks(30)
	await _ticks(90)
	_check(mirror.global_position.distance_to(player.global_position) <= mirror.radius + MountedPlayer.HURT_RADIUS + 2.0 and get_nodes_in_group(&"enemy_projectiles").is_empty() and mirror.windup_left <= 0.0, "Against a spear the mirror must rush all the way in, not shoot (%f)." % mirror.global_position.distance_to(player.global_position))
	player.weapon = MountedPlayer.Weapon.BOW
	mirror.fire_left = 0.0
	await _ticks(int(FlyingEnemy.WINDUP_TIME * 60.0) + 40)
	var mirror_shots: Array[Node] = get_nodes_in_group(&"enemy_projectiles")
	_check(mirror.preferred_distance == Mirror.BOW_DISTANCE and mirror_shots.size() >= 1 and not (mirror_shots[0] as EnemyProjectile).from_air, "Against a bow the mirror must keep away and fire ground shots.")
	for shot: Node in get_nodes_in_group(&"enemy_projectiles"):
		shot.free()
	mirror.fire_left = 0.0
	await _ticks(2)
	_check(mirror.windup_left > 0.0, "The mirror must wind up against the bow.")
	player.weapon = MountedPlayer.Weapon.SPEAR
	await _ticks(int(FlyingEnemy.WINDUP_TIME * 60.0) + 2)
	_check(get_nodes_in_group(&"enemy_projectiles").size() == 1, "Flicking to the spear must not cancel a shot already winding up.")
	_clear(run)
	await _settle()

	# 7. After the angel falls, a lit fuse stops and later deaths pay nothing. (Earlier kills
	# may have levelled the angel up; close that so the world runs.)
	for pickup: Node in run.pickups.get_children():
		pickup.free()
	run.pending_level_ups = 0
	run.hud.hide_level_up()
	paused = false
	player.global_position = Vector2(-1800.0, 1600.0)
	player.invulnerable_left = 100000.0
	var last: Bomber = run.spawn_enemy(Run.BOMBER, player.global_position + Vector2(160.0, 0.0)) as Bomber
	for tick: int in range(60):
		await _ticks(1)
		if last.fuse_left > 0.0:
			break
	_check(last.fuse_left > 0.0, "The last bomber must be lit before the angel falls.")
	var waiting: GroundStrike = GroundStrike.new()
	waiting.target = player
	waiting.delay = 5.0
	run.actors.add_child(waiting)
	waiting.global_position = player.global_position
	var bystander: Enemy = run.spawn_enemy(Run.HUSK, last.global_position + Vector2(20.0, 0.0))
	bystander.speed = 0.0
	var kills_before: int = run.kills
	var feathers_before: int = run.feathers_earned
	player.kill()
	await _ticks(int(Bomber.FUSE_TIME * 60.0) + 5)
	_check(is_instance_valid(last) and is_instance_valid(bystander), "A lit bomber must not explode after the angel falls.")
	_check(not is_instance_valid(waiting), "A marked circle must vanish once the angel falls.")
	bystander.take_hit(1000)
	await _ticks(2)
	_check(run.kills == kills_before and run.feathers_earned == feathers_before, "Nothing may be earned after the run ends.")

	await _settle()
	run.queue_free()
	await _ticks(30)
	print("enemy_types_smoke: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
