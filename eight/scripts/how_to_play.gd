extends CenterContainer


func _ready() -> void:
	UiMotion.watch(self)
	$Rows/Back.pressed.connect(Game.go_to_hub.bind(get_tree()))
	$Rows/Back.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Game.go_to_hub(get_tree())
