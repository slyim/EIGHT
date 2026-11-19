class_name SettingsPanel
extends Control
## The settings overlay, opened from the pentagram and the pause menu: a quality slider that
## layers the effects, display options, and gameplay-feel options. It covers the whole screen
## (a dim layer takes every click outside the panel), and the screens behind it ignore their
## keys while it is open. Every change saves at once and applies live (to the window, and to
## `run` when one is open). Works while the tree is paused.

signal closed

var settings: Settings
## The run to update live, if the panel was opened from one.
var run: Run
var last_save_error: Error = OK

@onready var quality: HSlider = $Panel/Box/Quality
@onready var quality_label: Label = $Panel/Box/QualityName
@onready var quality_note: Label = $Panel/Box/QualityNote
@onready var vsync: CheckButton = $Panel/Box/VSync
@onready var fps_cap: OptionButton = $Panel/Box/FpsCap
@onready var fullscreen: CheckButton = $Panel/Box/Fullscreen
@onready var damage_numbers: CheckButton = $Panel/Box/DamageNumbers
@onready var shake: OptionButton = $Panel/Box/Shake
@onready var hit_stop: CheckButton = $Panel/Box/HitStop
@onready var language: OptionButton = $Panel/Box/Language
@onready var notice: Label = $Panel/Box/Notice


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Opaque, so the screen behind does not show through the options.
	var panel: PanelContainer = $Panel
	var style: StyleBoxFlat = panel.get_theme_stylebox(&"panel").duplicate() as StyleBoxFlat
	style.bg_color.a = 1.0
	panel.add_theme_stylebox_override(&"panel", style)
	for control: Control in [quality_label, quality_note, fps_cap, shake, language, notice]:
		control.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	settings = Settings.load_saved()
	for _cap: int in Settings.FPS_CAPS:
		fps_cap.add_item("")
	for _scale: float in Settings.SHAKE_SCALES:
		shake.add_item("")
	for _name: String in Settings.LANGUAGE_NAMES:
		language.add_item("")
	quality.value = settings.quality
	vsync.button_pressed = settings.vsync
	fps_cap.selected = settings.fps_cap
	fullscreen.button_pressed = settings.fullscreen
	damage_numbers.button_pressed = settings.damage_numbers
	shake.selected = settings.shake
	hit_stop.button_pressed = settings.hit_stop
	var language_index: int = Settings.LANGUAGES.find(settings.language)
	language.selected = language_index if language_index >= 0 else 0
	quality.value_changed.connect(func(value: float) -> void: _change(&"quality", int(value)))
	vsync.toggled.connect(func(on: bool) -> void: _change(&"vsync", on))
	fps_cap.item_selected.connect(func(index: int) -> void: _change(&"fps_cap", index))
	fullscreen.toggled.connect(func(on: bool) -> void: _change(&"fullscreen", on))
	damage_numbers.toggled.connect(func(on: bool) -> void: _change(&"damage_numbers", on))
	shake.item_selected.connect(func(index: int) -> void: _change(&"shake", index))
	hit_stop.toggled.connect(func(on: bool) -> void: _change(&"hit_stop", on))
	language.item_selected.connect(func(index: int) -> void: _change(&"language", Settings.LANGUAGES[index]))
	($Panel/Box/Close as Button).pressed.connect(close)
	_refresh_texts()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and settings != null and language.item_count > 0:
		_refresh_texts()


func _change(setting: StringName, value: Variant) -> void:
	settings.set(setting, value)
	last_save_error = settings.save()
	settings.apply_language()
	settings.apply_display(get_window())
	if is_instance_valid(run):
		settings.apply_run(run)
	_refresh_texts()


func _refresh_texts() -> void:
	for index: int in range(Settings.FPS_CAPS.size()):
		var cap: int = Settings.FPS_CAPS[index]
		fps_cap.set_item_text(index, tr("FRAME CAP  UNLIMITED") if cap == 0 else tr("FRAME CAP  %d FPS") % cap)
	for index: int in range(Settings.SHAKE_SCALES.size()):
		shake.set_item_text(index, tr("SCREEN SHAKE %d%%") % roundi(Settings.SHAKE_SCALES[index] * 100.0))
	for index: int in range(Settings.LANGUAGE_NAMES.size()):
		language.set_item_text(index, tr("LANGUAGE  %s") % Settings.LANGUAGE_NAMES[index])
	quality_label.text = tr("QUALITY  %s") % tr(Settings.QUALITY_NAMES[settings.quality])
	quality_note.text = tr(Settings.QUALITY_NOTES[settings.quality])
	notice.text = "" if last_save_error == OK else tr("SETTINGS COULD NOT BE SAVED (ERROR %d)") % last_save_error


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
