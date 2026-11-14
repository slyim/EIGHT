class_name Mirror
extends GroundCaster
## PLACEHOLDER mirror (Envy): copies the angel's weapon. While the angel holds the spear it
## rushes in to touch; while the angel holds the bow it keeps its distance and fires ground
## shots (ember glint, aim locked) like the ground caster. Switching weapons baits it. Reuses
## the imp art, tinted mint in its scene; not an enemy design.

## PLACEHOLDER range it keeps against a bow.
const BOW_DISTANCE: float = 240.0


func _physics_process(delta: float) -> void:
	if health <= 0 or not is_instance_valid(target):
		return
	if target.weapon == MountedPlayer.Weapon.BOW:
		preferred_distance = BOW_DISTANCE
	else:
		# The spear: close all the way in, and start no new shot (one already winding up still
		# fires where its glint showed, so flicking weapons cannot disarm it).
		preferred_distance = -KEEP_SLACK
		if windup_left <= 0.0:
			fire_left = maxf(fire_left, 0.5)
	super(delta)
