class_name FlyingEnemy
extends Enemy
## PLACEHOLDER flying horde enemy: it hovers above the plain, keeps its preferred
## distance from the player instead of piling on, and fires an aimed shot after a
## short wind-up tell. Its shots reach an airborne player and pass over walls and
## pillars (from_air), and its contact hurts from the air too. Art reuses the imp and
## boss-projectile placeholder frames (tinted here and in the scene), so it is not an
## enemy design; a later wave adds a red-glow shader for enemy shots.

## Seconds the aiming tell shows before the shot leaves.
const WINDUP_TIME: float = 0.5
## It stops closing in anywhere inside this band around preferred_distance.
const KEEP_SLACK: float = 24.0
const BOB_AMPLITUDE: float = 5.0
const BOB_FREQUENCY: float = 3.0
## PLACEHOLDER shot look: smaller and tinted so it reads apart from boss shots.
const SHOT_SCALE: float = 1.5
const SHOT_COLOR: Color = Color(0.75, 0.64, 1.0, 1.0)

## Distance it tries to hold from the player.
@export_range(0.0, 600.0, 10.0) var preferred_distance: float = 170.0
## Seconds between shots.
@export_range(0.5, 10.0, 0.1) var fire_interval: float = 2.2
@export_range(40.0, 1000.0, 10.0) var shot_speed: float = 320.0
@export_range(1, 100, 1) var shot_damage: int = 10
## Body height above its ground position; the collision shape stays on the ground,
## where the arrow and spear rays look for enemies.
@export_range(0.0, 200.0, 2.0) var hover_height: float = 36.0

## Seconds until the next wind-up; the first shot comes a little early.
var fire_left: float = 1.4
var windup_left: float = 0.0
var aim: Vector2 = Vector2.RIGHT
var bob_time: float = 0.0
## Current body height above the node position, with the gentle bob added.
var lift: float = 0.0

@onready var sprite_base: Vector2 = sprite.position


func _init() -> void:
	flying = true


func _physics_process(delta: float) -> void:
	if health <= 0 or not is_instance_valid(target):
		return
	_tick_flash(delta)
	bob_time += delta
	var to_target: Vector2 = target.global_position - global_position
	var distance: float = to_target.length()
	aim = to_target / distance if distance > 0.001 else Vector2.RIGHT
	if windup_left > 0.0:
		# Hold still while winding up so the tell reads where the shot will come from.
		windup_left -= delta
		velocity = Vector2.ZERO
		if windup_left <= 0.0:
			_fire()
			fire_left = fire_interval
			queue_redraw()
	else:
		fire_left -= delta
		if fire_left <= 0.0:
			windup_left = WINDUP_TIME
			queue_redraw()
		# Hold near the preferred distance instead of piling onto the player.
		if distance > preferred_distance + KEEP_SLACK:
			velocity = aim * speed
		elif distance < preferred_distance - KEEP_SLACK:
			velocity = -aim * speed
		else:
			velocity = Vector2.ZERO
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 1400.0 * delta)
	move_and_slide()
	_face(to_target.x)
	_hover()
	if windup_left > 0.0:
		queue_redraw()
	_touch_player()


func _hover() -> void:
	lift = hover_height + sin(bob_time * BOB_FREQUENCY) * BOB_AMPLITUDE
	sprite.position = sprite_base - Vector2(0.0, lift)


func _fire() -> void:
	var shot: EnemyProjectile = EnemyProjectile.new()
	shot.velocity = aim * shot_speed
	shot.damage = shot_damage
	shot.from_air = true
	shot.target = target
	get_parent().add_child(shot)
	shot.global_position = global_position + aim * radius
	# The base sizes boss shots; shrink and tint after add_child so this shot reads apart.
	shot.scale = Vector2(SHOT_SCALE, SHOT_SCALE)
	shot.modulate = SHOT_COLOR


## Contact always hurts from the air: it reaches a grounded and an airborne player alike.
func _touch_player() -> void:
	if global_position.distance_to(target.global_position) <= radius + MountedPlayer.HURT_RADIUS:
		target.take_damage(contact_damage, true)


func _draw() -> void:
	# PLACEHOLDER ground shadow: the body hovers above the node, which stays on the ground.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 13.0, Color(0.0275, 0.0039, 0.0353, 0.6))
	draw_set_transform(Vector2.ZERO)
	if windup_left > 0.0:
		# Short wind-up tell: a thin glint along the path the shot will take.
		draw_line(Vector2.ZERO, aim * 220.0, Color(0.792, 0.922, 0.878, 0.55), 2.0)
