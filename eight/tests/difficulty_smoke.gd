extends SceneTree
## Difficulty tiers and the boss foundation: version-1 saves migrate, beating a tier opens the
## next for that sin, Satan offers the lowest tier beaten across the seven, tiers scale the horde,
## bosses and guards (never the countdown) and multiply feathers; every boss attack winds up
## before it lands and is followed by a recovery, bosses wait while the angel is off screen, and
## each health threshold speeds them up. The hub's tier picker enters a map on the chosen tier.
## Uses its own save file; native Godot only.

const TEST_SAVE: String = "user://test_difficulty.cfg"

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


func _scene_becomes(script: Script, limit: int = 600) -> bool:
	for tick: int in range(limit):
		if current_scene != null and current_scene.get_script() == script and current_scene.is_node_ready():
			return true
		await process_frame
	return false


func _new_run(tier: int) -> Run:
	var run: Run = load("res://scenes/run.tscn").instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	run.tier = tier
	root.add_child(run)
	current_scene = run
	return run


func _shots() -> int:
	return get_nodes_in_group(&"enemy_projectiles").size()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	Progress.path = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))

	# 1. Saves: a version-1 file (no tiers) migrates its wins to the first tier.
	var file: ConfigFile = ConfigFile.new()
	file.set_value("progress", "version", 1)
	file.set_value("progress", "sealed", [0, 2])
	file.set_value("progress", "satan_defeated", true)
	file.save(TEST_SAVE)
	var progress: Progress = Progress.load_saved()
	_check(progress.best == {0: 0, 2: 0, Run.SATAN: 0}, "Version-1 wins must migrate to the first tier (got %s)." % progress.best)
	_check(progress.max_tier(0) == 1 and progress.max_tier(1) == 0, "Beating a sin must open its next tier only (%d, %d)." % [progress.max_tier(0), progress.max_tier(1)])
	progress.record_win(0, 2)
	progress.record_win(0, 1)
	_check(progress.best[0] == 2 and progress.max_tier(0) == 3, "An easier win must not lower the best tier.")
	progress.record_win(0, 3)
	_check(progress.max_tier(0) == Run.TIERS.size() - 1, "The hardest tier is the last one offered.")
	_check(progress.save() == OK, "The save must write.")
	var loaded: Progress = Progress.load_saved()
	_check(loaded.best == progress.best and loaded.sealed == [0, 2], "Tiers must round-trip (got %s)." % loaded.best)
	# Damaged tier values are ignored.
	file = ConfigFile.new()
	file.load(TEST_SAVE)
	file.set_value("best", "1", 99)
	file.set_value("best", "3", "abyss")
	file.save(TEST_SAVE)
	loaded = Progress.load_saved()
	_check(not loaded.best.has(1) and not loaded.best.has(3), "Invalid tiers must be ignored (got %s)." % loaded.best)
	# A tier for a map the save never won is not trusted; a damaged tier on a won map is the first.
	file.set_value("best", "4", 3)
	file.set_value("best", "7", 2)
	file.set_value("best", "2", 99)
	file.set_value("progress", "satan_defeated", false)
	file.save(TEST_SAVE)
	loaded = Progress.load_saved()
	_check(not loaded.best.has(4) and not loaded.best.has(Run.SATAN) and loaded.best.get(2, -1) == 0, "Only won maps keep a tier (got %s)." % loaded.best)
	# Satan offers the lowest tier beaten across all seven.
	var seven: Progress = Progress.new()
	for sin: int in range(Run.SATAN):
		seven.record_win(sin, 2)
	seven.record_win(4, 3)
	_check(seven.satan_unlocked() and seven.max_tier(Run.SATAN) == 2, "Satan must offer the lowest tier beaten across the seven (got %d)." % seven.max_tier(Run.SATAN))
	seven.best[6] = 0
	_check(seven.max_tier(Run.SATAN) == 0, "One sin beaten only on the first tier keeps Satan there.")

	# 2. Tiers scale the horde, bosses, and guards, and feathers, never the countdown.
	var easy: Run = _new_run(0)
	await _ticks(2)
	easy.set_physics_process(false)
	var easy_guard: Boss = easy.guards[0]
	var easy_interval: float = easy.spawn_interval()
	var easy_batch: int = easy.spawn_batch()
	var easy_brute: Enemy = easy.spawn_enemy(2, Vector2(1500, 1500))
	var easy_time: float = easy.shrine_time
	var easy_left: float = easy.shrine_time_left
	var easy_stats: Array = [easy_guard.max_health, easy_guard.contact_damage, easy_guard.attack_interval, easy_guard.patterns.size(), easy_brute.max_health, easy_brute.contact_damage, easy_guard.shot_damage]
	easy.queue_free()
	await _ticks(2)
	var hard: Run = _new_run(3)
	await _ticks(2)
	hard.set_physics_process(false)
	var guard: Boss = hard.guards[0]
	var brute: Enemy = hard.spawn_enemy(2, Vector2(1500, 1500))
	_check(guard.max_health > easy_stats[0] and guard.contact_damage > easy_stats[1] and guard.attack_interval < easy_stats[2], "Abyss guards must be tougher and faster (%s vs %s)." % [[guard.max_health, guard.contact_damage, guard.attack_interval], easy_stats])
	_check(guard.patterns.size() > easy_stats[3] and not guard.patterns.has(Boss.Pattern.SUMMON) and guard.smarts == 3, "Abyss guards must gain attack patterns, never a summon (%s)." % [guard.patterns])
	_check(brute.max_health > easy_stats[4] and brute.contact_damage > easy_stats[5], "Abyss must scale the horde.")
	_check(easy_stats[6] == 12 and guard.shot_damage > easy_stats[6], "Abyss boss shots must hit harder (%d vs %d)." % [guard.shot_damage, easy_stats[6]])
	guard._fire(Vector2.RIGHT)
	var fired: EnemyProjectile = get_nodes_in_group(&"enemy_projectiles")[0] as EnemyProjectile
	_check(fired.damage == guard.shot_damage, "A boss shot must carry the boss's shot damage.")
	fired.queue_free()
	_check(hard.spawn_interval() < easy_interval and hard.spawn_batch() > easy_batch, "Abyss must spawn faster and in bigger waves.")
	_check(hard.shrine_time == easy_time and absf(hard.shrine_time_left - easy_left) < 0.2, "The countdown must never change with the tier.")
	hard.feathers_earned = 11
	_check(hard.feathers_total() == 33, "Abyss must triple feathers (got %d)." % hard.feathers_total())
	hard.hud._process(0.0)
	_check(hard.hud.difficulty_label.text.contains("ABYSS"), "The HUD must show the tier (%s)." % hard.hud.difficulty_label.text)
	hard.queue_free()
	await _ticks(2)

	# 3. Boss foundation: wind-up, then the attack, then a recovery.
	var run: Run = _new_run(0)
	await _ticks(3)
	var player: MountedPlayer = run.player
	player.invulnerable_left = 100000.0
	for each: Boss in run.guards.duplicate():
		each.queue_free()
	await _ticks(1)
	var boss: Boss = run._make_boss()
	boss.speed = 0.0
	boss.attack_left = 999.0
	run.actors.add_child(boss)
	boss.global_position = Vector2(-1800.0, 1600.0)
	player.global_position = boss.global_position + Vector2(300.0, 0.0)
	await _ticks(2)
	boss.attack_left = 0.0
	boss.patterns.assign([Boss.Pattern.BURST])
	await _ticks(2)
	_check(boss.windup_left > 0.0 and boss.pending == Boss.Pattern.BURST and _shots() == 0, "A burst must wind up before any shot is fired.")
	_check(boss.is_in_group(&"light"), "A wind-up must light its telegraph.")
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.BURST] * 60.0) + 2)
	_check(_shots() == Boss.BURST_SHOTS and boss.recover_left > 0.0 and not boss.is_in_group(&"light"), "The burst must land after its wind-up, then the boss recovers (shots %d)." % _shots())
	boss.speed = 200.0
	var resting: Vector2 = boss.global_position
	await _ticks(10)
	_check(boss.global_position.distance_to(resting) < 0.5, "A recovering boss must stand still.")
	for shot: Node in get_nodes_in_group(&"enemy_projectiles"):
		shot.queue_free()
	boss.speed = 0.0
	await _ticks(int(Boss.RECOVERIES[Boss.Pattern.BURST] * 60.0))
	# Off screen, the boss waits instead of attacking.
	player.global_position = boss.global_position + Vector2(900.0, 0.0)
	boss.attack_left = 0.0
	await _ticks(5)
	_check(boss.windup_left == 0.0 and boss.attack_left == 0.0, "A boss must not start attacks while the angel is off screen.")
	player.global_position = boss.global_position + Vector2(300.0, 0.0)
	await _ticks(3)
	_check(boss.windup_left > 0.0, "Back on screen, the boss attacks.")
	boss._cancel()
	# Each health threshold starts a faster phase, once.
	boss.attack_left = 999.0
	var calm: float = boss.attack_interval
	boss.take_hit(boss.max_health / 2 + 1)
	boss.take_hit(1)
	_check(boss.phase == 2 and is_equal_approx(boss.attack_interval, calm * Boss.PHASE_PACE) and boss.attack_left <= boss.attack_interval, "Half health must start a faster phase, once (phase %d, interval %f)." % [boss.phase, boss.attack_interval])
	# Smarter bosses aim where the angel is heading.
	player.velocity = Vector2(0.0, 300.0)
	boss.smarts = 0
	var plain: Vector2 = boss._aim(Boss.Pattern.AIMED)
	boss.smarts = Boss.LEAD_SMARTS
	var lead: Vector2 = boss._aim(Boss.Pattern.AIMED)
	_check(absf(plain.y) < 0.01 and lead.y > 0.3, "Smarter bosses must lead their aimed fans (%s vs %s)." % [plain, lead])
	_check(absf(boss._aim(Boss.Pattern.CHARGE).y) < 0.01, "A charge must not lead (its speed is not a shot's).")
	player.velocity = Vector2.ZERO
	# A charge lane stops at the first obstacle: aim one straight into the arena's left wall.
	boss.global_position = Vector2(Run.ARENA_RECT.position.x + 140.0, 0.0)
	player.global_position = boss.global_position + Vector2(-100.0, 0.0)
	await _ticks(2)
	boss.start_attack(Boss.Pattern.CHARGE)
	_check(boss.charge_length < 140.0 and boss.charge_length < boss.charge_speed() * Boss.CHARGE_TIME, "A charge lane must stop at a wall (length %f)." % boss.charge_length)
	boss._cancel()
	# After a charge the boss rests longer than after a shot.
	_check(Boss.RECOVERIES[Boss.Pattern.CHARGE] > Boss.RECOVERIES[Boss.Pattern.BURST], "A charge must leave a longer punish window.")
	run.queue_free()
	await _ticks(2)

	# Summon marks show exactly where the minions appear.
	run = _new_run(0)
	await _ticks(3)
	player = run.player
	player.invulnerable_left = 100000.0
	for each: Boss in run.guards.duplicate():
		each.queue_free()
	for child: Node in run.obstacles.get_children():
		var shrine: Breakable = child as Breakable
		if shrine != null and shrine.kind == Breakable.Kind.SHRINE:
			shrine.take_blow(1000)
			shrine.take_blow(1000)
	await _ticks(3)
	var sin: Boss = run.current_boss
	sin.speed = 0.0
	sin.attack_left = 999.0
	# Hard against a wall, so some marks must move to open ground.
	sin.global_position = Vector2(Run.ARENA_RECT.position.x + sin.radius + 4.0, 0.0)
	player.global_position = sin.global_position + Vector2(250.0, 0.0)
	await _ticks(2)
	sin.start_attack(Boss.Pattern.SUMMON)
	var marks: Array[Vector2] = []
	for offset: Vector2 in sin.summon_offsets():
		marks.append(sin.global_position + offset)
	var exact: bool = sin.summon_spots.size() == Boss.SUMMON_COUNT
	for index: int in range(mini(marks.size(), sin.summon_spots.size())):
		exact = exact and marks[index].distance_to(sin.summon_spots[index]) < 0.01
	# The mark behind the boss (index 2, toward the wall) had to move to open ground.
	var walled: Vector2 = sin.global_position + Vector2.RIGHT.rotated(PI) * (sin.radius + 30.0)
	_check(exact and marks[2].distance_to(walled) > 1.0, "A summon must plan its spots when the wind-up starts (%s)." % [sin.summon_spots])
	var horde: int = run.enemy_count
	await _ticks(int(Boss.WINDUPS[Boss.Pattern.SUMMON] * 60.0) + 2)
	var appeared: int = 0
	for actor: Node in run.actors.get_children():
		if actor is Enemy and not actor is Boss:
			for mark: Vector2 in marks:
				if (actor as Enemy).global_position.distance_to(mark) < 12.0:
					appeared += 1
					break
	_check(run.enemy_count == horde + Boss.SUMMON_COUNT and appeared == Boss.SUMMON_COUNT, "Minions must appear on their marks (%d of %d)." % [appeared, Boss.SUMMON_COUNT])
	run.queue_free()
	await _ticks(2)

	# A guard keeps its punish window even when the angel leaves its leash.
	run = _new_run(0)
	await _ticks(3)
	player = run.player
	player.invulnerable_left = 100000.0
	var keeper: Boss = run.guards[0]
	keeper.speed = 120.0
	keeper.attack_left = 999.0
	player.global_position = keeper.home + Vector2(0.0, 200.0)
	await _ticks(2)
	keeper.recover_left = 0.5
	player.global_position = Vector2.ZERO
	var held: Vector2 = keeper.global_position
	await _ticks(10)
	_check(keeper.global_position.distance_to(held) < 0.5, "A recovering guard must not walk home early.")
	run.queue_free()
	await _ticks(2)

	# 4. The hub's tier picker: hidden with one open tier, then enters on the chosen tier.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	change_scene_to_file(Game.HUB_SCENE)
	_check(await _scene_becomes(Hub), "The hub must open.")
	var hub: Hub = current_scene as Hub
	await _ticks(2)
	_check(not (hub.tier_arrows[0][0] as Button).visible, "A fresh sin must show no picker.")
	_check(hub.sin_buttons[0].text.contains("PENANCE") and hub.sin_buttons[0].text.contains("ENTER"), "A fresh sin shows its tier (%s)." % hub.sin_buttons[0].text)
	hub.progress.record_win(0, 0)
	hub._refresh()
	await _ticks(1)
	var down: Button = hub.tier_arrows[0][0]
	var up: Button = hub.tier_arrows[0][1]
	_check(down.visible and hub.tier_for(0) == 1 and up.disabled and not down.disabled, "A beaten sin must offer its next tier first.")
	_check(hub.sin_buttons[0].text.contains("PURGATORY") and hub.sin_buttons[0].text.contains("BEST PENANCE"), "The node shows the chosen tier and its best (%s)." % hub.sin_buttons[0].text)
	_check(up.size.x <= Hub.ARROW_SIZE.x, "Tier arrows must keep their narrow width (%s)." % up.size)
	var all: Array[Control] = []
	for index: int in range(Run.SATAN):
		all.append(hub.sin_buttons[index])
		all.append(hub.tier_arrows[index][0])
		all.append(hub.tier_arrows[index][1])
	all.append(hub.satan_button)
	for index: int in range(all.size()):
		for other: int in range(index + 1, all.size()):
			_check(not all[index].get_global_rect().intersects(all[other].get_global_rect()), "%s and %s must not overlap." % [all[index].name, all[other].name])
	down.pressed.emit()
	_check(hub.tier_for(0) == 0 and down.disabled, "The picker must step down to Penance.")
	# Shift with the node's key cycles its tier from the keyboard, wrapping.
	for expected: int in [1, 0, 1]:
		var shifted: InputEventKey = InputEventKey.new()
		shifted.physical_keycode = KEY_1
		shifted.shift_pressed = true
		shifted.pressed = true
		Input.parse_input_event(shifted)
		await _ticks(1)
		shifted = shifted.duplicate()
		shifted.pressed = false
		Input.parse_input_event(shifted)
		await _ticks(1)
		_check(current_scene == hub and hub.tier_for(0) == expected, "Shift+1 must cycle Pride's tier (got %d)." % hub.tier_for(0))
	hub.step_tier(0, -1)
	up.pressed.emit()
	hub.sin_buttons[0].pressed.emit()
	_check(await _scene_becomes(Game), "The sin must open.")
	_check((current_scene as Game).run.tier == 1 and (current_scene as Game).run.guards[0].smarts == 1, "The map must run on the chosen tier.")
	Hub.picked.clear()

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("difficulty_smoke: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
