class_name PracticeTarget
extends StaticBody2D
## PLACEHOLDER damage target, not an enemy design or production asset.

@export_range(1, 20, 1) var max_health: int = 3

var health: int = 0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var status_label: Label = $Status


func _ready() -> void:
	health = max_health
	_update_label()


func take_hit(damage: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - maxi(0, damage))
	if health == 0:
		collision_shape.set_deferred(&"disabled", true)
	_update_label()
	queue_redraw()


func _update_label() -> void:
	if health > 0:
		status_label.text = "PLACEHOLDER TARGET\n%d / %d" % [health, max_health]
	else:
		status_label.text = "TARGET CLEARED\nR to reset"


func _draw() -> void:
	var target_color: Color = Color("d9a26e") if health > 0 else Color("59636a")
	draw_rect(Rect2(-24.0, -24.0, 48.0, 48.0), target_color, false, 3.0)
	draw_line(Vector2(-12.0, 0.0), Vector2(12.0, 0.0), target_color, 3.0)
	draw_line(Vector2(0.0, -12.0), Vector2(0.0, 12.0), target_color, 3.0)
