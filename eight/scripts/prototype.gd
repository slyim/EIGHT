extends Node2D
## Graybox test space only. This layout and every drawn visual are PLACEHOLDER.

const FLOOR_RECT: Rect2 = Rect2(-960.0, -600.0, 1920.0, 1200.0)

@onready var geometry: StaticBody2D = $Geometry


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"reset"):
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()


func _draw() -> void:
	draw_rect(FLOOR_RECT, Color("20282e"))
	for x: int in range(-960, 961, 64):
		draw_line(Vector2(x, -600.0), Vector2(x, 600.0), Color("2a333a"))
	for y: int in range(-600, 601, 64):
		draw_line(Vector2(-960.0, y), Vector2(960.0, y), Color("2a333a"))
	for child: Node in geometry.get_children():
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision == null or not collision.shape is RectangleShape2D:
			continue
		var rectangle: RectangleShape2D = collision.shape as RectangleShape2D
		var bounds: Rect2 = Rect2(collision.position - rectangle.size * 0.5, rectangle.size)
		draw_rect(bounds, Color("4c5961"))
		draw_rect(bounds, Color("89979f"), false, 2.0)
