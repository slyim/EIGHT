class_name MountedPlayer
extends CharacterBody2D
## Mounted hero controller: movement, dash, flight, three-hit light-spear and bow combos,
## and the descent from the sky that opens a run. Sprites and drawn effects
## (including the bow and arrows) are PLACEHOLDER art.

signal health_changed(current: int, maximum: int)
signal died
signal hurt
## step is 0 and 1 for thrusts, 2 for the sweeping finisher.
signal attack_started(step: int)
signal dashed
## Emitted when the angel leaves the ground.
signal jumped
## Emitted on touchdown.
signal landed
## Emitted when the winning ascension reaches the sky.
signal ascended
signal weapon_switched(weapon: Weapon)
## step is 0 and 1 for the opening shots, 2 for the finisher.
signal arrow_fired(step: int)

enum Weapon { SPEAR, BOW }
## Evolution paths (once per weapon per run); each changes that weapon's finisher.
enum SpearPath { NONE, WHIRLWIND, CHAIN_LIGHT }
enum BowPath { NONE, RICOCHET, RAIN }

const HURT_RADIUS: float = 20.0
const COMBO_LENGTH: int = 3
## Spear sprite length in world units (48 px art at 2x); the tip sits at spear_length.
const SPEAR_SPRITE_LENGTH: float = 96.0
const SPEAR_HEIGHT: float = 6.0
## Above this height the angel is airborne (see is_airborne).
const JUMP_CLEAR_HEIGHT: float = 12.0
## PLACEHOLDER feel: the gentle hover bob, in world units and seconds per cycle.
const FLIGHT_BOB_HEIGHT: float = 4.0
const FLIGHT_BOB_PERIOD: float = 1.0
## Spear layers on the ground (World, practice targets, enemies) and in the air (World and
## flying enemies on layer 5). Walls stop it either way.
const SPEAR_GROUND_MASK: int = 1 | 4 | 8
const SPEAR_AIR_MASK: int = 1 | 16
## Widest gap, at the spear tip, between the rays that find obstacles in the finisher's sweep.
const FINISHER_RAY_SPACING: float = 24.0
const SLASH_FRAMES: SpriteFrames = preload("res://assets/art/placeholder/placeholder_vfx_slash.aseprite")
const ARROW_SCENE: PackedScene = preload("res://scenes/arrow.tscn")
## PLACEHOLDER chain-light streak: bright, even-width, no antialiasing.
const CHAIN_COLOR: Color = Color(1.4, 1.9, 1.8, 1.0)
const CHAIN_TIME: float = 0.2

@export_group("Movement")
@export_range(80.0, 600.0, 10.0) var movement_speed: float = 260.0

@export_group("Spear")
@export_range(64.0, 240.0, 1.0) var spear_reach: float = 112.0
@export_range(0.1, 1.0, 0.01) var thrust_duration: float = 0.18
@export_range(0.1, 2.0, 0.01) var thrust_cooldown: float = 0.3
@export_range(1, 10, 1) var spear_damage: int = 1
## How many targets one thrust can pass through.
@export_range(1, 20, 1) var spear_pierce: int = 1
## Multiplies the knockback an enemy gives itself on a spear hit (bosses have none).
@export_range(0.0, 5.0, 0.1) var spear_knockback_scale: float = 1.4

@export_group("Combo")
## Seconds after an attack ends in which the next press continues the combo.
@export_range(0.05, 2.0, 0.01) var combo_window: float = 0.45
@export_range(0.1, 1.0, 0.01) var finisher_duration: float = 0.26
@export_range(0.1, 2.0, 0.01) var finisher_cooldown: float = 0.5
@export_range(1.0, 5.0, 0.1) var finisher_damage_multiplier: float = 2.0
@export_range(30.0, 300.0, 5.0) var finisher_arc_degrees: float = 140.0
@export_range(0.0, 5.0, 0.1) var finisher_knockback_scale: float = 2.0

@export_group("Bow")
## Three-shot combo on the spear's rhythm: shot, quicker shot, finisher. The finisher is a
## plain arrow until a weapon evolution changes it. PLACEHOLDER values.
## Seconds after a shot before the next; the second shot recovers faster.
@export_range(0.05, 2.0, 0.01) var bow_cooldown: float = 0.26
@export_range(0.05, 2.0, 0.01) var bow_finisher_cooldown: float = 0.45
@export_range(1, 20, 1) var bow_damage: int = 1
@export_range(40.0, 2000.0, 10.0) var bow_range: float = 520.0
## Targets one arrow passes through.
@export_range(1, 20, 1) var bow_pierce: int = 1
@export_range(200.0, 3000.0, 10.0) var arrow_speed: float = 950.0

@export_group("Evolution")
## PLACEHOLDER values for the evolved finishers.
## Chain Light: extra enemies the finisher's lightning jumps to, and how far each jump reaches.
@export_range(1, 10, 1) var chain_jumps: int = 3
@export_range(40.0, 600.0, 10.0) var chain_range: float = 200.0
## Ricochet: how many more enemies the finishing arrow bounces to, and how far it looks.
@export_range(1, 10, 1) var ricochet_bounces: int = 4
@export_range(40.0, 800.0, 10.0) var ricochet_range: float = 280.0
## Rain of Light: the circle's radius, the delay before it strikes, and its damage per bow damage.
@export_range(20.0, 400.0, 5.0) var rain_radius: float = 110.0
@export_range(0.0, 2.0, 0.05) var rain_delay: float = 0.35
@export_range(0.5, 5.0, 0.1) var rain_damage_multiplier: float = 2.0

@export_group("Feel")
## Seconds a dash, take-off, or attack press is remembered until it can fire.
@export_range(0.0, 0.5, 0.01) var input_buffer: float = 0.15
## Real-time seconds the game slows on a spear thrust hit, and on a finisher hit.
@export_range(0.0, 0.3, 0.005) var hit_stop: float = 0.045
@export_range(0.0, 0.3, 0.005) var finisher_hit_stop: float = 0.09
## Time scale during hit-stop (0 freezes completely).
@export_range(0.0, 1.0, 0.01) var hit_stop_time_scale: float = 0.05
@export_range(0.0, 20.0, 0.5) var hit_shake: float = 3.0
@export_range(0.0, 20.0, 0.5) var finisher_shake: float = 7.0

@export_group("Dash")
@export_range(200.0, 1600.0, 10.0) var dash_speed: float = 760.0
@export_range(0.05, 0.5, 0.01) var dash_duration: float = 0.16
@export_range(0.1, 3.0, 0.05) var dash_cooldown: float = 0.55

@export_group("Flight")
## Seconds of flight a full stamina meter holds. It drains whenever the angel is off the ground.
@export_range(0.5, 10.0, 0.1) var flight_time: float = 2.5
## Seconds of flight regained per second on the ground; refilling starts only after landing.
@export_range(0.05, 5.0, 0.05) var flight_refill_rate: float = 0.6
## Stamina (seconds) needed to take off, so tapping Space cannot dodge the meter.
@export_range(0.05, 5.0, 0.05) var flight_min_stamina: float = 0.5
## Seconds to climb from the ground to hover height. A take-off always finishes its climb,
## so a tap of Space is a short hop.
@export_range(0.05, 1.0, 0.01) var flight_rise_time: float = 0.2
## Seconds to glide back down from hover height.
@export_range(0.05, 1.0, 0.01) var flight_descend_time: float = 0.25
@export_range(16.0, 240.0, 2.0) var flight_height: float = 80.0
## Movement speed multiplier at hover height (blended in during the climb).
@export_range(0.25, 2.0, 0.05) var flight_speed_multiplier: float = 1.0

@export_group("Life")
@export_range(1, 500, 1) var max_health: int = 100
@export_range(0.1, 3.0, 0.05) var hurt_invulnerability: float = 1.0
@export_range(16.0, 600.0, 4.0) var pickup_radius: float = 90.0

var aim_direction: Vector2 = Vector2.RIGHT
## How far the mouse is from the angel (Rain of Light lands there, within bow range).
var aim_distance: float = 0.0
var spear_path: SpearPath = SpearPath.NONE
var bow_path: BowPath = BowPath.NONE
var mount_direction: Vector2 = Vector2.RIGHT
var thrust_direction: Vector2 = Vector2.RIGHT
var spear_direction: Vector2 = Vector2.RIGHT
var attack_time_left: float = 0.0
var attack_duration: float = 0.22
var attack_step: int = -1
var cooldown_left: float = 0.0
var combo_window_left: float = 0.0
var thrust_hits_left: int = 0
var finisher_resolved: bool = true
var spear_length: float = 56.0
var dash_direction: Vector2 = Vector2.RIGHT
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
## Climbing to or holding hover height: Space is held, or a take-off is still climbing.
var flying: bool = false
## 0 on the ground, 1 at hover height.
var lift: float = 0.0
## Seconds of flight left.
var flight_stamina: float = 0.0
## Seconds since take-off; drives the hover bob.
var hover_time: float = 0.0
## How far the sprite is drawn above the ground; the shadow and hit position stay put.
var height: float = 0.0
var descent_height: float = 0.0
var descent_duration: float = 0.0
var descent_left: float = 0.0
## The descent runs in reverse: the angel rises into the sky (the win ending).
var ascending: bool = false
var shake_left: float = 0.0
var shake_strength: float = 0.0
var health: int = 0
var invulnerable_left: float = 0.0
var is_dead: bool = false
var weapon: Weapon = Weapon.SPEAR
var attack_buffer_left: float = 0.0
var dash_buffer_left: float = 0.0
var jump_buffer_left: float = 0.0
## The current attack has already hit something (hit-stop and shake fire once per attack).
var attack_connected: bool = false
## The running hit-stop; only the latest one restores the time scale.
var hit_stop_timer: SceneTreeTimer

@onready var spear_cast: RayCast2D = $SpearCast
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var spear: AnimatedSprite2D = $Spear
@onready var bow: Node2D = $Bow
## PLACEHOLDER descent beam light: lights spaced up the beam, shown only while descending.
@onready var beam: Node2D = $Beam
@onready var lamp: PointLight2D = $Lamp
@onready var camera: Camera2D = $Camera2D
@onready var sprite_base: Vector2 = sprite.position


func _ready() -> void:
	health = max_health
	flight_stamina = flight_time
	bow.draw.connect(_draw_bow)


func _exit_tree() -> void:
	# Never leave the whole game slowed if the player is freed mid hit-stop.
	if hit_stop_timer != null:
		hit_stop_timer = null
		Engine.time_scale = 1.0


func _input(event: InputEvent) -> void:
	# Handled as events so a mouse-wheel tick (pressed and released at once) is never missed.
	if event.is_action_pressed(&"switch_weapon") and not is_dead and not is_descending():
		switch_weapon()


## Toggles spear and bow. Cancels any combo in progress; the recovery carries over.
func switch_weapon() -> void:
	weapon = Weapon.BOW if weapon == Weapon.SPEAR else Weapon.SPEAR
	attack_time_left = 0.0
	attack_step = -1
	combo_window_left = 0.0
	finisher_resolved = true
	attack_buffer_left = 0.0
	weapon_switched.emit(weapon)


## Takes an evolution path for a weapon (path 1 or 2; see SpearPath and BowPath).
func evolve(which: Weapon, path: int) -> void:
	if which == Weapon.SPEAR:
		spear_path = path as SpearPath
	else:
		bow_path = path as BowPath


func is_evolved(which: Weapon) -> bool:
	return (spear_path if which == Weapon.SPEAR else bow_path) != 0


## The finisher's sweep: a full spin once evolved into Whirlwind.
func finisher_arc() -> float:
	return 360.0 if spear_path == SpearPath.WHIRLWIND else finisher_arc_degrees


## Combo step of the current weapon (0..COMBO_LENGTH-1) while a combo is live, else -1.
func combo_step() -> int:
	return attack_step if attack_time_left > 0.0 or combo_window_left > 0.0 or cooldown_left > 0.0 else -1


## Opens a run: the angel falls from the sky and lands. Input waits until landing.
func begin_descent(from_height: float, duration: float) -> void:
	descent_height = from_height
	descent_duration = duration
	descent_left = duration
	flying = false
	lift = 0.0
	height = from_height


## Ends a won run: the angel rises in its beam. Input waits; ascended fires at the top.
func begin_ascent(to_height: float, duration: float) -> void:
	begin_descent(to_height, duration)
	ascending = true
	height = 0.0


## True while descending into the run or ascending out of it.
func is_descending() -> bool:
	return descent_left > 0.0


func _update_lamp() -> void:
	lamp.position = Vector2(0.0, -height)
	lamp.energy = 2.5 * lerpf(0.2, 1.0, pow(1.0 - clampf(height / 420.0, 0.0, 1.0), 2.0))


## True once the angel is high enough to clear ground things: ground attacks miss it and the
## spear reaches flying enemies instead of ground ones. The single source of truth for "in the air".
func is_airborne() -> bool:
	return height > JUMP_CLEAR_HEIGHT


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		if lift > 0.0:
			# A slain angel drops out of the sky.
			flying = false
			_move_flight(delta)
			sprite.position = sprite_base - Vector2(0.0, height)
			_update_lamp()
			queue_redraw()
		return
	if is_descending():
		descent_left = maxf(0.0, descent_left - delta)
		var t: float = 1.0 - descent_left / descent_duration
		height = descent_height * (t * t if ascending else 1.0 - t * t)
		if descent_left == 0.0:
			if ascending:
				set_physics_process(false)
				ascended.emit()
			else:
				height = 0.0
				_land(14.0)
		_update_visuals(Vector2.ZERO, delta)
		return
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	# Expire the dash before choosing this tick's movement, so every dash-speed
	# movement tick also retains its dash invulnerability.
	dash_time_left = maxf(0.0, dash_time_left - delta)
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	dash_buffer_left = input_buffer if Input.is_action_just_pressed(&"dash") else maxf(0.0, dash_buffer_left - delta)
	jump_buffer_left = input_buffer if Input.is_action_just_pressed(&"jump") else maxf(0.0, jump_buffer_left - delta)
	attack_buffer_left = input_buffer if Input.is_action_just_pressed(&"attack") else maxf(0.0, attack_buffer_left - delta)

	var movement: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	var mouse_offset: Vector2 = get_global_mouse_position() - global_position
	aim_distance = mouse_offset.length()
	if not mouse_offset.is_zero_approx():
		aim_direction = mouse_offset.normalized()

	_update_flight(delta)
	if dash_buffer_left > 0.0 and dash_cooldown_left <= 0.0 and dash_time_left <= 0.0:
		dash_buffer_left = 0.0
		dash_direction = movement.normalized() if not movement.is_zero_approx() else aim_direction
		dash_time_left = dash_duration
		dash_cooldown_left = dash_duration + dash_cooldown
		dashed.emit()

	if dash_time_left > 0.0:
		velocity = dash_direction * dash_speed
	else:
		velocity = movement * movement_speed * lerpf(1.0, flight_speed_multiplier, lift)
	move_and_slide()
	if not movement.is_zero_approx():
		mount_direction = movement.normalized()

	_update_attack(delta)
	_update_visuals(movement, delta)


## Hold Space to take off and hover. Releasing it (once the climb is done) or running out of
## stamina brings the angel down; a press while gliding down climbs again if stamina allows.
func _update_flight(delta: float) -> void:
	if flying:
		# A press while flying is spent here, so it cannot relaunch the angel after landing.
		jump_buffer_left = 0.0
		if flight_stamina <= 0.0 or (lift >= 1.0 and not Input.is_action_pressed(&"jump")):
			flying = false
	elif jump_buffer_left > 0.0 and flight_stamina >= flight_min_stamina:
		jump_buffer_left = 0.0
		flying = true
		if lift == 0.0:
			hover_time = 0.0
			jumped.emit()
	_move_flight(delta)


## Climbs toward hover height or glides to the ground, draining stamina while off the ground.
## Stamina refills only once landed. Leaves height alone while grounded.
func _move_flight(delta: float) -> void:
	if lift == 0.0 and not flying:
		flight_stamina = minf(flight_time, flight_stamina + flight_refill_rate * delta)
		return
	lift = move_toward(lift, 1.0 if flying else 0.0, delta / (flight_rise_time if flying else flight_descend_time))
	flight_stamina = maxf(0.0, flight_stamina - delta)
	if lift == 0.0:
		height = 0.0
		_land(4.0)
		return
	hover_time += delta
	# Eases out on the climb and in on the way down; the bob fades in with height.
	var bob: float = sin(hover_time * TAU / FLIGHT_BOB_PERIOD) * FLIGHT_BOB_HEIGHT * lift
	height = flight_height * (1.0 - (1.0 - lift) * (1.0 - lift)) + bob


func _land(shake: float) -> void:
	_shake(shake)
	landed.emit()


## Starts a camera shake without cutting short a stronger one already running.
func _shake(strength: float) -> void:
	shake_strength = maxf(strength, shake_strength * shake_left / 0.25)
	shake_left = 0.25


## One hit-stop and shake per attack, on its first connecting hit.
func _on_attack_connected(finisher: bool) -> void:
	if attack_connected:
		return
	attack_connected = true
	_shake(finisher_shake if finisher else hit_shake)
	var duration: float = finisher_hit_stop if finisher else hit_stop
	if duration <= 0.0:
		return
	if hit_stop_timer != null and hit_stop_timer.time_left >= duration:
		return
	Engine.time_scale = hit_stop_time_scale
	var timer: SceneTreeTimer = get_tree().create_timer(duration, true, false, true)
	hit_stop_timer = timer
	# Bind the id, not the timer, so the timer does not keep itself alive.
	timer.timeout.connect(_end_hit_stop.bind(timer.get_instance_id()))


func _end_hit_stop(timer_id: int) -> void:
	if hit_stop_timer != null and hit_stop_timer.get_instance_id() == timer_id:
		hit_stop_timer = null
		Engine.time_scale = 1.0


## Scales the knockback the enemy just gave itself in take_hit.
func _push(collider: Object, scale: float) -> void:
	var enemy: Enemy = collider as Enemy
	if enemy != null:
		enemy.knockback *= scale


func _update_attack(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	combo_window_left = maxf(0.0, combo_window_left - delta)
	# The spear strikes what shares the angel's level: flying enemies in the air, the rest on the ground.
	spear_cast.collision_mask = SPEAR_AIR_MASK if is_airborne() else SPEAR_GROUND_MASK
	if weapon == Weapon.BOW:
		_update_bow()
		return
	var wants_attack: bool = Input.is_action_pressed(&"attack") or attack_buffer_left > 0.0
	if wants_attack and cooldown_left <= 0.0 and attack_time_left <= 0.0:
		attack_buffer_left = 0.0
		attack_connected = false
		attack_step = (attack_step + 1) % COMBO_LENGTH if combo_window_left > 0.0 else 0
		thrust_direction = aim_direction
		if attack_step == COMBO_LENGTH - 1:
			attack_duration = finisher_duration
			cooldown_left = finisher_cooldown
			finisher_resolved = false
			_spawn_slash()
		else:
			attack_duration = thrust_duration
			# The second thrust follows faster than the first.
			cooldown_left = thrust_cooldown * (0.8 if attack_step == 1 else 1.0)
			thrust_hits_left = spear_pierce
			spear_cast.clear_exceptions()
		attack_time_left = attack_duration
		attack_started.emit(attack_step)

	var resting_length: float = spear_reach * 0.5
	spear_length = resting_length
	spear_direction = aim_direction
	if attack_time_left <= 0.0:
		return
	attack_time_left = maxf(0.0, attack_time_left - delta)
	var progress: float = 1.0 - attack_time_left / attack_duration
	if attack_step == COMBO_LENGTH - 1:
		var half: float = deg_to_rad(finisher_arc()) * 0.5
		spear_length = spear_reach * 0.9
		spear_direction = thrust_direction.rotated(lerpf(-half, half, progress))
		if not finisher_resolved and progress >= 0.35:
			finisher_resolved = true
			_resolve_finisher()
	else:
		spear_length = lerpf(resting_length, spear_reach, sin(progress * PI))
		spear_direction = thrust_direction
		spear_cast.rotation = thrust_direction.angle()
		spear_cast.target_position = Vector2(spear_length, 0.0)
		_resolve_spear_hits()
	if attack_time_left == 0.0:
		combo_window_left = combo_window if attack_step < COMBO_LENGTH - 1 else 0.0


## Same input and timing rules as the spear: press or hold attack; a press within
## combo_window of the last shot's recovery continues the combo.
func _update_bow() -> void:
	var wants_attack: bool = Input.is_action_pressed(&"attack") or attack_buffer_left > 0.0
	if not wants_attack or cooldown_left > 0.0:
		return
	attack_buffer_left = 0.0
	attack_step = (attack_step + 1) % COMBO_LENGTH if combo_window_left > 0.0 else 0
	if attack_step == COMBO_LENGTH - 1 and bow_path == BowPath.RAIN:
		call_rain()
	else:
		fire_arrow(attack_step)
	if attack_step == COMBO_LENGTH - 1:
		cooldown_left = bow_finisher_cooldown
		combo_window_left = 0.0
	else:
		cooldown_left = bow_cooldown * (0.8 if attack_step == 1 else 1.0)
		combo_window_left = cooldown_left + combo_window


## Fires one arrow toward the aim. The finishing arrow of a Ricochet bow bounces on.
func fire_arrow(step: int = 0) -> Arrow:
	var arrow: Arrow = ARROW_SCENE.instantiate() as Arrow
	arrow.direction = aim_direction
	arrow.speed = arrow_speed
	arrow.damage = bow_damage
	arrow.range_left = bow_range
	arrow.pierce = bow_pierce
	if step == COMBO_LENGTH - 1 and bow_path == BowPath.RICOCHET:
		arrow.bounces = ricochet_bounces
		arrow.bounce_range = ricochet_range
	arrow.height = SPEAR_HEIGHT + height
	arrow.position = global_position
	get_parent().add_child(arrow)
	arrow_fired.emit(step)
	return arrow


## Rain of Light: the finishing shot marks the aim point (within bow range) and light falls there.
func call_rain() -> LightRain:
	var rain: LightRain = LightRain.new()
	rain.radius = rain_radius
	rain.delay = rain_delay
	rain.damage = maxi(1, roundi(bow_damage * rain_damage_multiplier))
	rain.position = global_position + aim_direction * minf(aim_distance, bow_range)
	get_parent().add_child(rain)
	arrow_fired.emit(COMBO_LENGTH - 1)
	return rain


## Each target is hit at most once per thrust; walls stop the spear. A breakable obstacle
## takes one blow and stops it too, which spends the thrust.
func _resolve_spear_hits() -> void:
	# ponytail: centerline hits only; use ShapeCast2D if spear width is needed.
	spear_cast.force_raycast_update()
	while thrust_hits_left > 0 and spear_cast.is_colliding():
		var collider: Object = spear_cast.get_collider()
		if not collider.has_method(&"take_hit"):
			if collider is Breakable:
				(collider as Breakable).take_blow(spear_damage)
				_on_attack_connected(false)
				thrust_hits_left = 0
			return
		collider.call(&"take_hit", spear_damage)
		_push(collider, spear_knockback_scale)
		_on_attack_connected(false)
		thrust_hits_left -= 1
		spear_cast.add_exception(collider as CollisionObject2D)
		spear_cast.force_raycast_update()


## The finisher strikes every target inside its arc once, unless a wall or obstacle is in
## the way, then deals one blow to each breakable obstacle its sweep touches. Targets are
## struck first, so the blow that breaks an obstacle does not reach what it was shielding.
func _resolve_finisher() -> void:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = spear_reach
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = spear_cast.collision_mask & ~1
	query.exclude = [get_rid()]
	var half: float = deg_to_rad(finisher_arc()) * 0.5
	var damage: int = maxi(1, roundi(spear_damage * finisher_damage_multiplier))
	var struck_targets: Array[Node2D] = []
	for result: Dictionary in space.intersect_shape(query, 128):
		var collider: Node2D = result["collider"] as Node2D
		if collider == null or not collider.has_method(&"take_hit"):
			continue
		var offset: Vector2 = collider.global_position - global_position
		# A full spin (Whirlwind) takes everything around; skip the angle test, whose edge is
		# exactly behind the angel and would drop targets there to float rounding.
		if finisher_arc() < 360.0 and offset.length() > 24.0 and absf(thrust_direction.angle_to(offset)) > half:
			continue
		var line_of_sight: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			global_position, collider.global_position, 1
		)
		if not space.intersect_ray(line_of_sight).is_empty():
			continue
		collider.call(&"take_hit", damage)
		_push(collider, finisher_knockback_scale)
		_on_attack_connected(true)
		struck_targets.append(collider)
	if spear_path == SpearPath.CHAIN_LIGHT and not struck_targets.is_empty():
		_chain_light(struck_targets, damage)
	# Sample the sweep with rays no further apart at the tip than FINISHER_RAY_SPACING.
	var rays: int = 2 + ceili(spear_reach * half * 2.0 / FINISHER_RAY_SPACING)
	var struck: Array[Breakable] = []
	for index: int in range(rays):
		var reach: Vector2 = thrust_direction.rotated(lerpf(-half, half, float(index) / (rays - 1))) * spear_reach
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + reach, 1))
		var obstacle: Breakable = hit.get("collider") as Breakable
		if obstacle != null and not struck.has(obstacle):
			struck.append(obstacle)
	for obstacle: Breakable in struck:
		obstacle.take_blow(damage)
		_on_attack_connected(true)


## Chain Light: lightning jumps from the last struck enemy to the nearest unstruck one in
## range, chain_jumps times, at the angel's level; each jump deals the finisher's damage.
func _chain_light(struck_targets: Array[Node2D], damage: int) -> void:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = chain_range
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.collision_mask = spear_cast.collision_mask & ~1
	var hit: Array[Node2D] = struck_targets.duplicate()
	var from: Node2D = struck_targets[0]
	var points: PackedVector2Array = [from.global_position]
	for jump: int in range(chain_jumps):
		query.transform = Transform2D(0.0, from.global_position)
		var next: Node2D = null
		for result: Dictionary in space.intersect_shape(query, 64):
			var collider: Node2D = result["collider"] as Node2D
			if collider == null or not collider.has_method(&"take_hit") or hit.has(collider):
				continue
			# Lightning does not jump through walls or standing obstacles.
			if not space.intersect_ray(PhysicsRayQueryParameters2D.create(from.global_position, collider.global_position, 1)).is_empty():
				continue
			if next == null or from.global_position.distance_to(collider.global_position) < from.global_position.distance_to(next.global_position):
				next = collider
		if next == null:
			break
		next.call(&"take_hit", damage)
		hit.append(next)
		points.append(next.global_position)
		from = next
	if points.size() > 1:
		_spawn_chain(points)


## PLACEHOLDER lightning: a jagged line through the chain that fades out.
func _spawn_chain(points: PackedVector2Array) -> void:
	var line: Line2D = Line2D.new()
	line.width = 2.0
	line.default_color = CHAIN_COLOR
	line.antialiased = false
	for index: int in range(points.size() - 1):
		var from: Vector2 = points[index]
		var to: Vector2 = points[index + 1]
		line.add_point(from)
		# A kink midway, on whole art pixels.
		var kink: Vector2 = (from + to) * 0.5 + (to - from).orthogonal().normalized() * 12.0 * (1.0 if index % 2 == 0 else -1.0)
		line.add_point((kink / 2.0).round() * 2.0)
	line.add_point(points[points.size() - 1])
	get_parent().add_child(line)
	var tween: Tween = line.create_tween()
	tween.tween_property(line, ^"modulate:a", 0.0, CHAIN_TIME)
	tween.tween_callback(line.queue_free)


func _spawn_slash() -> void:
	# Whirlwind spins all the way round, so its slash shows on three sides.
	var turns: int = 3 if spear_path == SpearPath.WHIRLWIND else 1
	for turn: int in range(turns):
		var arc: AnimatedSprite2D = AnimatedSprite2D.new()
		arc.sprite_frames = SLASH_FRAMES
		arc.position = Vector2(0.0, -SPEAR_HEIGHT - height)
		arc.rotation = thrust_direction.angle() + TAU * turn / turns
		# Always 2x so every art pixel matches; a longer reach does not stretch the art.
		arc.scale = Vector2(2.0, 2.0)
		arc.animation_finished.connect(arc.queue_free)
		add_child(arc)
		arc.play(&"slash")


func _update_visuals(movement: Vector2, delta: float) -> void:
	var animation: StringName = &"idle"
	if is_descending():
		animation = &"descend"
	elif dash_time_left > 0.0:
		animation = &"dash"
	elif height > 0.0:
		# Wings raised on the climb; spread and beating while hovering or gliding down.
		animation = &"jump" if flying and lift < 1.0 else &"descend"
	elif not movement.is_zero_approx():
		animation = &"run"
	if sprite.animation != animation:
		sprite.play(animation)
	# The art faces right; mirror it while the mount heads left.
	if absf(mount_direction.x) > 0.01:
		sprite.flip_h = mount_direction.x < 0.0
	sprite.position = sprite_base - Vector2(0.0, height)
	_update_lamp()

	beam.visible = is_descending()
	spear.visible = not is_descending() and weapon == Weapon.SPEAR
	bow.visible = not is_descending() and weapon == Weapon.BOW
	bow.position = Vector2(0.0, -SPEAR_HEIGHT - height)
	bow.rotation = aim_direction.angle()
	bow.queue_redraw()
	spear.rotation = spear_direction.angle()
	spear.position = Vector2(0.0, -SPEAR_HEIGHT - height) + spear_direction * (spear_length - SPEAR_SPRITE_LENGTH)

	shake_left = maxf(0.0, shake_left - delta)
	var strength: float = shake_strength * shake_left / 0.25
	camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
	# Whole screen pixels keep the world-locked light cells and dither from swimming.
	camera.force_update_scroll()
	var parent: CanvasItem = get_parent() as CanvasItem
	var parent_canvas: Transform2D = parent.get_global_transform_with_canvas() if parent != null else get_canvas_transform()
	var screen_transform: Transform2D = get_viewport().get_final_transform() * parent_canvas
	camera.offset += (screen_transform.origin - screen_transform.origin.round()) / screen_transform.get_scale()

	var blink: bool = invulnerable_left > 0.0 and int(invulnerable_left * 16.0) % 2 == 0
	modulate.a = 0.35 if blink else 1.0
	queue_redraw()


## True while ground attacks cannot land. Attacks from the air (see take_damage) still
## reach an airborne player.
func is_invulnerable() -> bool:
	return invulnerable_left > 0.0 or dash_time_left > 0.0 or is_airborne() or is_descending()


## Returns true when the damage landed.
## Ground attacks miss an airborne player; attacks from the air (from_air) reach the player at any height.
func take_damage(amount: int, from_air: bool = false) -> bool:
	if is_dead or amount <= 0 or is_descending() or invulnerable_left > 0.0 or dash_time_left > 0.0:
		return false
	if is_airborne() and not from_air:
		return false
	health = maxi(0, health - amount)
	invulnerable_left = hurt_invulnerability
	health_changed.emit(health, max_health)
	hurt.emit()
	if health == 0:
		_die()
	return true


## Dies at once whatever protects the angel (the shrine countdown running out).
func kill() -> void:
	if is_dead:
		return
	health = 0
	health_changed.emit(health, max_health)
	_die()


func _die() -> void:
	is_dead = true
	modulate = Color(0.45, 0.45, 0.45, 1.0)
	sprite.stop()
	spear.visible = false
	bow.visible = false
	died.emit()


func heal(amount: int) -> void:
	if is_dead:
		return
	health = mini(max_health, health + maxi(0, amount))
	health_changed.emit(health, max_health)


func _draw() -> void:
	# PLACEHOLDER ground shadow (stays on the ground and shrinks as the angel rises) and the
	# descent light beam.
	var shrink: float = clampf(1.0 - height / 160.0, 0.35, 1.0)
	draw_set_transform(Vector2(0.0, 14.0), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 22.0 * shrink, Color(0.0275, 0.0039, 0.0353, 0.75))
	draw_set_transform(Vector2.ZERO)
	if is_descending():
		var glow: float = 1.0 - descent_left / descent_duration
		draw_rect(Rect2(-14.0, -900.0, 28.0, 914.0), Color(0.792, 0.922, 0.878, 0.12 + 0.18 * glow))
		draw_rect(Rect2(-5.0, -900.0, 10.0, 914.0), Color(1.5, 1.9, 1.75, 0.28 + 0.35 * glow))


func _draw_bow() -> void:
	# PLACEHOLDER bow, drawn in the Bow node's space (+x is the aim): a light arc, its string,
	# and a nocked arrow once the next shot is ready. Widths are whole art pixels (2 units).
	var color: Color = Arrow.COLOR
	var grip: Vector2 = Vector2(30.0, 0.0)
	var tip_top: Vector2 = grip + Vector2(-10.0, -18.0)
	var tip_bottom: Vector2 = grip + Vector2(-10.0, 18.0)
	bow.draw_polyline(PackedVector2Array([tip_top, grip + Vector2(-2.0, -10.0), grip, grip + Vector2(-2.0, 10.0), tip_bottom]), color, 4.0)
	var nock: Vector2 = grip + Vector2(-10.0, 0.0)
	bow.draw_polyline(PackedVector2Array([tip_top, nock, tip_bottom]), color, 2.0)
	if cooldown_left <= 0.0:
		bow.draw_line(nock, nock + Vector2(Arrow.LENGTH, 0.0), color, 2.0)


## PLACEHOLDER lava burn: ground damage on the lava's own rhythm. Guards and death
## handling mirror take_damage, but burn never starts or extends hurt invulnerability:
## its ticks cannot be swallowed by their own window, lava cannot shield from enemies,
## and an in-progress hurt-blink delays a tick instead.
func apply_burn(amount: int) -> bool:
	if is_dead or amount <= 0 or is_descending() or invulnerable_left > 0.0 or dash_time_left > 0.0 or is_airborne():
		return false
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	hurt.emit()
	if health == 0:
		_die()
	return true
