extends SceneTree
## Native Godot smoke check for the Turkish gameplay text: every run data string has a
## translation that keeps its format specifiers, and the HUD shows Turkish under the "tr"
## locale and English again under "en". No test framework required.

const RUN_SCENE: PackedScene = preload("res://scenes/run.tscn")
const GAMEPLAY_PO: String = "res://resources/gameplay.tr.po"

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


## Every English key the run shows from its data tables.
func _data_keys() -> PackedStringArray:
	var keys: PackedStringArray = []
	var choices: Array = [Run.PACT_LEAVE]
	choices.append_array(Run.UPGRADES)
	choices.append_array(Run.PACTS)
	for entry: Dictionary in choices:
		keys.append_array([entry["name"], entry["text"]])
	for entry: Dictionary in Run.ITEMS:
		keys.append_array([String(entry["name"]).trim_prefix("Item: "), entry["text"]])
	for paths: Array in Run.EVOLUTIONS:
		for entry: Dictionary in paths:
			keys.append_array([String(entry["name"]).to_upper(), entry["text"]])
	for entry: Dictionary in Run.TIERS:
		keys.append(entry["name"])
	for entry: Dictionary in Run.BOSSES:
		keys.append(entry["name"])
	for weapon_name: String in SideWeapons.NAMES:
		keys.append(weapon_name.to_upper())
	for entry: Dictionary in Progress.UPGRADES:
		keys.append_array([String(entry["name"]).to_upper(), entry["text"]])
	keys.append_array(["%s GUARD", "DECOY"])
	return keys


func _specifiers(text: String, pattern: RegEx) -> PackedStringArray:
	var found: PackedStringArray = []
	for match: RegExMatch in pattern.search_all(text):
		found.append(match.get_string())
	return found


func _run() -> void:
	var turkish: Translation = load(GAMEPLAY_PO) as Translation
	_check(turkish != null and turkish.locale == "tr", "The gameplay translation must load as Turkish.")
	if turkish == null:
		quit(1)
		return
	for key: String in _data_keys():
		_check(turkish.get_message(key) != &"", "Missing Turkish text for \"%s\"." % key)
	# Every key keeps its format specifiers, in order, so "%" formatting cannot break.
	var pattern: RegEx = RegEx.create_from_string("%[0-9.]*[sdf%]")
	for key: StringName in turkish.get_message_list():
		var english: PackedStringArray = _specifiers(key, pattern)
		var translated: PackedStringArray = _specifiers(turkish.get_message(key), pattern)
		_check(english == translated, "\"%s\" must keep its format specifiers %s (got %s)." % [key, english, translated])

	_check(ProjectSettings.get_setting("internationalization/locale/translations").has(GAMEPLAY_PO), "Gameplay translations must be registered on startup.")
	TranslationServer.set_locale("tr")
	root.size = Vector2i(1280, 720)
	var run: Run = RUN_SCENE.instantiate() as Run
	run.spawning_enabled = false
	run.intro_enabled = false
	root.add_child(run)
	current_scene = run
	await _wait_ticks(3)
	await process_frame
	var hud: Hud = run.hud
	_check(run.guards[0].display_name() == "KİBİR MUHAFIZI", "Guards must use the current locale.")
	_check(hud._stats_text().contains("BELLEK"), "The debug overlay must follow the gameplay language.")

	_check(hud.life_label.text == "CAN 100 / 100", "Life must read in Turkish (%s)." % hud.life_label.text)
	_check(hud.xp_label.text.begins_with("SEVİYE 1    DP"), "XP must read in Turkish (%s)." % hud.xp_label.text)
	_check(hud.stage_label.text == "KİBİR DİYARI", "The realm must read in Turkish (%s)." % hud.stage_label.text)
	_check(hud.difficulty_label.text.contains("KEFARET") and hud.difficulty_label.text.contains("TEHDİT 1"), "Tier and threat must read in Turkish (%s)." % hud.difficulty_label.text)
	_check(hud.stats_label.text.contains("SUNAK 0 / 5"), "The shrine count must read in Turkish (%s)." % hud.stats_label.text)
	_check(hud.boss_status_label.text.begins_with("ŞEYTAN'IN SUNAKLARINI YOK ET   5 KALDI"), "The shrine goal must read in Turkish (%s)." % hud.boss_status_label.text)
	_check(hud.dash_label.text == "ATILMA HAZIR" and hud.flight_label.text == "UÇUŞ HAZIR", "Abilities must read in Turkish (%s, %s)." % [hud.dash_label.text, hud.flight_label.text])
	_check(hud.weapon_label.text.begins_with("MIZRAK"), "The weapon gauge must read in Turkish (%s)." % hud.weapon_label.text)
	_check(hud.stats_label.get_minimum_size().x <= hud.stats_label.size.x, "The Turkish status line must fit its panel.")
	# Scene labels translate themselves; the pause button shows Turkish.
	var resume: Button = hud.get_node("PauseMenu/Box/Resume") as Button
	_check(resume.atr(resume.text) == "DEVAM ET", "Scene buttons must translate (%s)." % resume.atr(resume.text))

	# Announcements from the run are translated at display.
	hud.announce("HORDE SURGE", Hud.ALERT_TINT)
	_check(hud.relic_label.text == "SÜRÜ DALGASI", "Announcements must read in Turkish (%s)." % hud.relic_label.text)
	run.player.side_weapons.add(SideWeapons.Kind.HALOS)
	hud.announce_relic(SideWeapons.Kind.HALOS)
	await _wait_ticks(1)
	_check(hud.relic_label.text == "YENİ: YÖRÜNGE HALELERİ I", "Side-weapon finds must read in Turkish (%s)." % hud.relic_label.text)
	_check(hud.side_label.text == "YAN SİLAHLAR\nYÖRÜNGE HALELERİ I", "The side-weapon list must read in Turkish (%s)." % hud.side_label.text)

	# Level-up cards show the Turkish name and effect of each English data entry.
	run.add_xp(run.xp_needed() + 100)
	await _wait_ticks(1)
	_check(hud.level_up_heading.text.begins_with("SEVİYE ATLADIN - BİRİNİ SEÇ (+"), "The level-up heading must read in Turkish (%s)." % hud.level_up_heading.text)
	for index: int in range(hud.choice_buttons.size()):
		var option: Dictionary = run.level_up_options[index]
		_check(hud.choice_buttons[index].text == "%d   %s" % [index + 1, turkish.get_message(option["name"])], "Choice %d must show its Turkish name (%s)." % [index, hud.choice_buttons[index].text])
		_check(hud.choice_details[index].text == String(turkish.get_message(option["text"])), "Choice %d must show its Turkish effect." % index)
		_check(hud.choice_details[index].get_minimum_size().x <= hud.choice_details[index].size.x, "Choice %d Turkish effect must fit." % index)
	var pact_options: Array[Dictionary] = [Run.PACTS[2], Run.PACT_LEAVE]
	hud.show_level_up(pact_options, "SHRINE PACT - TAKE ONE OR LEAVE")
	await process_frame
	_check(hud.level_up_heading.text == "SUNAK ANTLAŞMASI - BİRİNİ AL YA DA AYRIL", "The pact heading must read in Turkish (%s)." % hud.level_up_heading.text)
	_check(hud.choice_buttons[1].text == "2   Ayrıl", "Leaving a pact must read in Turkish (%s)." % hud.choice_buttons[1].text)
	_check(hud.choice_details[0].get_minimum_size().x <= hud.choice_details[0].size.x, "The longest Turkish pact text must fit.")
	hud.show_evolution(MountedPlayer.Weapon.BOW, Run.EVOLUTIONS[MountedPlayer.Weapon.BOW])
	_check((hud.get_node(^"Evolution/Box/Heading") as Label).text == "YAY EVRİMİ", "The evolution heading must read in Turkish.")
	_check((hud.evolution_cards[1].get_node(^"Text/Title") as Label).text == "2   IŞIK YAĞMURU", "Evolution paths must read in Turkish.")
	hud.hide_evolution()
	hud.hide_level_up()

	# End states.
	hud.show_end(false)
	_check(hud.end_label.text.begins_with("DÜŞTÜN"), "A defeat must read in Turkish (%s)." % hud.end_label.text)
	hud.show_feathers(5, 10, true)
	_check(hud.end_label.text.ends_with("5 / 10 TÜY KORUNDU"), "Kept feathers must read in Turkish (%s)." % hud.end_label.text)
	hud.show_end(true)
	_check(hud.end_label.text.begins_with("KİBİR DİYARI KURTARILDI"), "A win must read in Turkish (%s)." % hud.end_label.text)
	hud.end_label.hide()

	# Back to English: the next refresh reads English again.
	TranslationServer.set_locale("en")
	await _wait_ticks(1)
	_check(run.guards[0].display_name() == "PRIDE GUARD", "An existing guard must switch back to English.")
	_check(hud.life_label.text == "LIFE 100 / 100" and hud.stage_label.text == "REALM OF PRIDE", "English must return with the locale (%s, %s)." % [hud.life_label.text, hud.stage_label.text])

	paused = false
	run.queue_free()
	await _wait_ticks(15)
	if failures == 0:
		print("Localization smoke passed.")
	quit(failures)
