class_name Progress
extends RefCounted
## Saved campaign progress: which sins are sealed (their relics stand on the hub's pedestals)
## and whether Satan has fallen. A ConfigFile in user://; a missing or damaged file is a fresh
## start, and unknown values are ignored rather than trusted.

## Tests point this at their own file so they never touch the player's save.
static var path: String = "user://progress.cfg"

var sealed: Array[int] = []
var satan_defeated: bool = false


static func load_saved() -> Progress:
	var progress: Progress = Progress.new()
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return progress
	var stored: Variant = file.get_value("progress", "sealed", [])
	if stored is Array:
		for value: Variant in stored:
			if value is int and value >= 0 and value < Run.SATAN and not progress.sealed.has(value):
				progress.sealed.append(value)
	progress.sealed.sort()
	progress.satan_defeated = file.get_value("progress", "satan_defeated", false) is bool and file.get_value("progress", "satan_defeated", false)
	return progress


## Writes the file; returns the error so callers never claim a save that failed.
func save() -> Error:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("progress", "version", 1)
	file.set_value("progress", "sealed", sealed)
	file.set_value("progress", "satan_defeated", satan_defeated)
	return file.save(path)


## A won map: a sin's relic is sealed, or Satan falls. Winning again changes nothing.
func record_win(map: int) -> void:
	if map == Run.SATAN:
		satan_defeated = true
	elif map >= 0 and map < Run.SATAN and not sealed.has(map):
		sealed.append(map)
		sealed.sort()


## All seven relics are on their pedestals.
func satan_unlocked() -> bool:
	return sealed.size() == Run.SATAN
