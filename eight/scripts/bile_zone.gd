class_name BileZone
extends Node2D
## PLACEHOLDER bile puddle (Gluttony): left where its leap lands. While it lasts, a grounded
## angel standing in it is hurt every TICK seconds (the hurt blink spaces the hits); flying over
## it avoids it. A ground hazard: drawn ember on a dark backing with a dim fill, no antialiasing.

const TICK: float = 0.5
const FADE: float = 0.4

var radius: float = 90.0
var damage: int = 6
var lifetime: float = 4.0
var target: MountedPlayer
var time_left: float = 0.0
var tick_left: float = 0.0


func _ready() -> void:
	time_left = lifetime
	set_meta(&"light", Boss.TELEGRAPH_LIGHT)
	set_meta(&"light_radius", radius * 1.2)
	add_to_group(&"light")


func _physics_process(delta: float) -> void:
	# A fallen angel ends the fight.
	if not is_instance_valid(target) or target.is_dead:
		queue_free()
		return
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
		return
	tick_left -= delta
	if tick_left <= 0.0 and global_position.distance_to(target.global_position) <= radius + MountedPlayer.HURT_RADIUS:
		tick_left = TICK
		target.take_damage(damage)
	queue_redraw()


func _draw() -> void:
	var fade: float = clampf(time_left / FADE, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(Boss.EMBER_FILL, Boss.EMBER_FILL.a * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(Boss.BACKING, Boss.BACKING.a * fade), 6.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(Boss.EMBER, 0.7 * fade), 2.0)
