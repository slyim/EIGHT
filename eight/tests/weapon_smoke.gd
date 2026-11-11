extends SceneTree
## Bow, weapon switching, and input-buffer checks in the survival run; native Godot only.

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


## The HUD refreshes in _process, after the tree's process_frame signal.
func _hud_frame() -> void:
	await process_frame
	await process_frame


func _key(code: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _wheel(button: MouseButton) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)


func _still_enemy(run: Run, at: Vector2) -> Enemy:
	var enemy: Enemy = run.spawn_enemy(2, at)
	enemy.speed = 0.0
	enemy.knockback_strength = 0.0
	enemy.health = 50
	return enemy


func _run() -> void:
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	var player: MountedPlayer = run.player
	var arrows: Array[float] = []
	player.arrow_fired.connect(func(charge: float) -> void: arrows.append(charge))

	# Q and the mouse wheel both toggle the weapon; the HUD names it.
	_check(player.weapon == MountedPlayer.Weapon.SPEAR, "The run must start with the spear.")
	_key(KEY_Q, true)
	await _wait_ticks(2)
	_key(KEY_Q, false)
	_check(player.weapon == MountedPlayer.Weapon.BOW, "Q must switch to the bow.")
	await _hud_frame()
	_check(run.hud.weapon_label.text.begins_with("BOW"), "The HUD must show the bow.")
	_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await _wait_ticks(2)
	_check(player.weapon == MountedPlayer.Weapon.SPEAR, "The mouse wheel must switch back to the spear.")
	await _hud_frame()
	_check(run.hud.weapon_label.text.begins_with("SPEAR"), "The HUD must show the spear.")
	_wheel(MOUSE_BUTTON_WHEEL_UP)
	await _wait_ticks(2)
	_check(player.weapon == MountedPlayer.Weapon.BOW, "Wheel up must also switch weapons.")

	# Switching mid-draw cancels it without firing.
	Input.action_press(&"attack")
	await _wait_ticks(10)
	_check(player.draw_charge() > 0.0 and run.hud.weapon_label.text.begins_with("BOW DRAW"), "Holding attack must draw the bow and show the charge.")
	_key(KEY_Q, true)
	await _wait_ticks(1)
	_key(KEY_Q, false)
	Input.action_release(&"attack")
	await _wait_ticks(3)
	_check(player.draw_time < 0.0 and arrows.is_empty(), "Switching weapons must cancel the draw without firing.")
	_key(KEY_Q, true)
	await _wait_ticks(1)
	_key(KEY_Q, false)

	# A full draw deals full damage; a tap fires a weak arrow.
	var enemy: Enemy = _still_enemy(run, player.global_position + Vector2(200.0, 0.0))
	await _aim_at(enemy.global_position)
	Input.action_press(&"attack")
	await _wait_ticks(roundi(player.bow_draw_time * 60.0) + 6)
	_check(player.draw_charge() == 1.0, "A long hold must reach full charge.")
	Input.action_release(&"attack")
	await _wait_ticks(30)
	_check(arrows.size() == 1 and arrows[0] == 1.0, "Releasing must fire one fully charged arrow.")
	_check(enemy.health == 50 - player.bow_max_damage, "A charged arrow must deal full bow damage (health %d)." % enemy.health)
	Input.action_press(&"attack")
	await _wait_ticks(1)
	Input.action_release(&"attack")
	await _wait_ticks(30)
	_check(arrows.size() == 2 and arrows[1] < 0.2, "A tap must still fire a minimum-draw arrow.")
	_check(enemy.health == 50 - player.bow_max_damage - player.bow_min_damage, "A tap arrow must deal minimum damage.")
	enemy.queue_free()
	run.enemy_count = 0

	# A pillar (World layer) stops the arrow before an enemy behind it.
	player.global_position = Vector2(480.0, 300.0)
	var hidden: Enemy = _still_enemy(run, Vector2(900.0, 300.0))
	await _wait_ticks(3)
	await _aim_at(hidden.global_position)
	var arrow: Arrow = player.fire_arrow(1.0)
	await _wait_ticks(40)
	_check(not is_instance_valid(arrow), "An arrow must be freed when it hits a wall.")
	_check(hidden.health == 50, "A wall must stop the arrow before the enemy behind it.")
	hidden.queue_free()
	run.enemy_count = 0

	# An arrow is freed at the end of its range.
	player.global_position = Vector2(0.0, -300.0)
	await _wait_ticks(3)
	await _aim_at(Vector2(0.0, -1000.0))
	arrow = player.fire_arrow(0.0)
	await _wait_ticks(roundi(player.bow_min_range / player.arrow_speed * 60.0) + 4)
	_check(not is_instance_valid(arrow), "An arrow must be freed at the end of its range.")

	# A dash pressed shortly before its cooldown ends still fires.
	var dashes: Array[int] = []
	player.dashed.connect(func() -> void: dashes.append(1))
	player.dash_cooldown_left = 0.06
	_key(KEY_SHIFT, true)
	await _wait_ticks(1)
	_key(KEY_SHIFT, false)
	_check(dashes.is_empty(), "The dash must wait for its cooldown.")
	await _wait_ticks(8)
	_check(dashes.size() == 1, "A dash pressed during cooldown must be buffered, not dropped.")
	# A press older than the buffer is dropped.
	await _wait_ticks(60)
	dashes.clear()
	player.dash_cooldown_left = player.input_buffer + 0.15
	_key(KEY_SHIFT, true)
	await _wait_ticks(1)
	_key(KEY_SHIFT, false)
	await _wait_ticks(30)
	_check(dashes.is_empty(), "A press older than the input buffer must not dash.")

	# A spear hit briefly slows time and shakes the camera, then time recovers.
	_key(KEY_Q, true)
	await _wait_ticks(1)
	_key(KEY_Q, false)
	_check(player.weapon == MountedPlayer.Weapon.SPEAR, "Q must switch back to the spear.")
	var target: Enemy = _still_enemy(run, player.global_position + Vector2(80.0, 0.0))
	await _wait_ticks(2)
	await _aim_at(target.global_position)
	var slowed: Array[bool] = [false]
	target.hit.connect(func(_enemy: Enemy) -> void: slowed[0] = true)
	Input.action_press(&"attack")
	for tick: int in range(12):
		await physics_frame
		if slowed[0]:
			break
	Input.action_release(&"attack")
	_check(slowed[0] and Engine.time_scale < 1.0 and player.shake_left > 0.0, "A spear hit must start hit-stop and camera shake.")
	await _wait_ticks(30)
	_check(is_equal_approx(Engine.time_scale, 1.0), "Hit-stop must never leave the game slowed.")
	run.queue_free()
	# Let the audio server release playbacks before quitting.
	await _wait_ticks(15)
	if failures == 0:
		print("PASS: Q/wheel weapon switch, draw cancel, charged and tap arrows, wall-stopped and range-expired arrows, buffered dash, spear hit-stop.")
	quit(1 if failures > 0 else 0)
