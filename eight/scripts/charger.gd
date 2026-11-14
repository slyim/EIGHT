class_name Charger
extends Enemy
## PLACEHOLDER charger (Wrath, Pride): chases, and once close it stops, shows an ember lane
## (a ground attack: step out, dash through, or fly over), dashes along it, then stands still
## for a moment the angel can punish. Reuses the brute art, tinted red in its scene; not an
## enemy design.

## PLACEHOLDER timings and reach.
const CHARGE_RANGE: float = 260.0
const WINDUP_TIME: float = 0.5
const DASH_TIME: float = 0.4
const RECOVER_TIME: float = 0.6
const DASH_SPEED: float = 560.0
## Seconds after its rest before it can wind up again, so a pack staggers its lanes.
const COOLDOWN_TIME: float = 1.0

var windup_left: float = 0.0
var dash_left: float = 0.0
var recover_left: float = 0.0
var cooldown_left: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
## How far the locked dash reaches before a wall or obstacle (what the lane shows).
var dash_length: float = 0.0


func _physics_process(delta: float) -> void:
	if health <= 0 or not is_instance_valid(target) or target.is_dead:
		return
	_tick_flash(delta)
	var to_target: Vector2 = target.global_position - global_position
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if windup_left > 0.0:
		# Committed: blows cannot shove it off the lane it showed.
		windup_left -= delta
		velocity = Vector2.ZERO
		knockback = Vector2.ZERO
		if windup_left <= 0.0:
			dash_left = DASH_TIME
		queue_redraw()
	elif dash_left > 0.0:
		dash_left -= delta
		velocity = dash_direction * DASH_SPEED
		knockback = Vector2.ZERO
		if dash_left <= 0.0:
			recover_left = RECOVER_TIME
			cooldown_left = RECOVER_TIME + COOLDOWN_TIME
	elif recover_left > 0.0:
		# The punish window: it stands, but a blow still pushes it.
		recover_left -= delta
		velocity = knockback
	else:
		velocity = to_target.normalized() * speed + knockback
		if cooldown_left <= 0.0 and to_target.length() <= CHARGE_RANGE and not target.is_descending():
			_start_windup(to_target.normalized())
	knockback = knockback.move_toward(Vector2.ZERO, 1400.0 * delta)
	move_and_slide()
	_face(dash_direction.x if dash_left > 0.0 or windup_left > 0.0 else to_target.x)
	_touch_player()


func _start_windup(direction: Vector2) -> void:
	dash_direction = direction
	dash_length = Boss.clear_distance(self, direction * DASH_SPEED * DASH_TIME)
	windup_left = WINDUP_TIME
	queue_redraw()


func _draw() -> void:
	if windup_left > 0.0:
		# Stepped fill (quarters), like the bosses' tells.
		var fill: float = floorf((1.0 - windup_left / WINDUP_TIME) * 4.0) / 4.0
		Boss.draw_lane(self, dash_direction, dash_length, radius, fill)
