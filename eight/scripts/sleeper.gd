class_name Sleeper
extends Enemy
## PLACEHOLDER sleeper (Sloth): sits still until the angel comes close or strikes it, then a
## ring shows and it wakes fast. Awake, it pulses a slowing ring every few seconds: an ember
## circle fills, and if the angel is inside and on the ground when it lands, the angel is
## slowed for a moment (fly over it or dash out). Reuses the husk art, tinted grey-blue in its
## scene; not an enemy design.

## PLACEHOLDER waking, speed, and slowing pulse.
const WAKE_RANGE: float = 150.0
const WAKE_TIME: float = 0.4
const AWAKE_SPEED: float = 1.45
const PULSE_INTERVAL: float = 3.8
const PULSE_TELL: float = 0.75
const PULSE_RADIUS: float = 110.0
const SLOW_FACTOR: float = 0.68
const SLOW_TIME: float = 1.2
const WAKE_COLOR: Color = Color(0.75, 0.82, 0.9, 1.0)

var awake: bool = false
## Seconds left of the waking ring; it moves only once fully awake.
var waking_left: float = 0.0
var pulse_left: float = PULSE_INTERVAL
var tell_left: float = 0.0


func _physics_process(delta: float) -> void:
	if health <= 0 or not is_instance_valid(target) or target.is_dead:
		return
	if not awake:
		_tick_flash(delta)
		if global_position.distance_to(target.global_position) <= WAKE_RANGE:
			wake()
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, 1400.0 * delta)
		move_and_slide()
		return
	if waking_left > 0.0:
		_tick_flash(delta)
		waking_left -= delta
		queue_redraw()
		return
	if tell_left > 0.0:
		tell_left -= delta
		if tell_left <= 0.0:
			if global_position.distance_to(target.global_position) <= PULSE_RADIUS + MountedPlayer.HURT_RADIUS:
				target.apply_slow(SLOW_FACTOR, SLOW_TIME)
			pulse_left = PULSE_INTERVAL
		queue_redraw()
	else:
		pulse_left -= delta
		if pulse_left <= 0.0:
			tell_left = PULSE_TELL
	super(delta)


## Starts the waking ring (once).
func wake() -> void:
	if awake:
		return
	awake = true
	waking_left = WAKE_TIME
	speed *= AWAKE_SPEED
	queue_redraw()


func take_hit(damage: int, heavy: bool = false, from: Vector2 = Vector2.INF) -> void:
	super(damage, heavy, from)
	wake()


func _draw() -> void:
	if waking_left > 0.0:
		var grow: float = 1.0 - waking_left / WAKE_TIME
		draw_arc(Vector2.ZERO, radius + 6.0 + 24.0 * floorf(grow * 4.0) / 4.0, 0.0, TAU, 24, Boss.BACKING, 6.0)
		draw_arc(Vector2.ZERO, radius + 6.0 + 24.0 * floorf(grow * 4.0) / 4.0, 0.0, TAU, 24, WAKE_COLOR, 2.0)
	elif tell_left > 0.0:
		Boss.draw_circle_tell(self, PULSE_RADIUS, floorf((1.0 - tell_left / PULSE_TELL) * 4.0) / 4.0)
