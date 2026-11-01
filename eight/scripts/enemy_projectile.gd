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
	rotation = velocity.angle()
	play(&"fly")


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life_left -= delta
	if life_left <= 0.0:
		queue_free()
		return
	if not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) <= RADIUS + MountedPlayer.HURT_RADIUS:
		if target.take_damage(1):
			queue_free()
