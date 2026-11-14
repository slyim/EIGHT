extends SceneTree
## Pixel-perfect host: fixed 640x360 world buffer at whole-number scales with centered bars,
## native-resolution HUD, one art scale for every sprite, and mouse aim through the scaled
## view. Native Godot only; the look itself is verified in a window.

const GAME_SCENE: PackedScene = preload("res://scenes/game.tscn")

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _wait_ticks(count: int) -> void:
	for tick: int in range(count):
		await physics_frame
	await process_frame


## Physical window position of a world point, through the camera, the buffer, the scaled
## view, and the UI content scale.
func _to_window(game: Game, world_point: Vector2) -> Vector2:
	var buffer: SubViewport = game.view.get_child(0) as SubViewport
	return (game.view.position + buffer.get_canvas_transform() * world_point * game.view.stretch_shrink) * root.content_scale_factor


func _move_mouse(at: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	await _wait_ticks(2)


func _press_key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _wait_ticks(1)


func _click(at: Vector2) -> void:
	await _move_mouse(at)
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.global_position = at
		event.pressed = pressed
		Input.parse_input_event(event)
		await _wait_ticks(1)


## HUD position of a world point computed from first principles, independent of Hud.world_to_hud.
func _expected_hud(window: Vector2, run: Run, point: Vector2) -> Vector2:
	var factor: int = maxi(1, floori(minf(window.x / 640.0, window.y / 360.0)))
	var bars: Vector2 = ((window - Vector2(640, 360) * factor) * 0.5).floor()
	var buffer_pixel: Vector2 = Vector2(320, 180) + (point - run.player.camera.get_screen_center_position()) * 0.5
	return (bars + buffer_pixel * factor) / (factor * 0.5)


## Resizes the real window; the host lays itself out on size_changed.
func _resize(window: Vector2) -> void:
	root.size = Vector2i(window)
	await _wait_ticks(2)


func _art_scale(item: Node2D) -> bool:
	return item.global_scale.abs().is_equal_approx(Vector2(2.0, 2.0))


func _run() -> void:
	# Headless windows start tiny; use the minimum game window so HUD clicks land on screen.
	root.size = Vector2i(1280, 720)
	var game: Game = GAME_SCENE.instantiate() as Game
	var run: Run = game.get_node(^"WorldView/World/Run") as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(game)
	current_scene = game
	await _wait_ticks(3)
	var buffer: SubViewport = game.view.get_child(0) as SubViewport

	# Whole-number scales, centered, with the buffer fixed at 640x360.
	var cases: Array[Array] = [
		[Vector2(1280, 720), 2, Vector2(0, 0)],
		[Vector2(1366, 768), 2, Vector2(43, 24)],
		[Vector2(1440, 900), 2, Vector2(80, 90)],
		[Vector2(1920, 1080), 3, Vector2(0, 0)],
		[Vector2(2560, 1080), 3, Vector2(320, 0)],
		[Vector2(3840, 2160), 6, Vector2(0, 0)],
	]
	for case: Array in cases:
		await _resize(case[0])
		var ui: float = root.content_scale_factor
		_check(is_equal_approx(ui, case[1] * 0.5), "%s must scale the UI by %.1f (got %.2f)." % [case[0], case[1] * 0.5, ui])
		_check((game.view.size * ui).is_equal_approx(Vector2(Game.WORLD_SIZE) * float(case[1])), "%s world must be 640x360 x %d physical pixels (got %s)." % [case[0], case[1], game.view.size * ui])
		_check((game.view.position * ui).is_equal_approx(case[2]), "%s world must be centered at %s (got %s)." % [case[0], case[2], game.view.position * ui])
		_check(buffer.size == Game.WORLD_SIZE, "The world buffer must stay 640x360 (got %s)." % buffer.size)
		_check((run.hud.size * ui).is_equal_approx(case[0]), "%s: the scaled HUD must still cover the window (got %s)." % [case[0], run.hud.size * ui])
	await _resize(Vector2(1280, 720))

	# Rendering settings: nearest sampling, HDR, the world's own glow, and 2 units per buffer pixel.
	_check(buffer.use_hdr_2d and buffer.own_world_3d, "The world buffer must be HDR with its own environment.")
	_check(game.view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "The scaled world must use nearest sampling.")
	_check(run.player.camera.zoom == Vector2(0.5, 0.5), "The camera must show 2 world units per buffer pixel.")
	_check(ProjectSettings.get_setting("display/window/size/min_width") >= 1280 and ProjectSettings.get_setting("display/window/size/min_height") >= 720, "The minimum window must be 1280x720.")

	# The HUD renders at native resolution, outside the world buffer.
	_check(run.hud.get_viewport() == root, "The HUD must render in the native root viewport.")
	_check(run.player.get_viewport() == buffer, "The world must render in the pixel buffer.")

	# Every sprite draws at one art scale.
	_check(_art_scale(run.player.sprite) and _art_scale(run.player.spear), "The player and spear must be 2x.")
	var husk: Enemy = run.spawn_enemy(0, Vector2(300.0, 300.0))
	var flyer: Enemy = run.spawn_enemy(Run.FLYER, Vector2(-300.0, 300.0))
	var gem: Pickup = run.spawn_pickup(Pickup.Kind.XP, Vector2(300.0, -300.0), 20)
	var item: Pickup = run.spawn_pickup(Pickup.Kind.ITEM, Vector2(-300.0, -300.0), 0)
	run._spawn_poof(Vector2(200.0, 200.0))
	await _wait_ticks(2)
	_check(_art_scale(husk.sprite) and _art_scale(flyer.sprite), "Enemies must be 2x.")
	_check(_art_scale(gem) and _art_scale(item), "Pickups, including big XP, must be 2x.")
	_check(_art_scale(run.effects.get_child(run.effects.get_child_count() - 1) as Node2D), "Poofs must be 2x.")
	(flyer as FlyingEnemy)._fire()
	var shot: EnemyProjectile = null
	for child: Node in run.actors.get_children():
		if child is EnemyProjectile:
			shot = child
	_check(shot != null and _art_scale(shot), "Flying-enemy shots must be 2x.")
	_check(shot != null and shot.modulate == FlyingEnemy.SHOT_COLOR and FlyingEnemy.SHOT_COLOR != Color.WHITE, "Flying-enemy shots must be tinted apart from boss shots.")
	run.player.spear_reach += 60.0
	run.player.thrust_direction = Vector2.RIGHT
	run.player._spawn_slash()
	var slash: Node2D = run.player.get_child(run.player.get_child_count() - 1) as Node2D
	_check(slash is AnimatedSprite2D and _art_scale(slash), "The finisher slash must stay 2x after a reach upgrade.")
	husk.queue_free()
	flyer.queue_free()
	await _wait_ticks(2)

	# Mouse aim reaches the world through the scaled, centered view, with and without bars.
	for window: Vector2 in [Vector2(1280, 720), Vector2(1366, 768), Vector2(1920, 1080)]:
		await _resize(window)
		for direction: Vector2 in [Vector2.RIGHT, Vector2.UP, Vector2(-1.0, 1.0).normalized()]:
			await _move_mouse(_to_window(game, run.player.global_position + direction * 200.0))
			_check(run.player.aim_direction.dot(direction) > 0.99, "At %s, aiming %s must reach the world (aim %s)." % [window, direction, run.player.aim_direction])
	await _resize(Vector2(1280, 720))

	# The camera lands on whole buffer pixels while the player keeps a fractional position.
	run.player.global_position = Vector2(10.25, -7.75)
	await _wait_ticks(2)
	run.player.camera.force_update_scroll()
	var origin: Vector2 = (buffer.get_final_transform() * run.get_global_transform_with_canvas()).origin
	_check(origin.is_equal_approx(origin.round()), "The camera must snap to whole buffer pixels (origin %s)." % origin)
	_check(not run.player.global_position.is_equal_approx(run.player.global_position.round()), "Snapping must not round the player's position.")

	# Keys and clicks reach the world through the host: Q switches, a click attacks.
	run.player.global_position = Vector2.ZERO
	await _wait_ticks(2)
	await _press_key(KEY_Q)
	_check(run.player.weapon == MountedPlayer.Weapon.BOW, "Q must switch weapons through the host.")
	var shots: Array[int] = []
	run.player.arrow_fired.connect(func(step: int) -> void: shots.append(step))
	await _click(_to_window(game, run.player.global_position + Vector2(200.0, 0.0)))
	_check(shots == [0], "A click in the view must fire the bow (got %s)." % [shots])

	# Level-ups pause the world; the native HUD takes a click and a number key.
	var speed: float = run.player.movement_speed
	run.add_xp(run.xp_needed())
	await _wait_ticks(1)
	_check(paused and run.hud.level_up_panel.visible, "A level-up must pause and show its choices.")
	var choice: Button = run.hud.choice_buttons[0]
	await _click(choice.get_global_rect().get_center())
	_check(not paused and not run.hud.level_up_panel.visible, "Clicking a choice in the native HUD must resume the run.")
	run.add_xp(run.xp_needed())
	await _wait_ticks(1)
	await _press_key(KEY_2)
	_check(not paused and not run.hud.level_up_panel.visible, "Pressing 2 must pick a choice and resume.")
	_check(run.level == 3, "Both level-ups must have been taken.")

	# Esc pauses and resumes; the Resume button works; Esc never opens over a level-up.
	await _press_key(KEY_ESCAPE)
	_check(paused and run.hud.pause_menu.visible, "Esc must pause and open the pause menu.")
	await _press_key(KEY_ESCAPE)
	_check(not paused and not run.hud.pause_menu.visible, "Esc again must resume.")
	await _press_key(KEY_ESCAPE)
	await _wait_ticks(20)
	var resume: Button = run.hud.get_node(^"PauseMenu/Box/Resume") as Button
	await _click(resume.get_global_rect().get_center() * root.content_scale_factor)
	_check(not paused and not run.hud.pause_menu.visible, "The Resume button must resume.")
	run.add_xp(run.xp_needed())
	await _wait_ticks(1)
	await _press_key(KEY_ESCAPE)
	_check(not run.hud.pause_menu.visible and run.hud.level_up_panel.visible, "Esc must not open the pause menu over a level-up.")
	await _press_key(KEY_1)
	_check(not paused, "Picking the level-up must still resume.")

	# A level-up arriving while paused replaces the pause menu; choosing then resumes cleanly.
	run.hud.set_paused(true)
	run.add_xp(run.xp_needed())
	await _wait_ticks(1)
	_check(run.hud.level_up_panel.visible and not run.hud.pause_menu.visible and paused, "A level-up must replace an open pause menu and stay paused.")
	await _press_key(KEY_1)
	_check(not paused and not run.hud.pause_menu.visible, "Choosing must resume with no pause menu left behind.")

	# Boss and portal names are crisp HUD labels just above them, placed by an independent
	# calculation: camera center -> buffer pixel -> whole-number scale -> bars -> UI scale.
	var boss: Boss = run.spawn_sin_boss()
	boss.speed = 0.0
	boss.global_position = run.player.global_position + Vector2(180.0, -40.0)
	var tag: Label = run.hud.boss_tag
	for window: Vector2 in [Vector2(1920, 1080), Vector2(2560, 1080)]:
		await _resize(window)
		await _wait_ticks(2)
		var anchor: Vector2 = boss.global_position - Vector2(0.0, boss.radius + 18.0)
		var expected: Vector2 = _expected_hud(window, run, anchor)
		var rect: Rect2 = tag.get_global_rect()
		_check(tag.visible and tag.text == boss.boss_name and tag.get_viewport() == root, "At %s the boss tag must be a visible native HUD label." % window)
		_check(absf(rect.get_center().x - expected.x) < 1.5 and absf(rect.end.y - expected.y) < 1.5, "At %s the boss tag must sit centered on %s (tag %s)." % [window, expected, rect])
	# Off the world view (into the bars on ultrawide), the tag hides instead of floating.
	boss.global_position = run.player.global_position + Vector2(-760.0, 0.0)
	await _wait_ticks(3)
	_check(not tag.visible, "A boss outside the world view must not show a tag in the bars.")
	await _resize(Vector2(1280, 720))
	boss.global_position = run.player.global_position + Vector2(180.0, -40.0)
	boss.take_hit(100000)
	await _wait_ticks(3)
	var portal_anchor: Vector2 = run.exit_portal.global_position - Vector2(0.0, ExitPortal.RADIUS + 12.0)
	var portal_rect: Rect2 = run.hud.portal_tag.get_global_rect()
	var portal_expected: Vector2 = _expected_hud(Vector2(1280, 720), run, portal_anchor)
	_check(not tag.visible and run.hud.portal_tag.visible, "The portal prompt must replace the boss tag once the portal opens.")
	_check(absf(portal_rect.get_center().x - portal_expected.x) < 1.5 and absf(portal_rect.end.y - portal_expected.y) < 1.5, "The portal prompt must sit centered on %s (tag %s)." % [portal_expected, portal_rect])

	# R restarts the whole host: a fresh, unpaused Game with its HUD back at native resolution.
	paused = true
	await _press_key(KEY_R)
	await _wait_ticks(3)
	var fresh: Game = current_scene as Game
	_check(fresh != null and fresh != game and not is_instance_valid(game), "R must reload a fresh Game.")
	_check(not paused, "Restart must unpause.")
	if fresh != null:
		_check(fresh.run.hud.get_viewport() == root and fresh.run.player.get_viewport() != root, "The restarted Game must keep the HUD native and the world in the buffer.")
		fresh.queue_free()
	await _wait_ticks(15)
	if failures == 0:
		print("PASS: whole-number scales and centered bars, fixed 640x360 buffer, nearest HDR world, native HUD, 2x sprites, aim through the view, pixel-snapped camera, keys/clicks/level-ups/pause menu/world tags/restart through the host.")
	quit(1 if failures > 0 else 0)
