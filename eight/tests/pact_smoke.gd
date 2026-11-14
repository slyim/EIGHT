extends SceneTree
## Native Godot smoke check for shrine pacts: a broken shrine pauses with two untaken pacts and
## a way to leave; each pact's trade-off; leaving changes nothing; the last pact offered alone;
## a level-up waiting its turn behind a pact; and no offer past three pacts.

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


func _shrines(run: Run) -> Array[Breakable]:
	var found: Array[Breakable] = []
	for child: Node in run.obstacles.get_children():
		var obstacle: Breakable = child as Breakable
		if obstacle != null and obstacle.kind == Breakable.Kind.SHRINE:
			found.append(obstacle)
	return found


## The offered card index for a pact id, or -1.
func _card(run: Run, id: String) -> int:
	for index: int in range(run.level_up_options.size()):
		if run.level_up_options[index].get("id", "?") == id:
			return index
	return -1


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	var player: MountedPlayer = run.player
	player.invulnerable_left = 100000.0
	var shrines: Array[Breakable] = _shrines(run)

	# 1. A broken shrine pauses with two different untaken pacts and a way to leave.
	shrines[0].take_blow(1000)
	await _wait_ticks(2)
	var options: Array[Dictionary] = run.level_up_options
	_check(paused and options.size() == 3 and options[2]["id"] == "" and options[0]["id"] != options[1]["id"] and options[0]["id"] != "" and options[1]["id"] != "", "A broken shrine must offer two pacts and a way to leave (%s)." % [options])
	_check(run.hud.level_up_panel.visible and run.hud.level_up_heading.text.begins_with("SHRINE PACT") and run.hud.choice_buttons[2].visible, "The pact offer must show on the choice panel with its own heading.")
	# A level-up earned now waits its turn behind the pact.
	run.add_xp(run.xp_needed())
	_check(run.pending_level_ups == 1 and run.level_up_options[2]["id"] == "", "A level-up must wait behind an open pact offer.")
	# Glass Light (taken whichever slot it is in; re-roll the offer until it shows).
	while _card(run, "glass_light") < 0:
		run._offer_pact()
	var might: float = player.might
	player.health = player.max_health
	run.choose_upgrade(_card(run, "glass_light"))
	_check(run.pacts == ["glass_light"] and is_equal_approx(player.might, might + Run.GLASS_MIGHT) and player.max_health == 75 and player.health == 75, "Glass Light must add damage and cut max health (%.2f, %d / %d)." % [player.might, player.health, player.max_health])
	_check(paused and run.pending_level_ups == 1 and not run.level_up_options[0].has("id") and not run.hud.level_up_heading.text.begins_with("SHRINE PACT"), "The waiting level-up must follow the pact.")
	run.choose_upgrade(0)
	_check(not paused and run.level_up_options.is_empty(), "With nothing left to choose, play must resume.")

	# 2. Leaving changes nothing; Glass Light is never offered again.
	shrines[1].take_blow(1000)
	await _wait_ticks(2)
	_check(_card(run, "glass_light") < 0 and run.level_up_options.size() == 3, "A taken pact must not be offered again.")
	var feathers_before: float = run.pact_feathers
	run.choose_upgrade(2)
	_check(run.pacts.size() == 1 and run.pact_feathers == feathers_before and not paused, "Leaving must take no pact.")

	# 3. Golden Tithe: more feathers, fewer hearts.
	shrines[2].take_blow(1000)
	await _wait_ticks(2)
	var hearts: float = run.heart_drop_chance
	run.feathers_earned = 100
	run.choose_upgrade(_card(run, "golden_tithe"))
	_check(run.feathers_total() == 150 and is_equal_approx(run.heart_drop_chance, hearts * Run.TITHE_HEARTS), "Golden Tithe must pay more feathers and halve hearts (%d)." % run.feathers_total())

	# 4. The last pact is offered alone, with leave; Swift Blood quickens the angel, and enemies,
	# standing and new, hit harder.
	var standing: Enemy = run.spawn_enemy(Run.HUSK, player.global_position + Vector2(600.0, 0.0))
	var before_damage: int = standing.contact_damage
	shrines[3].take_blow(1000)
	await _wait_ticks(2)
	_check(run.level_up_options.size() == 2 and run.level_up_options[0]["id"] == "swift_blood" and not run.hud.choice_buttons[2].visible and (run.hud.get_node(^"LevelUp/Box/Hint") as Label).text.ends_with("1-2"), "The last pact must be offered alone, with leave (%s)." % [run.level_up_options])
	var haste: float = player.haste
	var dash: float = player.dash_cooldown
	run.choose_upgrade(0)
	var fresh: Enemy = run.spawn_enemy(Run.HUSK, player.global_position + Vector2(-600.0, 0.0))
	_check(is_equal_approx(player.haste, haste * Run.SWIFT_COOLDOWN) and is_equal_approx(player.dash_cooldown, dash * Run.SWIFT_COOLDOWN), "Swift Blood must quicken attacks, side weapons and dash.")
	_check(standing.contact_damage == roundi(before_damage * Run.SWIFT_ENEMY_DAMAGE) and fresh.contact_damage == standing.contact_damage, "Swift Blood must make standing and new enemies hit harder (%d, %d)." % [standing.contact_damage, fresh.contact_damage])

	# 5. Three pacts taken: the last shrine offers nothing (and summons the sin as ever).
	shrines[4].take_blow(1000)
	await _wait_ticks(2)
	_check(not paused and run.level_up_options.is_empty() and run.pending_pacts == 0 and run.current_boss != null, "No pact may be offered past three.")
	run.add_xp(run.xp_needed())
	await _wait_ticks(1)
	_check(run.hud.choice_buttons[2].visible and run.level_up_options.size() == 3, "A level-up after a lone pact must show all three cards.")
	run.choose_upgrade(0)
	run.queue_free()
	await _wait_ticks(2)

	# 6. Two shrines broken behind one offer: leaving the first still leaves the second's offer.
	run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	run.player.invulnerable_left = 100000.0
	shrines = _shrines(run)
	for index: int in range(2):
		run._take_pact(Run.PACTS[index]["id"])
	shrines[0].take_blow(1000)
	shrines[1].take_blow(1000)
	shrines[2].take_blow(1000)
	await _wait_ticks(2)
	_check(run.pending_pacts == 3, "Each broken shrine must queue its own offer (%d)." % run.pending_pacts)
	run.choose_upgrade(run.level_up_options.size() - 1)
	_check(paused and run.level_up_options.size() == 2 and run.level_up_options[0]["id"] == Run.PACTS[2]["id"], "Leaving one offer must still leave the next shrine's (%s)." % [run.level_up_options])
	run.choose_upgrade(0)
	_check(not paused and run.pacts.size() == 3 and run.pending_pacts == 0 and run.level_up_options.is_empty(), "The last pact taken, the third shrine's offer must lapse (%s)." % [run.level_up_options])
	# 7. A defeat with a pact offer open still reaches its end card.
	run.pacts.clear()
	shrines[3].take_blow(1000)
	await _wait_ticks(2)
	_check(paused and not run.level_up_options.is_empty(), "A pact offer must be open before the defeat.")
	run.player.invulnerable_left = 0.0
	run.player.kill()
	await _wait_ticks(roundi(Run.FALL_TIME * 60.0) + 60)
	_check(run.ended and run.ending_done and not paused and run.level_up_options.is_empty() and run.pending_pacts == 0 and not run.hud.level_up_panel.visible, "A defeat during a choice must clear it and reach the end card.")

	run.queue_free()
	await _wait_ticks(30) # Let freed nodes and sounds finish before quitting.
	if failures == 0:
		print("pact_smoke: PASS")
	quit(1 if failures > 0 else 0)
