extends SceneTree
## Stained-glass portraits, the hub's About panel, non-blocking boss cards, and the new sprite art.

const TEST_SETTINGS: String = "user://presentation_smoke_settings.cfg"
const TEST_SAVE: String = "user://presentation_smoke_progress.cfg"

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


func _plain_run(map: int, intro: bool) -> Run:
	var run: Run = (load(Game.map_path(map)) as PackedScene).instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = intro
	root.add_child(run)
	current_scene = run
	run.player.invulnerable_left = 1000.0
	return run


func _finish_descent(run: Run) -> void:
	run.has_landed = true
	run.player.descent_left = 0.0
	run.player.height = 0.0


func _run() -> void:
	root.size = Vector2i(1280, 720)
	Settings.path = TEST_SETTINGS
	Progress.path = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	TranslationServer.set_locale("en")

	# The spear is the same mint-white as the bow in every frame; no detached coloured glints.
	var spear: SpriteFrames = preload("res://assets/art/placeholder/placeholder_spear_light.aseprite")
	_check(spear.has_animation(&"idle") and spear.get_frame_count(&"idle") == 4, "The spear must keep its four-frame idle tag.")
	var white: Color = Color("caebe0")
	for index: int in range(spear.get_frame_count(&"idle")):
		var image: Image = spear.get_frame_texture(&"idle", index).get_image()
		_check(image.get_size() == Vector2i(48, 16), "The spear canvas must stay 48x16.")
		for y: int in range(image.get_height()):
			for x: int in range(image.get_width()):
				var pixel: Color = image.get_pixel(x, y)
				if pixel.a > 0.5:
					_check(pixel.is_equal_approx(white), "Every visible spear pixel must be mint-white, got %s." % pixel)

	# The flyer has its own four-frame, 32x32 eye-creature art using only the project's palette.
	_check(FlyingEnemy.FLYER_FRAMES.get_frame_count(&"walk") == 4, "The flying eye must keep four walk frames.")
	var palette: Dictionary = {}
	var previous: Image = null
	var frame_size: Vector2i = Vector2i(32, 32)
	for index: int in range(FlyingEnemy.FLYER_FRAMES.get_frame_count(&"walk")):
		var image: Image = FlyingEnemy.FLYER_FRAMES.get_frame_texture(&"walk", index).get_image()
		_check(image.get_size() == frame_size, "The flying-eye canvas must stay 32x32.")
		if previous != null:
			_check(image.get_data() != previous.get_data(), "The flying-eye wings must animate between frames.")
		previous = image
		var cream: bool = false
		for y: int in range(image.get_height()):
			for x: int in range(image.get_width()):
				var pixel: Color = image.get_pixel(x, y)
				if pixel.a > 0.5:
					palette[pixel.to_html(false)] = true
					cream = cream or pixel.is_equal_approx(Color("e6e29e"))
		_check(cream, "Every flying-eye frame must keep the cream glow-key pixel.")
	_check(palette.size() <= 21, "The flying eye must use only the 21-colour palette (got %d)." % palette.size())

	# Rider and ring layout hold at each supported UI scale; portraits use the requested shader/filter.
	var hub: Hub = (load(Game.HUB_SCENE) as PackedScene).instantiate() as Hub
	root.add_child(hub)
	current_scene = hub
	await _ticks(4)
	# The angel stands on the left, her buffalo on the right, apart and clear of the ring.
	var rider: Control = hub.get_node(^"Rider")
	var mount: Control = hub.get_node(^"Mount")
	for texture_path: String in ["Rider/Angel", "Mount/Buffalo"]:
		var portrait: TextureRect = hub.get_node(texture_path) as TextureRect
		_check(portrait.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "%s must use linear filtering." % texture_path)
		_check((portrait.material as ShaderMaterial).shader == GlassArt.SHADER, "%s must draw through the stained-glass shader." % texture_path)
		_check(is_equal_approx(float((portrait.material as ShaderMaterial).get_shader_parameter(&"sweep_strength")), 0.25), "%s must have the gentle light sweep." % texture_path)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = resolution
		await _ticks(4)
		_check(not rider.get_global_rect().intersects(mount.get_global_rect()), "The angel and the buffalo must not overlap at %s." % resolution)
		_check(rider.get_global_rect().get_center().x < hub.ring_center().x and mount.get_global_rect().get_center().x > hub.ring_center().x, "The angel must stand left of the ring and the buffalo right of it at %s." % resolution)
		for figure: Control in [rider, mount]:
			_check(hub.get_global_rect().encloses(figure.get_global_rect()), "%s must fit at %s." % [figure.name, resolution])
			for button: Button in hub.sin_buttons:
				_check(not figure.get_global_rect().intersects(button.get_global_rect()), "%s must not cover %s at %s." % [figure.name, button.name, resolution])
			_check(not figure.get_global_rect().intersects(hub.satan_button.get_global_rect()), "%s must not cover Satan at %s." % [figure.name, resolution])
	root.size = Vector2i(1280, 720)
	await _ticks(4)
	hub.preview_boss(5)
	await _ticks(30)
	var preview: PanelContainer = hub.get_node(^"PortraitPanel")
	_check(preview.visible and hub.preview_map == 5 and is_equal_approx(preview.modulate.a, 1.0), "Wrath focus/hover must fade in Kerberos.")
	_check((hub.get_node(^"PortraitPanel/Box/Art") as TextureRect).texture.resource_path.ends_with("kerberos.png"), "Wrath must show the Kerberos illustration.")
	_check((hub.get_node(^"PortraitPanel/Box/PortraitTitle") as Label).text == "KERBEROS", "The hover panel must name Kerberos.")
	hub.hide_boss_preview()
	await _ticks(20)
	_check(not preview.visible, "The hover portrait must leave when focus/hover ends.")
	hub.sin_buttons[5].grab_focus()
	await _ticks(2)
	_check(hub.preview_map == 5, "Keyboard focus must open the same boss portrait.")
	hub.sin_buttons[5].release_focus()
	hub.preview_boss(2)
	await _ticks(20)
	_check((hub.get_node(^"PortraitPanel/Box/Art") as TextureRect).texture.resource_path.ends_with("lilith.png"), "Lust must show the Lilith illustration.")
	hub.hide_boss_preview()

	# About is a real, fitted, translatable panel; hub shortcuts stay held until Esc closes it.
	var about: AboutPanel = hub.open_about()
	await _ticks(4)
	_check((about.get_node(^"Panel/Box/Heading") as Label).text == "ABOUT", "About must open from the hub.")
	_check((about.get_node(^"Panel/Box/Version") as Label).text.contains(str(ProjectSettings.get_setting(&"application/config/version"))), "About must read the project version.")
	_check((about.get_node(^"Panel/Box/Scroll/Credits/Team") as Label).text.contains("2308A061") and (about.get_node(^"Panel/Box/Scroll/Credits/Team") as Label).text.contains("Yıldız Teknik Üniversitesi"), "About must include the full team and university.")
	_check(about.get_global_rect().encloses((about.get_node(^"Panel") as Control).get_global_rect()), "About must fit at 1280x720.")
	await _key(KEY_1)
	_check(current_scene == hub, "Realm keys must not work behind About.")
	TranslationServer.set_locale("tr")
	await _ticks(2)
	_check((about.get_node(^"Panel/Box/Heading") as Label).text == "HAKKINDA", "About must translate to HAKKINDA with the correct capital I.")
	_check((about.get_node(^"Panel/Box/Scroll/Credits/TeamHeading") as Label).text == "EKİP", "TEAM must translate with the correct dotted İ.")
	await _key(KEY_ESCAPE)
	await _ticks(2)
	_check(not hub.has_node(^"AboutPanel") and current_scene == hub, "Esc must close About and return to the hub.")
	TranslationServer.set_locale("en")
	hub.free()

	# Kerberos: the card shows its glass portrait and holds only the arriving boss, not the world.
	var wrath: Run = _plain_run(5, true)
	await _ticks(3)
	_finish_descent(wrath)
	var kerberos: Boss = wrath.spawn_sin_boss()
	await create_timer(0.7, true, false, true).timeout
	_check(wrath.boss_intro != null and not kerberos.is_physics_processing(), "The arriving boss must wait for its card.")
	_check(wrath.find_children("*", "BossIntro", true, false).size() == 1, "Guards must not produce extra introduction cards.")
	var card: BossIntro = wrath.boss_intro
	_check((card.get_node(^"Slider/TextBlock/BossName") as Label).text == "KERBEROS" and (card.get_node(^"Slider/TextBlock/Realm") as Label).text == "WRATH", "The card must carry the character and realm names.")
	_check((card.get_node(^"Slider/Portrait") as TextureRect).visible, "Kerberos must have his portrait.")
	_check(((card.get_node(^"Slider/Portrait") as TextureRect).material as ShaderMaterial).shader == GlassArt.SHADER, "Boss portraits must use stained glass.")
	var clock: float = wrath.elapsed
	await create_timer(0.35, true, false, true).timeout
	_check(wrath.elapsed > clock, "The run clock must keep moving during the card.")
	await create_timer(2.4, true, false, true).timeout
	_check(wrath.boss_intro == null and kerberos.is_physics_processing(), "The boss must resume and the card must free itself without blocking input.")
	wrath.free()

	# Satan's head and hands all wait, then resume; guards and decoys are never announcement cards.
	var satan: Run = _plain_run(Run.SATAN, true)
	await _ticks(3)
	_finish_descent(satan)
	var _head: Boss = satan.spawn_sin_boss()
	await create_timer(0.7, true, false, true).timeout
	_check(satan.boss_intro != null and satan.satan_parts.size() == 3, "Satan must get one card for all three parts.")
	_check(satan.satan_parts.all(func(part: Boss) -> bool: return not part.is_physics_processing()), "Satan's head and hands must stay inactive mid-hold.")
	await create_timer(2.7, true, false, true).timeout
	_check(satan.boss_intro == null and satan.satan_parts.all(func(part: Boss) -> bool: return part.is_physics_processing()), "Every Satan part must resume after the card.")
	satan.free()

	# Sins without an illustration still use the same card, with no blank portrait plate.
	var fallback: BossIntro = (load("res://scenes/boss_intro.tscn") as PackedScene).instantiate() as BossIntro
	fallback.map = 1
	root.add_child(fallback)
	await _ticks(3)
	_check(not (fallback.get_node(^"Slider/Portrait") as TextureRect).visible and (fallback.get_node(^"Slider/TextBlock/BossName") as Label).text == "MIDAS", "A sin without art must keep the text-only card.")
	fallback.free()
	current_scene = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	await _ticks(10)
	if failures == 0:
		print("Presentation smoke passed: white spear, four-frame eye flyer, glass portraits at three hub scales, hover/focus previews, Turkish About, Kerberos/Satan cards and text-only fallback.")
	quit(failures)
