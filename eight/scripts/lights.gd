extends Node2D
## PLACEHOLDER-tunable light sources for the Lighting group. Every visible CanvasItem in
## group "light" gets one additive falloff quad at its position; the group then multiplies
## the world by ambient + the sum (shaders/lighting.gdshader).
## A light is two metadata values: `light` (a Color; its alpha is energy / 4) and
## `light_radius` (px). They are read from the node, or from its material when the node has
## none, so a whole family (every arrow, every enemy) is tuned once in its material.


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# The camera may have moved since this transform was read; the margin covers one frame.
	var view: Rect2 = (get_canvas_transform().affine_inverse() * get_viewport_rect()).grow(32.0)
	for item: CanvasItem in get_tree().get_nodes_in_group(&"light"):
		var source: Object = item if item.has_meta(&"light") else item.material
		if source == null or not source.has_meta(&"light") or not item.is_visible_in_tree():
			continue
		var radius: float = source.get_meta(&"light_radius")
		var at: Vector2 = item.global_position
		if view.grow(radius).has_point(at):
			draw_rect(Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), source.get_meta(&"light"))
