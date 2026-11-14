class_name EnemyProjectile
extends AnimatedSprite2D
## PLACEHOLDER boss projectile sprite. Dashing passes through it.

const RADIUS: float = 9.0
const LIFETIME: float = 5.0
const FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_projectile_fire.aseprite")

## PLACEHOLDER damage; every boss projectile hits for the same amount unless a
## spawner overrides it per instance.
@export var damage: int = 12
## Shots from the air (from_air) also reach an airborne player; ground shots miss it.
## From-air shots also pass over world walls and pillars.
var from_air: bool = false

var velocity: Vector2 = Vector2.ZERO
var target: MountedPlayer
var life_left: float = LIFETIME


func _ready() -> void:
	add_to_group(&"enemy_projectiles")
	# Shots from the air glow violet, ground shots ember, so the dodge reads from the glow too.
	material = preload("res://shaders/enemy_air_ammo.tres") if from_air else preload("res://shaders/enemy_ammo.tres")
	add_to_group(&"light")
	sprite_frames = FRAMES
	scale = Vector2(2.0, 2.0)
	global_rotation = velocity.angle()
	play(&"fly")


func _physics_process(delta: float) -> void:
	var start: Vector2 = global_position
	var end: Vector2 = start + velocity * delta
	global_position = end
	life_left -= delta
	if life_left <= 0.0:
		queue_free()
		return
	# Shots from the air travel over walls and pillars, so only ground shots ask the world.
	var wall_hit: Dictionary = {}
	if not from_air:
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, end, 1)
		query.hit_from_inside = true
		wall_hit = get_world_2d().direct_space_state.intersect_ray(query)
	var stop: Vector2 = wall_hit["position"] if not wall_hit.is_empty() else end
	if is_instance_valid(target):
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(target.global_position, start, stop)
		if closest.distance_to(target.global_position) <= RADIUS + MountedPlayer.HURT_RADIUS:
			if target.take_damage(damage, from_air):
				queue_free()
				return
	if not wall_hit.is_empty():
		queue_free()
