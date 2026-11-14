class_name Bomber
extends Enemy
## PLACEHOLDER bomber (Wrath): runs in, and once close it stops and lights a fuse: an ember
## circle (a ground attack: fly over it or dash out) fills, then it explodes and dies. The blast
## hurts the angel and every ground enemy inside it, so luring bombers into the horde pays.
## Slain before the fuse runs out, it does not explode. Reuses the imp art, tinted orange in
## its scene; not an enemy design.

## PLACEHOLDER reach, timing, and blast.
const FUSE_RANGE: float = 60.0
const FUSE_TIME: float = 0.7
const BLAST_RADIUS: float = 72.0
## Damage the blast deals each enemy caught in it at the start (the run scales it like horde
## health, so luring stays worth it on every tier).
const ENEMY_DAMAGE: int = 6
## A lit bomber is hard to shove, so a stray hit cannot slide the blast onto the angel's path.
const LIT_PUSH: float = 0.35
## Ground enemies (layer 4); flyers are above the blast.
const ENEMY_MASK: int = 8
const FLASH_TIME: float = 0.2
const BLAST_COLOR: Color = Color(1.9, 0.9, 0.3, 1.0)

var fuse_left: float = 0.0
var enemy_damage: int = ENEMY_DAMAGE


func _physics_process(delta: float) -> void:
	# A fallen angel ends the fight: no fuse burns on after it.
	if health <= 0 or not is_instance_valid(target) or target.is_dead:
		return
	_tick_flash(delta)
	var to_target: Vector2 = target.global_position - global_position
	if fuse_left > 0.0:
		fuse_left -= delta
		velocity = knockback * LIT_PUSH
		queue_redraw()
		if fuse_left <= 0.0:
			explode()
			return
	else:
		velocity = to_target.normalized() * speed + knockback
		if to_target.length() <= FUSE_RANGE + radius and not target.is_dead and not target.is_descending():
			fuse_left = FUSE_TIME
	knockback = knockback.move_toward(Vector2.ZERO, 1400.0 * delta)
	move_and_slide()
	_face(to_target.x)


## Only the blast hurts; walking into the angel does not.
func _touch_player() -> void:
	pass


func explode() -> void:
	if health <= 0:
		return
	var at: Vector2 = global_position
	if is_instance_valid(target) and at.distance_to(target.global_position) <= BLAST_RADIUS + MountedPlayer.HURT_RADIUS:
		target.take_damage(contact_damage)
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = BLAST_RADIUS
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, at)
	query.collision_mask = ENEMY_MASK
	query.exclude = [get_rid()]
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, LightRain.MAX_TARGETS):
		var caught: Enemy = result["collider"] as Enemy
		if caught != null and caught.health > 0:
			caught.take_hit(enemy_damage, false, at)
	_flash(at)
	_perish()


## PLACEHOLDER blast: a bright disc that fades, drawn by a throwaway node.
func _flash(at: Vector2) -> void:
	var flash: Node2D = Node2D.new()
	flash.set_meta(&"light", Color(1.0, 0.55, 0.2, 0.5))
	flash.set_meta(&"light_radius", BLAST_RADIUS * 1.6)
	flash.add_to_group(&"light")
	flash.draw.connect(func() -> void: flash.draw_circle(Vector2.ZERO, BLAST_RADIUS, BLAST_COLOR))
	get_parent().add_child(flash)
	flash.global_position = at
	var tween: Tween = flash.create_tween()
	tween.tween_property(flash, ^"modulate:a", 0.0, FLASH_TIME)
	tween.tween_callback(flash.queue_free)


func _draw() -> void:
	if fuse_left > 0.0:
		Boss.draw_circle_tell(self, BLAST_RADIUS, floorf((1.0 - fuse_left / FUSE_TIME) * 4.0) / 4.0)
