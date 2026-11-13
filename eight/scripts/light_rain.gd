class_name LightRain
extends Node2D
## Rain of Light (bow evolution): a marked circle where, after a short delay, arrows of light
## fall and strike every enemy inside it, on the ground or in the air. Walls do not stop
## light from the sky. The telegraph and streaks are PLACEHOLDER code-drawn shapes, drawn on
## whole art pixels (even widths, no antialiasing).

const COLOR: Color = Color(0.792, 0.922, 0.878, 1.0)
const GLOW: Color = Color(1.6, 2.0, 1.85, 1.0)
const STREAKS: int = 7
## Seconds the falling streaks show after the strike.
const STRIKE_TIME: float = 0.22

var radius: float = 110.0
var damage: int = 2
var delay: float = 0.35
## Practice targets, enemies, and flying enemies (layers 3-5).
var hit_mask: int = 28
## Query cap: above Run's largest horde (max_enemies tops out at 1000), so none is skipped.
const MAX_TARGETS: int = 1024
var struck: bool = false
var time_left: float = 0.0


func _ready() -> void:
	time_left = delay
	set_meta(&"light", Color(0.55, 1.0, 0.85, 0.35))
	set_meta(&"light_radius", radius * 1.2)
	add_to_group(&"light")


func _physics_process(delta: float) -> void:
	time_left -= delta
	if not struck and time_left <= 0.0:
		struck = true
		time_left = STRIKE_TIME
		_strike()
	elif struck and time_left <= 0.0:
		queue_free()
		return
	queue_redraw()


## Every enemy inside the circle takes one hit.
func _strike() -> void:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = hit_mask
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, MAX_TARGETS):
		var collider: Object = result["collider"]
		if collider != null and collider.has_method(&"take_hit"):
			collider.call(&"take_hit", damage)


func _draw() -> void:
	if not struck:
		# The telegraph: an outline, and a fill that grows until the strike.
		var progress: float = 1.0 - clampf(time_left / delay, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(COLOR, 0.8), 2.0)
		draw_circle(Vector2.ZERO, radius * progress, Color(COLOR, 0.18))
		return
	var fade: float = clampf(time_left / STRIKE_TIME, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(COLOR, 0.25 * fade))
	for index: int in range(STREAKS):
		var x: float = roundf((float(index) / (STREAKS - 1) - 0.5) * radius * 1.4 / 2.0) * 2.0
		var foot: Vector2 = Vector2(x, roundf(sin(index * 2.3) * radius * 0.3 / 2.0) * 2.0)
		draw_line(foot - Vector2(0.0, 120.0 * fade + 20.0), foot, Color(GLOW, fade), 2.0)
