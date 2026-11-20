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


## A material's value for a shader parameter: its own, or else the shader's default (-1 if none).
func _default(material: ShaderMaterial, parameter: StringName) -> float:
	var value: Variant = material.get_shader_parameter(parameter)
	if value != null:
		return float(value)
	# The headless renderer reports no shader defaults, so read the one in the source.
	var rule: RegEx = RegEx.create_from_string("uniform float %s[^=;]*= *([0-9.]+) *;" % parameter)
	var found: RegExMatch = rule.search(material.shader.code)
	return float(found.get_string(1)) if found != null else -1.0


## [glow, lamp shadows, soft shadows, wide bloom, haze, shimmer, eye pulse, two-tone] on a run.
func _effects(run: Run) -> Array[bool]:
	var environment: Environment = (run.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	var lamp: PointLight2D = run.player.get_node(^"Lamp") as PointLight2D
	return [
		environment.glow_enabled and float(run.veil.get_shader_parameter(&"bloom_strength")) > 0.0,
		lamp.shadow_enabled,
		lamp.shadow_filter != PointLight2D.SHADOW_FILTER_NONE,
		environment.get_glow_level(2) > 0.0 and float(run.veil.get_shader_parameter(&"bloom_spread")) > 2.0,
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
	var locale_before: String = TranslationServer.get_locale()

	# 1. The store: HIGH, feel options on/100%, English by default; bad values fall back; round trip keeps everything.
	var settings: Settings = Settings.load_saved()
	_check(settings.quality == Settings.Quality.HIGH and settings.vsync and settings.fps_cap == 3 and not settings.fullscreen, "Missing settings must be the defaults.")
	_check(settings.damage_numbers and settings.shake == 2 and is_equal_approx(Settings.SHAKE_SCALES[settings.shake], 1.0) and settings.hit_stop, "Missing gameplay-feel settings must default to on / 100%.")
	_check(settings.language == "en", "Missing language setting must default to English.")
	_check(settings.attack_key == KEY_J and settings.dash_key == KEY_K, "Missing control settings must default to J and K.")
	var file: ConfigFile = ConfigFile.new()
	file.set_value("graphics", "quality", 9)
	file.set_value("display", "vsync", "no")
	file.set_value("display", "fps_cap", -2)
	file.set_value("display", "fullscreen", 3)
	file.set_value("gameplay", "damage_numbers", "yes")
	file.set_value("gameplay", "shake", 7)
	file.set_value("gameplay", "hit_stop", 1)
	file.set_value("general", "language", "fr")
	file.set_value("controls", "attack_key", "J")
	file.set_value("controls", "dash_key", -1)
	file.save(TEST_SETTINGS)
	settings = Settings.load_saved()
	_check(settings.quality == Settings.Quality.HIGH and settings.vsync and settings.fps_cap == 3 and not settings.fullscreen, "Damaged settings must fall back to the defaults.")
	_check(settings.damage_numbers and settings.shake == 2 and settings.hit_stop, "Damaged gameplay-feel settings must fall back to defaults.")
	_check(settings.language == "en", "Unknown language must fall back to English.")
	_check(settings.attack_key == KEY_J and settings.dash_key == KEY_K, "Damaged control settings must fall back to J and K.")
	settings.quality = Settings.Quality.LOW
	settings.vsync = false
	settings.fps_cap = 1
	settings.damage_numbers = false
	settings.shake = 1
	settings.hit_stop = false
	settings.language = "tr"
	_check(settings.save() == OK, "Settings must save.")
	var reloaded: Settings = Settings.load_saved()
	_check(reloaded.quality == Settings.Quality.LOW and not reloaded.vsync and reloaded.fps_cap == 1, "Settings must load back.")
	_check(not reloaded.damage_numbers and reloaded.shake == 1 and not reloaded.hit_stop, "Gameplay-feel settings must load back.")
	_check(reloaded.language == "tr", "Saved language must load back.")
	_check(reloaded.attack_key == KEY_J and reloaded.dash_key == KEY_K, "Control defaults must survive a settings round trip.")
	settings.language = "en"
	settings.save()
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
	_check(panel.language.selected == 0 and panel.language.get_item_text(0) == "LANGUAGE  English" and panel.language.get_item_text(1) == "LANGUAGE  Türkçe", "Language options must list English and Turkish.")
	_check(panel.attack_key.text == "ATTACK KEY  J" and panel.dash_key.text == "DASH KEY  K", "Control buttons must show the default keys (got %s / %s)." % [panel.attack_key.text, panel.dash_key.text])
	panel.dash_key.pressed.emit()
	await _ticks(1)
	_check(panel.capturing == &"dash_key" and panel.dash_key.text == "PRESS A KEY...", "Dash rebinding must wait for a physical key.")
	await _key(KEY_ESCAPE)
	_check(run.hud.has_node(^"SettingsPanel") and panel.capturing.is_empty() and panel.settings.dash_key == KEY_K and paused, "Esc must cancel capture without closing settings or changing the key.")
	panel.dash_key.pressed.emit()
	await _key(KEY_L)
	await _ticks(1)
	_check(Settings.load_saved().dash_key == KEY_L and panel.dash_key.text == "DASH KEY  L", "Dash rebinding must save and reload the new physical key.")
	var old_dash: InputEventKey = InputEventKey.new()
	old_dash.physical_keycode = KEY_K
	_check(not InputMap.event_is_action(old_dash, &"dash"), "Rebinding must replace the old custom dash key.")
	var shift: InputEventKey = InputEventKey.new()
	shift.physical_keycode = KEY_SHIFT
	_check(InputMap.event_is_action(shift, &"dash"), "Rebinding must preserve dash's Shift default.")
	var left_click: InputEventMouseButton = InputEventMouseButton.new()
	left_click.button_index = MOUSE_BUTTON_LEFT
	var right_click: InputEventMouseButton = InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	_check(InputMap.event_is_action(left_click, &"attack") and InputMap.event_is_action(right_click, &"dash"), "Rebinding must preserve attack and dash mouse buttons.")
	var rebound: InputEventKey = InputEventKey.new()
	rebound.physical_keycode = KEY_L
	rebound.pressed = true
	Input.parse_input_event(rebound)
	await _ticks(1)
	_check(Input.is_action_pressed(&"dash"), "The dash action must respond to the rebound key.")
	rebound = InputEventKey.new()
	rebound.physical_keycode = KEY_L
	Input.parse_input_event(rebound)
	await _ticks(1)
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
	# Live language switch from pause settings: menu, gameplay, and lore catalogs all respond.
	panel.language.select(1)
	panel.language.item_selected.emit(1)
	await _ticks(2)
	_check(TranslationServer.get_locale() == "tr" and Settings.load_saved().language == "tr", "Selecting Turkish from pause must save and apply live.")
	_check(panel.quality_label.text == "KALİTE  YÜKSEK" and panel.language.get_item_text(1) == "DİL  Türkçe", "Settings panel must live-translate to Turkish (got %s / %s)." % [panel.quality_label.text, panel.language.get_item_text(1)])
	_check(panel.shake.get_item_text(2) == "EKRAN SARSINTISI %100" and panel.fps_cap.get_item_text(3) == "KARE SINIRI  SINIRSIZ", "Settings option lists must live-translate to Turkish.")
	_check(panel.attack_key.text == "SALDIRI TUŞU  J" and panel.dash_key.text == "ATILMA TUŞU  L", "Control buttons must live-translate to Turkish (got %s / %s)." % [panel.attack_key.text, panel.dash_key.text])
	var tr_panel_rect: Rect2 = (panel.get_node(^"Panel") as Control).get_rect()
	var tr_close_rect: Rect2 = (panel.get_node(^"Panel/Box/Close") as Control).get_global_rect()
	_check(tr_panel_rect.position.y >= 0.0 and tr_panel_rect.end.y <= 720.0 and tr_close_rect.end.y <= tr_panel_rect.end.y, "Turkish settings panel must fit at 1280x720 (panel %s, close %s)." % [tr_panel_rect, tr_close_rect])
	var pause_heading: Label = run.hud.get_node(^"PauseMenu/Box/Heading") as Label
	_check(pause_heading.atr(pause_heading.text) == "DURAKLATILDI", "Pause menu static text must translate live.")
	var controls_label: Label = run.hud.get_node(^"Controls") as Label
	_check(controls_label.atr(controls_label.text) != controls_label.text, "Run controls hint must translate live.")
	_check(TranslationServer.translate("ODIN — Even the light bows here.") == "ODIN — Burada ışık bile eğilir.", "Lore catalog must be registered and active.")
	_check(TranslationServer.translate("PRIDE") == "KİBİR", "Gameplay catalog must be registered and active.")
	panel.language.select(0)
	panel.language.item_selected.emit(0)
	await _ticks(2)
	_check(TranslationServer.get_locale() == "en" and panel.quality_label.text == "QUALITY  HIGH", "Switching back to English must apply live.")
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

	# 4. From the pentagram: live switch to Turkish, hub layout, shop, how-to-play, prototype, and startup restore.
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
	var hub_panel: SettingsPanel = hub.get_node(^"SettingsPanel") as SettingsPanel
	hub_panel.language.select(1)
	hub_panel.language.item_selected.emit(1)
	await _ticks(2)
	_check((hub.get_node(^"Feathers") as Label).text == "TÜY  0", "Hub feathers label must live-translate to Turkish (got %s)." % (hub.get_node(^"Feathers") as Label).text)
	_check(hub.sin_buttons[0].text.contains("KİBİR") and hub.sin_buttons[0].text.contains("KEFARET") and hub.sin_buttons[0].text.contains("GİR  [6]"), "Hub sin buttons must live-translate (got %s)." % hub.sin_buttons[0].text)
	# The ring puts Wrath first and Pride sixth: numerals and key hints follow the ring, not the sin index.
	_check(hub.sin_buttons[5].text.begins_with("I  GAZAP") and hub.sin_buttons[5].text.contains("GİR  [1]") and hub.sin_buttons[0].text.begins_with("VI  KİBİR"), "Wrath must be the first circle and Pride the sixth (got %s / %s)." % [hub.sin_buttons[5].text, hub.sin_buttons[0].text])
	_check(hub.satan_button.text.contains("ŞEYTAN") and hub.satan_button.text.contains("YADİGAR"), "Hub Satan button must live-translate (got %s)." % hub.satan_button.text)
	var hub_title: Label = hub.get_node(^"Header/Title") as Label
	_check(hub_title.atr(hub_title.text) == "PENTAGRAM", "Hub static title must translate live.")
	var hub_screen: Rect2 = hub.get_global_rect()
	for index: int in range(hub.sin_buttons.size()):
		var rect: Rect2 = hub.sin_buttons[index].get_global_rect()
		_check(hub_screen.encloses(rect), "Turkish sin %d button must stay on screen (%s)." % [index, rect])
		_check(not rect.intersects(hub.satan_button.get_global_rect()), "Turkish sin %d must not cover Satan." % index)
		_check(not rect.intersects((hub.get_node(^"Header") as Control).get_global_rect()), "Turkish sin %d must not cover header." % index)
		for other: int in range(index + 1, hub.sin_buttons.size()):
			_check(not rect.intersects(hub.sin_buttons[other].get_global_rect()), "Turkish sins %d and %d must not overlap." % [index, other])
	await _key(KEY_ESCAPE)
	await _ticks(2)
	_check(not hub.has_node(^"SettingsPanel"), "Esc must close the panel on the hub.")

	# Shop and How-to-play in Turkish.
	(hub.get_node(^"Shop") as Button).pressed.emit()
	_check(await _scene_becomes(Shop), "Shop must open in Turkish.")
	var shop: Shop = current_scene as Shop
	await _ticks(2)
	var shop_heading: Label = shop.get_node(^"Panel/Box/Heading") as Label
	_check(shop_heading.atr(shop_heading.text) == "DÜKKAN" and shop.balance.text == "TÜY  0", "Shop must render in Turkish (got %s / %s)." % [shop_heading.atr(shop_heading.text), shop.balance.text])
	var health_row: Control = shop.rows["health"]
	_check((health_row.get_node(^"Title") as Label).text == "DİRİLİK" and (health_row.get_node(^"Detail") as Label).text == "+10 azami can" and (health_row.get_node(^"Buy") as Button).text == "AL  10", "Shop upgrade rows must render in Turkish.")
	for row: Control in shop.get_node(^"Panel/Box/List").get_children():
		_check(shop.get_global_rect().encloses(row.get_global_rect()), "Turkish shop rows must fit the screen.")
	# Startup restore: force English locale, reopen Hub, verify saved Turkish is restored.
	TranslationServer.set_locale("en")
	change_scene_to_file(Game.HUB_SCENE)
	_check(await _scene_becomes(Hub), "Hub must reopen for startup restore check.")
	await _ticks(2)
	_check(TranslationServer.get_locale() == "tr" and (current_scene.get_node(^"Feathers") as Label).text == "TÜY  0", "Hub startup must restore saved Turkish language.")
	# How-to-play static scene text translates in Turkish.
	(current_scene.get_node(^"Guide") as Button).pressed.emit()
	await _ticks(5)
	var htp_title: Label = current_scene.get_node(^"Rows/Title") as Label
	var htp_back: Button = current_scene.get_node(^"Rows/Back") as Button
	_check(htp_title.atr(htp_title.text) == "NASIL OYNANIR" and htp_back.atr(htp_back.text) == "MERKEZE DÖN", "How-to-play static scene text must translate.")
	# Prototype scene and practice target restore saved language and update live.
	TranslationServer.set_locale("en")
	change_scene_to_file("res://scenes/prototype.tscn")
	await _ticks(5)
	var proto_notice: Label = current_scene.get_node(^"HUD/PlaceholderNotice") as Label
	var proto_controls: Label = current_scene.get_node(^"HUD/Controls") as Label
	var target: PracticeTarget = current_scene.get_node(^"PracticeTarget") as PracticeTarget
	_check(TranslationServer.get_locale() == "tr" and proto_notice.atr(proto_notice.text) == "EIGHT / BİNEKLİ MIZRAK TESTİ" and proto_controls.atr(proto_controls.text) != proto_controls.text, "Prototype scene must restore Turkish and translate static hints.")
	_check(target.status_label.text == "YER TUTUCU HEDEF\n3 / 3", "PracticeTarget label must translate to Turkish (got %s)." % target.status_label.text)
	TranslationServer.set_locale("en")
	await _ticks(1)
	_check(target.status_label.text == "PLACEHOLDER TARGET\n3 / 3", "PracticeTarget label must live-translate back to English.")
	# Missing settings on startup must restore English default even if OS/current locale is Turkish.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
	TranslationServer.set_locale("tr")
	change_scene_to_file(Game.HUB_SCENE)
	_check(await _scene_becomes(Hub), "Hub must reopen with missing settings.")
	await _ticks(2)
	_check(TranslationServer.get_locale() == "en" and (current_scene.get_node(^"Feathers") as Label).text == "FEATHERS  0", "Fresh startup without settings must preserve English default.")

	Enemy.EYE_MATERIAL.set_shader_parameter(&"pulse", Settings.PULSE_ON)
	# HIGH's on-values are the shaders' own defaults, so a run started on its own (F6) looks
	# exactly like a hub run on HIGH.
	# Fresh copies: earlier runs here changed the cached, shared materials.
	var plain: Run = (ResourceLoader.load("res://scenes/run.tscn", "", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene).instantiate() as Run
	var eyes: ShaderMaterial = ResourceLoader.load("res://shaders/eyes.tres", "", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as ShaderMaterial
	var veil: ShaderMaterial = (plain.get_node(^"Atmosphere/Veil") as ColorRect).material as ShaderMaterial
	var lava: ShaderMaterial = plain.get_node(^"Lava").material as ShaderMaterial
	var lights: ShaderMaterial = plain.get_node(^"Lighting/Lights").material as ShaderMaterial
	_check(is_equal_approx(_default(veil, &"haze_strength"), Settings.HAZE_ON) and is_equal_approx(_default(lava, &"shimmer"), Settings.SHIMMER_ON) and is_equal_approx(_default(eyes, &"pulse"), Settings.PULSE_ON) and is_equal_approx(_default(lights, &"core_whiten"), 0.0), "HIGH must match the scene's own shader values (haze %.3f, shimmer %.3f, pulse %.3f)." % [_default(veil, &"haze_strength"), _default(lava, &"shimmer"), _default(eyes, &"pulse")])
	plain.free()
	TranslationServer.set_locale(locale_before)
	Engine.max_fps = fps_before
	current_scene.queue_free()
	await _ticks(15)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	if failures == 0:
		print("Settings smoke passed: defaults, damaged settings, round trip, frame cap, LOW/MEDIUM/HIGH/ULTRA effect layers on a hub run, gameplay-feel toggles, language persistence and startup restore, live EN/TR switching from pause and hub, menu/gameplay/lore catalogs, Turkish layout fit.")
	quit(1 if failures > 0 else 0)
