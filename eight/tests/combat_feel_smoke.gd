extends SceneTree
## Combat feel: hits push along their direction and by the enemy's weight, unpushable bosses
## shudder, every hit throws sparks and reports a damage number (finishers and evolved strikes
## as heavy), the bow finisher hits harder and pierces further, shake and hit-stop follow the
## settings, being hurt flashes and shakes, a dash leaves afterimages, and a perfect dodge (a
## hit early in a dash) misses, refunds the dash, and quickens attacks once per buff.
## Native Godot only.

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


func _settle() -> void:
	while Engine.time_scale < 1.0:
		await process_frame


func _still(run: Run, type_index: int, at: Vector2) -> Enemy:
	var enemy: Enemy = run.spawn_enemy(type_index, at)
	enemy.speed = 0.0
	enemy.max_health = 1000
	enemy.health = 1000
	return enemy


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var run: Run = load("res://scenes/run.tscn").instantiate() as Run
	run.intro_enabled = false
	run.spawning_enabled = false
	root.add_child(run)
	current_scene = run
	await _ticks(3)
	var player: MountedPlayer = run.player
	player.invulnerable_left = 100000.0
	for guard: Boss in run.guards.duplicate():
		guard.queue_free()
	var reports: Array[Array] = []
	run.enemy_damaged.connect(func(at: Vector2, amount: int, heavy: bool, key: int) -> void: reports.append([at, amount, heavy, key]))

	# 1. Pushes follow the blow and the enemy's weight; every hit sparks and is reported.
	player.global_position = Vector2(-1800.0, 1600.0)
	var imp: Enemy = _still(run, 1, player.global_position + Vector2(0.0, -200.0))
	var brute: Enemy = _still(run, 2, player.global_position + Vector2(300.0, -200.0))
	await _ticks(1)
	imp.take_hit(1, false, imp.global_position + Vector2(-20.0, 0.0))
	brute.take_hit(1, false, brute.global_position + Vector2(-20.0, 0.0))
	_check(imp.knockback.x > 0.0 and absf(imp.knockback.y) < 0.01, "A blow from the left must push right, not away from the angel (%s)." % imp.knockback)
	_check(imp.knockback.length() > brute.knockback.length() * 2.0, "A light imp must fly further than a heavy brute (%s vs %s)." % [imp.knockback, brute.knockback])
	_check(reports.size() == 2 and reports[0][1] == 1 and not reports[0][2] and reports[0][3] == imp.get_instance_id(), "Each hit must be reported once, with its amount and enemy (%s)." % [reports])
	_check(run.sparks.sparks.size() >= 6, "Each hit must throw sparks (%d)." % run.sparks.sparks.size())
	imp.take_hit(2)
	_check(imp.knockback.y < 0.0 and absf(imp.knockback.x) < 0.01, "By default the push is away from the angel (%s)." % imp.knockback)
	await _ticks(10)
	_check(run.sparks.sparks.is_empty(), "Sparks must fade quickly.")

	# 2. Bosses cannot be pushed; they shudder a pixel while flashing.
	var boss: Boss = run._make_boss()
	boss.speed = 0.0
	boss.attack_left = 999.0
	run.actors.add_child(boss)
	boss.global_position = player.global_position + Vector2(-300.0, -200.0)
	await _ticks(1)
	var shuddered: bool = false
	boss.take_hit(1)
	for tick: int in range(4):
		await _ticks(1)
		shuddered = shuddered or boss.sprite.offset != Vector2.ZERO
	await _ticks(6)
	_check(boss.knockback.is_zero_approx() and shuddered and boss.sprite.offset == Vector2.ZERO, "A boss must shudder in place, then settle.")
	boss.queue_free()

	# 3. The spear finisher reports heavy hits.
	var husk: Enemy = _still(run, 0, player.global_position + Vector2(0.0, -70.0))
	await _ticks(1)
	reports.clear()
	player.aim_direction = Vector2.UP
	player.thrust_direction = Vector2.UP
	player._resolve_finisher()
	_check(reports.any(func(report: Array) -> bool: return report[3] == husk.get_instance_id()) and reports.all(func(report: Array) -> bool: return report[2]), "Finisher hits must be heavy (%s)." % [reports])
	await _settle()

	# 4. The bow finisher: more damage, one more pierce, heavy; its first hit shakes.
	player.weapon = MountedPlayer.Weapon.BOW
	player.might = 1.0
	var shot: Arrow = player.fire_arrow(0)
	var finisher: Arrow = player.fire_arrow(MountedPlayer.COMBO_LENGTH - 1)
	_check(not shot.heavy and finisher.heavy and finisher.pierce == shot.pierce + MountedPlayer.BOW_FINISHER_PIERCE and finisher.damage > shot.damage, "The bow finisher must be heavier (%d/%d vs %d/%d)." % [finisher.damage, finisher.pierce, shot.damage, shot.pierce])
	shot.queue_free()
	finisher.queue_free()
	await _ticks(1)

	# 5. The shake setting scales shakes; hit-stop can be switched off.
	player.shake_left = 0.0
	player.shake_strength = 0.0
	player.shake_scale = 0.0
	player._shake(10.0)
	_check(player.shake_strength == 0.0, "Shake at 0% must not shake.")
	player.shake_scale = 0.5
	player._shake(10.0)
	_check(is_equal_approx(player.shake_strength, 5.0), "Shake at 50%% must halve it (%f)." % player.shake_strength)
	player.shake_scale = 1.0
	player.hit_stop_enabled = false
	player._hit_stop(0.2)
	_check(is_equal_approx(Engine.time_scale, 1.0), "Hit-stop off must never slow time.")
	player.hit_stop_enabled = true

	# 6. Being hurt flashes the angel, shakes, and stops time briefly.
	player.invulnerable_left = 0.0
	player.shake_left = 0.0
	player.shake_strength = 0.0
	_check(player.take_damage(5), "The hit must land.")
	_check(player.hurt_flash_left > 0.0 and player.shake_strength > 0.0 and Engine.time_scale < 1.0, "Being hurt must flash, shake, and stop time.")
	await _ticks(1)
	_check(player.sprite.self_modulate == MountedPlayer.HURT_TINT, "The hurt flash must tint the angel.")
	await _settle()
	await _ticks(int(MountedPlayer.HURT_FLASH_TIME * 60.0) + 2)
	_check(player.sprite.self_modulate == Color.WHITE, "The hurt flash must clear.")

	# 7. A dash leaves afterimages; a hit early in it is a perfect dodge.
	player.invulnerable_left = 0.0
	player.dash_cooldown_left = 0.0
	var dodged: Array[int] = [0]
	player.perfect_dodged.connect(func() -> void: dodged[0] += 1)
	var nodes_before: int = run.get_child_count()
	Input.action_press(&"dash")
	await _ticks(1)
	Input.action_release(&"dash")
	_check(player.dash_time_left > 0.0, "The dash must start.")
	var health: int = player.health
	_check(not player.take_damage(20), "A hit early in a dash must miss.")
	_check(dodged[0] == 1 and player.perfect_left > 0.0 and player.dash_cooldown_left <= player.dash_time_left + 0.001 and player.health == health, "An early hit must be a perfect dodge with a refunded dash (cooldown %f)." % player.dash_cooldown_left)
	player.take_damage(20)
	_check(dodged[0] == 1, "One perfect dodge per dash.")
	await _ticks(3)
	var ghosts: int = 0
	for child: Node in run.get_children():
		if child is Sprite2D:
			ghosts += 1
	_check(ghosts >= 1 and run.get_child_count() > nodes_before, "A dash must leave afterimages (%d)." % ghosts)
	_check(is_equal_approx(player.attack_haste(), player.haste * MountedPlayer.PERFECT_HASTE), "A perfect dodge must quicken attacks.")
	# The refund: dash again right after.
	await _ticks(int(player.dash_duration * 60.0) + 1)
	Input.action_press(&"dash")
	await _ticks(1)
	Input.action_release(&"dash")
	_check(player.dash_time_left > 0.0, "The refunded dash must be ready at once.")
	_check(not player.take_damage(20) and dodged[0] == 1, "No second perfect dodge while the buff runs.")
	# A late hit in a fresh dash, after the buff, is a plain dash block.
	player.perfect_left = 0.0
	await _ticks(int(player.dash_duration * 60.0) + 1)
	player.dash_cooldown_left = 0.0
	Input.action_press(&"dash")
	await _ticks(1)
	Input.action_release(&"dash")
	await _ticks(int(MountedPlayer.PERFECT_WINDOW * 60.0) + 1)
	if player.dash_time_left > 0.0:
		player.take_damage(20)
		_check(dodged[0] == 1, "A hit late in a dash must not be perfect.")
	else:
		_check(false, "The late-hit dash ended too early to test.")
	await _ticks(int(MountedPlayer.PERFECT_BUFF_TIME * 60.0) + 10)
	_check(player.perfect_left == 0.0 and is_equal_approx(player.attack_haste(), player.haste), "The buff must expire back to plain haste.")

	# 8. Only hits that would have landed can be dodged perfectly.
	for case: String in ["airborne ground hit", "hurt-invulnerable hit"]:
		player.perfect_left = 0.0
		player.dash_cooldown_left = 0.0
		Input.action_press(&"dash")
		await _ticks(1)
		Input.action_release(&"dash")
		if case == "airborne ground hit":
			player.height = 40.0
			player.lift = 1.0
		else:
			player.invulnerable_left = 1.0
		player.take_damage(20)
		_check(dodged[0] == 1 and player.perfect_left == 0.0, "A %s must not be a perfect dodge." % case)
		player.height = 0.0
		player.lift = 0.0
		player.invulnerable_left = 0.0
		await _ticks(int(player.dash_duration * 60.0) + 1)
	# A hit from the air that would reach an airborne angel still counts.
	player.dash_cooldown_left = 0.0
	Input.action_press(&"dash")
	await _ticks(1)
	Input.action_release(&"dash")
	player.height = 40.0
	player.lift = 1.0
	_check(not player.take_damage(20, true) and dodged[0] == 2, "An air shot early in a dash must be a perfect dodge.")
	player.height = 0.0
	player.lift = 0.0

	# 9. The buff quickens side weapons too.
	player.side_weapons.add(SideWeapons.Kind.PULSE)
	player.side_weapons._pulse()
	var quick: float = player.side_weapons.waits[SideWeapons.Kind.PULSE]
	player.perfect_left = 0.0
	player.side_weapons._pulse()
	_check(quick < player.side_weapons.waits[SideWeapons.Kind.PULSE] * 0.75, "The perfect-dodge buff must quicken side weapons (%f vs %f)." % [quick, player.side_weapons.waits[SideWeapons.Kind.PULSE]])

	# 10. Switching shake or hit-stop off stops one already running.
	player._shake(10.0)
	player.shake_scale = 0.0
	_check(player.shake_left == 0.0, "Shake off must stop a running shake.")
	player.shake_scale = 1.0
	player._hit_stop(1.0)
	_check(Engine.time_scale < 1.0, "Hit-stop must slow time.")
	player.hit_stop_enabled = false
	_check(is_equal_approx(Engine.time_scale, 1.0), "Hit-stop off must restore time at once.")
	player.hit_stop_enabled = true

	# 11. Paused screens show no world feedback.
	player.health = 10
	player.health_changed.emit(player.health, player.max_health)
	run.enemy_damaged.emit(player.global_position, 3, false, 1)
	await _ticks(2)
	_check(run.hud.vignette.visible and run.hud.damage_numbers.visible, "Low life shows the edge, and hits their numbers.")
	run.hud.set_paused(true)
	await process_frame
	await process_frame
	_check(not run.hud.vignette.visible and not run.hud.damage_numbers.visible, "A paused screen must hide the edge and the numbers.")
	run.hud.set_paused(false)
	await _ticks(2)
	_check(run.hud.vignette.visible, "Resuming must bring the low-life edge back.")

	# The ascent clears a slow, so the tint does not ride up the beam.
	await _ticks(20)
	_check(player.apply_slow(0.5, 3.0) and player.slow_left > 0.0, "The angel must be slowed before the ascent.")
	player.begin_ascent(100.0, 1.0)
	_check(player.slow_left == 0.0 and is_equal_approx(player.slow_factor, 1.0), "The ascent must clear a slow.")
	await _settle()
	run.queue_free()
	await _ticks(30)
	print("combat_feel_smoke: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
