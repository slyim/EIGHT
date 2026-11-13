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


## One press of attack, held for a single tick.
func _tap_attack() -> void:
	Input.action_press(&"attack")
	await _wait_ticks(1)
	Input.action_release(&"attack")
	await _wait_ticks(1)


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
	var arrows: Array[int] = []
	player.arrow_fired.connect(func(step: int) -> void: arrows.append(step))

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

	# Taps run the three-shot combo: shot, quicker shot, finisher, then it starts over.
	var enemy: Enemy = _still_enemy(run, player.global_position + Vector2(200.0, 0.0))
	await _aim_at(enemy.global_position)
	await _tap_attack()
	_check(arrows == [0], "The first tap must fire combo step 0 (got %s)." % [arrows])
	await _hud_frame()
	_check(run.hud.weapon_label.text.begins_with("BOW  1 / 3"), "The HUD must show the bow combo step (got %s)." % run.hud.weapon_label.text)
	await _wait_ticks(roundi(player.bow_cooldown * 60.0) + 1)
	await _tap_attack()
	_check(arrows == [0, 1], "A tap inside the combo window must fire step 1 (got %s)." % [arrows])
	_check(player.cooldown_left < player.bow_cooldown * 0.85, "The second shot must recover faster than the first.")
	await _wait_ticks(roundi(player.bow_cooldown * 60.0) + 1)
	await _tap_attack()
	_check(arrows == [0, 1, 2], "The third tap must fire the finisher (got %s)." % [arrows])
	await _wait_ticks(roundi(player.bow_finisher_cooldown * 60.0) + 1)
	await _tap_attack()
	_check(arrows == [0, 1, 2, 0], "After the finisher the combo must start over (got %s)." % [arrows])
	await _wait_ticks(30)
	_check(enemy.health == 50 - 4 * player.bow_damage, "Every combo arrow must deal bow damage (health %d)." % enemy.health)

	# A pause longer than the combo window starts over at step 0.
	await _wait_ticks(roundi((player.bow_cooldown + player.combo_window) * 60.0) + 4)
	await _tap_attack()
	_check(arrows.back() == 0, "A late tap must restart the combo.")

	# Switching weapons cancels the combo without firing.
	await _wait_ticks(roundi(player.bow_cooldown * 60.0) + 1)
	_key(KEY_Q, true)
	await _wait_ticks(1)
	_key(KEY_Q, false)
	_key(KEY_Q, true)
	await _wait_ticks(1)
	_key(KEY_Q, false)
	var fired: int = arrows.size()
	await _tap_attack()
	_check(arrows.size() == fired + 1 and arrows.back() == 0, "Switching weapons must reset the bow combo.")
	enemy.queue_free()
	run.enemy_count = 0

	# A structure (World layer, the old Pillar2) stops the arrow before an enemy behind it.
	player.global_position = Vector2(480.0, 300.0)
	var hidden: Enemy = _still_enemy(run, Vector2(900.0, 300.0))
	await _wait_ticks(3)
	await _aim_at(hidden.global_position)
	var arrow: Arrow = player.fire_arrow()
	await _wait_ticks(40)
	_check(not is_instance_valid(arrow), "An arrow must be freed when it hits a wall.")
	_check(hidden.health == 50, "A wall must stop the arrow before the enemy behind it.")
	hidden.queue_free()
	run.enemy_count = 0

	# An arrow is freed at the end of its range.
	player.global_position = Vector2(0.0, -300.0)
	await _wait_ticks(3)
	await _aim_at(Vector2(0.0, -1000.0))
	arrow = player.fire_arrow()
	await _wait_ticks(roundi(player.bow_range / player.arrow_speed * 60.0) + 4)
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
		print("PASS: Q/wheel weapon switch, bow three-shot combo and reset, combo cancel on switch, wall-stopped and range-expired arrows, buffered dash, spear hit-stop.")
	quit(1 if failures > 0 else 0)
