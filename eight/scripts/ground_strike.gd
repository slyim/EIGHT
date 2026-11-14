class_name GroundStrike
extends Node2D
## A PLACEHOLDER strike circle that fills in steps for `delay` seconds, then lands once on the
## angel if it is inside. Ember (ground): flying over it or dashing through it avoids it. Violet
## (from_air, Greed's rain): it reaches a flying angel too, so only moving out or dashing helps.
## The telegraph is the attack: what is drawn is what hits.

const FLASH_TIME: float = 0.18
const FLASH_COLOR: Color = Color(1.9, 0.9, 0.3, 1.0)

var radius: float = 56.0
var delay: float = 0.8
var damage: int = 10
var from_air: bool = false
var target: MountedPlayer
var time_left: float = 0.0
var landed: bool = false


func _ready() -> void:
	time_left = delay
	set_meta(&"light", Boss.AIR_TELEGRAPH_LIGHT if from_air else Boss.TELEGRAPH_LIGHT)
	set_meta(&"light_radius", radius * 1.4)
	add_to_group(&"light")


func _physics_process(delta: float) -> void:
	# A fallen angel ends the fight; marks still waiting vanish.
	if not landed and (not is_instance_valid(target) or target.is_dead):
		queue_free()
		return
	time_left -= delta
	if not landed and time_left <= 0.0:
		landed = true
		time_left = FLASH_TIME
		if is_instance_valid(target) and global_position.distance_to(target.global_position) <= radius + MountedPlayer.HURT_RADIUS:
			target.take_damage(damage, from_air)
	elif landed and time_left <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if not landed:
		Boss.draw_circle_tell(self, radius, floorf((1.0 - clampf(time_left / delay, 0.0, 1.0)) * 4.0) / 4.0, from_air)
		return
	draw_circle(Vector2.ZERO, radius, Color(Boss.VIOLET if from_air else FLASH_COLOR, clampf(time_left / FLASH_TIME, 0.0, 1.0)))
