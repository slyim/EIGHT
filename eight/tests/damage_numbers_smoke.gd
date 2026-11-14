extends SceneTree
## Native Godot smoke check for floating damage numbers, low-health and hurt-flash screen-edge
## vignette, and the PERFECT dodge callout.

const RUN_SCENE: PackedScene = preload("res://scenes/run.tscn")

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


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	var hud: Hud = run.hud
	var player: MountedPlayer = run.player
	var numbers: DamageNumbers = hud.damage_numbers

	_check(numbers != null and numbers.get_parent() == hud, "Hud must create a single DamageNumbers Control.")
	_check(numbers.mouse_filter == Control.MOUSE_FILTER_IGNORE, "DamageNumbers must ignore mouse input.")
	_check(numbers.get_index() < hud.pause_menu.get_index() and numbers.get_index() < hud.level_up_panel.get_index(), "DamageNumbers must sit behind HUD panels.")
	_check(numbers.entries.is_empty(), "DamageNumbers must start with no live entries.")

	# Emitting enemy_damaged creates a number at the right HUD position.
	var hit_pos: Vector2 = player.global_position + Vector2(120.0, -40.0)
	run.enemy_damaged.emit(hit_pos, 7, false, 101)
	_check(numbers.entries.size() == 1, "Emitting enemy_damaged must create one entry (got %d)." % numbers.entries.size())
	var first_entry: Dictionary = numbers.entries[0]
	var expected_hud: Vector2 = hud.world_to_hud(hit_pos)
	var actual_hud: Vector2 = numbers.entry_hud_position(first_entry)
	_check(actual_hud.distance_to(expected_hud) < 1.0, "Entry must start at world_to_hud (%s vs %s)." % [actual_hud, expected_hud])
	_check(int(first_entry["amount"]) == 7 and not bool(first_entry["heavy"]), "First entry must record amount 7 and normal hit.")
	_check(numbers.is_entry_visible(first_entry), "An in-view damage number must be visible.")

	# Advancing a few frames moves the number upward.
	await _wait_ticks(6)
	_check(numbers.entry_hud_position(numbers.entries[0]).y < expected_hud.y, "Damage number must rise over time.")

	# A second emit with the same key within the lifetime stacks (one entry, summed amount),
	# updates the world position, resets its timer, and keeps heavy once any stacked hit was heavy.
	var moved_pos: Vector2 = hit_pos + Vector2(16.0, -8.0)
	run.enemy_damaged.emit(moved_pos, 14, true, 101)
	_check(numbers.entries.size() == 1, "Same key within lifetime must stack into one entry (got %d)." % numbers.entries.size())
	_check(int(numbers.entries[0]["amount"]) == 21, "Stacked entry must sum amounts to 21 (got %d)." % int(numbers.entries[0]["amount"]))
	_check(bool(numbers.entries[0]["heavy"]), "Heavy must be set when a heavy hit stacks.")
	_check(is_zero_approx(float(numbers.entries[0]["age"])), "Stacking must reset the entry's timer.")
	_check((numbers.entries[0]["at"] as Vector2).is_equal_approx(moved_pos), "Stacked entry must follow the latest hit position.")

	# A subsequent normal hit on the same key must keep heavy = true.
	run.enemy_damaged.emit(moved_pos, 4, false, 101)
	_check(numbers.entries.size() == 1 and int(numbers.entries[0]["amount"]) == 25 and bool(numbers.entries[0]["heavy"]), "Heavy must stick once any stacked hit was heavy.")

	# A different key makes a second entry, and an off-view hit is hidden outside the world view.
	var second_pos: Vector2 = player.global_position + Vector2(-90.0, 30.0)
	run.enemy_damaged.emit(second_pos, 9, false, 202)
	_check(numbers.entries.size() == 2, "Different key must create a second entry (got %d)." % numbers.entries.size())
	var offscreen_pos: Vector2 = player.global_position + Vector2(3000.0, 3000.0)
	run.enemy_damaged.emit(offscreen_pos, 5, false, 303)
	_check(not numbers.is_entry_visible(numbers.entries[2]), "An entry outside the world view must not be visible.")

	# Numbers expire after their lifetime (~0.45 s).
	await _wait_ticks(40)
	_check(numbers.entries.is_empty(), "Numbers must expire after their lifetime (left: %d)." % numbers.entries.size())

	# damage_numbers_enabled = false clears live numbers and blocks new ones.
	run.enemy_damaged.emit(hit_pos, 12, false, 404)
	_check(numbers.entries.size() == 1, "Enabled DamageNumbers must accept a new entry.")
	hud.damage_numbers_enabled = false
	_check(numbers.entries.is_empty(), "Disabling damage_numbers_enabled must clear live entries.")
	run.enemy_damaged.emit(hit_pos, 30, true, 505)
	_check(numbers.entries.is_empty(), "Disabled damage_numbers_enabled must block new entries.")
	hud.damage_numbers_enabled = true

	# The cap (~48) holds and recycles the oldest entries.
	for index: int in range(DamageNumbers.MAX_ENTRIES + 12):
		run.enemy_damaged.emit(hit_pos + Vector2(float(index), 0.0), index + 1, false, 1000 + index)
	_check(numbers.entries.size() == DamageNumbers.MAX_ENTRIES, "Live entries must be capped at %d (got %d)." % [DamageNumbers.MAX_ENTRIES, numbers.entries.size()])
	_check(int(numbers.entries[0]["key"]) == 1012, "Cap must recycle the oldest entries first (oldest key %d)." % int(numbers.entries[0]["key"]))
	numbers.clear()

	# Low-health vignette shows at low health and hides at full health.
	_check(hud.vignette != null and hud.vignette.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Vignette Control must exist and ignore mouse input.")
	_check(not hud.vignette.visible, "Vignette must stay hidden at full health.")
	player.health = roundi(Hud.LOW_LIFE_FRACTION * player.max_health)
	await process_frame
	_check(hud.vignette.visible, "Low-health vignette must show when health <= LOW_LIFE_FRACTION.")
	player.health = player.max_health
	await process_frame
	_check(not hud.vignette.visible, "Low-health vignette must hide again at full health.")

	# Hurt flash appears on player.take_damage even above the low-health threshold, then fades.
	var landed: bool = player.take_damage(10, true)
	_check(landed and player.health == 90, "take_damage(10, true) must land above the low-health threshold.")
	_check(hud.vignette.visible and hud.hurt_flash_left > 0.0, "Hurt flash must show the edge vignette on player.take_damage.")
	await _wait_ticks(20)
	_check(not hud.vignette.visible, "Hurt flash must hide once its brief duration ends above low health.")
	player.invulnerable_left = 0.0
	player.health = player.max_health

	# Emitting player.perfect_dodged shows the PERFECT gold callout near the angel and fades out.
	_check(hud.perfect_label != null and not hud.perfect_label.visible, "PERFECT callout must start hidden.")
	player.perfect_dodged.emit()
	await process_frame
	var angel_hud: Vector2 = hud.world_to_hud(player.global_position)
	var callout_center: Vector2 = hud.perfect_label.get_rect().get_center()
	_check(hud.perfect_label.visible and hud.perfect_label.text == "PERFECT", "Emitting perfect_dodged must show the PERFECT callout.")
	_check(callout_center.distance_to(angel_hud) < 120.0, "PERFECT callout must appear near the angel's HUD position (%s vs %s)." % [callout_center, angel_hud])
	await _wait_ticks(50)
	_check(not hud.perfect_label.visible, "PERFECT callout must hide after fading out.")

	run.queue_free()
	await _wait_ticks(15)

	if failures == 0:
		print("Damage numbers smoke passed.")
	quit(failures)
