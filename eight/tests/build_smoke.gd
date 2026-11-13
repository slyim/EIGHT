extends SceneTree
## The run build: level-up stats (might, armor, haste, luck), chests and guard relics, side
## weapons found and levelled to their cap (then experience), and each side weapon striking:
## halos on touch, feathers at the nearest, the pulse in its ring, the bolt within range.
## Native Godot only.

const RUN_SCENE: PackedScene = preload("res://scenes/run.tscn")

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


func _dummy(run: Run, at: Vector2, type_index: int = 0) -> Enemy:
	var enemy: Enemy = run.spawn_enemy(type_index, at)
	enemy.speed = 0.0
	enemy.knockback_strength = 0.0
	enemy.max_health = 100
	enemy.health = 100
	return enemy


func _clear(run: Run) -> void:
	for child: Node in run.actors.get_children():
		child.free()
	for child: Node in run.pickups.get_children():
		child.free()
	run.enemy_count = 0
	run.player.global_position = Vector2.ZERO
	await _ticks(2)


func _fresh() -> Run:
	var run: Run = RUN_SCENE.instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	await _ticks(3)
	run.player.invulnerable_left = 100000.0
	await _clear(run)
	return run


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var run: Run = await _fresh()
	var player: MountedPlayer = run.player

	# 1. Stats. Might scales spear, bow, and side-weapon damage; armor trims hits to a floor of
	# 1; haste shortens attack cooldowns; luck multiplies drop chances.
	_check(player.dealt(1) == 1 and player.dealt(3) == 3, "Base might must leave damage alone.")
	run._apply_bonus("might", 1.0)
	_check(player.might == 2.0 and player.dealt(1) == 2 and player.fire_arrow().damage == 2 * player.bow_damage, "Might must double damage at +100%%.")
	# Real hits under might: a spear thrust and a pulse each deal double.
	var struck: Enemy = _dummy(run, Vector2(60.0, 0.0))
	player.set_physics_process(false)
	player.attack_step = -1
	player.thrust_direction = Vector2.RIGHT
	player.spear_cast.rotation = 0.0
	player.spear_cast.target_position = Vector2(player.spear_reach, 0.0)
	player.spear_cast.collision_mask = MountedPlayer.SPEAR_GROUND_MASK
	player.thrust_hits_left = 1
	player.spear_cast.clear_exceptions()
	player._resolve_spear_hits()
	_check(struck.health == 100 - 2 * player.spear_damage, "A spear thrust must deal double under might (health %d)." % struck.health)
	player.set_physics_process(true)
	player.side_weapons.add(SideWeapons.Kind.PULSE)
	struck.health = 100
	await _ticks(3)
	_check(struck.health == 100 - 2 * SideWeapons.PULSE_DAMAGE[0], "A side weapon must deal double under might (health %d)." % struck.health)
	player.side_weapons.levels[SideWeapons.Kind.PULSE] = 0
	run._apply_bonus("might", -1.0)
	await _clear(run)
	run._apply_bonus("armor", 3.0)
	player.invulnerable_left = 0.0
	var health: int = player.health
	player.take_damage(10)
	_check(player.health == health - 7, "Armor must take 3 off a hit (got %d)." % (health - player.health))
	player.invulnerable_left = 0.0
	health = player.health
	player.take_damage(2)
	_check(player.health == health - 1, "Armor must never cut a hit below 1.")
	player.armor = 0
	player.invulnerable_left = 100000.0
	run._apply_bonus("haste", 0.5)
	_check(is_equal_approx(player.haste, 0.5), "Haste must multiply cooldowns.")
	player.weapon = MountedPlayer.Weapon.BOW
	player.attack_step = -1
	player.combo_window_left = 0.0
	player.cooldown_left = 0.0
	player.attack_buffer_left = 0.1
	await _ticks(2)
	_check(player.cooldown_left <= player.bow_cooldown * 0.5 + 0.001, "A hasted bow must recover twice as fast (%.3f)." % player.cooldown_left)
	player.haste = 1.0
	player.weapon = MountedPlayer.Weapon.SPEAR
	run._apply_bonus("luck", 1.0)
	run.heart_drop_chance = 0.5
	var hearts: int = 0
	for roll: int in range(40):
		var husk: Enemy = run.spawn_enemy(0, Vector2(900.0, 900.0))
		husk.take_hit(1000)
	for child: Node in run.pickups.get_children():
		if (child as Pickup).kind == Pickup.Kind.HEART:
			hearts += 1
	_check(hearts == 40, "Luck x2 on a 50%% heart chance must always drop (got %d / 40)." % hearts)
	player.luck = 1.0
	run.heart_drop_chance = 0.0
	var names: Array = Run.UPGRADES.map(func(upgrade: Dictionary) -> String: return upgrade["stat"])
	_check(names.has("might") and names.has("armor") and names.has("haste") and names.has("luck"), "Level-ups must offer Might, Armor, Haste, and Luck.")
	await _clear(run)

	# 2. Chests: three per map from its seed, on open ground away from the landing site; walking
	# up opens one once and a relic spills out.
	_check(run.chests.get_child_count() == Run.CHEST_COUNT, "A map without authored chests must get %d (got %d)." % [Run.CHEST_COUNT, run.chests.get_child_count()])
	for child: Node in run.chests.get_children():
		var spot: Vector2 = (child as Chest).position
		var clear: bool = spot.length() >= Run.CHEST_CLEARANCE and not run.lava.point_in_lava(spot)
		for obstacle: Node in run.obstacles.get_children():
			clear = clear and not (obstacle as Breakable).footprint().grow(20.0).has_point(spot)
		_check(clear, "A chest must stand on open ground away from the landing site (%s)." % spot)
	var chest: Chest = run.chests.get_child(0) as Chest
	player.global_position = chest.global_position + Vector2(0.0, -Chest.OPEN_RADIUS + 4.0)
	await _ticks(3)
	var relics: int = 0
	for child: Node in run.pickups.get_children():
		if (child as Pickup).kind == Pickup.Kind.RELIC:
			relics += 1
	_check(chest.is_open and relics == 1, "Walking up must open the chest and spill one relic.")
	await _ticks(10)
	player.global_position += Vector2(0.0, 1.0)
	await _ticks(10)
	relics = run.pickups.get_children().filter(func(pickup: Node) -> bool: return (pickup as Pickup).kind == Pickup.Kind.RELIC).size()
	_check(relics == 1 and not chest.is_in_group(&"light"), "An open chest must stay open, spill no second relic, and stop glowing (%d relics)." % relics)
	# Portals and spawns keep clear of chests.
	var other: Chest = run.chests.get_child(1) as Chest
	var portal: Vector2 = run._portal_position(other.position)
	_check(not other.footprint().grow(ExitPortal.RADIUS).has_point(portal), "A portal must not open over a chest (%s)." % portal)
	await _clear(run)

	# Haste has one floor; at the floor it leaves the level-up pool.
	player.haste = MountedPlayer.HASTE_FLOOR
	run._apply_bonus("haste", 0.92)
	_check(is_equal_approx(player.haste, MountedPlayer.HASTE_FLOOR), "Haste must stop at its floor.")
	for offer: int in range(20):
		run._offer_level_up()
		_check(not run.level_up_options.any(func(option: Dictionary) -> bool: return option["stat"] == "haste"), "Haste at its floor must not be offered.")
		run.level_up_options.clear()
	run.hud.hide_level_up()
	paused = false
	player.haste = 1.0

	# 3. A slain guard leaves a relic beside its evolution item.
	var guard: Boss = run.guards[0]
	if not is_instance_valid(guard):
		guard = run._make_boss(Run.GUARD_HEALTH_SCALE)
		guard.died.connect(run._on_guard_died)
		run.actors.add_child(guard)
	guard.take_hit(guard.max_health)
	await _ticks(2)
	var kinds: Array = run.pickups.get_children().map(func(pickup: Node) -> int: return (pickup as Pickup).kind)
	_check(kinds.has(Pickup.Kind.RELIC) and kinds.has(Pickup.Kind.EVOLUTION), "A guard must drop a relic and an evolution item (got %s)." % [kinds])
	await _clear(run)

	# 4. Relics find or level side weapons to the cap of 3 each; then they give experience.
	var weapons: SideWeapons = player.side_weapons
	for find: int in range(SideWeapons.Kind.size() * SideWeapons.MAX_LEVEL):
		run.grant_relic()
	_check(weapons.levels == [3, 3, 3, 3], "Twelve relics must max every side weapon (got %s)." % [weapons.levels])
	_check(weapons.can_grow().is_empty(), "Nothing may grow past the cap.")
	var xp_before: int = run.xp
	var level_before: int = run.level
	run.grant_relic()
	_check(run.xp != xp_before or run.level != level_before, "A relic past every cap must give experience.")
	while run.pending_level_ups > 0:
		run.choose_upgrade(0)
	await _ticks(2)
	_check(run.hud.side_label.visible and run.hud.side_label.text.contains("ORBITING HALOS III"), "The HUD must list the side weapons (%s)." % run.hud.side_label.text)
	_check(run.hud.relic_label.visible and run.hud.relic_label.text.begins_with("UPGRADED"), "The HUD must announce the latest find.")
	run.queue_free()
	await _ticks(2)

	# 5. Each side weapon strikes on its own (fresh runs, one weapon each).
	run = await _fresh()
	player = run.player
	player.side_weapons.add(SideWeapons.Kind.HALOS)
	var orb_hit: Enemy = _dummy(run, Vector2(SideWeapons.HALO_RADIUS, 0.0))
	await _ticks(90)
	_check(orb_hit.health < 100, "Orbiting halos must strike what they touch.")
	var hits: int = 100 - orb_hit.health
	_check(hits <= ceili(1.5 / SideWeapons.HALO_REHIT) * 2 + 1, "Halos must not strike the same target every tick (%d damage in 1.5 s)." % hits)
	run.queue_free()
	await _ticks(2)

	run = await _fresh()
	player = run.player
	player.side_weapons.add(SideWeapons.Kind.FEATHERS)
	await _ticks(30)
	var shots_idle: int = run.get_children().filter(func(node: Node) -> bool: return node is Arrow).size()
	_check(shots_idle == 0, "Feathers must not fire with nothing in range.")
	var near: Enemy = _dummy(run, Vector2(200.0, 0.0))
	var far: Enemy = _dummy(run, Vector2(SideWeapons.FEATHER_RANGE + 200.0, 0.0))
	await _ticks(40)
	_check(near.health < 100 and far.health == 100, "Feathers must strike the nearest enemy in range (%d, %d)." % [near.health, far.health])
	var hasted_wait: float = player.side_weapons.waits[SideWeapons.Kind.FEATHERS]
	_check(hasted_wait > 0.0 and hasted_wait <= SideWeapons.FEATHER_INTERVAL, "Feathers must wait their interval after firing.")
	player.haste = 0.5
	near.health = 100
	player.side_weapons.waits[SideWeapons.Kind.FEATHERS] = 0.0
	await _ticks(3)
	_check(player.side_weapons.waits[SideWeapons.Kind.FEATHERS] <= SideWeapons.FEATHER_INTERVAL * 0.5 + 0.01, "Haste must shorten side-weapon intervals.")
	run.queue_free()
	await _ticks(2)

	run = await _fresh()
	player = run.player
	player.side_weapons.add(SideWeapons.Kind.PULSE)
	var inside: Enemy = _dummy(run, Vector2(SideWeapons.PULSE_RADIUS[0] - 30.0, 0.0))
	var flying: Enemy = _dummy(run, Vector2(0.0, SideWeapons.PULSE_RADIUS[0] - 30.0), 3)
	var outside: Enemy = _dummy(run, Vector2(SideWeapons.PULSE_RADIUS[0] + 80.0, 0.0))
	await _ticks(5)
	_check(inside.health < 100 and flying.health < 100 and outside.health == 100, "The pulse must strike ground and flying enemies inside its ring only (%d, %d, %d)." % [inside.health, flying.health, outside.health])
	run.queue_free()
	await _ticks(2)

	run = await _fresh()
	player = run.player
	player.side_weapons.add(SideWeapons.Kind.BOLT)
	var target: Enemy = _dummy(run, Vector2(300.0, 100.0))
	var beyond: Enemy = _dummy(run, Vector2(SideWeapons.BOLT_RANGE + 300.0, 0.0))
	await _ticks(5)
	_check(target.health < 100 and beyond.health == 100, "The bolt must strike an enemy within range only (%d, %d)." % [target.health, beyond.health])
	# Walls block side weapons: a walled enemy is never struck by bolt, pulse, or halos.
	player.side_weapons.add(SideWeapons.Kind.PULSE)
	player.side_weapons.add(SideWeapons.Kind.HALOS)
	for child: Node in run.actors.get_children():
		child.free()
	run.enemy_count = 0
	var hidden: Enemy = _dummy(run, Vector2(110.0, 0.0))
	var wall: Breakable = run._add_obstacle(Breakable.Kind.WALL, Vector2(56.0, 0.0), true)
	await _ticks(200)
	_check(hidden.health == 100, "No side weapon may strike through a wall (health %d)." % hidden.health)
	wall.free()
	await _ticks(2)
	# Side weapons rest while the angel has fallen.
	player.kill()
	var before: int = hidden.health
	for kind: int in range(player.side_weapons.waits.size()):
		player.side_weapons.waits[kind] = 0.0
	await _ticks(10)
	_check(hidden.health == before, "Side weapons must stop once the angel falls.")
	run.queue_free()
	await _ticks(2)

	# The ending stops feathers already in flight, and chests stay shut through the ascension.
	run = await _fresh()
	player = run.player
	player.side_weapons.add(SideWeapons.Kind.FEATHERS)
	var victim: Enemy = _dummy(run, Vector2(400.0, 0.0))
	await _ticks(2)
	_check(not get_nodes_in_group(&"side_shots").is_empty(), "A feather must be in flight.")
	player.kill()
	# Long enough for the feather to cover the distance (about 34 ticks at its speed).
	await _ticks(70)
	_check(victim.health == 100, "A feather in flight must not strike after the angel falls (health %d)." % victim.health)
	run.queue_free()
	await _ticks(2)
	run = await _fresh()
	player = run.player
	var shut: Chest = run.chests.get_child(0) as Chest
	run._end_run(true)
	player.global_position = shut.global_position
	await _ticks(10)
	_check(not shut.is_open, "A chest must not open during the ending.")
	run.queue_free()
	await _ticks(15)
	if failures == 0:
		print("Build smoke passed: might, armor floor, haste, luck, the four stat level-ups, seeded chests on open ground, chest opens once with a relic, guard relic + evolution, side weapons levelled to the cap then XP, HUD list and announcement, halos (with re-hit delay), feathers (nearest in range, interval, haste), pulse (ring, ground and air), bolt (range), weapons rest when fallen.")
	quit(1 if failures > 0 else 0)
