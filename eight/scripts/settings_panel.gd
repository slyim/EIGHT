class_name SettingsPanel
extends Control
## The settings overlay, opened from the pentagram and the pause menu: a quality slider that
## layers the effects, and display options. It covers the whole screen (a dim layer takes
## every click outside the panel), and the screens behind it ignore their keys while it is open. Every change saves at once and applies live (to
## the window, and to `run` when one is open). Works while the tree is paused.

signal closed

var settings: Settings
## The run to update live, if the panel was opened from one.
var run: Run

@onready var quality: HSlider = $Panel/Box/Quality
@onready var quality_label: Label = $Panel/Box/QualityName
@onready var quality_note: Label = $Panel/Box/QualityNote
@onready var vsync: CheckButton = $Panel/Box/VSync
@onready var fps_cap: OptionButton = $Panel/Box/FpsCap
@onready var fullscreen: CheckButton = $Panel/Box/Fullscreen
@onready var notice: Label = $Panel/Box/Notice


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Opaque, so the screen behind does not show through the options.
	var panel: PanelContainer = $Panel
	var style: StyleBoxFlat = panel.get_theme_stylebox(&"panel").duplicate() as StyleBoxFlat
	style.bg_color.a = 1.0
	panel.add_theme_stylebox_override(&"panel", style)
	settings = Settings.load_saved()
	for cap: int in Settings.FPS_CAPS:
		fps_cap.add_item("FRAME CAP  " + ("UNLIMITED" if cap == 0 else "%d FPS" % cap))
	quality.value = settings.quality
	vsync.button_pressed = settings.vsync
	fps_cap.selected = settings.fps_cap
	fullscreen.button_pressed = settings.fullscreen
	quality.value_changed.connect(func(value: float) -> void: _change(&"quality", int(value)))
	vsync.toggled.connect(func(on: bool) -> void: _change(&"vsync", on))
	fps_cap.item_selected.connect(func(index: int) -> void: _change(&"fps_cap", index))
	fullscreen.toggled.connect(func(on: bool) -> void: _change(&"fullscreen", on))
	($Panel/Box/Close as Button).pressed.connect(close)
	_show_quality()


func _change(setting: StringName, value: Variant) -> void:
	settings.set(setting, value)
	var error: Error = settings.save()
	notice.text = "" if error == OK else "SETTINGS COULD NOT BE SAVED (ERROR %d)" % error
	settings.apply_display(get_window())
	if is_instance_valid(run):
		settings.apply_run(run)
	_show_quality()


func _show_quality() -> void:
	quality_label.text = "QUALITY  %s" % Settings.QUALITY_NAMES[settings.quality]
	quality_note.text = Settings.QUALITY_NOTES[settings.quality]


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
