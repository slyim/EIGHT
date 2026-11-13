class_name Pickup
extends AnimatedSprite2D
## PLACEHOLDER collectible sprite: experience, life, an item, a weapon evolution (the item
## art, tinted by weapon: mint for the spear, violet for the bow), or a side-weapon relic (gold).

signal collected(pickup: Pickup)

enum Kind { XP, HEART, ITEM, EVOLUTION, RELIC }

const COLLECT_RADIUS: float = 26.0
const FRAMES: Array[SpriteFrames] = [
	preload("res://assets/art/placeholder/placeholder_pickup_xp.aseprite"),
	preload("res://assets/art/placeholder/placeholder_pickup_life.aseprite"),
	preload("res://assets/art/placeholder/placeholder_pickup_item.aseprite"),
	preload("res://assets/art/placeholder/placeholder_pickup_item.aseprite"),
	preload("res://assets/art/placeholder/placeholder_pickup_item.aseprite"),
]
## Side-weapon relic tint (gold).
const RELIC_TINT: Color = Color(1.0, 0.85, 0.45, 1.0)
## Evolution tint per MountedPlayer.Weapon.
const EVOLUTION_TINTS: Array[Color] = [Color(0.6, 1.0, 0.9, 1.0), Color(0.78, 0.6, 1.0, 1.0)]

## PLACEHOLDER light per kind, in Kind order (alpha is energy / 4), and its reach in px.
const LIGHTS: Array[Color] = [Color(0.447, 0.604, 0.631, 0.3), Color(0.9, 0.3, 0.4, 0.35), Color(0.902, 0.886, 0.62, 0.45), Color(0.6, 1.0, 0.9, 0.55), Color(1.0, 0.85, 0.45, 0.55)]
const LIGHT_RADIUS: float = 44.0

var kind: Kind = Kind.XP
var value: int = 1
## ITEM: index into Run.ITEMS. EVOLUTION: the MountedPlayer.Weapon it evolves.
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
	if kind == Kind.EVOLUTION:
		self_modulate = EVOLUTION_TINTS[item_index]
	elif kind == Kind.RELIC:
		self_modulate = RELIC_TINT
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
	# Items and evolutions must be walked over; experience and life are pulled in.
	if kind in [Kind.XP, Kind.HEART] and distance <= target.pickup_radius:
		attracted = true
	if attracted:
		pull_speed += 900.0 * delta
		global_position += offset / distance * minf(distance, pull_speed * delta)
