extends SceneTree
## Settings: the saved store (defaults, validation, round trip), each quality step layering
## the effects onto a hub-launched run, display options, and the panel from the pentagram and
## from the pause menu (live changes, Esc closing only the panel). Own files; native Godot only.

const TEST_SETTINGS: String = "user://test_settings.cfg"
const TEST_SAVE: String = "user://test_settings_progress.cfg"

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _ticks(count: int) -> void:
	for index: int in range(count):
		await physics_frame
	await process_frame


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _ticks(1)


func _scene_becomes(script: Script, limit: int = 900) -> bool:
	for tick: int in range(limit):
		if current_scene != null and current_scene.get_script() == script and current_scene.is_node_ready():
			return true
		await process_frame
	return false


## [glow, lamp shadows, soft shadows, wide bloom, haze, shimmer, eye pulse, two-tone] on a run.
func _effects(run: Run) -> Array[bool]:
	var environment: Environment = (run.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	var lamp: PointLight2D = run.player.get_node(^"Lamp") as PointLight2D
	return [
		environment.glow_enabled,
		lamp.shadow_enabled,
		lamp.shadow_filter != PointLight2D.SHADOW_FILTER_NONE,
		environment.get_glow_level(2) > 0.0,
		float(run.veil.get_shader_parameter(&"haze_strength")) > 0.0,
		float((run.lava.material as ShaderMaterial).get_shader_parameter(&"shimmer")) > 0.0,
		float(Enemy.EYE_MATERIAL.get_shader_parameter(&"pulse")) > 0.0,
		float((run.get_node(^"Lighting/Lights").material as ShaderMaterial).get_shader_parameter(&"core_whiten")) > 0.0,
	]


func _run() -> void:
	root.size = Vector2i(1280, 720)
	Settings.path = TEST_SETTINGS
	Progress.path = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var fps_before: int = Engine.max_fps

	# 1. The store: HIGH and feel options on/100% by default, bad values fall back, a round trip keeps everything.
	var settings: Settings = Settings.load_saved()
	_check(settings.quality == Settings.Quality.HIGH and settings.vsync and settings.fps_cap == 3 and not settings.fullscreen, "Missing settings must be the defaults.")
	_check(settings.damage_numbers and settings.shake == 2 and is_equal_approx(Settings.SHAKE_SCALES[settings.shake], 1.0) and settings.hit_stop, "Missing gameplay-feel settings must default to on / 100%.")
	var file: ConfigFile = ConfigFile.new()
	file.set_value("graphics", "quality", 9)
	file.set_value("display", "vsync", "no")
	file.set_value("display", "fps_cap", -2)
	file.set_value("display", "fullscreen", 3)
	file.set_value("gameplay", "damage_numbers", "yes")
	file.set_value("gameplay", "shake", 7)
	file.set_value("gameplay", "hit_stop", 1)
	file.save(TEST_SETTINGS)
	settings = Settings.load_saved()
	_check(settings.quality == Settings.Quality.HIGH and settings.vsync and settings.fps_cap == 3 and not settings.fullscreen, "Damaged settings must fall back to the defaults.")
	_check(settings.damage_numbers and settings.shake == 2 and settings.hit_stop, "Damaged gameplay-feel settings must fall back to defaults.")
	settings.quality = Settings.Quality.LOW
	settings.vsync = false
	settings.fps_cap = 1
	settings.damage_numbers = false
	settings.shake = 1
	settings.hit_stop = false
	_check(settings.save() == OK, "Settings must save.")
	var reloaded: Settings = Settings.load_saved()
	_check(reloaded.quality == Settings.Quality.LOW and not reloaded.vsync and reloaded.fps_cap == 1, "Settings must load back.")
	_check(not reloaded.damage_numbers and reloaded.shake == 1 and not reloaded.hit_stop, "Gameplay-feel settings must load back.")
	reloaded.apply_display(root)
	_check(Engine.max_fps == 60, "The frame cap must apply (got %d)." % Engine.max_fps)

	# 2. Each quality step layers the effects onto a hub-launched run.
	Game.start_map(self, 0)
	_check(await _scene_becomes(Game), "A realm must open.")
	var run: Run = (current_scene as Game).run
	_check(_effects(run) == [false, false, false, false, false, false, false, false], "LOW must switch every effect off (got %s)." % [_effects(run)])
	var expected: Array = [
		[false, false, false, false, false, false, false, false],
		[true, true, false, false, false, true, true, false],
		[true, true, true, true, true, true, true, false],
		[true, true, true, true, true, true, true, true],
	]
	for step: int in range(4):
		settings.quality = step as Settings.Quality
		settings.apply_run(run)
		_check(_effects(run) == expected[step], "%s must give %s (got %s)." % [Settings.QUALITY_NAMES[step], expected[step], _effects(run)])
	await _ticks(5)

	# 3. From the pause menu: the panel opens over it, changes apply live, Esc closes only the panel.
	await _key(KEY_ESCAPE)
	_check(paused and run.hud.pause_menu.visible, "Esc must pause.")
	(run.hud.get_node(^"PauseMenu/Box/Settings") as Button).pressed.emit()
	await _ticks(2)
	var panel: SettingsPanel = run.hud.get_node(^"SettingsPanel") as SettingsPanel
	_check(panel != null and not run.hud.pause_menu.visible, "Settings must open over the pause menu.")
	var panel_rect: Rect2 = (panel.get_node(^"Panel") as Control).get_rect()
	var close_rect: Rect2 = (panel.get_node(^"Panel/Box/Close") as Control).get_global_rect()
	_check(panel_rect.position.y >= 0.0 and panel_rect.end.y <= 720.0 and close_rect.end.y <= panel_rect.end.y, "Settings panel must fit without clipping at 1280x720 (panel %s, close %s)." % [panel_rect, close_rect])
	_check(panel.quality.value == Settings.Quality.LOW, "The panel must show the saved quality.")
	_check(not panel.damage_numbers.button_pressed and panel.shake.selected == 1 and not panel.hit_stop.button_pressed, "The panel must show the saved gameplay-feel settings.")
	_check(panel.shake.get_item_text(0) == "SCREEN SHAKE 0%" and panel.shake.get_item_text(1) == "SCREEN SHAKE 50%" and panel.shake.get_item_text(2) == "SCREEN SHAKE 100%", "Shake options must show 0%/50%/100%.")
	panel.quality.value = Settings.Quality.HIGH
	await _ticks(2)
	_check(_effects(run)[4] and _effects(run)[2], "Raising quality must apply live to the run.")
	_check(Settings.load_saved().quality == Settings.Quality.HIGH, "A change must save at once.")
	_check(panel.quality_label.text == "QUALITY  HIGH" and panel.quality_note.text.contains("haze"), "The panel must name the step and what it adds.")
	# Toggle each gameplay-feel control and verify live save + live run application.
	panel.damage_numbers.button_pressed = true
	await _ticks(1)
	_check(run.hud.damage_numbers_enabled and Settings.load_saved().damage_numbers, "Enabling damage numbers must save and apply live.")
	panel.damage_numbers.button_pressed = false
	await _ticks(1)
	_check(not run.hud.damage_numbers_enabled and not Settings.load_saved().damage_numbers, "Disabling damage numbers must save and apply live.")
	panel.shake.select(0)
	panel.shake.item_selected.emit(0)
	await _ticks(1)
	_check(is_equal_approx(run.player.shake_scale, 0.0) and Settings.load_saved().shake == 0, "Selecting 0% shake must save and apply live.")
	panel.shake.select(2)
	panel.shake.item_selected.emit(2)
	await _ticks(1)
	_check(is_equal_approx(run.player.shake_scale, 1.0) and Settings.load_saved().shake == 2, "Selecting 100% shake must save and apply live.")
	panel.hit_stop.button_pressed = true
	await _ticks(1)
	_check(run.player.hit_stop_enabled and Settings.load_saved().hit_stop, "Enabling hit-stop must save and apply live.")
	panel.hit_stop.button_pressed = false
	await _ticks(1)
	_check(not run.player.hit_stop_enabled and not Settings.load_saved().hit_stop, "Disabling hit-stop must save and apply live.")
	# R and F3 are held while the panel is open (no restart, no overlay).
	await _key(KEY_R)
	await _key(KEY_F3)
	_check(current_scene is Game and (current_scene as Game).run == run and not run.hud.stats_panel.visible, "R and F3 must not act while settings is open.")
	panel.fps_cap.select(3)
	panel.fps_cap.item_selected.emit(3)
	_check(Engine.max_fps == 0, "Choosing unlimited must lift the cap.")
	await _key(KEY_ESCAPE)
	await _ticks(2)
	_check(not run.hud.has_node(^"SettingsPanel") and paused and run.hud.pause_menu.visible, "Esc must close only the panel, back to the pause menu.")
	await _key(KEY_ESCAPE)
	_check(not paused, "Esc again must resume.")

	# 4. From the pentagram.
	run.hud.hub_requested.emit()
	_check(await _scene_becomes(Hub), "The hub must open.")
	var hub: Hub = current_scene as Hub
	(hub.get_node(^"Settings") as Button).pressed.emit()
	await _ticks(2)
	_check(hub.has_node(^"SettingsPanel"), "The hub's SETTINGS must open the panel.")
	await _key(KEY_7)
	_check(current_scene == hub, "Keys must not enter a realm while the panel is open.")
	# A click outside the panel lands on the dim layer, not on the hub's buttons underneath.
	var quit_center: Vector2 = (hub.get_node(^"Shop") as Button).get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var click: InputEventMouseButton = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = quit_center
		click.global_position = quit_center
		click.pressed = pressed
		Input.parse_input_event(click)
		await _ticks(2)
	await _ticks(10)
	_check(current_scene == hub and hub.has_node(^"SettingsPanel"), "A click outside the panel must not reach the hub's buttons.")
	await _key(KEY_ESCAPE)
	await _ticks(2)
	_check(not hub.has_node(^"SettingsPanel"), "Esc must close the panel on the hub.")

	Enemy.EYE_MATERIAL.set_shader_parameter(&"pulse", Settings.PULSE_ON)
	Engine.max_fps = fps_before
	current_scene.queue_free()
	await _ticks(15)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	if failures == 0:
		print("Settings smoke passed: defaults, damaged settings, round trip, frame cap, LOW/MEDIUM/HIGH/ULTRA effect layers on a hub run, gameplay-feel toggles (damage numbers, shake, hit-stop) saved and applied live, panel fit at 1280x720, panel from the pause menu (live, saved, Esc back to pause), panel from the hub (keys held, Esc closes).")
	quit(1 if failures > 0 else 0)
