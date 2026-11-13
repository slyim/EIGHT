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
	# Darkness: the Lighting group multiplies the finished world, above everything on layer 0.
	var lighting: CanvasGroup = run.get_node("Lighting")
	check((lighting.material as ShaderMaterial).shader.code.contains("blend_mul"), "Lighting must multiply the world")
	check(lighting.z_index > run.get_node("Murk").z_index and run.get_node("Murk").z_index > 0, "Murk then Lighting must draw above the world")
	# Only the angel's Lamp casts shadows: it lights AngelLight alone, and obstacles occlude it.
	var lamp: PointLight2D = run.player.get_node("Lamp")
	var angel_light: CanvasItem = lighting.get_node("AngelLight")
	check(lamp.range_item_cull_mask == angel_light.light_mask, "The Lamp must light only AngelLight")
	check(lamp.shadow_enabled and lamp.shadow_item_cull_mask & angel_light.light_mask != 0, "AngelLight must receive shadows")
	var obstacle: Breakable = null
	for child: Node in run.obstacles.get_children():
		var each: Breakable = child as Breakable
		if each.kind == Breakable.Kind.SHRINE:
			check(is_light(each) and is_instance_valid(each.light_occluder), "Every shrine must be a light and cast a shadow")
		elif obstacle == null and each.kind == Breakable.Kind.STRUCTURE:
			obstacle = each
	check(lamp.shadow_item_cull_mask & obstacle.light_occluder.occluder_light_mask != 0, "Obstacles must shadow the Lamp")
	check(obstacle.light_occluder.occluder.polygon == PackedVector2Array([Vector2(-52, -52), Vector2(52, -52), Vector2(52, 60), Vector2(-52, 60)]), "Structure shadow must match the pillar art")
	obstacle.take_blow(1000)
	await process_frame
	check(not is_instance_valid(obstacle.light_occluder), "A broken obstacle must stop casting a shadow")
	var shared: Material = preload("res://shaders/eyes.tres")
	for i: int in Run.ENEMY_TYPES.size():
		var enemy: Enemy = run.spawn_enemy(i, Vector2(800,800))
		check(enemy.sprite.material == shared, "Every enemy must share the sin glow material")
		check(is_light(enemy.sprite), "Every enemy must be a light")
		check_key_frames(enemy.sprite, enemy.frames)
	for data: Dictionary in Run.BOSSES:
		var boss: Boss = Run.BOSS_SCENE.instantiate()
		boss.frames = data.frames
		run.actors.add_child(boss)
		check(boss.sprite.material == shared, "Every boss must share the sin glow material")
		check(is_light(boss.sprite), "Every boss must be a light")
		check_key_frames(boss.sprite, boss.frames)
	var shot: EnemyProjectile = EnemyProjectile.new()
	run.effects.add_child(shot)
	check(shot.material == preload("res://shaders/enemy_ammo.tres") and is_light(shot), "Enemy ammunition must emit hot light")
	var arrow: Arrow = Arrow.new()
	run.effects.add_child(arrow)
	arrow.set_physics_process(false)
	check(arrow.material == preload("res://shaders/weapon_light.tres") and is_light(arrow), "Arrows must emit cool light")
	var portal: ExitPortal = Run.PORTAL_SCENE.instantiate()
	run.add_child(portal)
	check(is_light(portal), "The exit portal must be a light")
	check(run.lava.get_child_count() > 0, "Lava needs blob lights")
	for blob: Node in run.lava.get_children():
		check(is_light(blob), "Every lava blob must be a light")
	for name: String in ["Sprite", "Spear", "Bow"]:
		check(run.player.get_node(name).material is ShaderMaterial, "Player and weapons need emission")
	check_key_frames(run.player.sprite, run.player.sprite.sprite_frames)
	# The angel's own lights: wings (the sprite), halo, spear and bow, and the descent beam.
	for path: String in ["Sprite", "Sprite/HaloLight", "Spear/SpearLight", "Bow/BowLight"]:
		check(is_light(run.player.get_node(path)), "%s must be a light" % path)
	var beam: Node2D = run.player.get_node("Beam")
	check(beam.get_child_count() > 0 and not beam.visible, "The beam lights must stay off outside the descent")
	for beam_light: Node in beam.get_children():
		check(is_light(beam_light), "Every beam light must be a light")
	run.player.position = Vector2(0.25, 0.5)
	run.player.begin_descent(600.0, 1.0)
	await physics_frame
	await physics_frame
	check(beam.visible, "The beam lights must shine during the descent")
	check(is_equal_approx(lamp.position.y, -run.player.height) and lamp.energy < 2.5, "The lamp must follow the angel and fade during descent")
	run.player.height = 0.0
	run.player._update_lamp()
	check(lamp.position.is_zero_approx() and is_equal_approx(lamp.energy, 2.5), "The lamp must return to full strength on the ground")
	run.player.camera.force_update_scroll()
	var screen_transform: Transform2D = root.get_final_transform() * run.get_global_transform_with_canvas()
	check(screen_transform.origin.is_equal_approx(screen_transform.origin.round()), "The camera must snap to whole screen pixels")
	for kind: int in Pickup.Kind.size():
		var pickup: Pickup = run.spawn_pickup(kind, Vector2(600, 600), 1)
		check(pickup.material == preload("res://shaders/pickup_light.tres") and is_light(pickup), "Every pickup must glow and be a light")
	# Lights leave with their node: nothing to unregister.
	var before: int = get_nodes_in_group(&"light").size()
	arrow.queue_free()
	await process_frame
	check(get_nodes_in_group(&"light").size() == before - 1, "A freed light must leave the light group")
	run.queue_free()
	await process_frame
	print("glow_smoke: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

## The rule scripts/lights.gd draws by: in group "light", with light metadata on the node or its material.
func is_light(item: CanvasItem) -> bool:
	var source: Object = item if item.has_meta(&"light") else item.material
	return item.is_in_group(&"light") and source != null and source.get_meta(&"light", null) is Color and float(source.get_meta(&"light_radius", 0.0)) > 0.0

## Glow by palette colour: every frame must carry at least one pixel of the material's key.
func check_key_frames(sprite: AnimatedSprite2D, frames: SpriteFrames) -> void:
	var key: Color = (sprite.material as ShaderMaterial).get_shader_parameter(&"key")
	for animation: StringName in frames.get_animation_names():
		for index: int in frames.get_frame_count(animation):
			var pixels: Image = frames.get_frame_texture(animation, index).get_image()
			var found: bool = false
			for y: int in pixels.get_height():
				for x: int in pixels.get_width():
					var pixel: Color = pixels.get_pixel(x, y)
					# The material's key is rounded; the shader's tolerance absorbs the same gap.
					if pixel.a > 0.5 and Vector3(pixel.r - key.r, pixel.g - key.g, pixel.b - key.b).length() < 0.01:
						found = true
			check(found, "%s %s frame %d needs a glow-key pixel" % [frames.resource_path, animation, index])
