class_name Boss
extends Enemy
## PLACEHOLDER boss: a generic attack-pattern mix standing in for an undesigned
## sin or Satan encounter. Patterns only make the bosses distinguishable for testing.
## Every attack is fair: a wind-up shows where it will land (ember = a ground attack, fly over
## or dash through it), then the boss stands in a short recovery the angel can punish. Bosses
## only start attacks while the angel is on screen and able to fight, and grow faster at each
## health threshold (phase). A phase change is announced by a short pose (the boss stands, and can
## still be hit) and may swap in that phase's own patterns. A guard stance blocks blows from the
## front like a shielder (heavy blows break it, opening a long punish window) and ends in a slam
## around the boss. An attack can open a combo: the patterns that follow it at once, each behind
## its own tell (a sin's data sets them per phase), before the boss rests. A shockwave sends three
## expanding ember rings out from the boss. A coin ring is a burst with two gaps either side of
## the angel (step into a gap); chained coin rings turn, so a volley spirals. Rain marks violet
## air circles around the angel that land one after another (flying does not help).

signal summon_requested(boss: Boss, count: int)
signal attacked(boss: Boss)
signal phase_changed(boss: Boss)

enum Pattern { CHARGE, BURST, AIMED, SUMMON, GUARD, SLAM, SHOCKWAVE, COINS, RAIN }

const CHARGE_TIME: float = 0.55
const PROJECTILE_SPEED: float = 260.0
const ATTACK_POSE_TIME: float = 0.5
## PLACEHOLDER wind-up per pattern (seconds the telegraph shows before the attack lands).
const WINDUPS: Array[float] = [0.6, 0.55, 0.5, 0.4, 0.35, 0.7, 0.6, 0.55, 0.35]
## PLACEHOLDER seconds the boss stands still after each pattern. A charge ends far from the
## angel, so it rests longer: long enough to walk back into spear reach.
const RECOVERIES: Array[float] = [0.8, 0.5, 0.5, 0.5, 0.5, 0.6, 0.6, 0.5, 0.6]
## PLACEHOLDER coin ring: shots in COIN_SLOTS directions, leaving gaps COIN_GAP slots either
## side of the angel (right beside the shot at it, so a step either way reaches one at any
## range); each chained ring keeps the volley's aim and turns half a slot, so it spirals.
const COIN_SLOTS: int = 12
const COIN_GAP: int = 1
## PLACEHOLDER rain: violet air circles around the angel, landing one after another.
const RAIN_SPOTS: Array[Vector2] = [Vector2.ZERO, Vector2(100.0, 0.0), Vector2(0.0, 100.0), Vector2(-100.0, 0.0), Vector2(0.0, -100.0)]
const RAIN_RADIUS: float = 48.0
const RAIN_DELAY: float = 0.8
const RAIN_STAGGER: float = 0.15
## Seconds of the angel's walking a leading rain looks ahead (a dash does not count).
const RAIN_LEAD: float = 0.35
## PLACEHOLDER phase-change pose: the boss stands for this long (still hittable).
const PHASE_POSE: float = 0.8
## PLACEHOLDER guard stance and the slam it ends in.
const GUARD_TIME: float = 1.5
const GUARD_BROKEN_RECOVERY: float = 1.2
const SLAM_RADIUS: float = 110.0
const SLAM_FLASH: float = 0.15
## Air shots (they reach a flying angel): violet, like the flyer's.
const VIOLET: Color = Color(1.15, 0.75, 1.8, 1.0)
const AIR_TELEGRAPH_LIGHT: Color = Color(0.65, 0.4, 1.0, 0.35)
const AIR_FILL: Color = Color(0.4, 0.25, 0.7, 0.22)
const POSE_COLOR: Color = Color(1.6, 1.5, 1.2, 1.0)
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
## Patterns per phase (index 0 is phase 1); empty keeps one list for the whole fight.
var phase_patterns: Array[Array] = []
var pose_left: float = 0.0
## The guard stance: seconds left, and the way the shield faces (it turns slowly).
var guard_left: float = 0.0
var guard_facing: Vector2 = Vector2.RIGHT
var block_flash_left: float = 0.0
var slam_flash_left: float = 0.0
## Combos for the current phase (pattern -> the patterns that follow it), one per phase from the
## sin's data, and the steps still to come in the running combo.
var phase_combos: Array[Dictionary] = []
var combos: Dictionary = {}
var combo_queue: Array[int] = []
## Movement speed and attack interval multipliers per phase (index 0 is phase 1), against the
## values the boss spawned with. Without paces, each phase multiplies the interval by PHASE_PACE.
var phase_speeds: Array[float] = []
var phase_paces: Array[float] = []
var base_speed: float = 0.0
var base_interval: float = 0.0
## This boss's slam (PLACEHOLDER; Wrath's is smaller and quicker than Pride's).
var slam_radius: float = SLAM_RADIUS
var slam_windup: float = WINDUPS[Pattern.SLAM]
## A charge that follows another in a combo: smarter bosses re-aim it at the angel; otherwise it
## heads for where the angel stood when the combo began.
var reaim_chains: bool = false
var combo_anchor: Vector2 = Vector2.ZERO
## The horde type a summon brings (an index into Run.ENEMY_TYPES).
var summon_type: int = 0
## The full length of the running wind-up (the tell's fill is measured against it).
var windup_total: float = 0.0
## Smarter tiers: aimed fans that may come from the air, and rain that lands where the angel is
## heading. Set by the run from the boss's data.
var air_fans: bool = false
var lead_rain: bool = false
## How far the running coin volley has turned (each chained ring turns half a slot).
var coin_turn: float = 0.0
## This aimed fan's shots come from the air (decided when its tell starts).
var fan_from_air: bool = false
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
	base_speed = speed
	base_interval = attack_interval
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
	block_flash_left = maxf(0.0, block_flash_left - delta)
	if slam_flash_left > 0.0:
		slam_flash_left = maxf(0.0, slam_flash_left - delta)
		queue_redraw()
	var leashed: bool = leash > 0.0 and target.global_position.distance_to(home) > leash
	if leashed and (windup_left > 0.0 or charge_left > 0.0 or guard_left > 0.0):
		_cancel()
	if pose_left > 0.0:
		pose_left -= delta
		velocity = Vector2.ZERO
		queue_redraw()
	elif recover_left > 0.0:
		# The punish window holds even if the angel leaves a guard's leash.
		recover_left -= delta
		velocity = Vector2.ZERO
	elif leashed:
		var to_home: Vector2 = home - global_position
		velocity = to_home.normalized() * speed if to_home.length() > speed * delta * 2.0 else Vector2.ZERO
	elif guard_left > 0.0:
		# The stance: stand behind the shield, turning slowly to face the angel, then slam.
		guard_left -= delta
		velocity = Vector2.ZERO
		var toward: Vector2 = target.global_position - global_position
		if not toward.is_zero_approx():
			guard_facing = guard_facing.rotated(clampf(guard_facing.angle_to(toward), -Shielder.TURN_RATE * delta, Shielder.TURN_RATE * delta))
		if guard_left <= 0.0:
			guard_left = 0.0
			_finish(Pattern.GUARD)
		queue_redraw()
	elif windup_left > 0.0:
		windup_left -= delta
		velocity = Vector2.ZERO
		if windup_left <= 0.0:
			var released: int = pending
			windup_left = 0.0
			pending = -1
			remove_from_group(&"light")
			_attack(released)
			if charge_left <= 0.0 and guard_left <= 0.0:
				_finish(released)
		queue_redraw()
	elif charge_left > 0.0:
		charge_left -= delta
		velocity = charge_direction * charge_speed()
		if charge_left <= 0.0:
			_finish(Pattern.CHARGE)
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


## Begins a wind-up: the attack's telegraph shows (aim locked now) until it lands. A fresh attack
## opens its combo; a chained one is a step of the running combo.
func start_attack(pattern: int, chained: bool = false) -> void:
	pending = pattern
	windup_left = slam_windup if pattern == Pattern.SLAM else WINDUPS[pattern]
	windup_total = windup_left
	if not chained:
		combo_queue.assign(combos.get(pattern, []))
		combo_anchor = target.global_position
		coin_turn = 0.0
	elif pattern == Pattern.COINS:
		coin_turn += PI / COIN_SLOTS
	if chained and pattern == Pattern.CHARGE and not reaim_chains:
		var toward: Vector2 = combo_anchor - global_position
		charge_direction = toward.normalized() if toward.length() > 1.0 else _aim(pattern)
	elif chained and pattern == Pattern.COINS:
		pass # A spiral keeps the volley's aim; only the turn changes.
	else:
		charge_direction = _aim(pattern)
	fan_from_air = pattern == Pattern.AIMED and air_fans and randf() < 0.5
	charge_length = clear_distance(self, charge_direction * charge_speed() * CHARGE_TIME) if pattern == Pattern.CHARGE else 0.0
	summon_spots.clear()
	attack_pose_left = ATTACK_POSE_TIME + windup_left
	# Attacks cast their tell's light (violet for an air fan, ember otherwise); a summon's marks
	# and a raised guard do not.
	set_meta(&"light", AIR_TELEGRAPH_LIGHT if fan_from_air or pattern == Pattern.RAIN else TELEGRAPH_LIGHT)
	if pattern != Pattern.SUMMON and pattern != Pattern.GUARD:
		add_to_group(&"light")
	attacked.emit(self)
	queue_redraw()


## An attack is done: the next step of its combo starts behind its own tell, or the boss rests.
func _finish(pattern: int) -> void:
	if not combo_queue.is_empty():
		start_attack(combo_queue.pop_front(), true)
	else:
		recover_left = RECOVERIES[pattern]


func _cancel() -> void:
	windup_left = 0.0
	charge_left = 0.0
	guard_left = 0.0
	combo_queue.clear()
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
		Pattern.COINS:
			for direction: Vector2 in coin_directions():
				_fire(direction)
		Pattern.RAIN:
			var center: Vector2 = target.global_position
			if lead_rain:
				center += target.velocity.limit_length(target.movement_speed) * RAIN_LEAD
			for index: int in range(RAIN_SPOTS.size()):
				var drop: GroundStrike = GroundStrike.new()
				drop.from_air = true
				drop.radius = RAIN_RADIUS
				drop.delay = RAIN_DELAY + index * RAIN_STAGGER
				drop.damage = shot_damage
				drop.target = target
				get_parent().add_child(drop)
				drop.global_position = center + RAIN_SPOTS[index]
		Pattern.GUARD:
			guard_left = GUARD_TIME
			guard_facing = charge_direction
		Pattern.SLAM:
			slam_flash_left = SLAM_FLASH
			if global_position.distance_to(target.global_position) <= slam_radius + MountedPlayer.HURT_RADIUS:
				target.take_damage(contact_damage)
		Pattern.SHOCKWAVE:
			var wave: Shockwave = Shockwave.new()
			wave.damage = contact_damage
			wave.target = target
			get_parent().add_child(wave)
			wave.global_position = global_position


## Where a coin ring's shots go: every slot around the boss but the gaps either side of the aim,
## turned by the running volley.
func coin_directions() -> Array[Vector2]:
	var directions: Array[Vector2] = []
	for slot: int in range(COIN_SLOTS):
		if slot == COIN_GAP or slot == COIN_SLOTS - COIN_GAP:
			continue
		directions.append(charge_direction.rotated(coin_turn + TAU * slot / COIN_SLOTS))
	return directions


## A raised guard blocks blows from inside the shield's front cone (sparks, no damage, no push);
## a heavy blow breaks it, lands, and leaves the boss open for a long moment.
func take_hit(damage: int, heavy: bool = false, from: Vector2 = Vector2.INF) -> void:
	if health <= 0:
		return
	if guard_left > 0.0:
		if heavy:
			# A heavy blow from any side breaks the stance: no slam, a long opening.
			guard_left = 0.0
			combo_queue.clear()
			recover_left = GUARD_BROKEN_RECOVERY
		else:
			var source: Vector2 = from
			if source == Vector2.INF and is_instance_valid(target):
				source = target.global_position
			var toward: Vector2 = source - global_position if source != Vector2.INF else Vector2.ZERO
			if not toward.is_zero_approx() and guard_facing.dot(toward.normalized()) > cos(Shielder.GUARD_HALF_ANGLE):
				blocked_last = true
				block_flash_left = Shielder.BLOCK_FLASH
				damaged.emit(self, 0, false)
				queue_redraw()
				return
	super(damage, heavy, from)


func _check_phase() -> void:
	while phase - 1 < phase_thresholds.size() and health > 0 and health <= max_health * phase_thresholds[phase - 1]:
		phase += 1
		if phase - 1 < phase_paces.size():
			attack_interval = base_interval * phase_paces[phase - 1]
		else:
			attack_interval *= PHASE_PACE
		attack_left = minf(attack_left, attack_interval)
		if phase - 1 < phase_patterns.size():
			patterns.assign(phase_patterns[phase - 1])
		if phase - 1 < phase_combos.size():
			combos = phase_combos[phase - 1]
		if phase - 1 < phase_speeds.size():
			speed = base_speed * phase_speeds[phase - 1]
		# The pose: whatever it was doing stops, and it stands (still hittable) to announce it.
		_cancel()
		recover_left = 0.0
		pose_left = PHASE_POSE
		phase_changed.emit(self)


func _fire(direction: Vector2) -> void:
	var projectile: EnemyProjectile = EnemyProjectile.new()
	projectile.velocity = direction * PROJECTILE_SPEED
	projectile.damage = shot_damage
	projectile.target = target
	projectile.from_air = fan_from_air
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction * radius
	if projectile.from_air:
		projectile.modulate = VIOLET


## Stepped fill (quarters), so the telegraph grows in pixel-sized beats.
func windup_progress() -> float:
	if pending < 0 or windup_total <= 0.0:
		return 0.0
	return floorf((1.0 - windup_left / windup_total) * 4.0) / 4.0


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
## A circle about to strike: a dark-backed ring and a stepped fill; ember for the ground, violet
## for the air.
static func draw_circle_tell(item: CanvasItem, radius: float, fill: float, air: bool = false) -> void:
	item.draw_circle(Vector2.ZERO, radius * fill, AIR_FILL if air else EMBER_FILL)
	item.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, BACKING, 6.0)
	item.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(VIOLET if air else EMBER, 0.85), 2.0)


func _draw() -> void:
	# PLACEHOLDER telegraphs. The name tag is HUD UI.
	if pose_left > 0.0:
		# The phase pose: a pale ring swelling out in steps.
		var grow: float = floorf((1.0 - pose_left / PHASE_POSE) * 4.0) / 4.0
		draw_arc(Vector2.ZERO, radius + 8.0 + 40.0 * grow, 0.0, TAU, 48, BACKING, 6.0)
		draw_arc(Vector2.ZERO, radius + 8.0 + 40.0 * grow, 0.0, TAU, 48, POSE_COLOR, 2.0)
	if guard_left > 0.0:
		var at: float = guard_facing.angle()
		var half: float = Shielder.GUARD_HALF_ANGLE
		draw_arc(Vector2.ZERO, radius + 10.0, at - half, at + half, 24, BACKING, 6.0)
		draw_arc(Vector2.ZERO, radius + 10.0, at - half, at + half, 24, Shielder.BLOCK_COLOR if block_flash_left > 0.0 else Shielder.SHIELD_COLOR, 2.0)
	if slam_flash_left > 0.0:
		draw_circle(Vector2.ZERO, slam_radius, Color(1.9, 0.9, 0.3, slam_flash_left / SLAM_FLASH))
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
			# Ember for a ground fan (fly over it), violet for an air fan (dash or step out).
			for index: int in range(-2, 3):
				var ray: Vector2 = charge_direction.rotated(index * AIMED_SPREAD)
				draw_tell(self, ray * radius, ray * (radius + 60.0 + 200.0 * fill), Color(VIOLET if fan_from_air else EMBER, 0.9 if fan_from_air else 0.7))
			if fan_from_air:
				# A shape cue as well as the color: an arc across the fan's mouth.
				var mouth: float = charge_direction.angle()
				draw_arc(Vector2.ZERO, radius + 12.0, mouth - AIMED_SPREAD * 2.0, mouth + AIMED_SPREAD * 2.0, 16, BACKING, 6.0)
				draw_arc(Vector2.ZERO, radius + 12.0, mouth - AIMED_SPREAD * 2.0, mouth + AIMED_SPREAD * 2.0, 16, VIOLET, 2.0)
		Pattern.GUARD:
			# The shield rising.
			var at: float = charge_direction.angle()
			var span: float = Shielder.GUARD_HALF_ANGLE * fill
			draw_arc(Vector2.ZERO, radius + 10.0, at - span, at + span, 24, BACKING, 6.0)
			draw_arc(Vector2.ZERO, radius + 10.0, at - span, at + span, 24, Shielder.SHIELD_COLOR, 2.0)
		Pattern.SLAM:
			draw_circle_tell(self, slam_radius, fill)
		Pattern.SHOCKWAVE:
			# Rings gathering at the boss's feet, about to roll out.
			for ring: int in range(Shockwave.RINGS):
				var gather: float = roundf((radius + 8.0 + ring * 10.0 * (1.0 - fill)) / 2.0) * 2.0
				draw_arc(Vector2.ZERO, gather, 0.0, TAU, 32, BACKING, 6.0)
				draw_arc(Vector2.ZERO, gather, 0.0, TAU, 32, Color(EMBER, 0.85), 2.0)
		Pattern.COINS:
			# One ray per coin; the gaps either side of the angel show as missing rays.
			for direction: Vector2 in coin_directions():
				draw_tell(self, direction * radius, direction * (radius + 36.0 + 64.0 * fill), Color(EMBER, 0.8))
		Pattern.RAIN:
			# A violet ring gathering above the boss: the rain is coming (air).
			draw_arc(Vector2.ZERO, radius + 12.0 + 12.0 * fill, 0.0, TAU, 32, BACKING, 6.0)
			draw_arc(Vector2.ZERO, radius + 12.0 + 12.0 * fill, 0.0, TAU, 32, Color(VIOLET, 0.9), 2.0)
		Pattern.SUMMON:
			for spot: Vector2 in summon_offsets():
				draw_arc(spot, 6.0 + 8.0 * fill, 0.0, TAU, 12, BACKING, 6.0)
				draw_arc(spot, 6.0 + 8.0 * fill, 0.0, TAU, 12, Color(SUMMON_MARK, 0.8), 2.0)
