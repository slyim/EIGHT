class_name Breakable
extends StaticBody2D
## PLACEHOLDER breakable obstacle: a wall segment, a structure (the old pillars), a tree, or
## one of Satan's shrines (the run's objective; see Run).
## While standing it is World geometry (layer 1), so it blocks exactly like the arena walls:
## the angel on the ground and in flight, ground enemies and bosses, ground shots, the spear
## and arrows. Flying enemies and their shots pass over it. Only the player's weapons damage
## it, through take_blow; it cracks and darkens as it weakens and breaks at zero health.
## Kinds, toughness, footprints, and every drawn visual are PLACEHOLDER, not designs.

signal hit(obstacle: Breakable)
signal broken(obstacle: Breakable)

enum Kind { WALL, STRUCTURE, TREE, SHRINE }

## PLACEHOLDER toughness (hit points) and footprint per kind. Walls run east-west unless
## vertical; a tree's footprint is a circle of that diameter, so the horde slides around it.
const KINDS: Array[Dictionary] = [
	{"health": 6, "size": Vector2(224.0, 48.0)},
	{"health": 10, "size": Vector2(160.0, 160.0)},
	{"health": 3, "size": Vector2(52.0, 52.0)},
	{"health": 20, "size": Vector2(80.0, 64.0)},
]
## PLACEHOLDER shrine: a dark obelisk with a red glowing pentagram, and a red light.
const SHRINE_LIFT: float = 72.0
const SHRINE_GLOW: Color = Color(2.4, 0.35, 0.3, 1.0)
const SHRINE_LIGHT: Color = Color(1.0, 0.25, 0.2, 0.55)
const SHRINE_LIGHT_RADIUS: float = 220.0
const PILLAR_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_env_pillar.aseprite")
const STRUCTURE_ART_RECT: Rect2 = Rect2(-52.0, -52.0, 104.0, 112.0)
## Seconds of shake after a blow; the flash covers the first FLASH_TIME of it.
const SHAKE_TIME: float = 0.16
const FLASH_TIME: float = 0.08
const SHAKE_STRENGTH: float = 3.0
## Softer than the enemy flash: obstacles are large, and values above 1 glow in HDR.
const FLASH_COLOR: Color = Color(2.2, 2.2, 2.2, 1.0)
## Tint at the last hit point; health in between blends from white.
const DAMAGED_COLOR: Color = Color(0.45, 0.38, 0.5, 1.0)
const CRACK_STAGES: int = 3
## Seconds the debris flies after breaking before the node frees itself.
const BREAK_TIME: float = 0.45
## Walls are drawn this much taller than their footprint, as the pillar art is.
const WALL_LIFT: float = 28.0
const WALL_FACE: float = 30.0
## PLACEHOLDER colors from the owner's palette.
const BLACK: Color = Color("070109")
const SHADOW: Color = Color(0.0275, 0.0039, 0.0353, 0.7)
const ABYSS: Color = Color("14081a")
const NIGHT: Color = Color("1e182e")
const NAVY: Color = Color("2e3850")
const STEEL: Color = Color("446077")
const WINE: Color = Color("6b2c40")
const RUST: Color = Color("995154")
const PLUM: Color = Color("3a2140")
const MAUVE: Color = Color("6e3f5f")
const ROSE: Color = Color("97576c")
const CRACK_COLOR: Color = Color("dccd93")
## PLACEHOLDER tree: trunk outline and branches as [from, to, width], drawn around the base.
## Widths stay even (whole 2-unit art pixels at the world's 0.5 zoom).
const TREE_TRUNK: Array[Vector2] = [Vector2(-18.0, 16.0), Vector2(-9.0, 6.0), Vector2(-8.0, -48.0),
	Vector2(-4.0, -76.0), Vector2(5.0, -78.0), Vector2(8.0, -48.0), Vector2(10.0, 6.0), Vector2(19.0, 16.0),
	Vector2(4.0, 12.0), Vector2(-5.0, 12.0)]
const TREE_BRANCHES: Array[Array] = [
	[Vector2(-5.0, -46.0), Vector2(-30.0, -80.0), 8.0], [Vector2(-30.0, -80.0), Vector2(-40.0, -102.0), 4.0],
	[Vector2(6.0, -58.0), Vector2(32.0, -88.0), 6.0], [Vector2(32.0, -88.0), Vector2(46.0, -92.0), 4.0],
	[Vector2(32.0, -88.0), Vector2(28.0, -110.0), 4.0], [Vector2(0.0, -76.0), Vector2(-6.0, -114.0), 6.0],
	[Vector2(7.0, -26.0), Vector2(27.0, -40.0), 4.0],
]

@export var kind: Kind = Kind.STRUCTURE
## Wall segments only: run north-south instead of east-west.
@export var vertical: bool = false

var max_health: int = 1
var health: int = 1
## Collision size, fixed once ready (floor placement asks for it often).
var size: Vector2 = Vector2.ZERO
## Seconds left of the hit shake and flash, then of the break debris.
var shake_left: float = 0.0
var break_left: float = 0.0
## Crack polylines, revealed one stage at a time as health drops.
var cracks: Array[PackedVector2Array] = []
## Break debris: [start, velocity, size, color] per chunk.
var debris: Array[Array] = []
var flip: float = 1.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var light_occluder: LightOccluder2D = $LightOccluder2D


## Collision size of a kind; vertical swaps a wall's length and depth.
static func footprint_size(of_kind: Kind, run_vertical: bool) -> Vector2:
	var size: Vector2 = KINDS[of_kind]["size"]
	return Vector2(size.y, size.x) if of_kind == Kind.WALL and run_vertical else size


func _ready() -> void:
	max_health = int(KINDS[kind]["health"])
	health = max_health
	size = footprint_size(kind, vertical)
	if kind == Kind.TREE:
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = size.x * 0.5
		collision_shape.shape = circle
	else:
		var box: RectangleShape2D = RectangleShape2D.new()
		box.size = size
		collision_shape.shape = box
	# Only the angel's Lamp casts shadows. PLACEHOLDER shape: the drawn obstacle (a tree's
	# trunk), wound clockwise and culled so the obstacle stays lit and its shadow falls behind.
	if kind == Kind.SHRINE:
		set_meta(&"light", SHRINE_LIGHT)
		set_meta(&"light_radius", SHRINE_LIGHT_RADIUS)
		add_to_group(&"light")
	var shade: Rect2 = Rect2(-10.0, -76.0, 20.0, 92.0) if kind == Kind.TREE else _visual_rect()
	if kind == Kind.STRUCTURE:
		shade = STRUCTURE_ART_RECT
	var occluder: OccluderPolygon2D = OccluderPolygon2D.new()
	occluder.cull_mode = OccluderPolygon2D.CULL_COUNTER_CLOCKWISE
	occluder.polygon = [shade.position, Vector2(shade.end.x, shade.position.y), shade.end, Vector2(shade.position.x, shade.end.y)]
	light_occluder.occluder = occluder
	# Each obstacle cracks and leans its own way, but the same way every time it is built.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(position)
	flip = -1.0 if rng.randf() < 0.5 else 1.0
	var area: Rect2 = _visual_rect().grow(-8.0)
	if kind == Kind.TREE:
		area = Rect2(-6.0, -74.0, 12.0, 82.0)
	elif kind == Kind.STRUCTURE:
		area = STRUCTURE_ART_RECT # Inside the pillar art's narrower top.
	for index: int in range(CRACK_STAGES):
		# Cracks start in the middle and spread out; trees split along the trunk.
		var point: Vector2 = area.position + area.size * Vector2(rng.randf_range(0.3, 0.7), rng.randf_range(0.3, 0.7))
		var heading: float = rng.randf() * TAU
		if kind == Kind.TREE:
			point.y = area.position.y + area.size.y * index / CRACK_STAGES
			heading = PI * 0.5
		var crack: PackedVector2Array = [point]
		for step: int in range(6):
			heading += rng.randf_range(-0.7, 0.7) * (0.35 if kind == Kind.TREE else 1.0)
			point += Vector2.from_angle(heading) * area.size.length() * rng.randf_range(0.08, 0.14)
			crack.append(point.clamp(area.position, area.end))
			if not area.has_point(point):
				break # A crack ends where it reaches the edge.
		cracks.append(crack)
	set_process(false)


## The ground this obstacle occupies, in its parent's space.
func footprint() -> Rect2:
	return Rect2(position - size * 0.5, size)


func is_standing() -> bool:
	return health > 0


## One blow from the player's weapons. Deliberately not take_hit: weapons treat take_hit
## targets as things to pierce through, while an obstacle stops the weapon that strikes it.
func take_blow(damage: int) -> void:
	if health <= 0 or damage <= 0:
		return
	health = maxi(0, health - damage)
	hit.emit(self)
	if health == 0:
		_break()
		return
	shake_left = SHAKE_TIME
	set_process(true)
	_update_tint()
	queue_redraw()


func _break() -> void:
	# Collision goes at once, so the horde, the angel, and shots pass this very tick.
	collision_layer = 0
	light_occluder.queue_free()
	remove_from_group(&"light")
	break_left = BREAK_TIME
	shake_left = 0.0
	modulate = Color.WHITE
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(position) + 1
	var area: Rect2 = _visual_rect()
	var colors: Array[Color] = [NAVY, NIGHT, STEEL]
	if kind == Kind.TREE:
		colors = [MAUVE, PLUM, ROSE]
	elif kind == Kind.SHRINE:
		colors = [WINE, ABYSS, RUST]
	for index: int in range(clampi(int(area.size.length() / 14.0), 8, 18)):
		var start: Vector2 = Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		var velocity: Vector2 = Vector2.from_angle(rng.randf_range(-PI, 0.0)) * rng.randf_range(90.0, 240.0)
		debris.append([start, velocity, rng.randf_range(7.0, 14.0), colors[index % colors.size()]])
	set_process(true)
	queue_redraw()
	broken.emit(self)


func _process(delta: float) -> void:
	if break_left > 0.0:
		break_left -= delta
		if break_left <= 0.0:
			queue_free()
			return
	else:
		shake_left = maxf(0.0, shake_left - delta)
		if shake_left == 0.0:
			set_process(false)
		_update_tint()
	queue_redraw()


func _update_tint() -> void:
	if shake_left > SHAKE_TIME - FLASH_TIME:
		modulate = FLASH_COLOR
	else:
		modulate = Color.WHITE.lerp(DAMAGED_COLOR, 1.0 - float(health) / max_health)


## Where the obstacle is drawn, around its footprint (walls stand taller than their base).
func _visual_rect() -> Rect2:
	match kind:
		Kind.WALL:
			return Rect2(-size.x * 0.5, -size.y * 0.5 - WALL_LIFT, size.x, size.y + WALL_LIFT)
		Kind.TREE:
			return Rect2(-46.0, -114.0, 92.0, 130.0)
		Kind.SHRINE:
			return Rect2(-size.x * 0.5, -size.y * 0.5 - SHRINE_LIFT, size.x, size.y + SHRINE_LIFT)
	return Rect2(-size * 0.5, size)


func _draw() -> void:
	if break_left > 0.0:
		_draw_debris()
		return
	var shake: Vector2 = Vector2.ZERO
	if shake_left > 0.0:
		shake = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SHAKE_STRENGTH * shake_left / SHAKE_TIME
	match kind:
		Kind.STRUCTURE:
			draw_set_transform(shake)
			# Drawn at the art's own 2x size, never stretched to the footprint.
			var pillar: Texture2D = PILLAR_FRAMES.get_frame_texture(&"idle", 0)
			draw_texture_rect(pillar, Rect2(-pillar.get_size(), pillar.get_size() * 2.0), false)
		Kind.WALL:
			draw_set_transform(shake)
			_draw_wall()
		Kind.TREE:
			_draw_tree(shake)
		Kind.SHRINE:
			draw_set_transform(shake)
			_draw_shrine()
	# A dark hairline marks every obstacle as breakable; damage opens glowing cracks, one
	# more per stage lost. The hairline is plain lines, which batch; polylines cost a draw call.
	var stage: int = ceili(CRACK_STAGES * (1.0 - float(health) / max_health) - 0.001)
	if stage == 0:
		for index: int in range(cracks[0].size() - 1):
			draw_line(cracks[0][index], cracks[0][index + 1], BLACK, 2.0)
	for index: int in range(mini(stage, cracks.size())):
		draw_polyline(cracks[index], BLACK, 6.0)
		draw_polyline(cracks[index], CRACK_COLOR, 2.0)


## PLACEHOLDER shrine: a stepped dark plinth, an obelisk, and a glowing inverted pentagram.
func _draw_shrine() -> void:
	var base: Rect2 = Rect2(-size.x * 0.5, -size.y * 0.5, size.x, size.y)
	draw_rect(Rect2(base.position + Vector2(6.0, base.size.y - 8.0), Vector2(base.size.x, 14.0)), SHADOW)
	draw_rect(base, NIGHT)
	draw_rect(Rect2(base.position, Vector2(base.size.x, 8.0)), PLUM)
	var obelisk: Rect2 = Rect2(-24.0, base.position.y - SHRINE_LIFT, 48.0, SHRINE_LIFT + 12.0)
	draw_rect(obelisk, ABYSS)
	draw_rect(Rect2(obelisk.position, Vector2(obelisk.size.x, 6.0)), WINE)
	var center: Vector2 = obelisk.get_center() - Vector2(0.0, 6.0)
	var star: PackedVector2Array = []
	for index: int in range(6):
		star.append(center + Vector2.from_angle(PI * 0.5 + TAU * 2.0 * index / 5.0) * 18.0)
	draw_polyline(star, SHRINE_GLOW, 2.0)
	draw_rect(obelisk, BLACK, false, 2.0)
	draw_rect(base, BLACK, false, 2.0)


## PLACEHOLDER wall segment in the pillar's stone colors: a lit top, a brick face, a dark
## outline. Every rect comes before every line, so each batches into one draw call.
func _draw_wall() -> void:
	var body: Rect2 = _visual_rect()
	var top: Rect2 = Rect2(body.position, Vector2(body.size.x, body.size.y - WALL_FACE))
	var face: Rect2 = Rect2(body.position.x, body.end.y - WALL_FACE, body.size.x, WALL_FACE)
	draw_rect(Rect2(body.position + Vector2(6.0, body.size.y - 8.0), Vector2(body.size.x, 14.0)), SHADOW)
	draw_rect(top, NAVY)
	draw_rect(face, NIGHT)
	# Capstone joints across the top, then a rim light along its far edge.
	for joint: int in range(1, int((top.size.y if vertical else top.size.x) / 36.0) + 1):
		if vertical:
			draw_line(top.position + Vector2(0.0, joint * 36.0), top.position + Vector2(top.size.x, joint * 36.0), NIGHT, 2.0)
		else:
			draw_line(top.position + Vector2(joint * 36.0, 0.0), top.position + Vector2(joint * 36.0, top.size.y), NIGHT, 2.0)
	draw_line(top.position + Vector2(0.0, 2.0), Vector2(top.end.x, top.position.y + 2.0), STEEL, 2.0)
	for row: int in range(3):
		var y: float = face.position.y + row * 10.0
		draw_line(Vector2(face.position.x, y), Vector2(face.end.x, y), ABYSS, 2.0)
		var x: float = face.position.x + (12.0 if row % 2 == 0 else 24.0)
		while x < face.end.x:
			draw_line(Vector2(x, y), Vector2(x, y + 10.0), ABYSS, 2.0)
			x += 24.0
	# Corruption veins as on the pillars.
	draw_line(Vector2(face.position.x + face.size.x * 0.3, face.position.y), Vector2(face.position.x + face.size.x * 0.27, face.end.y), WINE, 2.0)
	draw_line(Vector2(face.position.x + face.size.x * 0.72, face.position.y), Vector2(face.position.x + face.size.x * 0.76, face.end.y), WINE, 2.0)
	# Outline, each side run past the corners by half its width so the corners close.
	var outline: Rect2 = body.grow(-1.5)
	for side: int in range(4):
		var from: Vector2 = [outline.position, Vector2(outline.end.x, outline.position.y), outline.end, Vector2(outline.position.x, outline.end.y)][side]
		var to: Vector2 = [Vector2(outline.end.x, outline.position.y), outline.end, Vector2(outline.position.x, outline.end.y), outline.position][side]
		var along: Vector2 = (to - from).normalized() * 1.5
		draw_line(from - along, to + along, BLACK, 4.0)
	draw_line(face.position, Vector2(face.end.x, face.position.y), BLACK, 2.0)


## PLACEHOLDER tree: a thick withered trunk with flesh growths, much larger and lighter than
## the dead-tree floor props, drawn up from its footprint at the base. Outlines and branches
## are lines and the growths are pixel squares, so they batch into few draw calls.
func _draw_tree(shake: Vector2) -> void:
	draw_set_transform(shake + Vector2(0.0, 14.0), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 38.0, SHADOW)
	draw_set_transform(shake, 0.0, Vector2(flip, 1.0))
	for branch: Array in TREE_BRANCHES:
		draw_line(branch[0], branch[1], BLACK, float(branch[2]) + 4.0)
	for index: int in range(TREE_TRUNK.size()):
		draw_line(TREE_TRUNK[index], TREE_TRUNK[(index + 1) % TREE_TRUNK.size()], BLACK, 4.0)
	for branch: Array in TREE_BRANCHES:
		draw_line(branch[0], branch[1], MAUVE, branch[2])
	draw_colored_polygon(PackedVector2Array(TREE_TRUNK), MAUVE)
	draw_line(Vector2(-4.0, 8.0), Vector2(-2.0, -70.0), ROSE, 2.0)
	draw_line(Vector2(6.0, 8.0), Vector2(4.0, -60.0), PLUM, 2.0)
	for growth: Vector3 in [Vector3(-30.0, -80.0, 7.0), Vector3(32.0, -88.0, 6.0), Vector3(-2.0, -40.0, 5.0)]:
		# A rounded pixel blob: a wide and a tall rect crossed, outlined, with a highlight.
		var at: Vector2 = Vector2(growth.x, growth.y)
		for layer: Array in [[growth.z + 2.0, BLACK], [growth.z, WINE]]:
			var radius: float = layer[0]
			draw_rect(Rect2(at - Vector2(radius, radius * 0.6), Vector2(radius, radius * 0.6) * 2.0), layer[1])
			draw_rect(Rect2(at - Vector2(radius * 0.6, radius), Vector2(radius * 0.6, radius) * 2.0), layer[1])
		draw_rect(Rect2(at - Vector2.ONE * growth.z * 0.6, Vector2.ONE * growth.z * 0.6), RUST)


func _draw_debris() -> void:
	var t: float = BREAK_TIME - break_left
	var fade: float = break_left / BREAK_TIME
	for chunk: Array in debris:
		var at: Vector2 = chunk[0] + chunk[1] * t + Vector2(0.0, 520.0 * t * t)
		var size: float = chunk[2]
		var color: Color = chunk[3]
		# A short bright flash as it shatters, then the chunks fade.
		if t < FLASH_TIME:
			color = color.lerp(Color.WHITE, 0.6)
		color.a = fade
		draw_rect(Rect2(at - Vector2(size, size) * 0.5, Vector2(size, size)), color)
