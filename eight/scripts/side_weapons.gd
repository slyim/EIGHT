class_name SideWeapons
extends Node2D
## The angel's auto-firing side weapons, found in chests and on slain guards. Finding one
## again levels it up (to MAX_LEVEL). They strike ground and flying enemies alike, scale with
## the angel's might (damage) and haste (intervals), and rest while the angel descends or has
## fallen. Every number and the drawn orbs, ring, and bolt are PLACEHOLDER; drawing keeps to
## whole art pixels (even widths, no antialiasing).

enum Kind { HALOS, FEATHERS, PULSE, BOLT }

const MAX_LEVEL: int = 3
const NAMES: Array[String] = ["Orbiting halos", "Seeking feathers", "Holy pulse", "Judgment bolt"]
const NUMERALS: Array[String] = ["", "I", "II", "III"]
## Practice targets, enemies, and flying enemies (layers 3-5).
const HIT_MASK: int = 28
const GOLD: Color = Color(0.902, 0.886, 0.6196, 1.0)
const GLOW: Color = Color(1.8, 1.7, 1.1, 1.0)

## Orbiting halos: orbs circle the angel and strike what they touch (each target at most once
## per HALO_REHIT seconds).
const HALO_COUNT: Array[int] = [2, 3, 4]
const HALO_DAMAGE: Array[int] = [1, 1, 2]
const HALO_RADIUS: float = 72.0
const HALO_SPIN: float = 2.6
const HALO_SIZE: float = 8.0
const HALO_REHIT: float = 0.5
## Seeking feathers: every interval, feathers fly at the nearest enemies in range.
const FEATHER_INTERVAL: float = 1.6
const FEATHER_COUNT: Array[int] = [1, 2, 3]
const FEATHER_DAMAGE: Array[int] = [1, 1, 2]
const FEATHER_RANGE: float = 420.0
const FEATHER_SPEED: float = 700.0
## Holy pulse: every interval, a ring bursts out, striking and pushing back what it reaches.
const PULSE_INTERVAL: float = 3.0
const PULSE_RADIUS: Array[float] = [120.0, 150.0, 180.0]
const PULSE_DAMAGE: Array[int] = [1, 2, 3]
const PULSE_PUSH: float = 1.6
const PULSE_SHOW: float = 0.3
## Judgment bolt: every interval, light strikes a random enemy within range.
const BOLT_INTERVAL: Array[float] = [2.4, 1.9, 1.5]
const BOLT_DAMAGE: Array[int] = [3, 4, 5]
const BOLT_RANGE: float = 560.0
const BOLT_SHOW: float = 0.18

## Level per Kind; 0 means not found yet.
var levels: Array[int] = [0, 0, 0, 0]
## Seconds until each weapon may fire again.
var waits: Array[float] = [0.0, 0.0, 0.0, 0.0]
var halo_angle: float = 0.0
## Halo hits: target instance id -> seconds until it can be struck again.
var halo_rehit: Dictionary = {}
var pulse_left: float = 0.0
var bolt_left: float = 0.0
var bolt_at: Vector2 = Vector2.ZERO
## One light source per orb, so the halos light the dark around them (see scripts/lights.gd).
var orb_lights: Array[Node2D] = []

@onready var player: MountedPlayer = get_parent() as MountedPlayer


## Finds or levels a side weapon; false once it is at MAX_LEVEL.
func add(kind: Kind) -> bool:
	if levels[kind] >= MAX_LEVEL:
		return false
	levels[kind] += 1
	queue_redraw()
	return true


## The side weapons that can still be found or levelled.
func can_grow() -> Array[int]:
	var open: Array[int] = []
	for kind: int in range(levels.size()):
		if levels[kind] < MAX_LEVEL:
			open.append(kind)
	return open


## "Seeking feathers II" style name, for the HUD.
func label(kind: Kind) -> String:
	return "%s %s" % [NAMES[kind], NUMERALS[levels[kind]]]


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead or player.is_descending():
		return
	for kind: int in range(waits.size()):
		waits[kind] = maxf(0.0, waits[kind] - delta)
	pulse_left = maxf(0.0, pulse_left - delta)
	bolt_left = maxf(0.0, bolt_left - delta)
	for id: int in halo_rehit.keys():
		halo_rehit[id] = float(halo_rehit[id]) - delta
		if float(halo_rehit[id]) <= 0.0:
			halo_rehit.erase(id)
	if levels[Kind.HALOS] > 0:
		halo_angle = fmod(halo_angle + HALO_SPIN * delta, TAU)
		_place_orb_lights()
		_strike_halos()
	if levels[Kind.FEATHERS] > 0 and waits[Kind.FEATHERS] <= 0.0:
		_fire_feathers()
	if levels[Kind.PULSE] > 0 and waits[Kind.PULSE] <= 0.0:
		_pulse()
	if levels[Kind.BOLT] > 0 and waits[Kind.BOLT] <= 0.0:
		_bolt()
	queue_redraw()


## Snaps a world point to the art grid (one art pixel = 2 world units).
static func on_grid(point: Vector2) -> Vector2:
	return (point / 2.0).round() * 2.0


## Targets with take_hit inside a circle that the angel can see (no wall or standing obstacle
## between them), nearest first. Like the spear and bow, side weapons never act through walls.
func _targets_near(at: Vector2, radius: float) -> Array[Node2D]:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, at)
	query.collision_mask = HIT_MASK
	var found: Array[Node2D] = []
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, LightRain.MAX_TARGETS):
		var collider: Node2D = result["collider"] as Node2D
		if collider == null or not collider.has_method(&"take_hit") or found.has(collider):
			continue
		var sight: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(player.global_position, collider.global_position, 1)
		if get_world_2d().direct_space_state.intersect_ray(sight).is_empty():
			found.append(collider)
	found.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	return found


func halo_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	var count: int = HALO_COUNT[levels[Kind.HALOS] - 1] if levels[Kind.HALOS] > 0 else 0
	for index: int in range(count):
		points.append(player.global_position + Vector2.from_angle(halo_angle + TAU * index / count) * HALO_RADIUS)
	return points


func _place_orb_lights() -> void:
	var points: Array[Vector2] = halo_points()
	while orb_lights.size() < points.size():
		var light: Node2D = Node2D.new()
		light.set_meta(&"light", Color(1.0, 0.9, 0.5, 0.45))
		light.set_meta(&"light_radius", 56.0)
		light.add_to_group(&"light")
		add_child(light)
		orb_lights.append(light)
	for index: int in range(points.size()):
		orb_lights[index].global_position = points[index]


func _strike_halos() -> void:
	var damage: int = player.dealt(HALO_DAMAGE[levels[Kind.HALOS] - 1])
	for point: Vector2 in halo_points():
		for target: Node2D in _targets_near(point, HALO_SIZE + 6.0):
			var id: int = target.get_instance_id()
			if halo_rehit.has(id):
				continue
			halo_rehit[id] = HALO_REHIT
			target.call(&"take_hit", damage)


func _fire_feathers() -> void:
	var targets: Array[Node2D] = _targets_near(player.global_position, FEATHER_RANGE)
	if targets.is_empty():
		return # Ready again the moment something comes in range.
	var level: int = levels[Kind.FEATHERS]
	waits[Kind.FEATHERS] = FEATHER_INTERVAL * player.attack_haste()
	for index: int in range(mini(FEATHER_COUNT[level - 1], targets.size())):
		var feather: Arrow = MountedPlayer.ARROW_SCENE.instantiate() as Arrow
		feather.direction = (targets[index].global_position - player.global_position).normalized()
		feather.speed = FEATHER_SPEED
		feather.damage = player.dealt(FEATHER_DAMAGE[level - 1])
		feather.range_left = FEATHER_RANGE + 40.0
		feather.color = GOLD
		feather.add_to_group(&"side_shots")
		feather.height = MountedPlayer.SPEAR_HEIGHT + player.height
		feather.position = player.global_position
		player.get_parent().add_child(feather)


func _pulse() -> void:
	var level: int = levels[Kind.PULSE]
	waits[Kind.PULSE] = PULSE_INTERVAL * player.attack_haste()
	pulse_left = PULSE_SHOW
	var damage: int = player.dealt(PULSE_DAMAGE[level - 1])
	for target: Node2D in _targets_near(player.global_position, PULSE_RADIUS[level - 1]):
		target.call(&"take_hit", damage)
		var enemy: Enemy = target as Enemy
		if enemy != null:
			enemy.knockback *= PULSE_PUSH


func _bolt() -> void:
	var targets: Array[Node2D] = _targets_near(player.global_position, BOLT_RANGE)
	if targets.is_empty():
		return
	var level: int = levels[Kind.BOLT]
	waits[Kind.BOLT] = BOLT_INTERVAL[level - 1] * player.attack_haste()
	var target: Node2D = targets.pick_random()
	bolt_at = target.global_position
	bolt_left = BOLT_SHOW
	target.call(&"take_hit", player.dealt(BOLT_DAMAGE[level - 1]))


func _draw() -> void:
	if player == null:
		return
	var lift: Vector2 = Vector2(0.0, -MountedPlayer.SPEAR_HEIGHT - player.height)
	for point: Vector2 in halo_points():
		var at: Vector2 = on_grid(to_local(point) + lift)
		draw_circle(at, HALO_SIZE + 2.0, Color(GOLD, 0.6))
		draw_circle(at, HALO_SIZE - 2.0, GLOW)
	if pulse_left > 0.0 and levels[Kind.PULSE] > 0:
		var grown: float = 1.0 - pulse_left / PULSE_SHOW
		var ring: float = roundf(PULSE_RADIUS[levels[Kind.PULSE] - 1] * (0.4 + 0.6 * grown) / 2.0) * 2.0
		draw_arc(Vector2.ZERO, ring, 0.0, TAU, 64, Color(GLOW, 1.0 - grown), 4.0)
	if bolt_left > 0.0:
		var foot: Vector2 = on_grid(to_local(bolt_at))
		draw_line(foot - Vector2(0.0, 220.0), foot, Color(GLOW, bolt_left / BOLT_SHOW), 4.0)
		draw_circle(foot, 10.0, Color(GOLD, 0.4 * bolt_left / BOLT_SHOW))
