extends SceneTree
## Native smoke check for the PLACEHOLDER lava pools: burn rate, grace, air and dash
## safety, defeat by burning, hazard-blind enemies, and the deterministic per-map layout.

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
	# Query semantics on a hand-built single-blob pool, away from the arena.
	var lava: LavaPools = LavaPools.new()
	lava.set_pools([[[Vector2(4000.0, 4000.0), 100.0]]])
	_check(lava.point_in_lava(Vector2(4000.0, 4000.0)), "A pool centre must read as lava.")
	_check(lava.point_in_lava(Vector2(4089.0, 4000.0)), "Inside the drawn rim must read as lava.")
	_check(not lava.point_in_lava(Vector2(4101.0, 4000.0)), "Outside the drawn rim must read as dry.")
	_check(not lava.point_in_lava(Vector2(4089.0, 4000.0), 12.0), "The burn inset must forgive the rim.")
	_check(lava.point_in_lava(Vector2(4050.0, 4000.0), 12.0), "Deep molten must still burn.")
	lava.free()

	var run: Run = RUN_SCENE.instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	var player: MountedPlayer = run.player
	var lava_node: LavaPools = run.lava

	# Layout: a handful of pools, inside the arena, clear of landing, walls, pillars, each other.
	_check(lava_node.pools.size() >= Run.LAVA_COUNT_MIN and lava_node.pools.size() <= Run.LAVA_COUNT_MAX,
			"A map must dress a handful of pools, got %d." % lava_node.pools.size())
	_check(not run.hud.burn_label.visible, "The burn callout must start hidden.")
	if lava_node.pools.is_empty():
		quit(failures)
		return
	for pool: Dictionary in lava_node.pools:
		for blob: Array in pool["blobs"]:
			var center: Vector2 = blob[0]
			var radius: float = blob[1]
			_check(center.length() - radius >= Run.LANDING_CLEARANCE + Run.LAVA_LANDING_MARGIN,
					"Lava must keep the landing site clear.")
			_check(Run.ARENA_RECT.encloses(Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0)),
					"Lava must stay inside the arena.")
			_check(not run._blocked_rect(center.x, center.y, radius + Run.LAVA_SPACING),
					"Lava must stay off walls and pillars.")
	for first: int in lava_node.pools.size():
		for second: int in range(first + 1, lava_node.pools.size()):
			_check((lava_node.pools[first]["center"] as Vector2).distance_to(lava_node.pools[second]["center"])
					> (lava_node.pools[first]["extent"] as float) + (lava_node.pools[second]["extent"] as float),
					"Pools must not merge.")
	_check(lava_node.point_in_lava(lava_node.pools[0]["center"]), "A pool centre must query as lava.")
	_check(not lava_node.point_in_lava(lava_node.pools[0]["center"] + Vector2((lava_node.pools[0]["extent"] as float) + 1.0, 0.0)),
			"Beyond a pool must query as dry.")

	# The same sin map must generate the same layout; another map must differ.
	var twin: Run = RUN_SCENE.instantiate() as Run
	twin.intro_enabled = false
	twin.spawning_enabled = false
	root.add_child(twin)
	await _wait_ticks(3)
	_check(str(twin.lava.pools) == str(lava_node.pools), "The same sin map must generate the same lava layout.")
	var shifted: Run = RUN_SCENE.instantiate() as Run
	shifted.sin_index = 3
	shifted.intro_enabled = false
	shifted.spawning_enabled = false
	root.add_child(shifted)
	await _wait_ticks(3)
	_check(str(shifted.lava.pools) != str(lava_node.pools), "Another sin map must generate a different lava layout.")
	twin.queue_free()
	shifted.queue_free()
	await _wait_ticks(2)

	# apply_burn must refuse in every state take_damage refuses (plus none it invents).
	player.dash_time_left = 0.3
	_check(not player.apply_burn(1), "apply_burn must refuse during a dash.")
	player.dash_time_left = 0.0
	player.height = MountedPlayer.JUMP_CLEAR_HEIGHT + 10.0
	_check(not player.apply_burn(1), "apply_burn must refuse while airborne.")
	player.height = 0.0
	player.invulnerable_left = 0.5
	_check(not player.apply_burn(1), "apply_burn must refuse during the hurt-blink.")
	player.invulnerable_left = 0.0
	player.begin_descent(100.0, 0.5)
	_check(not player.apply_burn(1), "apply_burn must refuse during the descent.")
	await _wait_ticks(35)
	_check(player.health == player.max_health, "No stray damage may land before the burn checks.")

	# Standing in lava burns at the configured rate, once per interval after the grace.
	var pool: Dictionary = lava_node.pools[0]
	var spot: Vector2 = pool["blobs"][0][0]
	var damage: int = lava_node.burn_damage
	player.invulnerable_left = 0.0
	player.position = spot
	await _wait_ticks(30) # 0.5 s: the grace has elapsed and exactly one tick has fired.
	_check(player.health == player.max_health - damage, "Standing in lava must burn once after the grace, got %d." % player.health)
	_check(lava_node.burning and run.hud.burn_label.visible, "Burning must show while standing in lava.")
	await _wait_ticks(30) # second tick at 0.9 s
	_check(player.health == player.max_health - 2 * damage, "Burns must keep ticking at their own rate.")
	await _wait_ticks(30) # third tick at 1.4 s
	_check(player.health == player.max_health - 3 * damage, "Burns must keep ticking at their own rate.")

	# The first tick waits out the grace: a quick brush across the edge burns nothing.
	player.heal(player.max_health)
	player.position = Vector2.ZERO
	await _wait_ticks(3)
	player.position = spot
	await _wait_ticks(20) # 0.33 s, inside the grace
	_check(player.health == player.max_health, "The first burn must wait out the grace.")
	await _wait_ticks(15) # past the grace
	_check(player.health == player.max_health - damage, "The first burn must land shortly after the grace.")

	# Leaving the pool stops the burn.
	var after_grace: int = player.health
	player.position = Vector2.ZERO
	await _wait_ticks(36) # longer than a full interval
	_check(player.health == after_grace, "Leaving the lava must stop the burn.")
	_check(not lava_node.burning and not run.hud.burn_label.visible, "Burning must clear once out of the lava.")

	# Flying over lava is safe, and landing in it restarts the grace.
	player.heal(player.max_health)
	player.position = spot
	Input.action_press(&"jump")
	await _wait_ticks(14)
	_check(player.is_airborne(), "Holding Space must lift the angel over the pool.")
	await _wait_ticks(40) # hover well past the grace
	_check(player.health == player.max_health, "Flying over lava must not burn.")
	Input.action_release(&"jump")
	await _wait_ticks(42) # glide down (0.25 s), fresh grace (0.4 s), one tick
	_check(player.health == player.max_health - damage, "Landing in lava must restart the grace, then burn.")

	# Dashing across lava neither burns nor builds exposure, and exposure restarts after.
	player.heal(player.max_health)
	player.invulnerable_left = 0.0
	player.position = spot
	player.dash_direction = Vector2.ZERO # hold a live dash in place, like projectile_smoke
	player.dash_time_left = 0.9
	await _wait_ticks(30)
	_check(player.health == player.max_health, "Dashing in lava must neither burn nor build exposure.")
	player.dash_time_left = 0.0
	player.dash_direction = Vector2.RIGHT
	await _wait_ticks(30) # fresh grace (0.4 s), one tick
	_check(player.health == player.max_health - damage, "Exposure must restart fresh after a dash.")

	# Burning down to zero slays the angel and ends the run in defeat.
	player.invulnerable_left = 0.0
	player.health = damage
	player.position = spot
	await _wait_ticks(30)
	_check(player.health == 0 and player.is_dead, "Burning to zero must slay the angel.")
	_check(run.ended and not run.victory, "Burning to zero must end the run in defeat.")
	await _wait_ticks(roundi(Run.FALL_TIME * 60.0) + 10)
	_check(run.hud.end_label.visible, "The defeat message must be shown after the fall.")
	run.queue_free()
	await _wait_ticks(2)

	# A fresh run: ground enemies and bosses wade through lava unharmed and unslowed.
	var second: Run = RUN_SCENE.instantiate() as Run
	second.intro_enabled = false
	second.spawning_enabled = false
	root.add_child(second)
	current_scene = second
	await _wait_ticks(3)
	var lava_two: LavaPools = second.lava
	var player_two: MountedPlayer = second.player
	var wader: Enemy = second.spawn_enemy(0, lava_two.pools[0]["blobs"][0][0])
	var wader_speed: float = wader.speed
	var wader_start: Vector2 = wader.global_position
	var brute: Boss = second.spawn_sin_boss()
	brute.position = lava_two.pools[0]["center"]
	brute.attack_interval = 999.0
	var brute_speed: float = brute.speed
	await _wait_ticks(40)
	_check(wader.health == wader.max_health, "Lava must not burn enemies.")
	_check(wader.speed == wader_speed, "Lava must not slow enemies.")
	_check(wader.global_position.distance_to(wader_start) > 30.0, "Lava must not block enemy movement.")
	_check(brute.health == brute.max_health, "Lava must not burn bosses.")
	_check(brute.speed == brute_speed, "Lava must not slow bosses.")
	brute.free()
	second.current_boss = null
	wader.take_hit(9999)
	await _wait_ticks(2)
	# Its loot could heal the angel mid-check, and hit-stop slows ticks: keep this part exact.
	for pickup: Node in second.pickups.get_children():
		pickup.free()
	player_two.hit_stop_enabled = false

	# An enemy hit lands while standing in lava, its blink delays the burn, burn resumes.
	player_two.invulnerable_left = 0.0
	player_two.position = lava_two.pools[0]["blobs"][0][0]
	await _wait_ticks(30)
	_check(player_two.health == player_two.max_health - lava_two.burn_damage, "The angel must burn in lava first.")
	var toucher: Enemy = second.spawn_enemy(0, player_two.global_position)
	await _wait_ticks(4)
	_check(player_two.health == player_two.max_health - lava_two.burn_damage - toucher.contact_damage,
			"Standing in lava must not shield against enemies.")
	_check(player_two.invulnerable_left > 0.0, "The enemy hit must start its hurt invulnerability.")
	await _wait_ticks(30) # the next tick falls inside the hurt window
	_check(player_two.health == player_two.max_health - lava_two.burn_damage - toucher.contact_damage,
			"The hurt-blink must delay burn ticks instead of being ignored.")
	var toucher_damage: int = toucher.contact_damage
	toucher.free()
	await _wait_ticks(2)
	player_two.invulnerable_left = 0.0
	lava_two.burn_left = 0.05
	await _wait_ticks(15)
	_check(player_two.health == player_two.max_health - 2 * lava_two.burn_damage - toucher_damage,
			"Burn must resume at its own rate once the blink ends.")

	second.queue_free()
	# Let the audio server release playbacks before quitting.
	await _wait_ticks(15)
	if failures == 0:
		print("Lava smoke passed: query and inset, deterministic per-map layout, burn rate and grace, air and dash safety, defeat, hazard-blind enemies, hurt-blink interplay.")
	quit(failures)
