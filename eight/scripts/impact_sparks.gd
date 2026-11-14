class_name ImpactSparks
extends Node2D
## PLACEHOLDER impact sparks: every connecting hit throws a few art-pixel sparks along the push,
## drawn by this one node (no node per spark) on whole art pixels. Finishers and evolved
## strikes throw more, larger, gold sparks.

const LIFETIME: float = 0.12
const CAP: int = 96
const COLOR: Color = Color(1.4, 1.35, 1.1, 1.0)
const HEAVY_COLOR: Color = Color(1.9, 1.75, 0.9, 1.0)
const SPREAD: float = 0.6

## Each: [origin, direction, length, heavy, age].
var sparks: Array[Array] = []


func add(at: Vector2, direction: Vector2, heavy: bool) -> void:
	var count: int = 4 if heavy else 3
	for index: int in range(count):
		if sparks.size() >= CAP:
			sparks.pop_front()
		var angle: float = lerpf(-SPREAD, SPREAD, float(index) / (count - 1))
		sparks.append([at, direction.rotated(angle), (40.0 if heavy else 26.0) * (1.0 - absf(angle) * 0.6), heavy, 0.0])
	queue_redraw()


func _process(delta: float) -> void:
	if sparks.is_empty():
		return
	for spark: Array in sparks:
		spark[4] += delta
	sparks = sparks.filter(func(spark: Array) -> bool: return spark[4] < LIFETIME)
	queue_redraw()


func _draw() -> void:
	for spark: Array in sparks:
		var progress: float = spark[4] / LIFETIME
		var tip: Vector2 = spark[0] + spark[1] * spark[2] * progress
		var size: float = 4.0 if spark[3] else 2.0
		# Whole art pixels (2 world units), so sparks never smear across the grid.
		var cell: Vector2 = (tip / 2.0).floor() * 2.0
		draw_rect(Rect2(cell, Vector2(size, size)), HEAVY_COLOR if spark[3] else COLOR)
