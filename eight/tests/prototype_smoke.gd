extends SceneTree
## Native Godot smoke check; no test framework or external assets required.

const PROTOTYPE: PackedScene = preload("res://scenes/prototype.tscn")

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
	# Inject physical-window coordinates, including the headless viewport's stretch.
	motion.position = root.get_final_transform() * root.get_canvas_transform() * world_point
	motion.global_position = motion.position
	Input.warp_mouse(motion.position)
	Input.parse_input_event(motion)
	await _wait_ticks(2)


func _run() -> void:
	var world: Node2D = PROTOTYPE.instantiate() as Node2D
	root.add_child(world)
	current_scene = world
	await _wait_ticks(3)
	var player: MountedPlayer = world.get_node("MountedPlayer") as MountedPlayer
	var target: PracticeTarget = world.get_node("PracticeTarget") as PracticeTarget
	_check(target.health == 3, "Practice target must start with three test hit points.")

	player.position = Vector2(0.0, 250.0)
	var start: Vector2 = player.position
	Input.action_press(&"move_right")
	await _wait_ticks(24)
	Input.action_release(&"move_right")
	var straight_distance: float = player.position.distance_to(start)
	_check(straight_distance > 80.0, "Movement input must move the mounted player.")

	player.position = start
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	await _wait_ticks(24)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	var diagonal_distance: float = player.position.distance_to(start)
	_check(absf(diagonal_distance - straight_distance) < 8.0, "Diagonal speed must be normalized.")

	player.position = Vector2(900.0, 250.0)
	Input.action_press(&"move_right")
	await _wait_ticks(30)
	Input.action_release(&"move_right")
	_check(player.position.x > 920.0 and player.position.x < 939.0, "Walls must block mounted movement.")

	player.position = Vector2(140.0, 0.0)
	await _wait_ticks(3)
	await _aim_at(target.global_position)
	_check(player.aim_direction.dot(Vector2.RIGHT) > 0.99, "Mouse input must aim the spear.")
	Input.action_press(&"attack")
	await _wait_ticks(18)
	Input.action_release(&"attack")
	_check(target.health == 2, "A thrust must deal damage only once, not once per physics tick.")
	await _wait_ticks(24)

	player.position = Vector2.ZERO
	await _wait_ticks(3)
	await _aim_at(target.global_position)
	Input.action_press(&"attack")
	await _wait_ticks(18)
	Input.action_release(&"attack")
	_check(target.health == 2, "Out-of-range spear attacks must not damage the target.")
	await _wait_ticks(24)

	player.position = Vector2(900.0, 250.0)
	target.position = Vector2(1000.0, 250.0)
	await _wait_ticks(3)
	await _aim_at(target.global_position)
	Input.action_press(&"attack")
	await _wait_ticks(18)
	Input.action_release(&"attack")
	_check(target.health == 2, "A wall must stop the spear before a target behind it.")
	await _wait_ticks(24)

	player.position = Vector2(140.0, 0.0)
	target.position = Vector2(220.0, 0.0)
	await _wait_ticks(3)
	await _aim_at(target.global_position)
	Input.action_press(&"attack")
	await _wait_ticks(60)
	Input.action_release(&"attack")
	_check(target.health == 0, "Holding attack must repeat thrusts and clear the target.")
	_check(target.collision_shape.disabled, "A cleared target must stop blocking movement.")

	var reset_key: InputEventKey = InputEventKey.new()
	reset_key.physical_keycode = KEY_R
	reset_key.pressed = true
	Input.parse_input_event(reset_key)
	await _wait_ticks(3)
	reset_key = InputEventKey.new()
	reset_key.physical_keycode = KEY_R
	reset_key.pressed = false
	Input.parse_input_event(reset_key)
	var reset_target: PracticeTarget = current_scene.get_node("PracticeTarget") as PracticeTarget
	var reset_player: MountedPlayer = current_scene.get_node("MountedPlayer") as MountedPlayer
	_check(reset_target.health == 3, "Reset input must restore the practice target.")
	_check(reset_player.position.is_zero_approx(), "Reset input must restore the player's position.")

	if failures == 0:
		print("PASS: mounted movement, normalized diagonals, collision, aiming, spear damage, range, wall blocking, held attack, target clearing, and reset.")
	quit(1 if failures > 0 else 0)
