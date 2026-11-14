class_name BileZone
extends Node2D
## PLACEHOLDER ground puddle: Gluttony's bile (left where its leap lands) or Sloth's sludge.
## While it lasts, a grounded angel standing in bile is hurt every TICK seconds (the hurt blink
## spaces the hits), and one standing in sludge (slow_factor above 0) is slowed while inside;
## flying over either avoids it. A ground hazard: ember edges on a dark backing, no antialiasing.

const TICK: float = 0.5
const FADE: float = 0.4
## Seconds a sludge slow lingers after stepping out.
const SLOW_LINGER: float = 0.3
const SLUDGE_FILL: Color = Color(0.3, 0.35, 0.5, 0.25)

var radius: float = 90.0
var damage: int = 6
var lifetime: float = 4.0
## Above 0, the puddle slows instead of hurting (sludge).
var slow_factor: float = 0.0
var target: MountedPlayer
var time_left: float = 0.0
var tick_left: float = 0.0


func _ready() -> void:
	time_left = lifetime
	# Bile glows like the other ember hazards; sludge stays dark (it slows, it never hurts).
	if slow_factor <= 0.0:
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
	var inside: bool = global_position.distance_to(target.global_position) <= radius + MountedPlayer.HURT_RADIUS
	if slow_factor > 0.0:
		if inside:
			target.apply_slow(slow_factor, SLOW_LINGER)
	else:
		tick_left -= delta
		if tick_left <= 0.0 and inside:
			tick_left = TICK
			target.take_damage(damage)
	queue_redraw()


func _draw() -> void:
	var fade: float = clampf(time_left / FADE, 0.0, 1.0)
	var fill: Color = SLUDGE_FILL if slow_factor > 0.0 else Boss.EMBER_FILL
	draw_circle(Vector2.ZERO, radius, Color(fill, fill.a * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(Boss.BACKING, Boss.BACKING.a * fade), 6.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(Boss.SLUDGE_COLOR if slow_factor > 0.0 else Boss.EMBER, 0.7 * fade), 2.0)
