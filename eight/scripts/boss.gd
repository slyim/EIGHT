class_name Boss
extends Enemy
## PLACEHOLDER boss: a generic attack-pattern mix standing in for an undesigned
## sin or Satan encounter. Patterns only make the bosses distinguishable for testing.
## Every attack is fair: a wind-up shows where it will land (ember = a ground attack, fly over
## or dash through it), then the boss stands in a short recovery the angel can punish. Bosses
## only start attacks while the angel is on screen and able to fight, and grow faster at each
## health threshold (phase).

signal summon_requested(boss: Boss, count: int)
signal attacked(boss: Boss)
signal phase_changed(boss: Boss)

enum Pattern { CHARGE, BURST, AIMED, SUMMON }

const CHARGE_TIME: float = 0.55
const PROJECTILE_SPEED: float = 260.0
const ATTACK_POSE_TIME: float = 0.5
## PLACEHOLDER wind-up per pattern (seconds the telegraph shows before the attack lands).
const WINDUPS: Array[float] = [0.6, 0.55, 0.5, 0.4]
## PLACEHOLDER seconds the boss stands still after each pattern. A charge ends far from the
## angel, so it rests longer: long enough to walk back into spear reach.
const RECOVERIES: Array[float] = [0.8, 0.5, 0.5, 0.5]
## PLACEHOLDER: each phase multiplies the attack interval by this.
const PHASE_PACE: float = 0.75
## Attacks start only while the angel is this close on each axis (the view is 1280x720 world units).
const ON_SCREEN: Vector2 = Vector2(600.0, 330.0)
## Smarts at which aimed fans lead the angel's movement, and how far (a fraction of the full
## lead, so turning during the wind-up still clears the fan on foot). PLACEHOLDER.
const LEAD_SMARTS: int = 2
const LEAD_FACTOR: float = 0.6
const BURST_SHOTS: int = 12
const AIMED_SPREAD: float = 0.22
const SUMMON_COUNT: int = 4
## Ground attacks (the angel can fly over them or dash through).
const EMBER: Color = Color(1.6, 0.62, 0.22, 1.0)
## The charge lane's fill: dim, not HDR, so it reads as ground and does not bloom into a slab.
const EMBER_FILL: Color = Color(0.7, 0.24, 0.1, 0.22)
## Dark backing under every telegraph line, so ember stays readable over molten lava.
const BACKING: Color = Color(0.0275, 0.0039, 0.0353, 0.85)
const SUMMON_MARK: Color = Color(0.85, 0.8, 0.7, 1.0)
const TELEGRAPH_LIGHT: Color = Color(1.0, 0.5, 0.2, 0.35)

var boss_name: String = "BOSS"
var patterns: Array[int] = []
var attack_interval: float = 2.5
var attack_left: float = 2.0
var windup_left: float = 0.0
## The pattern being wound up, released when windup_left runs out.
var pending: int = -1
var charge_left: float = 0.0
var charge_direction: Vector2 = Vector2.RIGHT
## How far the locked charge can go before a wall or obstacle stops it (what the lane shows).
var charge_length: float = 0.0
## Where a pending summon's minions will appear (world positions), chosen by the run when the
## wind-up starts so the marks are exact; empty means around the boss.
var summon_spots: Array[Vector2] = []
var recover_left: float = 0.0
var attack_pose_left: float = 0.0
## Damage of each BURST/AIMED shot; scaled by the run with the tier and the clock.
var shot_damage: int = 12
## Fractions of max health; crossing each one starts the next phase. PLACEHOLDER.
var phase_thresholds: Array[float] = [0.5]
## 1 at full health, +1 per threshold crossed.
var phase: int = 1
## Set from the difficulty tier (0 = Penance); higher tiers lead their aim.
var smarts: int = 0
## Guards only: they fight while the target is within leash of home, otherwise walk back.
## 0 means no leash.
var home: Vector2 = Vector2.ZERO
var leash: float = 0.0


func _ready() -> void:
	super()
	set_meta(&"light", TELEGRAPH_LIGHT)
	set_meta(&"light_radius", 180.0)
	hit.connect(_check_phase.unbind(1))


func _base_animation() -> StringName:
	return &"idle"


func charge_speed() -> float:
	return maxf(speed * 4.0, 420.0)


## The angel can be attacked fairly: on screen, alive, and not descending or ascending.
func can_attack() -> bool:
	var offset: Vector2 = (target.global_position - global_position).abs()
	return offset.x <= ON_SCREEN.x and offset.y <= ON_SCREEN.y and not target.is_dead and not target.is_descending()


func _physics_process(delta: float) -> void:
	if health <= 0 or not is_instance_valid(target):
		return
	_tick_flash(delta)
	attack_pose_left = maxf(0.0, attack_pose_left - delta)
	var leashed: bool = leash > 0.0 and target.global_position.distance_to(home) > leash
	if leashed and (windup_left > 0.0 or charge_left > 0.0):
		_cancel()
	if recover_left > 0.0:
		# The punish window holds even if the angel leaves a guard's leash.
		recover_left -= delta
		velocity = Vector2.ZERO
	elif leashed:
		var to_home: Vector2 = home - global_position
		velocity = to_home.normalized() * speed if to_home.length() > speed * delta * 2.0 else Vector2.ZERO
	elif windup_left > 0.0:
		windup_left -= delta
		velocity = Vector2.ZERO
		if windup_left <= 0.0:
			var released: int = pending
			windup_left = 0.0
			pending = -1
			remove_from_group(&"light")
			_attack(released)
			if charge_left <= 0.0:
				recover_left = RECOVERIES[released]
		queue_redraw()
	elif charge_left > 0.0:
		charge_left -= delta
		velocity = charge_direction * charge_speed()
		if charge_left <= 0.0:
			recover_left = RECOVERIES[Pattern.CHARGE]
	else:
		velocity = (target.global_position - global_position).normalized() * speed
		if can_attack():
			attack_left -= delta
			if attack_left <= 0.0 and not patterns.is_empty():
				attack_left = attack_interval
				start_attack(patterns.pick_random())
	move_and_slide()
	_face(target.global_position.x - global_position.x)
	var attacking: bool = windup_left > 0.0 or charge_left > 0.0 or attack_pose_left > 0.0
	var animation: StringName = &"attack" if attacking else &"idle"
	if sprite.sprite_frames != null and sprite.animation != animation:
		sprite.play(animation)
	_touch_player()


## Begins a wind-up: the attack's telegraph shows (aim locked now) until it lands.
func start_attack(pattern: int) -> void:
	pending = pattern
	windup_left = WINDUPS[pattern]
	charge_direction = _aim(pattern)
	charge_length = clear_distance(self, charge_direction * charge_speed() * CHARGE_TIME) if pattern == Pattern.CHARGE else 0.0
	summon_spots.clear()
	attack_pose_left = ATTACK_POSE_TIME + windup_left
	# Only ground attacks cast the ember light; a summon's marks keep their own color.
	if pattern != Pattern.SUMMON:
		add_to_group(&"light")
	attacked.emit(self)
	queue_redraw()


func _cancel() -> void:
	windup_left = 0.0
	charge_left = 0.0
	pending = -1
	remove_from_group(&"light")
	queue_redraw()


## Where an attack goes: at the angel, or (smarter bosses' aimed fans) partly toward where the
## angel will be when the shots arrive.
func _aim(pattern: int) -> Vector2:
	var at: Vector2 = target.global_position
	if smarts >= LEAD_SMARTS and pattern == Pattern.AIMED:
		var arrival: float = WINDUPS[pattern] + global_position.distance_to(at) / PROJECTILE_SPEED
		at += target.velocity * minf(arrival, 1.5) * LEAD_FACTOR
	var direction: Vector2 = at - global_position
	return direction.normalized() if direction.length() > 0.01 else Vector2.RIGHT


## How far an enemy's body can travel along motion before walls or obstacles stop it (what a
## charge lane shows).
static func clear_distance(body: Enemy, motion: Vector2) -> float:
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = body.collision_shape.shape
	query.transform = Transform2D(0.0, body.global_position)
	query.motion = motion
	query.collision_mask = body.collision_mask
	query.exclude = [body.get_rid()]
	var safe: float = body.get_world_2d().direct_space_state.cast_motion(query)[0]
	return motion.length() * safe


## Lands an attack in the locked direction (charge_direction).
func _attack(pattern: int) -> void:
	match pattern:
		Pattern.CHARGE:
			charge_left = CHARGE_TIME
		Pattern.BURST:
			for index: int in range(BURST_SHOTS):
				_fire(Vector2.RIGHT.rotated(TAU * index / BURST_SHOTS))
		Pattern.AIMED:
			for index: int in range(-2, 3):
				_fire(charge_direction.rotated(index * AIMED_SPREAD))
		Pattern.SUMMON:
			summon_requested.emit(self, SUMMON_COUNT)


func _check_phase() -> void:
	while phase - 1 < phase_thresholds.size() and health > 0 and health <= max_health * phase_thresholds[phase - 1]:
		phase += 1
		attack_interval *= PHASE_PACE
		attack_left = minf(attack_left, attack_interval)
		phase_changed.emit(self)


func _fire(direction: Vector2) -> void:
	var projectile: EnemyProjectile = EnemyProjectile.new()
	projectile.velocity = direction * PROJECTILE_SPEED
	projectile.damage = shot_damage
	projectile.target = target
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction * radius


## Stepped fill (quarters), so the telegraph grows in pixel-sized beats.
func windup_progress() -> float:
	if pending < 0:
		return 0.0
	return floorf((1.0 - windup_left / WINDUPS[pending]) * 4.0) / 4.0


## Where the minions of a summon appear, relative to the boss.
func summon_offsets() -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	for index: int in range(SUMMON_COUNT):
		offsets.append(summon_spots[index] - global_position if index < summon_spots.size() else Vector2.RIGHT.rotated(TAU * index / SUMMON_COUNT) * (radius + 30.0))
	return offsets


## A telegraph line on a dark backing (even widths, no antialiasing).
static func draw_tell(item: CanvasItem, from: Vector2, to: Vector2, color: Color) -> void:
	item.draw_line(from, to, BACKING, 6.0)
	item.draw_line(from, to, color, 2.0)


## A charge lane: edges and an end cap, as wide as the body, filling toward the end.
static func draw_lane(item: CanvasItem, direction: Vector2, length: float, half_width: float, fill: float) -> void:
	var side: Vector2 = direction.orthogonal() * half_width
	var tip: Vector2 = direction * length
	item.draw_line(Vector2.ZERO, tip * fill, EMBER_FILL, half_width * 2.0)
	for edge: Vector2 in [side, -side]:
		draw_tell(item, edge, edge + tip, Color(EMBER, 0.8))
	draw_tell(item, tip + side, tip - side, Color(EMBER, 0.8))


## A ground circle about to strike: a dark-backed ember ring and a stepped fill.
static func draw_circle_tell(item: CanvasItem, radius: float, fill: float) -> void:
	item.draw_circle(Vector2.ZERO, radius * fill, EMBER_FILL)
	item.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, BACKING, 6.0)
	item.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(EMBER, 0.85), 2.0)


func _draw() -> void:
	# PLACEHOLDER telegraphs. The name tag is HUD UI.
	if windup_left <= 0.0 or pending < 0:
		return
	var fill: float = windup_progress()
	match pending:
		Pattern.CHARGE:
			# The lane the boss will cover, as wide as the boss, up to the first obstacle.
			draw_lane(self, charge_direction, charge_length, radius, fill)
		Pattern.BURST:
			for index: int in range(BURST_SHOTS):
				var ray: Vector2 = Vector2.RIGHT.rotated(TAU * index / BURST_SHOTS)
				draw_tell(self, ray * radius, ray * (radius + 24.0 + 40.0 * fill), Color(EMBER, 0.8))
			draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 32, BACKING, 6.0)
			draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 32, Color(EMBER, 0.5 + 0.5 * fill), 2.0)
		Pattern.AIMED:
			for index: int in range(-2, 3):
				var ray: Vector2 = charge_direction.rotated(index * AIMED_SPREAD)
				draw_tell(self, ray * radius, ray * (radius + 60.0 + 200.0 * fill), Color(EMBER, 0.7))
		Pattern.SUMMON:
			for spot: Vector2 in summon_offsets():
				draw_arc(spot, 6.0 + 8.0 * fill, 0.0, TAU, 12, BACKING, 6.0)
				draw_arc(spot, 6.0 + 8.0 * fill, 0.0, TAU, 12, Color(SUMMON_MARK, 0.8), 2.0)
