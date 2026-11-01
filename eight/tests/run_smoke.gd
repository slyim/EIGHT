extends SceneTree
## Native Godot smoke check for the survival run; no test framework required.

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


func _aim_at(world_point: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * root.get_canvas_transform() * world_point
	motion.global_position = motion.position
	Input.warp_mouse(motion.position)
	Input.parse_input_event(motion)
	await _wait_ticks(2)


func _clear_actors(run: Run) -> void:
	for child: Node in run.actors.get_children():
		child.queue_free()
	run.enemy_count = 0
	await _wait_ticks(1)


func _run() -> void:
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	var player: MountedPlayer = run.player
	_check(player.health == 5, "Player must start with five life.")

	# Spear kills a horde enemy, which drops experience that gets pulled in and collected.
	var enemy: Enemy = run.spawn_enemy(0, player.global_position + Vector2(90.0, 0.0))
	enemy.speed = 0.0
	enemy.knockback_strength = 0.0
	await _wait_ticks(2)
	await _aim_at(enemy.global_position)
	Input.action_press(&"attack")
	await _wait_ticks(50)
	Input.action_release(&"attack")
	_check(not is_instance_valid(enemy), "A thrust must kill a basic enemy.")
	_check(run.kills == 1 and run.enemy_count == 0, "A kill must be counted.")
	await _wait_ticks(60)
	_check(run.xp == 1, "Experience must be pulled to and collected by the player.")

	# Piercing: one thrust hits several lined-up enemies once each.
	player.spear_pierce = 3
	var lined: Array[Enemy] = []
	for index: int in range(3):
		var target: Enemy = run.spawn_enemy(2, player.global_position + Vector2(60.0 + index * 1.0, 0.0))
		target.speed = 0.0
		target.knockback_strength = 0.0
		lined.append(target)
	await _wait_ticks(2)
	Input.action_press(&"attack")
	await _wait_ticks(4)
	Input.action_release(&"attack")
	await _wait_ticks(20)
	for target: Enemy in lined:
		_check(target.health == target.max_health - 1, "A piercing thrust must hit each enemy exactly once.")
	await _clear_actors(run)
	player.spear_pierce = 1

	# Combo: thrust, thrust, then a finisher that sweeps an arc for double damage.
	player.attack_step = -1
	player.combo_window_left = 0.0
	player.cooldown_left = 0.0
	await _wait_ticks(30)
	var center: Enemy = run.spawn_enemy(2, player.global_position + Vector2(80.0, 0.0))
	var upper: Enemy = run.spawn_enemy(2, player.global_position + Vector2(80.0, 0.0).rotated(-0.6))
	var lower: Enemy = run.spawn_enemy(2, player.global_position + Vector2(80.0, 0.0).rotated(0.6))
	var behind: Enemy = run.spawn_enemy(2, player.global_position + Vector2(-80.0, 0.0))
	for target: Enemy in [center, upper, lower, behind]:
		target.speed = 0.0
		target.knockback_strength = 0.0
	await _wait_ticks(2)
	for target: Enemy in [center, upper, lower, behind]:
		target.health = 50
	await _aim_at(center.global_position)
	var steps: Array[int] = []
	var record: Callable = func(step: int) -> void: steps.append(step)
	player.attack_started.connect(record)
	Input.action_press(&"attack")
	await _wait_ticks(52)
	Input.action_release(&"attack")
	await _wait_ticks(20)
	player.attack_started.disconnect(record)
	_check(steps.slice(0, 3) == [0, 1, 2], "Held attack must chain thrust, thrust, finisher (got %s)." % [steps])
	_check(center.health == 46, "Two thrusts and a double-damage finisher must hit the aimed enemy (health %d)." % center.health)
	_check(upper.health == 48 and lower.health == 48, "The finisher must sweep enemies inside its arc.")
	_check(behind.health == 50, "The finisher must not hit enemies behind the player.")
	await _clear_actors(run)

	# Jump: the hero rises, clears damage while high, and lands.
	player.invulnerable_left = 0.0
	Input.action_press(&"jump")
	await _wait_ticks(12)
	Input.action_release(&"jump")
	_check(player.height > MountedPlayer.JUMP_CLEAR_HEIGHT, "Jumping must lift the hero.")
	_check(not player.take_damage(1), "A high jump must clear damage.")
	await _wait_ticks(40)
	_check(player.height == 0.0 and player.jump_time < 0.0, "The hero must land after a jump.")

	# Level-up pauses the run and applies the chosen upgrade.
	run.add_xp(run.xp_needed())
	_check(run.level == 2 and paused, "Reaching the experience threshold must level up and pause.")
	_check(run.hud.level_up_panel.visible, "The level-up choices must be shown.")
	run.level_up_options.assign([run.UPGRADES[0]])
	var damage_before: int = player.spear_damage
	run.choose_upgrade(0)
	_check(player.spear_damage == damage_before + 1, "The chosen upgrade must apply.")
	_check(not paused and not run.hud.level_up_panel.visible, "Choosing must resume the run.")

	# Damage, invulnerability, and life pickups.
	_check(player.take_damage(1), "The player must take damage.")
	_check(not player.take_damage(1), "Damage must be ignored during hurt invulnerability.")
	_check(player.health == 4, "One hit must cost one life.")
	run.spawn_pickup(Pickup.Kind.HEART, player.global_position + Vector2(40.0, 0.0), 1)
	await _wait_ticks(30)
	_check(player.health == 5, "A life pickup must heal the player.")

	# Dash moves quickly and grants invulnerability.
	player.invulnerable_left = 0.0
	var dash_start: Vector2 = player.global_position
	Input.action_press(&"move_down")
	Input.action_press(&"dash")
	await _wait_ticks(2)
	_check(player.is_invulnerable(), "Dashing must make the player invulnerable.")
	await _wait_ticks(10)
	Input.action_release(&"dash")
	Input.action_release(&"move_down")
	_check(player.global_position.y - dash_start.y > 100.0, "Dash must move the player quickly.")

	# Items are collected and applied.
	var reach_before: float = player.spear_reach
	run.spawn_pickup(Pickup.Kind.ITEM, player.global_position + Vector2(10.0, 0.0), 4)
	await _wait_ticks(3)
	_check(run.items.size() == 1 and player.spear_reach == reach_before + 28.0, "Items must be collected and applied.")

	# Seven sins in order, then Satan ends the run in victory.
	for index: int in range(Run.BOSSES.size()):
		_check(run.current_boss == null and not run.ended, "No boss may be active between fights.")
		var boss: Boss = run.spawn_next_boss()
		await _wait_ticks(2)
		_check(boss.boss_name.begins_with(Run.BOSSES[index]["name"] as String), "Bosses must appear in roster order.")
		boss.take_hit(boss.max_health)
		await _wait_ticks(2)
	_check(run.boss_index == 8, "All eight bosses must be counted.")
	_check(run.ended and run.victory and paused, "Defeating Satan must end the run in victory.")
	paused = false
	run.queue_free()
	await _wait_ticks(2)

	# Losing all life ends the run.
	var second: Run = RUN_SCENE.instantiate() as Run
	second.spawning_enabled = false
	second.intro_enabled = false
	root.add_child(second)
	current_scene = second
	await _wait_ticks(3)
	for hit: int in range(second.player.max_health):
		second.player.invulnerable_left = 0.0
		second.player.take_damage(1)
	_check(second.player.is_dead and second.ended and not second.victory, "Losing all life must end the run.")
	_check(second.hud.end_label.visible, "The defeat message must be shown.")

	# Natural spawning and boss timer.
	second.queue_free()
	await _wait_ticks(2)
	var third: Run = RUN_SCENE.instantiate() as Run
	third.boss_interval = 5.0
	third.intro_enabled = false
	root.add_child(third)
	current_scene = third
	third.player.max_health = 99
	third.player.health = 99
	await _wait_ticks(int(5.5 * 60.0))
	_check(third.enemy_count > 0, "Enemies must spawn over time.")
	_check(third.current_boss != null and third.current_boss.boss_name.begins_with("PRIDE"), "Pride must arrive when the boss timer runs out.")

	third.queue_free()
	await _wait_ticks(2)

	# Intro: the angel descends onto the plain; nothing spawns until touchdown.
	var fourth: Run = RUN_SCENE.instantiate() as Run
	root.add_child(fourth)
	current_scene = fourth
	await _wait_ticks(30)
	_check(fourth.player.is_descending() and fourth.player.height > 0.0, "A run must open with the descent.")
	_check(fourth.enemy_count == 0 and fourth.elapsed == 0.0, "Nothing may spawn before the angel lands.")
	await _wait_ticks(90)
	_check(not fourth.player.is_descending() and fourth.has_landed, "The angel must land on the plain.")
	fourth.queue_free()
	# Let the audio server release playbacks before quitting.
	await _wait_ticks(15)

	if failures == 0:
		print("PASS: kills, experience, piercing, combo finisher, jump, level-up, damage, life pickup, dash, items, boss order, victory, defeat, spawning, boss timer, descent intro.")
	quit(1 if failures > 0 else 0)
