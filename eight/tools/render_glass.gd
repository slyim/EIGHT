extends SceneTree
## Renders PNGs through the game's stained-glass shader, so the jury deck shows the exact look
## the game draws. Needs a rendering window (not --headless).
## Run: godot --path eight --script res://tools/render_glass.gd -- <in_dir> <out_dir> [scale]

const GLASS: Shader = preload("res://shaders/stained_glass.gdshader")


func _initialize() -> void:
	_render.call_deferred()


func _render() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <in_dir> <out_dir> [scale]")
		quit(1)
		return
	var scale: float = float(args[2]) if args.size() > 2 else 1.0
	DirAccess.make_dir_recursive_absolute(args[1])
	for file: String in DirAccess.get_files_at(args[0]):
		if not file.ends_with(".png"):
			continue
		var image: Image = Image.load_from_file(args[0].path_join(file))
		var size: Vector2i = Vector2i(Vector2(image.get_size()) * scale)
		var viewport: SubViewport = SubViewport.new()
		viewport.size = size
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		var rect: TextureRect = TextureRect.new()
		rect.texture = ImageTexture.create_from_image(image)
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.size = Vector2(size)
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = GLASS
		rect.material = material
		viewport.add_child(rect)
		root.add_child(viewport)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(args[1].path_join(file))
		viewport.queue_free()
	quit()
