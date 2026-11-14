class_name GroundCaster
extends FlyingEnemy
## PLACEHOLDER ground caster (Greed, Lust): keeps its distance like the flyer but walks on the
## ground, so walls stop it and its shots, and its shots are ground attacks an airborne angel
## flies over. The tell before each shot is an ember glint (ground). Reuses the imp art, tinted
## gold in its scene; not an enemy design.


## PLACEHOLDER glint length: a short tell, not a full-range beam.
const GLINT_LENGTH: float = 90.0


func _init() -> void:
	flying = false


func _ready() -> void:
	super()
	# Casters spawned together do not fire in lockstep.
	fire_left = randf_range(1.0, fire_interval)


## It walks: no bob, the sprite stays on the ground.
func _hover() -> void:
	lift = 0.0
	sprite.position = sprite_base


## Ground shots: walls stop them and they miss an airborne angel.
func _fire() -> void:
	var shot: EnemyProjectile = EnemyProjectile.new()
	shot.velocity = aim * shot_speed
	shot.damage = shot_damage
	shot.target = target
	get_parent().add_child(shot)
	shot.global_position = global_position + aim * radius


## Contact is a ground attack too.
func _touch_player() -> void:
	if global_position.distance_to(target.global_position) <= radius + MountedPlayer.HURT_RADIUS:
		target.take_damage(contact_damage)


func _draw() -> void:
	if windup_left > 0.0:
		Boss.draw_tell(self, aim * radius, aim * GLINT_LENGTH, Color(Boss.EMBER, 0.7))
