class_name Enemy
extends CharacterBody2D
## PLACEHOLDER horde enemy: placeholder sprite and test stats, not an enemy design.

signal died(enemy: Enemy)
signal hit(enemy: Enemy)
## Every hit: how much (the weapon's damage) and whether it was a finisher or evolved strike.
signal damaged(enemy: Enemy, amount: int, heavy: bool)

## Sin glow: every cream pixel of the sprite glows red, and the sprite is a small red light.
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
		# The colour key uses the unmodulated texture, so flashes/tints cannot turn eyes white.
		sprite.material = EYE_MATERIAL
		sprite.add_to_group(&"light")
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
		# Enemies too heavy to push (bosses, guards) shudder a pixel instead.
		sprite.offset = Vector2(randi_range(-1, 1), 0.0) if knockback_strength <= 0.0 and hit_flash > 0.0 else Vector2.ZERO
		if hit_flash == 0.0:
			sprite.modulate = Color.WHITE


func _touch_player() -> void:
	if global_position.distance_to(target.global_position) <= radius + MountedPlayer.HURT_RADIUS:
		target.take_damage(contact_damage)


## heavy marks a finisher or evolved strike; from is where the blow came from (an arrow's
## tail, a light circle's center), so the push follows it. By default the push is away from
## the angel.
func take_hit(damage: int, heavy: bool = false, from: Vector2 = Vector2.INF) -> void:
	if health <= 0:
		return
	health = maxi(0, health - maxi(0, damage))
	hit_flash = 0.08
	sprite.modulate = FLASH_COLOR
	if from == Vector2.INF and is_instance_valid(target):
		from = target.global_position
	if from != Vector2.INF:
		var away: Vector2 = global_position - from
		knockback = (away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * knockback_strength
	damaged.emit(self, maxi(0, damage), heavy)
	hit.emit(self)
	if health == 0:
		collision_shape.set_deferred(&"disabled", true)
		died.emit(self)
		queue_free()

