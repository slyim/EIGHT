class_name ExitPortal
extends Node2D
## PLACEHOLDER exit visual kept on its own node for later material work.

signal confirmed

const RADIUS: float = 48.0
@export_range(0.5, 3.0, 0.1) var hold_seconds: float = 1.0
var target: MountedPlayer
var hold_left: float = 0.0
var holding: bool = false
var used: bool = false


func _physics_process(delta: float) -> void:
	if used:
		return
	if not is_instance_valid(target) or target.is_dead or not is_nearby():
		holding = false
		hold_left = 0.0
	elif Input.is_action_just_pressed(&"enter_portal"):
		holding = true
	if holding:
		if not Input.is_action_pressed(&"enter_portal"):
			holding = false
			hold_left = 0.0
		else:
			hold_left += delta
			if hold_left >= hold_seconds:
				used = true
				confirmed.emit()
	queue_redraw()


func is_nearby() -> bool:
	return is_instance_valid(target) and global_position.distance_to(target.global_position) <= RADIUS


func _draw() -> void:
	# PLACEHOLDER primitive portal; no imported art.
	draw_circle(Vector2.ZERO, RADIUS, Color("19182e"))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 64, Color("99b9bd"), 4.0, true)
	draw_arc(Vector2.ZERO, RADIUS - 10.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(hold_left / hold_seconds, 0.001, 1.0), 64, Color("e6e29e"), 5.0, true)
	var font: Font = ThemeDB.fallback_font
	draw_string_outline(font, Vector2(-90, -64), "EXIT [HOLD E]", HORIZONTAL_ALIGNMENT_CENTER, 180, 18, 6, Color("070109"))
	draw_string(font, Vector2(-90, -64), "EXIT [HOLD E]", HORIZONTAL_ALIGNMENT_CENTER, 180, 18, Color("caebe0"))
