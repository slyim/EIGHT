class_name Arrow
extends Node2D
## Player arrow: a swept projectile that damages through take_hit, pierces up to
## `pierce` targets, stops at walls (damaging a breakable obstacle it stops at), and is
## freed at the end of its range.
## The drawn shaft and head are PLACEHOLDER art. The visual is drawn on this node,
## with a shared PLACEHOLDER-tunable cool emission material.

const LENGTH: float = 22.0
const COLOR: Color = Color(0.792, 0.922, 0.878, 1.0)

var direction: Vector2 = Vector2.RIGHT
var speed: float = 900.0
var range_left: float = 400.0
var damage: int = 1
var pierce: int = 1
## Layers that stop the arrow (1 = World).
var wall_mask: int = 1
## Layers the arrow damages from any height: practice targets, enemies, and flying enemies (layers 3-5).
var hit_mask: int = 28
var hit_rids: Array[RID] = []
## Visual only: how far above its ground track the arrow is drawn (the bow's height when fired).
var height: float = 0.0
## Ricochet: after a hit, turn toward the nearest unhit target within bounce_range this many
## more times (a bounce does not spend pierce), with a fresh bounce_range of flight each time.
var bounces: int = 0
## PLACEHOLDER tint: light for bow arrows, gold for side-weapon feathers.
var color: Color = COLOR
var bounce_range: float = 280.0


func _ready() -> void:
	material = preload("res://shaders/weapon_light.tres")
	add_to_group(&"light")
	global_rotation = direction.angle()


func _physics_process(delta: float) -> void:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var travel: float = minf(speed * delta, range_left)
	var start: Vector2 = global_position
	var end: Vector2 = start + direction * travel
	var wall_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, end, wall_mask)
	wall_query.hit_from_inside = true
	var wall_hit: Dictionary = space.intersect_ray(wall_query)
	var stop: Vector2 = wall_hit["position"] if not wall_hit.is_empty() else end
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, stop, hit_mask & ~wall_mask)
	query.hit_from_inside = true
	while true:
		query.exclude = hit_rids
		var result: Dictionary = space.intersect_ray(query)
		if result.is_empty():
			break
		hit_rids.append(result["rid"])
		var collider: Object = result["collider"]
		if collider == null or not collider.has_method(&"take_hit"):
			continue
		collider.call(&"take_hit", damage)
		if bounces > 0 and _bounce_from(result["position"]):
			return
		pierce -= 1
		if pierce <= 0:
			queue_free()
			return
	global_position = stop
	range_left -= travel
	if not wall_hit.is_empty():
		# A breakable obstacle takes the arrow's damage; the arrow is spent on it, pierce or not.
		var obstacle: Breakable = wall_hit["collider"] as Breakable
		if obstacle != null:
			obstacle.take_blow(damage)
		queue_free()
	elif range_left <= 0.0:
		queue_free()


## Turns toward the nearest target not hit yet; false when none is in range.
func _bounce_from(at: Vector2) -> bool:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = bounce_range
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, at)
	query.collision_mask = hit_mask & ~wall_mask
	query.exclude = hit_rids
	var next: Node2D = null
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var collider: Node2D = result["collider"] as Node2D
		if collider != null and collider.has_method(&"take_hit") and (next == null or at.distance_to(collider.global_position) < at.distance_to(next.global_position)):
			next = collider
	if next == null:
		return false
	bounces -= 1
	global_position = at
	direction = (next.global_position - at).normalized()
	global_rotation = direction.angle()
	range_left = bounce_range
	queue_redraw()
	return true


func _draw() -> void:
	# PLACEHOLDER arrow: a light shaft with a small head, lifted to screen-up by height.
	draw_set_transform(Vector2(0.0, -height).rotated(-global_rotation))
	draw_line(Vector2(-LENGTH, 0.0), Vector2.ZERO, color, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(4.0, 0.0), Vector2(-4.0, -4.0), Vector2(-4.0, 4.0)]), color)
