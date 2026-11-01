class_name Boss
extends Enemy
## PLACEHOLDER boss: a generic attack-pattern mix standing in for an undesigned
## sin or Satan encounter. Patterns only make the bosses distinguishable for testing.

signal summon_requested(boss: Boss, count: int)
signal attacked(boss: Boss)

enum Pattern { CHARGE, BURST, AIMED, SUMMON }

const CHARGE_WINDUP: float = 0.6
const CHARGE_TIME: float = 0.55
const PROJECTILE_SPEED: float = 260.0
const ATTACK_POSE_TIME: float = 0.5

var boss_name: String = "BOSS"
var patterns: Array[int] = []
var attack_interval: float = 2.5
var attack_left: float = 2.0
var windup_left: float = 0.0
var charge_left: float = 0.0
var charge_direction: Vector2 = Vector2.RIGHT
var attack_pose_left: float = 0.0


func _base_animation() -> StringName:
	return &"idle"


func _physics_process(delta: float) -> void:
	if health <= 0 or not is_instance_valid(target):
		return
	_tick_flash(delta)
	attack_pose_left = maxf(0.0, attack_pose_left - delta)
	if windup_left > 0.0:
		windup_left -= delta
		velocity = Vector2.ZERO
		if windup_left <= 0.0:
			charge_left = CHARGE_TIME
			queue_redraw()
	elif charge_left > 0.0:
		charge_left -= delta
		velocity = charge_direction * maxf(speed * 4.0, 420.0)
	else:
		velocity = (target.global_position - global_position).normalized() * speed
		attack_left -= delta
		if attack_left <= 0.0 and not patterns.is_empty():
			attack_left = attack_interval
			_attack(patterns.pick_random())
	move_and_slide()
	_face(target.global_position.x - global_position.x)
	var attacking: bool = windup_left > 0.0 or charge_left > 0.0 or attack_pose_left > 0.0
	var animation: StringName = &"attack" if attacking else &"idle"
	if sprite.sprite_frames != null and sprite.animation != animation:
		sprite.play(animation)
	_touch_player()


func _attack(pattern: int) -> void:
	var to_target: Vector2 = (target.global_position - global_position).normalized()
	attack_pose_left = ATTACK_POSE_TIME
	attacked.emit(self)
	match pattern:
		Pattern.CHARGE:
			charge_direction = to_target
			windup_left = CHARGE_WINDUP
			queue_redraw()
		Pattern.BURST:
			for index: int in range(12):
				_fire(Vector2.RIGHT.rotated(TAU * index / 12.0))
		Pattern.AIMED:
			for index: int in range(-2, 3):
				_fire(to_target.rotated(index * 0.22))
		Pattern.SUMMON:
			summon_requested.emit(self, 4)


func _fire(direction: Vector2) -> void:
	var projectile: EnemyProjectile = EnemyProjectile.new()
	projectile.position = global_position + direction * radius
	projectile.velocity = direction * PROJECTILE_SPEED
	projectile.target = target
	get_parent().add_child(projectile)


func _draw() -> void:
	# PLACEHOLDER charge telegraph and name tag.
	if windup_left > 0.0:
		draw_line(Vector2.ZERO, charge_direction * 260.0, Color(0.6, 0.32, 0.33, 0.7), 4.0)
	var font: Font = ThemeDB.fallback_font
	var at: Vector2 = Vector2(-120.0, -radius - 34.0)
	draw_string_outline(font, at, boss_name, HORIZONTAL_ALIGNMENT_CENTER, 240.0, 16, 6, Color("070109"))
	draw_string(font, at, boss_name, HORIZONTAL_ALIGNMENT_CENTER, 240.0, 16, Color("e6e29e"))
