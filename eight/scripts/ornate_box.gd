@tool
class_name OrnateBox
extends StyleBox
## Vector frame in the Hades manner, set like church stained glass: a chamfered plate of deep glass
## lit from its centre, a band of rim-coloured glass between two lead cames (bright along its middle
## and from above, deeper beside the lead), and round glass jewels on the chamfers. Shaded with
## colour only, no cracks. Drawn in code so it stays crisp at every UI scale and renders the same
## on Forward+ and Compatibility; the theme uses it for buttons, cards, and menu panels.

@export var fill_top: Color = Color("1e182e")
@export var fill_bottom: Color = Color("0c0611")
@export var rim: Color = Color("b7836b")
@export var trim: Color = Color(0.863, 0.804, 0.576, 0.3)
@export var stud: Color = Color("dccd93")
## A halo around the frame (hover and focus); transparent draws none.
@export var glow: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var chamfer: float = 8.0
@export var rim_width: float = 2.0
## Panels carry a crest (a diamond between two short rules) at the top and bottom centre.
@export var crest: bool = false
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.5)
@export var shadow_offset: Vector2 = Vector2(0.0, 4.0)
## A dark keyline just outside the rim, so frames separate from bright effects behind them.
@export var keyline: Color = Color(0.0275, 0.0039, 0.0353, 0.9)
## Draws this far inside the given rect (gauge fills nest inside their frame this way).
@export var inset: float = 0.0
## Width of the glass band inside the lead (capped at 12% of the frame's short side); below
## 1.5 UI units the rim is a plain rule.
@export var glass_width: float = 6.0

const LEAD: Color = Color(0.0784, 0.0314, 0.102, 1.0)


func _draw(to_canvas_item: RID, area: Rect2) -> void:
	var rect: Rect2 = area.grow(-inset)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	if shadow_color.a > 0.0:
		# Three widening, fading plates stand in for a blurred shadow.
		for step: int in range(3):
			var color: Color = shadow_color
			color.a *= 0.45 - step * 0.12
			var under: Rect2 = Rect2(rect.position + shadow_offset, rect.size).grow(1.0 + step * 2.0)
			RenderingServer.canvas_item_add_polygon(to_canvas_item, plate(under, chamfer + 1.0 + step * 2.0), [color])
	if glow.a > 0.0:
		for step: int in range(3):
			var color: Color = glow
			color.a *= 1.0 - step / 3.0
			_rule(to_canvas_item, plate(rect.grow(1.5 + step * 1.5), chamfer + 1.5 + step * 1.5), color, 2.0)
	var points: PackedVector2Array = plate(rect, chamfer)
	if fill_top.a > 0.0 or fill_bottom.a > 0.0:
		# Deep glass lit from the middle: a fan from a slightly warmer, brighter centre.
		var fan: PackedVector2Array = points.duplicate()
		fan.append(rect.get_center())
		var colors: PackedColorArray = []
		for point: Vector2 in points:
			colors.append(fill_top.lerp(fill_bottom, clampf((point.y - rect.position.y) / maxf(rect.size.y, 1.0), 0.0, 1.0)))
		var centre: Color = fill_top.lerp(fill_bottom, 0.5).lerp(rim, 0.07 * rim.a)
		centre.a = maxf(fill_top.a, fill_bottom.a)
		colors.append(centre)
		var indices: PackedInt32Array = []
		for index: int in range(points.size()):
			indices.append_array([index, (index + 1) % points.size(), points.size()])
		RenderingServer.canvas_item_add_triangle_array(to_canvas_item, indices, fan, colors)
	var band: float = minf(glass_width, minf(rect.size.x, rect.size.y) * 0.12)
	if rim.a > 0.0:
		if keyline.a > 0.0:
			_rule(to_canvas_item, plate(rect.grow(rim_width * 0.5 + 0.75), chamfer + 0.75), keyline, 1.5)
		if band >= 1.5:
			glass_band(to_canvas_item, rect, chamfer, band, rim)
		else:
			_rule(to_canvas_item, points, rim, rim_width)
	var inset: Rect2 = rect.grow(-(maxf(rim_width, band) + 3.0))
	if trim.a > 0.0 and inset.size.x > 12.0 and inset.size.y > 12.0:
		_rule(to_canvas_item, plate(inset, maxf(chamfer - 3.0, 2.0)), trim, 1.0)
	if stud.a <= 0.0:
		return
	# Jewels sit on the glass band where it turns the chamfer.
	var cut: float = _cut(rect, chamfer) * 0.5 + minf(glass_width, minf(rect.size.x, rect.size.y) * 0.12) * 0.35
	for corner: Vector2 in [rect.position + Vector2(cut, cut), Vector2(rect.end.x - cut, rect.position.y + cut), rect.end - Vector2(cut, cut), Vector2(rect.position.x + cut, rect.end.y - cut)]:
		jewel(to_canvas_item, corner, 3.2, stud)
	if crest:
		for y: float in [rect.position.y, rect.end.y]:
			var middle: Vector2 = Vector2(rect.get_center().x, y)
			for side: float in [-1.0, 1.0]:
				RenderingServer.canvas_item_add_line(to_canvas_item, middle + Vector2(side * 9.0, 0.0), middle + Vector2(side * 34.0, 0.0), stud, 1.5, true)
			_diamond(to_canvas_item, middle, 7.5, LEAD)
			_diamond(to_canvas_item, middle, 6.0, stud)
			jewel(to_canvas_item, middle, 2.4, rim)


## A band of glass just inside a chamfered outline, between two lead cames: light along its
## middle and from above, deeper beside the lead.
static func glass_band(item: RID, rect: Rect2, corner: float, width: float, glass: Color) -> void:
	var ring: Array[PackedVector2Array] = [plate(rect, corner), plate(rect.grow(-width * 0.5), maxf(corner - width * 0.2, 1.0)), plate(rect.grow(-width), maxf(corner - width * 0.4, 1.0))]
	var count: int = ring[0].size()
	for index: int in range(count):
		var next: int = (index + 1) % count
		for half: int in range(2):
			var quad: PackedVector2Array = [ring[half][index], ring[half][next], ring[half + 1][next], ring[half + 1][index]]
			var colors: PackedColorArray = []
			for corner_index: int in range(4):
				# The middle outline (outer half's inner edge, inner half's outer edge) is the lit one.
				var lit: bool = (half == 0) == (corner_index >= 2)
				colors.append(_glass_tone(glass, lit, (quad[corner_index].y - rect.position.y) / maxf(rect.size.y, 1.0)))
			RenderingServer.canvas_item_add_polygon(item, quad, colors)
	_rule(item, ring[0], LEAD, 1.6)
	_rule(item, ring[2], LEAD, 1.2)


## Glass colour at a height (0 top, 1 bottom): lit glass is brighter and warmer, deep glass darker.
static func _glass_tone(glass: Color, lit: bool, height: float) -> Color:
	var above: float = 1.0 - clampf(height, 0.0, 1.0)
	var tone: Color = glass.lightened(0.22 + 0.2 * above) if lit else glass.darkened(0.62 - 0.12 * above)
	tone.a = glass.a
	return tone


## A round glass jewel in a lead setting, lit near its top left.
static func jewel(item: RID, center: Vector2, radius: float, color: Color) -> void:
	RenderingServer.canvas_item_add_circle(item, center, radius + 1.3, LEAD)
	var ring: PackedVector2Array = []
	var colors: PackedColorArray = []
	for step: int in range(12):
		ring.append(center + Vector2.from_angle(TAU * step / 12.0) * radius)
		colors.append(Color(color.darkened(0.35), color.a))
	ring.append(center + Vector2(-0.3, -0.3) * radius)
	colors.append(Color(color.lightened(0.45), color.a))
	var indices: PackedInt32Array = []
	for step: int in range(12):
		indices.append_array([step, (step + 1) % 12, 12])
	RenderingServer.canvas_item_add_triangle_array(item, indices, ring, colors)


## The chamfered outline of a rect, clockwise from the top left edge.
static func plate(rect: Rect2, corner: float) -> PackedVector2Array:
	var c: float = _cut(rect, corner)
	var a: Vector2 = rect.position
	var b: Vector2 = rect.end
	return PackedVector2Array([
		Vector2(a.x + c, a.y), Vector2(b.x - c, a.y), Vector2(b.x, a.y + c), Vector2(b.x, b.y - c),
		Vector2(b.x - c, b.y), Vector2(a.x + c, b.y), Vector2(a.x, b.y - c), Vector2(a.x, a.y + c),
	])


static func _cut(rect: Rect2, corner: float) -> float:
	return clampf(corner, 0.0, minf(rect.size.x, rect.size.y) * 0.5)


static func _rule(item: RID, points: PackedVector2Array, color: Color, width: float) -> void:
	var closed: PackedVector2Array = points.duplicate()
	closed.append(points[0])
	RenderingServer.canvas_item_add_polyline(item, closed, [color], width, true)


static func _diamond(item: RID, center: Vector2, size: float, color: Color) -> void:
	var points: PackedVector2Array = [center + Vector2(0.0, -size), center + Vector2(size, 0.0), center + Vector2(0.0, size), center + Vector2(-size, 0.0)]
	RenderingServer.canvas_item_add_polygon(item, points, [color])
	_rule(item, points, color, 1.0)
