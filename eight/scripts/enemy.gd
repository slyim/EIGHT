class_name Enemy
extends CharacterBody2D
## PLACEHOLDER horde enemy: placeholder sprite and test stats, not an enemy design.

signal died(enemy: Enemy)
signal hit(enemy: Enemy)

# PLACEHOLDER eye regions in untrimmed atlas pixels; all animation poses included.
const EYE_PROFILES: Dictionary = {
	"husk": Vector4(19, 15, 22, 17), "imp": Vector4(19, 11, 20, 14),
	"brute": Vector4(25, 13, 27, 15), "pride": Vector4(30, 25, 35, 27),
	"greed": Vector4(25, 34, 40, 36), "lust": Vector4(30, 23, 35, 25),
	"envy": Vector4(24, 20, 40, 55), "gluttony": Vector4(22, 15, 35, 20),
	"wrath": Vector4(29, 26, 36, 29), "sloth": Vector4(50, 28, 58, 36),
	"satan": Vector4(29, 22, 36, 24),
}
const EYE_MATERIAL: ShaderMaterial = preload("res://shaders/eyes.tres")
const FLASH_COLOR: Color = Color(3.0, 3.0, 3.0, 1.0)

@export_range(1, 5000, 1) var max_health: int = 2
@export_range(0.0, 600.0, 5.0) var speed: float = 105.0
@export_range(0, 100, 1) var contact_damage: int = 1
@export_range(0, 500, 1) var xp_value: int = 1
@export_range(4.0, 120.0, 1.0) var radius: float = 14.0
@export_range(0.0, 1000.0, 10.0) var knockback_strength: float = 240.0
@export var frames: SpriteFrames

## True for flying enemies (physics layer 5): they ignore walls, and their attacks
## reach an airborne player where ground attacks miss.
var flying: bool = false
var target: MountedPlayer
var health: int = 0
var hit_flash: float = 0.0
var knockback: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	health = max_health
	(collision_shape.shape as CircleShape2D).radius = radius
	if frames != null:
		sprite.sprite_frames = frames
		# Colour keys use the unmodulated texture, so flashes/tints cannot turn eyes white.
		sprite.material = EYE_MATERIAL
		var kind: String = frames.resource_path.get_file().get_basename().get_slice("_", 2)
		sprite.set_instance_shader_parameter(&"eye_bounds", EYE_PROFILES.get(kind, Vector4.ZERO))
		sprite.set_instance_shader_parameter(&"frame_size", 64.0 if self is Boss else 32.0)
		sprite.set_instance_shader_parameter(&"dark_eyes", kind in ["pride", "greed", "sloth"])
		sprite.set_instance_shader_parameter(&"pale_eyes", kind not in ["greed", "sloth"])
		sprite.set_instance_shader_parameter(&"mint_eyes", kind == "satan")
		sprite.play(_base_animation())
		sprite.frame = randi() % sprite.sprite_frames.get_frame_count(sprite.animation)


func _base_animation() -> StringName:
	return &"walk"


func _physics_process(delta: float) -> void:
	if health <= 0 or not is_instance_valid(target):
		return
	_tick_flash(delta)
	var to_target: Vector2 = target.global_position - global_position
	velocity = to_target.normalized() * speed + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 1400.0 * delta)
	move_and_slide()
	_face(to_target.x)
	_touch_player()


## The art faces right; mirror it toward the player.
func _face(direction_x: float) -> void:
	if absf(direction_x) > 1.0:
		sprite.flip_h = direction_x < 0.0


func _tick_flash(delta: float) -> void:
	if hit_flash > 0.0:
		hit_flash = maxf(0.0, hit_flash - delta)
		if hit_flash == 0.0:
			sprite.modulate = Color.WHITE


func _touch_player() -> void:
	if global_position.distance_to(target.global_position) <= radius + MountedPlayer.HURT_RADIUS:
		target.take_damage(contact_damage)


func take_hit(damage: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - maxi(0, damage))
	hit_flash = 0.08
	sprite.modulate = FLASH_COLOR
	if is_instance_valid(target):
		knockback = (global_position - target.global_position).normalized() * knockback_strength
	hit.emit(self)
	if health == 0:
		collision_shape.set_deferred(&"disabled", true)
		died.emit(self)
		queue_free()

