class_name Chest
extends Node2D
## A chest on a realm's map: the angel opens it by walking up to it, and a side-weapon relic
## spills out (see Run). Opened chests stay, open. Chests under a map scene's Chests node are
## authored and can be moved in the editor; a map with none gets a few from its seed. The
## drawn chest is PLACEHOLDER (whole art pixels: even sizes and widths, no antialiasing).

signal opened(chest: Chest)

const OPEN_RADIUS: float = 40.0
const WOOD: Color = Color("3a2140")
const TRIM: Color = Color(0.902, 0.886, 0.6196, 1.0)
const DARK: Color = Color("070109")

var is_open: bool = false
var target: MountedPlayer


func _ready() -> void:
	set_meta(&"light", Color(0.9, 0.85, 0.5, 0.35))
	set_meta(&"light_radius", 70.0)
	add_to_group(&"light")


## The ground the chest occupies (kept clear by portals and spawns).
func footprint() -> Rect2:
	return Rect2(position + Vector2(-26.0, -22.0), Vector2(52.0, 36.0))


func _physics_process(_delta: float) -> void:
	if is_open or not is_instance_valid(target) or target.is_dead or target.is_descending():
		return
	if global_position.distance_to(target.global_position) <= OPEN_RADIUS:
		is_open = true
		remove_from_group(&"light")
		queue_redraw()
		opened.emit(self)


func _draw() -> void:
	draw_rect(Rect2(-22.0, 6.0, 48.0, 8.0), Color(DARK, 0.6))
	draw_rect(Rect2(-24.0, -14.0, 48.0, 24.0), WOOD)
	draw_rect(Rect2(-24.0, -14.0, 48.0, 24.0), DARK, false, 2.0)
	if is_open:
		# The lid stands open behind the box.
		draw_rect(Rect2(-24.0, -30.0, 48.0, 14.0), WOOD.darkened(0.3))
		draw_rect(Rect2(-24.0, -30.0, 48.0, 14.0), DARK, false, 2.0)
		return
	draw_rect(Rect2(-26.0, -22.0, 52.0, 10.0), WOOD.lightened(0.15))
	draw_rect(Rect2(-26.0, -22.0, 52.0, 10.0), DARK, false, 2.0)
	draw_rect(Rect2(-4.0, -14.0, 8.0, 10.0), TRIM)
