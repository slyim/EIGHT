extends Node2D
## PLACEHOLDER-tunable light sources for the Lighting group. Every visible CanvasItem in
## group "light" gets one additive falloff quad at its position; the group then multiplies
## the world by ambient + the sum (shaders/lighting.gdshader).
## A light is two metadata values: `light` (a Color; its alpha is energy / 4) and
## `light_radius` (px). They are read from the node, or from its material when the node has
## none. A node may also set a world-space `light_offset` to match raised art.


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# The camera may have moved since this transform was read; the margin covers one frame.
	var view: Rect2 = (get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()).grow(32.0)
	var viewport: Viewport = get_viewport()
	for item: CanvasItem in get_tree().get_nodes_in_group(&"light"):
		if item.get_viewport() != viewport or not item.is_visible_in_tree():
			continue
		var source: Object = item if item.has_meta(&"light") else item.material
		if source == null or not source.has_meta(&"light"):
			continue
		var radius: float = source.get_meta(&"light_radius")
		var offset: Vector2 = item.get_meta(&"light_offset", Vector2.ZERO)
		var at: Vector2 = to_local(item.global_position + offset)
		if view.grow(radius).has_point(at):
			draw_rect(Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), source.get_meta(&"light"))
