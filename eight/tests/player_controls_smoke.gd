extends SceneTree
## Physical controls and dash-boundary regression checks; native Godot only.

const PLAYER_SCENE: PackedScene = preload("res://scenes/mounted_player.tscn")

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


func _key(code: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _run() -> void:
	var player: MountedPlayer = PLAYER_SCENE.instantiate() as MountedPlayer
	root.add_child(player)
	await _wait_ticks(3)
	var attacks: Array[int] = []
	player.attack_started.connect(func(step: int) -> void: attacks.append(step))

	# Exercise physical keys rather than action_press, which bypasses the map.
	_key(KEY_SPACE, true)
	await _wait_ticks(30)
	_check(player.is_airborne() and player.flying, "Holding Space must take off and stay up.")
	_check(attacks.is_empty(), "Space must not also attack.")
	_key(KEY_SPACE, false)
	await _wait_ticks(30)
	_check(player.height == 0.0 and not player.flying, "Releasing Space must land.")
	_key(KEY_J, true)
	await _wait_ticks(3)
	_check(attacks == [0], "J must start the spear combo.")
	_check(player.height == 0.0 and not player.flying, "J must not also take off.")
	_key(KEY_J, false)
	await _wait_ticks(45)

	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await _wait_ticks(3)
	_check(attacks.size() == 2, "Left mouse button must still attack.")
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	Input.parse_input_event(click)
	await _wait_ticks(30)

	# A dash with less than one tick left must never move at dash speed while
	# exposing the player to damage. It expires before this tick's movement.
	player.dash_time_left = player.get_physics_process_delta_time() * 0.5
	player.dash_cooldown_left = 0.5
	player.dash_direction = Vector2.RIGHT
	player.invulnerable_left = 0.0
	var start: Vector2 = player.global_position
	await _wait_ticks(1)
	_check(player.global_position.is_equal_approx(start), "An expired dash must stop before moving without protection.")
	_check(not player.is_invulnerable(), "Dash protection must end once normal movement resumes.")
	_check(player.take_damage(1), "Damage must resume after the dash expires.")

	# Check a live dash separately so the boundary fix cannot disable dashing (after the
	# hurt hit-stop above has let time run again).
	while Engine.time_scale < 1.0:
		await process_frame
	player.invulnerable_left = 0.0
	player.dash_cooldown_left = 0.0
	Input.action_press(&"dash")
	await _wait_ticks(2)
	Input.action_release(&"dash")
	_check(player.global_position.distance_to(start) > 10.0, "A live dash must move at dash speed.")
	_check(player.is_invulnerable() and not player.take_damage(1), "A live dash must block damage.")

	player.queue_free()
	await _wait_ticks(2)
	if failures == 0:
		print("PASS: holding Space flies independently, J and LMB attack, dash movement and protection expire together.")
	quit(1 if failures > 0 else 0)
