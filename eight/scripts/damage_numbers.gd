class_name DamageNumbers
extends Control
## Crisp floating damage numbers drawn in one Control over the world view. Numbers on the same
## enemy key stack while alive instead of flooding the screen. Visuals and timings are PLACEHOLDER.

const LIFETIME: float = 0.45
const FADE_TIME: float = 0.15
const RISE_PIXELS: float = 18.0
const POP_TIME: float = 0.1
const HEAVY_POP_SCALE: float = 1.3
const STACK_POP_SCALE: float = 1.15
const NORMAL_FONT_SIZE: int = 15
const HEAVY_FONT_SIZE: int = 19
const OUTLINE_SIZE: int = 5
const NORMAL_COLOR: Color = Color(0.7922, 0.9216, 0.8784, 1.0)
const HEAVY_COLOR: Color = Color(0.902, 0.886, 0.6196, 1.0)
const OUTLINE_COLOR: Color = Color(0.0275, 0.0039, 0.0353, 1.0)
const MAX_ENTRIES: int = 48
const SPREAD_DISTANCE: float = 8.0
const SPREAD_STEP: float = 6.0
const HEAD_OFFSET: float = 14.0

var hud: Hud
var entries: Array[Dictionary] = []


func record(at: Vector2, amount: int, heavy: bool, key: int) -> void:
	if hud == null or not hud.damage_numbers_enabled or hud.run == null or hud.run.ended or amount <= 0:
		return
	for entry: Dictionary in entries:
		if int(entry["key"]) == key:
			entry["amount"] = int(entry["amount"]) + amount
			entry["at"] = at
			entry["heavy"] = bool(entry["heavy"]) or heavy
			entry["age"] = 0.0
			entry["stacked"] = true
			queue_redraw()
			return
	if entries.size() >= MAX_ENTRIES:
		entries.pop_front()
	var near: int = 0
	for other: Dictionary in entries:
		if at.distance_to(other["at"] as Vector2) < SPREAD_DISTANCE:
			near += 1
	var spread: float = 0.0
	if near > 0:
		spread = (1.0 if near % 2 == 1 else -1.0) * float((near + 1) / 2) * SPREAD_STEP
	entries.append({
		"at": at,
		"amount": amount,
		"heavy": heavy,
		"key": key,
		"age": 0.0,
		"stacked": false,
		"spread": spread,
	})
	queue_redraw()


func clear() -> void:
	if entries.is_empty():
		return
	entries.clear()
	queue_redraw()


## Current HUD position of an entry: its world anchor projected to HUD, plus rise and spread.
func entry_hud_position(entry: Dictionary) -> Vector2:
	var base: Vector2 = hud.world_to_hud(entry["at"] as Vector2)
	var rise: float = RISE_PIXELS * clampf(float(entry["age"]) / LIFETIME, 0.0, 1.0)
	return base + Vector2(float(entry["spread"]), -rise)


func is_entry_visible(entry: Dictionary) -> bool:
	if hud == null or hud.run == null or hud.run.ended or not hud.damage_numbers_enabled:
		return false
	var view: Rect2 = hud.world_view.get_rect() if hud.world_view != null else Rect2(Vector2.ZERO, size)
	return view.has_point(hud.world_to_hud(entry["at"] as Vector2))


func _process(delta: float) -> void:
	if hud == null or hud.run == null:
		return
	if not hud.damage_numbers_enabled or hud.run.ended:
		clear()
		return
	if get_tree().paused or entries.is_empty():
		return
	var index: int = 0
	while index < entries.size():
		var age: float = float(entries[index]["age"]) + delta
		if age >= LIFETIME:
			entries.remove_at(index)
		else:
			entries[index]["age"] = age
			index += 1
	queue_redraw()


func _draw() -> void:
	if hud == null or hud.run == null or hud.run.ended or not hud.damage_numbers_enabled or entries.is_empty():
		return
	var body_font: Font = get_theme_default_font()
	var heading_font: Font = get_theme_font(&"font", &"HeadingLabel")
	for entry: Dictionary in entries:
		if not is_entry_visible(entry):
			continue
		var heavy: bool = bool(entry["heavy"])
		var font: Font = heading_font if heavy else body_font
		var font_size: int = HEAVY_FONT_SIZE if heavy else NORMAL_FONT_SIZE
		var text: String = str(entry["amount"])
		var age: float = float(entry["age"])
		var alpha: float = clampf((LIFETIME - age) / FADE_TIME, 0.0, 1.0) if age > LIFETIME - FADE_TIME else 1.0
		var color: Color = HEAVY_COLOR if heavy else NORMAL_COLOR
		color.a *= alpha
		var outline: Color = OUTLINE_COLOR
		outline.a *= alpha
		var pop_scale: float = 1.0
		if age < POP_TIME and (heavy or bool(entry["stacked"])):
			var peak: float = HEAVY_POP_SCALE if heavy else STACK_POP_SCALE
			pop_scale = lerpf(peak, 1.0, age / POP_TIME)
		var pos: Vector2 = entry_hud_position(entry).round()
		var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_set_transform(pos, 0.0, Vector2(pop_scale, pop_scale))
		var draw_pos: Vector2 = Vector2(-text_width * 0.5, -HEAD_OFFSET)
		draw_string_outline(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, OUTLINE_SIZE, outline)
		draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	draw_set_transform(Vector2.ZERO)
