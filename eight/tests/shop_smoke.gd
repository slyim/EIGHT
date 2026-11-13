extends SceneTree
## Feathers and the shop: earning in a run (kills, guards, shrines, the sin, gems), banking
## all on a win and half on a defeat, the saved store (validation, purchases that are refused
## when unaffordable, maxed, or unsaved), the shop screen, and ranks applied once to
## hub-launched runs only. Uses its own save file; native Godot only.

const RUN_SCENE: PackedScene = preload("res://scenes/run.tscn")
const TEST_SAVE: String = "user://test_shop.cfg"

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


func _save(feathers: Variant, ranks: Dictionary = {}) -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("progress", "feathers", feathers)
	for id: String in ranks:
		file.set_value("upgrades", id, ranks[id])
	file.save(TEST_SAVE)


func _scene_becomes(script: Script, limit: int = 900) -> bool:
	for tick: int in range(limit):
		if current_scene != null and current_scene.get_script() == script and current_scene.is_node_ready():
			return true
		await process_frame
	return false


func _run() -> void:
	root.size = Vector2i(1280, 720)
	Progress.path = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))

	# 1. Earning in a run: kills, a guard, a shrine, the sin, and a gem.
	var run: Run = RUN_SCENE.instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	await _ticks(3)
	run.player.invulnerable_left = 100000.0
	_check(run.feathers_earned == 0, "A run must start with no feathers.")
	run.spawn_enemy(0, Vector2(900.0, 900.0)).take_hit(1000)
	_check(run.feathers_earned == Run.FEATHERS_PER_KILL, "A kill must earn feathers.")
	var guard: Boss = run.guards[0]
	var before: int = run.feathers_earned
	guard.take_hit(guard.max_health)
	_check(run.feathers_earned == before + Run.FEATHERS_PER_GUARD, "A guard must earn more.")
	before = run.feathers_earned
	var shrines: Array = run.obstacles.get_children().filter(func(node: Node) -> bool: return (node as Breakable).kind == Breakable.Kind.SHRINE)
	(shrines[0] as Breakable).take_blow(1000)
	_check(run.feathers_earned == before + Run.FEATHERS_PER_SHRINE, "A shrine must earn feathers.")
	before = run.feathers_earned
	run.spawn_pickup(Pickup.Kind.FEATHER, run.player.global_position + Vector2(60.0, 0.0), Run.FEATHER_GEM_VALUE)
	await _ticks(20)
	_check(run.feathers_earned == before + Run.FEATHER_GEM_VALUE, "A feather gem must be pulled in and counted.")
	run.feather_drop_chance = 1.0
	var gems: int = 0
	run.spawn_enemy(0, Vector2(-900.0, 900.0)).take_hit(1000)
	for child: Node in run.pickups.get_children():
		gems += 1 if (child as Pickup).kind == Pickup.Kind.FEATHER else 0
	_check(gems >= 1, "Horde enemies must be able to drop feather gems.")
	for shrine: Variant in shrines:
		if is_instance_valid(shrine):
			(shrine as Breakable).take_blow(1000)
	await _ticks(2)
	before = run.feathers_earned
	run.current_boss.take_hit(100000)
	await _ticks(2)
	_check(run.feathers_earned >= before + Run.FEATHERS_PER_SIN, "The sin must pay its reward.")
	await _ticks(2)
	_check(run.hud.stats_label.text.contains("FEATHERS %d" % run.feathers_earned), "The HUD must count the run's feathers (%s)." % run.hud.stats_label.text)
	_check(run.hud.stats_label.get_minimum_size().x <= run.hud.stats_label.size.x, "The status line must still fit its panel.")
	run.kills = 9876543
	run.feathers_earned = 1234567
	await _ticks(2)
	_check(run.hud.stats_label.text.contains("KILLS 9876.5K") and run.hud.stats_label.get_minimum_size().x <= run.hud.stats_label.size.x, "Huge counters must stay compact and fit (%s)." % run.hud.stats_label.text)
	run.queue_free()
	await _ticks(2)

	# 2. The store: validation, purchases, maxing, and failed saves.
	_save(-50, {"might": 99, "health": -3, "nonsense": 4})
	var progress: Progress = Progress.load_saved()
	_check(progress.feathers == 0 and progress.rank("might") == 5 and progress.rank("health") == 0 and not progress.ranks.has("nonsense"), "Damaged values must be clamped or ignored (%d, %s)." % [progress.feathers, progress.ranks])
	_save(15)
	var campaign: ConfigFile = ConfigFile.new()
	campaign.load(TEST_SAVE)
	campaign.set_value("progress", "sealed", [0, 3, 5])
	campaign.set_value("progress", "satan_defeated", true)
	campaign.save(TEST_SAVE)
	progress = Progress.load_saved()
	_check(progress.buy("armor") == ERR_UNAVAILABLE and progress.feathers == 15 and progress.rank("armor") == 0, "An unaffordable rank must change nothing.")
	_check(progress.buy("health") == OK and progress.feathers == 5 and progress.rank("health") == 1, "A purchase must deduct its price and add a rank.")
	var reloaded: Progress = Progress.load_saved()
	_check(reloaded.feathers == 5 and reloaded.rank("health") == 1, "A purchase must be saved at once.")
	_check(reloaded.sealed == [0, 3, 5] and reloaded.satan_defeated, "A purchase must keep sealed sins and Satan's fall (%s, %s)." % [reloaded.sealed, reloaded.satan_defeated])
	_save(100000, {"pull": 5})
	progress = Progress.load_saved()
	_check(progress.next_cost("pull") == -1 and progress.buy("pull") == ERR_UNAVAILABLE and progress.feathers == 100000, "A maxed upgrade must refuse further ranks.")
	Progress.path = "user://missing_folder/nested/shop.cfg"
	_check(progress.buy("health") != OK and progress.feathers == 100000 and progress.rank("health") == 0, "A purchase that cannot be saved must be undone.")
	Progress.path = TEST_SAVE

	# 3. The shop screen from the hub: rows with pips and prices, buying, and back.
	_save(40)
	change_scene_to_file(Game.HUB_SCENE)
	_check(await _scene_becomes(Hub), "The hub must open.")
	_check((current_scene.get_node(^"Feathers") as Label).text == "FEATHERS  40", "The hub must show banked feathers.")
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_B
	key.pressed = true
	Input.parse_input_event(key)
	_check(await _scene_becomes(Shop), "B must open the shop.")
	var shop: Shop = current_scene as Shop
	await _ticks(2)
	_check(shop.rows.size() == Progress.UPGRADES.size() and shop.balance.text == "FEATHERS  40", "The shop must list every upgrade and the balance.")
	var health_row: Control = shop.rows["health"]
	_check((health_row.get_node(^"Pips") as Label).text == "◇◇◇◇◇" and (health_row.get_node(^"Buy") as Button).text == "BUY  10", "A row must show empty pips and the next price.")
	_check((shop.rows["armor"].get_node(^"Buy") as Button).disabled == false and (shop.rows["might"].get_node(^"Buy") as Button).disabled == false, "Affordable ranks must be enabled.")
	(health_row.get_node(^"Buy") as Button).pressed.emit()
	(health_row.get_node(^"Buy") as Button).pressed.emit()
	_check(shop.balance.text == "FEATHERS  5" and (health_row.get_node(^"Pips") as Label).text == "◆◆◇◇◇", "Buying must update the balance and pips (%s)." % shop.balance.text)
	_check((health_row.get_node(^"Buy") as Button).disabled, "An unaffordable rank must be disabled.")
	for row: Control in shop.get_node(^"Panel/Box/List").get_children():
		_check(shop.get_global_rect().encloses(row.get_global_rect()), "Shop rows must fit the screen.")
	(shop.get_node(^"Panel/Box/Back") as Button).pressed.emit()
	_check(await _scene_becomes(Hub), "Back must return to the hub.")
	_check((current_scene.get_node(^"Feathers") as Label).text == "FEATHERS  5", "The hub must show the new balance.")

	# 4. Ranks apply once to a hub-launched run; banking keeps all on a win, half on a defeat.
	_save(0, {"health": 2, "might": 1, "speed": 3})
	Game.start_map(self, 0)
	_check(await _scene_becomes(Game), "A realm must open.")
	var game: Game = current_scene as Game
	var player: MountedPlayer = game.run.player
	_check(player.max_health == 120 and is_equal_approx(player.might, 1.05) and is_equal_approx(player.movement_speed, 290.0), "Shop ranks must apply once (health %d, might %.2f, speed %.0f)." % [player.max_health, player.might, player.movement_speed])
	await _ticks(5)
	game.run.feathers_earned = 25
	game.run.player.kill()
	# R right after dying must wait for the defeat to bank (the fall is not skippable).
	var key_r: InputEventKey = InputEventKey.new()
	key_r.physical_keycode = KEY_R
	key_r.pressed = true
	Input.parse_input_event(key_r)
	await _ticks(3)
	key_r = key_r.duplicate() as InputEventKey
	key_r.pressed = false
	Input.parse_input_event(key_r)
	_check(current_scene == game, "R during the fall must not restart before the defeat banks.")
	await _ticks(roundi(Run.FALL_TIME * 60.0) + 10)
	_check(Progress.load_saved().feathers == 12, "A defeat must bank half, rounded down (got %d)." % Progress.load_saved().feathers)
	_check(game.run.hud.end_label.text.contains("KEPT 12 OF 25 FEATHERS"), "The defeat card must say what was kept (%s)." % game.run.hud.end_label.text)
	Game.start_map(self, 1)
	_check(await _scene_becomes(Game), "Another realm must open.")
	game = current_scene as Game
	await _ticks(5)
	game.run.feathers_earned = 30
	Progress.path = "user://missing_folder/nested/shop.cfg"
	game.run._end_run(true)
	for tick: int in range(900):
		if game.run.hud.save_failed.visible:
			break
		await process_frame
	_check(game.run.hud.save_failed.visible, "A failed win save must be reported.")
	Progress.path = TEST_SAVE
	(game.run.hud.get_node(^"SaveFailed/Retry") as Button).pressed.emit()
	_check(await _scene_becomes(Hub, 1200), "A win must return to the hub.")
	_check(Progress.load_saved().feathers == 42, "A win must bank everything exactly once, even after a failed save (got %d)." % Progress.load_saved().feathers)
	# Unhosted runs (F6, tests) never take shop ranks.
	var bare: Run = RUN_SCENE.instantiate() as Run
	bare.intro_enabled = false
	root.add_child(bare)
	await _ticks(2)
	_check(bare.player.max_health == 100 and is_equal_approx(bare.player.might, 1.0), "An unhosted run must not take shop ranks.")
	bare.queue_free()

	current_scene.queue_free()
	await _ticks(15)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	if failures == 0:
		print("Shop smoke passed: feathers from kills, guards, shrines, gems, and the sin, HUD count, damaged saves clamped, unaffordable/maxed/unsaved purchases refused, purchases saved at once, shop rows, pips, prices, buying and back, ranks applied once to hub runs only, half kept on defeat, all on a win.")
	quit(1 if failures > 0 else 0)
