class_name UiMotion
## Button feel for the vector UI: hovering lifts a button slightly, pressing punches it in.
## Tweens run while the tree is paused (level-up and pause menus) and ignore hit-stop.

const HOVER_SCALE: float = 1.02
const PRESS_SCALE: float = 0.96
const SETTLE_TIME: float = 0.14


## Wires every button under root now, and any added under it later while root lives.
static func watch(root: Node) -> void:
	for button: Node in root.find_children("*", "BaseButton", true, false):
		wire(button as BaseButton)
	var tree: SceneTree = root.get_tree()
	var on_added: Callable = func(node: Node) -> void:
		if node is BaseButton and root.is_ancestor_of(node):
			wire(node as BaseButton)
	tree.node_added.connect(on_added)
	root.tree_exiting.connect(func() -> void: tree.node_added.disconnect(on_added), CONNECT_ONE_SHOT)


static func wire(button: BaseButton) -> void:
	if button.has_meta(&"ui_motion"):
		return
	button.set_meta(&"ui_motion", true)
	var center: Callable = func() -> void: button.pivot_offset = button.size * 0.5
	button.resized.connect(center)
	center.call()
	button.mouse_entered.connect(func() -> void: _settle(button, HOVER_SCALE if not button.disabled else 1.0))
	button.mouse_exited.connect(func() -> void: _settle(button, 1.0))
	button.focus_entered.connect(func() -> void: _settle(button, HOVER_SCALE if not button.disabled else 1.0))
	button.focus_exited.connect(func() -> void: _settle(button, 1.0))
	button.button_down.connect(func() -> void: _settle(button, PRESS_SCALE, 0.06))
	button.button_up.connect(func() -> void: _settle(button, HOVER_SCALE if button.is_hovered() else 1.0))


## Theatrical entrance: scales up from 85% with an overshoot while fading in. The scale is the
## control's one motion tween, so a hover or press during the entrance takes over cleanly.
static func pop_in(control: Control, delay: float, time: float) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * 0.85
	control.modulate.a = 0.0
	var fade: Tween = control.create_tween().set_ignore_time_scale()
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(control, ^"modulate:a", 1.0, time * 0.65).set_delay(delay)
	_restart(control).tween_property(control, ^"scale", Vector2.ONE, time).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _settle(button: BaseButton, target: float, time: float = SETTLE_TIME) -> void:
	if not button.is_inside_tree():
		return
	_restart(button).tween_property(button, ^"scale", Vector2.ONE * target, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Kills the control's previous motion tween and starts its next one: one owner per control,
## so a slower older tween can never finish after a newer one.
static func _restart(control: Control) -> Tween:
	var old: Tween = control.get_meta(&"ui_tween") as Tween if control.has_meta(&"ui_tween") else null
	if old != null and old.is_valid():
		old.kill()
	var tween: Tween = control.create_tween().set_ignore_time_scale()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	control.set_meta(&"ui_tween", tween)
	return tween
