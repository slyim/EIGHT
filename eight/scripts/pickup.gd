class_name Pickup
extends AnimatedSprite2D
## PLACEHOLDER collectible sprite: experience, life, or an item.

signal collected(pickup: Pickup)

enum Kind { XP, HEART, ITEM }

const COLLECT_RADIUS: float = 26.0
const FRAMES: Array[SpriteFrames] = [
	preload("res://assets/art/placeholder/placeholder_pickup_xp.aseprite"),
	preload("res://assets/art/placeholder/placeholder_pickup_life.aseprite"),
	preload("res://assets/art/placeholder/placeholder_pickup_item.aseprite"),
]

## PLACEHOLDER light per kind, in Kind order (alpha is energy / 4), and its reach in px.
const LIGHTS: Array[Color] = [Color(0.447, 0.604, 0.631, 0.3), Color(0.9, 0.3, 0.4, 0.35), Color(0.902, 0.886, 0.62, 0.45)]
const LIGHT_RADIUS: float = 44.0

var kind: Kind = Kind.XP
var value: int = 1
var item_index: int = -1
var target: MountedPlayer
var attracted: bool = false
var pull_speed: float = 160.0


func _ready() -> void:
	sprite_frames = FRAMES[kind]
	material = preload("res://shaders/pickup_light.tres")
	set_meta(&"light", LIGHTS[kind])
	set_meta(&"light_radius", LIGHT_RADIUS)
	add_to_group(&"light")
	# Always 2x so every art pixel matches; bigger drops need bigger art to read bigger.
	scale = Vector2(2.0, 2.0)
	play(&"idle")
	frame = randi() % sprite_frames.get_frame_count(&"idle")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_dead:
		return
	# Life is left on the ground while the player is at full health.
	if kind == Kind.HEART and target.health >= target.max_health:
		return
	var offset: Vector2 = target.global_position - global_position
	var distance: float = offset.length()
	if distance <= COLLECT_RADIUS:
		collected.emit(self)
		queue_free()
		return
	# Items must be walked over; experience and life are pulled in.
	if kind != Kind.ITEM and distance <= target.pickup_radius:
		attracted = true
	if attracted:
		pull_speed += 900.0 * delta
		global_position += offset / distance * minf(distance, pull_speed * delta)
