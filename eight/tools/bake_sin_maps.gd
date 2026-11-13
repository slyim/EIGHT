extends SceneTree
## Writes one editable map scene per sin (and Satan) under res://scenes/sins/, each inheriting
## run.tscn with its sin_index set, its PLACEHOLDER obstacles and shrines as real Breakable
## nodes, and its lava as lava_layout data. Existing map scenes are never overwritten, so
## hand edits are safe; delete a file to regenerate it.
## Run: godot --headless --path eight --script res://tools/bake_sin_maps.gd

const RUN_SCENE: PackedScene = preload("res://scenes/run.tscn")
const OUT_DIR: String = "res://scenes/sins/"


func _initialize() -> void:
	_bake.call_deferred()


func _bake() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var failures: int = 0
	for sin: int in range(Run.BOSSES.size()):
		var path: String = map_path(sin)
		if FileAccess.file_exists(path):
			print("kept ", path)
			continue
		# Generate the layout in a live run, then copy it into a clean inherited scene.
		var live: Run = RUN_SCENE.instantiate() as Run
		live.sin_index = sin
		live.intro_enabled = false
		live.spawning_enabled = false
		root.add_child(live)
		var text: PackedStringArray = [
			"[gd_scene load_steps=3 format=3]",
			"",
			"[ext_resource type=\"PackedScene\" path=\"res://scenes/run.tscn\" id=\"1_run\"]",
			"[ext_resource type=\"PackedScene\" path=\"res://scenes/breakable.tscn\" id=\"2_breakable\"]",
			"",
			"[node name=\"%s\" instance=ExtResource(\"1_run\")]" % String(Run.BOSSES[sin]["name"]).capitalize(),
			"sin_index = %d" % sin,
		]
		var pools: Array = []
		for pool: Dictionary in live.lava.pools:
			pools.append(pool["blobs"])
		text.append("lava_layout = %s" % var_to_str(pools))
		var counts: Dictionary = {}
		for child: Node in live.obstacles.get_children():
			var source: Breakable = child as Breakable
			var kind_name: String = String(Breakable.Kind.keys()[source.kind]).capitalize()
			counts[kind_name] = int(counts.get(kind_name, 0)) + 1
			text.append("")
			text.append("[node name=\"%s%d\" parent=\"Obstacles\" instance=ExtResource(\"2_breakable\")]" % [kind_name, counts[kind_name]])
			text.append("position = %s" % var_to_str(source.position.round()))
			text.append("kind = %d" % source.kind)
			if source.vertical:
				text.append("vertical = true")
		live.free()
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			failures += 1
			push_error("Could not write %s." % path)
			continue
		file.store_string("\n".join(text) + "\n")
		file.close()
		print("baked ", path)
	quit(1 if failures > 0 else 0)


static func map_path(sin: int) -> String:
	return OUT_DIR + String(Run.BOSSES[sin]["name"]).to_lower() + ".tscn"
