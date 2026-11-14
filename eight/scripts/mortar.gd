class_name Mortar
extends GroundCaster
## PLACEHOLDER mortar (Sloth, Greed): stands well back and, instead of shooting, marks an ember
## circle where the angel is; it lands after a moment (a ground attack: keep moving, fly over
## it, or dash out). Reuses the brute art, tinted brown in its scene; not an enemy design.

## PLACEHOLDER circle size and landing delay.
const STRIKE_RADIUS: float = 56.0
const STRIKE_DELAY: float = 0.8


## Off screen it holds its fire (it cannot see the angel), so mortars left behind do not shell
## the angel from across the realm.
func _physics_process(delta: float) -> void:
	if health > 0 and is_instance_valid(target) and windup_left <= 0.0:
		var offset: Vector2 = (target.global_position - global_position).abs()
		if offset.x > Boss.ON_SCREEN.x or offset.y > Boss.ON_SCREEN.y:
			fire_left = maxf(fire_left, 0.5)
	super(delta)


## The circle is the tell, so no glint beforehand.
func _draw() -> void:
	pass


func _fire() -> void:
	var strike: GroundStrike = GroundStrike.new()
	strike.radius = STRIKE_RADIUS
	strike.delay = STRIKE_DELAY
	strike.damage = shot_damage
	strike.target = target
	get_parent().add_child(strike)
	strike.global_position = target.global_position
