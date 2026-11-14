class_name Shielder
extends Enemy
## PLACEHOLDER shielder (Pride): turns slowly toward the angel and blocks every blow that comes
## from inside its front cone. A finisher or evolved strike (a heavy hit) breaks the guard for a
## moment and lands; blows from the side or behind (a dash around it, Ricochet, Rain of Light)
## always land. Reuses the brute art, tinted steel in its scene, with a code-drawn shield arc;
## not an enemy design.

## PLACEHOLDER turn rate (radians per second), guard cone, and guard break.
const TURN_RATE: float = PI * 75.0 / 180.0
const GUARD_HALF_ANGLE: float = PI / 3.0
const BREAK_TIME: float = 1.5
const SHIELD_COLOR: Color = Color(0.75, 0.82, 0.9, 1.0)
## A blocked blow flashes the shield bright.
const BLOCK_COLOR: Color = Color(1.8, 1.8, 1.9, 1.0)
const BLOCK_FLASH: float = 0.12

var facing: Vector2 = Vector2.RIGHT
var broken_left: float = 0.0
var block_flash_left: float = 0.0


func _physics_process(delta: float) -> void:
	if health <= 0 or not is_instance_valid(target):
		return
	broken_left = maxf(0.0, broken_left - delta)
	block_flash_left = maxf(0.0, block_flash_left - delta)
	var to_target: Vector2 = target.global_position - global_position
	if not to_target.is_zero_approx():
		var turn: float = clampf(facing.angle_to(to_target), -TURN_RATE * delta, TURN_RATE * delta)
		facing = facing.rotated(turn)
	super(delta)
	queue_redraw()


## True when a blow from `from` meets the raised shield.
func guards_against(from: Vector2) -> bool:
	if broken_left > 0.0:
		return false
	var toward: Vector2 = from - global_position
	return not toward.is_zero_approx() and facing.dot(toward.normalized()) > cos(GUARD_HALF_ANGLE)


func take_hit(damage: int, heavy: bool = false, from: Vector2 = Vector2.INF) -> void:
	if health <= 0:
		return
	var source: Vector2 = from
	if source == Vector2.INF and is_instance_valid(target):
		source = target.global_position
	blocked_last = guards_against(source) and not heavy
	if blocked_last:
		# Blocked: a flash, sparks, and a sound (the run's), but no damage and no push.
		block_flash_left = BLOCK_FLASH
		damaged.emit(self, 0, false)
		return
	if guards_against(source):
		broken_left = BREAK_TIME
	super(damage, heavy, from)


func _draw() -> void:
	if broken_left > 0.0:
		return
	# PLACEHOLDER shield: an even-width arc across the guarded cone.
	var at: float = facing.angle()
	draw_arc(Vector2.ZERO, radius + 8.0, at - GUARD_HALF_ANGLE, at + GUARD_HALF_ANGLE, 16, Boss.BACKING, 6.0)
	draw_arc(Vector2.ZERO, radius + 8.0, at - GUARD_HALF_ANGLE, at + GUARD_HALF_ANGLE, 16, BLOCK_COLOR if block_flash_left > 0.0 else SHIELD_COLOR, 2.0)
