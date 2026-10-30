class_name MountedPlayer
extends CharacterBody2D
## Temporary mounted controller. All drawn geometry is PLACEHOLDER, not game art.

@export_range(80.0, 600.0, 10.0) var movement_speed: float = 260.0
@export_range(64.0, 240.0, 1.0) var spear_reach: float = 112.0
@export_range(0.1, 1.0, 0.01) var thrust_duration: float = 0.22
@export_range(0.1, 2.0, 0.01) var thrust_cooldown: float = 0.38
@export_range(1, 10, 1) var spear_damage: int = 1

var aim_direction: Vector2 = Vector2.RIGHT
var mount_direction: Vector2 = Vector2.RIGHT
var thrust_direction: Vector2 = Vector2.RIGHT
var thrust_time_left: float = 0.0
var cooldown_left: float = 0.0
var thrust_has_hit: bool = false
var spear_length: float = 56.0

@onready var spear_cast: RayCast2D = $SpearCast


func _physics_process(delta: float) -> void:
	var movement: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	velocity = movement * movement_speed
	move_and_slide()
	if not movement.is_zero_approx():
		mount_direction = movement.normalized()

	var mouse_offset: Vector2 = get_global_mouse_position() - global_position
	if not mouse_offset.is_zero_approx():
		aim_direction = mouse_offset.normalized()

	cooldown_left = maxf(0.0, cooldown_left - delta)
	if Input.is_action_pressed(&"attack") and cooldown_left <= 0.0 and thrust_time_left <= 0.0:
		thrust_direction = aim_direction
		thrust_time_left = thrust_duration
		cooldown_left = thrust_cooldown
		thrust_has_hit = false

	var resting_length: float = spear_reach * 0.5
	spear_length = resting_length
	if thrust_time_left > 0.0:
		thrust_time_left = maxf(0.0, thrust_time_left - delta)
		var progress: float = 1.0 - thrust_time_left / thrust_duration
		spear_length = lerpf(resting_length, spear_reach, sin(progress * PI))
		spear_cast.rotation = thrust_direction.angle()
		spear_cast.target_position = Vector2(spear_length, 0.0)
		if not thrust_has_hit:
			# ponytail: one centerline hit per thrust; use ShapeCast2D if spear width is needed.
			spear_cast.force_raycast_update()
			var collider: Object = spear_cast.get_collider()
			if collider is PracticeTarget:
				collider.take_hit(spear_damage)
				thrust_has_hit = true
	queue_redraw()


func _draw() -> void:
	# PLACEHOLDER: boxes = ox, circle = rider, lines = horns and spear.
	draw_set_transform(Vector2.ZERO, mount_direction.angle())
	draw_rect(Rect2(-28.0, -17.0, 56.0, 34.0), Color("678b93"))
	draw_rect(Rect2(18.0, -12.0, 18.0, 24.0), Color("91aeb4"))
	draw_line(Vector2(28.0, -12.0), Vector2(32.0, -24.0), Color("dce5e6"), 3.0, true)
	draw_line(Vector2(28.0, 12.0), Vector2(32.0, 24.0), Color("dce5e6"), 3.0, true)
	draw_circle(Vector2(-6.0, 0.0), 11.0, Color("e5e9e8"))
	draw_circle(Vector2(-3.0, 0.0), 5.0, Color("29343b"))

	var spear_direction: Vector2 = thrust_direction if thrust_time_left > 0.0 else aim_direction
	draw_set_transform(Vector2.ZERO, spear_direction.angle())
	draw_line(Vector2(12.0, 0.0), Vector2(spear_length - 10.0, 0.0), Color("d5c49a"), 4.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(spear_length, 0.0),
		Vector2(spear_length - 12.0, -5.0),
		Vector2(spear_length - 12.0, 5.0),
	]), Color("f4eee0"))
	draw_set_transform(Vector2.ZERO)
