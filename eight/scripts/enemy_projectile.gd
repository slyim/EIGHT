class_name EnemyProjectile
extends AnimatedSprite2D
## PLACEHOLDER boss projectile sprite. Dashing passes through it.

const RADIUS: float = 9.0
const LIFETIME: float = 5.0
const FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_projectile_fire.aseprite")

var velocity: Vector2 = Vector2.ZERO
var target: MountedPlayer
var life_left: float = LIFETIME


func _ready() -> void:
	add_to_group(&"enemy_projectiles")
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
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, end, 1)
	query.hit_from_inside = true
	var wall_hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	var stop: Vector2 = wall_hit["position"] if not wall_hit.is_empty() else end
	if is_instance_valid(target):
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(target.global_position, start, stop)
		if closest.distance_to(target.global_position) <= RADIUS + MountedPlayer.HURT_RADIUS:
			if target.take_damage(1):
				queue_free()
				return
	if not wall_hit.is_empty():
		queue_free()
