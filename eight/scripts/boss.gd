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
## air circles around the angel that land one after another (flying does not help). Kisses are
## three slow violet air shots (dash through or step aside). A blink marks a circle behind the
## angel, then the boss appears there (a combo then follows, such as Lust's quick charge).

signal summon_requested(boss: Boss, count: int)
signal attacked(boss: Boss)
signal phase_changed(boss: Boss)
## A devour swallowed a horde enemy (it is gone; nothing is earned and the boss does not heal).
signal ate(boss: Boss, enemy: Enemy)
## A decoy call (Envy): the run raises that many dark copies at decoy_spots().
signal decoys_requested(boss: Boss, count: int)

enum Pattern { CHARGE, BURST, AIMED, SUMMON, GUARD, SLAM, SHOCKWAVE, COINS, RAIN, KISSES, BLINK, LEAP, VOMIT, DEVOUR, SNORE, SLUDGE, YAWN, NAP, MIRROR, THRUST, SHOT, DECOY }

const CHARGE_TIME: float = 0.55
const PROJECTILE_SPEED: float = 260.0
const ATTACK_POSE_TIME: float = 0.5
## PLACEHOLDER wind-up per pattern (seconds the telegraph shows before the attack lands).
const WINDUPS: Array[float] = [0.6, 0.55, 0.5, 0.4, 0.35, 0.7, 0.6, 0.55, 0.35, 0.6, 0.6, 1.0, 0.6, 0.5, 0.7, 0.6, 1.4, 0.05, 0.55, 0.55, 0.55, 0.6]
## PLACEHOLDER seconds the boss stands still after each pattern. A charge ends far from the
## angel, so it rests longer: long enough to walk back into spear reach.
const RECOVERIES: Array[float] = [0.8, 0.5, 0.5, 0.5, 0.5, 0.6, 0.6, 0.5, 0.6, 0.6, 0.4, 0.8, 0.5, 0.8, 0.6, 0.5, 2.0, 2.0, 0.5, 0.8, 0.5, 0.5]
## PLACEHOLDER kisses: a fan of slow air shots.
const KISS_COUNT: int = 3
const KISS_SPREAD: float = 0.22
const KISS_SPEED: float = 185.0
## PLACEHOLDER blink: the circle sits this far behind the angel (from the boss's side).
const BLINK_BEHIND: float = 120.0
const BLINK_COLOR: Color = Color(1.6, 1.5, 1.2, 1.0)
const BLINK_FILL: Color = Color(0.45, 0.4, 0.35, 0.18)
## PLACEHOLDER leap: a circle marks where the angel stood; the boss lands there and leaves bile.
const LEAP_RADIUS: float = 120.0
## A leap that follows another in a combo (smarter Gluttony) is told for less time.
const CHAINED_LEAP_WINDUP: float = 0.7
const BILE_RADIUS: float = 90.0
## PLACEHOLDER vomit: a wide fan of ground shots.
const VOMIT_COUNT: int = 9
const VOMIT_SPREAD: float = 0.18
## PLACEHOLDER devour: an inhale cone in front of the mouth pulls the angel and the horde in;
## horde enemies reaching the mouth are eaten; anyone still at the mouth when it closes is bitten.
const DEVOUR_TIME: float = 1.2
const DEVOUR_RANGE: float = 260.0
const DEVOUR_HALF_ANGLE: float = 0.6
const PULL_ANGEL: float = 150.0
const PULL_HORDE: float = 220.0
## The bite reaches this far past the boss's body, inside the cone.
const BITE_REACH: float = 60.0
const BITE_SCALE: float = 1.5
## PLACEHOLDER snore: a slow ring of ground shots with wide gaps (one aimed at the angel).
const SNORE_COUNT: int = 10
const SNORE_SPEED: float = 140.0
## PLACEHOLDER sludge: pools marked around the angel that slow a grounded angel inside, laid out
## across the line from the boss (x along it, y across it): one under the angel, two either side.
const SLUDGE_SPOTS: Array[Vector2] = [Vector2.ZERO, Vector2(40.0, 140.0), Vector2(40.0, -140.0)]
## Sludge is drawn slate (it slows, it never hurts), apart from the ember of damaging circles.
const SLUDGE_COLOR: Color = Color(0.75, 0.82, 0.9, 1.0)
const SLUDGE_RADIUS: float = 70.0
const SLUDGE_SLOW: float = 0.6
## PLACEHOLDER yawn: a huge ground slam with a long tell (fly over it); a nap (NAP's recovery,
## the punish window) follows it in Sloth's combo.
const YAWN_RADIUS: float = 320.0
const SLEEP_COLOR: Color = Color(1.4, 1.35, 1.2, 1.0)
## PLACEHOLDER mirror (Envy): it becomes the angel's weapon. Against the spear, a thrust along a
## lane in front of it; against the bow, it keeps its distance and shoots in the bow's rhythm.
const THRUST_LENGTH: float = 120.0
const THRUST_HALF: float = 18.0
const SHOT_SPEED: float = 440.0
## A shot following another in a volley waits only the bow's rhythm.
const CHAINED_SHOT_WINDUP: float = 0.26
## A smarter mirror's tells are shorter (never under this).
const QUICK_MIRROR_WINDUP: float = 0.45
const MIRROR_RANGE: float = 340.0
## PLACEHOLDER decoys: dark copies raised beside the boss; darker and cooler than the real one.
const DECOY_TINT: Color = Color(0.48, 0.42, 0.58, 1.0)
const DECOY_SPREAD: float = 90.0
const DECOY_MARK: Color = Color(0.85, 0.8, 0.9, 1.0)
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
## The landing flash covers exactly what just hit (a slam's or a leap's circle).
var flash_radius: float = SLAM_RADIUS
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
## Where a pending blink lands (world position), chosen when its tell starts.
var blink_spot: Vector2 = Vector2.ZERO
## The wind-up of a charge that follows another step in a combo (Lust's is quicker).
var chained_charge_windup: float = WINDUPS[Pattern.CHARGE]
## Where a pending leap lands (world position), chosen when its tell starts.
var leap_spot: Vector2 = Vector2.ZERO
## Seconds a leap's bile lasts (longer on smarter tiers).
var bile_time: float = 4.0
## Seconds left of a devour's inhale.
var devour_left: float = 0.0
## Where a pending sludge's pools go (world positions), chosen when its tell starts.
var sludge_spots: Array[Vector2] = []
## Seconds sludge lasts (longer on smarter tiers).
var sludge_time: float = 5.0
## Asleep after a yawn: the nap's recovery, drawn as sleep.
var napping: bool = false
## Sprite tint per phase (index 0 is phase 1), such as Sloth waking; empty keeps the tint.
var phase_tints: Array[Color] = []
## Mirrors the angel's weapon in its movement (Envy keeps its distance against a bow).
var mirrors: bool = false
## Smarter mirroring: shorter thrust and shot tells.
var quick_mirror: bool = false
## Decoys raised per call (more on smarter tiers), and where the pending call raises them: open
## ground (no wall, angel, or standing body), chosen when its tell starts so the marks are exact.
var decoy_count: int = 1
var decoy_plan: Array[Vector2] = []
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
		if recover_left <= 0.0 and napping:
			napping = false
			queue_redraw()
	elif leashed:
		var to_home: Vector2 = home - global_position
		velocity = to_home.normalized() * speed if to_home.length() > speed * delta * 2.0 else Vector2.ZERO
	elif devour_left > 0.0:
		devour_left -= delta
		velocity = Vector2.ZERO
		_inhale(delta)
		if devour_left <= 0.0:
			devour_left = 0.0
			_bite()
			remove_from_group(&"light")
			_finish(Pattern.DEVOUR)
		queue_redraw()
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
			# Charges, guard stances and inhales finish when they run out, not now.
			if charge_left <= 0.0 and guard_left <= 0.0 and devour_left <= 0.0:
				_finish(released)
		queue_redraw()
	elif charge_left > 0.0:
		charge_left -= delta
		velocity = charge_direction * charge_speed()
		if charge_left <= 0.0:
			_finish(Pattern.CHARGE)
	else:
		var toward_angel: Vector2 = target.global_position - global_position
		velocity = toward_angel.normalized() * speed
		if mirrors and target.weapon == MountedPlayer.Weapon.BOW:
			# Against a bow, keep the bow's distance instead of closing in.
			var gap: float = toward_angel.length()
			if gap < MIRROR_RANGE - 20.0:
				velocity = -velocity
			elif gap <= MIRROR_RANGE + 20.0:
				velocity = Vector2.ZERO
		if can_attack():
			attack_left -= delta
			if attack_left <= 0.0 and not patterns.is_empty():
				var choice: int = patterns.pick_random()
				if _ready_for(choice):
					attack_left = attack_interval
					start_attack(choice)
				else:
					attack_left = 0.25 # That attack would land on nothing now; roll again shortly.
	move_and_slide()
	_face(target.global_position.x - global_position.x)
	var attacking: bool = windup_left > 0.0 or charge_left > 0.0 or attack_pose_left > 0.0
	var animation: StringName = &"attack" if attacking else &"idle"
	if sprite.sprite_frames != null and sprite.animation != animation:
		sprite.play(animation)
	_touch_player()


## Begins a wind-up: the attack's telegraph shows (aim locked now) until it lands. A fresh attack
## opens its combo; a chained one is a step of the running combo.
func start_attack(pattern: int, chained: bool = false, after: int = -1) -> void:
	if pattern == Pattern.MIRROR:
		# The mirror becomes whatever the angel holds right now.
		pattern = Pattern.THRUST if target.weapon == MountedPlayer.Weapon.SPEAR else Pattern.SHOT
	pending = pattern
	windup_left = slam_windup if pattern == Pattern.SLAM else WINDUPS[pattern]
	if quick_mirror and (pattern == Pattern.THRUST or pattern == Pattern.SHOT):
		windup_left = QUICK_MIRROR_WINDUP
	if chained and pattern == Pattern.SHOT:
		windup_left = CHAINED_SHOT_WINDUP
	if pattern == Pattern.NAP and after == Pattern.RAIN:
		# A nap after rain waits until the last drop has landed, so the nap stays a clean opening.
		windup_left = RAIN_DELAY + RAIN_STAGGER * (RAIN_SPOTS.size() - 1)
	if chained and pattern == Pattern.CHARGE:
		windup_left = chained_charge_windup
	elif chained and pattern == Pattern.LEAP:
		windup_left = CHAINED_LEAP_WINDUP
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
	fan_from_air = (pattern == Pattern.AIMED and air_fans and randf() < 0.5) or pattern == Pattern.KISSES
	if pattern == Pattern.BLINK:
		blink_spot = _blink_spot()
	if pattern == Pattern.LEAP:
		leap_spot = _leap_spot()
	if pattern == Pattern.SLUDGE:
		_plan_sludge()
	if pattern == Pattern.DECOY:
		_plan_decoys()
	charge_length = clear_distance(self, charge_direction * charge_speed() * CHARGE_TIME) if pattern == Pattern.CHARGE else 0.0
	summon_spots.clear()
	if pattern == Pattern.NAP:
		# Falling asleep is not an attack: no attack pose, light, or sound.
		queue_redraw()
		return
	attack_pose_left = ATTACK_POSE_TIME + windup_left
	# Attacks cast their tell's light (violet for an air fan, ember otherwise); a summon's marks,
	# a raised guard, a blink, and sludge do not.
	set_meta(&"light", AIR_TELEGRAPH_LIGHT if fan_from_air or pattern == Pattern.RAIN or pattern == Pattern.DEVOUR else TELEGRAPH_LIGHT)
	if pattern != Pattern.SUMMON and pattern != Pattern.GUARD and pattern != Pattern.BLINK and pattern != Pattern.SLUDGE and pattern != Pattern.DECOY:
		add_to_group(&"light")
	attacked.emit(self)
	queue_redraw()


## False for an attack that could not land right now: a mirrored thrust while the angel holds
## the spear out of its reach, or a decoy call while its decoys already stand.
func _ready_for(pattern: int) -> bool:
	if pattern == Pattern.MIRROR and target.weapon == MountedPlayer.Weapon.SPEAR:
		return global_position.distance_to(target.global_position) <= radius + THRUST_LENGTH + MountedPlayer.HURT_RADIUS
	if pattern == Pattern.DECOY:
		return get_tree().get_nodes_in_group(&"decoys").size() < decoy_count
	return true


## Decoy spots either side of the boss on open ground, up to the copies still missing.
func _plan_decoys() -> void:
	decoy_plan.clear()
	var missing: int = decoy_count - get_tree().get_nodes_in_group(&"decoys").size()
	var room: Rect2 = Run.ARENA_RECT.grow(-radius)
	for spot: Vector2 in decoy_spots():
		if decoy_plan.size() < missing and room.has_point(spot) and _spot_clear(spot):
			decoy_plan.append(spot)


## Sludge spots across the line from the boss, kept inside the arena; a spot inside a wall or
## obstacle is dropped (its tell is never shown).
func _plan_sludge() -> void:
	sludge_spots.clear()
	var along: Vector2 = charge_direction
	var across: Vector2 = along.orthogonal()
	var room: Rect2 = Run.ARENA_RECT.grow(-SLUDGE_RADIUS)
	for offset: Vector2 in SLUDGE_SPOTS:
		var spot: Vector2 = (target.global_position + along * offset.x + across * offset.y).clamp(room.position, room.end)
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = MountedPlayer.HURT_RADIUS
		var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		query.shape = circle
		query.transform = Transform2D(0.0, spot)
		query.collision_mask = 1
		if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			sludge_spots.append(spot)


## Behind the angel as seen from the boss, on open ground inside the arena; in front of it if
## that is blocked, and where the boss stands if both are.
func _blink_spot() -> Vector2:
	var away: Vector2 = target.global_position - global_position
	away = away.normalized() if away.length() > 1.0 else Vector2.RIGHT
	for side: float in [1.0, -1.0]:
		var spot: Vector2 = (target.global_position + away * BLINK_BEHIND * side).clamp(Run.ARENA_RECT.position + Vector2(radius, radius), Run.ARENA_RECT.end - Vector2(radius, radius))
		if _spot_clear(spot):
			return spot
	return global_position


## Where the angel stands, kept inside the arena and off walls and obstacles (a leap is an attack:
## it may land on the angel).
func _leap_spot() -> Vector2:
	var spot: Vector2 = target.global_position.clamp(Run.ARENA_RECT.position + Vector2(radius, radius), Run.ARENA_RECT.end - Vector2(radius, radius))
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = Transform2D(0.0, spot)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return spot if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty() else global_position


## True when a point is inside the devour's cone (in front of the mouth, within its range).
func in_mouth_cone(point: Vector2, reach: float) -> bool:
	var offset: Vector2 = point - global_position
	return offset.length() <= reach and (offset.length() < 1.0 or absf(charge_direction.angle_to(offset)) <= DEVOUR_HALF_ANGLE)


## The inhale: the angel and the horde inside the cone are pulled toward the mouth; horde
## enemies reaching it are eaten.
func _inhale(delta: float) -> void:
	if in_mouth_cone(target.global_position, DEVOUR_RANGE):
		target.apply_pull((global_position - target.global_position).normalized() * PULL_ANGEL)
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = DEVOUR_RANGE
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 8 | 16
	query.exclude = [get_rid()]
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, LightRain.MAX_TARGETS):
		var prey: Enemy = result["collider"] as Enemy
		if prey == null or prey is Boss or prey.health <= 0 or not in_mouth_cone(prey.global_position, DEVOUR_RANGE):
			continue
		if prey.global_position.distance_to(global_position) <= radius + prey.radius:
			ate.emit(self, prey)
		else:
			prey.knockback = (global_position - prey.global_position).normalized() * PULL_HORDE
	if delta > 0.0:
		queue_redraw()


## The mouth closes: a big bite for an angel still right in front of it (it reaches the air).
func _bite() -> void:
	if in_mouth_cone(target.global_position, radius + BITE_REACH + MountedPlayer.HURT_RADIUS):
		target.take_damage(roundi(contact_damage * BITE_SCALE), true)


## True when a point (the angel) is inside the mirror's thrust lane in front of the boss.
func in_thrust_lane(point: Vector2) -> bool:
	var offset: Vector2 = point - global_position
	var along: float = offset.dot(charge_direction)
	return along >= 0.0 and along <= radius + THRUST_LENGTH + MountedPlayer.HURT_RADIUS and absf(offset.dot(charge_direction.orthogonal())) <= THRUST_HALF + MountedPlayer.HURT_RADIUS


## Where decoys appear: either side of the boss, across the line to the angel.
func decoy_spots() -> Array[Vector2]:
	var across: Vector2 = charge_direction.orthogonal() * (radius + DECOY_SPREAD)
	return [global_position + across, global_position - across]


## No wall, obstacle, angel, or ground enemy where the boss's body would stand.
func _spot_clear(spot: Vector2) -> bool:
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = Transform2D(0.0, spot)
	query.collision_mask = collision_mask | 2 | 8
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## An attack is done: the next step of its combo starts behind its own tell, or the boss rests.
func _finish(pattern: int) -> void:
	if not combo_queue.is_empty():
		start_attack(combo_queue.pop_front(), true, pattern)
	else:
		recover_left = RECOVERIES[pattern]


func _cancel() -> void:
	windup_left = 0.0
	charge_left = 0.0
	guard_left = 0.0
	devour_left = 0.0
	napping = false
	combo_queue.clear()
	pending = -1
	remove_from_group(&"light")
	queue_redraw()


## Where an attack goes: at the angel, or (smarter bosses' aimed fans) partly toward where the
## angel will be when the shots arrive.
func _aim(pattern: int) -> Vector2:
	var at: Vector2 = target.global_position
	if smarts >= LEAD_SMARTS and (pattern == Pattern.AIMED or pattern == Pattern.SHOT):
		var arrival: float = WINDUPS[pattern] + global_position.distance_to(at) / (SHOT_SPEED if pattern == Pattern.SHOT else PROJECTILE_SPEED)
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
		Pattern.KISSES:
			for index: int in range(KISS_COUNT):
				_fire(charge_direction.rotated((index - (KISS_COUNT - 1) * 0.5) * KISS_SPREAD), KISS_SPEED)
		Pattern.LEAP:
			global_position = leap_spot
			slam_flash_left = SLAM_FLASH
			flash_radius = LEAP_RADIUS
			if global_position.distance_to(target.global_position) <= LEAP_RADIUS + MountedPlayer.HURT_RADIUS:
				target.take_damage(contact_damage)
			var bile: BileZone = BileZone.new()
			bile.radius = BILE_RADIUS
			bile.lifetime = bile_time
			bile.damage = maxi(1, shot_damage / 2)
			bile.target = target
			get_parent().add_child(bile)
			bile.global_position = leap_spot
		Pattern.VOMIT:
			for index: int in range(VOMIT_COUNT):
				_fire(charge_direction.rotated((index - (VOMIT_COUNT - 1) * 0.5) * VOMIT_SPREAD))
		Pattern.DEVOUR:
			devour_left = DEVOUR_TIME
			add_to_group(&"light")
		Pattern.SNORE:
			for index: int in range(SNORE_COUNT):
				_fire(charge_direction.rotated(TAU * index / SNORE_COUNT), SNORE_SPEED)
		Pattern.SLUDGE:
			for spot: Vector2 in sludge_spots:
				var pool: BileZone = BileZone.new()
				pool.radius = SLUDGE_RADIUS
				pool.lifetime = sludge_time
				pool.slow_factor = SLUDGE_SLOW
				pool.target = target
				get_parent().add_child(pool)
				pool.global_position = spot
		Pattern.YAWN:
			slam_flash_left = SLAM_FLASH
			flash_radius = YAWN_RADIUS
			if global_position.distance_to(target.global_position) <= YAWN_RADIUS + MountedPlayer.HURT_RADIUS:
				target.take_damage(contact_damage)
		Pattern.NAP:
			napping = true
			queue_redraw()
		Pattern.THRUST:
			if in_thrust_lane(target.global_position):
				target.take_damage(contact_damage)
		Pattern.SHOT:
			_fire(charge_direction, SHOT_SPEED)
		Pattern.DECOY:
			decoys_requested.emit(self, decoy_plan.size())
		Pattern.BLINK:
			# If the marked spot is taken now (the angel walked onto it), the blink is called off:
			# never land somewhere else, never land on the angel.
			if _spot_clear(blink_spot):
				global_position = blink_spot
			else:
				combo_queue.clear()
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
			flash_radius = slam_radius
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
		if phase - 1 < phase_tints.size():
			sprite.self_modulate = phase_tints[phase - 1]
		# The pose: whatever it was doing stops, and it stands (still hittable) to announce it.
		_cancel()
		recover_left = 0.0
		pose_left = PHASE_POSE
		phase_changed.emit(self)


func _fire(direction: Vector2, shot_speed: float = PROJECTILE_SPEED) -> void:
	var projectile: EnemyProjectile = EnemyProjectile.new()
	projectile.velocity = direction * shot_speed
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
static func draw_circle_tell(item: CanvasItem, radius: float, fill: float, air: bool = false, at: Vector2 = Vector2.ZERO) -> void:
	item.draw_circle(at, radius * fill, AIR_FILL if air else EMBER_FILL)
	item.draw_arc(at, radius, 0.0, TAU, 48, BACKING, 6.0)
	item.draw_arc(at, radius, 0.0, TAU, 48, Color(VIOLET if air else EMBER, 0.85), 2.0)


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
		draw_circle(Vector2.ZERO, flash_radius, Color(1.9, 0.9, 0.3, slam_flash_left / SLAM_FLASH))
	if devour_left > 0.0:
		_draw_cone(1.0)
	if napping:
		# PLACEHOLDER sleep: three pale z-ticks rising off the boss.
		for index: int in range(3):
			var at: Vector2 = Vector2(radius * 0.5 + index * 10.0, -radius - 8.0 - index * 12.0)
			var size: float = 4.0 + index * 2.0
			draw_line(at, at + Vector2(size, 0.0), SLEEP_COLOR, 2.0)
			draw_line(at + Vector2(size, 0.0), at + Vector2(0.0, size), SLEEP_COLOR, 2.0)
			draw_line(at + Vector2(0.0, size), at + Vector2(size, size), SLEEP_COLOR, 2.0)
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
		Pattern.KISSES:
			# Three violet rays and an arc across their mouth: slow air shots (dash or step aside).
			for index: int in range(KISS_COUNT):
				var ray: Vector2 = charge_direction.rotated((index - (KISS_COUNT - 1) * 0.5) * KISS_SPREAD)
				draw_tell(self, ray * radius, ray * (radius + 40.0 + 100.0 * fill), Color(VIOLET, 0.9))
			var mouth: float = charge_direction.angle()
			draw_arc(Vector2.ZERO, radius + 12.0, mouth - KISS_SPREAD, mouth + KISS_SPREAD, 12, BACKING, 6.0)
			draw_arc(Vector2.ZERO, radius + 12.0, mouth - KISS_SPREAD, mouth + KISS_SPREAD, 12, VIOLET, 2.0)
		Pattern.LEAP:
			# Where it will land: the angel's spot, a wide ember circle (fly over it or leave it).
			draw_circle_tell(self, LEAP_RADIUS, fill, false, leap_spot - global_position)
			var toward_leap: Vector2 = (leap_spot - global_position).normalized()
			draw_tell(self, toward_leap * (radius + 4.0), toward_leap * (radius + 28.0), Color(EMBER, 0.85))
		Pattern.VOMIT:
			for index: int in range(VOMIT_COUNT):
				var spray: Vector2 = charge_direction.rotated((index - (VOMIT_COUNT - 1) * 0.5) * VOMIT_SPREAD)
				draw_tell(self, spray * radius, spray * (radius + 40.0 + 120.0 * fill), Color(EMBER, 0.7))
		Pattern.DEVOUR:
			_draw_cone(fill)
		Pattern.SNORE:
			for index: int in range(SNORE_COUNT):
				var ray: Vector2 = charge_direction.rotated(TAU * index / SNORE_COUNT)
				draw_tell(self, ray * radius, ray * (radius + 24.0 + 40.0 * fill), Color(EMBER, 0.8))
		Pattern.SLUDGE:
			for spot: Vector2 in sludge_spots:
				var at: Vector2 = spot - global_position
				draw_circle(at, SLUDGE_RADIUS * fill, BileZone.SLUDGE_FILL)
				draw_arc(at, SLUDGE_RADIUS, 0.0, TAU, 48, BACKING, 6.0)
				draw_arc(at, SLUDGE_RADIUS, 0.0, TAU, 48, SLUDGE_COLOR, 2.0)
		Pattern.YAWN:
			draw_circle_tell(self, YAWN_RADIUS, fill)
		Pattern.THRUST:
			# The spear's lane in front of it (a ground attack: fly over it or step aside).
			draw_lane(self, charge_direction, radius + THRUST_LENGTH, THRUST_HALF, fill)
		Pattern.SHOT:
			draw_tell(self, charge_direction * radius, charge_direction * (radius + 60.0 + 60.0 * fill), Color(EMBER, 0.85))
		Pattern.DECOY:
			# Pale circles as wide as the copies, exactly where they will rise.
			for spot: Vector2 in decoy_plan:
				var at: Vector2 = spot - global_position
				draw_circle(at, radius * fill, BLINK_FILL)
				draw_arc(at, radius, 0.0, TAU, 32, BACKING, 6.0)
				draw_arc(at, radius, 0.0, TAU, 32, DECOY_MARK, 2.0)
		Pattern.BLINK:
			# On the boss: a pale ring drawing in, and a tick pointing where it will appear.
			var gather: float = roundf((radius + 16.0 * (1.0 - fill)) / 2.0) * 2.0
			draw_arc(Vector2.ZERO, gather, 0.0, TAU, 32, BACKING, 6.0)
			draw_arc(Vector2.ZERO, gather, 0.0, TAU, 32, BLINK_COLOR, 2.0)
			var toward: Vector2 = (blink_spot - global_position).normalized()
			draw_tell(self, toward * (radius + 4.0), toward * (radius + 28.0), BLINK_COLOR)
			# Where the boss is about to appear: a pale circle as wide as the boss, filling in steps.
			var at: Vector2 = blink_spot - global_position
			# A dim, neutral fill (a bright one blooms toward the angel's mint).
			draw_circle(at, radius * fill, BLINK_FILL)
			draw_arc(at, radius, 0.0, TAU, 32, BACKING, 6.0)
			draw_arc(at, radius, 0.0, TAU, 32, BLINK_COLOR, 2.0)
		Pattern.RAIN:
			# A violet ring gathering above the boss: the rain is coming (air).
			draw_arc(Vector2.ZERO, radius + 12.0 + 12.0 * fill, 0.0, TAU, 32, BACKING, 6.0)
			draw_arc(Vector2.ZERO, radius + 12.0 + 12.0 * fill, 0.0, TAU, 32, Color(VIOLET, 0.9), 2.0)
		Pattern.SUMMON:
			for spot: Vector2 in summon_offsets():
				draw_arc(spot, 6.0 + 8.0 * fill, 0.0, TAU, 12, BACKING, 6.0)
				draw_arc(spot, 6.0 + 8.0 * fill, 0.0, TAU, 12, Color(SUMMON_MARK, 0.8), 2.0)


## The devour's cone (violet: it reaches a flying angel) and the bite zone at the mouth.
func _draw_cone(fill: float) -> void:
	var at: float = charge_direction.angle()
	var edge: Vector2 = Vector2.RIGHT * DEVOUR_RANGE
	for side: float in [-DEVOUR_HALF_ANGLE, DEVOUR_HALF_ANGLE]:
		draw_tell(self, Vector2.from_angle(at + side) * radius, edge.rotated(at + side), Color(VIOLET, 0.8))
	draw_arc(Vector2.ZERO, DEVOUR_RANGE, at - DEVOUR_HALF_ANGLE, at + DEVOUR_HALF_ANGLE, 24, BACKING, 6.0)
	draw_arc(Vector2.ZERO, DEVOUR_RANGE, at - DEVOUR_HALF_ANGLE, at + DEVOUR_HALF_ANGLE, 24, Color(VIOLET, 0.8), 2.0)
	var bite: float = radius + BITE_REACH
	draw_arc(Vector2.ZERO, bite, at - DEVOUR_HALF_ANGLE, at + DEVOUR_HALF_ANGLE, 16, BACKING, 6.0)
	draw_arc(Vector2.ZERO, bite, at - DEVOUR_HALF_ANGLE, at + DEVOUR_HALF_ANGLE, 16, Color(VIOLET, 0.5 + 0.5 * fill), 2.0)
