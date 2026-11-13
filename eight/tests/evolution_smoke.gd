extends SceneTree
## Weapon evolution: guard and horde drops, the paused two-path choice, once per weapon per
## run (spares become XP), queued level-ups after the choice, and the four evolved finishers
## (Whirlwind, Chain Light, Ricochet, Rain of Light). Native Godot only.

const RUN_SCENE: PackedScene = preload("res://scenes/run.tscn")

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


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _ticks(1)


## Points the real mouse at a world point (the angel re-reads the mouse every tick).
func _aim_at(world_point: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * root.get_canvas_transform() * world_point
	motion.global_position = motion.position
	Input.warp_mouse(motion.position)
	Input.parse_input_event(motion)
	await _ticks(2)


## A motionless, sturdy enemy for counting hits.
func _dummy(run: Run, at: Vector2, type_index: int = 0) -> Enemy:
	var enemy: Enemy = run.spawn_enemy(type_index, at)
	enemy.speed = 0.0
	enemy.knockback_strength = 0.0
	enemy.max_health = 100
	enemy.health = 100
	return enemy


func _clear(run: Run) -> void:
	for child: Node in run.actors.get_children():
		child.free()
	for child: Node in run.pickups.get_children():
		child.free()
	run.enemy_count = 0
	run.player.global_position = Vector2.ZERO
	await _ticks(2)


## Plays the finisher of the current weapon (the third step of its combo).
func _finisher(player: MountedPlayer) -> void:
	player.attack_step = MountedPlayer.COMBO_LENGTH - 2
	player.combo_window_left = 1.0
	player.cooldown_left = 0.0
	player.attack_time_left = 0.0
	player.attack_buffer_left = 0.1
	await _ticks(30)


func _evolve_via_pickup(run: Run, which: int, path_key: Key) -> void:
	run.spawn_pickup(Pickup.Kind.EVOLUTION, run.player.global_position, which)
	await _ticks(2)
	await _key(path_key)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var run: Run = RUN_SCENE.instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	await _ticks(3)
	var player: MountedPlayer = run.player
	player.invulnerable_left = 100000.0
	var hud: Hud = run.hud

	# 1. A guard always drops an evolution item, for a weapon that has not evolved.
	var guard: Boss = run.guards[0]
	var at: Vector2 = guard.global_position
	guard.take_hit(guard.max_health)
	await _ticks(2)
	var drops: Array[Pickup] = []
	for child: Node in run.pickups.get_children():
		if (child as Pickup).kind == Pickup.Kind.EVOLUTION:
			drops.append(child)
	_check(drops.size() == 1 and drops[0].global_position.distance_to(at) < 60.0, "A slain guard must drop one evolution item.")
	_check(drops.size() == 1 and drops[0].item_index in [MountedPlayer.Weapon.SPEAR, MountedPlayer.Weapon.BOW], "The drop must name a weapon.")
	await _clear(run)
	# Horde drops follow evolution_drop_chance.
	run.evolution_drop_chance = 1.0
	var husk: Enemy = run.spawn_enemy(0, Vector2(600.0, 600.0))
	husk.take_hit(1000)
	await _ticks(2)
	var horde_drop: bool = false
	for child: Node in run.pickups.get_children():
		horde_drop = horde_drop or (child as Pickup).kind == Pickup.Kind.EVOLUTION
	_check(horde_drop, "A horde enemy must be able to drop an evolution item.")
	run.evolution_drop_chance = 0.0
	await _clear(run)

	# 2. Collecting it pauses for two paths; Esc cannot open the pause menu over it; a level-up
	# that arrives meanwhile waits until the choice is made.
	run.spawn_pickup(Pickup.Kind.EVOLUTION, Vector2(10.0, 0.0), MountedPlayer.Weapon.SPEAR)
	await _ticks(3)
	_check(paused and hud.evolution_panel.visible and run.evolution_weapon == MountedPlayer.Weapon.SPEAR, "Collecting must pause for the spear's paths.")
	_check((hud.evolution_cards[0].get_node(^"Text/Title") as Label).text.contains("WHIRLWIND") and (hud.evolution_cards[1].get_node(^"Text/Title") as Label).text.contains("CHAIN LIGHT"), "The spear must offer Whirlwind and Chain Light.")
	await _key(KEY_ESCAPE)
	_check(not hud.pause_menu.visible and hud.evolution_panel.visible, "Esc must not open the pause menu over an evolution.")
	run.add_xp(run.xp_needed())
	await _ticks(1)
	_check(not hud.level_up_panel.visible and run.pending_level_ups == 1, "A level-up must wait behind the evolution choice.")
	await _key(KEY_1)
	_check(player.spear_path == MountedPlayer.SpearPath.WHIRLWIND and not hud.evolution_panel.visible, "Pressing 1 must take Whirlwind.")
	_check(hud.has_node(^"Flash"), "Choosing must flash.")
	_check(paused and hud.level_up_panel.visible, "The queued level-up must follow the choice.")
	run.choose_upgrade(0)
	_check(not paused, "Choosing the level-up must resume.")
	await _ticks(2)
	_check(hud.weapon_label.text.begins_with("WHIRLWIND"), "The weapon gauge must name the path (got %s)." % hud.weapon_label.text)

	# 3. Once per weapon per run: a spare spear item is experience, and no more spear drops.
	var xp_before: int = run.xp
	var level_before: int = run.level
	run.spawn_pickup(Pickup.Kind.EVOLUTION, Vector2(10.0, 0.0), MountedPlayer.Weapon.SPEAR)
	await _ticks(3)
	_check(not hud.evolution_panel.visible and player.spear_path == MountedPlayer.SpearPath.WHIRLWIND, "An evolved weapon must not evolve again.")
	_check(run.xp != xp_before or run.level != level_before, "A spare evolution item must give experience.")
	while run.pending_level_ups > 0:
		run.choose_upgrade(0)
	for roll: int in range(20):
		var pick: Pickup = run.drop_evolution(Vector2(900.0, 900.0))
		_check(pick != null and pick.item_index == MountedPlayer.Weapon.BOW, "With the spear evolved, drops must be for the bow.")
	await _clear(run)

	# 4. Whirlwind: the finisher strikes all around, even behind the aim.
	var behind: Enemy = _dummy(run, Vector2(-70.0, 0.0))
	var ahead: Enemy = _dummy(run, Vector2(70.0, 0.0))
	await _aim_at(player.global_position + Vector2(200.0, 0.0))
	await _finisher(player)
	_check(behind.health < 100 and ahead.health < 100, "Whirlwind must strike behind as well as ahead (%d, %d)." % [behind.health, ahead.health])
	await _clear(run)

	# 5. Chain Light (a fresh run): the finisher's hit jumps to enemies beyond the spear's reach.
	run.queue_free()
	await _ticks(2)
	run = RUN_SCENE.instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	await _ticks(3)
	player = run.player
	player.invulnerable_left = 100000.0
	hud = run.hud
	await _clear(run)
	_check(player.spear_path == MountedPlayer.SpearPath.NONE and player.bow_path == MountedPlayer.BowPath.NONE, "Evolutions must not carry into a new run.")
	await _evolve_via_pickup(run, MountedPlayer.Weapon.SPEAR, KEY_2)
	_check(player.spear_path == MountedPlayer.SpearPath.CHAIN_LIGHT, "Pressing 2 must take Chain Light.")
	await _clear(run)
	var first: Enemy = _dummy(run, Vector2(70.0, 0.0))
	var near: Enemy = _dummy(run, Vector2(240.0, 0.0))
	var further: Enemy = _dummy(run, Vector2(400.0, 0.0))
	var lonely: Enemy = _dummy(run, Vector2(70.0, -900.0))
	await _aim_at(player.global_position + Vector2(200.0, 0.0))
	await _finisher(player)
	_check(first.health < 100 and near.health < 100 and further.health < 100, "Chain Light must jump from the struck enemy along the chain (%d, %d, %d)." % [first.health, near.health, further.health])
	_check(lonely.health == 100, "Chain Light must not reach beyond its range.")
	await _clear(run)
	# A wall between the struck enemy and the next stops the jump.
	var struck: Enemy = _dummy(run, Vector2(70.0, 0.0))
	var walled: Enemy = _dummy(run, Vector2(230.0, 0.0))
	var wall: Breakable = run._add_obstacle(Breakable.Kind.WALL, Vector2(150.0, 0.0), true)
	await _ticks(2)
	await _aim_at(player.global_position + Vector2(200.0, 0.0))
	await _finisher(player)
	_check(struck.health < 100 and walled.health == 100, "Chain Light must not jump through a wall (%d, %d)." % [struck.health, walled.health])
	wall.free()
	await _clear(run)

	# 6. Ricochet: the finishing arrow bounces on to other enemies; earlier arrows do not.
	player.switch_weapon()
	await _evolve_via_pickup(run, MountedPlayer.Weapon.BOW, KEY_1)
	_check(player.bow_path == MountedPlayer.BowPath.RICOCHET, "Pressing 1 must take Ricochet for the bow.")
	await _clear(run)
	var a: Enemy = _dummy(run, Vector2(200.0, 0.0))
	var b: Enemy = _dummy(run, Vector2(260.0, 180.0))
	var c: Enemy = _dummy(run, Vector2(120.0, 330.0))
	player.aim_direction = Vector2.RIGHT
	var plain: Arrow = player.fire_arrow(0)
	_check(plain.bounces == 0, "Only the finishing arrow ricochets.")
	plain.queue_free()
	player.fire_arrow(MountedPlayer.COMBO_LENGTH - 1)
	await _ticks(40)
	_check(a.health < 100 and b.health < 100 and c.health < 100, "The finishing arrow must bounce through the group (%d, %d, %d)." % [a.health, b.health, c.health])
	await _clear(run)

	# 7. Rain of Light (a fresh run): the finisher marks the aim point, then strikes every enemy
	# in the circle, on the ground and in the air, after its delay.
	run.queue_free()
	await _ticks(2)
	run = RUN_SCENE.instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	await _ticks(3)
	player = run.player
	player.invulnerable_left = 100000.0
	hud = run.hud
	await _clear(run)
	player.switch_weapon()
	await _evolve_via_pickup(run, MountedPlayer.Weapon.BOW, KEY_2)
	_check(player.bow_path == MountedPlayer.BowPath.RAIN, "Pressing 2 must take Rain of Light.")
	# The longest gauge text, mid-combo, must still fit its bar.
	player.attack_step = MountedPlayer.COMBO_LENGTH - 1
	player.cooldown_left = 1.0
	await _ticks(2)
	_check(hud.weapon_label.text == "RAIN OF LIGHT  3 / 3" and hud.weapon_label.get_minimum_size().x <= hud.weapon_bar.size.x, "The longest gauge text must fit its bar (%s)." % hud.weapon_label.text)
	await _clear(run)
	var ground: Enemy = _dummy(run, Vector2(300.0, 40.0))
	var flyer: Enemy = _dummy(run, Vector2(260.0, -30.0), 3)
	var outside: Enemy = _dummy(run, Vector2(300.0, 260.0))
	# The real third shot of the bow combo calls the rain at the mouse.
	await _aim_at(player.global_position + Vector2(300.0, 0.0))
	player.attack_step = MountedPlayer.COMBO_LENGTH - 2
	player.combo_window_left = 1.0
	player.cooldown_left = 0.0
	player.attack_buffer_left = 0.1
	await _ticks(3)
	var rain: LightRain = null
	for child: Node in run.get_children():
		if child is LightRain:
			rain = child
	_check(rain != null and rain.global_position.distance_to(Vector2(300.0, 0.0)) < 2.0, "The bow finisher must call the rain at the mouse (got %s)." % [rain.global_position if rain != null else null])
	_check(rain == null or not rain.struck, "The rain must not strike at once.")
	player.set_physics_process(false)
	player.aim_direction = Vector2.RIGHT
	_check(ground.health == 100, "The rain must wait for its delay.")
	await _ticks(roundi(player.rain_delay * 60.0) + 4)
	_check(ground.health < 100 and flyer.health < 100, "The rain must strike ground and flying enemies in the circle (%d, %d)." % [ground.health, flyer.health])
	_check(outside.health == 100, "The rain must spare enemies outside the circle.")
	player.aim_distance = 5000.0
	var far: LightRain = player.call_rain()
	_check(far.global_position.distance_to(player.global_position) <= player.bow_range + 0.5, "The rain must land within bow range.")
	await _clear(run)
	# A packed crowd (more than the old 128-result cap) is struck in full.
	run.max_enemies = 1000
	var crowd: Array[Enemy] = []
	for index: int in range(160):
		crowd.append(_dummy(run, Vector2(600.0, 0.0) + Vector2.from_angle(index * 2.4) * (index % 9) * 8.0))
	player.aim_distance = 300.0
	var packed: LightRain = player.call_rain()
	packed.global_position = Vector2(600.0, 0.0)
	await _ticks(roundi(player.rain_delay * 60.0) + 6)
	var missed: int = 0
	for enemy: Enemy in crowd:
		if is_instance_valid(enemy) and enemy.health == 100:
			missed += 1
	_check(missed == 0, "The rain must strike every enemy in a crowded circle (%d missed)." % missed)
	player.set_physics_process(true)
	await _ticks(40)

	# 8. A won run closes any open evolution choice.
	run.spawn_pickup(Pickup.Kind.EVOLUTION, player.global_position, MountedPlayer.Weapon.SPEAR)
	await _ticks(3)
	_check(hud.evolution_panel.visible or run.hud.evolution_panel.visible, "The spear evolution must still be on offer.")
	run._end_run(true)
	_check(not run.hud.evolution_panel.visible and run.evolution_weapon == -1 and not paused, "Winning must close the evolution choice and unpause.")

	run.queue_free()
	await _ticks(15)
	if failures == 0:
		print("Evolution smoke passed: guard and horde drops, paused two-path choice, Esc refused, queued level-up after, flash, gauge name, once per weapon with XP spares, Whirlwind, Chain Light, Ricochet, Rain of Light, fresh runs reset, win closes the choice.")
	quit(1 if failures > 0 else 0)
