extends SceneTree
## Native Godot smoke check for champion elites: the multipliers after tier and clock, the gold
## tint and ring, the spawner's timer and two-alive cap, and the guaranteed feather gem.

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


func _feathers(run: Run) -> int:
	var count: int = 0
	for pickup: Node in run.pickups.get_children():
		if pickup is Pickup and (pickup as Pickup).kind == Pickup.Kind.FEATHER:
			count += 1
	return count


## Kills drop experience; a level-up would pause the tree mid-check.
func _clear_xp(run: Run) -> void:
	for pickup: Node in run.pickups.get_children():
		if pickup is Pickup and (pickup as Pickup).kind == Pickup.Kind.XP:
			pickup.free()
	paused = false


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	run.player.invulnerable_left = 100000.0
	run.feather_drop_chance = 0.0
	_check(is_equal_approx(run.elite_left, Run.ELITE_START), "Elites must wait ELITE_START (30 s) into the run.")
	# The elite clock stands still before landing and while the game is paused (level-ups).
	run.spawning_enabled = true
	run.spawn_left = 1000.0
	run.has_landed = false
	await _wait_ticks(5)
	run.has_landed = true
	paused = true
	await _wait_ticks(5)
	paused = false
	_check(is_equal_approx(run.elite_left, Run.ELITE_START), "The elite clock must wait for landing and stop while paused (%.3f)." % run.elite_left)
	run.spawning_enabled = false

	# The multipliers land on top of the spawned (tier- and clock-scaled) stats.
	var far: Vector2 = run.player.global_position + Vector2(600.0, 0.0)
	var husk: Enemy = run.spawn_enemy(Run.HUSK, far)
	var flyer: FlyingEnemy = run.spawn_enemy(Run.FLYER, far + Vector2(0.0, 80.0)) as FlyingEnemy
	var charger: Charger = run.spawn_enemy(Run.CHARGER, far + Vector2(0.0, -80.0)) as Charger
	var caster: Enemy = run.spawn_enemy(Run.CASTER, far + Vector2(0.0, 160.0))
	var bomber: Bomber = run.spawn_enemy(Run.BOMBER, far + Vector2(0.0, -160.0)) as Bomber
	var caster_tint: Color = caster.sprite.self_modulate
	var blast: int = bomber.enemy_damage
	var base: Array = [husk.max_health, husk.contact_damage, husk.speed, husk.xp_value, flyer.shot_damage]
	run._make_elite(husk)
	run._make_elite(flyer)
	run._make_elite(charger)
	run._make_elite(caster)
	run._make_elite(bomber)
	_check(is_equal_approx(charger.dash_speed, Charger.DASH_SPEED * Run.ELITE_SPEED), "An elite charger must dash faster too.")
	_check(caster_tint != Color.WHITE and caster.sprite.self_modulate == caster_tint * Run.ELITE_TINT, "An elite must gild its type's colour, not replace it.")
	_check(bomber.enemy_damage == roundi(blast * Run.ELITE_DAMAGE), "An elite bomber's blast must hurt the horde harder too.")
	for extra: Node in [charger, caster, bomber]:
		extra.free()
	_check(husk.max_health == roundi(base[0] * Run.ELITE_HEALTH) and husk.health == husk.max_health, "An elite must have four times the health, at full health.")
	_check(husk.contact_damage == roundi(base[1] * Run.ELITE_DAMAGE) and flyer.shot_damage == roundi(base[4] * Run.ELITE_DAMAGE), "An elite must hit harder, shots included.")
	_check(is_equal_approx(husk.speed, base[2] * Run.ELITE_SPEED) and husk.xp_value == base[3] * Run.ELITE_XP, "An elite must be faster and worth more experience.")
	var ring: Node2D = husk.sprite.get_node_or_null(^"EliteRing") as Node2D
	var flyer_ring: Node2D = flyer.sprite.get_node_or_null(^"EliteRing") as Node2D
	_check(ring != null and ring.global_position.is_equal_approx(husk.global_position) and flyer_ring != null and flyer_ring.global_position.is_equal_approx(flyer.sprite.global_position), "A ground elite's ring must sit at its feet, a flyer's around it in the air.")
	_check(husk.sprite.self_modulate == Run.ELITE_TINT and ring != null and ring.show_behind_parent and flyer_ring != null, "An elite must be gold-tinted and ringed behind its sprite, in the air too.")

	# Slain, it always drops a feather gem (random feather drops are off here).
	husk.take_hit(100000)
	await _wait_ticks(2)
	_clear_xp(run)
	_check(_feathers(run) == 1, "A slain elite must drop a feather gem (%d)." % _feathers(run))
	var plain: Enemy = run.spawn_enemy(Run.HUSK, far)
	plain.take_hit(100000)
	await _wait_ticks(2)
	_clear_xp(run)
	_check(_feathers(run) == 1, "An ordinary enemy must not get the elite's feather.")

	# The spawner: when the timer is due, one spawn comes out elite and the timer restarts;
	# never more than two alive (the flyer still stands).
	run.spawning_enabled = true
	run.elite_left = 0.0
	run.spawn_left = 0.0
	await _wait_ticks(2)
	var elites: int = get_nodes_in_group(&"elites").size()
	_check(elites == 2 and run.elite_left >= Run.ELITE_GAP_MIN - 1.0 and run.elite_left <= Run.ELITE_GAP_MAX, "A due timer must raise one elite and restart (%d, %.1f)." % [elites, run.elite_left])
	run.elite_left = 0.0
	run.spawn_left = 0.0
	await _wait_ticks(2)
	_check(get_nodes_in_group(&"elites").size() == Run.ELITE_MAX and run.elite_left <= 0.0, "No more than two elites may stand; the next waits for a free slot.")
	flyer.take_hit(100000)
	await _wait_ticks(2)
	_clear_xp(run)
	run.spawn_left = 0.0
	await _wait_ticks(2)
	_check(get_nodes_in_group(&"elites").size() == Run.ELITE_MAX and run.elite_left > 0.0, "A free slot must take the waiting elite.")

	run.queue_free()
	await _wait_ticks(30) # Let freed nodes and sounds finish before quitting.
	if failures == 0:
		print("elite_smoke: PASS")
	quit(1 if failures > 0 else 0)
