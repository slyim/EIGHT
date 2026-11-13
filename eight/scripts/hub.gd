class_name Hub
extends Control
## The pentagram: the game's main menu. The seven sins sit evenly on the outer ring; entering
## one opens its map. Each sealed sin's relic glows on its pedestal and a gold chord joins it to
## the center, where Satan waits until all seven relics are in place. Vector UI drawn by Godot
## from the shared theme; the pentagram geometry is code-drawn, not art.

## Set by Game when a map is won, so the hub can play the sealing shockwave once.
static var just_sealed: int = -1

const NUMERALS: Array[String] = ["I", "II", "III", "IV", "V", "VI", "VII"]
## Ring radius in UI units (the UI scales with the window).
const RING_RADIUS: float = 240.0
const PEDESTAL_INSET: float = 78.0
const GOLD: Color = Color(0.902, 0.886, 0.6196, 1.0)
const PLUM: Color = Color(0.4314, 0.2471, 0.3725, 1.0)
const CRIMSON: Color = Color(0.85, 0.32, 0.3, 1.0)
const STONE: Color = Color(0.2275, 0.1294, 0.251, 1.0)

var progress: Progress
var sin_buttons: Array[Button] = []
var satan_button: Button
## 0..1 while the sealing shockwave expands from the newly sealed sin.
var seal_wave: float = 0.0:
	set(value):
		seal_wave = value
		pentagram.queue_redraw()
var sealed_now: int = -1

@onready var pentagram: Control = $Pentagram


func _ready() -> void:
	progress = Progress.load_saved()
	for index: int in range(Run.SATAN):
		var button: Button = Button.new()
		button.name = "Sin%d" % (index + 1)
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(150.0, 62.0)
		button.add_theme_font_size_override(&"font_size", 18)
		button.pressed.connect(enter_sin.bind(index))
		add_child(button)
		sin_buttons.append(button)
	satan_button = Button.new()
	satan_button.name = &"Satan"
	satan_button.focus_mode = Control.FOCUS_NONE
	satan_button.custom_minimum_size = Vector2(190.0, 70.0)
	satan_button.add_theme_font_size_override(&"font_size", 20)
	satan_button.pressed.connect(summon_satan)
	add_child(satan_button)
	($Quit as Button).pressed.connect(get_tree().quit)
	($Shop as Button).pressed.connect(open_shop)
	($Settings as Button).pressed.connect(open_settings)
	Settings.load_saved().apply_display(get_window())
	($Feathers as Label).text = "FEATHERS  %d" % progress.feathers
	pentagram.draw.connect(_draw_pentagram)
	_refresh()
	resized.connect(_layout)
	get_window().size_changed.connect(_on_size_changed)
	_on_size_changed()
	_layout()
	# Theatrical entrance: the nodes deal in around the ring, then a fresh seal ripples out.
	for index: int in range(sin_buttons.size()):
		_pop_in(sin_buttons[index], 0.1 + index * 0.06)
	_pop_in(satan_button, 0.1 + sin_buttons.size() * 0.06)
	if just_sealed >= 0 and just_sealed < Run.SATAN and progress.sealed.has(just_sealed):
		sealed_now = just_sealed
		var tween: Tween = create_tween().set_ignore_time_scale()
		tween.tween_property(self, ^"seal_wave", 1.0, 1.4).set_delay(0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	just_sealed = -1


## The UI scale follows the window like the game's (half the world's whole-number scale).
func _on_size_changed() -> void:
	var ui: float = Game.ui_scale_for(Vector2(get_window().size))
	if not is_equal_approx(get_window().content_scale_factor, ui):
		get_window().content_scale_factor = ui


func _refresh() -> void:
	for index: int in range(sin_buttons.size()):
		var sealed: bool = progress.sealed.has(index)
		sin_buttons[index].text = "%s  %s\n%s" % [NUMERALS[index], Run.BOSSES[index]["name"], "SEALED" if sealed else "ENTER  [%d]" % (index + 1)]
	var relics: int = progress.sealed.size()
	satan_button.disabled = not progress.satan_unlocked()
	if progress.satan_defeated:
		satan_button.text = "SATAN HAS FALLEN\nSUMMON AGAIN  [S]"
	elif progress.satan_unlocked():
		satan_button.text = "SUMMON SATAN\n[S]"
	else:
		satan_button.text = "SATAN\n%d / %d RELICS" % [relics, Run.SATAN]
	pentagram.queue_redraw()


func ring_center() -> Vector2:
	return size * 0.5 + Vector2(0.0, 40.0)


## Where sin index sits on the ring, the first at the top, then clockwise.
func sin_point(index: int, radius: float = RING_RADIUS) -> Vector2:
	return ring_center() + Vector2.from_angle(-PI * 0.5 + TAU * index / Run.SATAN) * radius


func _layout() -> void:
	for index: int in range(sin_buttons.size()):
		var button: Button = sin_buttons[index]
		button.size = button.get_combined_minimum_size()
		button.position = (sin_point(index) - button.size * 0.5).round()
		button.pivot_offset = button.size * 0.5
	satan_button.size = satan_button.get_combined_minimum_size()
	satan_button.position = (ring_center() - satan_button.size * 0.5).round()
	satan_button.pivot_offset = satan_button.size * 0.5
	pentagram.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if has_node(^"SettingsPanel"):
		return # The settings panel has the keys while it is open.
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index: int = key.physical_keycode - KEY_1
	if index >= 0 and index < Run.SATAN:
		get_viewport().set_input_as_handled()
		enter_sin(index)
	elif key.physical_keycode == KEY_S:
		get_viewport().set_input_as_handled()
		summon_satan()
	elif key.physical_keycode == KEY_B:
		get_viewport().set_input_as_handled()
		open_shop()


func open_settings() -> SettingsPanel:
	var panel: SettingsPanel = (load("res://scenes/settings_panel.tscn") as PackedScene).instantiate() as SettingsPanel
	add_child(panel)
	return panel


func open_shop() -> void:
	get_tree().change_scene_to_file("res://scenes/shop.tscn")


func enter_sin(index: int) -> void:
	Game.start_map(get_tree(), index)


## Only with all seven relics on their pedestals.
func summon_satan() -> void:
	if progress.satan_unlocked():
		Game.start_map(get_tree(), Run.SATAN)


func _pop_in(control: Control, delay: float) -> void:
	control.scale = Vector2(0.85, 0.85)
	control.modulate.a = 0.0
	var tween: Tween = control.create_tween().set_parallel().set_ignore_time_scale()
	tween.tween_property(control, ^"scale", Vector2.ONE, 0.24).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, ^"modulate:a", 1.0, 0.16).set_delay(delay)


## A line with a soft glow: wide faint strokes under a crisp one.
func _glow_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	pentagram.draw_line(from, to, Color(color, 0.12), width + 10.0, true)
	pentagram.draw_line(from, to, Color(color, 0.25), width + 4.0, true)
	pentagram.draw_line(from, to, color, width, true)


func _draw_pentagram() -> void:
	var center: Vector2 = ring_center()
	# Outer circle, with a glow.
	pentagram.draw_arc(center, RING_RADIUS, 0.0, TAU, 160, Color(PLUM, 0.2), 12.0, true)
	pentagram.draw_arc(center, RING_RADIUS, 0.0, TAU, 160, PLUM, 2.0, true)
	# The pentagram inside it: every second point of five.
	var star_radius: float = RING_RADIUS - PEDESTAL_INSET - 34.0
	for index: int in range(5):
		var from: Vector2 = center + Vector2.from_angle(-PI * 0.5 + TAU * index / 5.0) * star_radius
		var to: Vector2 = center + Vector2.from_angle(-PI * 0.5 + TAU * (index + 2) / 5.0) * star_radius
		_glow_line(from, to, CRIMSON if progress.satan_unlocked() else PLUM, 2.0)
	pentagram.draw_arc(center, star_radius, 0.0, TAU, 120, Color(PLUM, 0.6), 1.5, true)
	# Pedestals between each sin and the center; a sealed sin's relic glows on it with a chord
	# to Satan. Sealed pedestals are also marked by shape (a relic), not only by color.
	for index: int in range(Run.SATAN):
		var at: Vector2 = sin_point(index, RING_RADIUS - PEDESTAL_INSET)
		pentagram.draw_rect(Rect2(at + Vector2(-16.0, 6.0), Vector2(32.0, 10.0)), STONE)
		pentagram.draw_rect(Rect2(at + Vector2(-10.0, 0.0), Vector2(20.0, 8.0)), STONE.lightened(0.15))
		if progress.sealed.has(index):
			_glow_line(at, center, Color(GOLD, 0.55), 1.5)
			var relic: PackedVector2Array = [at + Vector2(0.0, -22.0), at + Vector2(9.0, -10.0), at + Vector2(0.0, 2.0), at + Vector2(-9.0, -10.0)]
			pentagram.draw_circle(at + Vector2(0.0, -10.0), 18.0, Color(GOLD, 0.15))
			pentagram.draw_colored_polygon(relic, GOLD)
	# The sealing shockwave from the newly sealed sin.
	if sealed_now >= 0 and seal_wave > 0.0 and seal_wave < 1.0:
		var origin: Vector2 = sin_point(sealed_now, RING_RADIUS - PEDESTAL_INSET)
		pentagram.draw_arc(origin, 20.0 + 260.0 * seal_wave, 0.0, TAU, 96, Color(GOLD, 1.0 - seal_wave), 3.0, true)
