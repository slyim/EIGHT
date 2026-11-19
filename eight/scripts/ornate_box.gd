@tool
class_name OrnateBox
extends StyleBox
## Vector frame in the Hades manner: a chamfered dark plate on a soft offset shadow, a bronze
## outer rule, a fine inner rule, and diamond studs on the chamfers. Drawn in code so it stays
## crisp at every UI scale; the theme uses it for buttons, cards, and menu panels.

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
	var colors: PackedColorArray = []
	for point: Vector2 in points:
		colors.append(fill_top.lerp(fill_bottom, clampf((point.y - rect.position.y) / maxf(rect.size.y, 1.0), 0.0, 1.0)))
	if fill_top.a > 0.0 or fill_bottom.a > 0.0:
		RenderingServer.canvas_item_add_polygon(to_canvas_item, points, colors)
	if rim.a > 0.0:
		if keyline.a > 0.0:
			_rule(to_canvas_item, plate(rect.grow(rim_width * 0.5 + 0.75), chamfer + 0.75), keyline, 1.5)
		_rule(to_canvas_item, points, rim, rim_width)
	var inset: Rect2 = rect.grow(-(rim_width + 3.0))
	if trim.a > 0.0 and inset.size.x > 12.0 and inset.size.y > 12.0:
		_rule(to_canvas_item, plate(inset, maxf(chamfer - 3.0, 2.0)), trim, 1.0)
	if stud.a <= 0.0:
		return
	var cut: float = _cut(rect, chamfer) * 0.5
	for corner: Vector2 in [rect.position + Vector2(cut, cut), Vector2(rect.end.x - cut, rect.position.y + cut), rect.end - Vector2(cut, cut), Vector2(rect.position.x + cut, rect.end.y - cut)]:
		_diamond(to_canvas_item, corner, 3.0, stud)
	if crest:
		for y: float in [rect.position.y, rect.end.y]:
			var middle: Vector2 = Vector2(rect.get_center().x, y)
			for side: float in [-1.0, 1.0]:
				RenderingServer.canvas_item_add_line(to_canvas_item, middle + Vector2(side * 9.0, 0.0), middle + Vector2(side * 34.0, 0.0), stud, 1.5, true)
			_diamond(to_canvas_item, middle, 6.0, stud)
			_diamond(to_canvas_item, middle, 2.5, fill_bottom)


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
