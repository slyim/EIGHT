class_name Shockwave
extends Node2D
## PLACEHOLDER shockwave (Wrath): three ember rings roll out from where the boss stood, one after
## another. Each is a ground attack: it hurts a grounded angel once as it passes over it (fly
## over it, or dash through the edge). Drawn on even widths with a dark backing, no antialiasing.

const RINGS: int = 3
## Far enough apart that a dash (0.71 s cycle) or a step fits between rings.
const INTERVAL: float = 0.45
const SPEED: float = 300.0
const MAX_RADIUS: float = 420.0
## How thick each ring hits (it is drawn this thick too).
const BAND: float = 12.0

var damage: int = 10
var target: MountedPlayer
var time: float = 0.0
## Each ring hurts at most once.
var landed: Array[bool] = []


func _ready() -> void:
	landed.resize(RINGS)
	landed.fill(false)
	set_meta(&"light", Boss.TELEGRAPH_LIGHT)
	set_meta(&"light_radius", 160.0)
	add_to_group(&"light")


## On whole art pixels, so the drawn ring is exactly the one that hits.
func ring_radius(ring: int) -> float:
	return roundf((time - ring * INTERVAL) * SPEED / 2.0) * 2.0


func _physics_process(delta: float) -> void:
	# A fallen angel ends the fight.
	if not is_instance_valid(target) or target.is_dead:
		queue_free()
		return
	time += delta
	var distance: float = global_position.distance_to(target.global_position)
	for ring: int in range(RINGS):
		var reach: float = ring_radius(ring)
		if landed[ring] or reach <= 0.0 or reach > MAX_RADIUS:
			continue
		if absf(distance - reach) <= BAND * 0.5 + MountedPlayer.HURT_RADIUS and target.take_damage(damage):
			landed[ring] = true
	if ring_radius(RINGS - 1) > MAX_RADIUS:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	for ring: int in range(RINGS):
		var reach: float = ring_radius(ring)
		if reach <= 0.0 or reach > MAX_RADIUS:
			continue
		# Like the other tells: a dim fill across the band, crisp bright edges on dark backing,
		# so the rings read as ground without blooming into a slab.
		var fade: float = 1.0 - reach / MAX_RADIUS * 0.5
		draw_arc(Vector2.ZERO, reach, 0.0, TAU, 96, Boss.EMBER_FILL, BAND)
		for edge: float in [reach - BAND * 0.5, reach + BAND * 0.5]:
			draw_arc(Vector2.ZERO, edge, 0.0, TAU, 96, Boss.BACKING, 6.0)
			draw_arc(Vector2.ZERO, edge, 0.0, TAU, 96, Color(Boss.EMBER, fade), 2.0)
