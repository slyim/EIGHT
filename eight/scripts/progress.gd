class_name Progress
extends RefCounted
## Saved campaign progress: which sins are sealed (their relics stand on the hub's pedestals),
## whether Satan has fallen, banked feathers, and the shop's permanent upgrade ranks. A
## ConfigFile in user://; a missing or damaged file is a fresh start, and unknown or invalid
## values are ignored or clamped rather than trusted.

## Tests point this at their own file so they never touch the player's save.
static var path: String = "user://progress.cfg"

## The shop's permanent upgrades: each rank adds `amount` to `stat` (see Run._apply_bonus) at
## the start of every hub-launched run; `costs` holds one price per rank. PLACEHOLDER names,
## values, and prices.
const UPGRADES: Array[Dictionary] = [
	{"id": "health", "name": "Vitality", "text": "+10 max health", "stat": "max_health", "amount": 10.0, "costs": [10, 25, 50, 90, 150]},
	{"id": "might", "name": "Might", "text": "+5% damage from every weapon", "stat": "might", "amount": 0.05, "costs": [15, 35, 70, 120, 200]},
	{"id": "armor", "name": "Armor", "text": "Enemy hits deal 1 less", "stat": "armor", "amount": 1.0, "costs": [20, 45, 90, 150, 240]},
	{"id": "haste", "name": "Haste", "text": "All cooldowns 4% shorter", "stat": "haste", "amount": 0.96, "costs": [15, 35, 70, 120, 200]},
	{"id": "luck", "name": "Luck", "text": "+10% drop chances", "stat": "luck", "amount": 0.1, "costs": [10, 25, 50, 90, 150]},
	{"id": "speed", "name": "Swiftness", "text": "+10 movement speed", "stat": "speed", "amount": 10.0, "costs": [10, 25, 50, 90, 150]},
	{"id": "pull", "name": "Pull", "text": "+15 pickup radius", "stat": "magnet", "amount": 15.0, "costs": [8, 20, 40, 70, 120]},
	{"id": "flight", "name": "Wings", "text": "+0.3 s of flight", "stat": "flight", "amount": 0.3, "costs": [10, 25, 50, 90, 150]},
]

var sealed: Array[int] = []
var satan_defeated: bool = false
var feathers: int = 0
## Upgrade id -> rank (0..its number of costs).
var ranks: Dictionary = {}


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
	var banked: Variant = file.get_value("progress", "feathers", 0)
	progress.feathers = maxi(0, banked) if banked is int else 0
	for upgrade: Dictionary in UPGRADES:
		var rank: Variant = file.get_value("upgrades", upgrade["id"], 0)
		if rank is int:
			progress.ranks[upgrade["id"]] = clampi(rank, 0, (upgrade["costs"] as Array).size())
	return progress


## Writes the file; returns the error so callers never claim a save that failed.
func save() -> Error:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("progress", "version", 1)
	file.set_value("progress", "sealed", sealed)
	file.set_value("progress", "satan_defeated", satan_defeated)
	file.set_value("progress", "feathers", feathers)
	for id: String in ranks:
		file.set_value("upgrades", id, ranks[id])
	return file.save(path)


static func upgrade(id: String) -> Dictionary:
	for entry: Dictionary in UPGRADES:
		if entry["id"] == id:
			return entry
	return {}


func rank(id: String) -> int:
	return int(ranks.get(id, 0))


## The price of the next rank, or -1 once maxed (or unknown).
func next_cost(id: String) -> int:
	var costs: Array = upgrade(id).get("costs", [])
	return costs[rank(id)] if rank(id) < costs.size() else -1


## Buys the next rank and saves. Refused (nothing changes) when maxed, unaffordable, or if the
## save fails, so a purchase is never shown that was not kept.
func buy(id: String) -> Error:
	var cost: int = next_cost(id)
	if cost < 0 or feathers < cost:
		return ERR_UNAVAILABLE
	feathers -= cost
	ranks[id] = rank(id) + 1
	var error: Error = save()
	if error != OK:
		feathers += cost
		ranks[id] = rank(id) - 1
	return error


## Gives a fresh run its purchased ranks, once each, through the run's own bonus rules.
func apply_upgrades(run: Run) -> void:
	for entry: Dictionary in UPGRADES:
		for step: int in range(rank(entry["id"])):
			run._apply_bonus(entry["stat"], entry["amount"])


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
