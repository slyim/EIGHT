class_name MountedPlayer
extends CharacterBody2D
## Mounted hero controller: movement, dash, jump, a three-hit light-spear combo, and the
## descent from the sky that opens a run. Sprites and drawn effects are PLACEHOLDER art.

signal health_changed(current: int, maximum: int)
signal died
signal hurt
## step is 0 and 1 for thrusts, 2 for the sweeping finisher.
signal attack_started(step: int)
signal dashed
signal jumped
signal landed

const HURT_RADIUS: float = 20.0
const COMBO_LENGTH: int = 3
## Spear sprite length in world units (48 px art at 2x); the tip sits at spear_length.
const SPEAR_SPRITE_LENGTH: float = 96.0
const SPEAR_HEIGHT: float = 6.0
## Above this height a jump clears enemies and projectiles.
const JUMP_CLEAR_HEIGHT: float = 12.0
const SLASH_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_vfx_slash.aseprite")

@export_group("Movement")
@export_range(80.0, 600.0, 10.0) var movement_speed: float = 260.0

@export_group("Spear")
@export_range(64.0, 240.0, 1.0) var spear_reach: float = 112.0
@export_range(0.1, 1.0, 0.01) var thrust_duration: float = 0.22
@export_range(0.1, 2.0, 0.01) var thrust_cooldown: float = 0.38
@export_range(1, 10, 1) var spear_damage: int = 1
## How many targets one thrust can pass through.
@export_range(1, 20, 1) var spear_pierce: int = 1

@export_group("Combo")
## Seconds after an attack ends in which the next press continues the combo.
@export_range(0.05, 2.0, 0.01) var combo_window: float = 0.45
@export_range(0.1, 1.0, 0.01) var finisher_duration: float = 0.3
@export_range(0.1, 2.0, 0.01) var finisher_cooldown: float = 0.6
@export_range(1.0, 5.0, 0.1) var finisher_damage_multiplier: float = 2.0
@export_range(30.0, 300.0, 5.0) var finisher_arc_degrees: float = 140.0

@export_group("Dash")
@export_range(200.0, 1600.0, 10.0) var dash_speed: float = 760.0
@export_range(0.05, 0.5, 0.01) var dash_duration: float = 0.16
@export_range(0.1, 3.0, 0.05) var dash_cooldown: float = 0.55

@export_group("Jump")
@export_range(0.2, 1.5, 0.05) var jump_duration: float = 0.55
@export_range(16.0, 160.0, 2.0) var jump_height: float = 56.0
@export_range(0.0, 1.0, 0.05) var jump_cooldown: float = 0.15

@export_group("Life")
@export_range(1, 20, 1) var max_health: int = 5
@export_range(0.1, 3.0, 0.05) var hurt_invulnerability: float = 1.0
@export_range(16.0, 600.0, 4.0) var pickup_radius: float = 90.0

var aim_direction: Vector2 = Vector2.RIGHT
var mount_direction: Vector2 = Vector2.RIGHT
var thrust_direction: Vector2 = Vector2.RIGHT
var spear_direction: Vector2 = Vector2.RIGHT
var attack_time_left: float = 0.0
var attack_duration: float = 0.22
var attack_step: int = -1
var cooldown_left: float = 0.0
var combo_window_left: float = 0.0
var thrust_hits_left: int = 0
var finisher_resolved: bool = true
var spear_length: float = 56.0
var dash_direction: Vector2 = Vector2.RIGHT
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var jump_time: float = -1.0
var jump_cooldown_left: float = 0.0
var height: float = 0.0
var descent_height: float = 0.0
var descent_duration: float = 0.0
var descent_left: float = 0.0
var shake_left: float = 0.0
var shake_strength: float = 0.0
var health: int = 0
var invulnerable_left: float = 0.0
var is_dead: bool = false

@onready var spear_cast: RayCast2D = $SpearCast
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var spear: AnimatedSprite2D = $Spear
@onready var camera: Camera2D = $Camera2D
@onready var sprite_base: Vector2 = sprite.position


func _ready() -> void:
	health = max_health


## Opens a run: the angel falls from the sky and lands. Input waits until landing.
func begin_descent(from_height: float, duration: float) -> void:
	descent_height = from_height
	descent_duration = duration
	descent_left = duration
	height = from_height


func is_descending() -> bool:
	return descent_left > 0.0


func is_airborne() -> bool:
	return height > JUMP_CLEAR_HEIGHT


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	if is_descending():
		descent_left = maxf(0.0, descent_left - delta)
		var t: float = 1.0 - descent_left / descent_duration
		height = descent_height * (1.0 - t * t)
		if descent_left == 0.0:
			height = 0.0
			_land(14.0)
		_update_visuals(Vector2.ZERO, delta)
		return
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	jump_cooldown_left = maxf(0.0, jump_cooldown_left - delta)

	var movement: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	var mouse_offset: Vector2 = get_global_mouse_position() - global_position
	if not mouse_offset.is_zero_approx():
		aim_direction = mouse_offset.normalized()

	_update_jump(delta)
	if Input.is_action_just_pressed(&"dash") and dash_cooldown_left <= 0.0 and dash_time_left <= 0.0:
		dash_direction = movement.normalized() if not movement.is_zero_approx() else aim_direction
		dash_time_left = dash_duration
		dash_cooldown_left = dash_duration + dash_cooldown
		dashed.emit()

	if dash_time_left > 0.0:
		dash_time_left = maxf(0.0, dash_time_left - delta)
		velocity = dash_direction * dash_speed
	else:
		velocity = movement * movement_speed
	move_and_slide()
	if not movement.is_zero_approx():
		mount_direction = movement.normalized()

	_update_attack(delta)
	_update_visuals(movement, delta)


func _update_jump(delta: float) -> void:
	if jump_time < 0.0:
		if Input.is_action_just_pressed(&"jump") and jump_cooldown_left <= 0.0 and dash_time_left <= 0.0:
			jump_time = 0.0
			jumped.emit()
		return
	jump_time += delta
	var t: float = jump_time / jump_duration
	if t >= 1.0:
		jump_time = -1.0
		height = 0.0
		jump_cooldown_left = jump_cooldown
		_land(4.0)
	else:
		height = 4.0 * jump_height * t * (1.0 - t)


func _land(shake: float) -> void:
	shake_left = 0.25
	shake_strength = shake
	landed.emit()


func _update_attack(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	combo_window_left = maxf(0.0, combo_window_left - delta)
	if Input.is_action_pressed(&"attack") and cooldown_left <= 0.0 and attack_time_left <= 0.0:
		attack_step = (attack_step + 1) % COMBO_LENGTH if combo_window_left > 0.0 else 0
		thrust_direction = aim_direction
		if attack_step == COMBO_LENGTH - 1:
			attack_duration = finisher_duration
			cooldown_left = finisher_cooldown
			finisher_resolved = false
			_spawn_slash()
		else:
			attack_duration = thrust_duration
			# The second thrust follows faster than the first.
			cooldown_left = thrust_cooldown * (0.8 if attack_step == 1 else 1.0)
			thrust_hits_left = spear_pierce
			spear_cast.clear_exceptions()
		attack_time_left = attack_duration
		attack_started.emit(attack_step)

	var resting_length: float = spear_reach * 0.5
	spear_length = resting_length
	spear_direction = aim_direction
	if attack_time_left <= 0.0:
		return
	attack_time_left = maxf(0.0, attack_time_left - delta)
	var progress: float = 1.0 - attack_time_left / attack_duration
	if attack_step == COMBO_LENGTH - 1:
		var half: float = deg_to_rad(finisher_arc_degrees) * 0.5
		spear_length = spear_reach * 0.9
		spear_direction = thrust_direction.rotated(lerpf(-half, half, progress))
		if not finisher_resolved and progress >= 0.35:
			finisher_resolved = true
			_resolve_finisher()
	else:
		spear_length = lerpf(resting_length, spear_reach, sin(progress * PI))
		spear_direction = thrust_direction
		spear_cast.rotation = thrust_direction.angle()
		spear_cast.target_position = Vector2(spear_length, 0.0)
		_resolve_spear_hits()
	if attack_time_left == 0.0:
		combo_window_left = combo_window if attack_step < COMBO_LENGTH - 1 else 0.0


## Each target is hit at most once per thrust; walls stop the spear.
func _resolve_spear_hits() -> void:
	# ponytail: centerline hits only; use ShapeCast2D if spear width is needed.
	spear_cast.force_raycast_update()
	while thrust_hits_left > 0 and spear_cast.is_colliding():
		var collider: Object = spear_cast.get_collider()
		if not collider.has_method(&"take_hit"):
			return
		collider.call(&"take_hit", spear_damage)
		thrust_hits_left -= 1
		spear_cast.add_exception(collider as CollisionObject2D)
		spear_cast.force_raycast_update()


## The finisher strikes every target inside its arc once, unless a wall is in the way.
func _resolve_finisher() -> void:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = spear_reach
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = spear_cast.collision_mask & ~1
	query.exclude = [get_rid()]
	var half: float = deg_to_rad(finisher_arc_degrees) * 0.5
	var damage: int = maxi(1, roundi(spear_damage * finisher_damage_multiplier))
	for result: Dictionary in space.intersect_shape(query, 128):
		var collider: Node2D = result["collider"] as Node2D
		if collider == null or not collider.has_method(&"take_hit"):
			continue
		var offset: Vector2 = collider.global_position - global_position
		if offset.length() > 24.0 and absf(thrust_direction.angle_to(offset)) > half:
			continue
		var line_of_sight: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			global_position, collider.global_position, 1
		)
		if not space.intersect_ray(line_of_sight).is_empty():
			continue
		collider.call(&"take_hit", damage)


func _spawn_slash() -> void:
	var arc: AnimatedSprite2D = AnimatedSprite2D.new()
	arc.sprite_frames = SLASH_FRAMES
	arc.position = Vector2(0.0, -SPEAR_HEIGHT - height)
	arc.rotation = thrust_direction.angle()
	arc.scale = Vector2(2.0, 2.0) * (spear_reach / 112.0)
	arc.animation_finished.connect(arc.queue_free)
	add_child(arc)
	arc.play(&"slash")


func _update_visuals(movement: Vector2, delta: float) -> void:
	var animation: StringName = &"idle"
	if is_descending():
		animation = &"descend"
	elif height > 0.0:
		animation = &"jump"
	elif dash_time_left > 0.0:
		animation = &"dash"
	elif not movement.is_zero_approx():
		animation = &"run"
	if sprite.animation != animation:
		sprite.play(animation)
	# The art faces right; mirror it while the mount heads left.
	if absf(mount_direction.x) > 0.01:
		sprite.flip_h = mount_direction.x < 0.0
	sprite.position = sprite_base - Vector2(0.0, height)

	spear.visible = not is_descending()
	spear.rotation = spear_direction.angle()
	spear.position = Vector2(0.0, -SPEAR_HEIGHT - height) + spear_direction * (spear_length - SPEAR_SPRITE_LENGTH)

	shake_left = maxf(0.0, shake_left - delta)
	var strength: float = shake_strength * shake_left / 0.25
	camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))

	var blink: bool = invulnerable_left > 0.0 and int(invulnerable_left * 16.0) % 2 == 0
	modulate.a = 0.35 if blink else 1.0
	queue_redraw()


func is_invulnerable() -> bool:
	return invulnerable_left > 0.0 or dash_time_left > 0.0 or is_airborne() or is_descending()


## Returns true when the damage landed.
func take_damage(amount: int) -> bool:
	if is_dead or is_invulnerable() or amount <= 0:
		return false
	health = maxi(0, health - amount)
	invulnerable_left = hurt_invulnerability
	health_changed.emit(health, max_health)
	hurt.emit()
	if health == 0:
		is_dead = true
		modulate = Color(0.45, 0.45, 0.45, 1.0)
		sprite.stop()
		spear.visible = false
		died.emit()
	return true


func heal(amount: int) -> void:
	if is_dead:
		return
	health = mini(max_health, health + maxi(0, amount))
	health_changed.emit(health, max_health)


func _draw() -> void:
	# PLACEHOLDER ground shadow (shrinks while airborne) and the descent light beam.
	var lift: float = clampf(1.0 - height / 160.0, 0.35, 1.0)
	draw_set_transform(Vector2(0.0, 14.0), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 22.0 * lift, Color(0.0275, 0.0039, 0.0353, 0.75))
	draw_set_transform(Vector2.ZERO)
	if is_descending():
		var glow: float = 1.0 - descent_left / descent_duration
		draw_rect(Rect2(-14.0, -900.0, 28.0, 914.0), Color(0.792, 0.922, 0.878, 0.12 + 0.18 * glow))
		draw_rect(Rect2(-5.0, -900.0, 10.0, 914.0), Color(0.792, 0.922, 0.878, 0.2 + 0.3 * glow))
