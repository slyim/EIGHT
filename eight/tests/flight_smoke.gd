extends SceneTree
## Flight, flight stamina, air/ground hit rules, and weapons against flying enemies in the
## survival run; native Godot only.

const RUN_SCENE: PackedScene = preload("res://scenes/run.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const GROUND_LAYER: int = 8
## Flying enemies' physics layer (layer 5).
const FLYING_LAYER: int = 16

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


func _ticks(seconds: float) -> int:
	return ceili(seconds * Engine.physics_ticks_per_second)


func _aim_at(world_point: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * root.get_canvas_transform() * world_point
	motion.global_position = motion.position
	Input.warp_mouse(motion.position)
	Input.parse_input_event(motion)
	await _wait_ticks(2)


## The HUD refreshes in _process, after the tree's process_frame signal.
func _hud_frame() -> void:
	await process_frame
	await process_frame


## A still enemy stand-in on a physics layer. It has no target, so it never moves or
## touches the player.
func _stand_in(run: Run, at: Vector2, layer: int) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	enemy.max_health = 50
	enemy.collision_layer = layer
	enemy.position = at
	run.actors.add_child(enemy)
	return enemy


## Holds Space with a full meter until the climb has finished.
func _take_off(player: MountedPlayer) -> void:
	player.flight_stamina = player.flight_time
	Input.action_press(&"jump")
	await _wait_ticks(_ticks(player.flight_rise_time) + 2)


func _land(player: MountedPlayer) -> void:
	Input.action_release(&"jump")
	await _wait_ticks(_ticks(player.flight_descend_time) + 2)


## One spear attack; step 0 is a thrust, step 2 the sweeping finisher.
func _spear_attack(player: MountedPlayer, step: int) -> void:
	player.attack_step = step - 1
	player.combo_window_left = 1.0 if step > 0 else 0.0
	player.cooldown_left = 0.0
	Input.action_press(&"attack")
	await _wait_ticks(3)
	Input.action_release(&"attack")
	await _wait_ticks(20)


func _run() -> void:
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	var player: MountedPlayer = run.player
	var hud: Hud = run.hud
	var take_offs: Array[int] = [0]
	var landings: Array[int] = [0]
	player.jumped.connect(func() -> void: take_offs[0] += 1)
	player.landed.connect(func() -> void: landings[0] += 1)

	# 1. Holding Space climbs to a hover well above the old 56 px hop and stays up, bobbing.
	_check(player.flight_stamina == player.flight_time, "Flight stamina must start full.")
	await _take_off(player)
	_check(player.is_airborne() and take_offs[0] == 1, "Holding Space must take off once.")
	_check(player.height > player.flight_height - MountedPlayer.FLIGHT_BOB_HEIGHT - 0.5, "The angel must climb to hover height, got %f." % player.height)
	var heights: Array[float] = []
	for tick: int in range(60):
		await physics_frame
		heights.append(player.height)
	_check(player.is_airborne() and landings[0] == 0, "Holding Space must keep the angel up past the old hop's length.")
	_check(heights.min() > 60.0, "The hover must stay well above the old hop, got %f." % heights.min())
	var bob: float = heights.max() - heights.min()
	_check(bob > 2.0 and bob <= 2.0 * MountedPlayer.FLIGHT_BOB_HEIGHT + 0.5, "Hovering must bob gently, got %f." % bob)

	# 2. Stamina drains in the air and never refills there; the HUD gauge follows it.
	var airborne_stamina: float = player.flight_stamina
	_check(airborne_stamina < player.flight_time - 1.0, "Stamina must drain in flight, got %f." % airborne_stamina)
	await _wait_ticks(6)
	_check(player.flight_stamina < airborne_stamina, "Stamina must not refill in the air.")
	await _hud_frame()
	var gauge: float = player.flight_stamina / player.flight_time
	_check(absf(hud.flight_bar.value - gauge) < 0.02, "The flight gauge must follow stamina in the air (%f vs %f)." % [hud.flight_bar.value, gauge])
	var shown: int = int(hud.flight_label.text.trim_prefix("FLIGHT ").trim_suffix("%"))
	_check(hud.flight_label.text.ends_with("%") and absi(shown - roundi(gauge * 100.0)) <= 2, "The flight gauge must read the stamina left, got %s." % hud.flight_label.text)

	# 3. Ground attacks miss the airborne angel; attacks from the air land.
	player.invulnerable_left = 0.0
	_check(player.is_invulnerable(), "is_invulnerable must still report immunity to ground attacks in the air.")
	_check(not player.take_damage(10), "Ground damage must miss an airborne player.")
	_check(player.health == player.max_health, "A missed ground attack must not cost health.")
	_check(player.take_damage(10, true), "Damage from the air must reach an airborne player.")
	_check(player.health == player.max_health - 10, "Damage from the air must cost health.")
	_check(not player.take_damage(10, true), "Hurt invulnerability must still apply in the air.")
	player.invulnerable_left = 0.0
	player.heal(10)

	# 4. A dash in the air keeps the angel up and still bursts forward.
	var dash_start: Vector2 = player.global_position
	player.dash_cooldown_left = 0.0
	Input.action_press(&"dash")
	await _wait_ticks(4)
	Input.action_release(&"dash")
	_check(player.is_airborne() and player.flying, "Dashing in the air must keep the angel flying.")
	_check(player.global_position.distance_to(dash_start) > 30.0, "Dashing in the air must still burst forward.")

	# 5. Releasing Space lands once; stamina refills only after landing.
	await _land(player)
	_check(player.height == 0.0 and not player.is_airborne() and landings[0] == 1, "Releasing Space must land the angel once.")
	_check(player.take_damage(10), "Ground damage must land on a grounded player.")
	player.invulnerable_left = 0.0
	player.heal(10)
	var landed_stamina: float = player.flight_stamina
	await _wait_ticks(30)
	_check(player.flight_stamina > landed_stamina + 0.25, "Stamina must refill on the ground (%f -> %f)." % [landed_stamina, player.flight_stamina])

	# 6. Running dry forces a landing even with Space held, and holding does not relaunch.
	await _take_off(player)
	_check(player.is_airborne() and take_offs[0] == 2, "A fresh hold must take off again.")
	player.flight_stamina = 0.1
	await _wait_ticks(_ticks(0.1 + player.flight_descend_time) + 6)
	_check(Input.is_action_pressed(&"jump") and player.height == 0.0 and landings[0] == 2, "Running out of stamina must force a landing.")
	await _wait_ticks(_ticks(player.flight_min_stamina / player.flight_refill_rate) + 6)
	_check(player.flight_stamina >= player.flight_min_stamina, "Stamina must refill after an exhausted landing.")
	_check(player.height == 0.0 and take_offs[0] == 2, "Holding Space must not relaunch after an exhausted landing.")
	Input.action_release(&"jump")
	await _wait_ticks(2)

	# 7. Take-off is refused below the minimum, and that press does not fire once it refills.
	player.flight_stamina = player.flight_min_stamina * 0.2
	Input.action_press(&"jump")
	await _wait_ticks(4)
	_check(player.height == 0.0 and not player.flying and take_offs[0] == 2, "Take-off must be refused below the minimum stamina.")
	await _wait_ticks(_ticks(player.flight_min_stamina / player.flight_refill_rate) + 6)
	_check(player.flight_stamina >= player.flight_min_stamina and player.height == 0.0 and take_offs[0] == 2, "A refused press must not launch later.")
	Input.action_release(&"jump")
	await _wait_ticks(2)

	# 8. A tap is a short hop: the climb finishes, then the angel glides down.
	player.flight_stamina = player.flight_time
	Input.action_press(&"jump")
	await _wait_ticks(1)
	Input.action_release(&"jump")
	await _wait_ticks(_ticks(player.flight_rise_time) - 2)
	_check(player.is_airborne() and take_offs[0] == 3, "A tap must still lift the angel.")
	await _wait_ticks(_ticks(player.flight_descend_time) + 4)
	_check(player.height == 0.0 and landings[0] == 3, "A tap must land after a short hop.")

	# 9. Walls and obstacles still block the angel in flight. The first structure (the old
	# Pillar1) spans x -680..-520 at y -400.
	player.global_position = Vector2(-460.0, -400.0)
	await _take_off(player)
	Input.action_press(&"move_left")
	await _wait_ticks(30)
	Input.action_release(&"move_left")
	_check(player.is_airborne() and player.global_position.x > -510.0, "A pillar must block the flying angel, got x %f." % player.global_position.x)
	await _land(player)

	# 10. Airborne, the spear reaches flying enemies over ground ones; grounded, the reverse.
	player.global_position = Vector2.ZERO
	player.spear_pierce = 3
	var walker: Enemy = _stand_in(run, Vector2(60.0, 0.0), GROUND_LAYER)
	var flyer: Enemy = _stand_in(run, Vector2(90.0, 0.0), FLYING_LAYER)
	await _wait_ticks(3)
	await _aim_at(Vector2(90.0, 0.0))
	await _take_off(player)
	await _spear_attack(player, 0)
	_check(flyer.health == 49 and walker.health == 50, "An airborne thrust must hit only the flying enemy (flyer %d, walker %d)." % [flyer.health, walker.health])
	await _spear_attack(player, 2)
	_check(flyer.health == 47 and walker.health == 50, "An airborne finisher must sweep only the flying enemy (flyer %d, walker %d)." % [flyer.health, walker.health])
	await _land(player)
	await _wait_ticks(30)
	await _spear_attack(player, 0)
	_check(walker.health == 49 and flyer.health == 47, "A grounded thrust must hit only the ground enemy (flyer %d, walker %d)." % [flyer.health, walker.health])
	await _spear_attack(player, 2)
	_check(walker.health == 47 and flyer.health == 47, "A grounded finisher must sweep only the ground enemy (flyer %d, walker %d)." % [flyer.health, walker.health])
	walker.queue_free()
	flyer.queue_free()
	player.spear_pierce = 1
	await _wait_ticks(30)

	# 11. Arrows hit flying enemies from the ground and ground enemies from the air.
	player.switch_weapon()
	var high: Enemy = _stand_in(run, Vector2(220.0, 0.0), FLYING_LAYER)
	var low: Enemy = _stand_in(run, Vector2(0.0, 220.0), GROUND_LAYER)
	await _wait_ticks(3)
	await _aim_at(high.global_position)
	var arrow: Arrow = player.fire_arrow(0.0)
	_check(is_equal_approx(arrow.height, MountedPlayer.SPEAR_HEIGHT), "A grounded arrow must leave from the bow.")
	await _wait_ticks(20)
	_check(high.health == 50 - player.bow_min_damage, "A grounded arrow must hit a flying enemy (health %d)." % high.health)
	await _take_off(player)
	await _aim_at(low.global_position)
	arrow = player.fire_arrow(0.0)
	_check(arrow.height > player.flight_height - MountedPlayer.FLIGHT_BOB_HEIGHT, "An arrow shot in flight must leave from the raised bow.")
	await _wait_ticks(20)
	_check(low.health == 50 - player.bow_min_damage, "An arrow shot in flight must hit a ground enemy (health %d)." % low.health)
	high.queue_free()
	low.queue_free()

	# 12. Slain in the air, the angel falls to the ground instead of hanging there.
	player.invulnerable_left = 0.0
	player.health = 10
	_check(player.is_airborne() and player.take_damage(10, true) and player.is_dead, "A blow from the air must be able to kill in flight.")
	await _wait_ticks(_ticks(player.flight_descend_time) + 3)
	_check(player.height == 0.0 and player.sprite.position == player.sprite_base, "A slain angel must fall to the ground.")
	Input.action_release(&"jump")

	run.queue_free()
	# Let the audio server release playbacks before quitting.
	await _wait_ticks(15)
	if failures == 0:
		print("PASS: hold to fly, release to land, hover bob, stamina drain/refill/minimum/exhaustion, tap hop, air dash, walls in flight, air/ground hit rules, spear and arrows vs flying enemies, falling when slain.")
	quit(1 if failures > 0 else 0)
