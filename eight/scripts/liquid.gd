class_name Liquid
## Animated liquid for the HUD gauges: a wavy front that sloshes when the level changes, a
## surface sheen, and bubbles rising through it. Drawn in code, so it stays crisp vector UI.

## Eases a shown level toward its target (exponential; rate per second).
static func approach(shown: float, target: float, delta: float, rate: float = 8.0) -> float:
	return lerpf(shown, target, 1.0 - exp(-rate * delta))


## Fills a horizontal gauge from the left up to fraction, clipped to a chamfered plate.
## slosh (0..1) swells the front's wave right after a change.
static func draw_bar(canvas: CanvasItem, rect: Rect2, fraction: float, top: Color, bottom: Color, now: float, slosh: float) -> void:
	if fraction <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var plate: PackedVector2Array = OrnateBox.plate(rect, 4.0)
	var front: float = rect.position.x + rect.size.x * clampf(fraction, 0.0, 1.0)
	var amp: float = (1.0 + 3.0 * slosh) if fraction < 1.0 else 0.0
	var body: PackedVector2Array = [Vector2(rect.position.x - 2.0, rect.position.y - 2.0)]
	for step: int in range(9):
		var y: float = lerpf(rect.position.y - 2.0, rect.end.y + 2.0, step / 8.0)
		body.append(Vector2(front + sin(y * 0.6 + now * 7.0) * amp, y))
	body.append(Vector2(rect.position.x - 2.0, rect.end.y + 2.0))
	for part: PackedVector2Array in Geometry2D.intersect_polygons(plate, body):
		canvas.draw_polygon(part, _shade(part, rect, top, bottom))
	var sheen_end: float = minf(front - 2.0, rect.end.x - 4.0)
	if sheen_end > rect.position.x + 4.0:
		canvas.draw_line(Vector2(rect.position.x + 4.0, rect.position.y + 2.0), Vector2(sheen_end, rect.position.y + 2.0), Color(1.0, 0.96, 0.85, 0.22), 1.0)
	for index: int in range(5):
		var rise: float = fposmod(now * (0.35 + 0.13 * index) + index * 0.21, 1.0)
		var x: float = rect.position.x + 3.0 + fposmod(index * 0.37 + now * 0.04 * (index + 1), 1.0) * maxf(0.0, front - rect.position.x - 6.0)
		if x < front - 3.0:
			canvas.draw_circle(Vector2(x, lerpf(rect.end.y - 2.0, rect.position.y + 2.0, rise)), 1.0 + (index % 2) * 0.5, Color(1.0, 0.96, 0.85, 0.3 * (1.0 - rise)))


## Fills a closed shape from the bottom up to the surface y, with a wave that sloshes.
static func draw_pool(canvas: CanvasItem, shape: PackedVector2Array, bounds: Rect2, surface: float, top: Color, bottom: Color, now: float, slosh: float, wave: bool) -> void:
	var amp: float = (1.2 + 2.5 * slosh) if wave else 0.0
	var body: PackedVector2Array = []
	for step: int in range(13):
		var x: float = lerpf(bounds.position.x - 2.0, bounds.end.x + 2.0, step / 12.0)
		body.append(Vector2(x, surface + sin(x * 0.4 + now * 4.0) * amp))
	body.append(Vector2(bounds.end.x + 2.0, bounds.end.y + 2.0))
	body.append(Vector2(bounds.position.x - 2.0, bounds.end.y + 2.0))
	for part: PackedVector2Array in Geometry2D.intersect_polygons(shape, body):
		canvas.draw_polygon(part, _shade(part, bounds, top, bottom))


static func _shade(points: PackedVector2Array, rect: Rect2, top: Color, bottom: Color) -> PackedColorArray:
	var colors: PackedColorArray = []
	for point: Vector2 in points:
		colors.append(top.lerp(bottom, clampf((point.y - rect.position.y) / maxf(rect.size.y, 1.0), 0.0, 1.0)))
	return colors
