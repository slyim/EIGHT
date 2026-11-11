extends SceneTree
## PLACEHOLDER look-development wiring; pixel appearance is verified windowed.
var failures: int = 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	var run: Run = load("res://scenes/run.tscn").instantiate()
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	run.set_physics_process(false)
	check(ProjectSettings.get_setting("rendering/viewport/hdr_2d"), "HDR 2D must be enabled")
	var env: Environment = run.get_node("WorldEnvironment").environment
	check(env.glow_enabled and env.background_mode == Environment.BG_CANVAS, "Canvas glow must be enabled")
	check(env.background_canvas_max_layer < run.get_node("HUD").layer, "HUD must be outside glow")
	check(run.get_node("Atmosphere").layer < run.get_node("HUD").layer, "Atmosphere must be below HUD")
	var shared: Material = preload("res://shaders/eyes.tres")
	for i: int in Run.ENEMY_TYPES.size():
		var enemy: Enemy = run.spawn_enemy(i, Vector2(800,800))
		check(enemy.sprite.material == shared, "Every enemy must share the eyes material")
		check(enemy.sprite.get_instance_shader_parameter("eye_bounds") != Vector4.ZERO, "Enemy needs an eye region")
		check_eye_frames(enemy)
	for data: Dictionary in Run.BOSSES:
		var boss: Boss = Run.BOSS_SCENE.instantiate()
		boss.frames = data.frames
		run.actors.add_child(boss)
		check(boss.sprite.material == shared, "Every boss must share the eyes material")
		check(boss.sprite.get_instance_shader_parameter("eye_bounds") != Vector4.ZERO, "Boss needs an eye region")
		check_eye_frames(boss)
	var shot: EnemyProjectile = EnemyProjectile.new()
	run.effects.add_child(shot)
	check(shot.material == preload("res://shaders/enemy_ammo.tres"), "Enemy ammunition must emit red")
	var arrow: Arrow = Arrow.new()
	run.effects.add_child(arrow)
	check(arrow.material == preload("res://shaders/weapon_light.tres"), "Arrows must emit cool light")
	for name: String in ["Sprite", "Spear", "Bow"]:
		check(run.player.get_node(name).material is ShaderMaterial, "Player and weapons need emission")
	run.queue_free()
	await process_frame
	print("glow_smoke: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func check_eye_frames(enemy: Enemy) -> void:
	var bounds: Vector4 = enemy.sprite.get_instance_shader_parameter("eye_bounds")
	var keys: Array[Color] = []
	if enemy.sprite.get_instance_shader_parameter("pale_eyes"):
		keys.append(Color("e6e29e"))
	if enemy.sprite.get_instance_shader_parameter("dark_eyes"):
		keys.append(Color("070109"))
	if enemy.sprite.get_instance_shader_parameter("mint_eyes"):
		keys.append(Color("caebe0"))
	for animation: StringName in enemy.frames.get_animation_names():
		for index: int in enemy.frames.get_frame_count(animation):
			var pixels: Image = enemy.frames.get_frame_texture(animation, index).get_image()
			var found: bool = false
			for y: int in range(int(bounds.y), int(bounds.w)):
				for x: int in range(int(bounds.x), int(bounds.z)):
					if pixels.get_pixel(x, y) in keys:
						found = true
			check(found, "%s %s frame %d needs keyed eyes" % [enemy.frames.resource_path, animation, index])
